%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#define MAX_SIZE 256

/* A modifier */
typedef enum {
	BOOLEEN=0,
	ENTIER
}Type;

/* Rajout du type boolean
	-> clarifie le code
 */
typedef enum {
	FALSE=0,
	TRUE
}boolean;

typedef struct {
	Type type;
	char* name;
	int taille;
	int valeur; /*  */

}Table_symbol;

int yyerror(char*);
int yylex();
 FILE* yyin; 
 int yylval; 
 int jump_label=0;
 
 int *labels;
 int x; 
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);
 
 /* Verifie si le symbole donner est dans la table */
 boolean find(char *symbol);
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

%token IF ELSE PRINT NUM ALLOC
%token IDENT
%token WHILE
%token MAIN
%token TYPE
%token VOID
%token READ READCH
%token RETURN
%token CARACTERE
%token CONST

%left NOTELSE
%left ELSE
%left '='
%left '+'
%left '-'
%left '*'
%left '/'


%%

PROGRAMME : 
	DeclConst DeclVarPuisFonct DeclMain
    ;

/* Declaration de la liste des constante */	
DeclConst: /* Rien */
	| DeclConst CONST ListConst ';'	   
	;
  
ListConst : 
	| ListConst ',' IDENT '=' Litteral
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
	| TYPE ListVar ';' DeclVarPuisFonct
	| DeclFonct
	;
	
ListVar : 
	ListVar ',' Ident
	| Ident
	;
Ident : 
	IDENT Tab
	;
Tab : 
	/* Rien */
	| Tab '[' NUM ']'	
	;
DeclMain :
	EnTeteMain Corps
	;
EnTeteMain: 
	MAIN '(' ')'
	;
DeclFonct : 
	DeclFonct DeclUneFonct
	| DeclUneFonct
	;
DeclUneFonct:
	EnTeteFonct Corps
	;

EnTeteFonct : 
	TYPE IDENT '(' Parametres ')'
	| VOID IDENT '(' Parametres ')'
	;
Parametres : 
	VOID
	| ListTypVar
	;
ListTypVar :
	ListTypVar ',' TYPE IDENT
	| TYPE IDENT	
	;
	/* int x*/
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
	/*rien*/
	| DeclVar TYPE ListVar ';' { insert_symbol((char*)$3,$2);} /* Erreur pour le moment */
	;

SuiteInstr :
	/* rien*/
	| SuiteInstr Instr       
    ;
	  
InstrComp : 
	'{' SuiteInstr '}'
	;
	
Instr :
	LValue '=' E ';'{ printf("#---------truc\n");
	 
	}
	| IF '(' Ifbool{inst("POP");instarg("JUMPF",$$=jump_label++);instarg("LABEL",$3);}')' InstrIF
		
	| WHILE { instarg("LABEL",$$=jump_label++);} '(' Ifbool')' {inst("POP");instarg("JUMPF",$$=jump_label++);}      	
		Instr	{instarg("JUMP",$2); instarg("LABEL",$6);}
	
	| RETURN E ';' { 
	
	}
	| RETURN ';' { 
	
	}
	| IDENT '(' Arguments ')' ';' { 
	
	}
	| READ  '(' IDENT ')' ';'  { 
		inst("READ");
		inst("PUSH");	
	} 
	| READCH  '(' IDENT ')' ';' {
		 inst("READCH");
		 inst("PUSH");
	} 
	| PRINT '(' E ')' ';' { 
		inst("POP"); 
      	inst("WRITE");
	}
	| ';'
	| InstrComp	
	;	
	
Arguments: 
	/* rien */ 
	| ListExp
	;

LValue :
	/* rien */ 
	| IDENT TabExp	
	;
TabExp:
	/* */
	| TabExp '[' E ']'

	;

ListExp : 
	ListExp ',' E
	| E  
	;	

/* A completer */	 
E : 
	/* Exp ADDSUB Exp */
	E '+' E {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("ADD");
		inst("PUSH");
	}
	| E '-' E {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("SUB");
		inst("PUSH");
	}
	/* Exp DIVSTAR Exp */
	| E '*' E {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("MUL");
		inst("PUSH");
	}	
	| E '/' E {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("DIV");
		inst("PUSH");
	}
	| E '%' E {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("MOD");
		inst("PUSH");
	}
	| E '<' E JUMPIFLESS { $$=$4;}
    | E '>' E JUMPIFGREATER { $$=$4;}
    | E '<''=' E JUMPIFLEQ {$$=$5;}    
    | E '>''=' E JUMPIFGEQ {$$=$5;}
    | E '=''=' E JUMPIFEQUAL {$$=$5;}
    | E '!''=' E JUMPIFNOTEQUAL {$$=$5;}
    
	| '+' E { 
		inst("POP");
		inst("ADD");
		inst("PUSH"); 
	}
	| '-' E {
		inst("POP");
		inst("SUB");
		inst("PUSH"); 
	}
	| E '|''|' E { }
	| E '&''&' E { }	
	| '!' E { }
	| '(' E ')' { }
	| LValue { }
	| NUM { 
		instarg("SET",$1);
        inst("PUSH"); 
    }
	| CARACTERE { }
	| IDENT '(' Arguments ')' { }
	/*| IDENT { restoration();}*/
  ;
/*
Instr :
	  PRINT E ';' {
	  	inst("POP"); 
      	inst("WRITE");
	  	comment("---affichage");
	  }

	  | IDENT '=' E ';' {   stockage();    } 
	  
	  | IF '(' Ifbool{inst("POP");instarg("JUMPF",jump_label+1);instarg("LABEL",$3);jump_label++;}')' InstrIF
	  
      | WHILE { instarg("LABEL",jump_label++);fin++; my_realloc(&labels,fin); labels[fin-1]=jump_label-1;} InstrWhile
      
      | InstrComp
      
      ;

InstrWhile:
		'(' Ifbool ')' {inst("POP"); instarg("JUMPF",jump_label+1); instarg("LABEL",$2); jump_label++; jump_label++;} 
		Instr {instarg("JUMP",labels[fin-1]); instarg("LABEL",$2+1); fin--; my_realloc(&labels,fin);} 
		;
      */

InstrIF :
	 | Instr %prec NOTELSE {instarg("LABEL",jump_label++);}
     | Instr ELSE JUMPELSE {instarg("LABEL",$3-1);} Instr {instarg("LABEL",$3);}
	 ; 
Ifbool:
	 IfboolONE  '|' '|' Ifbool {ifor();$$=$4;}
	 | IfboolONE '&' '&' Ifbool {ifand();$$=$4;}	 
	 | IfboolONE {$$=$1;}
	;

IfboolONE: 
    |  E '<' E JUMPIFLESS { $$=$4;}
    |  E '>' E JUMPIFGREATER { $$=$4;}
    |  E '<''=' E JUMPIFLEQ {$$=$5;}    
    |  E '>''=' E JUMPIFGEQ {$$=$5;}
    |  E '=''=' E JUMPIFEQUAL {$$=$5;}
    |  E '!''=' E JUMPIFNOTEQUAL {$$=$5;}
	| "true" {instarg("SET",1); inst("PUSH");}
	| "false" {instarg("SET",0); inst("PUSH");}
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

boolean find(char *symbol){
	int i;
	for(i=0;i<MAX_SIZE;i++){
		if(strcmp(table[i].name,symbol))
			return TRUE;
	}
	return FALSE;
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
