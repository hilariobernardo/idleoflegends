extends SceneTree
## Integration check using the actual buttons and an isolated save.
const Scene = preload("res://scenes/main.tscn")
const Progression = preload("res://scripts/progression.gd")
var failures: int = 0
var capture: bool = false
var fixture: String = "res://tests/tmp_flow.json"

func _initialize() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	call_deferred("_run")

func _run() -> void:
	_clean()
	var app = Scene.instantiate()
	app.test_save_path = fixture
	app.progress.time_override = 1_700_000_000
	root.add_child(app)
	await process_frame
	app.set_process(false)
	_check(app.current_page == "MODOS", "Opening screen must present the four modes.")
	_check(app.progress.xp == 0, "A new save starts with zero XP.")
	await _capture("01-modos")
	app.nav_buttons.PARTIDA.pressed.emit()
	_check(app.current_page == "MODOS", "Choose a mode before entering a match.")
	app.mode_buttons.normal.pressed.emit()
	app.start_button.pressed.emit()
	_check(app.active and app.start_button.disabled, "Play must start one match and disable duplicate starts.")
	app.pause_button.pressed.emit()
	app._process(0.2)
	_check(app.simulation.elapsed == 0, "Pause must freeze the simulation.")
	app.pause_button.pressed.emit()
	for frame: int in range(300):
		app._process(0.1)
	await _capture("02-partida")
	for frame: int in range(700):
		app._process(0.1)
	_check(app.simulation.finished and not app.active, "The match must complete through the scene.")
	_check(app.progress.matches == 1 and app.progress.xp >= 70, "A completed match grants XP once.")
	for frame: int in range(30):
		app._process(0.1)
	_check(app.progress.matches == 1, "Idle frames must not award a second result.")
	await _capture("03-resultado")
	app.nav_buttons.MELHORIAS.pressed.emit()
	await _capture("04-melhorias")
	var before: int = app.progress.xp
	app.skill_buttons.farm.pressed.emit()
	_check(app.progress.upgrades.farm == 1 and app.progress.xp == before - 60, "The upgrade button spends XP and raises the skill.")
	var loaded = Progression.new()
	loaded.save_path = fixture
	loaded.time_override = app.progress.time_override
	loaded.load_save()
	_check(loaded.xp == app.progress.xp and loaded.upgrades.farm == 1 and loaded.matches == 1, "The complete gameplay loop must survive reloading.")
	app.auto_button.button_pressed = true
	app._process(3.1)
	_check(app.active, "Auto repeat must start the next match.")
	app.auto_button.button_pressed = false
	for frame: int in range(950):
		app._process(0.1)
	app._process(5.0)
	_check(not app.active and app.progress.matches == 2, "Disabling repeat must stop after the current match.")
	# Exercise the new UI with an isolated advanced account, never the player's save.
	app.progress.xp = 20000
	app.progress.lifetime_xp = 20000
	app._refresh_progress()
	app.nav_buttons.ESTUDOS.pressed.emit()
	var tutorial_key: String = Progression.TRAINING_ORDER[1]
	app.training_buttons[tutorial_key].pressed.emit()
	_check(app.progress.training_rate() == 3, "Buying tutorials produces a combined 3 XP per second.")
	_check(app.progress.xp == 19700, "Training purchase spends its displayed XP price.")
	_check(not app.training_buttons[tutorial_key].disabled, "Owned studies remain upgradable.")
	app.training_buttons[tutorial_key].pressed.emit()
	_check(app.progress.training_levels[tutorial_key] == 2 and app.progress.training_rate() == 6, "A second upgrade raises the level and production.")
	_check(app.progress.xp == 18980, "Second tutorial level costs 720 XP.")
	app.progress.time_override += 1
	app.speed_button.pressed.emit()
	_check(app.speed_button.disabled and app.speed_button.text == "1×", "Only baseline movement speed is available.")
	app._process(1.0)
	_check(app.progress.xp == 18986, "The wallet credits one real second, unaffected by match speed.")
	_check(app.income_label.text.contains("6 XP/s") and app.xp_label.text == "18,9K XP", "Wallet displays compact balance and per-second production.")
	await _capture("05-estudos")
	app.nav_buttons.MODOS.pressed.emit()
	_check(app.mode_buttons.ranked.disabled, "Money alone cannot unlock Ranked before Barro IV.")
	app.progress.ladders.normal = 400
	app._refresh_progress()
	_check(not app.mode_buttons.ranked.disabled, "Barro IV and enough XP enable the Ranked purchase.")
	app.mode_buttons.ranked.pressed.emit()
	_check(app.progress.ranked_unlocked and app.progress.selected_mode == "ranked", "Ranked unlock button purchases and selects the mode.")
	_check(app.progress.xp == 8986, "Ranked unlock spends 10000 XP once.")
	_check(app.progress.rank_name() == "Ferro IV", "Ranked starts its independent ladder at Ferro IV.")
	await _capture("06-ranked")
	app.start_button.pressed.emit()
	app._choose_mode("normal")
	_check(app.progress.selected_mode == "ranked" and app.match_mode == "ranked", "A live match cannot switch modes.")
	for frame: int in range(950):
		app._process(0.1)
	_check(app.progress.matches == 3, "Ranked match awards a result.")
	_check(app.progress.ladders.normal == 400, "Ranked results leave Normal ladder unchanged.")
	var ranked_balance: int = app.progress.xp
	app._choose_mode("ranked")
	_check(app.progress.xp == ranked_balance, "Re-entering Ranked never charges a second unlock.")
	# A three-hour absence pays only two hours at the same 6 XP/s rate.
	var return_time: int = app.progress.time_override
	app.progress.training_last_at -= 3 * 3600
	_check(app.progress.save_game(), "Offline return fixture saves.")
	app.queue_free()
	await process_frame
	var returned = Scene.instantiate()
	returned.test_save_path = fixture
	returned.progress.time_override = return_time
	root.add_child(returned)
	await process_frame
	returned.set_process(false)
	_check(returned.progress.xp == ranked_balance + 43200, "Returning credits exactly two hours at 6 XP/s.")
	_check(returned.training_notice.visible and returned.training_notice.text.contains("XP"), "The returning player sees the training reward.")
	returned._process(1.0)
	_check(returned.progress.xp == ranked_balance + 43200, "The offline reward cannot be credited again by a UI tick.")
	await _capture("07-retorno")
	returned.queue_free()
	await process_frame
	_clean()
	print("PASS flow: play, rewards, upgrades, auto repeat, study levels, XP/s wallet, Ranked, two-hour offline cap." if failures == 0 else "FAIL flow: %d failures" % failures)
	quit(0 if failures == 0 else 1)

func _capture(filename: String) -> void:
	if not capture:
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var output: String = ProjectSettings.globalize_path("res://../artifacts/" + filename + ".png")
	var error: Error = root.get_texture().get_image().save_png(output)
	_check(error == OK, "Screenshot must save: " + filename)

func _clean() -> void:
	for suffix: String in ["", ".tmp"]:
		if FileAccess.file_exists(fixture + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture + suffix))

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

