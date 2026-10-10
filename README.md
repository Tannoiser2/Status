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
