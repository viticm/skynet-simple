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

// Read lua source from a file and output a simplified equivalent that is easier
// for other tools to parse. If the -luac flag is given the output will generate
// identical Lua instructions when passed to 'luac -l'.

#include <stdio.h>
#include <cstdlib>
#include <cstring>
#include "util.h"
#include "lua_simplifier.h"

// Command line flags.
bool flag_luac_mode = false;
bool flag_emit_lines = false;

// Global state for the parser.
int lua_parser_indent = 0;
std::vector<int> array_index;

int lua_parser_lex(char **yylval_param, YYLTYPE *yylloc_param) {
  return lua_lexxer_lex(yylval_param, yylloc_param);
}

void Usage() {
  fprintf(stderr, "Usage: lua_simplifier [-luac] [-emit_lines] <filename.lua>\n");
  exit(1);
}

int main(int argc, char **argv) {
  for (int i = 1; i < argc-1; i++) {
    if (strcmp(argv[i], "-luac") == 0) {
      flag_luac_mode = true;
    } else if (strcmp(argv[i], "-emit_lines") == 0) {
      flag_emit_lines = true;
    } else {
      Usage();
    }
  }

  if (argc < 2 || argv[argc-1][0] == '-') Usage();
  InitializeLexxer(argv[argc-1], false);
  lua_parser_indent = -1;
  array_index.clear();
  lua_parser_parse();
  FinalizeLexxer();

  return 0;
}
