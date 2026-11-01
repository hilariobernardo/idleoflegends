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
		for page: String in ["MODOS", "PARTIDA", "EVOLUÇÃO", "CARTAS"]:
			app._show_page(page)
			await _frames()
			_check(app.pages[page].visible and app.current_page == page, "Correct page is visible: " + page)
			for child: Node in app.scroll.get_children():
				if child is MarginContainer:
					_check(child.size.x <= app.scroll.size.x + 1, "Content fits width: %s %s" % [page, dimensions])
			for button: Node in app.find_children("*", "Button", true, false):
				if button.is_visible_in_tree():
					var rect: Rect2 = button.get_global_rect()
					_check(rect.position.x >= 0 and rect.end.x <= app.size.x + 1, "Button stays inside viewport: " + button.text)
		if OS.get_cmdline_user_args().has("--capture"):
			app._show_page("MODOS")
			await _frames()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../artifacts/mobile-%dx%d.png" % [dimensions.x, dimensions.y])
	var groups: Array[GridContainer] = []
	for child: Node in app.pages["EVOLUÇÃO"].get_children():
		if child is GridContainer:
			groups.append(child)
	_check(groups.size() == 2, "Evolution has separate skill and study groups")
	if groups.size() == 2:
		_check(groups[0].columns == 2 and groups[0].get_child_count() == 5, "Five skills in two columns")
		_check(groups[1].columns == 2 and groups[1].get_child_count() == 4, "Four studies in two columns")
	app._show_page("EVOLUÇÃO")
	app.skill_buttons.farm.pressed.emit()
	_check(app.progress.upgrades.farm == 0, "Unaffordable skill purchase is rejected")
	app.progress.xp = 1000
	app.progress.lifetime_xp = 1000
	app._refresh_progress()
	app.skill_buttons.farm.pressed.emit()
	app.training_buttons.videos.pressed.emit()
	_check(app.progress.upgrades.farm == 1 and app.progress.training_levels.videos == 2, "Both upgrade groups remain functional")
	app._show_page("CARTAS")
	_check(app.card_open_button.disabled and app.card_buttons.size() == 15, "Empty wallet disables opening and catalog has 15 cards")
	app.progress.idle_points = 300
	app._refresh_progress()
	app.card_open_button.pressed.emit()
	await _frames()
	_check(app.progress.idle_points == 200 and app.progress.collection.size() == 1, "Open button purchases one card")
	_check(app.card_result.visible and app.card_result_label.text.contains("NOVA CARTA"), "Purchased card is revealed")
	var id: String = str(app.progress.collection.keys()[0])
	app.card_buttons[id].pressed.emit()
	_check(app.progress.equipped_cards.has(id) and app.card_buttons[id].text == "REMOVER", "Equip button updates collection and label")
	app._start_match()
	var equipped_skills: Dictionary = app.progress.combat_upgrades()
	_check(app.active and app.simulation._upgrades == equipped_skills, "Match starts with equipped bonuses")
	app.card_buttons[id].pressed.emit()
	_check(app.simulation._upgrades == equipped_skills and app.progress.equipped_cards.is_empty(), "Removing a card does not alter an ongoing match")
	app.progress.practice_mode = true
	app._reset_test_session()
	_check(not app.active and app.current_page == "MODOS" and not app.card_result.visible, "Reset cancels match, hides reveal and returns to modes")
	_check(app.progress.collection.is_empty() and app.progress.idle_points == 300 and app.ip_label.text == "300 IP", "Reset restores starter IP and clears collection")
	app.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tests/tmp_mobile.json"))
	print("PASS mobile UI: drag, tap, 4 viewport sizes, upgrade grids, cards, combat bonuses, reset" if failures == 0 else "FAIL mobile UI: %d" % failures)
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

