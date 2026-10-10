class_name StatusAI
extends RefCounted
## IA euristica per STATUS. Valuta ogni spazio legale con una stima in "punti Status".
## level: 0 = facile (molto rumore), 1 = normale, 2 = difficile (poco rumore).

var level := 1
var rng := RandomNumberGenerator.new()

const V_STATUS := 1.0
const V_CONT := 0.42


func _init() -> void:
	rng.randomize()


func noise() -> float:
	var amp: float = [0.9, 0.35, 0.08][clampi(level, 0, 2)]
	return rng.randf_range(-amp, amp)


# ---------------------------------------------------------------- valutazione asset

## Potenziale degli asset: i set E+P+C valgono quasi uno Status.
static func phi(a: Dictionary) -> float:
	var m: int = mini(a["E"], mini(a["P"], a["C"]))
	var tot: int = a["E"] + a["P"] + a["C"]
	return 0.9 * m + 0.17 * (tot - 3 * m)


func delta_assets(e: GameEngine, seat: int, d: Dictionary) -> float:
	var a: Dictionary = e.players[seat]["assets"].duplicate()
	var before := phi(a)
	for t in d:
		a[t] = maxi(0, a[t] + d[t])
	return phi(a) - before


func best_jolly_type(a: Dictionary) -> String:
	var best := "E"
	for t in ["E", "P", "C"]:
		if a[t] < a[best]:
			best = t
	return best


func worst_loss_type(a: Dictionary) -> String:
	var best := ""
	for t in ["E", "P", "C"]:
		if a[t] <= 0:
			continue
		if best == "" or a[t] > a[best]:
			best = t
	return best


func jolly_value(e: GameEngine, seat: int, n: int) -> float:
	var a: Dictionary = e.players[seat]["assets"].duplicate()
	var before := phi(a)
	for i in range(n):
		a[best_jolly_type(a)] += 1
	return phi(a) - before


func mil_value(e: GameEngine) -> float:
	return 0.14 if e.round_n < 4 else 0.08


func rounds_left(e: GameEngine) -> int:
	return GameEngine.ROUNDS - e.round_n + 1


func items_value(e: GameEngine, seat: int, items: Array, value: int, gain: bool) -> float:
	var v := 0.0
	var d := {"E": 0, "P": 0, "C": 0}
	var sign := 1 if gain else -1
	for s in items:
		var it := CardsDB.parse_item(s)
		var amt: int = it["n"] * (value if it["x"] else 1)
		match it["t"]:
			"E", "P", "C":
				d[it["t"]] += sign * amt
			"J":
				v += sign * jolly_value(e, seat, amt)
			"M":
				v += sign * amt * mil_value(e)
			"S":
				v += sign * amt * V_STATUS
	v += delta_assets(e, seat, d)
	return v


func rendita_value(e: GameEngine, t: String) -> float:
	var r := rounds_left(e)
	match t:
		"S":
			return V_STATUS
		"J":
			return 0.38 * r
		"":
			return 0.0
	return 0.3 * r


# ---------------------------------------------------------------- stima maggioranze

func est_hidden(e: GameEngine, seat: int) -> float:
	var unseen := [1, 2, 3, 4]
	for v in e.players[seat]["seen"]:
		unseen.erase(v)
	if unseen.is_empty():
		return 2.5
	var s := 0.0
	for v in unseen:
		s += v
	return s / unseen.size()


func est_sum(e: GameEngine, me: int, group: String, seat: int) -> float:
	var t := 0.0
	for k in e.group_keys(group):
		if e.spaces.has(k) and e.spaces[k]["seat"] == seat:
			if e.spaces[k]["up"] or seat == me:
				t += e.spaces[k]["value"]
			else:
				t += est_hidden(e, seat)
	return t


func officers_left(e: GameEngine, except_seat: int) -> int:
	var n := 0
	for p in e.players:
		if p["seat"] == except_seat:
			continue
		n += p["stack"].size() + (1 if p["hand"] > 0 else 0)
	return n


func win_prob(e: GameEngine, seat: int, group: String, extra: int, key: String) -> float:
	var mine := est_sum(e, seat, group, seat) + extra
	var other := 0.0
	for s in e.seats_on(group):
		if s != seat:
			other = maxf(other, est_sum(e, seat, group, s))
	var open := 0
	for k in e.group_keys(group):
		if not e.spaces.has(k) and k != key:
			open += 1
	var threat := minf(float(open), officers_left(e, seat) / 2.0) * 1.1
	var diff := mine - other - threat
	return 1.0 / (1.0 + exp(-diff / 1.1))


func card_prize(e: GameEngine, seat: int, cid: String) -> float:
	var c: Dictionary = CardsDB.CARDS[cid]
	var v := rendita_value(e, c["rw"])
	var cc := e.continent_counts(e.players[seat])
	for k in c["cont"]:
		v += V_CONT + (0.15 if cc[k] == 0 else 0.0)
	return v


# ---------------------------------------------------------------- valutazione spazio

func eval_space(e: GameEngine, seat: int, key: String, value: int) -> float:
	var d := e.space_def(key)
	var p: Dictionary = e.players[seat]
	var sc := 0.0
	sc += items_value(e, seat, d.get("c", []), value, false)
	sc += items_value(e, seat, d.get("g", []), value, true)
	match d["group"]:
		"G1":
			sc -= 0.32  # debito da ripagare
		"G2":
			sc += maxf(jolly_value(e, seat, 1), mil_value(e))
			sc -= 0.12 # spreco di un funzionario: preferisci le carte
		"G3":
			var best := 0.0
			if p["assets"]["E"] >= 1 and p["assets"]["P"] >= 1 and p["assets"]["C"] >= 1:
				best = maxf(best, V_STATUS + delta_assets(e, seat, {"E": -1, "P": -1, "C": -1}))
			if p["mil"] >= 4:
				best = maxf(best, V_STATUS - 4 * mil_value(e) - 0.15)
			if e.asset_total(p) >= 4:
				var a: Dictionary = p["assets"].duplicate()
				var b0 := phi(a)
				for i in range(4):
					a[worst_loss_type(a)] -= 1
				best = maxf(best, V_STATUS + phi(a) - b0)
			sc += best
		"M":
			var cid: String = d["card"]
			var group := "M%d" % d["slot"]
			var pw := win_prob(e, seat, group, value, key)
			var already := e.sum_on(group, seat) > 0
			var pw_before := win_prob(e, seat, group, 0, "") if already else 0.0
			sc += (pw - pw_before) * card_prize(e, seat, cid)
			sc += eval_effect(e, seat, d, value, group, already)
			# preferisci mettere valori alti sulle carte, bassi sul giornale
			sc += 0.03 * value
	return sc


func eval_effect(e: GameEngine, seat: int, d: Dictionary, value: int, group: String, already: bool) -> float:
	var fxd: Dictionary = CardsDB.CARDS[d["card"]]["fx"]
	if fxd.is_empty():
		return 0.0
	var tot := 0.0
	for k in e.group_keys(group):
		if e.spaces.has(k):
			tot += e.spaces[k]["value"] if (e.spaces[k]["up"] or e.spaces[k]["seat"] == seat) else est_hidden(e, e.spaces[k]["seat"])
	tot += value
	var open := 0
	for k in e.group_keys(group):
		if not e.spaces.has(k):
			open += 1
	open -= 1
	var pres_bonus := 0.0 if already else 1.0
	match fxd["k"]:
		"coin_gain":
			return 0.5 * items_value(e, seat, fxd["items"], value, true)
		"coin_lose":
			return -0.5 * 0.35
		"gain":
			return items_value(e, seat, fxd["items"], value, true)
		"tribute":
			var n := 0
			for q in e.players:
				if q["seat"] != seat and e.asset_total(q) > 0:
					n += 1
			return jolly_value(e, seat, n)
		"income":
			var r: Dictionary = e.players[seat]["rendita"]
			return 0.32 * (r["E"] + r["P"] + r["C"]) + 0.38 * r["J"] + mil_value(e) * r["M"]
		"reveal":
			for k in e.group_keys(group):
				if e.spaces.has(k) and e.spaces[k]["seat"] != seat and not e.spaces[k]["up"]:
					return jolly_value(e, seat, int(round(est_hidden(e, e.spaces[k]["seat"]))))
			return 0.0
		"deep_state":
			return maxf(delta_assets(e, seat, {"E": value, "P": 0, "C": 0}), maxf(delta_assets(e, seat, {"E": 0, "P": value, "C": 0}), delta_assets(e, seat, {"E": 0, "P": 0, "C": value})))
		"algocrazia":
			return 0.5 * value * 0.3 + 0.5 * value * 0.25
		"disarm":
			var m: int = e.players[seat]["mil"]
			if m >= 4:
				return maxf(0.0, V_STATUS - 4 * mil_value(e))
			return 0.0
		"rendita_from_cost":
			return rendita_value(e, "E")
		"total_cmp":
			var rv := items_value(e, seat, fxd["reward"], 0, true)
			var exp_tot := tot + open * 2.5 * 0.5
			var pr := 0.0
			if fxd["op"] == ">":
				pr = 1.0 / (1.0 + exp(-(exp_tot - fxd["n"] - 0.5) / 1.2))
			else:
				pr = 1.0 / (1.0 + exp(-(fxd["n"] - exp_tot - 0.5) / 1.2))
			if fxd["w"] == "now":
				pr = 1.0 if tot > fxd["n"] else 0.0
			return pr * rv * pres_bonus
		"own_gt":
			var mine := est_sum(e, seat, group, seat) + value
			if mine > fxd["n"]:
				return V_STATUS * (1.0 if est_sum(e, seat, group, seat) <= fxd["n"] else 0.0)
			return 0.15
		"full":
			return (0.7 if open <= 0 else 0.35) * pres_bonus
		"same_faction":
			for k in e.group_keys(group):
				if e.spaces.has(k):
					return V_STATUS if e.spaces[k]["seat"] == seat else 0.0
			return 0.3
		"same_value":
			for k in e.group_keys(group):
				if e.spaces.has(k):
					return items_value(e, seat, fxd["reward"], 0, true) * (1.0 if e.spaces[k]["value"] == value else 0.0) * pres_bonus
			return 0.12
		"punish":
			var mult := 0.5 if fxd.get("coin", false) else 1.0
			return 0.55 * mult * pres_bonus
		"vs":
			return 0.4 * pres_bonus
		"coin_all":
			return 0.0
		"mil_leader":
			return 0.1
	return 0.0


# ---------------------------------------------------------------- decisioni

func decide(e: GameEngine, seat: int, req: Dictionary):
	match req["type"]:
		"place":
			return decide_place(e, seat, req)
		"alloc":
			return decide_alloc(e, seat, req)
		"choice":
			return decide_choice(e, seat, req)
	return null


func decide_place(e: GameEngine, seat: int, req: Dictionary) -> String:
	var best := ""
	var bs := -INF
	for k in req["options"]:
		var s := eval_space(e, seat, k, req["value"]) + noise()
		if s > bs:
			bs = s
			best = k
	return best


func decide_alloc(e: GameEngine, seat: int, req: Dictionary) -> Dictionary:
	var a: Dictionary = e.players[seat]["assets"].duplicate()
	var mx: Dictionary = req["max"].duplicate()
	var out := {"E": 0, "P": 0, "C": 0, "S": 0}
	for i in range(req["n"]):
		if req["mode"] == "gain":
			var best := ""
			for t in ["E", "P", "C"]:
				if out[t] >= mx.get(t, 0):
					continue
				if best == "" or a[t] < a[best]:
					best = t
			if best == "":
				break
			a[best] += 1
			out[best] += 1
		else:
			var best2 := ""
			var loss := INF
			for t in ["E", "P", "C"]:
				if out[t] >= mx.get(t, 0):
					continue
				var b := a.duplicate()
				b[t] -= 1
				var l := phi(a) - phi(b)
				if l < loss:
					loss = l
					best2 = t
			var s_ok: bool = mx.has("S") and out["S"] < mx["S"]
			if best2 == "" or (s_ok and loss > 0.95):
				if s_ok:
					out["S"] += 1
					continue
				break
			a[best2] -= 1
			out[best2] += 1
	return out


func decide_choice(e: GameEngine, seat: int, req: Dictionary):
	var opts: Array = req["options"]
	var p: Dictionary = e.players[seat]
	match req.get("ctx", ""):
		"buy_status":
			return opts[opts.size() - 1]["id"]
		"g2":
			return "J" if jolly_value(e, seat, 1) >= mil_value(e) else "M"
		"g3":
			var best = "none"
			var bv := 0.0
			for o in opts:
				var v := 0.0
				match o["id"]:
					"set":
						v = V_STATUS + delta_assets(e, seat, {"E": -1, "P": -1, "C": -1})
					"four":
						var a: Dictionary = p["assets"].duplicate()
						var b0 := phi(a)
						for i in range(4):
							a[worst_loss_type(a)] -= 1
						v = V_STATUS + phi(a) - b0
					"mil":
						v = V_STATUS - 4 * mil_value(e) - 0.15
				if v > bv:
					bv = v
					best = o["id"]
			return best
		"tribute":
			var t := worst_loss_type(p["assets"])
			for o in opts:
				if o["id"] == t:
					return t
			return opts[0]["id"]
		"deep_state", "algo_head":
			var best2 = opts[0]["id"]
			var bv2 := -INF
			for o in opts:
				var d := {"E": 0, "P": 0, "C": 0}
				d[o["id"]] = req["value"]
				var v2 := delta_assets(e, seat, d)
				if v2 > bv2:
					bv2 = v2
					best2 = o["id"]
			return best2
		"algo_arch":
			var vc := delta_assets(e, seat, {"E": 0, "P": 0, "C": req["value"]})
			return "C" if vc >= req["value"] * mil_value(e) else "M"
		"disarm":
			var best3 = "0"
			for o in opts:
				if o["id"] == "4" and V_STATUS > 4 * mil_value(e) + 0.2:
					best3 = "4"
				if o["id"] == "8" and 2 * V_STATUS > 8 * mil_value(e) + 0.5 and e.round_n >= 3:
					best3 = "8"
			return best3
		"pay_or_status":
			var d2 := {"E": 0, "P": 0, "C": 0}
			d2[req["t"]] = -req["n"]
			return "pay" if -delta_assets(e, seat, d2) < V_STATUS else "status"
		"reveal":
			return opts[rng.randi_range(0, opts.size() - 1)]["id"]
	return opts[0]["id"]
