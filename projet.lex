%{
#include "projet.h"

%}

%x comment

%%
"/*" BEGIN(comment);
<comment>[^*\n]* ;
<comment>"*"+[^*/\n]* ;
<comment>"*"+"/" BEGIN(INITIAL);
[ \t\n]+ ;
[0-9]+ {sscanf(yytext,"%d",&yylval.entier); return NUM;}
"if" {return IF;}
"else" {return ELSE;}
"print" {return PRINT;}
"while" {return WHILE;}
"entier" {return INT;}
"caractere" {return CHAR;}
"return" {return RETURN;}
"void" {return VOID;}
"main" {return MAIN;}
"const" {return CONST;}
"true" {return TRUE;}
"false" {return FALSE;}
"read" {return READ;}
"readch" {return READCH;}
"'"[a-zA-Z]"'" {yylval.caract = yytext[1];return CARACTERE;}
[A-Za-z_]+ {sscanf(yytext,"%s",yylval.string);return IDENT;}
. return yytext[0];
%%
