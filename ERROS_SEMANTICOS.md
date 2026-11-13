# Erros semânticos implementados

As verificações estão em `semantico.c`. O Flex reconhece tokens e cadastra
lexemas; o Bison constrói a árvore; o percurso semântico registra declarações
na tabela de símbolos e verifica os usos. Cada erro semântico imprime a linha,
incrementa `erros_semanticos` e impede a mensagem de compilação com sucesso.
Os exemplos abaixo são trechos: precisam estar em um programa C- completo.

## Os dez casos previstos no esboço

| Caso | Erro | Exemplo / condição | Verificação em `semantico.c` |
|---|---|---|---|
| 1 | Variável não declarada ou fora de escopo | `a = 1;` sem declaração visível de `a` | `expressao`, caso `ID_NO`; busca no escopo atual e nos pais |
| 2 | Atribuição do resultado de função `void` | `a = f();`, com `void f(void)` | `expressao`, caso `ATRIB`, e `exigir_int` |
| 3 | Variável de tipo `void` | `void a;` | `declarar` |
| 4 | Declaração duplicada no mesmo escopo | `int a; int a;` | `declarar` e `buscar_local`; também detecta funções, parâmetros e conflitos entre categorias no mesmo escopo |
| 5 | Chamada de função não declarada | `f();` sem função visível já declarada | `expressao`, caso `CHAMADA` |
| 6 | Ausência ou assinatura inválida da função principal | Falta de `void main(void)`, ou declaração de `int main(void)` | `analisar_semantica` |
| 7 | Variável ou parâmetro com nome de função global já declarada | `void f(void) {}` seguido de uma função contendo `int f;` | `declarar`; em escopo global, conflitos são diagnosticados como duplicidade |
| 8 | Quantidade incorreta de argumentos | `f();` quando a assinatura é `void f(int x)` | `expressao`, caso `CHAMADA` |
| 9 | Tipo de argumento incompatível | Passar `int` para um parâmetro `int[]`, ou o inverso; também passar resultado `void` | `expressao`, caso `CHAMADA` |
| 10 | Retorno de função `int` ignorado em chamada isolada | `f();`, com `int f(void)` | `comando`, caso `EXPR` |

O caso 9 distingue **inteiro escalar e vetor de inteiros**: não há `float` na
gramática. Os casos 7 e 10 seguem as restrições do trabalho; não representam
proibições gerais da linguagem C. A verificação do caso 10 aplica-se à chamada
que constitui toda a expressão do comando, inclusive entre parênteses.

## Verificações adicionais

| Erro | Exemplo / condição | Local |
|---|---|---|
| Parâmetro nomeado de tipo `void` | `void f(void x)`; `(void)` sozinho é permitido e significa nenhum parâmetro | `declarar` |
| Vetor sem tamanho positivo | `int a[0];` | `declarar` |
| Função usada como variável | `a = f;`, sendo `f` uma função | `expressao`, caso `ID_NO` |
| Indexação de uma variável escalar | `a[0]`, com `int a;` | `expressao`, caso `ID_NO` |
| Índice que não é inteiro escalar | `a[v]`, sendo `v` um vetor; também resultado de função `void` | `expressao`, caso `ID_NO`, e `exigir_int` |
| Operandos incompatíveis em operações aritméticas ou relacionais | `v + 1`, sendo `v` um vetor; operações com resultado `void` | `expressao`, caso `OP`, e `exigir_int` |
| Atribuição incompatível | Atribuir vetor inteiro sem índice, usar vetor inteiro como destino sem índice ou atribuir resultado `void` | `expressao`, caso `ATRIB`, e `exigir_int` |
| Chamar uma variável como função | `a();`, com `int a;` | `expressao`, caso `CHAMADA` |
| Condição que não é inteiro escalar | `if (v)` ou `while (v)`, sendo `v` um vetor; também resultado `void` | `comando`, casos `SE` e `ENQUANTO` |
| Retornar expressão em função `void` | `void f(void) { return 1; }` | `comando`, caso `RETORNO` |
| Retorno incompatível em função `int` | `return;`, retornar vetor sem índice ou resultado de função `void` | `comando`, caso `RETORNO` |
| Função `int` que pode terminar sem retornar | Corpo vazio, ou somente um `if` sem retorno garantido nos dois ramos | `analisar_semantica` e análise estrutural em `bloco`/`comando` |

## Comportamento e limites

- Declarações são consideradas na ordem do arquivo. Recursão direta é
  permitida porque a função entra na tabela antes de analisar seu corpo;
  chamada a função posterior é rejeitada. Não há funções de biblioteca
  predefinidas, incluindo `input` e `output`.
- Parâmetros e variáveis do corpo externo da função compartilham o escopo.
  Blocos internos criam escopos filhos. Sombrear variáveis de outro escopo é
  permitido; repetir o nome no mesmo escopo é erro.
- `T_ERRO` evita repetir erros de tipo derivados de uma expressão já inválida.
  Algumas violações diferentes usam a mesma mensagem: por exemplo,
  `expressao deve ser inteiro escalar`.
- Na análise parcial após erros léxicos ou sintáticos, a árvore e a tabela
  continuam sendo exibidas. As verificações de `main` e de caminhos sem retorno
  são omitidas; outros diagnósticos podem decorrer de declarações descartadas.
- A verificação de retorno é estrutural: `if` só garante retorno com os dois
  ramos retornando; `while` não garante retorno, mesmo com condição constante.
- Não há detecção de variável não inicializada, divisão por zero ou índice
  fora dos limites. Essas verificações não foram implementadas.
- Constante inteira fora do intervalo e comentário não fechado são erros
  **léxicos**. Pontuação ou construção incompatível com a gramática é erro
  **sintático**. Esses erros não pertencem à lista semântica acima.
