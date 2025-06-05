%{
#include "proiect.tab.h"                //definiri de tokeni, generate de Bison
#include <string.h>
%}

%%

"{"             { return LBRACE; }  //delimitari json
"}"             { return RBRACE; }
"["             { return LBRACKET; }
"]"             { return RBRACKET; }
":"             { return COLON; }
","             { return COMMA; }

\"[^\"]*\"      {
                    yylval.str = strdup(yytext + 1);                //pt a elimina ghilimele de la inceput si sfarsit
                    yylval.str[strlen(yylval.str) - 1] = '\0';
                    return STRING;
                }

[0-9]+"."[0-9]+ {                                       //numere reale, cu zecimale
                    yylval.str = strdup(yytext);
                    return STRING;
                }

[0-9]+          {                                      //numere intregi
                    yylval.str = strdup(yytext);
                    return STRING;
                }

true            {                                      //valoarea booleana true
                    yylval.str = strdup("true");
                    return STRING;
                }

false           {                                      //valoare booleana false
                    yylval.str = strdup("false");
                    return STRING;
                }

null            {                                      //valoare null
                    yylval.str = strdup("null");
                    return STRING;
                }

[ \t\n\r]+      ;                                      //ignorare spatii si newline

.               { printf("Caracter invalid: %s\n", yytext); }

%%

int yywrap() {
    return 1;
}
