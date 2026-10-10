class_name CardsDB
extends RefCounted
## Database delle 42 carte Evento di STATUS (40 + 2 promo).
##
## Formato degli spazi Funzionario:
##   r   : requisito -> "?" nascosto, "=" valore esatto, "+" valore >= v, "<=" >= del vicino sinistro
##   v   : valore del requisito
##   c   : costi   (array di stringhe)
##   g   : guadagni (array di stringhe)
##   b   : angolo alto-sx del box sulla carta (coordinate su carta 840x1420)
##   s   : lato per carte VS (0 = sinistra / Testa, 1 = destra / Arco)
## Formato degli oggetti costo/guadagno:  [x][n]T
##   x  = moltiplica per il valore del Funzionario
##   n  = quantità (default 1)
##   T  = E Economia, P Politica, C Consenso, J Asset a scelta, M Militare, S Status
## Ricompensa (rw): "" nessuna, "S" punto Status, "E"/"P"/"C"/"J" segnalino Rendita.
## Effetti (fx): k = tipo, w = "now" (fulmine) / "res" (risoluzione).

const CARD_W := 840.0
const CARD_H := 1420.0
const BOX_W := 188.0
const BOX_H := 171.0

const CARDS := {
	"01": {"t": "Censura di Stato", "first": true, "cont": ["AM"], "rw": "",
		"sp": [{"r": "?", "c": ["2C"], "b": [170, 842]}, {"r": "?", "c": ["2M"], "b": [469, 845]}],
		"fx": {"k": "same_faction", "w": "res", "reward": ["S"]},
		"txt": "Se entrambi i Funzionari sono della stessa fazione, questa ottiene 1 Status."},
	"02": {"t": "Aiuti umanitari", "first": true, "cont": ["AM"], "rw": "J",
		"sp": [{"r": "+", "v": 1, "c": ["P"], "b": [50, 872]}, {"r": "<=", "c": ["P"], "b": [323, 871]}, {"r": "<=", "c": ["P"], "b": [596, 869]}],
		"fx": {"k": "tribute", "w": "now"},
		"txt": "Ogni altra fazione in gioco deve darti 1 Asset a sua scelta (oppure mostrare di non averne)."},
	"03": {"t": "Giunta militare", "first": true, "cont": ["AM", "AF"], "rw": "",
		"sp": [{"r": "?", "g": ["M"], "b": [47, 783]}, {"r": "?", "c": ["C"], "g": ["2M"], "b": [323, 783]}, {"r": "?", "c": ["2C"], "g": ["3M"], "b": [594, 784]}],
		"fx": {"k": "coin_all", "w": "res"},
		"txt": "Lancia la Moneta. Testa: ogni fazione presente ottiene 1 Status. Arco: ogni fazione presente perde 1 Status."},
	"04": {"t": "Finanziamenti americani", "first": true, "cont": ["AM"], "rw": "",
		"sp": [{"r": "+", "v": 1, "c": ["S"], "g": ["3J"], "b": [53, 792]}, {"r": "+", "v": 1, "c": ["S"], "g": ["2J"], "b": [323, 793]}, {"r": "+", "v": 1, "c": ["S"], "g": ["J"], "b": [587, 793]}],
		"fx": {"k": "gain", "w": "now", "items": ["xJ"]},
		"txt": "In aggiunta, ottieni Asset a scelta pari al valore del tuo Funzionario."},
	"05": {"t": "Visita di Stato in Corea del Nord", "first": true, "cont": ["AS"], "rw": "",
		"sp": [{"r": "+", "v": 1, "c": ["xE"], "g": ["x2M"], "b": [49, 902]}, {"r": "+", "v": 1, "c": ["xP"], "g": ["x2M"], "b": [326, 903]}, {"r": "+", "v": 1, "c": ["xC"], "g": ["x2M"], "b": [598, 903]}],
		"fx": {}, "txt": ""},
	"06": {"t": "Gasdotto transnazionale", "first": true, "cont": ["EU"], "rw": "C",
		"sp": [{"r": "?", "g": ["E"], "b": [55, 754]}, {"r": "?", "g": ["P"], "b": [333, 749]}, {"r": "?", "g": ["C"], "b": [604, 745]}],
		"fx": {"k": "total_cmp", "w": "res", "op": ">", "n": 6, "reward": ["C", "P", "E"]},
		"txt": "Se la somma totale è maggiore di 6, ogni fazione presente ottiene 1 Consenso, 1 Politica e 1 Economia."},
	"07": {"t": "Costruzione di isole artificiali", "first": true, "cont": ["AS"], "rw": "S",
		"sp": [{"r": "+", "v": 1, "g": ["P"], "b": [34, 779]}, {"r": "?", "c": ["E"], "g": ["P"], "b": [225, 942]}, {"r": "+", "v": 1, "c": ["E"], "g": ["2P"], "b": [416, 779]}, {"r": "?", "c": ["2E"], "g": ["3P"], "b": [608, 940]}],
		"fx": {}, "txt": ""},
	"08": {"t": "Sfruttamento delle miniere di coltan", "first": true, "cont": ["AF"], "rw": "E",
		"sp": [{"r": "?", "g": ["2E"], "b": [50, 932]}, {"r": "?", "c": ["C"], "g": ["2E"], "b": [326, 931]}, {"r": "?", "c": ["2C"], "g": ["2E"], "b": [597, 929]}],
		"fx": {}, "txt": ""},
	"09": {"t": "Relazioni con il Bhutan", "first": true, "cont": ["AS"], "rw": "",
		"sp": [{"r": "=", "v": 1, "g": ["2E"], "b": [31, 762]}, {"r": "=", "v": 1, "g": ["2C"], "b": [223, 924]}, {"r": "=", "v": 1, "g": ["2P"], "b": [414, 762]}, {"r": "+", "v": 1, "c": ["M"], "b": [607, 922]}],
		"fx": {}, "txt": ""},
	"10": {"t": "Consiglio delle Nazioni Unite", "first": true, "cont": [], "rw": "S",
		"sp": [{"r": "?", "b": [36, 701]}, {"r": "?", "c": ["P"], "b": [226, 864]}, {"r": "?", "c": ["2P"], "b": [416, 701]}, {"r": "?", "c": ["3P"], "b": [606, 863]}],
		"fx": {"k": "own_gt", "w": "res", "n": 4, "reward": ["S"]},
		"txt": "Ogni fazione presente con la propria somma maggiore di 4 ottiene 1 Status."},
	"11": {"t": "Ingresso nell'Unione Europea", "first": true, "cont": ["EU"], "rw": "S",
		"sp": [{"r": "=", "v": 1, "b": [32, 879]}, {"r": "?", "c": ["2C"], "b": [225, 1041]}, {"r": "?", "c": ["2P"], "b": [418, 879]}, {"r": "?", "c": ["3E"], "b": [611, 1041]}],
		"fx": {}, "txt": ""},
	"12": {"t": "Accordo diplomatico", "first": true, "cont": ["AF"], "rw": "S",
		"sp": [{"r": "+", "v": 1, "c": ["xC"], "b": [37, 711]}, {"r": "+", "v": 1, "c": ["xM"], "b": [226, 873]}, {"r": "+", "v": 1, "c": ["xE"], "b": [414, 713]}, {"r": "+", "v": 1, "c": ["xP"], "b": [604, 873]}],
		"fx": {"k": "total_cmp", "w": "res", "op": "<", "n": 7, "reward": ["S"]},
		"txt": "Se la somma totale è minore di 7, ogni fazione presente ottiene 1 Status."},
	"13": {"t": "Costruzione di una diga gigante", "first": true, "cont": ["AF"], "rw": "P",
		"sp": [{"r": "+", "v": 1, "g": ["3C"], "b": [55, 930]}, {"r": "<=", "g": ["3C"], "b": [325, 928]}, {"r": "<=", "g": ["3C"], "b": [595, 927]}],
		"fx": {}, "txt": ""},
	"14": {"t": "Rapporti con i narcotrafficanti", "first": true, "cont": ["AM", "AS"], "rw": "",
		"sp": [{"r": "?", "c": ["P"], "g": ["3E"], "b": [41, 920]}, {"r": "?", "c": ["M"], "g": ["3C"], "b": [322, 920]}, {"r": "?", "c": ["E"], "g": ["3P"], "b": [596, 920]}],
		"fx": {}, "txt": ""},
	"15": {"t": "Patto con Dubai", "first": true, "cont": ["AS"], "rw": "E",
		"sp": [{"r": "+", "v": 1, "c": ["xM"], "g": ["x2E"], "b": [47, 934]}, {"r": "+", "v": 1, "c": ["xP"], "g": ["x2E"], "b": [325, 935]}, {"r": "+", "v": 1, "c": ["xC"], "g": ["x2E"], "b": [596, 935]}],
		"fx": {}, "txt": ""},
	"16": {"t": "Sfruttamento di combustibili fossili", "first": true, "cont": ["AS"], "rw": "E",
		"sp": [{"r": "+", "v": 1, "g": ["3E"], "b": [51, 744]}, {"r": "<=", "g": ["3E"], "b": [316, 741]}, {"r": "<=", "g": ["3E"], "b": [582, 738]}],
		"fx": {"k": "coin_lose", "w": "now", "loss": "C"},
		"txt": "Lancia la Moneta. Se esce Testa, perdi 1 Consenso (oppure 1 Status)."},
	"17": {"t": "Indizione di libere elezioni", "first": true, "cont": ["AM"], "rw": "S",
		"sp": [{"r": "+", "v": 1, "c": ["3C"], "b": [30, 701]}, {"r": "+", "v": 2, "c": ["2C"], "b": [221, 860]}, {"r": "+", "v": 3, "c": ["C"], "b": [405, 696]}, {"r": "=", "v": 4, "b": [597, 855]}],
		"fx": {"k": "own_gt", "w": "res", "n": 4, "reward": ["S"]},
		"txt": "Ogni fazione presente con la propria somma maggiore di 4 ottiene 1 Status."},
	"18": {"t": "Relazioni con l'Egitto", "first": true, "cont": ["AF"], "rw": "E",
		"sp": [{"r": "+", "v": 1, "c": ["xM"], "g": ["x2P"], "b": [58, 936]}, {"r": "+", "v": 1, "c": ["xE"], "g": ["x2P"], "b": [330, 934]}, {"r": "+", "v": 1, "c": ["xC"], "g": ["x2P"], "b": [596, 932]}],
		"fx": {}, "txt": ""},
	"19": {"t": "Ingresso nella NATO", "first": true, "cont": ["AM", "EU"], "rw": "",
		"sp": [{"r": "+", "v": 1, "g": ["3M"], "b": [48, 910]}, {"r": "<=", "g": ["3M"], "b": [321, 911]}, {"r": "<=", "g": ["3M"], "b": [595, 911]}],
		"fx": {}, "txt": ""},
	"20": {"t": "Investimenti in Africa", "first": true, "cont": ["AF"], "rw": "S",
		"sp": [{"r": "=", "v": 1, "g": ["2E"], "b": [33, 873]}, {"r": "?", "c": ["2C"], "b": [223, 1036]}, {"r": "?", "c": ["2P"], "b": [415, 875]}, {"r": "?", "c": ["2M"], "b": [606, 1036]}],
		"fx": {}, "txt": ""},
	"21": {"t": "Ingresso nei BRICS", "first": true, "cont": ["AM", "AF", "AS"], "rw": "",
		"sp": [{"r": "+", "v": 1, "c": ["3P"], "b": [54, 848]}, {"r": "+", "v": 2, "c": ["2P"], "b": [322, 843]}, {"r": "+", "v": 3, "c": ["P"], "b": [585, 839]}],
		"fx": {"k": "full", "w": "res", "reward": ["S"]},
		"txt": "Se sono presenti 3 Funzionari, ogni fazione presente ottiene 1 Status."},
	"22": {"t": "Transizione democratica", "first": true, "cont": ["AF"], "rw": "C",
		"sp": [{"r": "+", "v": 1, "c": ["P"], "g": ["xC"], "b": [76, 919]}, {"r": "+", "v": 1, "c": ["M"], "g": ["xC"], "b": [346, 919]}, {"r": "+", "v": 1, "c": ["E"], "g": ["xC"], "b": [616, 918]}],
		"fx": {}, "txt": ""},
	"23": {"t": "Politica del disarmo", "first": true, "cont": ["AF"], "rw": "C",
		"sp": [{"r": "+", "v": 1, "b": [48, 801]}, {"r": "+", "v": 1, "c": ["E"], "b": [320, 801]}, {"r": "+", "v": 1, "c": ["P"], "b": [586, 801]}],
		"fx": {"k": "disarm", "w": "now"},
		"txt": "Puoi indietreggiare di 4 spazi sul tracciato Militare per ottenere 1 Status, oppure di 8 spazi per ottenerne 2."},
	"24": {"t": "Investimento in criptovalute", "first": true, "cont": ["AM", "EU"], "rw": "",
		"sp": [{"r": "?", "c": ["E"], "b": [53, 843]}, {"r": "?", "c": ["E"], "b": [324, 838]}, {"r": "?", "c": ["E"], "b": [590, 833]}],
		"fx": {"k": "coin_gain", "w": "now", "items": ["4E"]},
		"txt": "Lancia la Moneta. Se esce Testa, ottieni 4 Economia."},
	"25": {"t": "Tensioni tra Cina e Taiwan", "first": false, "cont": ["AS"], "rw": "P", "vs": true,
		"sp": [{"r": "?", "c": ["2M"], "b": [38, 629], "s": 0}, {"r": "?", "c": ["P"], "b": [192, 868], "s": 0}, {"r": "?", "c": ["M"], "b": [453, 868], "s": 1}, {"r": "?", "c": ["2E"], "b": [603, 629], "s": 1}],
		"fx": {"k": "vs", "w": "res"},
		"txt": "Lancia la Moneta e aggiungi 3 al lato ottenuto. Le fazioni nel lato con somma maggiore ottengono 1 Status. In caso di parità vince il lato ottenuto."},
	"26": {"t": "Genocidio a Gaza", "first": false, "cont": ["AF", "AS"], "rw": "",
		"sp": [{"r": "+", "v": 1, "c": ["C"], "b": [26, 704]}, {"r": "+", "v": 1, "c": ["C"], "b": [220, 867]}, {"r": "+", "v": 1, "c": ["P"], "b": [415, 706]}, {"r": "+", "v": 1, "c": ["2P"], "b": [609, 868]}],
		"fx": {"k": "total_cmp", "w": "res", "op": ">", "n": 8, "reward": ["S"]},
		"txt": "Se la somma totale è maggiore di 8, ogni fazione presente ottiene 1 Status."},
	"27": {"t": "Invasione russa dell'Ucraina", "first": false, "cont": ["EU"], "rw": "S", "vs": true,
		"sp": [{"r": "?", "c": ["E"], "b": [39, 623], "s": 0}, {"r": "?", "c": ["P"], "b": [195, 860], "s": 0}, {"r": "?", "c": ["2M"], "b": [453, 860], "s": 1}, {"r": "?", "c": ["2M"], "b": [605, 624], "s": 1}],
		"fx": {"k": "vs", "w": "res"},
		"txt": "Lancia la Moneta e aggiungi 3 al lato ottenuto. Le fazioni nel lato con somma maggiore ottengono 1 Status. In caso di parità vince il lato ottenuto."},
	"28": {"t": "Compagnia di contractor", "first": false, "cont": ["AS"], "rw": "",
		"sp": [{"r": "?", "g": ["M"], "b": [68, 783]}, {"r": "?", "c": ["E"], "g": ["2M"], "b": [341, 784]}, {"r": "?", "c": ["2E"], "g": ["3M"], "b": [608, 785]}],
		"fx": {"k": "mil_leader", "w": "res", "reward": ["3J"]},
		"txt": "La fazione in gioco più avanti sul tracciato Militare ottiene 3 Asset a scelta."},
	"29": {"t": "Traffico di armi", "first": false, "cont": ["EU", "AF"], "rw": "",
		"sp": [{"r": "+", "v": 1, "c": ["xM"], "g": ["x2E"], "b": [169, 721]}, {"r": "+", "v": 1, "c": ["xE"], "g": ["x2M"], "b": [464, 725]}],
		"fx": {"k": "same_value", "w": "res", "reward": ["2P"]},
		"txt": "Se entrambi i Funzionari hanno lo stesso valore, ogni fazione presente ottiene 2 Politica."},
	"30": {"t": "Gestione della crisi migratoria", "first": false, "cont": ["EU", "AS"], "rw": "C",
		"sp": [{"r": "?", "c": ["M"], "b": [55, 830]}, {"r": "?", "c": ["E"], "b": [328, 830]}, {"r": "?", "c": ["P"], "b": [592, 829]}],
		"fx": {"k": "punish", "w": "res", "loss": "2C"},
		"txt": "Le fazioni non presenti oppure, se tutte presenti, quelle con somma minore perdono 2 Consenso (oppure 1 Status)."},
	"31": {"t": "Non siamo uno stato canaglia!", "first": false, "cont": [], "rw": "S",
		"sp": [{"r": "+", "v": 1, "c": ["2P"], "b": [36, 696]}, {"r": "+", "v": 2, "c": ["P"], "b": [225, 858]}, {"r": "+", "v": 3, "c": ["P"], "b": [413, 698]}, {"r": "=", "v": 4, "b": [602, 859]}],
		"fx": {"k": "punish", "w": "res", "loss": "S"},
		"txt": "Le fazioni non presenti oppure, se tutte presenti, quelle con somma minore perdono 1 Status."},
	"32": {"t": "Incontro di Davos", "first": false, "cont": ["EU"], "rw": "P",
		"sp": [{"r": "+", "v": 1, "b": [72, 751]}, {"r": "+", "v": 1, "c": ["E"], "g": ["P"], "b": [345, 750]}, {"r": "+", "v": 1, "c": ["2E"], "g": ["2P"], "b": [612, 748]}],
		"fx": {"k": "total_cmp", "w": "now", "op": ">", "n": 7, "reward": ["S"]},
		"txt": "Dopo aver posizionato il tuo Funzionario, se la somma totale è maggiore di 7, ogni fazione presente ottiene 1 Status."},
	"33": {"t": "Programma nucleare", "first": false, "cont": [], "rw": "S",
		"sp": [{"r": "+", "v": 3, "c": ["2E"], "g": ["2M"], "b": [54, 769]}, {"r": "?", "c": ["E"], "b": [326, 771]}, {"r": "?", "c": ["E"], "b": [593, 772]}],
		"fx": {"k": "total_cmp", "w": "res", "op": "<", "n": 6, "reward": ["2J"]},
		"txt": "Se la somma totale è minore di 6, ogni fazione presente ottiene 2 Asset a scelta."},
	"34": {"t": "Operazione di intelligence", "first": false, "cont": ["AM"], "rw": "",
		"sp": [{"r": "?", "g": ["2P"], "b": [40, 702]}, {"r": "?", "b": [229, 863]}, {"r": "?", "b": [416, 702]}, {"r": "?", "b": [606, 862]}],
		"fx": {"k": "reveal", "w": "now"},
		"txt": "Rivela un Funzionario di un'altra fazione su questa carta (se presente), poi ottieni Asset a scelta pari al suo valore."},
	"35": {"t": "Deep State", "first": false, "cont": [], "rw": "P",
		"sp": [{"r": "=", "v": 4, "b": [53, 805]}, {"r": "=", "v": 3, "b": [323, 806]}, {"r": "=", "v": 2, "b": [587, 807]}],
		"fx": {"k": "deep_state", "w": "now"},
		"txt": "Ottieni Consenso, Politica oppure Economia pari al valore del tuo Funzionario. Poi ogni altra fazione in gioco ottiene 1 Asset dello stesso tipo."},
	"36": {"t": "Riconoscimento del passaporto", "first": false, "cont": ["AM", "EU", "AF", "AS"], "rw": "",
		"sp": [{"r": "+", "v": 1, "c": ["xP"], "b": [170, 837]}, {"r": "+", "v": 1, "c": ["xP"], "b": [466, 837]}],
		"fx": {"k": "total_cmp", "w": "res", "op": ">", "n": 5, "reward": ["S"]},
		"txt": "Se la somma totale è maggiore di 5, ogni fazione presente ottiene 1 Status."},
	"37": {"t": "Conflitto indo-pakistano", "first": false, "cont": ["AS"], "rw": "", "vs": true,
		"sp": [{"r": "?", "c": ["2P"], "b": [31, 627], "s": 0}, {"r": "?", "c": ["M"], "b": [191, 864], "s": 0}, {"r": "?", "c": ["C"], "b": [453, 864], "s": 1}, {"r": "?", "c": ["2M"], "b": [605, 627], "s": 1}],
		"fx": {"k": "vs", "w": "res"},
		"txt": "Lancia la Moneta e aggiungi 3 al lato ottenuto. Le fazioni nel lato con somma maggiore ottengono 1 Status. In caso di parità vince il lato ottenuto."},
	"38": {"t": "Una nuova pandemia", "first": false, "cont": [], "rw": "S",
		"sp": [{"r": "?", "b": [52, 829]}, {"r": "?", "c": ["P"], "b": [321, 828]}, {"r": "?", "c": ["2P"], "b": [585, 826]}],
		"fx": {"k": "punish", "w": "res", "loss": "3C", "coin": true},
		"txt": "Lancia la Moneta. Se esce Testa, le fazioni non presenti oppure, se tutte presenti, quelle con somma minore perdono 3 Consenso (oppure 1 Status)."},
	"39": {"t": "Avvento dell'algocrazia", "first": false, "cont": ["EU"], "rw": "",
		"sp": [{"r": "+", "v": 1, "b": [44, 811]}, {"r": "+", "v": 1, "b": [320, 814]}, {"r": "+", "v": 1, "b": [590, 817]}],
		"fx": {"k": "algocrazia", "w": "now"},
		"txt": "Lancia la Moneta. Testa: ottieni Politica oppure Economia pari al valore. Arco: ottieni Consenso pari al valore oppure avanza di altrettanti spazi sul tracciato Militare."},
	"40": {"t": "Processo di dedollarizzazione", "first": false, "cont": ["EU"], "rw": "J",
		"sp": [{"r": "?", "b": [53, 808]}, {"r": "?", "b": [324, 808]}, {"r": "?", "b": [589, 808]}],
		"fx": {"k": "income", "w": "now"},
		"txt": "Ottieni immediatamente la rendita da tutti i tuoi segnalini Rendita."},
	"P1": {"t": "Fondazione di Novalandia", "first": false, "cont": [], "rw": "S", "promo": true,
		"sp": [{"r": "?", "c": ["E"], "b": [49, 845]}, {"r": "?", "c": ["P"], "b": [327, 844]}, {"r": "?", "c": ["C"], "b": [599, 843]}],
		"fx": {"k": "rendita_from_cost", "w": "now"},
		"txt": "Prendi un segnalino Rendita corrispondente all'Asset che hai speso per posizionare il tuo Funzionario."},
	"P2": {"t": "Alleanza con la Bielorussia", "first": false, "cont": ["EU", "AS"], "rw": "", "promo": true,
		"sp": [{"r": "+", "v": 1, "b": [36, 687]}, {"r": "+", "v": 1, "b": [227, 851]}, {"r": "+", "v": 1, "b": [416, 688]}, {"r": "+", "v": 1, "b": [607, 850]}],
		"fx": {"k": "coin_gain", "w": "now", "items": ["xJ"]},
		"txt": "Lancia la Moneta. Se esce Testa, ottieni Asset a scelta pari al valore del tuo Funzionario."},
}

## Spazi Giornale sul tabellone (coordinate tabellone 1600x1065, centro dello spazio)
const GIORNALE := {
	"G1": {"name": "Giornale della Finanza", "spaces": [
		{"r": "+", "v": 1, "g": ["xC"], "p": [92, 405]},
		{"r": "+", "v": 1, "g": ["xE"], "p": [173, 405]},
		{"r": "+", "v": 1, "g": ["xP"], "p": [255, 405]},
		{"r": "+", "v": 1, "g": ["xM"], "p": [337, 405]}],
		"fx": {"k": "debt", "w": "res"},
		"txt": "Risoluzione: ogni fazione presente scarta 1 Asset a scelta (oppure perde 1 Status) per ogni suo Funzionario qui."},
	"G2": {"name": "Giornale della Diplomazia", "spaces": [
		{"r": "?", "g2": true, "p": [547, 303]}, {"r": "?", "g2": true, "p": [631, 303]}, {"r": "?", "g2": true, "p": [716, 303]},
		{"r": "?", "g2": true, "p": [547, 413]}, {"r": "?", "g2": true, "p": [631, 413]}, {"r": "?", "g2": true, "p": [716, 413]}],
		"fx": {}, "txt": "Ottieni 1 Asset a scelta oppure avanza di 1 spazio sul tracciato Militare."},
	"G3": {"name": "Giornale della Politica", "spaces": [
		{"r": "+", "v": 1, "p": [842, 412]}, {"r": "+", "v": 1, "p": [923, 412]},
		{"r": "+", "v": 1, "p": [1004, 412]}, {"r": "+", "v": 1, "p": [1085, 412]}],
		"fx": {"k": "g3", "w": "now"},
		"txt": "Fulmine: scarta Consenso+Politica+Economia, oppure 4 Asset qualsiasi, oppure indietreggia di 4 spazi Militari, per ottenere 1 Status."},
}

## Geometria del tabellone (spazio 1600x1065)
const BOARD_W := 1600.0
const BOARD_H := 1065.0
const MIL_X0 := 55.0
const MIL_DX := 69.75
const MIL_Y := 128.0
const MONITOR_X := [57.0, 366.0, 675.0, 982.0, 1291.0]
const MONITOR_Y := 588.0
const MONITOR_W := 272.0
const MONITOR_H := 460.0
const PHASE_X := [87.0, 275.0, 530.0, 750.0, 915.0, 1085.0]
const PHASE_NUM_X := [25.0, 190.0, 428.0, 712.0, 839.0, 1042.0]


static func status_pos(k: int) -> Vector2:
	if k <= 0:
		return Vector2(1237, 142)
	var kk := mini(k, 20)
	var r := (kk - 1) / 5
	var c := (kk - 1) % 5
	return Vector2(1237 + c * 75, 217 + r * 75)


static func mil_pos(k: int) -> Vector2:
	return Vector2(MIL_X0 + k * MIL_DX, MIL_Y)


static func all_ids(include_promo: bool) -> Array:
	var out := []
	for id in CARDS.keys():
		if CARDS[id].get("promo", false) and not include_promo:
			continue
		out.append(id)
	return out


static func first_game_ids() -> Array:
	var out := []
	for id in CARDS.keys():
		if CARDS[id]["first"]:
			out.append(id)
	return out


## Analizza un oggetto costo/guadagno: ritorna {t, n, x}
static func parse_item(s: String) -> Dictionary:
	var mult := false
	var i := 0
	if s.begins_with("x"):
		mult = true
		i = 1
	var num := ""
	while i < s.length() and s[i].is_valid_int():
		num += s[i]
		i += 1
	var t := s.substr(i, 1)
	return {"t": t, "n": int(num) if num != "" else 1, "x": mult}


static func item_amount(s: String, value: int) -> int:
	var it := parse_item(s)
	return it["n"] * (value if it["x"] else 1)


## Centro dello spazio i sulla carta, in coordinate normalizzate 0..1
static func space_center_norm(card_id: String, i: int) -> Vector2:
	var b: Array = CARDS[card_id]["sp"][i]["b"]
	return Vector2((b[0] + BOX_W * 0.5) / CARD_W, (b[1] + BOX_H * 0.5) / CARD_H)
