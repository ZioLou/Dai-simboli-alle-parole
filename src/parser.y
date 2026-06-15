%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//dichiara il lexer, quando il parser ha bisogno di un nuovo token chiama questa funzione
int yylex(void);
//dichiara la funzione che Bison chiama quando incontra un errore sintattico
void yyerror(const char *s);
//puntatore al file dove scriviamo la traduzione
FILE *output_file;
%}

  /*diciamo a bison che i token possono avere un valore semantico, in questo caso una stringa*/
%union {
    char *str;
}

  /*dichiaro i token che non hanno valore semantico*/
%token ERRORE_LESSICALE
%token NEWLINE DOMANDA
%token TONDA_CHIUSA TONDA_APERTA SLASH O_EMOTICON

  /*qui dichiaro i token che portano con sé una stringa (il loro valore testuale)*/
%token <str> PRO_PER PRO_RIF V_OPIN V_IMPR
%token <str> AVV_QUANT AGG EMOJ EMOTICON GENERE MOTIVAZIONE CONGIUNZIONE

  /*qui dichiaro i non terminali che producono una stringa*/
%type <str> frase corpo prefisso descrizione lista_descrittori elemento
%type <str> descrittore_base ripetizione emoticon_completa coda_emoticon
%type <str> opzionale_genere causa_genere genere_seq genere_base ripetizione_genere

  /*dico a Bison qual è il simbolo iniziale della grammatica*/
%start programma

%%

//inizio grammatica

//questa è la prima produzione, permette di leggere 0 o più righe
programma:
      /* vuoto */
    | programma riga
;

riga:
    //una riga corretta è una frase seguita da invio \n
      frase NEWLINE
      {
          printf("%s\n", $1);//stampa nel terminale la frase tradotta
          //se il file di output è aperto ci scrive dentro la stessa frase
          if (output_file != NULL) fprintf(output_file, "%s\n", $1);
          free($1);//libera la memoria della stringa prodotta
      }
    | NEWLINE  //solo invio, non fa nulla
    //questo invece se il lexer ci manda un errore lessicale, es. :)(
    | ERRORE_LESSICALE NEWLINE
      {
          printf("Errore lessicale: token non riconosciuto.\n");
          if (output_file != NULL)
              fprintf(output_file, "Errore lessicale: token non riconosciuto.\n");
          yyerrok;
      }
    | error NEWLINE //questo invece se c'è un errore di sintassi
      {
          printf("Errore sintattico: frase non conforme alla grammatica definita.\n"); //stampa l'errore
          if (output_file != NULL) fprintf(output_file, "Errore sintattico: frase non conforme alla grammatica definita.\n"); //e lo scrive nel file
          yyerrok;//dice a Bison di riprendere a leggere le righe senza bloccarsi sull'errore
      }
;


frase:
      //prefisso(chi commenta) + corpo della frase
      //es. io penso 💣 🎸  oppure solo io penso 💣
      prefisso corpo
      {
          char buffer[2048];//array che conterrà la frase tradotta
          //il prefisso porta già dentro "...questa canzone è ", quindi basta concatenare il corpo
          sprintf(buffer, "%s%s", $1, $2);
          //allochiamo dinamicamente perché buffer vive solo dentro queste {}, fuori sparirebbe
          $$ = strdup(buffer);
          //libero le stringhe usate
          free($1); free($2);
      }
    //qui senza prefisso, il soggetto resta sottinteso: aggiungo io "questa canzone è"
    //es. 💣 🎸  oppure solo 💣
    | corpo
      {
          char buffer[2048];
          sprintf(buffer, "questa canzone è %s", $1);
          $$ = strdup(buffer);
          free($1);
      }
    //qui aggiungo ? alla fine, es. 💣 🎸 ?
    //che diventa: secondo te questa canzone è bomba perché è rock?
    | corpo DOMANDA
      {
          char buffer[2048];
          sprintf(buffer, "secondo te questa canzone è %s?", $1);
          $$ = strdup(buffer);
          free($1);
      }
    //come sopra ma con il prefisso davanti: una domanda è sempre rivolta all'altro,
    //quindi il prefisso non serve e lo libero soltanto
    | prefisso corpo DOMANDA
      {
          char buffer[2048];
          sprintf(buffer, "secondo te questa canzone è %s?", $2);
          $$ = strdup(buffer);
          free($1); free($2);
      }
;

//il corpo è la descrizione della canzone con l'eventuale genere.
//L'ordine è libero: "bomba rock" e "rock bomba" danno la stessa traduzione,
//perché in output rimettiamo sempre l'ordine naturale: prima il descrittore, poi la causa.
corpo:
      //descrizione seguita dal genere opzionale, es. "bomba" oppure "bomba rock"
      descrizione opzionale_genere
      {
          char buffer[2048];
          sprintf(buffer, "%s%s", $1, $2);
          $$ = strdup(buffer);
          free($1); free($2);
      }
    //genere prima della descrizione, es. "rock bomba"
    //qui $1 è la causa (" perché è rock") e $2 il descrittore ("bomba"):
    //li scrivo al contrario così l'output resta "bomba perché è rock"
    | causa_genere descrizione
      {
          char buffer[2048];
          sprintf(buffer, "%s%s", $2, $1);
          $$ = strdup(buffer);
          free($1); free($2);
      }
;

//questa è la produzione prefisso: usando il valore dei token controllo gli accordi
//(pronome giusto con il verbo giusto) così evito che l'utente scriva cose tipo:
/*
io pensi bomba
tu penso bomba
mi penso bomba
*/
//il prefisso produce sempre la testa della frase "secondo me/te questa canzone è "
prefisso:
      //solo il verbo di opinione, soggetto sottinteso
      V_OPIN
      {
          //"penso" lo leggo come prima persona, "pensi" come seconda
          if (strcmp($1, "penso") == 0)
            $$ = strdup("secondo me questa canzone è ");
          else
            $$ = strdup("secondo te questa canzone è ");
          free($1);
      }

    | PRO_RIF V_IMPR
      {  //"mi sembra" -> secondo me, "ti sembra" -> secondo te
          if (strcmp($1, "mi") == 0 && strcmp($2, "sembra") == 0)
            $$ = strdup("secondo me questa canzone è ");
          else if (strcmp($1, "ti") == 0 && strcmp($2, "sembra") == 0)
            $$ = strdup("secondo te questa canzone è ");
          else YYERROR;//pronome e verbo non si accordano -> errore
          free($1); free($2);
      }
    | PRO_PER V_OPIN
      {
        //qui controllo "io penso" e "tu pensi"
          if (strcmp($1, "io") == 0 && strcmp($2, "penso") == 0)
            $$ = strdup("secondo me questa canzone è ");
          else if (strcmp($1, "tu") == 0 && strcmp($2, "pensi") == 0)
            $$ = strdup("secondo te questa canzone è ");
          else YYERROR;
          free($1); free($2);
      }
    | PRO_PER
        //se c'è solo "io" diventa secondo me, se c'è solo "tu" diventa secondo te
      {
          if (strcmp($1, "io") == 0)
            $$ = strdup("secondo me questa canzone è ");
          else $$ = strdup("secondo te questa canzone è ");
          free($1);
      }
;

//la descrizione produce una lista di descrittori (com'è la canzone)
descrizione:
      lista_descrittori //il valore è direttamente quello prodotto da lista_descrittori
      { $$ = $1; }
;


//lista_descrittori:
//descrittori diversi si collegano con il token CONGIUNZIONE (la "e").
//Le ripetizioni dello stesso descrittore senza "e" le gestisce 'elemento'.
lista_descrittori:
      //caso base della ricorsione: un solo gruppo di descrittori
      elemento
      {
          $$ = $1;
      }
      //ricorsione a destra: uno o più descrittori uniti dalla "e"
      //es. bomba e ballabile
    | elemento CONGIUNZIONE lista_descrittori
      {
          char buffer[2048];
          //concateno il primo gruppo con il resto, mettendo " e " in mezzo
          sprintf(buffer, "%s e %s", $1, $3);
          $$ = strdup(buffer);
          free($1); free($2); free($3);
      }
;


elemento:

      //singolo descrittore
      descrittore_base
      { $$ = $1; }

      //descrittore preceduto da un avverbio quantitativo (molto, troppo, un po'...)
    | AVV_QUANT elemento
      {
          char buffer[2048];
          //attacco l'avverbio davanti al descrittore
          sprintf(buffer, "%s %s", $1, $2);
          $$ = strdup(buffer);
          free($1); free($2);
      }
      //questo riconosce la ripetizione dello stesso descrittore (es. 💣💣💣)
      //ripetizione restituisce: descrittore|molto molto ...
      //se il descrittore ripetuto è uguale a quello base allora va bene,
      //altrimenti sono emoji diverse appiccicate e quindi è un errore di sintassi
    | descrittore_base ripetizione
  {
      char buffer[2048];

      //$2 contiene: descrittore_ripetuto|molto molto ...
      //quindi separo le due parti, sep punta al carattere |
      char *sep = strchr($2, '|');
      //se non trovo il separatore qualcosa è andato storto
      if (sep == NULL) {
          YYERROR;
      }

      //taglio la stringa: mettendo \0 al posto di | ottengo
      //descrittore\0molto molto.. così a sinistra ho solo il descrittore
      *sep = '\0';

      //confronto il descrittore ripetuto con quello di partenza
      //se sono diversi è un errore (es. 💣💥 uguali appiccicati non hanno senso)
      if (strcmp($1, $2) != 0) {
          free($1);
          free($2);
          YYERROR;
      }

      //se sono uguali concateno tutti i "molto molto..." (che stanno dopo lo \0, in sep+1)
      //davanti al descrittore base $1
      sprintf(buffer, "%s%s", sep + 1, $1);
      $$ = strdup(buffer);

      free($1);
      free($2);
  }
;

//qui riconosco la ripetizione di descrittori uguali, è ricorsiva a destra
ripetizione:
      descrittore_base
      {
          char buffer[2048];

          /*
             salvo due informazioni:
             1) il descrittore ripetuto, cioè $1
             2) la stringa "molto " da aggiungere

             uso il simbolo | come separatore interno, esempio:
             bomba|molto
          */
          sprintf(buffer, "%s|molto ", $1);
          $$ = strdup(buffer);

          free($1);
      }

    | descrittore_base ripetizione
      {
          char buffer[2048];

          /*
             $2 contiene già qualcosa tipo:
             bomba|molto molto
          */
          //cerco il separatore |
          char *sep = strchr($2, '|');
          //se non lo trovo torno errore
          if (sep == NULL) {
              YYERROR;
          }

          //taglio la stringa dove c'è il separatore
          *sep = '\0';

          /*
             ogni volta che il descrittore si ripete controllo che sia uguale
             a quello di prima, altrimenti torno errore
          */
          if (strcmp($1, $2) != 0) {
              free($1);
              free($2);
              YYERROR;
          }

          //se sono uguali aggiungo un altro "molto":
          //prima il descrittore, poi "molto", poi la serie di "molto" che c'era già (sep+1)
          sprintf(buffer, "%s|molto %s", $2, sep + 1);
          $$ = strdup(buffer);

          free($1);
          free($2);
      }
;
//un descrittore base può essere testuale, una emoji oppure una emoticon
//restituisce direttamente il valore che arriva dal lexer
descrittore_base:
      AGG //descrittore testuale, es. "bella"
      { $$ = $1; }
    | EMOJ  //emoji, es. 💣 -> bomba
      { $$ = $1; }
    | emoticon_completa //emoticon, es. :)
      { $$ = $1; }
;

//emoticon_completa serve a produrre una emoticon semplice :) oppure con la coda :))))
emoticon_completa:

    //caso base: emoticon semplice :), il lexer ci ha già dato il valore (es. "bella")
      EMOTICON
      { $$ = $1; }

    //emoticon seguita da una coda di simboli
    //coda_emoticon restituisce un "molto " per ogni simbolo ripetuto
    | EMOTICON coda_emoticon
      {
          char buffer[2048];
          //attacco tutti i "molto" della coda ($2) davanti al valore dell'emoticon ($1)
          sprintf(buffer, "%s%s", $2, $1);
          $$ = strdup(buffer);
          free($1); free($2);
      }
;


//la coda restituisce una serie di "molto", tanti quanti sono i simboli ),(,/,o,O che trova
coda_emoticon:

    //casi base: un solo simbolo in più vale un "molto"
      TONDA_CHIUSA
      { $$ = strdup("molto "); }
    | TONDA_APERTA
      { $$ = strdup("molto "); }
    | SLASH
      { $$ = strdup("molto "); }
    | O_EMOTICON
      { $$ = strdup("molto "); }

    //ricorsioni a destra: per ogni simbolo in più aggiungo un "molto"
    //es: ))) -> molto molto molto
    | TONDA_CHIUSA coda_emoticon
      {
          char buffer[2048];
          sprintf(buffer, "molto %s", $2);
          $$ = strdup(buffer);
          free($2);
      }
    | TONDA_APERTA coda_emoticon
      {
          char buffer[2048];
          sprintf(buffer, "molto %s", $2);
          $$ = strdup(buffer);
          free($2);
      }
    | SLASH coda_emoticon
      {
          char buffer[2048];
          sprintf(buffer, "molto %s", $2);
          $$ = strdup(buffer);
          free($2);
      }
    | O_EMOTICON coda_emoticon
      {
          char buffer[2048];
          sprintf(buffer, "molto %s", $2);
          $$ = strdup(buffer);
          free($2);
      }
;




//questa è la produzione opzionale_genere
//può produrre la stringa vuota oppure la causa con il genere musicale
opzionale_genere:
      //qui se c'è un genere
      causa_genere
      { $$ = $1; }
    | /* vuoto */
      { $$ = strdup(""); }
;


//una causa può avere 2 forme:
//- solo genere: es. rock
//- genere preceduto dal token MOTIVAZIONE (quindi "perché"): perche rock
//in entrambi i casi prendo il valore del genere e aggiungo davanti " perché è "
//es. bomba rock -> questa canzone è bomba perché è rock
causa_genere:
      genere_seq
      {
          char buffer[2048];
          sprintf(buffer, " perché è %s", $1);
          $$ = strdup(buffer);
          free($1);
      }
    | MOTIVAZIONE genere_seq
      {
          char buffer[2048];
          sprintf(buffer, " perché è %s", $2);
          $$ = strdup(buffer);
          free($1); free($2);
      }
;




//sequenza di genere, stessa logica delle emoji ripetute
genere_seq:
      // singolo genere
      genere_base
      {
          $$ = $1;
      }

    // genere ripetuto: es. 🎸🎸 -> molto rock
    | genere_base ripetizione_genere
      {
          char buffer[2048];

          /*
             $2 contiene:
             genere_ripetuto|molto molto ...
             esempio:
             rock|molto
          */
          char *sep = strchr($2, '|');

          if (sep == NULL) {
              YYERROR;
          }

          /*
             taglio la stringa:
             prima del separatore ho il genere ripetuto,
             dopo il separatore ho i "molto".
          */
          *sep = '\0';

          /*
             controllo che il primo genere sia uguale a quello che si ripete.
             corretto:  rock rock
             sbagliato: rock rap
          */
          if (strcmp($1, $2) != 0) {
              free($1);
              free($2);
              YYERROR;
          }

          /*
             se sono uguali costruisco:
             molto rock
             molto molto rock
             ecc.
          */
          sprintf(buffer, "%s%s", sep + 1, $1);
          $$ = strdup(buffer);

          free($1);
          free($2);
      }
;

ripetizione_genere:
  //caso base per uscire dalla ricorsione, cioè il valore del genere
      genere_base
      {
          char buffer[2048];

          /*
             salvo due informazioni:
             1) il genere ripetuto
             2) la stringa "molto "
             esempio:
             rock|molto
          */
          sprintf(buffer, "%s|molto ", $1);
          $$ = strdup(buffer);

          free($1);
      }
    //ricorsione a destra: tanti generi ripetuti, concateno una serie di "molto"
    | genere_base ripetizione_genere
      {
          char buffer[2048];

          /*
             $2 contiene già qualcosa tipo:
             rock|molto molto
          */
          char *sep = strchr($2, '|');

          if (sep == NULL) {
              YYERROR;
          }

          /*
             isolo il genere salvato nella parte sinistra.
          */
          *sep = '\0';

          /*
             controllo che ogni nuovo genere sia uguale a quello già salvato.
          */
          if (strcmp($1, $2) != 0) {
              free($1);
              free($2);
              YYERROR;
          }

          /*
             se è uguale aggiungo un altro "molto".
          */
          sprintf(buffer, "%s|molto %s", $2, sep + 1);
          $$ = strdup(buffer);

          free($1);
          free($2);
      }
;

//genere base
genere_base:
      GENERE //il token GENERE restituito dal lexer con il suo valore, es. rock
      { $$ = $1; }
;

//fine grammatica
%%


//funzione chiamata da Bison in caso di errore sintattico
//è vuota perché l'errore lo gestiamo nella produzione 'error NEWLINE', così evito doppie stampe
void yyerror(const char *s) {
}

//il main apre il file di output, avvia il parser con yyparse()
//e quando il parser ha finito chiude il file e termina
int main(void) {
    output_file = fopen("output.txt", "w");
    if (output_file == NULL) {
        printf("Errore: impossibile creare il file output.txt\n");
        return 1;
    }

    //avvia il parser
    yyparse();

    //quando il parser ha finito chiude il file di output e termina
    fclose(output_file);
    return 0;
}
