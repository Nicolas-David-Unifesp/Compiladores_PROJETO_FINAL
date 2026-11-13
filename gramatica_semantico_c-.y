%{
#include "arvore.h"
#include <stdio.h>
int yylex(void);
void yyerror(const char *s);
extern int yylineno;
extern char lexema_atual[];
int erros_sintaticos;
%}
/* Valores transportados pelos tokens e nao terminais.
   $1, $2... acessam valores da producao; $$ define o valor da reducao.
   Os tokens ID/NUM recebem seus valores de yylval, preenchido no Flex. */
%union {
    const char *texto;
    long numero;
    Tipo tipo;
    No *no;
    int operador;
}
/* Habilita @n.first_line para preservar a linha de origem em cada no. */
%locations
%token <texto> ID
%token <numero> NUM
%token SOM SUB MUL DIV IGL PEV APR FPR ACH FCH ACO FCO
%token IF ELSE INT VOID WHILE RETURN LE LT GT GE EQ NE VIR
/* O ELSE tem precedencia maior: associa-se ao IF mais proximo
   que ainda nao possui ELSE (resolve o conflito do dangling else). */
%nonassoc IF_SEM_ELSE
%nonassoc ELSE
/* Cada %type seleciona um campo da %union para o nao terminal. */
%type <tipo> tipo_especificador
%type <operador> relacional soma mult
%type <no> programa declaracao_lista declaracao var_declaracao fun_declaracao
%type <no> params param_lista param composto_decl local_declaracoes statement_lista
%type <no> statement expressao_decl selecao_decl iteracao_decl retorno_decl
%type <no> expressao var simples_expressao soma_expressao termo fator ativacao args arg_lista
/* Libera subarvores descartadas durante recuperacao ou aborto.
   declaracao_lista fica de fora: sua memoria pertence a raiz e sera
   liberada pelo main, preservando declaracoes completas apos um erro. */
%destructor { liberar_arvore($$); } programa declaracao var_declaracao fun_declaracao params param_lista param composto_decl local_declaracoes statement_lista statement expressao_decl selecao_decl iteracao_decl retorno_decl expressao var simples_expressao soma_expressao termo fator ativacao args arg_lista
%start programa
%%
/* A gramatica constroi a AST; a verificacao de tipos e escopos acontece
   depois, em analisar_semantica. NULL em $$ evita liberar a raiz no aceite. */
programa : declaracao_lista { raiz = $1; $$ = NULL; } ;
/* A lista de declaracoes completas pertence a raiz, inclusive se o parser abortar.
   Os demais valores na pilha continuam sendo liberados pelos destructors. */
declaracao_lista : declaracao_lista declaracao { raiz = $$ = juntar($1, $2); }
                 | declaracao { raiz = $$ = $1; } ;
/* error e um simbolo especial do Bison: descarta a declaracao invalida
   ate o ponto e virgula. yyerrok encerra o estado de recuperacao.
   O contador permanece incrementado, portanto o arquivo ainda sera rejeitado. */
declaracao : var_declaracao { $$ = $1; } | fun_declaracao { $$ = $1; }
           | error PEV { $$ = NULL; yyerrok; } ;
/* DECL guarda nome/tipo. Em vetores, filhos[0] representa o tamanho.
   Aceitar VOID aqui permite relatar void x; como erro SEMANTICO. */
var_declaracao : tipo_especificador ID PEV {
    $$ = novo_no(DECL, @2.first_line); $$->nome = $2; $$->tipo = $1;
} | tipo_especificador ID ACO NUM FCO PEV {
    $$ = novo_no(DECL, @2.first_line); $$->nome = $2; $$->tipo = $1;
    $$->vetor = 1; $$->filhos[0] = numero($4, @4.first_line);
} ;
tipo_especificador : INT { $$ = T_INT; } | VOID { $$ = T_VOID; } ;
/* FUNCAO: filhos[0] = lista de parametros; filhos[1] = corpo.
   As listas usam proximo, preservando a ordem escrita no programa. */
fun_declaracao : tipo_especificador ID APR params FPR composto_decl {
    $$ = novo_no(FUNCAO, @2.first_line); $$->nome = $2; $$->tipo = $1;
    $$->filhos[0] = $4; $$->filhos[1] = $6;
} ;
/* (void) representa ausencia de parametros (NULL), nao um parametro void.
   Ja void x e um parametro nomeado, rejeitado na analise semantica. */
params : param_lista { $$ = $1; } | VOID { $$ = NULL; } ;
param_lista : param_lista VIR param { $$ = juntar($1, $3); } | param { $$ = $1; } ;
param : tipo_especificador ID {
    $$ = novo_no(PARAM, @2.first_line); $$->tipo = $1; $$->nome = $2;
} | tipo_especificador ID ACO FCO {
    $$ = novo_no(PARAM, @2.first_line); $$->tipo = $1; $$->nome = $2; $$->vetor = 1;
} ;
/* BLOCO: filhos[0] = declaracoes locais; filhos[1] = comandos.
   Criar o no nao cria o escopo: semantico.c faz isso ao percorrer a AST. */
composto_decl : ACH local_declaracoes statement_lista FCH {
    $$ = novo_no(BLOCO, @1.first_line); $$->filhos[0] = $2; $$->filhos[1] = $3;
} ;
/* Uma declaracao local malformada e descartada ate ;, preservando
   a lista anterior. Lista vazia e representada por NULL. */
local_declaracoes : local_declaracoes var_declaracao { $$ = juntar($1, $2); }
                  | local_declaracoes tipo_especificador error PEV { $$ = $1; yyerrok; }
                  | /* vazio */ { $$ = NULL; } ;
statement_lista : statement_lista statement { $$ = juntar($1, $2); } | /* vazio */ { $$ = NULL; } ;
/* Um comando recuperado ganha ERRO_NO para aparecer na impressao
   da arvore parcial; o analisador semantico ignora esse marcador. */
statement : expressao_decl { $$ = $1; } | composto_decl { $$ = $1; }
          | selecao_decl { $$ = $1; } | iteracao_decl { $$ = $1; } | retorno_decl { $$ = $1; }
          | error PEV { $$ = novo_no(ERRO_NO, @1.first_line); yyerrok; } ;
expressao_decl : expressao PEV { $$ = novo_no(EXPR, @1.first_line); $$->filhos[0] = $1; }
               | PEV { $$ = novo_no(EXPR, @1.first_line); } ;
/* IF: filhos[0] = condicao; filhos[1] = entao; filhos[2] = senao.
   Sem ELSE, o terceiro filho permanece NULL (novo_no inicializa com zeros). */
selecao_decl : IF APR expressao FPR statement %prec IF_SEM_ELSE {
    $$ = novo_no(SE, @1.first_line); $$->filhos[0] = $3; $$->filhos[1] = $5;
} | IF APR expressao FPR statement ELSE statement {
    $$ = novo_no(SE, @1.first_line); $$->filhos[0] = $3; $$->filhos[1] = $5; $$->filhos[2] = $7;
} ;
/* WHILE: filhos[0] = condicao; filhos[1] = corpo. */
iteracao_decl : WHILE APR expressao FPR statement {
    $$ = novo_no(ENQUANTO, @1.first_line); $$->filhos[0] = $3; $$->filhos[1] = $5;
} ;
/* RETURN sem expressao deixa filhos[0] NULL. O tipo de retorno
   so pode ser validado depois de identificar a funcao que contem este no. */
retorno_decl : RETURN PEV { $$ = novo_no(RETORNO, @1.first_line); }
             | RETURN expressao PEV { $$ = novo_no(RETORNO, @1.first_line); $$->filhos[0] = $2; } ;
/* ATRIB: filhos[0] = destino; filhos[1] = valor.
   A recursao a direita permite a = b = 1. O destino deve ser uma var. */
expressao : var IGL expressao {
    $$ = novo_no(ATRIB, @2.first_line); $$->filhos[0] = $1; $$->filhos[1] = $3;
} | simples_expressao { $$ = $1; } ;
/* ID_NO com filhos[0] representa um acesso indexado; sem filho, e
   uma referencia simples. A tabela determina se o nome e escalar ou vetor. */
var : ID { $$ = novo_no(ID_NO, @1.first_line); $$->nome = $1; }
    | ID ACO expressao FCO { $$ = novo_no(ID_NO, @1.first_line); $$->nome = $1; $$->filhos[0] = $3; } ;
/* A hierarquia expressao/soma/termo/fator define a precedencia:
   multiplicacao e divisao agrupam antes de soma, depois relacionais.
   OP usa filhos[0]/[1] como operandos esquerdo/direito. */
simples_expressao : soma_expressao relacional soma_expressao {
    $$ = novo_no(OP, @2.first_line); $$->operador = $2; $$->filhos[0] = $1; $$->filhos[1] = $3;
} | soma_expressao { $$ = $1; } ;
/* Codigos internos: l <=, g >=, e ==, n !=. */
relacional : LE { $$ = 'l'; } | LT { $$ = '<'; } | GT { $$ = '>'; }
           | GE { $$ = 'g'; } | EQ { $$ = 'e'; } | NE { $$ = 'n'; } ;
soma_expressao : soma_expressao soma termo {
    $$ = novo_no(OP, @2.first_line); $$->operador = $2; $$->filhos[0] = $1; $$->filhos[1] = $3;
} | termo { $$ = $1; } ;
soma : SOM { $$ = '+'; } | SUB { $$ = '-'; } ;
termo : termo mult fator {
    $$ = novo_no(OP, @2.first_line); $$->operador = $2; $$->filhos[0] = $1; $$->filhos[1] = $3;
} | fator { $$ = $1; } ;
mult : MUL { $$ = '*'; } | DIV { $$ = '/'; } ;
/* Parenteses apenas agrupam: a AST reutiliza o no da expressao. */
fator : APR expressao FPR { $$ = $2; } | var { $$ = $1; }
      | ativacao { $$ = $1; } | NUM { $$ = numero($1, @1.first_line); } ;
/* CHAMADA guarda o nome e a lista de argumentos em filhos[0].
   Existencia da funcao e compatibilidade da assinatura sao semanticas. */
ativacao : ID APR args FPR { $$ = novo_no(CHAMADA, @1.first_line); $$->nome = $1; $$->filhos[0] = $3; } ;
args : arg_lista { $$ = $1; } | /* vazio */ { $$ = NULL; } ;
arg_lista : arg_lista VIR expressao { $$ = juntar($1, $3); } | expressao { $$ = $1; } ;
%%
/* Recuperar o parser nao zera este contador; o arquivo continua invalido. */
void yyerror(const char *s) {
    ++erros_sintaticos;
    fprintf(stderr, "ERRO SINTATICO (linha %d): %s; encontrado: %s\n", yylineno, s, lexema_atual);
}
