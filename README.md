# STATUS — adattamento digitale (Godot 4)

Versione digitale per uso personale di **STATUS** (Paolo Mori, Nova Lectio / MS Edizioni).
Componenti e regole © dei rispettivi autori: non distribuire pubblicamente gli asset.

## Avvio
1. Apri Godot 4 (testato su 4.4, compatibile con 4.7) → *Importa* → seleziona `project.godot`.
2. Premi **F5**. Il gioco parte a schermo intero (F11 alterna schermo intero e finestra).

## Cosa c'è
- **Partita da 2 a 4 fazioni**, ognuna Umano o IA. Con più umani si gioca in hotseat: una schermata
  "Passa il dispositivo" nasconde Asset e Funzionari tra un turno e l'altro.
- **Regole complete**: 6 fasi, i 3 Giornali, requisiti `?` / `=` / `+` / `≤`, costi e guadagni ×valore,
  effetti ⚡ e ⟳ di tutte le 42 carte (40 base + 2 promo), carte VS con la Moneta, spinte sul tracciato
  Militare, spareggi, Priorità, punteggio finale con Asset, maggioranze per Continente e set.
- **IA** su tre livelli (Facile / Normale / Difficile): valuta ogni spazio in "punti Status attesi",
  stima i Funzionari coperti degli avversari dai valori che ha già visto.
- **Tutorial**: 12 schede illustrate sul tabellone, poi una partita guidata (Ragione di Stato contro
  Mano Invisibile, IA facile, carte per la prima partita) con suggerimenti a ogni fase.
- **Regole rapide** consultabili dal menu e in partita (pulsante REGOLE).

## Gioco online
Dal menu, **GIOCA ONLINE** (anche dalla versione web su GitHub Pages:
https://tannoiser2.github.io/Status/). Usa lo stesso progetto Firebase di Ultimo chilometro e
Snow Tails (Realtime Database, piano gratuito), con le stanze sotto `status/rooms`.

- **Chi crea la stanza** sceglie nel menu fazioni e opzioni: le fazioni su UMANO diventano i posti per
  gli amici (la prima è la sua). Scrive il nome, preme *Crea una stanza* e comunica il codice di 4
  lettere. Quando ci sono tutti preme *Inizia online*: i posti rimasti liberi li gioca l'IA.
- **Gli amici** scrivono il nome e il codice e premono *Entra*.
- Ognuno vede solo il proprio schermo: Asset e Funzionari coperti degli altri restano nascosti.
  Le fazioni IA le gioca il dispositivo di chi ha creato la stanza, che deve restare collegato.
- **Come funziona.** Ogni decisione del motore (dove inviare un Funzionario, le scelte, la ripartizione
  degli Asset) è una mossa numerata nel database (`acts/0`, `acts/1`, …). Tutti i dispositivi fanno
  girare lo stesso motore con lo stesso seme e applicano le stesse mosse nello stesso ordine, quindi
  la partita è identica ovunque: sul database passano solo le scelte.
- **Se cade la linea** si rientra con lo stesso codice e *Entra*: il gioco recupera le mosse già
  giocate e riprende. Se un giocatore tace per un minuto, al suo posto gioca l'IA finché non rientra.
- Nota: come in ogni gioco online fra amici senza server, i dati nascosti sono nascosti dall'interfaccia,
  non dalla rete: chi volesse barare leggendo la memoria del gioco potrebbe farlo.

**Configurazione Firebase.** Le regole sono in `firebase/database.rules.json` e comprendono anche
quelle di Ultimo chilometro e Snow Tails: vanno pubblicate nella console di Firebase
(Realtime Database → Regole) al posto delle precedenti.

**Prove senza Firebase.** `tests/firebase_mock.py` è un finto Firebase locale. Con `SS_DB_URL`,
`SS_AUTH_URL` e `SS_REFRESH_URL` che puntano lì, `tests/online_play.gd` fa giocare una partita
intera a due istanze (`SS_ROLE=host` e `guest`, più una fazione IA; con `SS_PHASE=drop` e poi `back`
l'ospite esce a metà e rientra). Alla fine ognuna stampa l'impronta della partita, che deve coincidere.

## Comandi
- Clic su uno spazio evidenziato per inviare il Funzionario; passa il mouse per leggere costo,
  guadagno ed effetto.
- Clic destro su una carta del Monitor per ingrandirla.
- CARTE mostra le carte Evento che hai preso e il conteggio dei Continenti.

## Struttura
```
scripts/data/cards_db.gd     database carte e geometria del tabellone
scripts/core/game_engine.gd  motore delle regole (nessuna dipendenza dalla UI)
scripts/core/status_ai.gd    IA euristica
scripts/ui/                  menu, vista di gioco, tutorial
tests/sim.gd                 godot --headless -s res://tests/sim.gd -- 200   (partite IA vs IA)
tests/bench.gd               godot --headless -s res://tests/bench.gd -- 2 0 150 (livello vs livello)
assets/                      tabellone, 42 carte + dorso, segnalini scontornati, font OFL
```

## Scelte da verificare
- Rendita iniziale: Mano = Economia, Ragione = Politica,
  Pugno = Consenso, Milizia = Militare.
- Il lato con il valore dei Funzionari (1–4) è ricostruito graficamente.
- Testa = lato con il ritratto della Moneta, Arco = lato con l'arco.
- Carte "prima partita": 01–24 (riconosciute dal simbolo accanto al titolo).
