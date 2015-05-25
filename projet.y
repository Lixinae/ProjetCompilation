%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#define MAX_SIZE 256

/* A modifier */
typedef enum{
	false=0,
	true
}Bool;

typedef enum {
	caract=0,
	integ
}Type;

typedef struct {
	Type type;/* 0 : caract
				 1 : integ 
			  	*/
	char* name;
	int size;
	int value;

}Table_symbol;

 int yyerror(char*);
 int yylex();
 FILE* yyin; 
 int yylval; 
 int jump_label=0;
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);
 
 /* Verifie si le symbole donné est dans la table */
 Bool find(char *symbol);
 /* insert le symbole "symbol" de type "type" dans la table*/
 void insert_symbol(char* symbol,Type type); 
  /* Modifier les 2 fonctions
	-> utiliser table des symbole
 */
 void stockage(void);
 void restoration(void); 
 void ifand();
 void ifor();
 
 Table_symbol table[MAX_SIZE];
 int nbElemTable=0;
 
%}

%token IF ELSE PRINT NUM 
%token IDENT
%token WHILE
%token MAIN
%token VOID
%token RETURN
%token CARACTERE
%token CONST
%token INT CHAR
%token TRUE FALSE

%left NOTELSE
%left ELSE
%left '='
%left '+'
%left '-'
%left '*'
%left '/'


%%

Progamme : 
	DeclConst DeclVarPuisFonct DeclMain
    ;

/* Declaration de la liste des constante */	
DeclConst: 
	/* vide */
	| CONST ListConst ';' DeclConst	   
	;
  
ListConst : 
	IDENT '=' Litteral ',' ListConst
	| IDENT '=' Litteral
	;
Litteral :
	NombreSigne
	| CARACTERE
	;

NombreSigne:
	NUM
	| '+' NUM
	| '-' NUM
	;

DeclVarPuisFonct :
	/* vide */
	| INT ListVar ';' DeclVarPuisFonct
	| CHAR ListVar ';' DeclVarPuisFonct
	| DeclFonct
	;

	
ListVar : 
	Ident ',' ListVar
	| Ident
	;
Ident : 
	IDENT Tab
	;
Tab : 
	/* vide */
	| '[' NUM ']' Tab 	
	;
DeclMain :
	EnTeteMain Corps
	;
EnTeteMain: 
	MAIN '(' ')'
	;
DeclFonct : 
	DeclUneFonct DeclFonct
	| DeclUneFonct
	;
DeclUneFonct:
	EnTeteFonct Corps
	;
EnTeteFonct : 
	INT IDENT '(' Parametres ')'
	| CHAR IDENT '(' Parametres ')'
	| VOID IDENT '(' Parametres ')'
	;
Parametres : 
	VOID
	| ListTypVar
	;
ListTypVar :
	INT IDENT ',' ListTypVar
	| CHAR IDENT ',' ListTypVar  
	| INT IDENT
	| CHAR IDENT	
	;
Corps : 
	'{' DeclConst DeclVar SuiteInstr '}'
	;

/* Declaration des variables
	forme : 
	int x,z;
	int y;
	Pas affectation a la declaration
 */	
DeclVar : 
	/*vide*/
	| DeclVar INT ListVar ';' /*{ insert_symbol((char*)$3,$2);}  Erreur pour le moment */
	| DeclVar CHAR ListVar ';'  
	;

SuiteInstr :
	/*vide*/
	| Instr SuiteInstr       
    ;
	
Instr :
	LValue '=' Exp ';'
	| IF '(' Ifbool ')' InstrIF
		
	| WHILE  { instarg("LABEL",$$=jump_label++);} '(' Ifbool ')' {inst("POP");instarg("JUMPF",$$=jump_label++);}      	
		Instr	{instarg("JUMP",$2); instarg("LABEL",$6);}
	
	| RETURN Exp ';' { 
	
	}
	| RETURN ';' { 
	
	}
	| IDENT '(' Arguments ')' ';' { 
	
	}
		/* READ */
	| INT {inst("READ");inst("PUSH");} '(' IDENT ')' ';'  { 
	
	} 
		/* READCH */
	| CHAR {inst("READCH");inst("PUSH");}  '(' IDENT ')' ';' {

	}
	| PRINT '(' Exp {inst("POP");inst("WRITE");comment("---affichage");}')' ';' 
	| ';'
	| '{' SuiteInstr '}'
	;	
	
Arguments: 
	/* vide */ 
	| ListExp
	;

LValue :
	IDENT TabExp	
	;
TabExp:
	/* vide */
	| TabExp '[' Exp ']' 

	;

ListExp : 
	ListExp ',' Exp 
	| Exp  
	;	

/* A completer */	 
Exp : 
	/* Exp ADDSUB Exp */
	Exp '+' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("ADD");
		inst("PUSH");
	}
	| Exp '-' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("SUB");
		inst("PUSH");
	}
	
	/* Exp DIVSTAR Exp */
	| Exp '*' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("MUL");
		inst("PUSH");
	}	
	| Exp '/' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("DIV");
		inst("PUSH");
	}
	| '(' Exp '%' Exp ')' {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("MOD");
		inst("PUSH");
	}
    
    /* ADDSUB Exp */
	| '(' '-' Exp ')' {
		inst("POP");
		inst("NEG");
		inst("PUSH"); 
	}
	/*Exp BOPE Exp 
	*/
	
	/* NEGATION Exp */	
	
	/* */
	| '(' Exp ')' { }
	| LValue { }
	| NUM { 
		instarg("SET",$1);
        inst("PUSH"); 
    }
	| CARACTERE { }
	| IDENT '(' Arguments ')' { }
  ;


InstrIF :
	 Instr %prec NOTELSE {instarg("LABEL",jump_label++);}
     | Instr ELSE JUMPELSE {instarg("LABEL",$3-1);} Instr {instarg("LABEL",$3);}
	 ;
	 
Ifbool:
	 IfboolONE  '|' '|' Ifbool {ifor();$$=$4;}
	 | IfboolONE '&' '&' Ifbool {ifand();$$=$4;}	 
	 | IfboolONE {$$=$1;}
	;

IfboolONE: 
    Exp '<' Exp JUMPIFLESS { $$=$4;}
    |  Exp '>' Exp JUMPIFGREATER { $$=$4;}
    |  Exp '<''=' Exp JUMPIFLEQ {$$=$5;}    
    |  Exp '>''=' Exp JUMPIFGEQ {$$=$5;}
    |  Exp '=''=' Exp JUMPIFEQUAL {$$=$5;}
    |  Exp '!''=' Exp JUMPIFNOTEQUAL {$$=$5;}
    | '!' Exp JUMPIFNOT {$$=$3;}
	| TRUE {instarg("SET",1); inst("PUSH");}
	| FALSE {instarg("SET",0); inst("PUSH");}
	;

JUMPIFNOT:{
		inst("POP");
		inst("NEG");
		inst("SWAP");
		instarg("SET",1);
		inst("ADD");
		inst("PUSH");
		}
	;

JUMPIFEQUAL:{
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("EQUAL");
		$$=jump_label;
		inst("PUSH");
	}
	;
JUMPIFNOTEQUAL:{
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("NOTEQ");
		$$=jump_label;
		inst("PUSH");
	}
	;   	      
JUMPIFLESS :  {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("LESS");
		$$=jump_label;
		inst("PUSH");
	}
	;
JUMPIFLEQ :  {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("LEQ");
		$$=jump_label;
		inst("PUSH");
	}
	;	 
JUMPIFGREATER :  {
		inst("POP"); 
    	inst("SWAP"); 
		inst("POP");
		inst("GREATER");
		$$=jump_label;
		inst("PUSH");
	}	 
	;
JUMPIFGEQ :  {
		inst("POP"); 
        inst("SWAP"); 
		inst("POP");
		inst("GEQ");
		$$=jump_label;
		inst("PUSH");
	 }	 
	 ;	  
JUMPELSE : {
	instarg("JUMP", $$=jump_label++);

	}	 
	;




%%

/* Recupere la val en sommet de pile et la place à l'adresse 0 */ 
void stockage(){
	instarg("SET",0);
	inst("SWAP"); 
	inst("POP");
	inst("SAVE");
}

/* Recupere la val à l'adresse 0 et la place en sommet de la pile */
void restoration(){
	instarg("SET",0);
	inst("LOAD");
	inst("PUSH");
}

void ifor(){
	inst("POP");
	inst("NEG");
	inst("SWAP");
	instarg("SET",1);
	inst("ADD");
	instarg("JUMPF",jump_label);

}

void ifand(){
	inst("POP");
	inst("SWAP");
	inst("POP");
	inst("ADD");
	inst("SWAP");
	instarg("SET",2);
	inst("LEQ");
	inst("PUSH");

}

Bool find(char *symbol){
	int i;
	for(i=0;i<MAX_SIZE;i++){
		if(strcmp(table[i].name,symbol))
			return true;
	}
	return false;
}


void insert_symbol(char* symbol,Type type){
	if(!find(symbol)){
		table[nbElemTable].name=(char*)calloc(sizeof(char),strlen(symbol));
		strcpy(table[nbElemTable].name,symbol);
		table[nbElemTable].type = type;
		nbElemTable++;
	}	
}




int yyerror(char* s) {
  fprintf(stderr,"%s\n",s);
  return 0;
}

void endProgram() {
  printf("HALT\n");
}

void inst(const char *s){
  printf("%s\n",s);
}

void instarg(const char *s,int n){
  printf("%s\t%d\n",s,n);
}


void comment(const char *s){
  printf("#%s\n",s);
}

int main(int argc, char** argv) {
  if(argc==2){
    yyin = fopen(argv[1],"r");
  }
  else if(argc==1){
    yyin = stdin;
  }
  else{
    fprintf(stderr,"usage: %s [src]\n",argv[0]);
    return 1;
  }
  instarg("ALLOC",1);
  yyparse();
  instarg("FREE",1);
  endProgram();
  return 0;
}
