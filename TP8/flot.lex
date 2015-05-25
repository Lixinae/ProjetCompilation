%{
#include "flot.h"
%}
%%
[ \t\n]+ ;
[0-9]+ {sscanf(yytext,"%d",&yylval); return NOMBRE_ENTIER;}
"if" {return IF;}
"else" {return ELSE;}
"print" {return PRINT;}
[A-Za-z]+ {return IDENT;}
"while" {return WHILE;}
. return yytext[0];
%%
