extends Control

const Simulation = preload("res://scripts/match_sim.gd")
const Progression = preload("res://scripts/progression.gd")
const Arena = preload("res://scripts/arena_view.gd")
const Numbers = preload("res://scripts/number_format.gd")
const Cards = preload("res://scripts/card_catalog.gd")
const CardArt = preload("res://scripts/card_art.gd")
const INK: Color = Color("edf3ef")
const MUTED: Color = Color("93a9b8")
const MINT: Color = Color("75e4bd")
const GOLD: Color = Color("f1c779")
const BLUE: Color = Color("70c5ff")
const RED: Color = Color("ff818d")

var progress: RefCounted = Progression.new()
var simulation: RefCounted = Simulation.new()
var active: bool = false
var paused: bool = false
var match_speed: float = 1.0
var auto_play: bool = false
var restart_remaining: float = -1.0
var test_save_path: String = ""
var current_page: String = "MODOS"
var xp_label: Label
var record_label: Label
var score_label: Label
var clock_label: Label
var gold_label: Label
var status_label: Label
var detail_label: Label
var objective_label: Label
var event_label: Label
var warning_label: Label
var match_bar: ProgressBar
var arena: Control
var start_button: Button
var pause_button: Button
var speed_button: Button
var auto_button: CheckButton
var pages: Dictionary = {}
var nav_buttons: Dictionary = {}
var skill_buttons: Dictionary = {}
var skill_labels: Dictionary = {}
var training_buttons: Dictionary = {}
var training_levels: Dictionary = {}
var training_rates: Dictionary = {}
var income_label: Label
var mode_buttons: Dictionary = {}
var mode_details: Dictionary = {}
var training_label: Label
var training_notice: Label
var rank_label: Label
var rank_detail: Label
var rank_bar: ProgressBar
var match_title: Label
var training_timer: float = 0.0
var match_mode: String = "normal"
var scroll: ScrollContainer
var skills_scroll: ScrollContainer
var secondary_header: Array[Control] = []
var mode_chosen: bool = false
var ip_label: Label
var card_wallet: Label
var card_pity: Label
var card_milestone: Label
var card_summary: Label
var card_open_button: Button
var card_result: PanelContainer
var card_result_label: Label
var card_buttons: Dictionary = {}
var card_counts: Dictionary = {}
var card_panels: Dictionary = {}
var reveal_tween: Tween

func _ready() -> void:
	if not test_save_path.is_empty():
		progress.save_path = test_save_path
	else:
		progress.practice_mode = true
	progress.load_save()
	match_speed = 2.0 if progress.practice_mode else 1.0
	simulation.start(progress.combat_upgrades(), 0, progress.opponent_level(), _mode_name())
	_build_ui()
	_refresh_progress()
	_refresh_match()
	set_process(true)

func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color("0a1421")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var column: VBoxContainer = _column(16)
	margin.add_child(column)
	var masthead: HBoxContainer = HBoxContainer.new()
	column.add_child(masthead)
	secondary_header.append(masthead)
	var brand: VBoxContainer = _column(0)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masthead.add_child(brand)
	brand.add_child(_label("N E X O", 30, INK))
	brand.add_child(_label("I D L E   A R E N A", 10, MINT))
	var badge: Label = _label("TESTE  0.10" if progress.practice_mode else "PRÉVIA  0.10", 11, MUTED)
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	masthead.add_child(badge)
	var wallet: PanelContainer = _panel(Color("142433"))
	column.add_child(wallet)
	var wallet_row: HBoxContainer = HBoxContainer.new()
	wallet.add_child(wallet_row)
	var wallet_left: VBoxContainer = _column(3)
	wallet_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallet_row.add_child(wallet_left)
	wallet_left.add_child(_label("SUA EXPERIÊNCIA", 10, MUTED))
	xp_label = _label("0 XP", 27, GOLD)
	wallet_left.add_child(xp_label)
	income_label = _label("", 12, MINT)
	wallet_left.add_child(income_label)
	var wallet_right: VBoxContainer = _column(5)
	wallet_row.add_child(wallet_right)
	var team_label: Label = _label("TIME AZUL", 10, BLUE)
	team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wallet_right.add_child(team_label)
	ip_label = _label("0 IP", 24, MINT)
	ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wallet_right.add_child(ip_label)
	record_label = _label("0 vitórias · 0 partidas", 12, MUTED)
	wallet_right.add_child(record_label)
	if progress.practice_mode:
		var test_note: Label = _label("Modo de teste · XP ilimitado · progresso não é salvo", 12, GOLD)
		test_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(test_note)
		secondary_header.append(test_note)
		var reset: Button = _button("RECOMEÇAR TESTE", false)
		reset.pressed.connect(_reset_test_session)
		column.add_child(reset)
		secondary_header.append(reset)
	training_notice = _label("", 13, MINT)
	training_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(training_notice)
	if progress.last_training_reward > 0:
		training_notice.text = "Enquanto você esteve fora: +%s XP de estudos!" % Numbers.compact(progress.last_training_reward)
	training_notice.visible = not training_notice.text.is_empty()
	var nav: HBoxContainer = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	column.add_child(nav)
	for title: String in ["PARTIDA", "EVOLUÇÃO", "CARTAS", "MODOS"]:
		var button: Button = _button(title, false)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(_show_page.bind(title))
		nav.add_child(button)
		nav_buttons[title] = button
	scroll = ScrollContainer.new()
	scroll.scroll_deadzone = 10
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var page_column: VBoxContainer = _column(12)
	page_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page_column)
	for title: String in ["PARTIDA", "EVOLUÇÃO", "CARTAS", "MODOS"]:
		var page: VBoxContainer = _column(12)
		page_column.add_child(page)
		pages[title] = page
	pages.PARTIDA.reparent(column)
	pages.PARTIDA.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_match_page(pages.PARTIDA)
	_build_skills_page(pages["EVOLUÇÃO"])
	pages["EVOLUÇÃO"].add_child(HSeparator.new())
	_build_training_page(pages["EVOLUÇÃO"])
	_build_cards_page(pages.CARTAS)
	_build_modes_page(pages.MODOS)
	warning_label = _label("", 12, RED)
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(warning_label)
	var footer: Label = _label("Observe. Aprenda. Evolua.", 12, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_column.add_child(footer)
	_allow_scroll_gestures(margin)
	_show_page("MODOS")

func _allow_scroll_gestures(node: Node) -> void:
	# Let the enclosing ScrollContainer receive gestures started on cards and buttons.
	# Native scroll notifications cancel button activation after a drag.
	if node is Control and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child: Node in node.get_children():
		_allow_scroll_gestures(child)

func _build_match_page(page: VBoxContainer) -> void:
	var title_row: HBoxContainer = HBoxContainer.new()
	page.add_child(title_row)
	match_title = _label("Normal Game", 21, INK)
	match_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(match_title)
	var tag: Label = _label("5v5  /  AUTOMÁTICO", 10, MINT)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(tag)
	var rank_card: PanelContainer = _panel(Color("142433"), 12)
	var rank_stack: VBoxContainer = _column(5)
	rank_card.add_child(rank_stack)
	rank_label = _label("", 18, GOLD)
	rank_stack.add_child(rank_label)
	rank_bar = ProgressBar.new()
	rank_bar.show_percentage = false
	rank_bar.custom_minimum_size.y = 6
	rank_bar.add_theme_stylebox_override("background", _style(Color("263746"), 3))
	rank_bar.add_theme_stylebox_override("fill", _style(GOLD, 3))
	rank_stack.add_child(rank_bar)
	rank_detail = _label("", 12, MUTED)
	rank_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rank_stack.add_child(rank_detail)
	var board: PanelContainer = _panel(Color("0e1b29"), 12)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.size_flags_stretch_ratio = 1.2
	page.add_child(board)
	var content: VBoxContainer = _column(7)
	board.add_child(content)
	var scores: HBoxContainer = HBoxContainer.new()
	content.add_child(scores)
	var blue: Label = _label("●  SEU TIME", 11, BLUE)
	blue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scores.add_child(blue)
	score_label = _label("0  :  0", 24, INK)
	scores.add_child(score_label)
	var red: Label = _label("RIVAIS  ●", 11, RED)
	red.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	red.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scores.add_child(red)
	clock_label = _label("00:00 / 01:30", 11, MUTED)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(clock_label)
	arena = Arena.new()
	arena.fit_to_width = false
	arena.custom_minimum_size.y = 160
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.simulation = simulation
	content.add_child(arena)
	gold_label = _label("OURO  0  ×  0", 11, GOLD)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(gold_label)
	match_bar = ProgressBar.new()
	match_bar.show_percentage = false
	match_bar.custom_minimum_size.y = 4
	match_bar.add_theme_stylebox_override("background", _style(Color("263746"), 2))
	match_bar.add_theme_stylebox_override("fill", _style(MINT, 2))
	content.add_child(match_bar)
	objective_label = _label("", 10, GOLD)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(objective_label)
	event_label = _label("Três rotas. Dez jogadores. Um nexo para conquistar.", 11, MUTED)
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.custom_minimum_size.y = 32
	content.add_child(event_label)
	status_label = _label("Sua próxima vitória começa aqui.", 18, INK)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(status_label)
	detail_label = _label("Jogue, ganhe XP e melhore as habilidades do seu time.", 12, MUTED)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(detail_label)
	start_button = _button("JOGAR NORMAL  →", true)
	start_button.custom_minimum_size.y = 52
	start_button.pressed.connect(_start_match)
	page.add_child(start_button)
	var controls: HBoxContainer = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	page.add_child(controls)
	pause_button = _button("Pausar", false)
	pause_button.disabled = true
	pause_button.pressed.connect(_toggle_pause)
	controls.add_child(pause_button)
	speed_button = _button("%d×" % int(match_speed), false)
	speed_button.pressed.connect(_toggle_speed)
	speed_button.tooltip_text = "Alternar entre 1× e 2× para toda a partida."
	speed_button.custom_minimum_size.x = 55
	controls.add_child(speed_button)
	auto_button = CheckButton.new()
	auto_button.text = "Repetir partidas"
	auto_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_button.add_theme_font_size_override("font_size", 12)
	auto_button.add_theme_color_override("font_color", MUTED)
	auto_button.toggled.connect(_set_auto_play)
	controls.add_child(auto_button)
	# Match controls and map stay fixed; only the improvements below them scroll.
	page.move_child(start_button, 1)
	page.move_child(controls, 2)
	skills_scroll = ScrollContainer.new()
	skills_scroll.scroll_deadzone = 10
	skills_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	skills_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skills_scroll.custom_minimum_size.y = 180
	page.add_child(skills_scroll)
	var improvements: VBoxContainer = _column(12)
	improvements.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skills_scroll.add_child(improvements)
	# Reuse the same skill cards in the match and in the Improvements tab.
	status_label.reparent(improvements)
	detail_label.reparent(improvements)
	pages["EVOLUÇÃO"].reparent(improvements)
	improvements.add_child(rank_card)

func _build_skills_page(page: VBoxContainer) -> void:
	page.add_child(_label("HABILIDADES  /  VENÇA NA ARENA", 18, MINT))
	var intro: Label = _label("Treine seu time com XP. Cada habilidade ajuda a ganhar a próxima partida.", 13, MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)
	var grid: GridContainer = _grid(page)
	for key: String in Progression.SKILL_ORDER:
		var card: PanelContainer = _tile(grid)
		var stack: VBoxContainer = _column(8)
		card.add_child(stack)
		var title: Label = _label(str(Progression.SKILL_LABELS[key]), 18, INK)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(title)
		var level: Label = _label("NÍVEL 0", 12, MINT)
		stack.add_child(level)
		skill_labels[key] = level
		var description: Label = _label(str(Progression.SKILL_DESCRIPTIONS[key]), 12, MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stack.add_child(description)
		var buy: Button = _button("", false)
		buy.pressed.connect(_buy_upgrade.bind(key))
		stack.add_child(buy)
		skill_buttons[key] = buy

func _build_training_page(page: VBoxContainer) -> void:
	page.add_child(_label("ESTUDOS  /  PRODUZA MAIS XP", 18, GOLD))
	var intro: Label = _label("Estudos produzem XP/s para investir nas habilidades. Fora do modo de teste, acumulam por até 2 horas com o jogo fechado.", 13, MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)
	training_label = _label("", 18, GOLD)
	training_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(training_label)
	var descriptions: Array[String] = [
		"Seu jogador acompanha dicas e aprende os fundamentos.",
		"Estude farm, trocas e builds em tutoriais de vídeo.",
		"Observe os profissionais e aprenda decisões de macro e visão.",
		"Um coach analisa os erros do seu jogador e orienta o treino."
	]
	var grid: GridContainer = _grid(page)
	for index: int in range(Progression.TRAINING_ORDER.size()):
		var key: String = Progression.TRAINING_ORDER[index]
		var card: PanelContainer = _tile(grid)
		var stack: VBoxContainer = _column(8)
		card.add_child(stack)
		var title: Label = _label(str(Progression.TRAINING_LABELS[key]), 17, INK)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(title)
		var level: Label = _label("", 12, MUTED)
		stack.add_child(level)
		training_levels[key] = level
		var rate: Label = _label("", 14, MINT)
		rate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(rate)
		training_rates[key] = rate
		var description: Label = _label(descriptions[index], 12, MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stack.add_child(description)
		var buy: Button = _button("", false)
		buy.pressed.connect(_buy_training.bind(key))
		stack.add_child(buy)
		training_buttons[key] = buy
	var note: Label = _label("Atividades fictícias do seu jogador, sem precisar abrir vídeos reais. Cada nível é permanente e aumenta seu XP/s. A produção de todos os estudos se soma.", 12, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(note)

func _build_cards_page(page: VBoxContainer) -> void:
	page.add_child(_label("Cartas do Nexo", 24, INK))
	page.add_child(_wrapped("Colecione relíquias e equipe até 3 cartas. Os bônus se somam às habilidades na próxima partida.", 13, MUTED))
	var shop: PanelContainer = _panel(Color("1b233b"))
	page.add_child(shop)
	var stack: VBoxContainer = _column(10)
	shop.add_child(stack)
	stack.add_child(_label("INVOCAÇÃO  /  UMA CARTA POR ABERTURA", 11, MINT))
	card_wallet = _label("", 26, MINT)
	stack.add_child(card_wallet)
	stack.add_child(_wrapped("Normal, rara, épica, lendária ou mítica. Descubra a próxima peça do seu time.", 13, INK))
	card_open_button = _button("ABRIR CARTA  ·  100 IP", true)
	card_open_button.custom_minimum_size.y = 52
	card_open_button.pressed.connect(_open_card)
	stack.add_child(card_open_button)
	card_pity = _wrapped("", 12, GOLD)
	stack.add_child(card_pity)
	stack.add_child(_wrapped("Chances por abertura: Normal 60% · Rara 25% · Épica 10% · Lendária 4% · Mítica 1%.", 12, MUTED))
	stack.add_child(_wrapped("Após 9 cartas sem épica ou superior, a próxima garante: Épica ≈66,67% · Lendária ≈26,67% · Mítica ≈6,67%. Uma épica ou superior reinicia a contagem. Cada carta tem a mesma chance dentro da sua raridade.", 11, MUTED))
	card_result = _panel(Color("203044"))
	page.add_child(card_result)
	card_result_label = _wrapped("", 18, INK)
	card_result.add_child(card_result_label)
	card_result.hide()
	var earn: PanelContainer = _panel(Color("142433"))
	page.add_child(earn)
	var earn_stack: VBoxContainer = _column(7)
	earn.add_child(earn_stack)
	earn_stack.add_child(_label("COMO GANHAR IDLE POINTS", 14, MINT))
	earn_stack.add_child(_wrapped("+25 IP por nova divisão alcançada, até Mestre na Ranked. +75 IP extras ao chegar a um novo elo, inclusive Grão-Mestre e Challenger. Cada conquista paga uma vez por modo.", 12, INK))
	card_milestone = _wrapped("", 12, GOLD)
	earn_stack.add_child(card_milestone)
	earn_stack.add_child(_wrapped("IP é uma moeda rara: estudos geram XP, não IP. Anúncios premiados e compra de IP: em breve.", 12, MUTED))
	if progress.practice_mode:
		earn_stack.add_child(_wrapped("Nesta sessão de teste você começa com 300 IP para experimentar. IP é limitado; cartas e saldo reiniciam ao recomeçar ou fechar o jogo.", 12, GOLD))
	page.add_child(_label("Sua coleção", 22, INK))
	card_summary = _wrapped("", 12, MINT)
	page.add_child(card_summary)
	page.add_child(_wrapped("Repetidas devolvem IP: Normal 10 · Rara 20 · Épica 35 · Lendária 50 · Mítica 75. Cópias não multiplicam o bônus.", 12, MUTED))
	var grid: GridContainer = _grid(page)
	for definition: Dictionary in Cards.CARDS:
		var id: String = str(definition.id)
		var rarity: Dictionary = Cards.RARITIES[int(definition.rarity)]
		var accent: Color = Color(str(rarity.color))
		var card: PanelContainer = _tile(grid)
		card.custom_minimum_size.y = 290
		var style: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
		style.border_color = accent.darkened(0.35)
		style.set_border_width_all(2)
		card.add_theme_stylebox_override("panel", style)
		card_panels[id] = card
		var content: VBoxContainer = _column(6)
		card.add_child(content)
		content.add_child(_label("%s  /  %s" % [str(rarity.name).to_upper(), definition.sigil], 11, accent))
		var art: Control = CardArt.new()
		art.accent = accent
		art.skill = str(definition.skill)
		art.rarity = int(definition.rarity)
		content.add_child(art)
		var name_label: Label = _wrapped(str(definition.name), 17, INK)
		name_label.custom_minimum_size.y = 44
		content.add_child(name_label)
		content.add_child(_wrapped("+%d níveis de %s" % [int(definition.bonus), Progression.SKILL_LABELS[definition.skill]], 12, accent))
		var owned: Label = _wrapped("", 11, MUTED)
		owned.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(owned)
		card_counts[id] = owned
		var equip: Button = _button("", false)
		equip.pressed.connect(_toggle_card.bind(id))
		content.add_child(equip)
		card_buttons[id] = equip

func _open_card() -> void:
	var result: Dictionary = progress.open_card()
	if not result.is_empty():
		var card: Dictionary = result.card
		var rarity: Dictionary = Cards.RARITIES[int(card.rarity)]
		card_result_label.text = "%s!\n%s · %s\n+%d níveis de %s ao equipar\n%s" % [
			"CARTA REPETIDA" if bool(result["duplicate"]) else "NOVA CARTA",
			card.name, rarity.name, int(card.bonus), Progression.SKILL_LABELS[card.skill],
			"+%d IP devolvidos" % int(result.refund) if bool(result["duplicate"]) else "Já está na sua coleção. Equipe abaixo!",
		]
		card_result_label.add_theme_color_override("font_color", Color(str(rarity.color)))
		card_result.show()
		if reveal_tween != null:
			reveal_tween.kill()
		card_result.modulate.a = 0.0
		reveal_tween = create_tween()
		reveal_tween.tween_property(card_result, "modulate:a", 1.0, 0.4)
		# Reveal happens after the saved purchase; animation never controls the reward.
		scroll.ensure_control_visible.call_deferred(card_result)
	_refresh_progress()

func _toggle_card(id: String) -> void:
	progress.toggle_card(id)
	_refresh_progress()

func _refresh_cards() -> void:
	ip_label.text = "%s IP" % Numbers.compact(progress.idle_points)
	ip_label.tooltip_text = "%d Idle Points" % progress.idle_points
	card_wallet.text = "%s IP" % Numbers.compact(progress.idle_points)
	card_open_button.disabled = progress.idle_points < Cards.PACK_COST
	card_pity.text = "Épica ou superior garantida em até %d abertura(s)." % (Cards.PITY_LIMIT - progress.pulls_without_epic)
	card_milestone.text = "+50 IP a cada 10 vitórias · Próximo marco: %d/10" % (progress.wins % Progression.WIN_MILESTONE)
	var names: Array[String] = []
	for id: String in progress.equipped_cards:
		names.append(str(Cards.find_card(id).name))
	card_summary.text = "%d/%d descobertas · %d/3 equipadas\n%s" % [
		progress.collection.size(), Cards.CARDS.size(), progress.equipped_cards.size(),
		"Nenhuma carta equipada. Escolha até três abaixo." if names.is_empty() else "Equipadas: " + ", ".join(names),
	]
	for card: Dictionary in Cards.CARDS:
		var id: String = str(card.id)
		var owned: bool = progress.collection.has(id)
		var equipped: bool = progress.equipped_cards.has(id)
		card_counts[id].text = "%d cópia(s) obtida(s)" % int(progress.collection[id]) if owned else "Ainda não descoberta"
		card_buttons[id].text = "REMOVER" if equipped else ("EQUIPAR" if owned else "NÃO OBTIDA")
		card_buttons[id].disabled = not owned or (not equipped and progress.equipped_cards.size() >= Cards.MAX_EQUIPPED)
		card_panels[id].modulate = Color.WHITE if owned else Color("82909e")
		card_buttons[id].add_theme_color_override("font_color", MINT if equipped else INK)

func _grid(parent: Control) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(grid)
	return grid

func _tile(grid: GridContainer) -> PanelContainer:
	var card: PanelContainer = _panel(Color("142433"), 12)
	card.custom_minimum_size.y = 230
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(card)
	return card

func _wrapped(text: String, font_size: int, color: Color) -> Label:
	var label: Label = _label(text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _build_modes_page(page: VBoxContainer) -> void:
	page.add_child(_label("Escolha sua arena", 24, INK))
	page.add_child(_label("A jornada começa no Normal Game.", 13, MUTED))
	var modes: Array[Dictionary] = [
		{"name":"NORMAL GAME", "key":"normal", "tag":"ESCALADA", "text":"", "color":MINT},
		{"name":"RANKED", "key":"ranked", "tag":"DESAFIO COMPETITIVO", "text":"", "color":GOLD},
		{"name":"ARAM", "tag":"EM BREVE", "text":"Uma rota. Toda a equipe. Desbloqueio com XP.", "color":BLUE},
		{"name":"URF", "tag":"EM BREVE · 2× XP", "text":"Acesso planejado por anúncio ou compra permanente.", "color":RED}
	]
	for mode: Dictionary in modes:
		var card: PanelContainer = _panel(Color("142433"))
		page.add_child(card)
		var stack: VBoxContainer = _column(10)
		card.add_child(stack)
		stack.add_child(_label(str(mode.tag), 10, mode.color))
		stack.add_child(_label(str(mode.name), 21, INK))
		var description: Label = _label(str(mode.text), 13, MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(description)
		if mode.has("key"):
			var play: Button = _button("ABRIR ARENA  →", true)
			play.pressed.connect(_choose_mode.bind(str(mode.key)))
			stack.add_child(play)
			mode_buttons[mode.key] = play
			mode_details[mode.key] = description

func _process(delta: float) -> void:
	training_timer += delta
	if training_timer >= 1.0:
		training_timer = fmod(training_timer, 1.0)
		progress.settle_training()
		_refresh_progress()
	if active and not paused:
		simulation.advance(minf(delta, 0.25) * match_speed)
		_refresh_match()
		if simulation.finished:
			_finish_match()
	elif restart_remaining >= 0 and auto_play:
		restart_remaining -= delta * match_speed
		if restart_remaining <= 0:
			_start_match()

func _start_match() -> void:
	if active or not mode_chosen:
		return
	restart_remaining = -1
	match_mode = progress.selected_mode
	simulation.start(progress.combat_upgrades(), 0, progress.opponent_level(match_mode), _mode_name())
	active = true
	paused = false
	arena.running = true
	start_button.text = "PARTIDA EM ANDAMENTO"
	start_button.disabled = true
	pause_button.disabled = false
	pause_button.text = "Pausar"
	status_label.text = "Seu time está na arena."
	status_label.add_theme_color_override("font_color", INK)
	detail_label.text = "As jogadas são automáticas. Você cuida da evolução."
	_refresh_progress()
	_refresh_match()

func _finish_match() -> void:
	active = false
	paused = false
	arena.running = false
	var won: bool = simulation.winner == 0
	var previous_points: int = int(progress.ladders[match_mode])
	var previous_rank: String = progress.rank_name(match_mode)
	var reward: int = progress.record_match(won, match_mode)
	var point_change: int = int(progress.ladders[match_mode]) - previous_points
	status_label.text = ("Vitória!" if won else "Derrota. O treino continua.") + "  +%s XP" % Numbers.compact(reward)
	status_label.add_theme_color_override("font_color", MINT if won else GOLD)
	detail_label.text = "%+d pontos · %s · %s. Invista nas habilidades." % [point_change, progress.rank_name(match_mode), progress.rank_points_text(match_mode)]
	if progress.last_ip_reward > 0:
		status_label.text += "  +%d IP" % progress.last_ip_reward
	if previous_rank != progress.rank_name(match_mode):
		detail_label.text = ("Subiu de divisão! " if won else "Desceu de divisão. ") + detail_label.text
	if not progress.last_error.is_empty():
		status_label.text = "Resultado não salvo."
		detail_label.text = "Não foi possível registrar XP e pontos desta partida. " + progress.last_error
	start_button.text = "JOGAR NOVAMENTE  →"
	start_button.disabled = false
	pause_button.disabled = true
	pause_button.text = "Pausar"
	_refresh_progress()
	if auto_play:
		restart_remaining = 3.0

func _refresh_match() -> void:
	objective_label.text = simulation.objective_status()
	score_label.text = "%d  :  %d" % [simulation.kills[0], simulation.kills[1]]
	var seconds: int = int(simulation.elapsed + 0.000001)
	clock_label.text = "%02d:%02d / 01:30" % [seconds / 60, seconds % 60]
	gold_label.text = "OURO  %s  ×  %s" % [Numbers.compact(int(simulation.team_gold[0])), Numbers.compact(int(simulation.team_gold[1]))]
	match_bar.value = simulation.elapsed / simulation.duration * 100
	if not active and not simulation.finished:
		event_label.text = "Três rotas. Dez jogadores. Um nexo para conquistar."
	elif not simulation.events.is_empty():
		event_label.text = str(simulation.events.front())

func _refresh_progress() -> void:
	_refresh_cards()
	xp_label.text = "∞ XP" if progress.practice_mode else "%s XP" % Numbers.compact(progress.xp)
	xp_label.tooltip_text = "XP ilimitado nesta sessão" if progress.practice_mode else "%d XP" % progress.xp
	income_label.text = "+%s XP/s · Estudos" % Numbers.compact(progress.training_rate())
	record_label.text = "%d vitórias · %d partidas" % [progress.wins, progress.matches]
	for key: String in Progression.SKILL_ORDER:
		var level: int = int(progress.upgrades[key])
		var cost: int = progress.upgrade_cost(key)
		var bonus: int = int(progress.combat_upgrades()[key]) - level
		skill_labels[key].text = "NÍVEL %d / 20" % level + ("\n+%d pelas cartas" % bonus if bonus > 0 else "")
		skill_buttons[key].text = "NÍVEL MÁXIMO" if level >= 20 else "MELHORAR\n%s XP" % Numbers.compact(cost)
		skill_buttons[key].tooltip_text = "%d XP" % cost if cost >= 0 else "Nível máximo"
		skill_buttons[key].disabled = level >= 20 or not progress.can_afford(cost)
	match_title.text = _mode_name()
	rank_label.text = "%s · %s" % [progress.rank_name(), progress.rank_points_text()]
	rank_bar.value = progress.rank_lp()
	rank_bar.visible = not (progress.selected_mode == "ranked" and int(progress.ladders.ranked) >= 2800)
	if int(progress.ladders[progress.selected_mode]) == progress.ladder_cap():
		rank_label.text = "%s · TOPO DA ESCALADA" % progress.rank_name()
		rank_bar.value = 100
	rank_detail.text = "+25 vitória / −25 derrota · Vitória: %s XP\nRivais: nível %.1f · Quanto maior o elo, maior o desafio." % [Numbers.compact(progress.victory_reward()), progress.opponent_level()]
	training_label.text = "%s XP/s  ·  Até %s XP em 2 horas" % [Numbers.compact(progress.training_rate()), Numbers.compact(progress.training_rate() * Progression.TRAINING_CAP_HOURS * 3600)]
	for key: String in Progression.TRAINING_ORDER:
		var level: int = int(progress.training_levels[key])
		var cost: int = progress.training_cost(key)
		var production: int = progress.training_production(key)
		training_levels[key].text = "NÍVEL %d / %d" % [level, Progression.MAX_TRAINING_LEVEL]
		training_rates[key].text = "%s XP/s\nPróximo: %s XP/s" % [Numbers.compact(production), Numbers.compact(progress.training_production(key, level + 1))] if cost >= 0 else "%s XP/s · Produção máxima" % Numbers.compact(production)
		training_buttons[key].text = "NÍVEL MÁXIMO" if cost < 0 else ("MELHORAR\n%s XP" % Numbers.compact(cost) if level > 0 else "INICIAR\n%s XP" % Numbers.compact(cost))
		training_buttons[key].tooltip_text = "%d XP" % cost if cost >= 0 else "Nível máximo"
		training_buttons[key].disabled = cost < 0 or not progress.can_afford(cost)
	mode_details.normal.text = "%s · %d/100 pontos. Comece em Sal IV, suba de divisão e ganhe mais XP por vitória." % [progress.rank_name("normal"), progress.rank_lp("normal")]
	mode_details.ranked.text = ("%s · %s. De Ferro a Challenger, com 50%% mais XP." % [progress.rank_name("ranked"), progress.rank_points_text("ranked")]) if progress.ranked_unlocked else "Alcance Barro IV no Normal e compre o acesso por %s XP. Rivais mais fortes e 50%% mais XP." % Numbers.compact(Progression.RANKED_COST)
	mode_buttons.normal.disabled = active
	mode_buttons.ranked.text = "ABRIR RANKED →" if progress.ranked_unlocked else "DESBLOQUEAR · %s XP" % Numbers.compact(Progression.RANKED_COST)
	mode_buttons.ranked.disabled = active or (not progress.ranked_unlocked and not progress.can_unlock_ranked())
	if not active and not simulation.finished:
		start_button.text = "JOGAR %s →" % _mode_name().to_upper()
	warning_label.text = str(progress.last_error)
	warning_label.visible = not str(progress.last_error).is_empty()

func _buy_upgrade(key: String) -> void:
	progress.buy_upgrade(key)
	_refresh_progress()

func _reset_test_session() -> void:
	if not progress.practice_mode:
		return
	progress.load_save()
	if reveal_tween != null:
		reveal_tween.kill()
	card_result.hide()
	card_result_label.text = ""
	match_speed = 2.0
	speed_button.text = "2×"
	active = false
	paused = false
	auto_play = false
	restart_remaining = -1.0
	training_timer = 0.0
	mode_chosen = false
	match_mode = "normal"
	auto_button.set_pressed_no_signal(false)
	simulation.start(progress.combat_upgrades(), 0, progress.opponent_level(), _mode_name())
	arena.running = false
	start_button.disabled = false
	pause_button.disabled = true
	pause_button.text = "Pausar"
	training_notice.hide()
	status_label.text = "Escolha um modo para começar o teste."
	detail_label.text = "XP ilimitado. Seu progresso vale apenas nesta sessão."
	_show_page("MODOS")
	_refresh_progress()
	_refresh_match()

func _buy_training(key: String) -> void:
	progress.buy_training(key)
	_refresh_progress()

func _mode_name() -> String:
	return "Ranked" if progress.selected_mode == "ranked" else "Normal Game"

func _choose_mode(mode: String) -> void:
	if active:
		return
	if mode == "ranked" and not progress.ranked_unlocked:
		if not progress.unlock_ranked():
			_refresh_progress()
			return
	if progress.select_mode(mode):
		mode_chosen = true
		restart_remaining = -1.0
		auto_button.button_pressed = false
		simulation.start(progress.combat_upgrades(), 0, progress.opponent_level(), _mode_name())
		status_label.text = "Sua próxima vitória começa aqui."
		detail_label.text = "Melhore suas habilidades para acompanhar a força dos rivais."
		_show_page("PARTIDA")
		_refresh_match()
	_refresh_progress()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_instance_valid(training_label):
		var earned: int = progress.settle_training()
		if earned > 0:
			training_notice.text = "Boas-vindas de volta! +%s XP de estudos." % Numbers.compact(earned)
			training_notice.show()
		_refresh_progress()

func _toggle_pause() -> void:
	if not active:
		return
	paused = not paused
	pause_button.text = "Continuar" if paused else "Pausar"
	status_label.text = "Partida pausada." if paused else "Seu time está na arena."

func _toggle_speed() -> void:
	match_speed = 2.0 if match_speed == 1.0 else 1.0
	speed_button.text = "%d×" % int(match_speed)

func _set_auto_play(enabled: bool) -> void:
	auto_play = enabled
	if not enabled:
		restart_remaining = -1
	elif simulation.finished and not active:
		restart_remaining = 3.0

func _show_page(title: String) -> void:
	if title == "PARTIDA" and not mode_chosen:
		title = "MODOS"
	current_page = title
	var showing_match: bool = title == "PARTIDA"
	for header: Control in secondary_header:
		header.visible = not showing_match
	scroll.visible = not showing_match
	var skills_parent: Node = status_label.get_parent() if showing_match else pages.CARTAS.get_parent()
	if pages["EVOLUÇÃO"].get_parent() != skills_parent:
		pages["EVOLUÇÃO"].reparent(skills_parent)
		skills_parent.move_child(pages["EVOLUÇÃO"], 2 if showing_match else 0)
	if is_instance_valid(scroll):
		scroll.set_deferred("scroll_vertical", 0)
	for key: String in pages:
		pages[key].visible = key == title or (key == "EVOLUÇÃO" and showing_match)
		nav_buttons[key].add_theme_color_override("font_color", MINT if key == title else MUTED)
		nav_buttons[key].add_theme_stylebox_override("normal", _style(Color("213c40") if key == title else Color("122231"), 10))

func _column(gap: int) -> VBoxContainer:
	var result: VBoxContainer = VBoxContainer.new()
	result.add_theme_constant_override("separation", gap)
	return result

func _label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style

func _panel(color: Color, padding: int = 16) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = _style(color, 16)
	style.set_content_margin_all(padding)
	style.border_color = Color("293d4c")
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _button(text: String, primary: bool) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("10251f") if primary else INK)
	button.add_theme_color_override("font_hover_color", Color("10251f") if primary else INK)
	button.add_theme_color_override("font_pressed_color", Color("10251f") if primary else MINT)
	button.add_theme_color_override("font_disabled_color", Color("768794"))
	button.add_theme_stylebox_override("normal", _style(MINT if primary else Color("223746"), 10))
	button.add_theme_stylebox_override("hover", _style(Color("97f3d2") if primary else Color("304c5c"), 10))
	button.add_theme_stylebox_override("pressed", _style(Color("5fcda6") if primary else Color("1b303b"), 10))
	button.add_theme_stylebox_override("disabled", _style(Color("1b2a37"), 10))
	var focus: StyleBoxFlat = _style(Color(0,0,0,0), 10)
	focus.border_color = GOLD
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	return button

