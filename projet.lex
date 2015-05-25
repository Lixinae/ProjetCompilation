%{
#include "projet.h"
%}
%%
[ \t\n]+ ;
[0-9]+ {sscanf(yytext,"%d",&yylval); return NUM;}
"if" {return IF;}
"else" {return ELSE;}
"print" {return PRINT;}
[A-Za-z] {return IDENT;}
"while" {return WHILE;}
"int" {return TYPE;}
"return" {return RETURN;}
"void" {return VOID;}
"main" {return MAIN;}
"const" {return CONST;}

. return yytext[0];
%%
