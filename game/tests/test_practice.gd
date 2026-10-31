extends SceneTree
const Progression = preload("res://scripts/progression.gd")
const Numbers = preload("res://scripts/number_format.gd")
const Scene = preload("res://scenes/main.tscn")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var cases: Dictionary = {0:"0", 999:"999", 1000:"1K", 1599:"1,5K", 999999:"999,9K", 1000000:"1M", 1234567:"1,2M", 1000000000:"1B", 9000000000000:"9T", -1500:"-1,5K"}
	for value: int in cases:
		_check(Numbers.compact(value) == cases[value], "Compact boundary %d" % value)
	var p = Progression.new()
	p.save_path = "res://tests/tmp_practice_guard.json"
	var file = FileAccess.open(p.save_path, FileAccess.WRITE)
	file.store_string("existing save must remain untouched")
	file.close()
	p.practice_mode = true
	p.load_save()
	_check(p.xp == p.MAX_COUNTER and p.matches == 0 and p.last_error.is_empty(), "Practice ignores existing disk data")
	for key: String in p.SKILL_ORDER:
		for i: int in range(20): _check(p.buy_upgrade(key), "Free skill purchase")
	for key: String in p.TRAINING_ORDER:
		while p.training_levels[key] < 20: _check(p.buy_training(key), "Free study purchase")
	_check(p.xp == p.MAX_COUNTER, "Purchases never deplete XP")
	_check(not p.can_unlock_ranked(), "Fresh Ranked still requires rank")
	for i: int in range(16): p.record_match(true)
	_check(p.unlock_ranked(), "Ranked unlock uses unlimited XP after rank requirement")
	_check(p.settle_training(p.training_last_at + 7200) == 0, "No offline earnings in practice")
	_check(FileAccess.get_file_as_string(p.save_path) == "existing save must remain untouched", "Practice never writes save")
	p.load_save()
	_check(p.matches == 0 and p.upgrades.farm == 0 and not p.ranked_unlocked and p.ladders.normal == 0, "Reset clears progress")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p.save_path))
	var app = Scene.instantiate()
	root.add_child(app)
	await process_frame
	app.set_process(false)
	_check(app.progress.practice_mode and app.xp_label.text == "∞ XP", "Default application is practice")
	app._choose_mode("normal")
	app._start_match()
	app._buy_upgrade("farm")
	app._reset_test_session()
	_check(not app.active and not app.auto_play and not app.mode_chosen and app.current_page == "MODOS", "UI reset cancels match and returns to modes")
	_check(app.progress.upgrades.farm == 0 and app.xp_label.text == "∞ XP", "UI reset clears upgrades, retains infinite XP")
	if OS.get_cmdline_user_args().has("--capture"):
		for i: int in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../artifacts/practice-v07.png")
		app._choose_mode("normal")
		app._start_match()
		app.simulation.advance(8.0)
		app._refresh_match()
		for i: int in range(5): await process_frame
		app.scroll.scroll_vertical = 450
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../artifacts/jungle-v07.png")
	app.queue_free()
	await process_frame
	print("PASS practice: no save reads/writes, unlimited purchases, reset, compact values" if failures == 0 else "FAIL practice: %d" % failures)
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
