#ifndef ARVORE_H
#define ARVORE_H
#include <stdio.h>
typedef enum { T_INT, T_VOID, T_ERRO, T_VETOR } Tipo;
typedef enum { DECL, FUNCAO, PARAM, BLOCO, ID_NO, NUM_NO, ATRIB, OP, CHAMADA, SE, ENQUANTO, RETORNO, EXPR, ERRO_NO } Categoria;
typedef struct No {
    Categoria categoria;
    Tipo tipo;
    int linha, vetor, operador;
    long valor;
    const char *nome;
    struct No *filhos[3], *proximo;
} No;
extern No *raiz;
extern int erros_semanticos;
const char *internar_lexema(const char *nome);
void liberar_lexemas(void);
No *novo_no(Categoria categoria, int linha);
No *numero(long valor, int linha);
No *juntar(No *lista, No *no);
void imprimir_arvore(No *no, int nivel);
void liberar_arvore(No *no);
void analisar_semantica(No *no, int parcial);
void imprimir_tabela_simbolos(void);
void liberar_simbolos(void);
#endif
