extends SceneTree
const Map = preload("res://scripts/map_layout.gd")

class Overlay:
	extends Control
	const TEXTURE = preload("res://assets/arena.png")
	func _draw() -> void:
		draw_texture_rect(TEXTURE, Rect2(0, 0, 1000, 1000), false)
		for edge: Array in Map.data.edges:
			draw_line(Map.graph.get_point_position(int(edge[0])) * 1000, Map.graph.get_point_position(int(edge[1])) * 1000, Color(1, 0, 1, .7), 1)
		for lane: int in range(3):
			var points = Map.lane_points(lane)
			for i: int in range(points.size()): points[i] *= 1000
			draw_polyline(points, Color(0, 1, 1), 2)
		for team: int in range(2):
			for point: Vector2 in Map.camps(team):
				draw_circle(point * 1000, 5, Color.BLUE if team == 0 else Color.RED)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Map.prepare()
	root.size = Vector2i(1000,1000)
	root.content_scale_size = Vector2i(1000,1000)
	root.add_child(Overlay.new())
	for i: int in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../artifacts/navigation-v08.png")
	quit()

