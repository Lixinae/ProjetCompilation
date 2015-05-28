%{
#include "projet.h"
%}
%%
[ \t\n]+ ;
[0-9]+ {sscanf(yytext,"%d",&yylval.entier); return NUM;}
"if" {return IF;}
"else" {return ELSE;}
"print" {return PRINT;}
"while" {return WHILE;}
"int" {return INT;}
"char" {return CHAR;}
"return" {return RETURN;}
"void" {return VOID;}
"main" {return MAIN;}
"const" {return CONST;}
"true" {return TRUE;}
"false" {return FALSE;}
"'"[a-zA-Z]"'" {yylval.caract = yytext[1];return CARACTERE;}
[A-Za-z]+ {sscanf(yytext,"%s",yylval.string);return IDENT;}
. return yytext[0];
%%
