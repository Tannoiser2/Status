extends SceneTree
func _initialize() -> void:
	var m = load("res://scenes/Main.tscn").instantiate()
	root.add_child(m)
	_go.call_deferred(m)
func _go(m) -> void:
	await process_frame
	m.start_game({"seats": [{"fid": 0, "ai": true}, {"fid": 1, "ai": false, "name": "Ragione di Stato"}, {"fid": 2, "ai": true}, {"fid": 3, "ai": true}], "ai_delay": 0.0, "seed": 11})
	var gv = m.current
	gv.engine.pause_enabled = false
	gv.engine.players[1]["ai"] = true   # decisioni automatiche per il test
	while not gv.engine.game_over:
		await process_frame
	for i in range(15): await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/end.png")
	quit()
