extends SceneTree
const Scene = preload("res://scenes/main.tscn")
var failures: int = 0
var app

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	app = Scene.instantiate()
	app.test_save_path = "res://tests/tmp_mobile.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(app.test_save_path))
	root.add_child(app)
	await _frames()
	app.set_process(false)
	_check(app.current_page == "MODOS" and not app.mode_chosen, "Opening requires mode choice")
	_check(not app.mode_buttons.normal.disabled and app.mode_buttons.ranked.disabled, "Only Normal unlocked on fresh save")
	app._start_match()
	_check(not app.active, "Cannot bypass mode choice")
	# Feed real GUI mouse events: touch emulation enables native drag scrolling.
	var start: Vector2 = app.mode_buttons.normal.get_global_rect().get_center()
	_mouse_button(start, true)
	await process_frame
	for step: int in range(1, 9):
		var event = InputEventMouseMotion.new()
		event.position = start - Vector2(0, step * 20)
		event.relative = Vector2(0, -20)
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(event, true)
		await process_frame
	_mouse_button(start - Vector2(0, 160), false)
	await _frames()
	_check(app.scroll.scroll_vertical > 50, "Dragging on a button scrolls content")
	_check(not app.mode_chosen, "Dragging must not click Normal")
	app.scroll.scroll_vertical = 0
	await _frames()
	start = app.mode_buttons.normal.get_global_rect().get_center()
	_mouse_button(start, true)
	_mouse_button(start, false)
	await _frames()
	_check(app.mode_chosen and app.current_page == "PARTIDA", "Tap selects Normal")
	for dimensions: Vector2i in [Vector2i(540,960), Vector2i(540,1200), Vector2i(540,1260), Vector2i(768,1024)]:
		root.size = dimensions
		await _frames()
		_check(app.size.is_equal_approx(root.get_visible_rect().size), "Root fills viewport %s" % dimensions)
		_check(app.scroll.size.is_equal_approx(app.size), "Scroll fills viewport %s" % dimensions)
		for page: String in ["MODOS", "PARTIDA", "MELHORIAS", "ESTUDOS"]:
			app._show_page(page)
			await _frames()
			_check(app.scroll.get_child(2).size.x <= app.scroll.size.x + 1 if app.scroll.get_child_count() > 2 else true, "Content fits width")
		if OS.get_cmdline_user_args().has("--capture"):
			app._show_page("MODOS")
			await _frames()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../artifacts/mobile-%dx%d.png" % [dimensions.x, dimensions.y])
	app.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tests/tmp_mobile.json"))
	print("PASS mobile UI: drag, tap, mode gate, viewport sizes" if failures == 0 else "FAIL mobile UI: %d" % failures)
	quit(0 if failures == 0 else 1)

func _mouse_button(pos: Vector2, pressed: bool) -> void:
	var event = InputEventMouseButton.new()
	event.position = pos
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	root.push_input(event, true)

func _frames() -> void:
	for i: int in range(5): await process_frame

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

