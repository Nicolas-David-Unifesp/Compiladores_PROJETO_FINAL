%{

%}

%% /* O que deve ser adcionado. Só verificar se faz sentido com a gramática que tem 
1. Declaração e Escopo de Variáveis

• Variável não declarada (Caso 1): Ocorre ao utilizar uma variável (como b = a;) que não existe no escopo atual nem no escopo global.
• Tipo inválido para variável (Caso 3): Ocorre ao declarar uma variável com o tipo void (como void a;). Esse tipo é exclusivo para o retorno ou parâmetros de funções.
• Duplicidade de declaração (Caso 4): Ocorre ao declarar duas variáveis com o mesmo identificador dentro do mesmo escopo (como int a; int a;).
• Conflito de nome com função (Caso 7): Ocorre ao declarar uma variável utilizando o mesmo nome de uma função já definida no programa (como int xyz; quando já existe int xyz()).

2. Estrutura e Chamada de Funções

• Ausência da função principal (Caso 6): Ocorre quando o programa inteiro é analisado e a função obrigatória void main(void) não foi declarada.
• Chamada de função inexistente (Caso 5): Ocorre ao invocar uma função (como fun3()) que não foi previamente declarada.
• Quantidade incorreta de argumentos (Caso 8): Ocorre quando a chamada da função passa um número de parâmetros diferente da sua assinatura (ex: fun1(a) para void fun1(int x, int y)).
• Tipo incorreto de argumentos (Caso 9): Ocorre quando os tipos das variáveis enviadas na chamada não correspondem aos tipos esperados na declaração (ex: passar int onde se espera float).

3. Retorno e Atribuição

• Atribuição de função sem retorno (Caso 2): Ocorre ao tentar atribuir o resultado de uma função void a uma variável tipada (como a = exemplo();).
• Retorno de função ignorado (Caso 10): Ocorre ao chamar uma função que possui retorno (como int xyz()) de forma isolada, sem atribuir ou utilizar o valor devolvido.
 */
programa    	   : declaracao_lista { };
declaracao_lista   : declaracao_lista declaracao { }
		   	   	   | declaracao { };
declaracao	       : var_declaracao { }
		           | fun_declaracao { };
id	               : ID { }; 
fid		           : {  }; 
var_declaracao	   : tipo_especificador var SEMI { };
tipo_especificador : INT { } 
		           | VOID { };
fun_declaracao	   : tipo_especificador id fid APAR params FPAR 
composto_decl { };
params		       : param_lista { }
		           | VOID { };
param_lista	       : param_lista VIR param { }
		           | param { };
param		       : tipo_especificador id { }
		           | tipo_especificador id ACOL FCOL { };
composto_decl	   : ACHA local_declaracoes statement_lista FCHA { };
local_declaracoes  : local_declaracoes var_declaracao { }
		           | /*epsilon*/ { };
statement_lista	   : statement_lista statement { }
		           | /*epsilon*/ { };
statement	       : expressao_decl { }
		           | composto_decl { }
		           | selecao_decl { }
		           | iteracao_decl {  }
		           | retorno_decl { };
expressao_decl	   : expressao SEMI {  }
		           | SEMI { };
selecao_decl	   : IF APAR expressao FPAR statement { }
		           | IF APAR expressao FPAR statement ELSE statement	{ };
iteracao_decl	   : WHILE APAR expressao FPAR statement{ };
retorno_decl	   : RETURN SEMI { }
		           | RETURN expressao SEMI	{ };
expressao	       : var ASSIGN expressao { }
		           | simples_expressao { };
var		           : id { }
		           | id ACOL expressao FCOL{ };
var2		       : id { };
simples_expressao  : soma_expressao relacional soma_expressao { }
		           | soma_expressao { };
relacional	       : MEIG { }
		           | MEQ {  }
		           | MAQ { }
		           | MAIG { }
		           | EQ { }
		           | DIF { } ;
soma_expressao	   : soma_expressao soma termo {  }
		           | termo { };
soma		       : SOM { }
		           | SUB { };
termo		       : termo mult fator { }
		           | fator {  };
mult		       : MUL { }
		           | DIV { };
fator		       : APAR expressao FPAR { }
		           | var {  }
		           | ativacao {  }
		           | NUM { };
ativacao	       : var2 APAR args FPAR { };
args		       : arg_lista {  }
		           | /*epsilon*/ { };
arg_lista	       : arg_lista VIR expressao { }
       		       | expressao { };

%%
