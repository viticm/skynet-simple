%{

/*

Copyright (C) 2008 Google Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 

*/

/*

Parser for a simplified Lua grammar that does various checks.

The following attributes can be added through special comments:
  * const - No assignments after the first declaration can be done.

TODO:
	* track types of variables at each point in the code.
		- warn when TYPE_UNASSIGNED variables go out of scope (useless variables).
		- when TYPE_UNASSIGNED variables assigned to functions and -const_functions
		  given then make those variables const.
		- warn when variables change type
	* allow forward declaration of functions when using -const_functions
	* allow global variable_list=expression_list to define new variables?
	* warning about defining/assigning new global functions in local scope
	* using ellipses in function that doesn't have it as an arg
	* in rules: [LOCAL] IDENTIFIER '=' expression, isn't an assignment
	  to expression_list allowed? allowing this would make the type checking
	  logic more complex, and anyway this represents a programming error
	  and should be properly warned about.
	* in rule: LOCAL identifier_list_2 '=' expression_list, assignments of
	  functions should make the variables constant (if -const_functions given).
	* If -const_functions given, "local function bar() end; bar=2" not warned
	  about since this becomes local bar; bar = function() end; bar=2", so we
	  don't detect that bar needs to be constant initially.
	* warn about any uses of 'dofile' here, as "correct" uses would have already
	  been expanded inline.
	* dofile() returns values returned by chunk (with return?). if the dofile
	  return is expanded inline, that wont work (it will terminate the dofile
	  caller early).
        * Warn about updating a table that is being traversed with for ... in pairs().

DONE:
	* -no-reassignment-of-function-variables (make them implicitly constant)

*/

#include <map>
#include <vector>
#include <string>
#include <cstring>
#include "util.h"
#include "lua_checker.h"
#include "lua_checker_parser.h"

using std::vector;
using std::map;

// Functions called by the parser.
int lua_parser_error(const char *s);
int lua_parser_lex(YYSTYPE *yylval_param, YYLTYPE *yylloc_param);

// Type constants. TYPE_UNKNOWN means that the actual type either can't be
// inferred or changes at runtime.
enum {
  TYPE_UNKNOWN,
  TYPE_NIL,
  TYPE_BOOLEAN,
  TYPE_NUMBER,
  TYPE_STRING,
  TYPE_TABLE,
  TYPE_FUNCTION,
  TYPE_WRONG,			// For development: correct type not computed
};

// The type of a variable or expression.
struct TypeInfo {
  int type;			// A TYPE_xxx constant

  TypeInfo(int _type = TYPE_UNKNOWN) {
    type = _type;
  }
};

// Information stored for one variable.
struct VariableInfo {
  int line_number;		// Line this declared on, 0 if declared outside main chunk
  const char *filename;		// File this is declared in
  bool is_constant;		// Can its value be changed?

  VariableInfo(int _line_number = 0, const char *_filename = 0, bool _is_constant = false) {
    line_number = _line_number;
    filename = _filename;
    is_constant = _is_constant;
  }
};

// Information stored per scope.
struct ltstr {
  bool operator()(const char* s1, const char* s2) const
    { return strcmp(s1, s2) < 0; }
};
struct ScopeInfo {
  typedef map<const char*, VariableInfo, ltstr> vars_t;
  vars_t vars;
};

// Array of scopes.
vector<ScopeInfo> scope_vars;

// Forward declarations.
void Initialize();
void Finalize();
void PushScope();
void PopScope();
void AddVariable(const char *filename, int line_number, const char *name, bool is_constant = false);
void CheckVariable(const char *filename, int line_number, const char *name, bool is_assignment = false);
bool IsGlobalVariable(const char *name);

%}

// Semantic values.
%union {
  char *string;			// Also used for identifiers
  double number;
  bool is_constant;		// For opt_const
  struct TypeInfo *type_info;
}

// Tokens. @@@ This list must match other files that use lua.lex.
%token AND BREAK DO ELSE ELSEIF END FALSE FOR FUNCTION IF IN LOCAL NIL
  NOT OR REPEAT RETURN THEN TRUE UNTIL WHILE CONCAT ELLIPSES EQ GE LE NE
%token SPECIAL SPECIAL_CONST SPECIAL_NUMBER
%token <string> NUMBER STRING IDENTIFIER

%type <is_constant> opt_const
%type <type_info> expression prefix_expression variable function_call

// Operator precedence.
%left OR
%left AND
%left '<' '>' LE GE
%left EQ NE
%right CONCAT
%left '+' '-'
%left '*' '/' '%'
%left UNARY_OPERATOR
%right '^'

// Misc directives.
%start file
%name-prefix="lua_parser_"
%error-verbose
%pure-parser
%locations
%expect 1

%%

file: { Initialize(); } opt_statement_list { Finalize(); } ;

statement:
    IDENTIFIER '=' expression ';' opt_const
	{
	  // If a single identifier is assigned for the first time in the outer
	  // scope then this is considered to be a valid variable declaration.
	  // This rule creates an expected shift/reduce conflict.
	  // @@@ If a variable is assigned multiple times, check that its type is the same.
	  if (scope_vars.size() == 1 && !IsGlobalVariable($1)) {
	    bool is_const = $5 || (flag_const_functions && $3->type == TYPE_FUNCTION);
	    AddVariable(@1.filename, @1.line, $1, is_const);
	  } else {
	    CheckVariable(@1.filename, @1.line, $1, true);
	    if ($5) {
	      printf("%s:%d: Only declaration of variable '%s' may use 'const'\n", @1.filename, @1.line, $1);
	    }
	  }
	}
  | variable_list '=' expression_list ';'
  | function_call ';'
  | DO { PushScope(); } opt_statement_list { PopScope(); } END
  | WHILE expression DO { PushScope(); } opt_statement_list { PopScope(); } END
  | REPEAT { PushScope(); } opt_statement_list { PopScope(); } UNTIL expression ';'
  | IF expression THEN { PushScope(); } opt_statement_list { PopScope(); } opt_elseif_block_list opt_else_block END
  | for IDENTIFIER { AddVariable(@1.filename, @1.line, $2); } '=' expression ',' expression ',' expression
	DO opt_statement_list END { PopScope(); }
  | for identifier_list IN expression_list
	DO opt_statement_list END { PopScope(); }
  | LOCAL IDENTIFIER '=' expression ';' opt_const
	{
	  bool is_const = $6 || (flag_const_functions && $4->type == TYPE_FUNCTION);
	  AddVariable(@1.filename, @1.line, $2, is_const);
	}
  | LOCAL identifier_list ';'
  | LOCAL identifier_list_2 '=' expression_list ';'
  | RETURN opt_expression_list ';'
  | BREAK ';'
  ;

for: FOR { PushScope(); } ;

elseif_block:
    ELSEIF expression THEN { PushScope(); } opt_statement_list { PopScope(); }
  ;

opt_else_block:
  | ELSE { PushScope(); } opt_statement_list { PopScope(); }
  ;

// Expressions.

expression:
    NIL						{ $$ = new TypeInfo(TYPE_NIL); }
  | FALSE					{ $$ = new TypeInfo(TYPE_BOOLEAN); }
  | TRUE					{ $$ = new TypeInfo(TYPE_BOOLEAN); }
  | NUMBER					{ $$ = new TypeInfo(TYPE_NUMBER); }
  | STRING					{ $$ = new TypeInfo(TYPE_STRING); }
  | ELLIPSES					{ $$ = new TypeInfo(TYPE_UNKNOWN); }
  | FUNCTION { PushScope(); } function_body	{ $$ = new TypeInfo(TYPE_FUNCTION); PopScope(); }
  | prefix_expression
  | '{' opt_field_list '}'			{ $$ = new TypeInfo(TYPE_TABLE); }
  | expression CONCAT expression		{ $$ = new TypeInfo(TYPE_STRING); }
  | expression '+' expression			{ $$ = new TypeInfo(TYPE_NUMBER); }
  | expression '-' expression			{ $$ = new TypeInfo(TYPE_NUMBER); }
  | expression '*' expression			{ $$ = new TypeInfo(TYPE_NUMBER); }
  | expression '/' expression			{ $$ = new TypeInfo(TYPE_NUMBER); }
  | expression '^' expression			{ $$ = new TypeInfo(TYPE_NUMBER); }
  | expression '%' expression			{ $$ = new TypeInfo(TYPE_NUMBER); }
  | expression '<' expression			{ $$ = new TypeInfo(TYPE_BOOLEAN); }
  | expression LE expression			{ $$ = new TypeInfo(TYPE_BOOLEAN); }
  | expression '>' expression			{ $$ = new TypeInfo(TYPE_BOOLEAN); }
  | expression GE expression			{ $$ = new TypeInfo(TYPE_BOOLEAN); }
  | expression EQ expression			{ $$ = new TypeInfo(TYPE_BOOLEAN); }
  | expression NE expression			{ $$ = new TypeInfo(TYPE_BOOLEAN); }
  | expression AND expression			{ $$ = new TypeInfo(TYPE_WRONG); }
  | expression OR expression			{ $$ = new TypeInfo(TYPE_WRONG); }
  | NOT expression %prec UNARY_OPERATOR		{ $$ = new TypeInfo(TYPE_WRONG); }
  | '-' expression %prec UNARY_OPERATOR		{ $$ = new TypeInfo(TYPE_NUMBER); }
  | '#' expression %prec UNARY_OPERATOR		{ $$ = new TypeInfo(TYPE_NUMBER); }
  ;

// "Prefix expressions" are R-values, i.e. expression values.

prefix_expression:
    variable
  | '(' expression ')'				{ $$ = $2; }
  | function_call
  ;

// "Variables" are L-values, i.e. anything that can appear on the left hand
// side of an equals sign and be assigned to.

variable:
    IDENTIFIER					{ CheckVariable(@1.filename, @1.line, $1); $$ = new TypeInfo(TYPE_WRONG); }
  | prefix_expression '[' expression ']'	{ $$ = new TypeInfo(TYPE_WRONG); }
  ;

// Functions.

function_call:
    prefix_expression '(' opt_expression_list ')'			{ $$ = new TypeInfo(TYPE_WRONG); }
  | prefix_expression ':' IDENTIFIER '(' opt_expression_list ')'	{ $$ = new TypeInfo(TYPE_WRONG); }
  ;

function_body:
    '(' ')' opt_statement_list END
  | '(' ELLIPSES ')' opt_statement_list END
  | '(' identifier_list ')' opt_statement_list END
  | '(' identifier_list ',' ELLIPSES ')' opt_statement_list END
  ;

// Table fields.

field: '[' expression ']' '=' expression ;

// Lists of one or more things, often separated by commas.

statement_list:
    statement
  | statement_list statement
  ;

elseif_block_list:
    elseif_block
  | elseif_block_list elseif_block
  ;

identifier_list:
    IDENTIFIER				{ AddVariable(@1.filename, @1.line, $1); }
  | identifier_list ',' IDENTIFIER	{ AddVariable(@1.filename, @1.line, $3); }
  ;

variable_list:
    variable
  | variable_list ',' variable
  ;

expression_list:
    expression
  | expression_list ',' expression
  ;

field_list:
    field
  | field_list ',' field
  ;

// Lists of two or more things.

identifier_list_2:
    identifier_list ',' IDENTIFIER	{ AddVariable(@1.filename, @1.line, $3); }
  ;

// Lists of zero or more things, often separated by commas.

opt_statement_list: | statement_list ;
opt_elseif_block_list: | elseif_block_list ;
opt_expression_list: | expression_list ;
opt_field_list: | field_list ;
opt_const: { $$ = false; } | SPECIAL_CONST { $$ = true; } ;

%%

int lua_parser_error (const char *s) {
  Panic("%s, at %s:%d of simplified lua source", s, LexxerFilename(), LexxerLinecount());
}

void Initialize() {
  scope_vars.resize(1);
  // Add global functions and variables.
  scope_vars.back().vars["error"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["print"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["pairs"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["ipairs"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["assert"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["type"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["loadstring"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["tonumber"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["tostring"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["rawget"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["next"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["dofile"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["setmetatable"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["_G"] = VariableInfo(0, 0, true);
  // Add library function tables.
  scope_vars.back().vars["string"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["io"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["os"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["table"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["math"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["coroutine"] = VariableInfo(0, 0, true);
  // Add mylua/lmake extensions. @@@ need a different way to specify these.
  scope_vars.back().vars["arg"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["FLAGS"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["ErrorHandler"] = VariableInfo(0);	// Can be assigned to
  scope_vars.back().vars["Rule"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["Cmd"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["CmdNoError"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["CmdGrabOutput"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["FileExists"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["StringToFile"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["FileAsString"] = VariableInfo(0, 0, true);
  scope_vars.back().vars["ExpandVariables"] = VariableInfo(0, 0, true);
}

void Finalize() {
  CHECK(scope_vars.size() == 1);
}

void PushScope() {
  scope_vars.resize(scope_vars.size() + 1);
}

void PopScope() {
  scope_vars.pop_back();
}

// Add a variable to the current scope.

void AddVariable(const char *filename, int line_number, const char *name, bool is_constant) {
  CHECK(line_number > 0);
  CHECK(scope_vars.size() > 0);

  // Check for this variable in the current scope, and optionally outer
  // scopes too.
  for (int i = scope_vars.size()-1 ; i >= 0; i--) {
    if (scope_vars[i].vars.count(name) > 0) {
      const char *f = scope_vars[i].vars[name].filename;
      int l = scope_vars[i].vars[name].line_number;
      if (l > 0) {
        printf("%s:%d: variable '%s' already declared at %s:%d\n",
               filename, line_number, name, f, l);
      } else {
        printf("%s:%d: variable '%s' is declared external to this file\n",
               filename, line_number, name);
      }
      break;
    }
    if (!flag_no_reuse_varnames) break;
  }
  scope_vars.back().vars[name] = VariableInfo(line_number, filename, is_constant);
}

// Check that a variable exists in the current or previous scopes. Print a
// warning if this variable is being assigned to and has a constant value.

void CheckVariable(const char *filename, int line_number, const char *name, bool is_assignment) {
  for (int i = scope_vars.size()-1 ; i >= 0; i--) {
    ScopeInfo::vars_t::iterator it = scope_vars[i].vars.find(name);
    if (it != scope_vars[i].vars.end()) {
      if (is_assignment && it->second.is_constant) {
        if (it->second.line_number > 0) {
          printf("%s:%d: Assignment to constant '%s' (which was declared at %s:%d)\n",
                 filename, line_number, name, it->second.filename, it->second.line_number);
        } else {
          printf("%s:%d: Assignment to constant '%s' (which was declared external to this file)\n",
                 filename, line_number, name);
        }
      }
      return;
    }
  }
  printf("%s:%d: Variable '%s' not declared\n", filename, line_number, name);
}

// Return true if the given name is a global variable.

bool IsGlobalVariable(const char *name) {
  CHECK(scope_vars.size() > 0);
  return scope_vars[0].vars.find(name) != scope_vars[0].vars.end();
}
