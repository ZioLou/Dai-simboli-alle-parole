# Dai simboli alle parole

Traduttore di commenti musicali che trasforma frasi simboliche, testuali o ibride
(emoji, emoticon e parole) in frasi italiane ben formate, usando un analizzatore
lessicale (Flex) e uno sintattico (Bison).

## Requisiti

- `flex`
- `bison`
- un compilatore C (`cc` / `gcc`)

## Compilazione

```bash
flex lexer.l
bison -d parser.y
cc -o traduttore parser.tab.c lex.yy.c
```

## Esecuzione

Scrivi i comandi in `input.txt` (uno per riga) ed esegui:

```bash
./traduttore < input.txt
```

Il programma stampa le frasi tradotte a schermo e, allo stesso tempo, le scrive
nel file **`output.txt`**, che viene rigenerato (sovrascritto) a ogni esecuzione.
