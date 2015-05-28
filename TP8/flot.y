%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

 int yyerror(char*);
 int yylex();
 
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);

 void stockage(void);
 void restoration(void);
 
 void ifand();
 void ifor();
 
 FILE* yyin; 
 int yylval; 
 int jump_label=0;

%}

%token IF ELSE PRINT NOMBRE_ENTIER IDENT
%token WHILE
%token TRUE FALSE

%left NOTELSE
%left ELSE
%left '='
%left '+'
%left '-'
%left '*'
%left '/'


%%
PROGRAMME :/* vide */ | INSTRUCTION PROGRAMME 

       ;
INSTRUCTION :
	  PRINT E ';' {
	  	inst("POP"); 
      	inst("WRITE");
	  	comment("---affichage");
	  }

	  | IDENT '=' E ';' {   stockage();    } 	  
	  
	  | IF '(' IFBOOL ')' JUMPIF INSTRUCTION %prec NOTELSE {instarg ("LABEL", $5) ; }

	  | IF '(' IFBOOL ')' JUMPIF INSTRUCTION ELSE JUMPELSE{ instarg("LABEL", $5) ; } INSTRUCTION{ instarg("LABEL", $8) ;}	
	  
	  | WHILE  { instarg("LABEL",$$=jump_label++);} '(' IFBOOL ')' 
	  {inst("POP");jump_label++;instarg("JUMPF",$$=jump_label++);instarg("LABEL",$2+1);}      	
		INSTRUCTION	{instarg("JUMP",$2); instarg("LABEL",$6);}
		
	  | '{' INSTRUCTIONETOILE '}'
      
      ;	
		
	  /*| IF '(' IFBOOL{inst("POP");instarg("JUMPF",$$=jump_label++);instarg("LABEL",$3);}')'
	   INSTRUCTION %prec NOTELSE {instarg("LABEL",jump_label++);}
	  
	  | IF '(' IFBOOL{inst("POP");instarg("JUMPF",$$=jump_label++);instarg("LABEL",$3);}')'
	  INSTRUCTION ELSE JUMPELSE {instarg("LABEL",$3-1);} INSTRUCTION {instarg("LABEL",$8);}
	  
	  | IF '(' IFBOOL ')' {inst("POP");instarg("JUMPF",$$=jump_label);}
  	  	INSTRUCTION %prec NOTELSE {instarg("LABEL",$3);}
	  
	  | IF '(' IFBOOL ')' {inst("POP");instarg("JUMPF",$$=jump_label);} INSTRUCTION ELSE JUMPELSE 
	  /* instarg("JUMP", $$=jump_label++); {instarg("LABEL",$8);} INSTRUCTION {instarg("LABEL",$9);}
*/
      
	  /* { instarg("LABEL",$$=jump_label++);}  compte comme une instruction
	  		WHILE = $1 
	  		{ instarg("LABEL",$$=jump_label++);} = $2 
	  		'(' = $3 
	  		IFBOOL = $4 
	  		')' = $5
	  */  

      

INSTRUCTIONETOILE  : /* rien*/ | INSTRUCTION INSTRUCTIONETOILE     
      ;
      /*
      test -> | IF {instarg("LABEL",$$=jump_label++);} '(' IFBOOL ')' {inst("POP");instarg("JUMPF",$$=jump_label++);}
      
      IF '(' Ifbool{inst("POP");instarg("JUMPF",jump_label+1);instarg("LABEL",$3);jump_label++;}')' InstrIF
      
INSTRUCTIONIF : INSTRUCTION %prec NOTELSE {instarg("LABEL",jump_label++);}
				| INSTRUCTION ELSE JUMPELSE {instarg("LABEL",$3-1);} INSTRUCTION {instarg("LABEL",$3);}
				; 
				*/
IFBOOL:
	 IFBOOLONE  '|' '|' IFBOOL {ifor();$$=$4;}
	 | IFBOOLONE '&' '&' IFBOOL {ifand();$$=$4;}	 
	 | IFBOOLONE {$$=$1;}
	;

IFBOOLONE: 
    |  E '<' E JUMPIFLESS { $$=$4;}
    |  E '>' E JUMPIFGREATER { $$=$4;}
    |  E '<''=' E JUMPIFLEQ {$$=$5;}    
    |  E '>''=' E JUMPIFGEQ {$$=$5;}
    |  E '=''=' E JUMPIFEQUAL {$$=$5;}
    |  E '!''=' E JUMPIFNOTEQUAL {$$=$5;}
	| TRUE {instarg("SET",1); inst("PUSH");$$=jump_label;}
	| FALSE {instarg("SET",0); inst("PUSH");$$=jump_label;}
	;

JUMPIF :{
	inst("POP");
	instarg("JUMPF", $$=jump_label+1);
	instarg("LABEL",jump_label++);
	jump_label++;
};
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
	

	 
	
E:	 E '+' E {
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
	| IDENT {
		restoration();
    }
	| NOMBRE_ENTIER {
		instarg("SET",$1);
        inst("PUSH");
    }
  ;
/* 
  
  
  */
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
/*
void my_realloc(int **labels,int fin){
	int *tmp;
	tmp=realloc(*labels,fin+1);
	if(tmp==NULL){
		perror("realloc");
		exit(EXIT_FAILURE);	
	}
	*labels=tmp;
}
*/
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
