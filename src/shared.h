#define VMAJ 0
#define VMIN 1
#define VPAT 0

/* Set by the lexer when it finds a directive, used by the parser to expand it. */
extern char directive_indent[];
extern int directive_lineno;

/* Input file name, for error messages. */
extern const char *input_name;
