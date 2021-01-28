%{
  #include "y.tab.h"
%}
%option yylineno

spec_chars \xc3[\x80-\xbf]
letter    [a-zA-Z]|{spec_chars}

pal       {letter}+(_{letter}*)*
par       [^\n#@]+

%x TRIPLOS CONCEITO TEXTO TITULO META

%%


<*>===                                         { BEGIN CONCEITO; return TRESIGUAIS; }
<*>@tit:                                       { BEGIN TITULO; return BEGIN_CON; }
<*>@triplos:                                   { BEGIN TRIPLOS;  return BEGIN_TRIP; }
<*>@meta:                                      { BEGIN META; return BEGIN_META; }

<CONCEITO>:{pal}                               { BEGIN TEXTO; yylval.string = strdup(yytext+1); return con; }

<TEXTO>#                                       { BEGIN TITULO; return CARDINALT; }
<TEXTO>{par}                                   { yylval.string = strdup(yytext); return frase; }
<TITULO>{par}                                  { BEGIN TEXTO; yylval.string = strdup(yytext); return titulo;}

<TRIPLOS>\.                                    { return PONTO; }
<TRIPLOS>;                                     { return PONTOVIRG; }
<TRIPLOS>,                                     { return VIRGULA; }
<TRIPLOS>:img                                  { return BEGIN_IMG; }
<TRIPLOS>a                                     { return A; }
<TRIPLOS>\"[^\"]+\"                            { yytext[yyleng-1] = '\0'; yylval.string = strdup(yytext+1);   return quote; }
<TRIPLOS>:{pal}                                { yylval.string = strdup(yytext+1); return con; }

<META>:inverseOf                               { return INVERSEOF; }
<META>:{pal}                                   { return con; }

<*>[ \t\n\r]                                   ;
<*>.                                           { return ERROR; }
