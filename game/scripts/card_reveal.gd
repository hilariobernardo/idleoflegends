extends Control
## Presentation only: the purchase is committed before this overlay opens.
signal finished

const Cards = preload("res://scripts/card_catalog.gd")
const CardArt = preload("res://scripts/card_art.gd")
const CardStars = preload("res://scripts/card_stars.gd")
const CANVAS_SIZE: Vector2 = Vector2(340, 680)
const GOLD: Color = Color("f1c779")
const INK: Color = Color("edf3ef")
const MUTED: Color = Color("93a9b8")

var _canvas: Control
var _card: Control
var _back: PanelContainer
var _front: PanelContainer
var _title: Label
var _subtitle: Label
var _detail: Label
var _action: Button
var _stars: Control
var _tween: Tween
var _accent: Color = GOLD
var _result: Dictionary = {}
var _revealed: bool = false
var _burst: float = 0.0
var _elapsed: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas = Control.new()
	_canvas.size = CANVAS_SIZE
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_title = _text("INVOCANDO RELÍQUIA", 24, GOLD)
	_place(_title, Vector2.ZERO, Vector2(340, 32))
	_subtitle = _text("Uma nova força para o seu time", 14, MUTED)
	_place(_subtitle, Vector2(0, 40), Vector2(340, 40))
	_card = Control.new()
	_card.position = Vector2(20, 92)
	_card.size = Vector2(300, 430)
	_card.pivot_offset = _card.size * 0.5
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_card)
	_back = _face(GOLD)
	var back_stack: VBoxContainer = _stack(_back)
	_spacer(back_stack)
	back_stack.add_child(_text("N  E  X  O", 32, GOLD))
	var seal: Control = CardArt.new()
	seal.accent = GOLD
	seal.skill = "macro"
	seal.rarity = 4
	back_stack.add_child(seal)
	seal.custom_minimum_size.y = 130
	back_stack.add_child(_text("RELÍQUIA DA ARENA", 13, GOLD))
	back_stack.add_child(_text("Seu próximo poder está aqui", 12, MUTED))
	_spacer(back_stack)
	_detail = _text("", 14, MUTED)
	_place(_detail, Vector2(0, 543), Vector2(340, 54))
	_action = Button.new()
	_action.text = "PULAR ANIMAÇÃO"
	_action.add_theme_font_size_override("font_size", 15)
	_action.add_theme_color_override("font_color", Color("10251f"))
	_action.add_theme_color_override("font_hover_color", Color("10251f"))
	_action.add_theme_color_override("font_pressed_color", Color("10251f"))
	_action.add_theme_stylebox_override("normal", _style(Color("75e4bd"), Color("75e4bd")))
	_action.add_theme_stylebox_override("hover", _style(Color("97f3d2"), GOLD))
	_action.add_theme_stylebox_override("pressed", _style(Color("5fcda6"), GOLD))
	_action.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD))
	_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_action.pressed.connect(_advance)
	_place(_action, Vector2(20, 610), Vector2(300, 52))
	# Keep keyboard navigation inside the modal while the purchase is displayed.
	_action.focus_neighbor_top = _action.get_path()
	_action.focus_neighbor_bottom = _action.get_path()
	_action.focus_neighbor_left = _action.get_path()
	_action.focus_neighbor_right = _action.get_path()
	_action.focus_next = _action.get_path()
	_action.focus_previous = _action.get_path()
	resized.connect(_layout)
	_layout()
	hide()
	set_process(false)
	set_process_unhandled_key_input(false)

func show_purchase(result: Dictionary) -> void:
	cancel()
	_result = result.duplicate(true)
	var definition: Dictionary = _result.card
	var rarity: Dictionary = Cards.RARITIES[int(definition.rarity)]
	_accent = Color(str(rarity.color))
	if is_instance_valid(_front):
		_card.remove_child(_front)
		_front.queue_free()
	_front = _face(_accent)
	var front_stack: VBoxContainer = _stack(_front)
	front_stack.add_child(_text(str(rarity.name).to_upper() + "  /  " + str(definition.sigil), 13, _accent))
	var art: Control = CardArt.new()
	art.accent = _accent
	art.skill = str(definition.icon)
	art.rarity = int(definition.rarity)
	front_stack.add_child(art)
	art.custom_minimum_size.y = 90
	var name_label: Label = _text(str(definition.name), 23, INK)
	name_label.custom_minimum_size.y = 58
	front_stack.add_child(name_label)
	front_stack.add_child(_text("NÍVEL %d / %d" % [int(_result.level), Cards.MAX_CARD_LEVEL], 22, _accent))
	_stars = CardStars.new()
	_stars.level = int(_result.level)
	front_stack.add_child(_stars)
	_spacer(front_stack)
	front_stack.add_child(_text(Cards.describe_effects(_result.effects), 15, INK))
	_spacer(front_stack)
	_front.hide()
	_back.show()
	_card.scale = Vector2(0.75, 0.75)
	_card.rotation = 0.0
	_card.modulate = Color.WHITE
	_revealed = false
	_burst = 0.0
	_elapsed = 0.0
	_title.text = "INVOCANDO RELÍQUIA"
	_title.modulate = Color.WHITE
	_title.add_theme_color_override("font_color", GOLD)
	_subtitle.text = "Uma nova força para o seu time"
	_detail.text = "Abrindo sua carta…"
	_action.text = "PULAR ANIMAÇÃO"
	modulate.a = 0.0
	show()
	set_process(true)
	set_process_unhandled_key_input(true)
	_action.grab_focus()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_tween.parallel().tween_property(_card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(0.2)
	for angle: float in [-0.045, 0.045, -0.065, 0.065, 0.0]:
		_tween.tween_property(_card, "rotation", angle, 0.07)
	_tween.tween_property(_card, "scale:x", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_reveal_face)
	_tween.tween_property(_card, "scale:x", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "_burst", 1.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_finish_reveal)

func _reveal_face() -> void:
	_back.hide()
	_front.show()
	_title.text = "SUBIU DE NÍVEL!" if bool(_result["duplicate"]) else "NOVA CARTA!"
	_title.add_theme_color_override("font_color", _accent)
	_subtitle.text = "Nível %d → %d · Bônus aumentado" % [int(_result.previous_level), int(_result.level)] if bool(_result["duplicate"]) else "Adicionada à sua coleção · Nível 1"
	if int(_result.level) == Cards.MAX_CARD_LEVEL:
		_detail.text = "NÍVEL MÁXIMO!\nAs próximas aberturas trarão outras cartas."
	else:
		_detail.text = "Repetidas aumentam o nível e o bônus.\nEquipe na coleção para a próxima partida."

func _finish_reveal() -> void:
	_revealed = true
	_action.text = "CONTINUAR"

func _advance() -> void:
	if not visible:
		return
	if not _revealed:
		if _tween != null:
			_tween.kill()
		modulate.a = 1.0
		_card.scale = Vector2.ONE
		_card.rotation = 0.0
		_burst = 1.0
		_reveal_face()
		_finish_reveal()
		return
	cancel()
	finished.emit()

func cancel() -> void:
	if _tween != null:
		_tween.kill()
	if is_instance_valid(_action):
		_action.release_focus()
	hide()
	set_process(false)
	set_process_unhandled_key_input(false)

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_advance()

func _layout() -> void:
	var factor: float = minf(1.0, minf((size.x - 24.0) / CANVAS_SIZE.x, (size.y - 24.0) / CANVAS_SIZE.y))
	_canvas.scale = Vector2.ONE * maxf(0.1, factor)
	_canvas.position = (size - CANVAS_SIZE * _canvas.scale) * 0.5
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(_canvas):
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.08, 0.96))
	var factor: float = _canvas.scale.x
	var center: Vector2 = _canvas.position + Vector2(170, 307) * factor
	var color: Color = _accent if is_instance_valid(_front) and _front.visible else GOLD
	var pulse: float = 1.0 + sin(_elapsed * 3.0) * 0.035
	for ring: int in range(8, 0, -1):
		draw_circle(center, (155.0 + ring * 12.0) * factor * pulse, Color(color, 0.012))
	if _burst > 0.0 and _burst < 1.0:
		draw_arc(center, (160.0 + _burst * 120.0) * factor, 0, TAU, 64, Color(color, (1.0 - _burst) * 0.8), 3.0 * factor, true)
		for index: int in range(24):
			var angle: float = index * TAU / 24.0
			var direction: Vector2 = Vector2.from_angle(angle)
			var distance: float = (150.0 + _burst * (100.0 + (index % 3) * 28.0)) * factor
			var point: Vector2 = center + direction * distance
			draw_line(point, point + direction * 14.0 * factor, Color(color, 1.0 - _burst), 3.0 * factor, true)

func _place(control: Control, location: Vector2, dimensions: Vector2) -> void:
	_canvas.add_child(control)
	control.position = location
	control.size = dimensions

func _text(value: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(20)
	return style

func _face(accent: Color) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color("142433"), accent))
	_card.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel

func _stack(parent: Control) -> VBoxContainer:
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stack)
	return stack

func _spacer(parent: Control) -> void:
	var spacer: Control = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
