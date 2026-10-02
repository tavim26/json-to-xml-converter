%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);        //functie pt erori de sintaxa
int yylex(void);                    //functia lexerului
%}


%union {                
    char* str;      
}



%token <str> STRING
%token LBRACE RBRACE LBRACKET RBRACKET COLON COMMA


%type <str> json pair_list pair value object array array_elements


%start json

%%

json:
    //regula principala: intregul fisier JSON e un obiect
    object
    {
        //rezultatul vine scris intr-un fisier XML
        FILE* f = fopen("output.xml", "w");        
        if (f) 
        {
            //tag pentru root
            fprintf(f, "<root>\n%s</root>\n", $1);          
            fclose(f);
            printf("XML scris in output.xml\n");            

        } 
        else 
        {
            perror("Eroare la crearea fisier output.xml");
        }
        free($1);       //eliberare memorie
    }
;

object:
    //obiect JSON este o lista de perechi cheie:valoare
    LBRACE pair_list RBRACE
    {
        $$ = $2;            
    }
;

pair_list:
    //lista de perechi = una sau mai multe perechi, separate prin virgule
    pair
    {
        $$ = $1;      //o singura pereche
    }
    | pair COMMA pair_list
    {
        

        //concatenam XML-ul produs de fiecare pereche
        size_t len = strlen($1) + strlen($3) + 1;
        $$ = malloc(len);
        snprintf($$, len, "%s%s", $1, $3);
        free($1); 
        free($3);
    }
;

pair:

    //o pereche de tip cheie:valoare devine in XML <cheie>valoare</cheie>
    STRING COLON value
    {
        
        size_t size = strlen($1) * 2 + strlen($3) + 20;         //calculeaza lungimea pentru tag
        $$ = malloc(size);

        snprintf($$, size, "  <%s>%s</%s>\n", $1, $3, $1);      //formatare string XML
        free($1); 
        free($3);
    }
;

value:

    //valoarea poate fi: string, obiect imbricat sau array
    STRING
    {
        $$ = strdup($1);    //transmite string-ul ca atare
        free($1);
    }
    | object
    {
        $$ = strdup($1);
        free($1);
    }
    | array
    {
        $$ = strdup($1);
        free($1);
    }
;

//array in JSON = lista de valori intre paranteze drepte
array:
    LBRACKET array_elements RBRACKET
    {
        $$ = $2;        //returneaza direct string-ul XML pentru array
    }
;

//un array e o lista de valori, pt fiecare se pune in <item></item>
array_elements:
    value
    {
        // "<item>" (6) + "</item>" (7) + "\n" (1) + '\0' (1) = 15
        size_t len = strlen($1) + 15;
        $$ = malloc(len);
        snprintf($$, len, "<item>%s</item>\n", $1);
        free($1);
    }
    | value COMMA array_elements
    {
        //genereaza mai multe taguri
        size_t len = strlen($1) + strlen($3) + 20;
        $$ = malloc(len);
        snprintf($$, len, "<item>%s</item>\n%s", $1, $3);
        free($1); 
        free($3);
    }
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Eroare de sintaxa: %s\n", s);
}

int main() {
    return yyparse();
}
