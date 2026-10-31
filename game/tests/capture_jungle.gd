extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	app.test_save_path = "res://tests/tmp_jungle_capture.json"
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app._choose_mode("normal")
	app._start_match()
	app.simulation.start({}, 7182)
	for moment: int in [8, 24]:
		app.simulation.advance(float(moment) - app.simulation.elapsed)
		app._refresh_match()
		for i: int in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../artifacts/jungle-%ds.png" % moment)
	app.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tests/tmp_jungle_capture.json"))
	quit()
