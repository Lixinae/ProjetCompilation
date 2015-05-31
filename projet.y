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
	voide=0,
	caracter,
	integer
}Type;

typedef struct {
	Type type;/*0: voide 
				1 : caracter
				2 : integer 
			  	*/
	char name[MAX_SIZE];
	int value;

}Symbol;


typedef struct {

	char name[MAX_SIZE]; /* Nom de la fonction */
	Type typeRetour; /* A voir pour l'utilisation */
	int label; /* Label correspondant a la fonction */
	int nbArg; /* Nombre d'arguments d'une fonction */
	Symbol listeArg[2048]; /* Contient la liste des arguments d'une fonction */
	int nbVar; /* Nombre de variable dans une fonction */
	Symbol listVar[2048]; /* Liste des variables de la fonction */

}Func;

 int yyerror(char*);
 int yylex();
 FILE* yyin; 
 
 int jump_label=0, jump_label_main,jump_label_neg=-1;
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);
 
 
 int find(char *symbol,Symbol* table,int size); /* Verifie si le symbole donné est dans la table */ 
 void insert_value(int value,Symbol* table,int indice);
 void insert_type(Type type,Symbol* table,int indice); /* Insert le type dans la table "table" */
 void insert_type_rec(Type type,Symbol* table,int nbElem,int* count); 
 void insert_symbol(char*,Symbol* table,int *indice); /* insert le symbole "symbol" de type "type" dans la table*/
 void update_symbol(char*,int,Symbol*,int size);/* Met a jour le symbol dans la table*/
 
 void delete_symbol_fonc();
 void printTabSymbol(Symbol*,int);
  /* Modifier les 2 fonctions
	-> utiliser table des symbole
 */
 /*
 void stockage(void);
 void restoration(void); */
 void ifand();
 void ifor();
 
 int find_fonc(char*);
 void insert_fonc_tab(char*,int,Type);
 
 void printTabFunc();
 
 

 int countSymbolVar=0; /* Nombre de variable en parametre de fonction */
 int countSymbolVarFonc=0; /* */
 
 FILE* fd_fichier=NULL;
 
 
 Symbol tableS[2048]; /* Table des symbol global */
 int nbElemTable=0; /* Nombre de variable dans la table des symbol global */
 
 
 Func tableFunc[1024]; /* Table des fonction */
 int nbFunc=1; /* Nombre de fonction dans la table des fonction */
 
 int indFuncCourrant=-1; /* Indice de la fonction dans laquel on se trouve actuellement */
 
 Symbol tableVarFonction[2048]; /* Table des symbol pour variable dans fonction */
 int nbElemFonc=0; /* Nombre de variable dans tout les fonction*/
 
 int indMain=0;/* Indice de la fonction main dans le tableau de fonction */
 
%}


%left NOTELSE
%left ELSE



%left '|'
%left '&'
%left '!'
%left '<'
%left '>'

%left '='
%left '+'
%left '-'
%left '%'
%left '*'
%left '/'
%left '('
%left ')'

%token IF ELSE PRINT 

%token WHILE 
%token MAIN
%token VOID
%token RETURN

%token CONST
%token INT CHAR
%token TRUE FALSE


%union {
	int entier;
	char string[256];
	char caract;
}


%token <entier> NUM READ
%token <string> IDENT 
%token <caract> CARACTERE READCH

%type <entier> LABEL JUMPIF JUMPWHILE

/*
%type <entier> Ifbool IfboolONE

%type <entier> JUMPELSE JUMPIFEQUAL JUMPIFNOT JUMPIFNOTEQUAL JUMPIFGEQ JUMPIFGREATER JUMPIFLEQ JUMPIFLESS
*/
%type <entier> JUMPELSE 
%type <entier> Exp NombreSigne Type_val Type_valFonc
%type <string> LValue Ident




%%

Progamme : 
	/* Jump au label du main  */
	DeclConst {jump_label_main = jump_label; instarg("JUMP",jump_label++);} 
		DeclVarPuisFonct /*{printTabSymbol(tableS,nbElemTable);}*/
			DeclMain
    ;

/* Declaration de la liste des constante global */	
DeclConst: 
	/* vide */
	| CONST ListConst ';' DeclConst /* Ajout dans table des symbol */	   
	;  
ListConst : 
	IDENT '=' Litteral ',' {insert_symbol((char*)$1,tableS,&nbElemTable);} 	ListConst 
	| IDENT '=' Litteral {insert_symbol((char*)$1,tableS,&nbElemTable);}
	;
Litteral :
	NombreSigne {
				insert_value($1,tableS,nbElemTable);
				insert_type(2,tableS,nbElemTable);
	}
	| CARACTERE {
				insert_value($1,tableS,nbElemTable);
				insert_type(1,tableS,nbElemTable);
	}
	;

/* Liste des constante d'une fonction */	
DeclConstFonc:
	/* vide */
	| CONST ListConstFonc ';' DeclConstFonc
	;	
ListConstFonc:
	IDENT '=' LitteralFonc ',' {insert_symbol((char*)$1,tableFunc[nbFunc].listVar,&nbElemFonc);} ListConstFonc 
	| IDENT '=' LitteralFonc {insert_symbol((char*)$1,tableFunc[nbFunc].listVar,&nbElemFonc);}
	;	
LitteralFonc:
	NombreSigne {
				insert_value($1,tableFunc[nbFunc].listVar,nbElemFonc);
				insert_type(2,tableFunc[nbFunc].listVar,nbElemFonc);
	}
	| CARACTERE { 
				insert_value($1,tableFunc[nbFunc].listVar,nbElemFonc);
				insert_type(1,tableFunc[nbFunc].listVar,nbElemFonc);
	}
	;

NombreSigne:
	NUM {$$=$1;}
	| '+' NUM {$$=$2;}
	| '-' NUM {$$=$2;}
	;

DeclVarPuisFonct :
	/* vide */
	| INT ListVar {insert_type_rec(2,tableS,nbElemTable,&countSymbolVar); } ';' DeclVarPuisFonct 
	| CHAR ListVar {insert_type_rec(1,tableS,nbElemTable,&countSymbolVar);} ';' DeclVarPuisFonct
	| DeclFonct
	;
/* endroit ou Rajouter dans table des symbol
	
	countSymbolVar ? -> compte le nombre de symbol dans une fonction 
 */ 
/* Ajout de variable dans la table des symbol global */ 
ListVar : 
	Ident Type_val ',' ListVar {countSymbolVar++;insert_type($2,tableS,nbElemTable);insert_symbol((char*)$1,tableS,&nbElemTable);}
	| Ident {countSymbolVar++;insert_symbol((char*)$1,tableS,&nbElemTable);}
	;
Type_val:{
		$$=tableS[nbElemTable].type;/* A modifier */
	}	
	;
	
/* Pour l'ajout de variable dans la table des symbole de fonction */	
ListVarFonc : 
	Ident Type_valFonc ',' ListVarFonc {/*countSymbolVar++;*/
		countSymbolVarFonc++; /* compte le nombre de variable dans la fonction */ 
		insert_type($2,tableFunc[nbFunc-1].listVar,nbElemFonc);
		insert_symbol((char*)$1,tableFunc[nbFunc-1].listVar,&nbElemFonc);
		}
	| Ident {
		countSymbolVarFonc++;
		insert_symbol((char*)$1,tableFunc[nbFunc-1].listVar,&nbElemFonc);}
	;
Type_valFonc:{
		$$=tableFunc[nbFunc-1].listVar[nbElemFonc].type;
		printf("#----tableFunc[%d].listVar[%d].type = %d\n",nbFunc-1,nbElemFonc,tableFunc[nbFunc-1].listVar[nbElemFonc].type);
	}	
	;	
	
Ident : 
	IDENT Tab
	;
Tab : 
	/* vide */
	| '[' NUM ']' Tab 	
	;
DeclMain :
	EnTeteMain { instarg("LABEL",jump_label_main);printf("#----nbFunc = %d\n",nbFunc);} Corps 
	;
EnTeteMain: 
	MAIN '(' ')'
	;
DeclFonct : 
	DeclUneFonct DeclFonct
	| DeclUneFonct
	;
DeclUneFonct:
	EnTeteFonct { instarg("LABEL",jump_label++);} Corps
	;
	
EnTeteFonct : /* A modifier */
	INT IDENT '(' Parametres ')' {insert_fonc_tab($2,jump_label,2);}
	| CHAR IDENT '(' Parametres ')' {insert_fonc_tab($2,jump_label,1);}
	| VOID IDENT '(' Parametres ')' {insert_fonc_tab($2,jump_label,0);}
	;
	
Parametres : 
	VOID
	| ListTypVar
	;
	
	/* Verifier bon nombre arguments */
	/* A modifier */
ListTypVar : /* Pour chaque variable lu , on incremente le nombre de variable de la fonction */
	INT IDENT { insert_type(2,tableFunc[nbFunc].listeArg,tableFunc[nbFunc].nbArg);
				insert_symbol($2,tableFunc[nbFunc].listeArg,&tableFunc[nbFunc].nbArg);
				; 
			 	}
			 ',' ListTypVar 
			 
	| CHAR IDENT {
				insert_type(1,tableFunc[nbFunc].listeArg,tableFunc[nbFunc].nbArg);
				insert_symbol($2,tableFunc[nbFunc].listeArg,&tableFunc[nbFunc].nbArg);
				
			    }
			 ',' ListTypVar  
			 
	| INT IDENT {
				insert_type(2,tableFunc[nbFunc].listeArg,tableFunc[nbFunc].nbArg);
				insert_symbol($2,tableFunc[nbFunc].listeArg,&tableFunc[nbFunc].nbArg);
				 
				}
	| CHAR IDENT {
				insert_type(1,tableFunc[nbFunc].listeArg,tableFunc[nbFunc].nbArg); 
				insert_symbol($2,tableFunc[nbFunc].listeArg,&tableFunc[nbFunc].nbArg);
				
				}	
	;
Corps : 
	'{' {nbElemFonc=0;} 
		DeclConstFonc 
		DeclVar 
		{
				tableFunc[nbFunc-1].nbVar = nbElemFonc;
				/*printf("#------Table arg de tableFunc[%d] \n",nbFunc-1);
				printTabSymbol(tableFunc[nbFunc-1].listeArg,tableFunc[nbFunc-1].nbArg);
				printf("#------Table var de tableFunc[%d] \n",nbFunc-1);
				printTabSymbol(tableFunc[nbFunc-1].listVar,tableFunc[nbFunc-1].nbVar);
				printf("#------Table var de tableFunc[%d] \n",nbFunc);
				printTabSymbol(tableFunc[nbFunc].listVar,tableFunc[nbFunc].nbVar);*/
		}	
			/**/
		 
		SuiteInstr '}'
	;

DeclVar : 
	/*vide*/						
	| INT ListVarFonc {insert_type_rec(2,tableFunc[nbFunc-1].listVar,nbElemFonc,&countSymbolVarFonc);} ';' DeclVar 
	| CHAR ListVarFonc {insert_type_rec(1,tableFunc[nbFunc-1].listVar,nbElemFonc,&countSymbolVarFonc);} ';' DeclVar 
	;
/*DeclVarPuisFonct :
	/* vide 
	| INT ListVar {insert_type_rec(2,tableS,nbElemTable,&countSymbolVar); } ';' DeclVarPuisFonct 
	| CHAR ListVar {insert_type_rec(1,tableS,nbElemTable,&countSymbolVar);} ';' DeclVarPuisFonct */
	
SuiteInstr :
	/*vide*/
	| Instr SuiteInstr       
    ;
	
	
/* Faire le truc sur les variables */	
Instr :
																		
	LValue '=' Exp ';' {	/* probleme -> comment savoir si dans une fonction ou dans global ?  */ 
						/*  Si symbole dans liste des arguments de la fonction courante{
								-> update argument 
							}
							Si non{
								verifier si symbole dans tableVarFonction des fonctions (taille = nbElemFonc) {
									-> update celui de la fonction
								}
								Sinon{
									 -> update global 
								}
							}*/
						/*printf("nbElemTable = %d\n",nbElemTable);
						printTabSymbol(tableS,nbElemTable);	
						printf("#-----indFuncCourrant %d nbFunc %d\n",indFuncCourrant,nbFunc);*/
						int indice=0;
						/* Au debut */
						if(indFuncCourrant == -1){
							indice = nbFunc-1;
						}
						else{
							indice = indFuncCourrant;	
						}
						
						printf("#----LValue %s = %d\n",$1,$3);
						int i=find($1,tableFunc[indice].listeArg,tableFunc[indice].nbArg);
						if(i>=0){
							update_symbol($1,$3,tableFunc[indice].listeArg,i);
						}
						else{
							i=find($1,tableFunc[indice].listVar,tableFunc[indice].nbVar);
							if(i>=0){
								update_symbol($1,$3,tableFunc[indice].listVar,i);							
							}
							else{
								indice = nbFunc;
								i=find($1,tableFunc[indice].listVar,tableFunc[indice].nbVar);
								if(i>=0){
									update_symbol($1,$3,tableFunc[indice].listVar,i);							
								}
								else{
									i=find($1,tableS,nbElemTable);
									if(i>=0){
										update_symbol ($1,$3,tableS,i); 
									}
									else{
										fprintf(fd_fichier,"#------Symbol %s doesn't exist 562\n",$1); 
									}
								}							
							}						
						}
						/*fprintf(fd_fichier,"#-------LValue %s = %d\n",$1,$3);*/
	}
		
	| IF '(' Exp ')' JUMPIF Instr %prec NOTELSE {instarg ("LABEL", $5) ; }

	| IF '(' Exp ')' JUMPIF Instr ELSE JUMPELSE{ instarg("LABEL", $5) ; } Instr { instarg("LABEL", $8) ;}		
		
	| WHILE  LABEL '(' Exp ')' JUMPWHILE {instarg("LABEL",$2+1);} Instr {instarg("JUMP",$2); instarg("LABEL",$6);}	

	| RETURN Exp ';' {  instarg("SET",$2); printf("#-----return %d\n",$2);/* $$=Exp Jump */
		/*;inst("PUSH"); -> set deja fait dans exp*/inst("RETURN");
	}
	| RETURN ';' {
		inst("RETURN");
	}
	/* Appel d'une fonction' */
	| IDENT {indFuncCourrant=find_fonc($1);} '(' Arguments ')' ';' 
			{
				if(indFuncCourrant>=0){ 
					instarg("CALL",indFuncCourrant);	
				} 
				else { 
					fprintf(fd_fichier,"Function %s doesn't exist\n",$1); 
					exit(EXIT_FAILURE);
				}
	
	}
		/* Lis un entier tape au clavier -> int a; read (a) -> a = truc tapé au clavier*/
	| READ '(' IDENT ')' ';'  {/* inst("READ");inst("PUSH"); -> recup ce qui a été stocker dans la pile
																 update_symbol();
	*/
	} 
		/* Lis un caracter tape au clavier -> */
	| READCH '(' IDENT ')' ';' { /*inst("READCH");inst("PUSH");
	*/
	}
	/* recup symbole dans la table , push symbol -> pop -> write */
	| PRINT '(' Exp {/*int i=find($3);  / Probleme -> peut pas verifier type -> Exp = int /
						inst("POP");
						if(table[i].type==2){
							inst("WRITE");
						}
						else if(table[i].type==1){
							inst("WRITECH");
						} */
						/*inst("POP");*/
						inst("WRITE");
						comment("---affichage");}')' ';' 
	
	| ';'
	| '{' SuiteInstr '}'
	;	

/* 
IF '(' Exp ')' JUMPIF Instr %prec NOELSE {instarg ("LABEL", $5) ; }

IF '(' Exp ')' JUMPIF Instr ELSE JUMPELSE{ instarg("LABEL", $5) ; } Instr { instarg("LABEL", $8) ;}

*/	
	
Arguments: 
	/* vide */ 
	| ListExp
	;

LValue :
	IDENT TabExp { }	
	;
TabExp:
	/* vide */
	| TabExp '[' Exp ']' 

	;
/* On ajoute dans le tableau des variable de fonction */

/* On met a jour */
ListExp : 
	ListExp ',' Exp {
		/*printf("#------ Liste exp indFuncCourrant = %d\n",indFuncCourrant);*/
		
		insert_value($3,tableFunc[indFuncCourrant].listeArg,tableFunc[indFuncCourrant].nbArg-1);} 
	| Exp {
		printf("#------ Liste exp indFuncCourrant = %d\n",indFuncCourrant);
		insert_value($1,tableFunc[indFuncCourrant].listeArg,tableFunc[indFuncCourrant].nbArg-1);
		
		printTabSymbol(tableFunc[indFuncCourrant].listeArg,tableFunc[indFuncCourrant].nbArg);
		} 
	;	

 
Exp : 
	/* Exp ADDSUB Exp */
	Exp '+' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("ADD");
		inst("PUSH");
		$$=$1+$3;
	}
	| Exp '-' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("SUB");
		inst("PUSH");
		$$=$1-$3;
	}
	
	/* Exp DIVSTAR Exp */
	| Exp '*' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("MUL");
		inst("PUSH");
		$$=$1*$3;
	}	
	| Exp '/' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("DIV");
		inst("PUSH");
		$$=$1/$3;
	}
	| Exp '%' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("MOD");
		inst("PUSH");
		$$=$1%$3;
	}
	/* Exp Comp Exp */
    | Exp '<' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("LESS");
		inst("PUSH");
		$$=$1<$3;
	}	
    | Exp '>' Exp {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("GREATER");
		inst("PUSH");
		$$=$1>$3;
	}
    | Exp '<''=' Exp  {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("LEQ");
		inst("PUSH");
		$$=$1<=$4;
	}     
    | Exp '>''=' Exp {
    	inst("POP"); 
        inst("SWAP"); 
		inst("POP");
		inst("GEQ");
		inst("PUSH");
		$$=$1>=$4;
	}
    | Exp '=''=' Exp {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("EQUAL");
		inst("PUSH");
		$$=$1==$4;
	}
    | Exp '!''=' Exp {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("NOTEQ");
		inst("PUSH");
		$$=$1!=$4;
	}
    /* ADDSUB Exp */
	| '(' '-' Exp ')' {
		inst("POP");
		inst("NEG");
		inst("PUSH");
		$$=-$3; 
	}
	
	/*Exp BOPE Exp */
	| Exp '|' '|' Exp {ifor();$$=($4==0)?($1==0)?0:$1/$1:$4/$4;}
	| Exp '&' '&' Exp {ifand();$$=($4==0)?0:($1==0)?0:$4/$4;}
	
	/* NEGATION Exp */	
    | '!' Exp { 
    	inst("POP");
    	instarg("JUMPF",jump_label_neg);
    	inst("PUSH");
    	inst("SWAP");
    	inst("POP");
    	inst("DIV");
    	instarg("LABEL",jump_label_neg--);
		inst("NEG");
		inst("SWAP");
		instarg("SET",1);
		inst("ADD");
		inst("PUSH");
		$$=($2==0)?$2:$2/$2;
	}
	| TRUE {instarg("SET",1); inst("PUSH");}
	| FALSE {instarg("SET",0); inst("PUSH");}

	| '(' Exp ')' { $$=$2; }
			/* Comment savoir si dans fonction ou global ? */
				/*  recherche dans fonction -> si pas dans fonction -> recherche global */
	| LValue { 			int indice=0;
						/* Au debut */
						if(indFuncCourrant == -1){
							indice = nbFunc-1;
						}
						else{
							indice = indFuncCourrant;	
						}
						int i=find($1,tableFunc[indice+1].listeArg,tableFunc[indice].nbArg);
						
						/*printf("#---i = %d,indFuncCourrant %d, indice %d $1 = %s \n",i,indFuncCourrant,indice,$1);
						*/
						if(i>=0){
							instarg("SET",tableFunc[indice].listeArg[i].value);
							inst("PUSH");
				 			$$=tableFunc[indice].listeArg[i].value;	
						}
						else{
							
							i=find($1,tableFunc[indice].listVar,tableFunc[indice].nbVar);
							if(i>=0){
								instarg("SET",tableFunc[indice].listVar[i].value);
								inst("PUSH");
				 				$$=tableFunc[indice].listVar[i].value;								
							}
							else{
								indice = nbFunc;
								
								/*printf("#------indice = %d,indFuncCourrant %d\n",indice,indFuncCourrant);*/
								i=find($1,tableFunc[indice].listVar,tableFunc[indice].nbVar);
								if(i>=0){
									instarg("SET",tableFunc[indice].listVar[i].value);
									inst("PUSH");
				 					$$=tableFunc[indice].listVar[i].value;							
								}
								else{
									i=find($1,tableS,nbElemTable);
									if(i>=0){
										instarg("SET",tableS[i].value);
				 						inst("PUSH");
				 						$$=tableS[i].value; 
									}
									else{
									fprintf(fd_fichier,"#------Symbol %s doesn't exist\n",$1); 
									}
								
								}							
							}				
						}
	
	/*
				int i=find($1,tableVarFonction,nbElemFonc);
				 Si trouve pas dans fonction -> recherche dans le global /
				if(i<0){
					i=find($1,tableS,nbElemTable);
					
					fprintf(fd_fichier,"#---$1 = %s i = %d table[%d].value = %d\n",$1,i,i,tableS[i].value);
					if(i>=0){
						instarg("SET",tableS[i].value);
				 		inst("PUSH");
				 		$$=tableS[i].value;	
					} 
					else { 
				 		fprintf(fd_fichier,"#---%s doesn't exist\n",$1); 
						exit(EXIT_FAILURE);
					}
								
				}
				else{
					instarg("SET",tableVarFonction[i].value);
				 	inst("PUSH");
				 	$$=tableVarFonction[i].value;
				}*/
				
	}
	| NUM { 
		instarg("SET",$1);
        inst("PUSH");
        $$=$1;
    }
	| CARACTERE { /* A voir */
		instarg("SET",$1);
        inst("PUSH"); 
        $$=$1;
	}
	| IDENT { indFuncCourrant=find_fonc($1);} '(' Arguments ')' {
									if(indFuncCourrant>=0){ 
										instarg("CALL",indFuncCourrant);	
									} 
									else { 
										fprintf(fd_fichier,"Function %s doesn't exist\n",$1); 
										exit(EXIT_FAILURE);
									} 
							  } 
  ;

 
JUMPELSE : {
	instarg("JUMP", $$=jump_label++);

	}	 
	;

LABEL : {
	instarg("LABEL",$$=jump_label++);
	}
	;
	
JUMPIF :{
	inst("POP");
	instarg("JUMPF", $$=jump_label+1);
	instarg("LABEL",jump_label++);
	jump_label++;
};

JUMPWHILE : {
	inst("POP");
	jump_label++;
	instarg("JUMPF",$$=jump_label++);
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
    instarg("JUMPF",jump_label_neg);
    inst("PUSH");
    inst("SWAP");
    inst("POP");
    inst("DIV");
    instarg("LABEL",jump_label_neg--);
	inst("NEG");
	inst("SWAP");
	instarg("SET",1);
	inst("ADD");
	instarg("JUMPF",jump_label);

}

void ifand(){
	inst("POP");
   	instarg("JUMPF",jump_label_neg);
   	inst("PUSH");
    inst("SWAP");
    inst("POP");
    inst("DIV");
    instarg("LABEL",jump_label_neg--);
	inst("SWAP");
	inst("POP");
	inst("ADD");
	inst("SWAP");
	instarg("SET",2);
	inst("LEQ");
	inst("PUSH");

}

void init_string(char *string,int size){
	int i;
	for(i=0;i<size;i++){
		string[i]='\0';
	}
}

void printTabFunc(){
	int i;
	for(i=nbFunc-1;i>=0;i--){
		fprintf(fd_fichier,"#------i = %d name : %s Type : %d Label : %d \n",i,tableFunc[i].name,tableFunc[i].typeRetour,tableFunc[i].label);
	}
}

void printTabSymbol(Symbol* table,int size){
	/* size = nbElemTable */
	int i;	
	for(i=size;i>=0;i--){
		fprintf(stdout,"#------table[%d].name = %s type : %d value : %d\n",i,table[i].name,table[i].type,table[i].value);
	}
}


int find(char *symbol,Symbol* table,int size){
	int i;	
	for(i=size;i>=0;i--){
		if(strcmp(table[i].name,symbol)==0)
			return i;
	}
	/*for(i=debut;i<fin;i++){
		if(strcmp(table[i].name,symbol)==0)
			return i;
	*/
	return -1;
}




void insert_value(int value,Symbol* table,int indice){
	/* indice = nbElemTable */
	table[indice].value=value;
}
void insert_type(Type type,Symbol* table,int indice){
	/* indice = nbElemTable */
	table[indice].type = type;
}

/*  */
void insert_type_rec(Type type,Symbol* table,int nbElem,int* count){
	/* nbElem = nbElemTable 
	*/
	while(*count>0){
		table[nbElem-(*count)].type = type;
		*count-=1;
	}
	

}

void insert_symbol(char* symbol,Symbol* table,int *indice){
	/* indice = nbElemTable */
	if(find(symbol,table,*indice)<0){
		/*table[nbElemTable].name=(char*)calloc(sizeof(char),strlen(symbol)+1);*/
		strncpy(table[*indice].name,symbol,strlen(symbol)+1);
		*indice+=1;
		
		/*if(NULL ==(table = (Symbol*)realloc(table,nbElemTable+1))){
			perror("realloc\n");
			exit(EXIT_FAILURE);
		}*/
	}
	else{
		fprintf(fd_fichier,"#-----Redeclaration of variable %s\n",symbol);	
	}	
}

void update_symbol(char* symbol,int value,Symbol* table,int ind){
	/*if((i=find(symbol,table,size))>=0){
		
		table[i].value = value;
	}*/
	table[ind].value = value;
	
}

/* Renvoie le label de la fonction s'il trouve , -1 sinon */
int find_fonc(char* name){
	int i;
	/*printTabFunc();*/
	for(i=nbFunc-1;i>=0;i--){
		if(strcmp(tableFunc[i].name,name)==0)
			return tableFunc[i].label;
	}
	return -1;
}

void insert_fonc_tab(char* name,int label,Type type){
	if(find_fonc(name)<0){
		init_string(tableFunc[nbFunc].name,MAX_SIZE);
		strncpy(tableFunc[nbFunc].name,name,strlen(name)+1);		
		tableFunc[nbFunc].typeRetour=type; /* N'a aucun effet */
		tableFunc[nbFunc].label=label; /* N'a aucun effet */
		nbFunc++;
		
		/*if(NULL ==(tableFunc = (Func*)realloc(tableFunc,nbFunc+1))){
			perror("realloc\n");
			exit(EXIT_FAILURE);
		}
		*/
		
	}
	else{
		fprintf(fd_fichier,"#----Redeclaration of function %s\n",name);	
	}

}

void init(){
	int i;
	for(i=0;i<1024;i++){
		tableFunc[i].nbArg=0;
		tableFunc[i].nbVar=0;
	}


}

int yyerror(char* s) {
  fprintf(stderr,"%s\n",s);
  return 0;
}

void endProgram() {
  fprintf(fd_fichier,"HALT\n");
}

void inst(const char *s){
  fprintf(fd_fichier,"%s\n",s);
}

void instarg(const char *s,int n){
  fprintf(fd_fichier,"%s\t%d\n",s,n);
}


void comment(const char *s){
  fprintf(fd_fichier,"#%s\n",s);
}

int main(int argc, char** argv) {
	char optstring[]="o";
	char option;
	char* string = (char*)malloc((strlen(argv[1]))*sizeof(char)); 

  if(argc==2){
    yyin = fopen(argv[1],"r");
    fd_fichier=stdout;
  }
  else if(argc==1){
    yyin = stdin;
  }
  else if(argc==3){
  	yyin = fopen(argv[1],"r");
  	while((option=getopt(argc,argv,optstring))!=-1){
		switch(option){
		  case 'o':
		  	strcpy(string,argv[1]);	
			fd_fichier = fopen(strcat(string,".vm"),"w");
			break;
		  default:
		  	fd_fichier=stdout;
			break;
		}	
  	}  
  }
  
  else{
    fprintf(stderr,"usage: %s [src]\n",argv[0]);
    return 1;
  }
  init();

  yyparse();
  endProgram();
  free(string);
  return 0;
}
