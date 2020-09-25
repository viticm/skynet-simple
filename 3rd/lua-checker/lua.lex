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

Lua lexxer.

*/

// Semantic values.
#define YYSTYPE char*

#include <libgen.h>			// For dirname()
#include <vector>
#include <string>
#include "util.h"
#include "lua_parser.h"

// Constants.
#define MAX_INCLUDE_DEPTH 100

// Information about the main file and files nested with 'dofile'.
struct FileInfo {
  YY_BUFFER_STATE buffer;
  char *filename;			// Name of file being processed
  int line_count;			// Current line position in file
  int marker_line_number;		// Last @filename:number line number
  const char *marker_filename;		// Last @filename:number filename

  FileInfo() { memset(this, 0, sizeof(*this)); }
};

// Local state.
static std::vector<FileInfo> files;	// Top level and nested files
static bool expand_special_tokens;      // Controls production of SPECIAL tokens
static bool ignore_first_semicolon;	// Ignore ';' one time

// Return a token number to the caller and set the location.
#define TOKEN(n) { int ret = n; SetLocation(yylloc); ignore_first_semicolon = false; return ret; }

// Set location information for a token.
static void SetLocation(YYLTYPE *yylloc) {
  yylloc->line = files.back().marker_line_number ?
    files.back().marker_line_number : files.back().line_count;
  yylloc->filename = files.back().marker_line_number ?
    files.back().marker_filename : files.back().filename;
}

// Return the number of characters 'c' in the given string.
static int CountChars(const char *s, char c) {
  int count = 0;
  while (*s) {
    if (*s == c) count++;
    s++;
  }
  return count;
}

// Complain about a bad character in the input.
static void PanicWithBadChar(int c) {
  if (c >= 32 && c <= 126) {
    Panic("Unexpected character '%c', at %s:%d", c,
          files.back().filename, files.back().line_count);
  } else {
    Panic("Unexpected character #%d, at %s:%d", (unsigned char) c,
          files.back().filename, files.back().line_count);
  }
}

// Skip over '#!...' on the first line of a file, return true if a line was
// skipped.
static bool SkipInterpreterLine(FILE *fin) {
  int c = fgetc(fin);
  if (c == '#') {
    for(;;) {
      c = fgetc(fin);
      if (c == '\n' || c == EOF) break;
    }
    return true;
  } else {
    ungetc(c, fin);
    return false;
  }
}

void InitializeLexxer(const char *filename, bool _expand_special_tokens) {
  if (strchr(filename, ':')) Panic("Colons not allowed in filenames (%s)", filename);
  lua_lexxer_in = fopen(filename,"rb");
  if (!lua_lexxer_in) Panic("Can not open %s (%s)", filename, strerror(errno));

  FileInfo file;
  file.filename = strdup(filename);
  file.line_count = 1 + SkipInterpreterLine(lua_lexxer_in);
  file.marker_line_number = 0;
  file.marker_filename = 0;
  files.push_back(file);

  expand_special_tokens = _expand_special_tokens;
  ignore_first_semicolon = false;
}

void FinalizeLexxer() {
  fclose(lua_lexxer_in);
}

void LexxerPushFile(const char *filename) {
  if (files.size() >= MAX_INCLUDE_DEPTH) {
    Panic("dofile() files nested too deeply, at %s:%d",
          files.back().filename, files.back().line_count);
  }
  files.back().buffer = YY_CURRENT_BUFFER;
  std::string fname = dirname(strdup(files[0].filename));
  fname += "/";
  fname += filename + 1;		// Chop off first quote
  fname.resize(fname.size() - 1);	// Chop off last quote
  InitializeLexxer(fname.c_str(), expand_special_tokens);
  yy_switch_to_buffer(yy_create_buffer(lua_lexxer_in, YY_BUF_SIZE));	//@@@ can we not use the global lua_lexxer_in?
}

const char *LexxerFilename() {
  return files.back().filename;
}

int LexxerLinecount() {
  return files.back().line_count;
}

// Forward declarations.
static void SingleLineComment(char **ret_string);
static void MultilineCommentOrString(char *prefix, char **ret_string);
static bool HandleEndOfFile();

%}

%option prefix="lua_lexxer_"
%option outfile="lex.yy.c"
%option noyywrap
%x special

%%

"--@"					{
					  if (expand_special_tokens) {
					    BEGIN(special);
					  } else {
					    SingleLineComment(yylval);
					    TOKEN(SPECIAL);
					  }
					}
<special>const				{ TOKEN(SPECIAL_CONST); }
<special>number				{ TOKEN(SPECIAL_NUMBER); }
<special>";"				{ TOKEN(';'); }
<special>[ \t\r]			{ /* Ignore whitespace in one line */ }
<special>"--"				{ SingleLineComment(0); BEGIN(INITIAL); }

"--["=*"["				{ MultilineCommentOrString(yytext, 0); }
"--"					{ SingleLineComment(0); }
<*>"\n"					{ files.back().line_count++; BEGIN(INITIAL); }
[ \t\v\f\r]+				{ /* Ignore whitespace */ }

"and"					{ TOKEN(AND); }
"break"					{ TOKEN(BREAK); }
"do"					{ TOKEN(DO); }
"else"					{ TOKEN(ELSE); }
"elseif"				{ TOKEN(ELSEIF); }
"end"					{ TOKEN(END); }
"false"					{ TOKEN(FALSE); }
"for"					{ TOKEN(FOR); }
"function"				{ TOKEN(FUNCTION); }
"if"					{ TOKEN(IF); }
"in"					{ TOKEN(IN); }
"local"					{ TOKEN(LOCAL); }
"nil"					{ TOKEN(NIL); }
"not"					{ TOKEN(NOT); }
"or"					{ TOKEN(OR); }
"repeat"				{ TOKEN(REPEAT); }
"return"				{ TOKEN(RETURN); }
"then"					{ TOKEN(THEN); }
"true"					{ TOKEN(TRUE); }
"until"					{ TOKEN(UNTIL); }
"while"					{ TOKEN(WHILE); }
".."					{ TOKEN(CONCAT); }
"..."					{ TOKEN(ELLIPSES); }
"=="					{ TOKEN(EQ); }
">="					{ TOKEN(GE); }
"<="					{ TOKEN(LE); }
"~="					{ TOKEN(NE); }

[a-zA-Z_][a-zA-Z_0-9]*			{ *yylval = strdup(yytext); TOKEN(IDENTIFIER); }

0[xX][a-fA-F0-9]+			|
[0-9]+([Ee][+-]?[0-9]+)?		|
[0-9]*"."[0-9]+([Ee][+-]?[0-9]+)?	|
[0-9]+"."[0-9]*([Ee][+-]?[0-9]+)?	{ *yylval = strdup(yytext); TOKEN(NUMBER); }

\"(\\.|\\\n|[^\\"])*\"			|
\'(\\.|\\\n|[^\\'])*\'			{ *yylval = strdup(yytext); TOKEN(STRING); }
"["=*"["				{ MultilineCommentOrString(yytext, yylval); TOKEN(STRING); }

[+\-*/%^#<>=(){}\[\]:,.]		{ TOKEN(yytext[0]); }

";"					{
					  if (ignore_first_semicolon) {
					    ignore_first_semicolon = false;
					  } else {
					    TOKEN(';');
					  }
					}

@[^:]+:[0-9]+				{
					  // A special filename:line_number marker that is not part
					  // of regular Lua syntax.
					  char *colon = strchr(yytext, ':');
					  *colon = 0;
					  files.back().marker_filename = strdup(yytext + 1);
					  files.back().marker_line_number = atoi(colon + 1);
					}

<*>.					{ PanicWithBadChar(yytext[0]); }

<<EOF>>					{ if (HandleEndOfFile()) return 0; }

%%

// These functions are defined down here because they need to call yyinput() or
// other lexxer functions.

// Skip a single line comment in the lexxer input file. If ret_string is
// nonzero then save the comment line in the string.
static void SingleLineComment(char **ret_string) {
  std::string buffer;
  if (ret_string) buffer += " --@";
  for(;;) {
    int c = yyinput();
    if (c == '\n') {
      files.back().line_count++;
    } else if (ret_string) {
      buffer.push_back(c);
    }
    if (c == '\n' || c == EOF) {
      if (ret_string) {
        *ret_string = strdup(buffer.c_str());
      }
      return;
    }
  }
}

// This scans the lexxer input file until it finds ]===] where the number of '='
// characters to match is the number present in the prefix. If ret_string is
// nonzero then it is set to a string containing the prefix plus the scanned
// characters.
static void MultilineCommentOrString(char *prefix, char **ret_string) {
  int equals_to_match = CountChars(prefix, '=');
  int startline = files.back().line_count;
  int state = 0;
  std::string buffer;
  if (ret_string) buffer += prefix;
  for (;;) {
    int c = yyinput();
    if (ret_string) buffer.push_back(c);
    if (c == EOF) {
      files.back().line_count = startline;
      Panic("Unclosed long comment or string, at %s:%d",
            files.back().filename, files.back().line_count);
    }
    if (c == '\n') files.back().line_count++;

    if (state == equals_to_match+1) {
      if (c == ']') {
        if (ret_string) {
          CHECK(int(buffer.length()) >= equals_to_match+2);
          *ret_string = strdup(buffer.c_str());
        }
        return;
      }
      state = 0;
    } else if (state == 0) {
      if (c == ']') state = 1;
    } else {
      if (c == '=') state++;
      else if (c == ']') state = 1;
      else state = 0;
    }
  }
}

static bool HandleEndOfFile() {
  if (files.size() <= 1) {	
    return true;
  } else {
    files.pop_back();
    yy_delete_buffer(YY_CURRENT_BUFFER);
    yy_switch_to_buffer(files.back().buffer);

    // The expanded "dofile 'filename'" statement might be followed by a
    // semicolon. If we see it, ignore it, since it wont be syntactically
    // valid after the expanded code.
    ignore_first_semicolon = true;

    return false;
  }
}
