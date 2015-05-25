%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
int yyerror(char*);
int yylex();
 FILE* yyin; 
 int yylval; 
 int jump_label=0;
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);
 void stockage(void);
 void restoration(void);
 void my_realloc(int **labels,int fin);
 
 int *labels;
 int fin=0;
 
 int x;
 
%}

%token IF ELSE PRINT NOMBRE_ENTIER ALLOC
%token IDENT
%token WHILE


%left NOTELSE
%left ELSE
%left '='
%left '+'
%left '-'
%left '*'
%left '/'


%%
PROGRAMME : /* rien */ | PROGRAMME INSTRUCTION 
       ;
INSTRUCTION :
	  PRINT E ';' {
	  	inst("POP"); 
      	inst("WRITE");
	  	comment("---affichage");
	  }
	  /* marche pas */  
	  | IDENT '=' E ';' {   stockage();    } 
	  
      | IF '(' E '<' E ')' JUMPIFLESS INSTRUCTION %prec NOTELSE { instarg("LABEL",$7); } 
      | IF '(' E '<' E ')' JUMPIFLESS INSTRUCTION ELSE JUMPELSE 
      		{ instarg("LABEL",$7); } INSTRUCTION {instarg("LABEL",$10);}
      		
      | IF '(' E '<''=' E ')' JUMPIFLEQ INSTRUCTION %prec NOTELSE { instarg("LABEL",$8); }
      | IF '(' E '<''=' E ')' JUMPIFLEQ INSTRUCTION ELSE JUMPELSE 
      		{ instarg("LABEL",$8); } INSTRUCTION {instarg("LABEL",$11);}
      		
      | IF '(' E '>' E ')' JUMPIFGREATER INSTRUCTION %prec NOTELSE { instarg("LABEL",$7); }
      | IF '(' E '>' E ')' JUMPIFGREATER INSTRUCTION ELSE JUMPELSE 
      		{ instarg("LABEL",$7); } INSTRUCTION {instarg("LABEL",$10);}
      		
      | IF '(' E '>''=' E ')' JUMPIFGEQ INSTRUCTION %prec NOTELSE { instarg("LABEL",$8); }
      | IF '(' E '>''=' E ')' JUMPIFGEQ INSTRUCTION ELSE JUMPELSE 
      		{ instarg("LABEL",$8); } INSTRUCTION {instarg("LABEL",$11);}
      		
      | IF '(' E '=''=' E ')' JUMPIFEQUAL INSTRUCTION %prec NOTELSE { instarg("LABEL",$8); }
      | IF '(' E '=''=' E ')' JUMPIFEQUAL INSTRUCTION ELSE JUMPELSE 
      		{ instarg("LABEL",$8); } INSTRUCTION {instarg("LABEL",$11);}
      
      | IF '(' E '!''=' E ')' JUMPIFNOTEQUAL INSTRUCTION %prec NOTELSE { instarg("LABEL",$8); }
      | IF '(' E '!''=' E ')' JUMPIFNOTEQUAL INSTRUCTION ELSE JUMPELSE 
      		{ instarg("LABEL",$8); } INSTRUCTION {instarg("LABEL",$11);}
      
      | WHILE { instarg("LABEL",jump_label++);fin++;my_realloc(&labels,fin);labels[fin-1]=jump_label-1;} WHILEINSTRUCTION
      
      | '{' INSTRUCTIONETOILE '}' { }
      ;
WHILEINSTRUCTION:
		'(' E '<' E ')' JUMPIFLESS INSTRUCTION { instarg("JUMP",labels[fin-1]);instarg("LABEL",$6);fin--;
     													 my_realloc(&labels,fin);} 
		| '(' E '<''=' E ')' JUMPIFLEQ INSTRUCTION { instarg("JUMP",labels[fin-1]);instarg("LABEL",$7);fin--;
     													 my_realloc(&labels,fin);} 
		| '(' E '>' E ')' JUMPIFGREATER INSTRUCTION { instarg("JUMP",labels[fin-1]);instarg("LABEL",$6);fin--;
     													 my_realloc(&labels,fin);} 
		| '(' E '>''=' E ')' JUMPIFGEQ INSTRUCTION { instarg("JUMP",labels[fin-1]);instarg("LABEL",$7);fin--;
     													 my_realloc(&labels,fin);} 
		| '(' E '=''=' E ')' JUMPIFEQUAL INSTRUCTION { instarg("JUMP",labels[fin-1]);instarg("LABEL",$7);fin--;
     													 my_realloc(&labels,fin);} 
		| '(' E '!''=' E ')' JUMPIFNOTEQUAL INSTRUCTION { instarg("JUMP",labels[fin-1]);instarg("LABEL",$7);fin--;
     													 my_realloc(&labels,fin);} 

;      

      
INSTRUCTIONETOILE  : /* rien*/ | INSTRUCTIONETOILE INSTRUCTION       
      ;

 
JUMPIFEQUAL:{
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("EQUAL");
		instarg("JUMPF", $$=jump_label++);
	}
	;
	
JUMPIFNOTEQUAL:{
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("NOTEQ");
		instarg("JUMPF", $$=jump_label++);
	}
	;   	      
      
JUMPIFLESS :  {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("LESS");
		instarg("JUMPF", $$=jump_label++);
	}
	;
JUMPIFLEQ :  {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("LEQ");
		instarg("JUMPF", $$=jump_label++);
	}
	;	 
JUMPIFGREATER :  {
		inst("POP"); 
    	inst("SWAP"); 
		inst("POP");
		inst("GREATER");
		instarg("JUMPF", $$=jump_label++);
	}	 
	;
	
JUMPIFGEQ :  {
		inst("POP"); 
        inst("SWAP"); 
		inst("POP");
		inst("GEQ");
	  	instarg("JUMPF", $$=jump_label++);
	 }	 
	 ;	 
	 
JUMPELSE : {
	instarg("JUMP", $$=jump_label++);

	}	 
	;	 
	

	 
E : E '+' E {
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

void my_realloc(int **labels,int fin){
	int *tmp;
	tmp=realloc(*labels,fin+1);
	if(tmp==NULL){
		perror("realloc");
		exit(EXIT_FAILURE);	
	}
	*labels=tmp;
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
