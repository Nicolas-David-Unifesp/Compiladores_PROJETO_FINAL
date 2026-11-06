%{
#include "semantico.tab.h"
#include <stdio.h>
#include <string.h>

extern int erros_sintaticos;

int erros_lexicos = 0;
int linha_comentario_inicio = 0;
char lexema_atual[256];

#define YY_USER_ACTION \
    snprintf(lexema_atual, sizeof(lexema_atual), "%.*s", (int)yyleng, yytext);

/* Relata um erro lexico, indicando a linha e o que está errado */
void erro_lexico(const char *lexema, int linha);
%}

%option noyywrap 
/* Para evitar a necessidade de uma função yywrap e 
como estou fazendo rodar um arquivo por execução é mais prático.*/
%option yylineno 
/* Para rastrear o número da linha */

%x COMMENT 
/* Define o estado para comentários */

DIGITO [0-9]
LETRA [a-zA-Z]
%%
{DIGITO}+ return NUM;

"else"    return ELSE;
"if"      return IF;
"int"     return INT;
"return"  return RETURN;
"void"    return VOID;
"while"   return WHILE;

{LETRA}+  return ID;

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

<<EOF>>     { snprintf(lexema_atual, sizeof(lexema_atual), "fim do arquivo"); return 0; }

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

    int resultado = yyparse();
    fclose(yyin);

    if (resultado == 0 && erros_lexicos == 0 && erros_sintaticos == 0) {
        puts("Arquivo aceito.");
        return 0;
    }

    fprintf(stderr, "Arquivo rejeitado: %d erro(s) lexico(s), %d erro(s) sintatico(s).\n",
            erros_lexicos, erros_sintaticos);
    return 1;
}
