%{
#include "flot.h"
%}
%%
[ \t\n]+ ;
[0-9]+ {sscanf(yytext,"%d",&yylval); return NOMBRE_ENTIER;}
"if" {return IF;}
"else" {return ELSE;}
"print" {return PRINT;}
"while" {return WHILE;}
"true" {return TRUE;}
"false" {return FALSE;}
[A-Za-z]+ {return IDENT;}
. return yytext[0];
%%
