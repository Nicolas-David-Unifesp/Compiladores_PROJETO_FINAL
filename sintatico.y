%{
#include <stdio.h>
#include <stdlib.h>

/* Protótipos obrigatórios para o Bison */
int yylex(void);
void yyerror(const char *s);//Define a função yyerror para tratar erros sintáticos

extern int yylineno; /* Caso precise reportar linhas em erros sintáticos */
extern char lexema_atual[];
int erros_sintaticos = 0;
%}

/* DEFINIÇÃO DE TOKENS CONFORME O SEU FLEX */
%token NUM "número" ID "identificador"
%token SOM "'+'" SUB "'-'" MUL "'*'" DIV "'/'" IGL "'='"
%token PEV "';'" APR "'('" FPR "')'" ACH "'{'" FCH "'}'"
%token ACO "'['" FCO "']'" IF "'if'" ELSE "'else'"
%token INT "'int'" VOID "'void'" WHILE "'while'" RETURN "'return'"
%token LE "'<='" LT "'<'" GT "'>'" GE "'>='" EQ "'=='" NE "'!='" VIR "','"
%define parse.error detailed
%nonassoc IF_SEM_ELSE
%nonassoc ELSE

%%

/* 1. programa -> declaração-lista */
programa : declaracao_lista
         ;

/* 2. declaração-lista -> declaração-lista declaração | declaração */
declaracao_lista : declaracao_lista declaracao
                 | declaracao
                 | declaracao_lista error PEV { yyerrok; }
                 ;

/* 3. declaração -> var-declaração | fun-declaração */
declaracao : var_declaracao
           | fun_declaracao
           ;

/* 4. var-declaração -> tipo-especificador ID ; | tipo-especificador ID [ NUM ] ; */
var_declaracao : tipo_especificador ID PEV
               | tipo_especificador ID ACO NUM FCO PEV
               ;

/* 5. tipo-especificador -> int | void */
tipo_especificador : INT
                   | VOID
                   ;

/* 6. fun-declaração -> tipo-especificador ID ( params ) composto-decl */
fun_declaracao : tipo_especificador ID APR params FPR composto_decl
               ;

/* 7. params -> param-lista | void */
params : param_lista
       | VOID
       ;

/* 8. param-lista -> param-lista , param | param */
param_lista : param_lista VIR param
            | param
            ;

/* 9. param -> tipo-especificador ID | tipo-especificador ID [ ] */
param : tipo_especificador ID
      | tipo_especificador ID ACO FCO
      ;

/* 10. composto-decl -> { local-declarações statement-lista } */
composto_decl : ACH local_declaracoes statement_lista FCH
              ;

/* 11. local-declarações -> local-declarações var-declaração | vazio */
local_declaracoes : local_declaracoes var_declaracao
                  | /* vazio */
                  | local_declaracoes tipo_especificador error PEV { yyerrok; }
                  ;

/* 12. statement-lista -> statement-lista statement | vazio */
statement_lista : statement_lista statement
                | /* vazio */
                ;

/* 13. statement -> expressão-decl | composto-decl | seleção-decl | iteração-decl | retorno-decl */
statement : expressao_decl
          | composto_decl
          | selecao_decl
          | iteracao_decl
          | retorno_decl
          | error PEV { yyerrok; }
          ;

/* 14. expressão-decl -> expressão ; | ; */
expressao_decl : expressao PEV
               | PEV
               ;

/* 15. seleção-decl -> if ( expressão ) statement | if ( expressão ) statement else statement */
selecao_decl: IF APR expressao FPR statement %prec IF_SEM_ELSE
    | IF APR expressao FPR statement ELSE statement
    ;

/* 16. iteração-decl -> while ( expressão ) statement */
iteracao_decl : WHILE APR expressao FPR statement
              ;

/* 17. retorno-decl -> return ; | return expressão ; */
retorno_decl : RETURN PEV
             | RETURN expressao PEV
             ;

/* 18. expressão -> var = expressão | simples-expressão */
expressao : var IGL expressao
          | simples_expressao
          ;

/* 19. var -> ID | ID [ expressão ] */
var : ID
    | ID ACO expressao FCO
    ;

/* 20. simples-expressão -> soma-expressão relacional soma-expressão | soma-expressão */
simples_expressao : soma_expressao relacional soma_expressao
                  | soma_expressao
                  ;

/* 21. relacional -> <= | < | > | >= | == | != */
relacional : LE
           | LT
           | GT
           | GE
           | EQ
           | NE
           ;

/* 22. soma-expressão -> soma-expressão soma termo | termo */
soma_expressao : soma_expressao soma termo
               | termo
               ;

/* 23. soma -> + | - */
soma : SOM
     | SUB
     ;

/* 24. termo -> termo mult fator | fator */
termo : termo mult fator
      | fator
      ;

/* 25. mult -> * | / */
mult : MUL
     | DIV
     ;

/* 26. fator -> ( expressão ) | var | ativação | NUM */
fator : APR expressao FPR
      | var
      | ativacao
      | NUM
      ;

/* 27. ativação -> ID ( args ) */
ativacao : ID APR args FPR
         ;

/* 28. args -> arg-lista | vazio */
args : arg_lista
     | /* vazio */
     ;

/* 29. arg-lista -> arg-lista , expressão | expressão */
arg_lista : arg_lista VIR expressao
          | expressao
          ;

%%

/* Função obrigatória para tratamento de erros sintáticos */
void yyerror(const char *s) {
    erros_sintaticos++;
    fprintf(stderr, "ERRO SINTÁTICO: %s; encontrado: %s LINHA: %d\n",
            s, lexema_atual, yylineno);
}
