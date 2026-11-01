extends Control
## Small vector emblems stay crisp at every card size, without external assets.
var accent: Color = Color.WHITE
var skill: String = "farm"
var rarity: int = 0

func _ready() -> void:
	custom_minimum_size.y = 76
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center, 34, Color(accent, 0.08))
	var diamond: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -32), center + Vector2(32, 0),
		center + Vector2(0, 32), center + Vector2(-32, 0), center + Vector2(0, -32),
	])
	draw_polyline(diamond, Color(accent, 0.45), 1.5, true)
	for index: int in range(rarity + 1):
		draw_circle(center + Vector2((index - rarity * 0.5) * 9, 35), 2, accent)
	match skill:
		"farm":
			draw_arc(center, 15, 0, TAU, 40, accent, 2.5, true)
			draw_line(center + Vector2(0, -9), center + Vector2(0, 9), accent, 3, true)
			draw_line(center + Vector2(-6, -5), center + Vector2(6, -5), accent, 2, true)
			draw_line(center + Vector2(-6, 5), center + Vector2(6, 5), accent, 2, true)
		"trades":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -22), center + Vector2(6, -4), center + Vector2(0, 8), center + Vector2(-6, -4)]), accent)
			draw_line(center + Vector2(-10, 9), center + Vector2(10, 9), accent, 3, true)
			draw_line(center + Vector2(0, 8), center + Vector2(0, 21), accent, 4, true)
		"vision":
			draw_polyline(PackedVector2Array([center + Vector2(-22, 0), center + Vector2(0, -13), center + Vector2(22, 0), center + Vector2(0, 13), center + Vector2(-22, 0)]), accent, 2.5, true)
			draw_circle(center, 6, accent)
		"builds":
			draw_polyline(PackedVector2Array([center + Vector2(-14, -16), center + Vector2(14, -16), center + Vector2(12, 6), center + Vector2(0, 20), center + Vector2(-12, 6), center + Vector2(-14, -16)]), accent, 2.5, true)
			draw_line(center + Vector2(0, -9), center + Vector2(0, 10), accent, 2, true)
		"macro":
			draw_polyline(PackedVector2Array([center + Vector2(-17, 15), center + Vector2(-17, -10), center + Vector2(5, -10), center + Vector2(5, 12), center + Vector2(19, 12)]), accent, 3, true)
			draw_circle(center + Vector2(-17, 15), 4, accent)
			draw_line(center + Vector2(19, 12), center + Vector2(13, 5), accent, 3, true)
			draw_line(center + Vector2(19, 12), center + Vector2(13, 19), accent, 3, true)
