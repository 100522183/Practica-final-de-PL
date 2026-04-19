%{
/*
 * Traductor LISP -> FORTH (Backend)
 * Procesadores del Lenguaje 2025-2026
 * 
 * Nombre: [VUESTROS NOMBRES]
 * Grupo: [VUESTRO GRUPO]
 * Emails: [email1] [email2]
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern int yylex();
extern int yyparse();

void yyerror(const char *s);

/* Variables globales */
int inside_main = 0;

int peekchar();
%}

%union {
    int num;
    char *str;
    struct {
        char *code;
        int is_boolean;
    } expr;
}

%token <num> NUMBER
%token <str> IDENTIFIER STRING
%token 
    LPAREN RPAREN
    T_DEFUN T_SETQ T_IF T_WHILE T_RETURN
    T_PRINT T_PRINTLN
    T_AND T_OR T_NOT
    T_EQ T_NE T_LT T_LE T_GT T_GE
    T_PLUS T_MINUS T_MUL T_DIV T_MOD
    T_MAIN

%type <expr> expr list sexpr function_def setq_expr if_expr while_expr print_expr arithmetic_expr relational_expr logical_expr

%start program

%%

program:
      /* vacío */
    | program sexpr
    | program function_def
;

function_def:
    LPAREN T_DEFUN LPAREN IDENTIFIER RPAREN expr RPAREN {
        if (strcmp($4, "main") == 0) {
            fprintf(stdout, ": main %s ;\n", $6.code);
        }
        free($4);
        free($6.code);
    }
    | LPAREN T_DEFUN LPAREN IDENTIFIER list RPAREN expr RPAREN {
        if (strcmp($4, "main") == 0) {
            fprintf(stdout, ": main %s ;\n", $7.code);
        }
        free($4);
        free($7.code);
    }
;

sexpr:
    expr {
        free($1.code);
    }
    | LPAREN T_MAIN RPAREN {
        /* Directiva //@ (main) - ignorar */
    }
;

expr:
    NUMBER {
        $$.code = malloc(32);
        sprintf($$.code, "%d ", $1);
        $$.is_boolean = 0;
    }
    | IDENTIFIER {
        $$.code = malloc(strlen($1) + 5);
        sprintf($$.code, "%s @ ", $1);
        $$.is_boolean = 0;
        free($1);
    }
    | STRING {
        $$.code = malloc(strlen($1) + 10);
        char *s = $1;
        int len = strlen(s);
        if (s[0] == '"' && s[len-1] == '"') {
            s[len-1] = '\0';
            s++;
        }
        sprintf($$.code, ".\" %s\" ", s);
        $$.is_boolean = 0;
        free($1);
    }
    | setq_expr { $$ = $1; }
    | if_expr { $$ = $1; }
    | while_expr { $$ = $1; }
    | print_expr { $$ = $1; }
    | arithmetic_expr { $$ = $1; }
    | relational_expr { $$ = $1; }
    | logical_expr { $$ = $1; }
    | LPAREN expr RPAREN {
        $$ = $2;
    }
;

setq_expr:
    LPAREN T_SETQ IDENTIFIER expr RPAREN {
        $$.code = malloc(strlen($3) + strlen($4.code) + 20);
        sprintf($$.code, "%s%s ! ", $4.code, $3);
        $$.is_boolean = 0;
        free($3);
        free($4.code);
    }
;

if_expr:
    LPAREN T_IF expr expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + strlen($5.code) + 50);
        sprintf($$.code, "%s if %s else %s then ", $3.code, $4.code, $5.code);
        $$.is_boolean = 0;
        free($3.code);
        free($4.code);
        free($5.code);
    }
    | LPAREN T_IF expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 30);
        sprintf($$.code, "%s if %s then ", $3.code, $4.code);
        $$.is_boolean = 0;
        free($3.code);
        free($4.code);
    }
;

while_expr:
    LPAREN T_WHILE expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 50);
        sprintf($$.code, "begin %s while %s repeat ", $3.code, $4.code);
        $$.is_boolean = 0;
        free($3.code);
        free($4.code);
    }
;

print_expr:
    LPAREN T_PRINT expr RPAREN {
        $$.code = malloc(strlen($3.code) + 10);
        if ($3.code[0] == '.' && $3.code[1] == '"') {
            sprintf($$.code, "%s", $3.code);
        } else {
            sprintf($$.code, "%s . ", $3.code);
        }
        $$.is_boolean = 0;
        free($3.code);
    }
    | LPAREN T_PRINTLN expr RPAREN {
        $$.code = malloc(strlen($3.code) + 20);
        if ($3.code[0] == '.' && $3.code[1] == '"') {
            sprintf($$.code, "%s cr ", $3.code);
        } else {
            sprintf($$.code, "%s . cr ", $3.code);
        }
        $$.is_boolean = 0;
        free($3.code);
    }
;

arithmetic_expr:
    LPAREN T_PLUS expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 10);
        sprintf($$.code, "%s %s + ", $3.code, $4.code);
        $$.is_boolean = 0;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_MINUS expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 10);
        sprintf($$.code, "%s %s - ", $3.code, $4.code);
        $$.is_boolean = 0;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_MUL expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 10);
        sprintf($$.code, "%s %s * ", $3.code, $4.code);
        $$.is_boolean = 0;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_DIV expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 10);
        sprintf($$.code, "%s %s / ", $3.code, $4.code);
        $$.is_boolean = 0;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_MOD expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 10);
        sprintf($$.code, "%s %s mod ", $3.code, $4.code);
        $$.is_boolean = 0;
        free($3.code);
        free($4.code);
    }
;

relational_expr:
    LPAREN T_EQ expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 10);
        sprintf($$.code, "%s %s = ", $3.code, $4.code);
        $$.is_boolean = 1;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_NE expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 15);
        sprintf($$.code, "%s %s <> ", $3.code, $4.code);
        $$.is_boolean = 1;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_LT expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 10);
        sprintf($$.code, "%s %s < ", $3.code, $4.code);
        $$.is_boolean = 1;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_LE expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 10);
        sprintf($$.code, "%s %s <= ", $3.code, $4.code);
        $$.is_boolean = 1;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_GT expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 10);
        sprintf($$.code, "%s %s > ", $3.code, $4.code);
        $$.is_boolean = 1;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_GE expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 10);
        sprintf($$.code, "%s %s >= ", $3.code, $4.code);
        $$.is_boolean = 1;
        free($3.code);
        free($4.code);
    }
;

logical_expr:
    LPAREN T_AND expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 15);
        sprintf($$.code, "%s %s and ", $3.code, $4.code);
        $$.is_boolean = 1;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_OR expr expr RPAREN {
        $$.code = malloc(strlen($3.code) + strlen($4.code) + 15);
        sprintf($$.code, "%s %s or ", $3.code, $4.code);
        $$.is_boolean = 1;
        free($3.code);
        free($4.code);
    }
    | LPAREN T_NOT expr RPAREN {
        $$.code = malloc(strlen($3.code) + 15);
        sprintf($$.code, "%s 0= ", $3.code);
        $$.is_boolean = 1;
        free($3.code);
    }
;

list:
    expr
    | list expr
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int yywrap() {
    return 1;
}

int peekchar() {
    int c = getchar();
    ungetc(c, stdin);
    return c;
}

int yylex() {
    int c;
    
    while ((c = getchar()) == ' ' || c == '\t');
    
    if (c == EOF) return 0;
    
    if (c == '(') return LPAREN;
    if (c == ')') return RPAREN;
    
    if (c == '"') {
        char buffer[1024];
        int i = 0;
        buffer[i++] = '"';
        while ((c = getchar()) != '"' && c != EOF && i < 1022) {
            buffer[i++] = c;
        }
        buffer[i++] = '"';
        buffer[i] = '\0';
        yylval.str = strdup(buffer);
        return STRING;
    }
    
    if (isdigit(c) || (c == '-' && isdigit(peekchar()))) {
        int num = 0;
        int sign = 1;
        if (c == '-') {
            sign = -1;
            c = getchar();
        }
        while (isdigit(c)) {
            num = num * 10 + (c - '0');
            c = getchar();
        }
        ungetc(c, stdin);
        yylval.num = num * sign;
        return NUMBER;
    }
    
    if (isalpha(c) || c == '=' || c == '<' || c == '>' || c == '!' || c == '&' || c == '|') {
        char buffer[256];
        int i = 0;
        while (isalnum(c) || c == '=' || c == '<' || c == '>' || c == '!' || c == '&' || c == '|' || c == '?') {
            buffer[i++] = c;
            c = getchar();
        }
        buffer[i] = '\0';
        ungetc(c, stdin);
        
        yylval.str = strdup(buffer);
        
        if (strcmp(buffer, "defun") == 0) return T_DEFUN;
        if (strcmp(buffer, "setq") == 0) return T_SETQ;
        if (strcmp(buffer, "if") == 0) return T_IF;
        if (strcmp(buffer, "while") == 0) return T_WHILE;
        if (strcmp(buffer, "return") == 0) return T_RETURN;
        if (strcmp(buffer, "print") == 0) return T_PRINT;
        if (strcmp(buffer, "println") == 0) return T_PRINTLN;
        if (strcmp(buffer, "and") == 0) return T_AND;
        if (strcmp(buffer, "or") == 0) return T_OR;
        if (strcmp(buffer, "not") == 0) return T_NOT;
        if (strcmp(buffer, "=") == 0) return T_EQ;
        if (strcmp(buffer, "/=") == 0 || strcmp(buffer, "!=") == 0) return T_NE;
        if (strcmp(buffer, "<") == 0) return T_LT;
        if (strcmp(buffer, "<=") == 0) return T_LE;
        if (strcmp(buffer, ">") == 0) return T_GT;
        if (strcmp(buffer, ">=") == 0) return T_GE;
        if (strcmp(buffer, "+") == 0) return T_PLUS;
        if (strcmp(buffer, "-") == 0) return T_MINUS;
        if (strcmp(buffer, "*") == 0) return T_MUL;
        if (strcmp(buffer, "/") == 0) return T_DIV;
        if (strcmp(buffer, "mod") == 0) return T_MOD;
        if (strcmp(buffer, "main") == 0) return T_MAIN;
        
        return IDENTIFIER;
    }
    
    return c;
}

int main(int argc, char **argv) {
    /* No usamos yyin, simplemente leemos de stdin */
    /* Si se pasa un argumento, redirigimos stdin */
    if (argc > 1) {
        if (freopen(argv[1], "r", stdin) == NULL) {
            perror(argv[1]);
            return 1;
        }
    }
    
    yyparse();
    
    return 0;
}