%option noinput nounput noyywrap yylineno case-insensitive

%{
#include <string.h>

#include "parse.h"
#include "shared.h"

char directive_indent[64];
int directive_lineno;
static char line_indent[sizeof directive_indent];
static int line_indent_len;
%}

PREFIX "mal:"
ID     [[:alpha:]_][[:alnum:]_]*
STRING \"(\\.|[^\\"\n])*\"
CHAR   '(\\.|[^\\'\n])*'
SP     [ \t]

%x DIRECTIVE COMMENT

%%

^{SP}+ {
        line_indent_len = yyleng < (int) sizeof line_indent - 1 ? yyleng : (int) sizeof line_indent - 1;
        memcpy(line_indent, yytext, line_indent_len);
        ECHO;
}

"//"{SP}*{PREFIX}.* {
        ECHO;
        yyless(strchr(yytext, ':') + 1 - yytext);
        memcpy(directive_indent, line_indent, line_indent_len);
        directive_indent[line_indent_len] = '\0';
        directive_lineno = yylineno;
        BEGIN(DIRECTIVE);
}

"//".*                  { ECHO; }
"/*"                    { ECHO; BEGIN(COMMENT); }
{STRING}                { ECHO; }
{CHAR}                  { ECHO; }
\n                      { line_indent_len = 0; ECHO; }
[^/"' \t\n]+            { ECHO; }
{SP}+                   { ECHO; }
.                       { ECHO; }

<COMMENT>"*/"           { ECHO; BEGIN(INITIAL); }
<COMMENT>\n             { line_indent_len = 0; ECHO; }
<COMMENT>[^*\n]+|"*"    { ECHO; }

<DIRECTIVE>[ \t\r]+     { ; }
<DIRECTIVE>"loop"       { return TOK_LOOP; }
<DIRECTIVE>"acc"        { return TOK_ACC; }
<DIRECTIVE>"single"     { return TOK_SINGLE; }
<DIRECTIVE>"check"      { return TOK_CHECK; }
<DIRECTIVE>"decide"     { return TOK_DECIDE; }
<DIRECTIVE>"->"         { return TOK_ARROW; }
<DIRECTIVE>{ID}         { yylval.str = strdup(yytext); return TOK_ID; }
<DIRECTIVE>{STRING}     { yylval.str = strdup(yytext); return TOK_STRING; }
<DIRECTIVE>\n           { line_indent_len = 0; BEGIN(INITIAL); return TOK_EOL; }
<DIRECTIVE><<EOF>>      { BEGIN(INITIAL); return TOK_EOL; }
<DIRECTIVE>.            { return yytext[0]; }

%%
