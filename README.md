# Analisador de C-

Requer Flex, Bison, compilador C e Make. Os testes usam Python 3.

```sh
make
./build/analisador programa.cm
make test
```

O executavel sempre imprime a arvore sintatica abstrata e a tabela de simbolos
apos analisar o arquivo, inclusive quando existem erros. Em caso de erro lexico
ou sintatico, as estruturas sao identificadas como parciais. O parser tenta
recuperar declaracoes e comandos usando `;` como ponto de sincronizacao;
comandos descartados aparecem como trechos com erro sintatico. Se a leitura
abortar, as declaracoes globais completas anteriores continuam disponiveis.
Uma funcao interrompida antes de fechar seu corpo pode nao ser recuperada.
Quando nada puder ser recuperado, a arvore informa isso e a tabela fica vazia.

A analise semantica verifica os trechos recuperados e informa erros com linha.
Na entrada parcial, as verificacoes de ausencia de `main` e de caminhos sem
retorno sao omitidas para evitar conclusoes baseadas em trechos descartados.
Outros diagnosticos semanticos podem decorrer de declaracoes nao recuperadas.
Qualquer erro mantem o arquivo rejeitado; somente a ausencia de erros produz
`Compilacao com sucesso. Arquivo aceito.`. O status de saida e 0 para
aceitacao, 1 para rejeicao e 2 para uso incorreto.

## Organizacao

- `lexico.l`: reconhece tokens; no modo semantico, cadastra identificadores na
  tabela de lexemas e envia nomes e numeros ao Bison por `yylval`.
- `gramatica_semantico_c-.y`: constroi a arvore e preserva linhas com `%locations`.
- `arvore.h` e `arvore.c`: nos da arvore, listas, impressao, liberacao e internacao
  dos lexemas. Nomes iguais compartilham o texto, mas nao o simbolo semantico.
- `semantico.c`: percorre a arvore, cria escopos e registra declaracoes,
  parametros e assinaturas na tabela de simbolos. Tambem verifica tipos e usos.
- `tests/test_semantico.py`: testes de integracao com programas validos e invalidos.

O Makefile gera parser, scanner e executavel em `build/`. Os arquivos gerados
antigos na raiz nao sao usados por esse build. O scanner conserva o modo
sintatico antigo quando compilado sem `ANALISE_SEMANTICA`.

A lista de verificações e exemplos está em [Erros semânticos implementados](ERROS_SEMANTICOS.md).
Os fontes `lexico.l` e `gramatica_semantico_c-.y` contêm comentários sobre a
integração Flex/Bison, a construção da árvore e a recuperação de erros.

## Regras adotadas

A linguagem tem tipos `int` e `void`, variaveis escalares, vetores e funcoes.
Identificadores seguem a regra original: uma ou mais letras, sem numeros ou `_`.
Parametros vazios sao escritos como `(void)`; chamadas sem argumentos usam `()`.
Nao ha funcoes de biblioteca predefinidas.

O programa deve declarar `void main(void)`. Declaracoes globais sao analisadas
na ordem do arquivo: uma funcao pode chamar a si mesma, mas nao uma funcao
posterior. Parametros e variaveis do bloco externo da funcao compartilham o
escopo; blocos internos criam escopos filhos. Sombreamento de variaveis e
permitido. Uma variavel nao pode usar o nome de uma funcao global ja declarada.

Seguindo o esboco do trabalho, uma chamada isolada de funcao `int` e erro por
ignorar seu retorno. Argumentos distinguem inteiro escalar de vetor de inteiros.
Variaveis e parametros nomeados nao podem ser `void`; vetores devem ter tamanho
positivo. Indices, condicoes e operandos devem ser inteiros escalares.

Funcoes `void` so permitem `return;`. Funcoes `int` exigem retorno inteiro em
todos os caminhos reconhecidos pela analise estrutural: um `if` retorna quando
ambos os ramos retornam. Um `while` nao garante retorno, mesmo com condicao
constante. Nao ha avaliacao de expressoes constantes, verificacao de limites de
indice em execucao ou analise de inicializacao de variaveis.

O arquivo `teste.txt` contém um exemplo válido de ordenação por seleção, com
entrada e saída simuladas. Exemplo mínimo válido:

```c
int dobro(int x) {
    return x * 2;
}

void main(void) {
    int resultado;
    resultado = dobro(3);
}
```
