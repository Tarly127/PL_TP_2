%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>

  extern int yyerror();
  extern int yylex();

  extern char* yytext;
  extern int yylineno;

  /*Função que escreve num ficheiro apenas se este não existir*/
  void fwriteif(char* path, char* str);

  /*Função que escreve no fim de um ficheiro. Apenas para poupar linhas*/
  void fappend(char* path, char* str);

  /*Função que escreve no início de um ficheiro. Passa o conteúdo do ficheiro para
    para a memória do programa primeiro se ele já existir, para depois escrever outra
    vez o que já estava lá
  */
  void fbegwrt(char* path, char* str);


  char *filename;
  char *documento, *sujeito, *relacao;
  char *conceito;

  FILE *fp;

  char **hyperlinks;
  int size = 0;

  void add_to_hyperlinks(char* n_link);
  void ifn_add_to_hyperlinks(char* n_link);

%}

%union
{
  char* string;
}

%token<string> frase titulo quote con
%token<string> ERROR BEGIN_CON BEGIN_TRIP BEGIN_IMG BEGIN_META TRESIGUAIS INVERSEOF
%token<string> CARDINALT VIRGULA PONTOVIRG PONTO A

%type<string> DocElems Titulo Texto Documento ConceitoDoc TriplosElems Triplos
%type<string> Objeto Par Triplo Relacao Relacoes Bloco ConceitoTriplo ConceitoPar ConceitoRelacao

%%

Caderno     : Pares Meta
            ;
Pares       : Pares Par
            |
            ;
Par         : TRESIGUAIS ConceitoPar Documento Triplos    { asprintf(&filename, "out/%s.html", $2);
                                                            ifn_add_to_hyperlinks(filename);
                                                            fp = fopen(filename, "a");
                                                            asprintf(&$3,"%s<h2>Triplos</h2>\n", $3);
                                                            if(fp != NULL){
                                                              fbegwrt(filename, $3);
                                                              fprintf(fp, "%s", $4);
                                                              fclose(fp);
                                                            }
                                                          }
            ;
ConceitoPar : con                                  { documento = strdup($1);
                                                     relacao = strdup(""); }
            ;

Documento    : ConceitoDoc DocElems                { asprintf(&$$, "%s%s",$1,$2); }
             ;
ConceitoDoc  : BEGIN_CON titulo                    { asprintf(&$$, "<h1>%s</h1>\n", $2); }
             ;
DocElems     : DocElems Bloco                      { asprintf(&$$, "%s%s", $1, $2); }
             |                                     { $$ = strdup(""); }
             ;
Bloco        : Titulo Texto                        { asprintf(&$$, "%s\n%s", $1, $2); }
             ;
Titulo       : CARDINALT titulo                    { asprintf(&$$, "<h2>%s</h2>", $2); }
             |                                     { $$ = strdup(""); }
             ;
Texto        : frase                               { asprintf(&$$, "<p>%s</p>", $1); }
             ;


Triplos         : BEGIN_TRIP TriplosElems          { asprintf(&$$, "%s\n", $2); }
                ;
TriplosElems    : TriplosElems Triplo              { asprintf(&$$, "%s%s", $1, $2);}
                | Triplo                           { asprintf(&$$, "%s", $1); }
                ;
Triplo          : ConceitoTriplo Relacoes PONTO    { asprintf(&$$, "<a href=\"%s.html\">%s</a>:\n%s", $1, $1, $2);
                                                     if(strcmp(documento, sujeito) != 0){
                                                        asprintf(&$1, "<h1>%s</h1>", sujeito);
                                                        asprintf(&filename, "out/%s.html", sujeito);
                                                        fwriteif(filename, $1);
                                                        fappend(filename, $2);
                                                     }
                                                     relacao = strdup("");
                                                   }
                ;
ConceitoTriplo  : con                              { asprintf(&$$, "%s", $1);
                                                     sujeito = strdup($1); }
                ;
Relacoes        : Relacoes PONTOVIRG Relacao       { asprintf(&$$, "%s%s\n", $1, $3); }
                | Relacao                          { asprintf(&$$, "%s\n", $1); }
                ;
Relacao         : A Objeto                         { asprintf(&$$, "<p>%s</p>", $2); }
                | ConceitoRelacao Objeto           { asprintf(&$$, "<p><a href=\"%s.html\">%s</a>: %s</p>", $1, $1, $2);
                                                     asprintf(&filename, "out/%s.html", relacao);
                                                     asprintf(&$2, "<p><a href=\"%s.html\">%s</a>: %s</p>", sujeito, sujeito, $2);
                                                     asprintf(&$1, "<h1>%s</h1>", relacao);
                                                     fwriteif(filename, $1);
                                                     fappend(filename, $2);
                                                   }
                | BEGIN_IMG quote                  { asprintf(&$$, "<img src=\"../in/img/%s\" alt=\"Unable to show image\"></img>\n<p></p>\n", $2); }
                ;
ConceitoRelacao : con                              { $$ = strdup($1);
                                                     relacao = strdup($1);
                                                   }
                ;
Objeto          : Objeto VIRGULA con               { asprintf(&$$, "%s, <a href=\"%s.html\">%s</a>", $1, $3, $3);
                                                     asprintf(&filename, "out/%s.html", $3);
                                                     asprintf(&conceito, "<h1>%s</h1>", $3);
                                                     fwriteif(filename, conceito);
                                                     asprintf(&$3, "<a href=\"%s.html\"><p>%s</a> <a href=\"%s.html\">%s</p></a>\n", relacao, relacao, sujeito, sujeito);
                                                     fappend(filename, $3);
                                                   }
                | con                              { asprintf(&$$, "<a href=\"%s.html\">%s</a>", $1, $1);
                                                      asprintf(&filename, "out/%s.html", $1);
                                                      asprintf(&conceito, "<h1>%s</h1>", $1);
                                                      fwriteif(filename, conceito);
                                                      asprintf(&$1, "<a href=\"%s.html\"><p>%s</a> <a href=\"%s.html\">%s</p></a>\n", relacao, relacao, sujeito, sujeito);
                                                      fappend(filename, $1);
                                                   }
                | quote                            { $$ = strdup($1); }
                ;

Meta      : BEGIN_META MetaElems
          |
          ;
MetaElems : MetaElems TriploM
          | TriploM
          ;
TriploM   : con INVERSEOF con
          ;

%%


void fwriteif(char* path, char* str)
{

  FILE *fp;
  fp = fopen(path, "r");
  if(!fp){
    fp = fopen(path, "w");
    fprintf(fp, "%s", str);
    fclose(fp);

    /*Aproveito e adiciono aos hyperlinks*/
    add_to_hyperlinks(path);
  }
}

void fappend(char* path, char* str)
{

  FILE *fp;
  fp = fopen(path, "a");
  if(fp != NULL){
    fprintf(fp, "%s\n", str);
    fclose(fp);
  }
}

void fbegwrt(char* path, char* str)
{

  FILE *fp;
  char *tmp, buf[1024];

  tmp = strdup("");

  fp = fopen(path, "r");
  if(fp){
    while(fgets(buf, 1024, fp)){
      asprintf(&tmp, "%s", buf);
    }
    fclose(fp);
  }

  fp = fopen(path, "w");
  if(fp){
    fprintf(fp, "%s%s", str, tmp);
    fclose(fp);
  }
  free(tmp);
}

void add_to_hyperlinks(char* n_link)
{
  hyperlinks = (char**)realloc(hyperlinks, (size+1) * sizeof(char*));
  hyperlinks[size] = strdup(n_link);
  size++;
}

void ifn_add_to_hyperlinks(char* n_link)
{
  FILE *fp = fopen(n_link, "r");
  if(!fp){
    hyperlinks = (char**)realloc(hyperlinks, (size+1) * sizeof(char*));
    hyperlinks[size] = strdup(n_link);
    size++;
  }
  else
    fclose(fp);
}

void make_index(char** hyperlinks, int h_size)
{
  FILE* fp = fopen("out/index.html", "w");
  if(fp != NULL){
    fprintf(fp, "<h1>TP2 PL</h1>\n<h2>Output</h2>\n");
    for(int i = 0; i < size; i++){
      fprintf(fp, "<p><a href=%s>", hyperlinks[i]+4);
      hyperlinks[i][strlen(hyperlinks[i])-5] = '\0';
      fprintf(fp, "%s</a><p>\n", hyperlinks[i]+4);
    }
  }
  fclose(fp);
}

void free_hyperlinks()
{
  for(int i = 0; i < size; i++){
    free(hyperlinks[i]);
  }
  free(hyperlinks);
}

int yyerror()
{
  printf("Erro (%d): %s\n", yylineno, yytext);
  return 0;
}

int main()
{
  hyperlinks = (char**)malloc(sizeof(char*));

  yyparse();

  make_index(hyperlinks, size);
  free_hyperlinks();
  return 0;
}
