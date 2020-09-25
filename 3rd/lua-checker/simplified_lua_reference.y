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

Parser for a simplified Lua grammar that has no ambiguities and no syntactic
sugar. This is a subset of the complete Lua grammar. It is easier to write
things such as Lua checkers based on the simplified grammar.

This file is not compiled, it is just a reference for other parsers that are
based on the simplified Lua syntax.

*/

%}

// Tokens. @@@ This list must match other files that use lua.lex.
%token AND BREAK DO ELSE ELSEIF END FALSE FOR FUNCTION IF IN LOCAL NIL
  NOT OR REPEAT RETURN THEN TRUE UNTIL WHILE CONCAT ELLIPSES EQ GE LE NE
%token NUMBER STRING IDENTIFIER
%token SPECIAL SPECIAL_CONST SPECIAL_NUMBER

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

%start file

%%

file: opt_statement_list ;

statement:
    variable_list '=' expression_list ';'
  | function_call ';'
  | DO opt_statement_list END
  | WHILE expression DO opt_statement_list END
  | REPEAT opt_statement_list UNTIL expression ';'
  | IF expression THEN opt_statement_list opt_elseif_block_list opt_else_block END
  | FOR IDENTIFIER '=' expression ',' expression ',' expression DO opt_statement_list END
  | FOR identifier_list IN expression_list DO opt_statement_list END
  | LOCAL identifier_list ';'
  | LOCAL identifier_list '=' expression_list ';'
  | RETURN opt_expression_list ';'
  | BREAK ';'
  ;

elseif_block:
    ELSEIF expression THEN opt_statement_list
  ;

opt_else_block:
  | ELSE opt_statement_list
  ;

// Expressions.

expression:
    NIL
  | FALSE
  | TRUE
  | NUMBER
  | STRING
  | ELLIPSES
  | FUNCTION function_body
  | prefix_expression
  | '{' opt_field_list '}'
  | expression CONCAT expression
  | expression '+' expression
  | expression '-' expression
  | expression '*' expression
  | expression '/' expression
  | expression '^' expression
  | expression '%' expression
  | expression '<' expression
  | expression LE expression
  | expression '>' expression
  | expression GE expression
  | expression EQ expression
  | expression NE expression
  | expression AND expression
  | expression OR expression
  | NOT expression %prec UNARY_OPERATOR
  | '-' expression %prec UNARY_OPERATOR
  | '#' expression %prec UNARY_OPERATOR
  ;

// "Prefix expressions" are R-values, i.e. expression values.

prefix_expression:
    variable
  | '(' expression ')'
  | function_call
  ;

// "Variables" are L-values, i.e. anything that can appear on the left hand
// side of an equals sign and be assigned to.

variable:
    IDENTIFIER
  | prefix_expression '[' expression ']'
  ;

// Functions.

function_call:
    prefix_expression '(' opt_expression_list ')'
  | prefix_expression ':' IDENTIFIER '(' opt_expression_list ')'
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

statement_list: statement | statement_list statement ;
elseif_block_list: elseif_block | elseif_block_list elseif_block ;
identifier_list: IDENTIFIER | identifier_list ',' IDENTIFIER ;
variable_list: variable | variable_list ',' variable ;
expression_list: expression | expression_list ',' expression ;
field_list: field | field_list ',' field ;

// Lists of zero or more things, often separated by commas.

opt_statement_list: | statement_list ;
opt_elseif_block_list: | elseif_block_list ;
opt_expression_list: | expression_list ;
opt_field_list: | field_list ;

%%
