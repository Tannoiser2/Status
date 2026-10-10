extends SceneTree
func _initialize() -> void:
	var m = load("res://scenes/Main.tscn").instantiate()
	root.add_child(m)
	_go.call_deferred(m)
func _go(m) -> void:
	for i in range(20): await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/menu.png")
	m.current.seat_mode = [1, 0, 2, 1]
	m.current._refresh_tiles()
	for i in range(5): await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/menu2.png")
	m.start_tutorial()
	for i in range(20): await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/tut0.png")
	quit()
