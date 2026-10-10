class_name TutorialData
extends RefCounted
## Testi del tutorial, dei suggerimenti in partita e del riepilogo regole.

const SLIDES := [
	{"title": "Benvenuto in STATUS",
	 "text": "Dopo un periodo di grandi disordini la nazione è contesa da [b]quattro fazioni[/b]: la [b]Mano Invisibile[/b], la [b]Ragione di Stato[/b], il [b]Pugno del Popolo[/b] e la [b]Nuova Milizia[/b].\n\nOgnuna vuole essere riconosciuta come unico governo legittimo. Non basta la forza militare: servono diplomazia, economia e consenso.\n\n[b]Scopo del gioco:[/b] avere più [b]punti Status[/b] alla fine del quarto round.",
	 "rect": [], "show": "banners"},
	{"title": "Il tracciato Status",
	 "text": "Qui in alto a destra c'è la lavagna dello [b]Status[/b] (0–20). Ogni fazione parte da 1.\n\nSi ottengono punti Status:\n• come [b]ricompensa[/b] di alcune carte Evento;\n• con gli [b]effetti[/b] delle carte e del Giornale;\n• nella [b]Fase V[/b], scartando Asset;\n• con i bonus di [b]fine partita[/b].\n\nAlcuni effetti fanno anche [b]perdere[/b] Status.",
	 "rect": [1170, 85, 425, 450]},
	{"title": "Il tracciato Militare",
	 "text": "La [b]Potenza Militare[/b] (0–15) non è un Asset, ma serve a due cose:\n\n1. Alcuni spazi hanno un [b]costo Militare[/b] (fiamma con freccia rossa): per usarli devi indietreggiare.\n2. In [b]ogni parità[/b] vince la fazione più avanti nel Militare, che poi indietreggia di 1 spazio.\n\nOgni spazio ospita un solo indicatore: se arrivi su uno spazio occupato, [b]spingi[/b] l'altro indicatore (indietro se avanzi, in avanti se arretri).",
	 "rect": [0, 95, 1150, 120]},
	{"title": "Asset e Rendita",
	 "text": "Gli [b]Asset[/b] sono Economia (verde), Politica (azzurro) e Consenso (viola). Restano [b]nascosti dietro il tuo schermo[/b]: gli avversari non sanno quanti ne hai.\n\nL'icona a torta indica un [b]Asset a scelta[/b].\n\nI [b]segnalini Rendita[/b] (sacchetti) producono ogni round un Asset del loro tipo; la Rendita Jolly un Asset a scelta, quella Militare fa avanzare di 1. Ogni fazione inizia con 1 Asset per tipo e il proprio segnalino Rendita.",
	 "rect": [], "show": "assets"},
	{"title": "I Funzionari",
	 "text": "Ogni fazione ha [b]4 Funzionari[/b] di valore 1, 2, 3 e 4, mescolati a faccia in giù.\n\nConosci solo il Funzionario che hai [b]in mano[/b] (dietro lo schermo). Nel tuo turno lo invii su uno spazio libero, poi peschi il successivo.\n\nIn un round ogni fazione invia tutti e quattro i Funzionari, uno per turno, a partire da chi ha la [b]Priorità[/b].",
	 "rect": [], "show": "officers"},
	{"title": "Gli spazi Funzionario",
	 "text": "Ogni spazio ha un [b]requisito[/b]:\n• [b]?[/b] — il Funzionario va [b]coperto[/b], qualsiasi valore: gli altri non lo vedono fino alla risoluzione.\n• [b]3[/b] — solo un Funzionario di quel valore esatto.\n• [b]2+[/b] — valore uguale o maggiore.\n• [b]≤[/b] — valore ≥ di quello nello spazio subito a sinistra, che deve essere già occupato.\n\n[b]Sopra[/b] lo spazio c'è il [b]costo[/b] (icona barrata o freccia rossa); [b]sotto[/b] c'è il [b]guadagno[/b], immediato. La valigetta col reticolo significa [b]× valore del Funzionario[/b].",
	 "rect": [], "show": "card", "card": "07"},
	{"title": "Il Monitor e le carte Evento",
	 "text": "Nel Monitor ci sono le carte Evento del round (3 con 2 fazioni, 4 con 3, 5 con 4).\n\n• In alto a destra: la [b]ricompensa[/b] per chi ha la maggioranza (Status o un segnalino Rendita).\n• In basso a destra: i [b]Continenti[/b] (AM, EU, AF, AS), che contano a fine partita.\n• Nella fascia nera: l'[b]effetto[/b]. Il fulmine ⚡ si attiva [b]subito[/b] quando invii il Funzionario; il simbolo ⟳ si attiva in [b]risoluzione[/b].\n• Le carte [b]VS[/b] hanno due schieramenti: la Moneta aggiunge 3 a un lato.\n\nClic destro su una carta per ingrandirla.",
	 "rect": [40, 570, 1545, 490]},
	{"title": "I tre Giornali",
	 "text": "Gli spazi Giornale sono sempre disponibili:\n\n• [b]Finanza[/b] (sinistra): guadagni Consenso, Economia, Politica o Militare pari al valore; ma in risoluzione [b]ripaghi il debito[/b]: 1 Asset (o 1 Status) per ogni tuo Funzionario lì.\n• [b]Diplomazia[/b] (centro): Funzionario coperto, ottieni 1 Asset a scelta oppure +1 Militare.\n• [b]Politica[/b] (destra): ⚡ scarta Consenso+Politica+Economia, oppure 4 Asset, oppure 4 Militare, per [b]1 Status[/b].\n\nI Giornali non si vincono: non hanno maggioranza.",
	 "rect": [30, 240, 1115, 300]},
	{"title": "Il round in 6 fasi",
	 "text": "[b]I · Nuovi Eventi[/b] — si riempie il Monitor (saltata nel 1° round).\n[b]II · Inviare i Funzionari[/b] — a turno, 4 Funzionari a testa.\n[b]III · Risolvere gli Eventi[/b] — si rivelano i Funzionari, si attivano gli effetti ⟳, poi su ogni carta la somma più alta prende ricompensa e carta.\n[b]IV · Riscuotere la Rendita[/b].\n[b]V · Aumentare lo Status[/b] — scarta E+P+C per 1 Status, o 2 di ogni tipo per 2 (massimo 2 per round).\n[b]VI · Stabilire la Priorità[/b] — va alla fazione con meno Status (in parità, a quella più indietro nel Militare).\n\nL'orologio sul tabellone indica la fase in corso.",
	 "rect": [0, 0, 1150, 95]},
	{"title": "Risolvere gli Eventi",
	 "text": "Per ogni carta, da sinistra a destra:\n1. si sommano i valori dei Funzionari di ogni fazione;\n2. la somma più alta ottiene la [b]ricompensa[/b];\n3. e prende la [b]carta[/b], che tiene coperta vicino al proprio schermo.\n\nIn parità vince chi è più avanti nel Militare, che poi indietreggia di 1.\nLe carte senza Funzionari vengono scartate.\n\nPoi ognuno riprende i propri Funzionari e li rimescola.",
	 "rect": [40, 570, 1545, 490]},
	{"title": "Fine della partita",
	 "text": "La partita finisce dopo il [b]4° round[/b]. Poi:\n\n1. Chi ha [b]più Asset[/b] dietro lo schermo: +1 Status.\n2. Per ogni Continente (in ordine America, Europa, Africa, Asia), chi ha più simboli sulle carte prese: +1 Status.\n3. +1 Status per ogni [b]set completo[/b] dei 4 Continenti.\n\nLe parità si risolvono col Militare. Vince chi ha più Status; in parità, chi ha più Potenza Militare.",
	 "rect": [1170, 85, 425, 450]},
	{"title": "Pronto a giocare",
	 "text": "Nella partita guidata giochi la [b]Ragione di Stato[/b] contro la [b]Mano Invisibile[/b] (IA facile), con le carte consigliate per la prima partita.\n\nDurante il gioco compariranno [b]suggerimenti[/b] in basso a destra. Passa il mouse sugli spazi evidenziati per leggere requisiti, costi e guadagni prima di scegliere.\n\nBuon lavoro, Ministro.",
	 "rect": [], "show": "banners", "final": true},
]

const HINTS := {
	"phase_1": "[b]Fase I – Nuovi Eventi.[/b] Nuove carte Evento entrano nel Monitor. Studiale: ricompensa in alto a destra, continenti in basso, effetto nella fascia nera.",
	"phase_2": "[b]Fase II – Inviare i Funzionari.[/b] A turno ogni fazione invia il Funzionario che ha in mano. Il valore del tuo è nel riquadro [b]Dietro il tuo schermo[/b] a destra.",
	"first_place": "Gli spazi [b]evidenziati in magenta[/b] sono quelli che puoi usare con questo Funzionario: rispetti il requisito e puoi pagarne il costo.\n\nPassa il mouse su uno spazio per leggere costo e guadagno. Pensa alla [b]maggioranza[/b]: chi ha la somma più alta su una carta la vince!",
	"phase_3": "[b]Fase III – Risoluzione.[/b] Tutti i Funzionari vengono girati. Prima si attivano gli effetti ⟳ (prima i Giornali, poi le carte da sinistra), poi si assegnano le carte alle maggioranze.",
	"resolve_done": "Ecco chi ha vinto ogni carta. Le carte prese contano per i [b]Continenti[/b] a fine partita: cerca di collezionare i quattro simboli diversi!",
	"phase_4": "[b]Fase IV – Rendita.[/b] Ogni segnalino Rendita produce il suo Asset. Più Rendita ottieni presto, più ti frutta.",
	"phase_5": "[b]Fase V – Aumentare lo Status.[/b] Con un Asset di ogni tipo (E+P+C) compri 1 Status; con due di ogni tipo, 2 Status. Al massimo 2 per round.",
	"buy_status": "Comprare Status è quasi sempre conveniente, ma ricorda che alcuni spazi richiedono Asset come costo: valuta se tenerne qualcuno.",
	"phase_6": "[b]Fase VI – Priorità.[/b] La fazione con meno Status gioca per prima nel prossimo round: è il meccanismo di recupero del gioco.",
}

const SUMMARY := "[b]Ogni round:[/b]\n[b]I[/b] Nuovi Eventi: 3/4/5 carte nel Monitor (2/3/4 fazioni).\n[b]II[/b] Inviare i Funzionari: dalla Priorità in senso orario, uno alla volta, finché tutti ne hanno inviati 4. Paga il costo (sopra), prendi il guadagno (sotto), attiva ⚡.\n[b]III[/b] Risolvere: rivela; effetti ⟳ (Giornali poi carte, da sinistra); su ogni carta la somma maggiore prende ricompensa e carta. Parità: vince il più avanti nel Militare, che arretra di 1.\n[b]IV[/b] Rendita: ogni segnalino produce.\n[b]V[/b] Status: E+P+C = 1 Status; 2×(E+P+C) = 2 Status (max 2).\n[b]VI[/b] Priorità: a chi ha meno Status (parità: meno Militare).\n\n[b]Requisiti:[/b] ? coperto · N esatto · N+ almeno N · ≤ almeno quanto il vicino sinistro.\n[b]Fine (dopo 4 round):[/b] più Asset +1 · maggioranza per Continente +1 (AM, EU, AF, AS) · +1 per set dei 4 Continenti."
