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

#ifndef __UTIL_H__
#define __UTIL_H__

#include <stdio.h>

#define CHECK(cond) if(!(cond)) { Panic("Check failed at %s:%d : " #cond, __FILE__, __LINE__); }

// Global variables and functions for the lexxer.
extern FILE *lua_lexxer_in;
void InitializeLexxer(const char *filename, bool _expand_special_tokens);
void FinalizeLexxer();
void LexxerPushFile(const char *filename);
const char *LexxerFilename();
int LexxerLinecount();

// Location type for parsers and lexxer.
#define YYLTYPE_IS_DECLARED
struct YYLTYPE {
  int line;
  const char *filename;
};
#define YYLLOC_DEFAULT(Current, Rhs, N) { \
  if (N) { \
    (Current).line = (Rhs)[1].line; \
    (Current).filename = (Rhs)[1].filename; \
  } else { \
    (Current).line = (Rhs)[0].line; \
    (Current).filename = (Rhs)[0].filename; \
  } \
}

// Error handling.
void Panic(const char *msg, ...)
  __attribute__((format (printf, 1, 2), noreturn));

#endif
