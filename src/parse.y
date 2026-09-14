%{
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "lex.h"
#include "shared.h"

void yyerror(const char *msg);
static void emit(const char *fmt, ...);
%}

%define api.token.prefix {TOK_}
%define parse.error detailed

%union {
        char *str;
}

%token LOOP "loop" 
%token ACC "acc" 
%token SINGLE "single" 
%token CHECK "check" 
%token DECIDE "decide"
%token ARROW "->"
%token EOL "end of line"
%token <str> ID "identifier"
%token <str> STRING "string"

%type <str> acc arg

%destructor { free($$); } <str>

%%

/* The lexer copies everything that is not a directive straight to the output,
 * so the grammar only sees directive lines. Each directive prints the code it
 * expands to right below the comment, with the same indentation. */

input
        : %empty
        | input line
        ;

line
        : directive EOL { fputc('\n', yyout); }
        ;

directive
        : LOOP ID ARROW ID acc {
                emit("std::optional<MalFor> malpp_f;");
                emit("auto malpp_max = %s;", $4);
                emit("for (int malpp_i = 0; malpp_i <= 2; malpp_i++)");
                emit("if (malpp_i == 0) { mal_init(); malpp_f.emplace(mal_for(malpp_max, %s, %s));", $2, $4);
                if ($5) fprintf(yyout, " mal_attach_acc(*malpp_f, %s);", $5);
                fprintf(yyout, " }");
                emit("else if (malpp_i == 2) { mal_finalize(); }");
                emit("else");
                free($2), free($4), free($5);
        }
        | "single" {
                emit("if (mal_rank() == 0)");
        }
        | "check" {
                emit("mal_check_for(*malpp_f);");
        }
        | "decide" '=' ID {
                emit("mal_set_decide_resize_func(%s);", $3);
                free($3);
        }
        | "decide" '=' arg ':' arg {
                emit("mal_set_decide_resize_plugin(%s, %s);", $3, $5);
                free($3), free($5);
        }
        ;

acc
        : %empty         { $$ = NULL; }
        | "acc" '=' ID   { $$ = $3; }
        ;

arg
        : ID
        | STRING
        ;

%%

/* Starts a new output line, indented like the directive being expanded. */
static void
emit(const char *fmt, ...)
{
        va_list ap;
        fprintf(yyout, "\n%s", directive_indent);
        va_start(ap, fmt);
        vfprintf(yyout, fmt, ap);
        va_end(ap);
}

void
yyerror(const char *msg)
{
        fprintf(stderr, "%s:%d: %s\n", input_name, directive_lineno, msg);
}
