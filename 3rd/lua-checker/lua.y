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

Lua parser.

The Lua grammar has a well known ambiguity in the parsing of e.g. f(a)(b)(c),
in that this can be interpreted as either f(a);(b)(c) or (f(a)(b))(c).
The second parse is always preferred, which means that a function call
statement (that doesn't end in a semicolon) cannot be followed by a statement
that starts with an "(". This is expressed in this grammar by dividing some
rules into br_ and nobr_ versions, i.e. those that can start with a bracket '('
and those that can't. The 'statement list' rule is divided into parts to express
the disallowed transitions.

To avoid visual ambiguity in Lua code you cannot put a line break before
the '(' in a function call. This is not enforced here, since any code that is
compiled without error by Lua will be unambiguous here.

Two shift/reduce conflicts are expected. The first parses prefix_expression(...
as a function call rather than an expression followed by the start of a new
statement. The second calls out function call statements that looks like
'IDENTIFIER STRING', so that dofile files can be expanded inline.

The rule actions here output "normalized" Lua source code that is somewhat
easier for a following stage to parse: All output statements end with
semicolons, eliminating the above ambiguity, and various kinds of Lua
syntactic sugar are expanded out:

  a.name                          --> a['name']
  fn{fields}                      --> fn({fields})
  fn'string'                      --> fn('string')
  function fn() body              --> fn = function() body
  function t.a.b.c.f() body       --> t.a.b.c.f = function() body
  local function fn() body        --> local fn; fn = function() body
  function t.a.b.c:f(params) body --> t.a.b.c.f = function(self, params) body
  { foo=1 }                       --> { 'foo'=1 }

The following syntactic sugar expansion from the Lua manual is *not* done,
since 'v' must be evaluated only once:

  v:name(args) --> v.name(v,args)

*/

#include <string.h>
#include <stdarg.h>
#include "util.h"
#include "lua_simplifier.h"

// Semantic values.
#define YYSTYPE char*

// Error function called by the parser.
int lua_parser_error(const char *s);

// Take printf-style arguments and return a new string on the heap.
// The special word '@MarkerAndIndent@' is replaced by a filename:line_number marker and an
// indent appropriate for the current scope.
char *String(const char *filename, int line_number, const char *msg, ...)
  __attribute__((format (printf, 3, 4)));
#define INDENT "@MarkerAndIndent@"

// Concatenate two strings and return the result. If trim_trailing_newline is
// true then the trailing \n of s1 is removed and appended to the final string,
// unless both strings have zero length.
char *Concat(char *s1, const char *s2, bool trim_trailing_newline = false);

%}

// Tokens. @@@ This list must match other files that use lua.lex.
%token AND BREAK DO ELSE ELSEIF END FALSE FOR FUNCTION IF IN LOCAL NIL
  NOT OR REPEAT RETURN THEN TRUE UNTIL WHILE CONCAT ELLIPSES EQ GE LE NE
%token SPECIAL SPECIAL_CONST SPECIAL_NUMBER
%token NUMBER STRING IDENTIFIER

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
%expect 2
%name-prefix="lua_parser_"
%error-verbose
%pure-parser
%locations

%%

file:
    opt_block					{ printf("%s", $1); }
  ;

opt_block: { lua_parser_indent++; } opt_block_statements
           { lua_parser_indent--; $$ = $2; } ;

opt_block_statements:
						{ $$ = ""; }
  | last_statement
  | statement_list
  | statement_list last_statement		{ $$ = Concat($1, $2); }
  ;

// Statement lists are divided into four sub-lists, each of which ends in
// a different kind of statement. Transitions between the different kinds
// of list are carefully written to disallow statements that start with
// brackets from following function calls that don't end in a semicolon.
//
// Individual statements are distinguished based on:
//   - If they start with a bracket '('.
//   - If they are function calls.
//   - If they end with a semicolon ';'.
//
// The 8 possible kinds of statement are grouped into classes as follows:
//   Class 1: Unbracketed function calls.
//      function-call()
//   Class 2: Bracketed function calls.
//      (function-call)()
//   Class 3: Safe unbracketed statements that can be followed by anything.
//      non-function-call
//      function-call();
//	non-function-call;
//   Class 4: Safe bracketed statements that can be followed by anything.
//      (non-function-call)
//      (non-function-call);
//      (function-call)();
//
// Each of the four statement lists ends in one of these classes. The allowed
// and disallowed transitions between classes are:
//
//     From |To: 1   2   3   4 
//     -----+------+---+---+---
//       1  |    .   X   .   X      . = yes
//       2  |    .   X   .   X      X = no
//       3  |    .   .   .   .
//       4  |    .   .   .   .
  
class_1_statement:
    nobr_function_call				{ $$ = String(@1.filename, @1.line, INDENT"%s;\n", $1); }
  ;

class_2_statement:
    br_function_call				{ $$ = String(@1.filename, @1.line, INDENT"%s;\n", $1); }
  ;

class_3_statement:
    nobr_statement opt_special			{ $$ = Concat($1, $2, true); }
  | nobr_statement ';' opt_special		{ $$ = Concat($1, $3, true); }
  | nobr_function_call ';'			{ $$ = String(@1.filename, @1.line, INDENT"%s;\n", $1); }
  ;

class_4_statement:
    br_statement
  | br_statement ';'
  | br_function_call ';'			{ $$ = String(@1.filename, @1.line, INDENT"%s;\n", $1); }
  ;

statement_list:
    statement_list_1
  | statement_list_2
  | statement_list_3
  | statement_list_4
  ;

statement_list_1:
    class_1_statement
  | statement_list_1 class_1_statement		{ $$ = Concat($1, $2); }
  | statement_list_2 class_1_statement		{ $$ = Concat($1, $2); }
  | statement_list_3 class_1_statement		{ $$ = Concat($1, $2); }
  | statement_list_4 class_1_statement		{ $$ = Concat($1, $2); }
  ;

statement_list_2:
    class_2_statement
  | statement_list_3 class_2_statement		{ $$ = Concat($1, $2); }
  | statement_list_4 class_2_statement		{ $$ = Concat($1, $2); }
  ;

statement_list_3:
    class_3_statement
  | statement_list_1 class_3_statement		{ $$ = Concat($1, $2); }
  | statement_list_2 class_3_statement		{ $$ = Concat($1, $2); }
  | statement_list_3 class_3_statement		{ $$ = Concat($1, $2); }
  | statement_list_4 class_3_statement		{ $$ = Concat($1, $2); }
  ;

statement_list_4:
    class_4_statement
  | statement_list_3 class_4_statement		{ $$ = Concat($1, $2); }
  | statement_list_4 class_4_statement		{ $$ = Concat($1, $2); }
  ;

// A non-function-call statement that doesn't start with a bracket.

nobr_statement:
    nobr_variable_list '=' expression_list	{ $$ = String(@1.filename, @1.line, INDENT"%s = %s;\n", $1, $3); }
  | DO opt_block END				{ $$ = String(@1.filename, @1.line, INDENT"do\n%s"INDENT"end\n", $2); }
  | WHILE expression DO opt_block END		{ $$ = String(@1.filename, @1.line, INDENT"while %s do\n%s"INDENT"end\n", $2, $4); }
  | REPEAT opt_block UNTIL expression		{ $$ = String(@1.filename, @1.line, INDENT"repeat\n%s"INDENT"until %s;\n", $2, $4); }
  | IF expression THEN opt_block opt_elseif_block_list
	opt_else_block END			{ $$ = String(@1.filename, @1.line, INDENT"if %s then\n%s%s%s"INDENT"end\n", $2, $4, $5, $6); }
  | FOR IDENTIFIER '=' expression ',' expression
	DO opt_block END			{ $$ = String(@1.filename, @1.line, INDENT"for %s = %s,%s,1 do\n%s"INDENT"end\n", $2, $4, $6, $8); }
  | FOR IDENTIFIER '=' expression ',' expression ',' expression
	DO opt_block END			{ $$ = String(@1.filename, @1.line, INDENT"for %s = %s,%s,%s do\n%s"INDENT"end\n", $2, $4, $6, $8, $10); }
  | FOR identifier_list IN expression_list
	DO opt_block END			{ $$ = String(@1.filename, @1.line, INDENT"for %s in %s do\n%s"INDENT"end\n", $2, $4, $6); }
  | FUNCTION func_name_list function_body	{ $$ = String(@1.filename, @1.line, INDENT"%s = function(%s;\n", $2, $3); }
  | FUNCTION func_name_list ':' IDENTIFIER
	function_body				{ $$ = String(@1.filename, @1.line, INDENT"%s['%s'] = function(self, %s;\n", $2, $4, $5); }
  | LOCAL FUNCTION IDENTIFIER function_body	{
						  if (flag_luac_mode) {
						    $$ = String(@1.filename, @1.line, INDENT"local function %s (%s\n" , $3, $4);
						  } else {
						    // This generates extra LOADNIL instructions when passed to luac.
						    $$ = String(@1.filename, @1.line, INDENT"local %s;\n"INDENT"%s = function(%s;\n" , $3, $3, $4);
						  }
						}
  | LOCAL identifier_list			{ $$ = String(@1.filename, @1.line, INDENT"local %s;\n", $2); }
  | LOCAL identifier_list '=' expression_list	{ $$ = String(@1.filename, @1.line, INDENT"local %s = %s;\n", $2, $4); }
  | IDENTIFIER STRING				{
						  // Separately handle these function call statements so that
						  // we can expand outer-scope dofiles inline.
						  if (strcmp($1, "dofile") == 0 && lua_parser_indent == 0) {
						    CHECK(strcmp(yylval, $2) == 0);	// Ensure lexxer hasn't read past the string
						    $$ = "";
						    LexxerPushFile($2);
						  } else {
						    $$ = String(@1.filename, @1.line, INDENT"%s(%s);\n", $1, $2);
						  }
						}
  ;

// A non-function-call statement that starts with a bracket.

br_statement:
    br_variable_list '=' expression_list	{ $$ = String(@1.filename, @1.line, INDENT"%s = %s;\n", $1, $3); }
  ;

// Rules that make up parts 'if-then-elseif-else' statements.

opt_elseif_block_list:
						{ $$ = ""; }
  | elseif_block_list
  ;

elseif_block_list:
    elseif_block
  | elseif_block_list elseif_block		{ $$ = Concat($1, $2); }
  ;

elseif_block:
    ELSEIF expression THEN opt_block		{ $$ = String(@1.filename, @1.line, INDENT"elseif %s then\n%s", $2, $4); }
  ;

opt_else_block:
						{ $$ = ""; }
  | ELSE opt_block				{ $$ = String(@1.filename, @1.line, INDENT"else\n%s", $2); }
  ;

// The last statement in a block.

last_statement:
    RETURN opt_semicolon			{ $$ = String(@1.filename, @1.line, INDENT"return;\n"); }
  | RETURN expression_list opt_semicolon	{ $$ = String(@1.filename, @1.line, INDENT"return %s;\n", $2); }
  | BREAK opt_semicolon				{ $$ = String(@1.filename, @1.line, INDENT"break;"); }
  ;
 
// Variable lists used in statements.

nobr_variable_list:
    nobr_variable
  | nobr_variable_list ',' nobr_variable	{ $$ = String(@1.filename, @1.line, "%s, %s", $1, $3); }
  | nobr_variable_list ',' br_variable		{ $$ = String(@1.filename, @1.line, "%s, %s", $1, $3); }
  ;

br_variable_list:
    br_variable
  | br_variable_list ',' nobr_variable		{ $$ = String(@1.filename, @1.line, "%s, %s", $1, $3); }
  | br_variable_list ',' br_variable		{ $$ = String(@1.filename, @1.line, "%s, %s", $1, $3); }
  ;

// Function names.

func_name_list:
    IDENTIFIER
  | func_name_list '.' IDENTIFIER		{ $$ = String(@1.filename, @1.line, "%s['%s']", $1, $3); }
  ;

// Expressions.

expression:
    NIL						{ $$ = "nil"; }
  | FALSE					{ $$ = "false"; }
  | TRUE					{ $$ = "true"; }
  | NUMBER
  | STRING
  | ELLIPSES					{ $$ = "..."; }
  | FUNCTION function_body			{ $$ = String(@1.filename, @1.line, "function(%s", $2); }
  | nobr_prefix_expression
  | '(' expression ')'				{ $$ = String(@1.filename, @1.line, "(%s)", $2); }
  | table_constructor
  | expression CONCAT expression		{ $$ = String(@1.filename, @1.line, "%s .. %s", $1, $3); }
  | expression '+' expression			{ $$ = String(@1.filename, @1.line, "%s + %s", $1, $3); }
  | expression '-' expression			{ $$ = String(@1.filename, @1.line, "%s - %s", $1, $3); }
  | expression '*' expression			{ $$ = String(@1.filename, @1.line, "%s * %s", $1, $3); }
  | expression '/' expression			{ $$ = String(@1.filename, @1.line, "%s / %s", $1, $3); }
  | expression '^' expression			{ $$ = String(@1.filename, @1.line, "%s ^ %s", $1, $3); }
  | expression '%' expression			{ $$ = String(@1.filename, @1.line, "%s %% %s", $1, $3); }
  | expression '<' expression			{ $$ = String(@1.filename, @1.line, "%s < %s", $1, $3); }
  | expression LE expression			{ $$ = String(@1.filename, @1.line, "%s <= %s", $1, $3); }
  | expression '>' expression			{ $$ = String(@1.filename, @1.line, "%s > %s", $1, $3); }
  | expression GE expression			{ $$ = String(@1.filename, @1.line, "%s >= %s", $1, $3); }
  | expression EQ expression			{ $$ = String(@1.filename, @1.line, "%s == %s", $1, $3); }
  | expression NE expression			{ $$ = String(@1.filename, @1.line, "%s ~= %s", $1, $3); }
  | expression AND expression			{ $$ = String(@1.filename, @1.line, "%s and %s", $1, $3); }
  | expression OR expression			{ $$ = String(@1.filename, @1.line, "%s or %s", $1, $3); }
  | NOT expression %prec UNARY_OPERATOR		{ $$ = String(@1.filename, @1.line, "not %s", $2); }
  | '-' expression %prec UNARY_OPERATOR		{ $$ = String(@1.filename, @1.line, "- %s", $2); }
  | '#' expression %prec UNARY_OPERATOR		{ $$ = String(@1.filename, @1.line, "# %s", $2); }
  ;

expression_list:
    expression
  | expression_list ',' expression		{ $$ = String(@1.filename, @1.line, "%s, %s", $1, $3); }
  ;

// "Prefix expressions" are R-values, i.e. expression values.
// The only prefix expression that starts with '(' is '(expression)'.

nobr_prefix_expression:
    nobr_variable
  | nobr_function_call
  ;

// "Variables" are L-values, i.e. anything that can appear on the left hand
// side of an equals sign and be assigned to.

nobr_variable:
    IDENTIFIER
  | nobr_prefix_expression '[' expression ']'	{ $$ = String(@1.filename, @1.line, "%s[%s]", $1, $3); }
  | nobr_prefix_expression '.' IDENTIFIER	{ $$ = String(@1.filename, @1.line, "%s['%s']", $1, $3); }
  ;

br_variable:
    '(' expression ')' '[' expression ']'	{ $$ = String(@1.filename, @1.line, "(%s)[%s]", $2, $5); }
  | '(' expression ')' '.' IDENTIFIER		{ $$ = String(@1.filename, @1.line, "(%s)['%s']", $2, $5); }
  ;

// Functions.

nobr_function_call:
    nobr_prefix_expression arguments		{ $$ = String(@1.filename, @1.line, "%s(%s)", $1, $2); }
  | nobr_prefix_expression ':' IDENTIFIER
	arguments				{ $$ = String(@1.filename, @1.line, "%s:%s(%s)", $1, $3, $4); }
  ;

br_function_call:
    '(' expression ')' arguments		{ $$ = String(@1.filename, @1.line, "(%s)(%s)", $2, $4); }
  | '(' expression ')' ':' IDENTIFIER arguments	{ $$ = String(@1.filename, @1.line, "(%s):%s(%s)", $2, $5, $6); }
  ;

arguments:
    '(' ')'					{ $$ = ""; }
  | '(' expression_list ')'			{ $$ = $2; }
  | table_constructor
  | STRING
  ;

function_body:
    '(' opt_parameter_list ')' opt_block END	{ $$ = String(@1.filename, @1.line, "%s)\n%s"INDENT"end", $2, $4); }
  ;

opt_parameter_list:
						{ $$ = ""; }
  | ELLIPSES					{ $$ = "..."; }
  | identifier_list
  | identifier_list ',' ELLIPSES		{ $$ = String(@1.filename, @1.line, "%s, ...", $1); }
  ;

// Tables.

table_constructor:
    '{' '}'					{ $$ = "{}"; }
  | '{' { lua_parser_indent++; array_index.push_back(1); } field_list opt_field_separator '}' {
						  lua_parser_indent--;
						  array_index.pop_back();
						  $$ = String(@1.filename, @1.line, "{\n%s\n"INDENT"}", $3);
						}
  ;

field_list:
    field					{ $$ = String(@1.filename, @1.line, INDENT"%s", $1); }
  | field_list field_separator field		{ $$ = String(@1.filename, @1.line, "%s,\n"INDENT"%s", $1, $3); }
  ;

field:
    '[' expression ']' '=' expression		{ $$ = String(@1.filename, @1.line, "[%s] = %s", $2, $5); }
  | IDENTIFIER '=' expression			{ $$ = String(@1.filename, @1.line, "['%s'] = %s", $1, $3); }
  | expression					{
						  if (flag_luac_mode) {
						    $$ = $1;
						  } else {
						    // This generates SETTABLE instead of SETLIST
						    // instructions when passed to luac.
						    $$ = String(@1.filename, @1.line, "[%d] = %s", array_index.back()++, $1);
						  }
						}
  ;

// Trivial stuff

opt_semicolon: | ';' ;

field_separator: ',' | ';' ;

opt_field_separator: | field_separator ;

identifier_list:
    IDENTIFIER
  | identifier_list ',' IDENTIFIER		{ $$ = String(@1.filename, @1.line, "%s, %s", $1, $3); }
  ;

opt_special:
						{ $$ = ""; }
  | SPECIAL
  ;

%%

int lua_parser_error (const char *s) {
  Panic("%s, at %s:%d", s, LexxerFilename(), LexxerLinecount());
}

char *String(const char *filename, int line_number, const char *msg, ...) {
  char *buffer = 0;

  // Replace the special word '@MarkerAndIndent@' with the filename:line_number
  // (if the -emit_lines flag is set) and indent spaces.
  if (strstr(msg, "@MarkerAndIndent@")) {
    // Copy the format string and deactivate all %'s.
    char *tmp1 = strdup(msg);
    for (char *s = tmp1; *s; s++) {
      if (*s == '%') *s = -'%';
    }
    // Replace all @MarkerAndIndent@ markers by the appropriate printf() format string.
    char *ind = tmp1 - 17;
    while((ind = strstr(ind + 17, "@MarkerAndIndent@"))) {
      if (flag_emit_lines) {
        memcpy(ind, "@%3$s:%4$d%2$*1$s", 17);
      } else {
        memcpy(ind, "          %2$*1$s", 17);
      }
    }
    // Do the @MarkerAndIndent@ substitution.
    asprintf(&buffer, tmp1, lua_parser_indent*2 + 1, "", filename, line_number);
    free(tmp1);
    // Reactivate the original %'s.
    for (char *s = buffer; *s; s++) {
      if (*s == -'%') *s = '%';
    }
    msg = buffer;
  }

  // Run sprintf.
  va_list ap;
  va_start(ap, msg);
  char *ret = 0;
  vasprintf(&ret, msg, ap);
  if (buffer) free(buffer);
  return ret;
}

char *Concat(char *s1, const char *s2, bool trim_trailing_newline) {
  if (trim_trailing_newline && (s1[0] || s2[0])) {
    int len = strlen(s1);
    CHECK(len > 0 && s1[len-1] == '\n');
    s1[len-1] = 0;
    return String(0, 0, "%s%s\n", s1, s2);
  } else {
    return String(0, 0, "%s%s", s1, s2);
  }
}
