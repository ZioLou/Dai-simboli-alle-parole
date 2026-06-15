%option noyywrap
%option yylineno

%{
#include "parser.tab.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
%}

SPAZI       [ \t\r]+

%%

    /*gli spazi vengono ignorati*/
{SPAZI}             ;

\n                  { return NEWLINE; }

"?"                 { return DOMANDA; }

    /*anche questi simboli di punteggiatura vengono ignorati*/
"."|"!"|","|";"     ;


    /*avverbi quantitativi, ritorno il valore testuale così com'è*/
"molto"|"tanto"|"troppo"|"poco"|"abbastanza"        { yylval.str = strdup(yytext); return AVV_QUANT; }

    /*caso particolare "un po": ritorno direttamente il valore "un po'"*/
"un"[ ]+"po"                { yylval.str = strdup("un po'"); return AVV_QUANT; }

    /*pronomi personali*/
"io"|"tu"                   { yylval.str = strdup(yytext); return PRO_PER; }
    /*pronomi riflessivi*/
"mi"|"ti"                   { yylval.str = strdup(yytext); return PRO_RIF; }
    /*verbo di opinione (io penso / tu pensi)*/
"penso"|"pensi"             { yylval.str = strdup(yytext); return V_OPIN; }
    /*verbo di impressione (mi sembra / ti sembra)*/
"sembra"|"pare"             { yylval.str = strdup("sembra"); return V_IMPR; }
    /*congiunzione*/
"e"                         { yylval.str = strdup(yytext); return CONGIUNZIONE; }
    /*MOTIVAZIONE*/
"perche"|"perché"           { yylval.str = strdup("perché"); return MOTIVAZIONE; }

    /*GENERE MUSICALE (versione testuale)*/
"techno"|"elettronica"      { yylval.str = strdup("elettronica"); return GENERE; }
"rock"                      { yylval.str = strdup("rock"); return GENERE; }
"rap"|"trap"                { yylval.str = strdup("rap"); return GENERE; }
"classica"                  { yylval.str = strdup("classica"); return GENERE; }
"pop"                       { yylval.str = strdup("pop"); return GENERE; }
"jazz"                      { yylval.str = strdup("jazz"); return GENERE; }
"metal"                     { yylval.str = strdup("metal"); return GENERE; }
"house"|"dance"             { yylval.str = strdup("house"); return GENERE; }
    /*GENERE MUSICALE (emoji): restituisco il genere come testo*/
"🎸"                        { yylval.str = strdup("pop"); return GENERE; }
"🎧"                        { yylval.str = strdup("elettronica"); return GENERE; }
"🎤"                        { yylval.str = strdup("rap"); return GENERE; }
"🎻"                        { yylval.str = strdup("classica"); return GENERE; }
"🎹"                        { yylval.str = strdup("house"); return GENERE; }
"🥁"                        { yylval.str = strdup("metal"); return GENERE; }

    /*DESCRITTORI TESTUALI (com'è la canzone)*/
"bella"|"bellissima"        { yylval.str = strdup("bella"); return AGG; }
"brutta"                    { yylval.str = strdup("brutta"); return AGG; }
"bomba"                     { yylval.str = strdup("bomba"); return AGG; }
"esplosiva"                 { yylval.str = strdup("esplosiva"); return AGG; }
"aliena"                    { yylval.str = strdup("aliena"); return AGG; }
"ballabile"                 { yylval.str = strdup("ballabile"); return AGG; }
"infuocata"                 { yylval.str = strdup("infuocata"); return AGG; }
"pazzesca"                  { yylval.str = strdup("pazzesca"); return AGG; }
"noiosa"                    { yylval.str = strdup("noiosa"); return AGG; }
"rilassante"                { yylval.str = strdup("rilassante"); return AGG; }
"orecchiabile"              { yylval.str = strdup("orecchiabile"); return AGG; }
"ripetitiva"                { yylval.str = strdup("ripetitiva"); return AGG; }
"festosa"                   { yylval.str = strdup("festosa"); return AGG; }


    /*DESCRITTORI EMOJI: a ogni emoji associo il suo valore testuale*/
"💣"|"🧨"                   { yylval.str = strdup("bomba"); return EMOJ; }
"💥"                        { yylval.str = strdup("esplosiva"); return EMOJ; }
"🛸"|"👽"                   { yylval.str = strdup("aliena"); return EMOJ; }
"🪩"                        { yylval.str = strdup("ritmata"); return EMOJ; }
"🔥"                        { yylval.str = strdup("infuocata"); return EMOJ; }
"🤩"|"😍"                   { yylval.str = strdup("pazzesca"); return EMOJ; }
"🥱"|"😴"                   { yylval.str = strdup("noiosa"); return EMOJ; }
"😎"|"😌"                   { yylval.str = strdup("rilassante"); return EMOJ; }
"🎉"|"🥳"                   { yylval.str = strdup("festosa"); return EMOJ; }
"😑"                   { yylval.str = strdup("monotona"); return EMOJ; }

    /*QUI RICONOSCO ERRORI CON EMOTICON DEL TIPO :) SEGUITO DA PARENTESI A CASO, es. :)( DÀ ERRORE LESSICALE*/

    /* emoticon "bella" scritta male: dopo :) compare una ( */
":)"[()]*"("        { return ERRORE_LESSICALE; }
":-)"[()]*"("       { return ERRORE_LESSICALE; }

    /* emoticon "brutta" scritta male: dopo :( compare una ) */
":("[()]*")"        { return ERRORE_LESSICALE; }
":-("[()]*")"       { return ERRORE_LESSICALE; }
    /* emoticon "tremenda" scritta male: dopo >:( compare una ) */
">:("[()]*")"       { return ERRORE_LESSICALE; }
">:-("[()]*")"      { return ERRORE_LESSICALE; }

    /*EMOTICON*/
":)"|":-)"                  { yylval.str = strdup("bella"); return EMOTICON; }
":("|":-("                  { yylval.str = strdup("brutta"); return EMOTICON; }
">:("|">:-("                { yylval.str = strdup("tremenda"); return EMOTICON; }


    /*SIMBOLI PER CREARE LA CODA NELLE EMOTICON (es. :)))) -> molto molto molto)*/
")"                         { return TONDA_CHIUSA; }
"("                         { return TONDA_APERTA; }
"/"                         { return SLASH; }
"O"|"o"                     { return O_EMOTICON; }

.                           { printf("Token non riconosciuto: %s\n", yytext); return ERRORE_LESSICALE; }

%%
