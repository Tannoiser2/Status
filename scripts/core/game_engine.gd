class_name GameEngine
extends Node
## Motore delle regole di STATUS. Nessuna dipendenza dalla UI.
## Le decisioni vengono chieste con `decide()`: l'IA risponde subito,
## per i giocatori umani viene emesso `decision_requested` e si attende `provide_decision()`.

signal changed
signal log_added(text: String)
signal phase_changed(round_n: int, phase_n: int)
signal decision_requested(req: Dictionary)
signal decision_provided(result)
signal game_ended(results: Array)
signal fx(kind: String, data: Dictionary)
signal turn_started(seat: int)
signal pause_requested(text: String)

const FACTIONS := [
	{"id": 0, "name": "Mano Invisibile", "short": "Mano", "color": Color("#3a3a3a"), "light": Color("#9a9a9a"), "rendita": "E"},
	{"id": 1, "name": "Ragione di Stato", "short": "Ragione", "color": Color("#2e9c7f"), "light": Color("#5fd3b0"), "rendita": "P"},
	{"id": 2, "name": "Pugno del Popolo", "short": "Pugno", "color": Color("#23468f"), "light": Color("#6f95e6"), "rendita": "C"},
	{"id": 3, "name": "Nuova Milizia", "short": "Milizia", "color": Color("#c0302a"), "light": Color("#f07068"), "rendita": "M"},
]
const ASSETS := ["E", "P", "C"]
const ASSET_NAMES := {"E": "Economia", "P": "Politica", "C": "Consenso", "J": "Jolly", "M": "Militare", "S": "Status"}
const MIL_MAX := 15
const ROUNDS := 4
const CARDS_PER_ROUND := {2: 3, 3: 4, 4: 5}
const PHASE_NAMES := ["", "Nuovi Eventi", "Inviare i Funzionari", "Risolvere gli Eventi", "Riscuotere la Rendita", "Aumentare lo Status", "Stabilire la Priorità"]
const CONTINENTS := ["AM", "EU", "AF", "AS"]
const CONT_NAMES := {"AM": "America", "EU": "Europa", "AF": "Africa", "AS": "Asia"}

var rng := RandomNumberGenerator.new()
var ai_delay := 0.0
var headless := false
var ai: StatusAI
var ais := {}

var players: Array = []
var n_players := 0
var deck: Array = []
var monitor: Array = []
var spaces: Dictionary = {}       # key -> {"seat", "value", "up"}
var round_n := 0
var phase := 0
var priority := 0
var current_seat := -1
var supply := {"E": 36, "P": 36, "C": 36}
var rendita_supply := {"E": 6, "P": 6, "C": 6, "J": 2}
var discard_box: Array = []
var game_over := false
var results: Array = []
var log_lines: Array = []
var first_game := false
var include_promo := true
var last_coin := ""
var running := false
var abort := false
var pause_enabled := false


# ------------------------------------------------------------------ setup

## config: {"seats": [{"fid":int, "ai":bool, "name":String}], "first_game":bool, "promo":bool, "seed":int}
func setup(config: Dictionary) -> void:
	if config.has("seed"):
		rng.seed = config["seed"]
	else:
		rng.randomize()
	ai = StatusAI.new()
	ai.level = config.get("ai_level", 1)
	first_game = config.get("first_game", false)
	include_promo = config.get("promo", true)
	players.clear()
	var seats: Array = config["seats"]
	n_players = seats.size()
	ais.clear()
	for i in range(n_players):
		var s: Dictionary = seats[i]
		var a := StatusAI.new()
		a.level = s.get("level", ai.level)
		ais[i] = a
		var f: Dictionary = FACTIONS[s["fid"]]
		players.append({
			"seat": i, "fid": s["fid"], "name": s.get("name", f["name"]), "ai": s.get("ai", true),
			"assets": {"E": 0, "P": 0, "C": 0},
			"rendita": {"E": 0, "P": 0, "C": 0, "J": 0, "M": 0},
			"mil": 0, "status": 1, "cards": [], "stack": [], "hand": 0, "seen": [],
		})
	# mazzo Eventi
	var pool: Array = CardsDB.first_game_ids() if first_game else CardsDB.all_ids(include_promo)
	_shuffle(pool)
	var deck_size: int = CARDS_PER_ROUND[n_players] * ROUNDS
	deck = pool.slice(0, deck_size)
	monitor = []
	for i in range(5):
		monitor.append("")
	spaces.clear()
	round_n = 1
	phase = 0
	log_lines.clear()
	game_over = false
	results.clear()
	supply = {"E": 36, "P": 36, "C": 36}
	rendita_supply = {"E": 6, "P": 6, "C": 6, "J": 2}
	# priorità e tracciato Militare
	priority = rng.randi_range(0, n_players - 1)
	var pos := 5
	for k in range(n_players):
		var seat := (priority + k) % n_players
		players[seat]["mil"] = pos
		pos += 1
	# funzionari, asset e rendita iniziali
	for p in players:
		_reshuffle_officers(p)
		for t in ASSETS:
			_add_asset(p, t, 1)
		var r: String = FACTIONS[p["fid"]]["rendita"]
		p["rendita"][r] += 1
		if r in rendita_supply:
			rendita_supply[r] -= 1


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func _reshuffle_officers(p: Dictionary) -> void:
	var st := [1, 2, 3, 4]
	_shuffle(st)
	p["hand"] = st.pop_back()
	p["stack"] = st
	p["seen"] = []


# ------------------------------------------------------------------ utility

func pname(seat: int) -> String:
	return players[seat]["name"]


func log_msg(t: String) -> void:
	log_lines.append(t)
	log_added.emit(t)


func turn_order() -> Array:
	var out := []
	for k in range(n_players):
		out.append((priority + k) % n_players)
	return out


func cards_per_round() -> int:
	return CARDS_PER_ROUND[n_players]


func asset_total(p: Dictionary) -> int:
	return p["assets"]["E"] + p["assets"]["P"] + p["assets"]["C"]


func _add_asset(p: Dictionary, t: String, n: int) -> int:
	var got := mini(n, supply[t])
	supply[t] -= got
	p["assets"][t] += got
	return got


func _remove_asset(p: Dictionary, t: String, n: int) -> void:
	var k := mini(n, p["assets"][t])
	p["assets"][t] -= k
	supply[t] += k


func change_status(seat: int, d: int) -> void:
	var p: Dictionary = players[seat]
	var old: int = p["status"]
	p["status"] = maxi(0, old + d)
	var real: int = p["status"] - old
	if real > 0:
		log_msg("  %s ottiene %d Status (ora %d)." % [pname(seat), real, p["status"]])
	elif real < 0:
		log_msg("  %s perde %d Status (ora %d)." % [pname(seat), -real, p["status"]])
	fx.emit("status", {"seat": seat, "delta": real})


## Sposta l'indicatore Militare con la regola delle spinte.
func move_mil(seat: int, delta: int) -> void:
	if delta == 0:
		return
	var p: Dictionary = players[seat]
	var from: int = p["mil"]
	var to: int = clampi(from + delta, 0, MIL_MAX)
	if to == from:
		return
	var occ := {}
	for q in players:
		if q["seat"] != seat:
			occ[q["mil"]] = q["seat"]
	p["mil"] = to
	var step := -1 if to > from else 1   # direzione della spinta
	var cur := to
	var pushed = occ.get(cur, -1)
	while pushed != -1:
		var nxt := cur + step
		var next_pushed = occ.get(nxt, -1)
		players[pushed]["mil"] = nxt
		occ.erase(cur)
		cur = nxt
		pushed = next_pushed
	if delta > 0:
		log_msg("  %s avanza sul tracciato Militare: %d → %d." % [pname(seat), from, to])
	else:
		log_msg("  %s indietreggia sul tracciato Militare: %d → %d." % [pname(seat), from, to])
	fx.emit("mil", {"seat": seat})


## Spareggio: vince chi è più avanti nel Militare, poi indietreggia di 1.
func tiebreak(seats: Array, move_back := true) -> int:
	var best: int = seats[0]
	for s in seats:
		if players[s]["mil"] > players[best]["mil"]:
			best = s
	if move_back and seats.size() > 1:
		log_msg("  Parità: vince %s (più avanti nel Militare) e indietreggia di 1." % pname(best))
		move_mil(best, -1)
	return best


func flip_coin() -> String:
	last_coin = "head" if rng.randi_range(0, 1) == 0 else "arch"
	log_msg("  Lancio della Moneta: esce %s." % ("TESTA" if last_coin == "head" else "ARCO"))
	fx.emit("coin", {"side": last_coin})
	return last_coin


# ------------------------------------------------------------------ spazi

func all_space_keys() -> Array:
	var out := []
	for g in ["G1", "G2", "G3"]:
		for i in range(CardsDB.GIORNALE[g]["spaces"].size()):
			out.append("%s_%d" % [g, i])
	for slot in range(5):
		var cid: String = monitor[slot]
		if cid == "":
			continue
		for i in range(CardsDB.CARDS[cid]["sp"].size()):
			out.append("M%d_%d" % [slot, i])
	return out


## Ritorna la definizione dello spazio + info di contesto.
func space_def(key: String) -> Dictionary:
	var parts := key.split("_")
	var head: String = parts[0]
	var idx := int(parts[1])
	if head.begins_with("G"):
		var d: Dictionary = CardsDB.GIORNALE[head]["spaces"][idx].duplicate()
		d["group"] = head
		d["slot"] = -1
		d["idx"] = idx
		return d
	var slot := int(head.substr(1))
	var cid: String = monitor[slot]
	var d2: Dictionary = CardsDB.CARDS[cid]["sp"][idx].duplicate()
	d2["group"] = "M"
	d2["slot"] = slot
	d2["idx"] = idx
	d2["card"] = cid
	return d2


func card_keys(slot: int) -> Array:
	var out := []
	var cid: String = monitor[slot]
	if cid == "":
		return out
	for i in range(CardsDB.CARDS[cid]["sp"].size()):
		out.append("M%d_%d" % [slot, i])
	return out


func group_keys(group: String) -> Array:
	if group.begins_with("M"):
		return card_keys(int(group.substr(1)))
	var out := []
	for i in range(CardsDB.GIORNALE[group]["spaces"].size()):
		out.append("%s_%d" % [group, i])
	return out


func can_pay(p: Dictionary, costs: Array, value: int) -> bool:
	var need := {"E": 0, "P": 0, "C": 0, "M": 0, "S": 0}
	for c in costs:
		var it := CardsDB.parse_item(c)
		need[it["t"]] += it["n"] * (value if it["x"] else 1)
	for t in ASSETS:
		if p["assets"][t] < need[t]:
			return false
	if p["mil"] < need["M"]:
		return false
	if p["status"] < need["S"]:
		return false
	return true


func is_legal(seat: int, key: String, value: int) -> bool:
	if spaces.has(key):
		return false
	var d := space_def(key)
	var r: String = d["r"]
	match r:
		"=":
			if value != d["v"]:
				return false
		"+":
			if value < d["v"]:
				return false
		"<=":
			var left := "M%d_%d" % [d["slot"], d["idx"] - 1]
			if not spaces.has(left):
				return false
			if value < spaces[left]["value"]:
				return false
	return can_pay(players[seat], d.get("c", []), value)


func legal_spaces(seat: int, value: int) -> Array:
	var out := []
	for k in all_space_keys():
		if is_legal(seat, k, value):
			out.append(k)
	return out


func seats_on(group: String) -> Array:
	var out := []
	for k in group_keys(group):
		if spaces.has(k):
			var s: int = spaces[k]["seat"]
			if not out.has(s):
				out.append(s)
	return out


func sum_on(group: String, seat: int) -> int:
	var t := 0
	for k in group_keys(group):
		if spaces.has(k) and spaces[k]["seat"] == seat:
			t += spaces[k]["value"]
	return t


func total_on(group: String) -> int:
	var t := 0
	for k in group_keys(group):
		if spaces.has(k):
			t += spaces[k]["value"]
	return t


# ------------------------------------------------------------------ decisioni

func decide(seat: int, req: Dictionary):
	req["seat"] = seat
	if abort:
		return ai.decide(self, seat, req)
	if players[seat]["ai"]:
		if ai_delay > 0.0 and not headless and is_inside_tree():
			await get_tree().create_timer(ai_delay).timeout
		return ais[seat].decide(self, seat, req)
	decision_requested.emit(req)
	var r = await decision_provided
	return r


func pause_point(text: String) -> void:
	if pause_enabled and not abort:
		pause_requested.emit(text)
		await decision_provided


func provide_decision(result) -> void:
	decision_provided.emit(result)


## Guadagno di n Asset a scelta (jolly)
func gain_jolly(seat: int, n: int) -> void:
	if n <= 0:
		return
	var p: Dictionary = players[seat]
	var mx := {}
	var avail := 0
	for t in ASSETS:
		mx[t] = supply[t]
		avail += supply[t]
	n = mini(n, avail)
	if n <= 0:
		return
	var res: Dictionary = await decide(seat, {"type": "alloc", "mode": "gain", "n": n, "max": mx,
		"title": "Scegli %d Asset da prendere" % n})
	var parts := []
	for t in ASSETS:
		var k: int = res.get(t, 0)
		if k > 0:
			_add_asset(p, t, k)
			parts.append("%d %s" % [k, ASSET_NAMES[t]])
	log_msg("  %s prende %s." % [pname(seat), ", ".join(parts)])


## Scarto di n Asset a scelta, con eventuale sostituzione con Status
func lose_jolly(seat: int, n: int, allow_status: bool, title: String) -> void:
	if n <= 0:
		return
	var p: Dictionary = players[seat]
	var mx := {}
	var have := 0
	for t in ASSETS:
		mx[t] = p["assets"][t]
		have += p["assets"][t]
	if allow_status:
		mx["S"] = p["status"]
	var cap: int = have + (p["status"] if allow_status else 0)
	var nn := mini(n, cap)
	var missing := n - nn
	if nn > 0:
		var res: Dictionary = await decide(seat, {"type": "alloc", "mode": "lose", "n": nn, "max": mx, "title": title})
		var parts := []
		for t in ASSETS:
			var k: int = res.get(t, 0)
			if k > 0:
				_remove_asset(p, t, k)
				parts.append("%d %s" % [k, ASSET_NAMES[t]])
		if parts.size() > 0:
			log_msg("  %s scarta %s." % [pname(seat), ", ".join(parts)])
		if res.get("S", 0) > 0:
			change_status(seat, -res["S"])
	if missing > 0:
		log_msg("  %s non ha nulla da scartare." % pname(seat))


## "perdi nC (oppure S)"
func pay_or_lose_status(seat: int, t: String, n: int) -> void:
	var p: Dictionary = players[seat]
	var opts := []
	if p["assets"][t] >= n:
		opts.append({"id": "pay", "label": "Scarta %d %s" % [n, ASSET_NAMES[t]]})
	opts.append({"id": "status", "label": "Perdi 1 Status"})
	var choice = "status"
	if opts.size() > 1:
		choice = await decide(seat, {"type": "choice", "ctx": "pay_or_status", "t": t, "n": n,
			"title": "%s: scarta %d %s oppure perdi 1 Status" % [pname(seat), n, ASSET_NAMES[t]], "options": opts})
	if choice == "pay":
		_remove_asset(p, t, n)
		log_msg("  %s scarta %d %s." % [pname(seat), n, ASSET_NAMES[t]])
	else:
		change_status(seat, -1)


func apply_items(seat: int, items: Array, value: int, gain: bool) -> void:
	var p: Dictionary = players[seat]
	for s in items:
		var it := CardsDB.parse_item(s)
		var amt: int = it["n"] * (value if it["x"] else 1)
		var t: String = it["t"]
		if amt <= 0:
			continue
		if gain:
			match t:
				"E", "P", "C":
					var got := _add_asset(p, t, amt)
					log_msg("  %s prende %d %s." % [pname(seat), got, ASSET_NAMES[t]])
				"J":
					await gain_jolly(seat, amt)
				"M":
					move_mil(seat, amt)
				"S":
					change_status(seat, amt)
		else:
			match t:
				"E", "P", "C":
					_remove_asset(p, t, amt)
					log_msg("  %s paga %d %s." % [pname(seat), amt, ASSET_NAMES[t]])
				"M":
					move_mil(seat, -amt)
				"S":
					change_status(seat, -amt)
				"J":
					await lose_jolly(seat, amt, false, "Scarta %d Asset" % amt)


func take_rendita(seat: int, t: String) -> void:
	if rendita_supply.get(t, 0) <= 0:
		log_msg("  Nessun segnalino Rendita %s disponibile nella riserva." % ASSET_NAMES[t])
		return
	rendita_supply[t] -= 1
	players[seat]["rendita"][t] += 1
	log_msg("  %s prende un segnalino Rendita %s." % [pname(seat), ASSET_NAMES[t]])


func collect_income(seat: int) -> void:
	var p: Dictionary = players[seat]
	var r: Dictionary = p["rendita"]
	var parts := []
	for t in ASSETS:
		if r[t] > 0:
			parts.append("%d %s" % [_add_asset(p, t, r[t]), ASSET_NAMES[t]])
	if parts.size() > 0:
		log_msg("  %s riscuote %s." % [pname(seat), ", ".join(parts)])
	if r["M"] > 0:
		move_mil(seat, r["M"])
	if r["J"] > 0:
		await gain_jolly(seat, r["J"])


# ------------------------------------------------------------------ flusso di gioco

func run() -> void:
	running = true
	log_msg("=== Inizia la partita: %d fazioni ===" % n_players)
	log_msg("Priorità a %s." % pname(priority))
	for p in players:
		await collect_income(p["seat"])
	for r in range(1, ROUNDS + 1):
		if abort:
			return
		round_n = r
		await phase_1()
		await phase_2()
		await phase_3()
		await phase_4()
		await phase_5()
		phase_6()
	final_scoring()
	running = false


func _set_phase(ph: int) -> void:
	phase = ph
	log_msg("— Round %d · Fase %s: %s —" % [round_n, ["", "I", "II", "III", "IV", "V", "VI"][ph], PHASE_NAMES[ph]])
	phase_changed.emit(round_n, ph)
	changed.emit()


func phase_1() -> void:
	_set_phase(1)
	for i in range(5):
		monitor[i] = ""
	for i in range(cards_per_round()):
		if deck.is_empty():
			break
		monitor[i] = deck.pop_front()
		log_msg("  Nuovo evento: %s." % CardsDB.CARDS[monitor[i]]["t"])
	changed.emit()


func phase_2() -> void:
	_set_phase(2)
	for _pass in range(4):
		for seat in turn_order():
			if abort:
				return
			var p: Dictionary = players[seat]
			if p["hand"] <= 0:
				continue
			current_seat = seat
			turn_started.emit(seat)
			changed.emit()
			var value: int = p["hand"]
			var opts := legal_spaces(seat, value)
			if opts.is_empty():
				log_msg("%s non ha spazi disponibili: il Funzionario resta fuori." % pname(seat))
				p["hand"] = p["stack"].pop_back() if p["stack"].size() > 0 else 0
				continue
			var key: String = await decide(seat, {"type": "place", "value": value, "options": opts,
				"title": "%s: invia il Funzionario (valore %d)" % [pname(seat), value]})
			await place(seat, key)
			p["hand"] = p["stack"].pop_back() if p["stack"].size() > 0 else 0
			changed.emit()
	current_seat = -1


func place(seat: int, key: String) -> void:
	var p: Dictionary = players[seat]
	var value: int = p["hand"]
	var d := space_def(key)
	var up: bool = d["r"] != "?"
	var where: String = CardsDB.GIORNALE[d["group"]]["name"] if d["slot"] < 0 else CardsDB.CARDS[d["card"]]["t"]
	log_msg("%s invia un Funzionario %s su «%s»." % [pname(seat), ("di valore %d" % value) if up else "coperto", where])
	await apply_items(seat, d.get("c", []), value, false)
	spaces[key] = {"seat": seat, "value": value, "up": up}
	if up:
		p["seen"].append(value)
	fx.emit("place", {"key": key, "seat": seat})
	changed.emit()
	await apply_items(seat, d.get("g", []), value, true)
	if d.get("g2", false):
		var c = await decide(seat, {"type": "choice", "ctx": "g2", "title": "Giornale: scegli il guadagno",
			"options": [{"id": "J", "label": "1 Asset a scelta"}, {"id": "M", "label": "+1 Militare"}]})
		if c == "J":
			await gain_jolly(seat, 1)
		else:
			move_mil(seat, 1)
	# effetti fulmine
	if d["group"] == "G3":
		await effect_g3(seat)
	elif d["slot"] >= 0:
		var fxd: Dictionary = CardsDB.CARDS[d["card"]]["fx"]
		if fxd.get("w", "") == "now":
			await run_now_effect(seat, d, value, fxd)
	changed.emit()


func effect_g3(seat: int) -> void:
	var p: Dictionary = players[seat]
	var opts := []
	if p["assets"]["E"] >= 1 and p["assets"]["P"] >= 1 and p["assets"]["C"] >= 1:
		opts.append({"id": "set", "label": "Scarta Consenso + Politica + Economia → +1 Status"})
	if asset_total(p) >= 4:
		opts.append({"id": "four", "label": "Scarta 4 Asset qualsiasi → +1 Status"})
	if p["mil"] >= 4:
		opts.append({"id": "mil", "label": "Indietreggia di 4 nel Militare → +1 Status"})
	opts.append({"id": "none", "label": "Non fare nulla"})
	var c = await decide(seat, {"type": "choice", "ctx": "g3", "title": "Giornale della Politica", "options": opts})
	match c:
		"set":
			for t in ASSETS:
				_remove_asset(p, t, 1)
			log_msg("  %s scarta Consenso, Politica ed Economia." % pname(seat))
			change_status(seat, 1)
		"four":
			await lose_jolly(seat, 4, false, "Scarta 4 Asset qualsiasi")
			change_status(seat, 1)
		"mil":
			move_mil(seat, -4)
			change_status(seat, 1)


func run_now_effect(seat: int, d: Dictionary, value: int, fxd: Dictionary) -> void:
	var p: Dictionary = players[seat]
	var group := "M%d" % d["slot"]
	match fxd["k"]:
		"coin_gain":
			if flip_coin() == "head":
				await apply_items(seat, fxd["items"], value, true)
		"coin_lose":
			if flip_coin() == "head":
				await pay_or_lose_status(seat, fxd["loss"], 1)
		"gain":
			await apply_items(seat, fxd["items"], value, true)
		"tribute":
			for q in turn_order():
				if q == seat:
					continue
				var qp: Dictionary = players[q]
				if asset_total(qp) <= 0:
					log_msg("  %s mostra di non avere Asset." % pname(q))
					continue
				var opts := []
				for t in ASSETS:
					if qp["assets"][t] > 0:
						opts.append({"id": t, "label": "Dai 1 %s" % ASSET_NAMES[t]})
				var c = await decide(q, {"type": "choice", "ctx": "tribute", "title": "%s: dai 1 Asset a %s" % [pname(q), pname(seat)], "options": opts})
				qp["assets"][c] -= 1
				p["assets"][c] += 1
				log_msg("  %s dà 1 %s a %s." % [pname(q), ASSET_NAMES[c], pname(seat)])
		"income":
			await collect_income(seat)
		"reveal":
			var opts2 := []
			for k in card_keys(d["slot"]):
				if spaces.has(k) and spaces[k]["seat"] != seat and not spaces[k]["up"]:
					opts2.append({"id": k, "label": "Funzionario coperto di %s" % pname(spaces[k]["seat"])})
			if opts2.is_empty():
				log_msg("  Nessun Funzionario coperto di altre fazioni da rivelare.")
			else:
				var k2: String = await decide(seat, {"type": "choice", "ctx": "reveal", "title": "Scegli il Funzionario da rivelare", "options": opts2})
				spaces[k2]["up"] = true
				var v2: int = spaces[k2]["value"]
				players[spaces[k2]["seat"]]["seen"].append(v2)
				log_msg("  Rivelato: il Funzionario di %s vale %d." % [pname(spaces[k2]["seat"]), v2])
				fx.emit("place", {"key": k2, "seat": spaces[k2]["seat"]})
				await gain_jolly(seat, v2)
		"deep_state":
			var c3 = await decide(seat, {"type": "choice", "ctx": "deep_state", "value": value, "title": "Deep State: scegli il tipo di Asset (ottieni %d)" % value,
				"options": [{"id": "C", "label": "%d Consenso" % value}, {"id": "P", "label": "%d Politica" % value}, {"id": "E", "label": "%d Economia" % value}]})
			_add_asset(p, c3, value)
			log_msg("  %s prende %d %s." % [pname(seat), value, ASSET_NAMES[c3]])
			for q in players:
				if q["seat"] != seat:
					_add_asset(q, c3, 1)
			log_msg("  Ogni altra fazione prende 1 %s." % ASSET_NAMES[c3])
		"algocrazia":
			if flip_coin() == "head":
				var c4 = await decide(seat, {"type": "choice", "ctx": "algo_head", "value": value, "title": "Algocrazia (Testa)",
					"options": [{"id": "P", "label": "%d Politica" % value}, {"id": "E", "label": "%d Economia" % value}]})
				_add_asset(p, c4, value)
				log_msg("  %s prende %d %s." % [pname(seat), value, ASSET_NAMES[c4]])
			else:
				var c5 = await decide(seat, {"type": "choice", "ctx": "algo_arch", "value": value, "title": "Algocrazia (Arco)",
					"options": [{"id": "C", "label": "%d Consenso" % value}, {"id": "M", "label": "Avanza di %d nel Militare" % value}]})
				if c5 == "C":
					_add_asset(p, "C", value)
					log_msg("  %s prende %d Consenso." % [pname(seat), value])
				else:
					move_mil(seat, value)
		"total_cmp":
			var tot := total_on(group)
			if _cmp(tot, fxd["op"], fxd["n"]):
				log_msg("  Somma totale %d %s %d: ogni fazione presente ottiene la ricompensa." % [tot, fxd["op"], fxd["n"]])
				for s in seats_on(group):
					await apply_items(s, fxd["reward"], 0, true)
		"disarm":
			var opts3 := [{"id": "0", "label": "Non indietreggiare"}]
			if p["mil"] >= 4:
				opts3.append({"id": "4", "label": "Indietreggia di 4 → +1 Status"})
			if p["mil"] >= 8:
				opts3.append({"id": "8", "label": "Indietreggia di 8 → +2 Status"})
			var c6 = await decide(seat, {"type": "choice", "ctx": "disarm", "title": "Politica del disarmo", "options": opts3})
			if c6 == "4":
				move_mil(seat, -4)
				change_status(seat, 1)
			elif c6 == "8":
				move_mil(seat, -8)
				change_status(seat, 2)
		"rendita_from_cost":
			for c in d.get("c", []):
				var it := CardsDB.parse_item(c)
				if it["t"] in ASSETS:
					take_rendita(seat, it["t"])


func _cmp(a: int, op: String, b: int) -> bool:
	if op == ">":
		return a > b
	return a < b


func phase_3() -> void:
	_set_phase(3)
	for k in spaces.keys():
		if not spaces[k]["up"]:
			spaces[k]["up"] = true
			players[spaces[k]["seat"]]["seen"].append(spaces[k]["value"])
	fx.emit("reveal", {})
	log_msg("Tutti i Funzionari vengono rivelati.")
	changed.emit()
	# Effetti di risoluzione: prima il Giornale (da sinistra), poi le carte
	var g1 := seats_on("G1")
	if g1.size() > 0:
		log_msg("Giornale della Finanza: si ripaga il debito.")
		for s in turn_order():
			if not g1.has(s):
				continue
			var cnt := 0
			for k in group_keys("G1"):
				if spaces.has(k) and spaces[k]["seat"] == s:
					cnt += 1
			await lose_jolly(s, cnt, true, "%s: scarta %d Asset (o perdi Status) per i Funzionari sul Giornale" % [pname(s), cnt])
	for slot in range(5):
		var cid: String = monitor[slot]
		if cid == "" or seats_on("M%d" % slot).is_empty():
			continue
		var fxd: Dictionary = CardsDB.CARDS[cid]["fx"]
		if fxd.get("w", "") == "res":
			log_msg("Effetto di «%s»:" % CardsDB.CARDS[cid]["t"])
			await run_res_effect(slot, fxd)
			changed.emit()
	# Maggioranze
	var summary := []
	var to_clear := []
	for slot in range(5):
		var cid: String = monitor[slot]
		if cid == "":
			continue
		var group := "M%d" % slot
		var present := seats_on(group)
		to_clear.append(slot)
		if present.is_empty():
			log_msg("«%s»: nessun Funzionario, la carta torna nella scatola." % CardsDB.CARDS[cid]["t"])
			discard_box.append(cid)
			summary.append("«%s»: nessuno, scartata." % CardsDB.CARDS[cid]["t"])
			continue
		var best := -1
		var tied := []
		for s in present:
			var v := sum_on(group, s)
			if v > best:
				best = v
				tied = [s]
			elif v == best:
				tied.append(s)
		log_msg("«%s»: maggioranza con %d." % [CardsDB.CARDS[cid]["t"], best])
		var win := tiebreak(tied)
		var rw: String = CardsDB.CARDS[cid]["rw"]
		if rw == "S":
			change_status(win, 1)
		elif rw != "":
			take_rendita(win, rw)
		players[win]["cards"].append(cid)
		log_msg("  %s prende la carta." % pname(win))
		summary.append("«%s» → %s (%d%s)" % [CardsDB.CARDS[cid]["t"], pname(win), best, ", spareggio" if tied.size() > 1 else ""])
		fx.emit("card_won", {"slot": slot, "seat": win})
		changed.emit()
	await pause_point("\n".join(summary))
	for slot in to_clear:
		monitor[slot] = ""
	# Ritiro dei Funzionari
	spaces.clear()
	for p in players:
		_reshuffle_officers(p)
	changed.emit()


func run_res_effect(slot: int, fxd: Dictionary) -> void:
	var group := "M%d" % slot
	var present := seats_on(group)
	var keys := card_keys(slot)
	match fxd["k"]:
		"same_faction":
			if keys.size() == 2 and spaces.has(keys[0]) and spaces.has(keys[1]) and spaces[keys[0]]["seat"] == spaces[keys[1]]["seat"]:
				await apply_items(spaces[keys[0]]["seat"], fxd["reward"], 0, true)
			else:
				log_msg("  Condizione non soddisfatta.")
		"same_value":
			if keys.size() == 2 and spaces.has(keys[0]) and spaces.has(keys[1]) and spaces[keys[0]]["value"] == spaces[keys[1]]["value"]:
				for s in present:
					await apply_items(s, fxd["reward"], 0, true)
			else:
				log_msg("  Condizione non soddisfatta.")
		"full":
			var full := true
			for k in keys:
				if not spaces.has(k):
					full = false
			if full:
				for s in present:
					await apply_items(s, fxd["reward"], 0, true)
			else:
				log_msg("  Condizione non soddisfatta.")
		"total_cmp":
			var tot := total_on(group)
			if _cmp(tot, fxd["op"], fxd["n"]):
				log_msg("  Somma totale %d: condizione soddisfatta." % tot)
				for s in present:
					await apply_items(s, fxd["reward"], 0, true)
			else:
				log_msg("  Somma totale %d: condizione non soddisfatta." % tot)
		"own_gt":
			for s in present:
				if sum_on(group, s) > fxd["n"]:
					await apply_items(s, fxd["reward"], 0, true)
		"mil_leader":
			var best := 0
			for p in players:
				if p["mil"] > players[best]["mil"]:
					best = p["seat"]
			log_msg("  %s è la fazione più avanti nel Militare." % pname(best))
			await apply_items(best, fxd["reward"], 0, true)
		"coin_all":
			var side := flip_coin()
			for s in present:
				change_status(s, 1 if side == "head" else -1)
		"punish":
			if fxd.get("coin", false) and flip_coin() != "head":
				return
			var losers := []
			for p in players:
				if not present.has(p["seat"]):
					losers.append(p["seat"])
			if losers.is_empty():
				var low := 999
				for s in present:
					low = mini(low, sum_on(group, s))
				for s in present:
					if sum_on(group, s) == low:
						losers.append(s)
			for s in losers:
				var loss: String = fxd["loss"]
				if loss == "S":
					change_status(s, -1)
				else:
					var it := CardsDB.parse_item(loss)
					await pay_or_lose_status(s, it["t"], it["n"])
		"vs":
			var sides := [0, 0]
			var who := [[], []]
			var spdefs: Array = CardsDB.CARDS[monitor[slot]]["sp"]
			for i in range(keys.size()):
				if spaces.has(keys[i]):
					var sd: int = spdefs[i].get("s", 0)
					sides[sd] += spaces[keys[i]]["value"]
					if not who[sd].has(spaces[keys[i]]["seat"]):
						who[sd].append(spaces[keys[i]]["seat"])
			var coin := flip_coin()
			var got := 0 if coin == "head" else 1
			sides[got] += 3
			log_msg("  Schieramenti: Testa %d VS Arco %d." % [sides[0], sides[1]])
			var winside := got
			if sides[0] > sides[1]:
				winside = 0
			elif sides[1] > sides[0]:
				winside = 1
			for s in who[winside]:
				change_status(s, 1)


func phase_4() -> void:
	_set_phase(4)
	for s in turn_order():
		await collect_income(s)
	changed.emit()


func phase_5() -> void:
	_set_phase(5)
	for s in turn_order():
		var p: Dictionary = players[s]
		var mx := mini(2, mini(p["assets"]["E"], mini(p["assets"]["P"], p["assets"]["C"])))
		if mx <= 0:
			continue
		current_seat = s
		var opts := [{"id": 0, "label": "Non acquistare"}]
		opts.append({"id": 1, "label": "Scarta 1 Economia + 1 Politica + 1 Consenso → +1 Status"})
		if mx >= 2:
			opts.append({"id": 2, "label": "Scarta 2 di ogni tipo → +2 Status"})
		var c = await decide(s, {"type": "choice", "ctx": "buy_status", "title": "%s: aumentare lo Status" % pname(s), "options": opts})
		c = int(c)
		if c > 0:
			for t in ASSETS:
				_remove_asset(p, t, c)
			log_msg("%s scarta %d Asset di ogni tipo." % [pname(s), c])
			change_status(s, c)
	current_seat = -1
	changed.emit()


func phase_6() -> void:
	_set_phase(6)
	var low := 999
	var cand := []
	for p in players:
		if p["status"] < low:
			low = p["status"]
			cand = [p["seat"]]
		elif p["status"] == low:
			cand.append(p["seat"])
	var best: int = cand[0]
	for s in cand:
		if players[s]["mil"] < players[best]["mil"]:
			best = s
	priority = best
	log_msg("La Priorità passa a %s." % pname(best))
	fx.emit("priority", {"seat": best})
	changed.emit()


func continent_counts(p: Dictionary) -> Dictionary:
	var c := {"AM": 0, "EU": 0, "AF": 0, "AS": 0}
	for cid in p["cards"]:
		for k in CardsDB.CARDS[cid]["cont"]:
			c[k] += 1
	return c


func final_scoring() -> void:
	phase = 7
	log_msg("=== Fine della partita: punteggio finale ===")
	phase_changed.emit(round_n, 7)
	var breakdown := {}
	for p in players:
		breakdown[p["seat"]] = {"base": p["status"], "assets": 0, "asset_total": asset_total(p), "cont": 0,
			"cont_won": [], "cc": continent_counts(p), "sets": 0, "mil_end": p["mil"]}
	# 1. più Asset
	var best := -1
	var tied := []
	for p in players:
		var t := asset_total(p)
		if t > best:
			best = t
			tied = [p["seat"]]
		elif t == best:
			tied.append(p["seat"])
	if best > 0:
		log_msg("Più Asset dietro lo schermo (%d):" % best)
		var w := tiebreak(tied)
		change_status(w, 1)
		breakdown[w]["assets"] = 1
		breakdown[w]["asset_tie"] = tied.size() > 1
	# 2a. maggioranze per continente
	for cont in CONTINENTS:
		var b2 := 0
		var t2 := []
		for p in players:
			var v: int = continent_counts(p)[cont]
			if v > b2:
				b2 = v
				t2 = [p["seat"]]
			elif v == b2 and v > 0:
				t2.append(p["seat"])
		if b2 > 0:
			log_msg("Maggioranza %s (%d simboli):" % [CONT_NAMES[cont], b2])
			var w2 := tiebreak(t2)
			change_status(w2, 1)
			breakdown[w2]["cont"] += 1
			breakdown[w2]["cont_won"].append(cont)
	# 2b. set completi
	for p in players:
		var cc := continent_counts(p)
		var sets: int = mini(mini(cc["AM"], cc["EU"]), mini(cc["AF"], cc["AS"]))
		if sets > 0:
			log_msg("%s ha %d set completi di Continenti: +%d Status." % [p["name"], sets, sets])
			change_status(p["seat"], sets)
			breakdown[p["seat"]]["sets"] = sets
	results.clear()
	for p in players:
		results.append({"seat": p["seat"], "fid": p["fid"], "name": p["name"], "status": p["status"], "mil": p["mil"],
			"cards": p["cards"].size(), "card_ids": p["cards"].duplicate(), "assets": asset_total(p), "breakdown": breakdown[p["seat"]], "ai": p["ai"]})
	results.sort_custom(func(a, b): return a["status"] > b["status"] or (a["status"] == b["status"] and a["mil"] > b["mil"]))
	log_msg("Vince %s con %d punti Status!" % [results[0]["name"], results[0]["status"]])
	game_over = true
	changed.emit()
	game_ended.emit(results)
