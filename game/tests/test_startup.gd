extends SceneTree

const Scene = preload("res://scenes/main.tscn")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var app = Scene.instantiate()
	root.add_child(app)
	await process_frame
	app.set_process(false)
	var arena: Variant = app.get("arena")
	_check(arena != null, "Arena initializes without an imported texture cache")
	if arena == null:
		app.queue_free()
		await process_frame
		quit(1)
		return
	var texture: Texture2D = arena.map_texture
	_check(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "Map texture contains an image")
	_check(app.current_page == "MODOS" and not app.mode_chosen, "Startup finishes on mode selection")
	app._choose_mode("normal")
	app._start_match()
	app.simulation.advance(1.0)
	app._refresh_match()
	_check(app.active and app.current_page == "PARTIDA" and app.simulation.elapsed > 0, "A match starts and advances after startup")
	app.queue_free()
	await process_frame
	print("PASS startup: map, interface and match" if failures == 0 else "FAIL startup: %d" % failures)
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
