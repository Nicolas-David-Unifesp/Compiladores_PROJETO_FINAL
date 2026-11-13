#include "arvore.h"
#include <stdlib.h>
#include <string.h>
No *raiz;
typedef struct Lexema { char *nome; struct Lexema *proximo; } Lexema;
static Lexema *lexemas;
static void *alocar(size_t n) {
    void *p = calloc(1, n);
    if (!p) { perror("memoria"); exit(2); }
    return p;
}
const char *internar_lexema(const char *nome) {
    Lexema *p;
    for (p = lexemas; p; p = p->proximo)
        if (!strcmp(p->nome, nome)) return p->nome;
    p = alocar(sizeof *p);
    p->nome = alocar(strlen(nome) + 1);
    strcpy(p->nome, nome);
    p->proximo = lexemas; lexemas = p;
    return p->nome;
}
void liberar_lexemas(void) {
    while (lexemas) { Lexema *p = lexemas; lexemas = p->proximo; free(p->nome); free(p); }
}
No *novo_no(Categoria categoria, int linha) {
    No *n = alocar(sizeof *n); n->categoria = categoria; n->linha = linha; return n;
}
No *numero(long valor, int linha) { No *n = novo_no(NUM_NO, linha); n->valor = valor; return n; }
No *juntar(No *lista, No *no) {
    No *p = lista;
    if (!p) return no;
    while (p->proximo) p = p->proximo;
    p->proximo = no; return lista;
}
/* O prefixo guarda as linhas verticais dos ancestrais que ainda tem irmaos. */
static const char *rotulo_filho(Categoria categoria, int indice) {
    switch (categoria) {
    case FUNCAO: return indice == 0 ? "parametro" : "corpo";
    case BLOCO: return indice == 0 ? "declaracao" : "comando";
    case DECL: return "tamanho";
    case ID_NO: return "indice";
    case ATRIB: return indice == 0 ? "destino" : "valor";
    case OP: return indice == 0 ? "esquerda" : "direita";
    case CHAMADA: return "argumento";
    case SE: return indice == 0 ? "condicao" : indice == 1 ? "entao" : "senao";
    case ENQUANTO: return indice == 0 ? "condicao" : "corpo";
    case RETORNO: return "valor";
    case EXPR: return "expressao";
    default: return "filho";
    }
}

static void imprimir_no(No *n, const char *prefixo, int ultimo, const char *rotulo) {
    static const char *nomes[] = {"declaracao", "funcao", "parametro", "bloco", "identificador", "numero", "atribuicao", "operacao", "chamada", "if", "while", "return", "expressao", "trecho com erro sintatico"};
    int i, restantes = 0;
    No *filho;
    char *continuacao;
    const char *ramo = ultimo ? "    " : "│   ";

    printf("%s%s", prefixo, ultimo ? "└── " : "├── ");
    if (rotulo) printf("%s: ", rotulo);
    printf("%s", nomes[n->categoria]);
    if (n->nome) printf(" %s", n->nome);
    if (n->categoria == NUM_NO) printf(" %ld", n->valor);
    if (n->categoria == OP) {
        const char *op = n->operador == 'l' ? "<=" : n->operador == 'g' ? ">=" :
                         n->operador == 'e' ? "==" : n->operador == 'n' ? "!=" : NULL;
        if (op) printf(" %s", op); else printf(" %c", n->operador);
    }
    if (n->categoria == DECL || n->categoria == PARAM || n->categoria == FUNCAO)
        printf(" : %s%s", n->tipo == T_VOID ? "void" : "int", n->vetor ? "[]" : "");
    printf(" (linha %d)\n", n->linha);

    for (i = 0; i < 3; ++i)
        for (filho = n->filhos[i]; filho; filho = filho->proximo) ++restantes;
    if (!restantes) return;

    continuacao = alocar(strlen(prefixo) + strlen(ramo) + 1);
    strcpy(continuacao, prefixo);
    strcat(continuacao, ramo);
    for (i = 0; i < 3; ++i)
        for (filho = n->filhos[i]; filho; filho = filho->proximo)
            imprimir_no(filho, continuacao, --restantes == 0, rotulo_filho(n->categoria, i));
    free(continuacao);
}

void imprimir_arvore(No *n, int nivel) {
    char *prefixo;
    /* Mantem o parametro de recuo da interface original. */
    if (nivel < 0) nivel = 0;
    prefixo = alocar((size_t)nivel * 2 + 1);
    memset(prefixo, ' ', (size_t)nivel * 2);
    printf("%sprograma\n", prefixo);
    for (; n; n = n->proximo) imprimir_no(n, prefixo, n->proximo == NULL, NULL);
    free(prefixo);
}
void liberar_arvore(No *n) {
    while (n) { No *p = n->proximo; int i; for (i = 0; i < 3; ++i) liberar_arvore(n->filhos[i]); free(n); n = p; }
}
