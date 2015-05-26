%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#define MAX_SIZE 1024

/* A modifier */
typedef enum{
	false=0,
	true
}Bool;

typedef enum {
	caracter=0,
	integer
}Type;

typedef struct {
	Type type;/* 0 : caract
				 1 : integ 
			  	*/
	char* name;
	/*int size; inutile */ 
	int value;
	
	/* Rajouter une variable pour indiquer qu'un symbol est "mort" et donc reutilisable */

}Symbol;

 int yyerror(char*);
 int yylex();
 FILE* yyin; 
 int yylval; 
 int jump_label=0;
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);
 
 /* Verifie si le symbole donné est dans la table */
 int find(char *symbol,Type type);
 /* insert le symbole "symbol" de type "type" dans la table*/
 void insert_symbol(char* symbol,Type type); 
 /* Met a jour le symbol dans le table*/
 void update_symbol(char* symbol,Type type,int value);
 
  /* Modifier les 2 fonctions
	-> utiliser table des symbole
 */
 void stockage(void);
 void restoration(void); 
 void ifand();
 void ifor();
 
 Symbol* table; /*MAX_SIZE]; Table des symbol */
 int nbElemTable=0; /* Nombre de variable dans la table */
 int nbElemFonc=0; /* Nombre de variable dans la fonctions */
 
%}


%left NOTELSE
%left ELSE
%left '='
%left '+'
%left '-'
%left '*'
%left '/'
%left '%'
%left '('
%left ')'

%token IF ELSE PRINT 

%token WHILE NUM IDENT CARACTERE
%token MAIN
%token VOID
%token RETURN

%token CONST
%token INT CHAR
%token TRUE FALSE

/*
%union {
	int entier;
	char* string;
	char caract;
}


%token <entier> NUM 
%token <string> IDENT
%token <string> CARACTERE

%type <entier> Ifbool IfboolONE
%type <entier> JUMPELSE JUMPIFEQUAL JUMPIFNOT JUMPIFNOTEQUAL JUMPIFGEQ JUMPIFGREATER JUMPIFLEQ JUMPIFLESS
%type <entier> Exp

*/
%%

Progamme : 
	DeclConst DeclVarPuisFonct DeclMain
    ;

/* Declaration de la liste des constante */	
DeclConst: 
	/* vide */
	| CONST ListConst ';' DeclConst /* Ajout dans table des symbol */	   
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
	
/* endroit ou Rajouter dans table des symbol */
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
	EnTeteFonct { nbElemFonc = 0;} Corps 
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
	| INT IDENT /*{ insert_symbol($2,integer); }*/
	| CHAR IDENT /*{ insert_symbol($2,caracter); }*/	
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
	| DeclVar INT ListVar ';' /* Ajout dans table des symbole */ 
	| DeclVar CHAR ListVar ';' /* Ajout dans table des symbole */
	;

SuiteInstr :
	/*vide*/
	| Instr SuiteInstr       
    ;
	
Instr :
	LValue '=' Exp ';' { /* update_symbol (LValue,Exp) */ }
	| IF '(' Ifbool ')' InstrIF
		
	| WHILE  { instarg("LABEL",$$=jump_label++);} '(' Ifbool ')' {inst("POP");instarg("JUMPF",$$=jump_label++);}      	
		Instr	{instarg("JUMP",$2); instarg("LABEL",$6);}
	
	| RETURN Exp ';' { /* $$=Exp Jump */
	
	}
	| RETURN ';' { /* Jump */
	
	}
	/* Appel d'une fonction' */
	| IDENT '(' Arguments ')' ';' { /* Jump -> label de IDENT */ 
	
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
	| Exp '%' Exp {
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
	| '(' Exp ')' { $$=$2; }
	| LValue { $$=$1; }
	| NUM { 
		instarg("SET",$1);
        inst("PUSH"); 
    }
	| CARACTERE { /* A voir */
		instarg("SET",$1);
        inst("PUSH"); 
	}
	| IDENT '(' Arguments ')' { } /* Jump -> label fonctions */
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

int find(char *symbol,Type type){
	int i;
	for(i=nbElemTable;i>0;i--){
		if(strcmp(table[i].name,symbol) && table[i].type == type)
			return i;
	}
	return -1;
}


void insert_symbol(char* symbol,Type type){
	if(find(symbol,type)<0){
		nbElemTable++;
		nbElemFonc++;
		if(NULL ==(table = (Symbol*)realloc(table,nbElemTable))){
			perror("realloc\n");
			exit(EXIT_FAILURE);
		}
		
		table[nbElemTable].name=(char*)calloc(sizeof(char),strlen(symbol)+1);
		strcpy(table[nbElemTable].name,symbol);
		table[nbElemTable].type = type;
		/*if(type == 1) integer 
			table[nbElemTable].taille=sizeof(int);
		else
			table[nbElemTable].taille=sizeof(char);*/
		
		
		
	}	
}

void update_symbole(char* symbol,Type type,int value){
	int i=-1;
	if(0<=(i=find(symbol,type))){
		table[i].value = value;
	}
}

void delete_symbol(){
	nbElemTable--;
	if(NULL ==(table = (Symbol*)realloc(table,nbElemTable))){
		perror("realloc\n");
		exit(EXIT_FAILURE);
	}
}

void delete_symbol_fonc(){
	int i=-1;
	for(i=nbElemTable;i>nbElemTable-nbElemFonc;i--){
		delete_symbol();
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
  yyparse();

  endProgram();
  return 0;
}
