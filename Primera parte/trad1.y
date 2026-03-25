%{                          // SECCION 1 Declaraciones de C-Yacc

#include <stdio.h>
#include <ctype.h>            // declaraciones para tolower
#include <string.h>           // declaraciones para cadenas
#include <stdlib.h>           // declaraciones para exit ()

#define FF fflush(stdout);    // para forzar la impresion inmediata

int yylex () ;
int yyerror () ;
char *my_malloc (int) ;
char *gen_code (char *) ;
char *int_to_string (int) ;
char *char_to_string (char) ;

char temp [2048] ;
char output_buffer[65536];    // buffer para acumular la salida
int output_pos = 0;           // posición actual en el buffer

// Función para añadir texto al buffer de salida
void emit(char *str) {
    int len = strlen(str);
    if (output_pos + len < 65536) {
        strcpy(output_buffer + output_pos, str);
        output_pos += len;
    }
}

// Abstract Syntax Tree (AST) Node Structure
typedef struct ASTnode t_node ;

struct ASTnode {
    char *op ;
    int type ;
    t_node *left ;
    t_node *right ;
} ;

// Definitions for explicit attributes
typedef struct s_attr {
    int value ;
    char *code ;
    t_node *node ;
} t_attr ;

#define YYSTYPE t_attr

%}

// Definitions for explicit attributes
%token NUMBER        
%token IDENTIF       
%token INTEGER       
%token STRING
%token MAIN          
%token WHILE         
%token IF            
%token ELSE          
%token FOR           
%token RETURN        
%token PRINTF        
%token PUTS          

// Operadores lógicos y de comparación
%token LOGICAL_AND   
%token LOGICAL_OR    
%token EQ            
%token NE            
%token LE            
%token GE            

// Precedencia y asociatividad
%right '='
%left LOGICAL_OR
%left LOGICAL_AND
%left EQ NE
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/' '%'
%right UNARY_SIGN
%right '!'

%%

// Programa completo
programa:      global_declarations function_definitions
             {
                emit("\n");
             }
             ;

global_declarations: 
             | global_declaration global_declarations
             ;

global_declaration: INTEGER global_var_list ';'
             ;

global_var_list: global_var_init
             | global_var_list ',' global_var_init
             ;

global_var_init: IDENTIF
             { 
                sprintf(temp, "(setq %s 0)\n", $1.code);
                emit(temp);
             }
             | IDENTIF '=' NUMBER
             { 
                sprintf(temp, "(setq %s %d)\n", $1.code, $3.value);
                emit(temp);
             }
            ;

function_definitions: function_definition function_definitions
             | 
             ;

function_definition: MAIN '(' ')' block
             { 
                emit("(defun main () ");
             }
             ;

block: '{' statement_list '}'
             { 
                emit(")\n");
             }
             ;

statement_list: 
             | statement statement_list
             ;

statement: local_declaration
             {
                // ya se emite en local_declaration
             }
             | assignment ';'
             { 
                emit($1.code);
             }
             | print_function ';'
             | while_statement
             | if_statement
             | return_statement ';'
             | block
             ;

// Declaraciones locales dentro de funciones
local_declaration: INTEGER local_var_list ';'
             ;

local_var_list: local_var_init
             | local_var_list ',' local_var_init
             ;

local_var_init: IDENTIF
             { 
                sprintf(temp, "(setq %s 0) ", $1.code);
                emit(temp);
             }
             | IDENTIF '=' NUMBER
             { 
                sprintf(temp, "(setq %s %d) ", $1.code, $3.value);
                emit(temp);
             }
             ;

// Asignación simple - sin encadenamiento
assignment: IDENTIF '=' expression
             { 
                sprintf(temp, "(setq %s %s) ", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             ;

expression: comparison_expression
             {
                $$ = $1;
             }
             | expression LOGICAL_AND comparison_expression
             { 
                sprintf(temp, "(and %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             | expression LOGICAL_OR comparison_expression
             { 
                sprintf(temp, "(or %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             ;

comparison_expression: additive_expression
             {
                $$ = $1;
             }
             | additive_expression EQ additive_expression
             { 
                sprintf(temp, "(= %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             | additive_expression NE additive_expression
             { 
                sprintf(temp, "(/= %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             | additive_expression '<' additive_expression
             { 
                sprintf(temp, "(< %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             | additive_expression '>' additive_expression
             { 
                sprintf(temp, "(> %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             | additive_expression LE additive_expression
             { 
                sprintf(temp, "(<= %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             | additive_expression GE additive_expression
             { 
                sprintf(temp, "(>= %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             ;

additive_expression: multiplicative_expression
             {
                $$ = $1;
             }
             | additive_expression '+' multiplicative_expression
             { 
                sprintf(temp, "(+ %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             | additive_expression '-' multiplicative_expression
             { 
                sprintf(temp, "(- %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             ;

multiplicative_expression: unary_expression
             {
                $$ = $1;
             }
             | multiplicative_expression '*' unary_expression
             { 
                sprintf(temp, "(* %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             | multiplicative_expression '/' unary_expression
             { 
                sprintf(temp, "(/ %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             | multiplicative_expression '%' unary_expression
             { 
                sprintf(temp, "(mod %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
             }
             ;

unary_expression: primary_expression
             {
                $$ = $1;
             }
             | '+' unary_expression %prec UNARY_SIGN
             { 
                $$ = $2;
             }
             | '-' unary_expression %prec UNARY_SIGN
             { 
                sprintf(temp, "(- %s)", $2.code);
                $$.code = gen_code(temp);
             }
             | '!' unary_expression
             { 
                sprintf(temp, "(not %s)", $2.code);
                $$.code = gen_code(temp);
             }
             ;

primary_expression: IDENTIF
             { 
                $$.code = gen_code($1.code);
             }
             | NUMBER
             { 
                sprintf(temp, "%d", $1.value);
                $$.code = gen_code(temp);
             }
             | '(' expression ')'
             { 
                $$ = $2;
             }
             ;

// Funciones de impresión
print_function: printf_function
             | puts_function
             ;

printf_function: PRINTF '(' printf_arguments ')'
             {
                // ya se emite en printf_arguments
             }
             ;

printf_arguments: STRING
             { 
                sprintf(temp, "(print %s) ", $1.code);
                emit(temp);
             }
             | STRING ',' printf_arg_list
             { 
                sprintf(temp, "(print %s) ", $1.code);
                emit(temp);
             }
             ;

printf_arg_list: printf_arg
             | printf_arg_list ',' printf_arg
             ;

printf_arg: expression
             { 
                emit($1.code);
                emit(" ");
             }
             ;

puts_function: PUTS '(' puts_argument ')'
             {
                // ya se emite en puts_argument
             }
             ;

puts_argument: STRING
             { 
                sprintf(temp, "(print %s) ", $1.code);
                emit(temp);
             }
             | expression
             { 
                sprintf(temp, "(print %s) ", $1.code);
                emit(temp);
             }
             ;

while_statement: WHILE '(' expression ')' block
             { 
                sprintf(temp, "(loop while %s do ", $3.code);
                emit(temp);
             }
             ;

if_statement: IF '(' expression ')' block
             { 
                sprintf(temp, "(if %s ", $3.code);
                emit(temp);
                emit(") ");
             }
             | IF '(' expression ')' block ELSE block
             { 
                sprintf(temp, "(if %s ", $3.code);
                emit(temp);
                emit(") (else ");
                emit(") ");
             }
             ;

return_statement: RETURN expression
             { 
                sprintf(temp, "(return %s) ", $2.code);
                emit(temp);
             }
             | RETURN
             { 
                emit("(return) ");
             }
             ;

%%

// SECCION 4    Codigo en C

int n_line = 1 ;

int yyerror (char *mensaje)
{
    fprintf (stderr, "%s en la linea %d\n", mensaje, n_line) ;
    return 0;
}

char *int_to_string (int n)
{
    char ltemp [2048] ;
    sprintf (ltemp, "%d", n) ;
    return gen_code (ltemp) ;
}

char *char_to_string (char c)
{
    char ltemp [2048] ;
    sprintf (ltemp, "%c", c) ;
    return gen_code (ltemp) ;
}

char *my_malloc (int nbytes)
{
    char *p ;
    static long int nb = 0;
    static int nv = 0 ;

    p = malloc (nbytes) ;
    if (p == NULL) {
        fprintf (stderr, "No queda memoria para %d bytes mas\n", nbytes) ;
        fprintf (stderr, "Reservados %ld bytes en %d llamadas\n", nb, nv) ;
        exit (0) ;
    }
    nb += (long) nbytes ;
    nv++ ;
    return p ;
}

/***************************************************************************/
/********************** Seccion de Palabras Reservadas *********************/
/***************************************************************************/

typedef struct s_keyword {
    char *name ;
    int token ;
} t_keyword ;

t_keyword keywords [] = {
    "main",        MAIN,
    "int",         INTEGER,
    "while",       WHILE,
    "if",          IF,
    "else",        ELSE,
    "for",         FOR,
    "return",      RETURN,
    "printf",      PRINTF,
    "puts",        PUTS,
    "&&",          LOGICAL_AND,
    "||",          LOGICAL_OR,
    "==",          EQ,
    "!=",          NE,
    "<=",          LE,
    ">=",          GE,
    NULL,          0
} ;

t_keyword *search_keyword (char *symbol_name)
{
    int i ;
    t_keyword *sim ;
    i = 0 ;
    sim = keywords ;
    while (sim [i].name != NULL) {
        if (strcmp (sim [i].name, symbol_name) == 0) {
            return &(sim [i]) ;
        }
        i++ ;
    }
    return NULL ;
}

/***************************************************************************/
/******************* Seccion del Analizador Lexicografico ******************/
/***************************************************************************/

char *gen_code (char *name)
{
    char *p ;
    int l ;
    l = strlen (name)+1 ;
    p = (char *) my_malloc (l) ;
    strcpy (p, name) ;
    return p ;
}

int yylex ()
{
    int i ;
    unsigned char c ;
    unsigned char cc ;
    char ops_expandibles [] = "!<=|>%&/+-*" ;
    char temp_str [256] ;
    t_keyword *symbol ;

    do {
        c = getchar () ;

        if (c == '#') {
            do {
                c = getchar () ;
            } while (c != '\n') ;
        }

        if (c == '/') {
            cc = getchar () ;
            if (cc != '/') {
                ungetc (cc, stdin) ;
            } else {
                c = getchar () ;
                if (c == '@') {
                    do {
                        c = getchar () ;
                        putchar (c) ;
                    } while (c != '\n') ;
                } else {
                    while (c != '\n') {
                        c = getchar () ;
                    }
                }
            }
        } else if (c == '\\') {
            c = getchar () ;
        }
		
        if (c == '\n')
            n_line++ ;

    } while (c == ' ' || c == '\n' || c == 10 || c == 13 || c == '\t') ;

    if (c == '\"') {
        i = 0 ;
        do {
            c = getchar () ;
            temp_str [i++] = c ;
        } while (c != '\"' && i < 255) ;
        if (i == 256) {
            printf ("AVISO: string con mas de 255 caracteres en linea %d\n", n_line) ;
        }
        temp_str [--i] = '\0' ;
        yylval.code = gen_code (temp_str) ;
        return (STRING) ;
    }

    if (c == '.' || (c >= '0' && c <= '9')) {
        ungetc (c, stdin) ;
        scanf ("%d", &yylval.value) ;
        return NUMBER ;
    }

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
        i = 0 ;
        while (((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '_') && i < 255) {
            temp_str [i++] = tolower (c) ;
            c = getchar () ;
        }
        temp_str [i] = '\0' ;
        ungetc (c, stdin) ;

        yylval.code = gen_code (temp_str) ;
        symbol = search_keyword (yylval.code) ;
        if (symbol == NULL) {
            return (IDENTIF) ;
        } else {
            return (symbol->token) ;
        }
    }

    if (strchr (ops_expandibles, c) != NULL) {
        cc = getchar () ;
        sprintf (temp_str, "%c%c", (char) c, (char) cc) ;
        symbol = search_keyword (temp_str) ;
        if (symbol == NULL) {
            ungetc (cc, stdin) ;
            yylval.code = NULL ;
            return (c) ;
        } else {
            yylval.code = gen_code (temp_str) ;
            return (symbol->token) ;
        }
    }

    if (c == EOF || c == 255 || c == 26) {
        return (0) ;
    }

    return c ;
}

int main ()
{
    output_pos = 0;
    output_buffer[0] = '\0';
    yyparse ();
    printf("%s", output_buffer);
    return 0;
}