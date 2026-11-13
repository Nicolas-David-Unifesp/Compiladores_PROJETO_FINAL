#include "arvore.h"
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
typedef struct Escopo { struct Escopo *pai, *proximo; int id; } Escopo;
typedef struct Simbolo { No *decl; Escopo *escopo; struct Simbolo *proximo; } Simbolo;
static Escopo *escopos, *global;
static Simbolo *simbolos;
static int proximo_escopo;
int erros_semanticos;
static void erro(No *n, const char *formato, ...) {
    va_list args; fprintf(stderr, "ERRO SEMANTICO (linha %d): ", n ? n->linha : 1);
    va_start(args, formato); vfprintf(stderr, formato, args); va_end(args);
    fputc('\n', stderr); ++erros_semanticos;
}
static void *alocar(size_t tamanho) {
    void *p = calloc(1, tamanho); if (!p) { perror("memoria"); exit(2); } return p;
}
static Escopo *novo_escopo(Escopo *pai) {
    Escopo *e = alocar(sizeof *e); e->pai = pai; e->id = proximo_escopo++;
    e->proximo = escopos; escopos = e; return e;
}
static Simbolo *buscar_local(Escopo *e, const char *nome) {
    Simbolo *s; for (s = simbolos; s; s = s->proximo)
        if (s->escopo == e && !strcmp(s->decl->nome, nome)) return s;
    return NULL;
}
static Simbolo *buscar(Escopo *e, const char *nome) {
    for (; e; e = e->pai) { Simbolo *s = buscar_local(e, nome); if (s) return s; } return NULL;
}
static void declarar(Escopo *e, No *n) {
    Simbolo *s;
    if (n->categoria != FUNCAO && n->tipo == T_VOID) erro(n, "'%s' nao pode ter tipo void", n->nome);
    if (n->categoria == DECL && n->vetor && n->filhos[0]->valor <= 0)
        erro(n, "vetor '%s' deve ter tamanho positivo", n->nome);
    if (buscar_local(e, n->nome)) { erro(n, "declaracao duplicada de '%s'", n->nome); return; }
    s = buscar_local(global, n->nome);
    if (e != global && s && s->decl->categoria == FUNCAO)
        erro(n, "variavel '%s' conflita com funcao", n->nome);
    s = alocar(sizeof *s); s->decl = n; s->escopo = e; s->proximo = simbolos; simbolos = s;
}
static Tipo expressao(No *n, Escopo *e);
static void exigir_int(No *n, Tipo t) {
    if (t != T_INT && t != T_ERRO) erro(n, "expressao deve ser inteiro escalar");
}
static Tipo expressao(No *n, Escopo *e) {
    Tipo a, b; Simbolo *s; No *p, *arg;
    if (!n) return T_VOID;
    switch (n->categoria) {
    case NUM_NO: return n->tipo = T_INT;
    case ID_NO:
        if (n->filhos[0]) exigir_int(n->filhos[0], expressao(n->filhos[0], e));
        s = buscar(e, n->nome);
        if (!s) { erro(n, "variavel '%s' nao declarada", n->nome); return n->tipo = T_ERRO; }
        if (s->decl->categoria == FUNCAO) { erro(n, "funcao '%s' usada como variavel", n->nome); return n->tipo = T_ERRO; }
        if (n->filhos[0] && !s->decl->vetor) { erro(n, "'%s' nao e vetor", n->nome); return n->tipo = T_ERRO; }
        return n->tipo = s->decl->tipo == T_VOID ? T_ERRO : (s->decl->vetor && !n->filhos[0] ? T_VETOR : T_INT);
    case ATRIB:
    case OP:
        a = expressao(n->filhos[0], e); b = expressao(n->filhos[1], e);
        exigir_int(n->filhos[0], a); exigir_int(n->filhos[1], b);
        return n->tipo = a == T_INT && b == T_INT ? T_INT : T_ERRO;
    case CHAMADA:
        s = buscar(e, n->nome);
        if (!s || s->decl->categoria != FUNCAO) {
            erro(n, "'%s' nao e funcao declarada", n->nome);
            for (arg = n->filhos[0]; arg; arg = arg->proximo) expressao(arg, e);
            return n->tipo = T_ERRO;
        }
        p = s->decl->filhos[0]; arg = n->filhos[0];
        while (arg) {
            a = expressao(arg, e);
            if (p) {
                b = p->tipo == T_VOID ? T_ERRO : (p->vetor ? T_VETOR : T_INT);
                if (a != T_ERRO && b != T_ERRO && a != b) erro(arg, "tipo de argumento incompativel na chamada de '%s'", n->nome);
                p = p->proximo;
            }
            arg = arg->proximo;
        }
        { int esperados = 0, recebidos = 0;
          for (p = s->decl->filhos[0]; p; p = p->proximo) ++esperados;
          for (arg = n->filhos[0]; arg; arg = arg->proximo) ++recebidos;
          if (esperados != recebidos) erro(n, "'%s' espera %d argumento(s), recebeu %d", n->nome, esperados, recebidos);
        }
        return n->tipo = s->decl->tipo;
    default: return T_ERRO;
    }
}
/* Retorna verdadeiro quando todos os caminhos do comando retornam. */
static int comando(No *n, Escopo *e, No *funcao);
static int bloco(No *n, Escopo *e, No *funcao) {
    No *p; int retorna = 0;
    for (p = n->filhos[0]; p; p = p->proximo) declarar(e, p);
    for (p = n->filhos[1]; p; p = p->proximo) if (comando(p, e, funcao)) retorna = 1;
    return retorna;
}
static int comando(No *n, Escopo *e, No *funcao) {
    Tipo t; int a, b;
    if (!n) return 0;
    switch (n->categoria) {
    case BLOCO: return bloco(n, novo_escopo(e), funcao);
    case EXPR:
        t = expressao(n->filhos[0], e);
        if (n->filhos[0] && n->filhos[0]->categoria == CHAMADA && t == T_INT)
            erro(n, "retorno de '%s' ignorado", n->filhos[0]->nome);
        return 0;
    case RETORNO:
        t = expressao(n->filhos[0], e);
        if (funcao->tipo == T_VOID && n->filhos[0]) erro(n, "funcao void nao pode retornar expressao");
        if (funcao->tipo == T_INT && t != T_INT && t != T_ERRO) erro(n, "funcao int deve retornar inteiro escalar");
        return 1;
    case SE:
        exigir_int(n->filhos[0], expressao(n->filhos[0], e));
        a = comando(n->filhos[1], e, funcao); b = comando(n->filhos[2], e, funcao);
        return a && b;
    case ENQUANTO:
        exigir_int(n->filhos[0], expressao(n->filhos[0], e)); comando(n->filhos[1], e, funcao); return 0;
    default: return 0;
    }
}
void analisar_semantica(No *n, int parcial) {
    No *p; Simbolo *s;
    global = novo_escopo(NULL);
    for (p = n; p; p = p->proximo) {
        declarar(global, p);
        if (p->categoria == FUNCAO) {
            Escopo *e = novo_escopo(global); No *param;
            for (param = p->filhos[0]; param; param = param->proximo) declarar(e, param);
            if (!bloco(p->filhos[1], e, p) && p->tipo == T_INT && !parcial)
                erro(p, "funcao '%s' pode terminar sem retornar valor", p->nome);
        }
    }
    s = buscar_local(global, "main");
    if (!parcial && (!s || s->decl->categoria != FUNCAO || s->decl->tipo != T_VOID || s->decl->filhos[0]))
        erro(n, "programa deve declarar void main(void)");
}
void imprimir_tabela_simbolos(void) {
    Simbolo *s;
    puts("Nome\tCategoria\tTipo\tEscopo\tLinha\tParametros");
    for (s = simbolos; s; s = s->proximo) {
        No *n = s->decl, *p;
        printf("%s\t%s\t%s%s\t%d\t%d\t", n->nome,
               n->categoria == FUNCAO ? "funcao" : n->categoria == PARAM ? "parametro" : "variavel",
               n->tipo == T_VOID ? "void" : "int", n->vetor ? "[]" : "", s->escopo->id, n->linha);
        for (p = n->categoria == FUNCAO ? n->filhos[0] : NULL; p; p = p->proximo)
            printf("%s%s%s", p->tipo == T_VOID ? "void" : "int", p->vetor ? "[]" : "", p->proximo ? ", " : "");
        putchar('\n');
    }
}
void liberar_simbolos(void) {
    while (simbolos) { Simbolo *s = simbolos; simbolos = s->proximo; free(s); }
    while (escopos) { Escopo *e = escopos; escopos = e->proximo; free(e); }
    global = NULL; proximo_escopo = 0;
}
