extends Control
## Approved map texture and simulation share normalized image coordinates.
const MAP_TEXTURE = preload("res://assets/arena.png")
const Map = preload("res://scripts/map_layout.gd")

var simulation: RefCounted
var running: bool = false
const BLUE: Color = Color("70c5ff")
const RED: Color = Color("ff818d")

func _ready() -> void:
	custom_minimum_size = Vector2(0, 354)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit_square)

func _fit_square() -> void:
	if size.x > 0:
		custom_minimum_size.y = size.x

func _process(_delta: float) -> void:
	queue_redraw()

func _point(p: Vector2) -> Vector2:
	var side: float = minf(size.x - 18, size.y - 12)
	return (size - Vector2.ONE * side) * 0.5 + p * side

func _draw() -> void:
	if simulation == null:
		return
	var side: float = minf(size.x - 18, size.y - 12)
	var bounds: Rect2 = Rect2(_point(Vector2.ZERO), Vector2.ONE * side)
	draw_texture_rect(MAP_TEXTURE, bounds, false)
	for team: int in range(2):
		var origin: Vector2 = Map.base(team)
		var color: Color = BLUE if team == 0 else RED
		var p: Vector2 = _point(origin)
		draw_circle(p, 24, Color(color, .10))
		draw_arc(p, 24, 0, TAU, 40, Color(color, .45), 1.5, true)
		var diamond: PackedVector2Array = PackedVector2Array([p+Vector2(0,-14),p+Vector2(12,0),p+Vector2(0,14),p+Vector2(-12,0)])
		draw_colored_polygon(diamond, color)
		_health(p + Vector2(0, 30), float(simulation.base_hp[team]) / 1000.0, color, 40)
	for tower: Dictionary in simulation.towers:
		var p: Vector2 = _point(tower.position)
		var color: Color = BLUE if int(tower.team) == 0 else RED
		if float(tower.hp) <= 0:
			draw_circle(p, 7, Color("384149"))
			draw_line(p-Vector2(4,4), p+Vector2(4,4), Color("71808a"), 2)
			continue
		draw_circle(p, 13, Color(color, .10))
		draw_rect(Rect2(p-Vector2(7,7),Vector2(14,14)), Color("132535"))
		draw_rect(Rect2(p-Vector2(7,7),Vector2(14,14)), color, false, 2)
		_health(p+Vector2(0,13),float(tower.hp)/float(tower.max_hp),color,22)
	for unit: Dictionary in simulation.units:
		if not bool(unit.alive):
			continue
		var p: Vector2 = _point(unit.position)
		var color: Color = BLUE if int(unit.team) == 0 else RED
		draw_circle(p + Vector2(0,1), 5.5, Color(0,0,0,.4))
		draw_circle(p, 4.5, color)
		draw_circle(p-Vector2(1,1), 1, Color(1,1,1,.6))
		_health(p+Vector2(0,-8),float(unit.hp)/float(unit.max_hp),color,19)

func _health(p: Vector2, amount: float, color: Color, width: float) -> void:
	draw_line(p-Vector2(width/2,0),p+Vector2(width/2,0),Color("07121c"),3)
	draw_line(p-Vector2(width/2,0),p+Vector2(width*(clampf(amount,0,1)-.5),0),color,3)

func _box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

