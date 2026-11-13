%{

%}

%% /* Grammar for C- */
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