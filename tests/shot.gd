extends SceneTree
## Cattura screenshot automatici dell'interfaccia (richiede display, es. xvfb-run).

var main
var out_dir := "user://shots"
var n := 0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots")
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	n += 1
	img.save_png(OS.get_user_data_dir() + "/shots/%02d_%s.png" % [n, name])
	print("shot ", name)


func wait(f := 10) -> void:
	for i in range(f):
		await process_frame


func _run() -> void:
	var mode: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "game"
	await wait(5)
	if mode == "slides":
		main.start_tutorial()
		for i in range(12):
			await wait(6)
			await shot("slide%d" % i)
			main.current._go(main.current.idx + 1)
		quit()
		return
	await shot("menu")
	main.start_game({"seats": [{"fid": 0, "ai": true, "name": "Mano Invisibile"}, {"fid": 1, "ai": false, "name": "Ragione di Stato"}, {"fid": 2, "ai": true, "name": "Pugno del Popolo"}, {"fid": 3, "ai": true, "name": "Nuova Milizia"}],
		"first_game": false, "promo": true, "ai_level": 1, "ai_delay": 0.0, "tutorial": true, "seed": 7})
	var gv = main.current
	var shots_taken := {}
	var steps := 0
	while steps < 4000:
		steps += 1
		await wait(2)
		if gv.engine.game_over:
			await wait(10)
			await shot("end")
			break
		var p: Dictionary = gv.pending
		if gv.overlay.get_child_count() > 0 and p.is_empty():
			# pausa di risoluzione
			var key := "pause_r%d" % gv.engine.round_n
			if not shots_taken.has(key):
				shots_taken[key] = true
				await wait(10)
				await shot(key)
			gv._clear_overlay()
			gv._clear_frames()
			gv.engine.provide_decision(null)
			continue
		if p.is_empty():
			continue
		var key2 := "%s_%s_r%d" % [p["type"], p.get("ctx", ""), gv.engine.round_n]
		if not shots_taken.has(key2) and shots_taken.size() < 14:
			shots_taken[key2] = true
			await wait(30)
			await shot(key2)
		var res = gv.engine.ai.decide(gv.engine, p["seat"], p)
		gv._finish(res)
	quit()
