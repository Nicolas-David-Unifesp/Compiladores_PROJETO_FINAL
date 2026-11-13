%{
/* O Makefile define ANALISE_SEMANTICA para usar o parser com arvore.
   Sem essa definicao, este scanner continua compativel com sintatico.y. */
#ifdef ANALISE_SEMANTICA
#include "arvore.h"
#include "semantico.tab.h"
#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#else
#include "sintatico.tab.h"
#endif
#include <stdio.h>
#include <string.h>

int yyparse(void);
extern int erros_sintaticos;

int erros_lexicos = 0;
int linha_comentario_inicio = 0;
char lexema_atual[256];

/* yylloc leva a linha de cada token ate as acoes @1, @2 etc. do Bison. */
#ifdef ANALISE_SEMANTICA
#define LOCALIZAR yylloc.first_line = yylloc.last_line = yylineno;
#else
#define LOCALIZAR
#endif

/* Executada antes de cada regra: atualiza a localizacao e guarda o texto
   atual para o diagnostico sintatico. Nao e o armazenamento dos nomes da AST. */
#define YY_USER_ACTION \
    LOCALIZAR \
    snprintf(lexema_atual, sizeof(lexema_atual), "%.*s", (int)yyleng, yytext);

/* Relata um erro lexico, indicando a linha e o que está errado */
void erro_lexico(const char *lexema, int linha);
%}

/* nounput/noinput evitam gerar funcoes auxiliares que nao utilizamos. */
%option noyywrap nounput noinput 
/* Para evitar a necessidade de uma função yywrap e 
como estou fazendo rodar um arquivo por execução é mais prático.*/
%option yylineno 
/* Para rastrear o número da linha */

%x COMMENT 
/* Define o estado para comentários */

DIGITO [0-9]
LETRA [a-zA-Z]
%%
  /* NUM transporta o valor numerico em yylval, nao somente o token.
     strtol e INT_MAX detectam constantes fora do intervalo aceito. */
{DIGITO}+ {
#ifdef ANALISE_SEMANTICA
    errno = 0;
    yylval.numero = strtol(yytext, NULL, 10);
    if (errno == ERANGE || yylval.numero > INT_MAX) {
        erro_lexico("inteiro fora do intervalo", yylineno);
        erros_lexicos++;
    }
#endif
    return NUM;
}

  /* Em empates de tamanho, o Flex escolhe a primeira regra. Por isso,
     palavras reservadas devem aparecer antes da regra de identificadores. */
"else"    return ELSE;
"if"      return IF;
"int"     return INT;
"return"  return RETURN;
"void"    return VOID;
"while"   return WHILE;

  /* Internar copia o nome para memoria estavel: yytext e reutilizado pelo Flex.
     Aqui cadastramos o lexema; tipo, escopo e declaracao serao definidos
     em semantico.c, durante o percurso da arvore criada pelo Bison. */
{LETRA}+ {
#ifdef ANALISE_SEMANTICA
    yylval.texto = internar_lexema(yytext);
#endif
    return ID;
}

^\357\273\277 ;/* para ignorar o BOM (Byte Order Mark) */

"+"		  return SOM;
"-"		  return SUB;
"*"		  return MUL;
"/"		  return DIV;

"//".* ;

  /* Comentario de uma linha */

"/*"              { linha_comentario_inicio = yylineno; BEGIN(COMMENT); } 
  /* Inicio de comentario */
<COMMENT>"*/"     BEGIN(INITIAL); 
  /* Para voltar ao estado normal quando encontra isso */
<COMMENT>\n       ; 
  /* Para ignorar a quebra de linha dentro do comentário */
<COMMENT>.        ;
  /* Para ignorar os caracteres dentro do comentário */

  /* EOF dentro de comentario e erro lexico; o numero salvo aponta para
     a linha em que o comentario comecou, mesmo apos varias quebras de linha. */
<COMMENT><<EOF>>  {
      fprintf(stderr, "ERRO LEXICO (linha %d): comentario iniciado com /* nao foi fechado\n", linha_comentario_inicio);
      erros_lexicos++;
      yyterminate();
}

"<="	  return LE;
">="      return GE;
"=="      return EQ;
"!="      return NE;
"<"		  return LT;
">"       return GT;

"="		  return IGL;
";"		  return PEV;
","       return VIR;

"("		  return APR;
")"		  return FPR;
"["       return ACO;
"]"       return FCO;
"{"       return ACH;
"}"       return FCH;

[ \t\r\n]+         ;

  /* Zero informa ao Bison que nao ha mais tokens. */
<<EOF>>     { LOCALIZAR snprintf(lexema_atual, sizeof(lexema_atual), "fim do arquivo"); return 0; }

  /* Regra final: caractere nao reconhecido. Registra o erro e continua
     lendo para permitir outros diagnosticos e a construcao parcial da AST. */
.			{ erro_lexico(yytext, yylineno); erros_lexicos++; }


%%

/* A função de relatar erros léxicos */
void erro_lexico(const char *lexema, int linha)
{
  fprintf(stderr, "ERRO LÉXICO: %s LINHA: %d\n", lexema, linha);
}

int main(int argc, char *argv[])
{
    if (argc != 2) {
        fprintf(stderr, "Uso: %s arquivo\n", argv[0]);
        return 2;
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        perror(argv[1]);
        return 1;
    }

    /* yyparse chama yylex conforme precisa de tokens; suas reducoes
       constroem a arvore e atualizam raiz. Retorno zero nao exclui erros
       recuperados: por isso tambem consultamos os contadores. */
    int resultado = yyparse();
    fclose(yyin);

#ifdef ANALISE_SEMANTICA
    /* Mesmo com erros, percorremos e mostramos os trechos recuperados.
       O modo parcial evita exigir main/retorno de um programa incompleto. */
    int parcial = resultado != 0 || erros_lexicos != 0 || erros_sintaticos != 0;
    analisar_semantica(raiz, parcial);
    puts("ARVORE SINTATICA:");
    if (parcial) puts("[Parcial: somente os trechos recuperados da entrada.]");
    if (raiz) imprimir_arvore(raiz, 0);
    else puts("[Nenhuma declaracao completa recuperada.]");
    puts("TABELA DE SIMBOLOS:");
    if (parcial) puts("[Parcial: simbolos das declaracoes recuperadas.]");
    imprimir_tabela_simbolos();
    /* Os simbolos apontam para nos, e os nos apontam para lexemas.
       Liberar nessa ordem mantem os dados disponiveis ate a impressao. */
    liberar_simbolos();
    liberar_arvore(raiz);
    liberar_lexemas();
    /* A impressao da arvore/tabela nao significa aceitacao do programa. */
    if (resultado == 0 && erros_lexicos == 0 && erros_sintaticos == 0 && erros_semanticos == 0) {
        puts("Compilacao com sucesso. Arquivo aceito.");
        return 0;
    }
    fprintf(stderr, "Arquivo rejeitado: %d erro(s) lexico(s), %d sintatico(s), %d semantico(s).\n",
            erros_lexicos, erros_sintaticos, erros_semanticos);
#else
    if (resultado == 0 && erros_lexicos == 0 && erros_sintaticos == 0) {
        puts("Compilacao com sucesso. Arquivo aceito.");
        return 0;
    }
    fprintf(stderr, "Arquivo rejeitado: %d erro(s) lexico(s), %d erro(s) sintatico(s).\n",
            erros_lexicos, erros_sintaticos);
#endif
    return 1;
}
