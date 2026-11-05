extends Control
## Five drawn stars keep levels readable without relying on font glyph support.
const Cards = preload("res://scripts/card_catalog.gd")
var level: int = 0:
	set(value):
		level = clampi(value, 0, Cards.MAX_CARD_LEVEL)
		tooltip_text = "Nível %d/%d" % [level, Cards.MAX_CARD_LEVEL]
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(110, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var spacing: float = minf(24.0, size.x / Cards.MAX_CARD_LEVEL)
	var radius: float = minf(10.0, minf(spacing * 0.43, size.y * 0.45))
	var left: float = (size.x - spacing * Cards.MAX_CARD_LEVEL) * 0.5
	for index: int in range(Cards.MAX_CARD_LEVEL):
		var center: Vector2 = Vector2(left + spacing * (index + 0.5), size.y * 0.5)
		var points: PackedVector2Array = PackedVector2Array()
		for vertex: int in range(10):
			var angle: float = -PI / 2.0 + vertex * PI / 5.0
			points.append(center + Vector2.from_angle(angle) * radius * (1.0 if vertex % 2 == 0 else 0.45))
		draw_colored_polygon(points, Color("f1c779") if index < level else Color("344b5d"))
