extends SceneTree
## Simulazione headless: godot --headless -s res://tests/sim.gd -- [n_partite]

func _initialize() -> void:
	var n := 50
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	var wins := {0: 0, 1: 0, 2: 0, 3: 0}
	var scores := []
	var errors := 0
	for g in range(n):
		var e := GameEngine.new()
		e.headless = true
		var np := 2 + (g % 3)
		var fids := [0, 1, 2, 3]
		var seats := []
		for i in range(np):
			seats.append({"fid": fids[(i + g) % 4], "ai": true})
		e.setup({"seats": seats, "seed": 1000 + g, "first_game": g % 4 == 0, "ai_level": 1 + (g % 2)})
		e.run()
		if not e.game_over:
			errors += 1
			print("GAME %d NOT FINISHED" % g)
		else:
			wins[e.results[0]["fid"]] += 1
			for r in e.results:
				scores.append(r["status"])
			if g < 3:
				for line in e.log_lines:
					print(line)
		e.free()
	var tot := 0
	for s in scores:
		tot += s
	print("Partite: %d  errori: %d  vittorie per fazione: %s  status medio: %.2f  max: %d" % [n, errors, str(wins), float(tot) / max(1, scores.size()), scores.max() if scores.size() else 0])
	quit()
