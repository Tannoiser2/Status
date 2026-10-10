extends SceneTree
## Confronto livelli IA: un seat a livello A contro gli altri a livello B.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var la := int(args[0]); var lb := int(args[1]); var n := int(args[2])
	var wins := 0
	var games := 0
	var avg := [0.0, 0.0]
	for g in range(n):
		var np := 2 + (g % 3)
		var seats := []
		var hero := g % np
		for i in range(np):
			seats.append({"fid": i, "ai": true, "level": la if i == hero else lb})
		var e := GameEngine.new()
		e.headless = true
		e.setup({"seats": seats, "seed": 5000 + g})
		e.run()
		games += 1
		if e.results[0]["seat"] == hero:
			wins += 1
		for r in e.results:
			if r["seat"] == hero: avg[0] += r["status"]
			else: avg[1] += r["status"] / float(np - 1)
		e.free()
	print("hero lvl %d vs lvl %d: vittorie %d/%d (atteso ~%.0f%%), status medio eroe %.2f vs altri %.2f" % [la, lb, wins, games, 100.0 * (1.0/2 + 1.0/3 + 1.0/4) / 3, avg[0] / games, avg[1] / games])
	quit()
