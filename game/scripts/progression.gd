extends RefCounted

## Permanent progression for the first playable Normal Game prototype.
## Balance values are deliberately provisional, not final design decisions.
const SAVE_VERSION: int = 5
const Cards = preload("res://scripts/card_catalog.gd")
const DIVISION_IP: int = 25
const TIER_IP: int = 75
const WIN_MILESTONE: int = 10
const WIN_MILESTONE_IP: int = 50
const PRACTICE_IP: int = 300
const MAX_LEVEL: int = 20
const MAX_COUNTER: int = 9_000_000_000_000
const MAX_TIMESTAMP: int = 4_102_444_800
const RANKED_COST: int = 10_000
const RANKED_REQUIRED_DIVISION: int = 4
const TRAINING_CAP_HOURS: int = 2
const MAX_TRAINING_LEVEL: int = 20
const MAX_LADDER_POINTS: int = 2799
const RANK_NAMES: Array[String] = ["Sal", "Barro", "Pedra", "Cobre", "Aço", "Titânio", "Lenda"]
const RANKED_NAMES: Array[String] = ["Ferro", "Bronze", "Prata", "Ouro", "Platina", "Esmeralda", "Diamante"]
const RANKED_MAX_POINTS: int = 3999
const TRAINING_GROWTH: float = 1.6
const TRAINING_COST_GROWTH: float = 2.4
const DIVISION_NAMES: Array[String] = ["IV", "III", "II", "I"]
const TRAINING_ORDER: Array[String] = ["videos", "tutoriais", "competicoes", "coach"]
const TRAINING_LABELS: Dictionary = {
	"videos": "Vídeos de dicas", "tutoriais": "Tutoriais de gameplay",
	"competicoes": "Estudar competições", "coach": "Sessões com coach",
}
const TRAINING_COSTS: Dictionary = {"videos": 100, "tutoriais": 300, "competicoes": 1200, "coach": 4000}
# XP per second, for each level of an activity.
const TRAINING_RATES: Dictionary = {"videos": 1, "tutoriais": 2, "competicoes": 4, "coach": 10}
const LEGACY_TRAINING_RATES: Dictionary = {"videos": 30, "tutoriais": 60, "competicoes": 120, "coach": 300}
const SKILL_ORDER: Array[String] = ["farm", "trades", "builds", "macro", "vision"]
const SKILL_LABELS: Dictionary = {
	"farm": "Farm",
	"trades": "Trocas",
	"builds": "Builds",
	"macro": "Macro",
	"vision": "Visão de mapa",
}
const SKILL_DESCRIPTIONS: Dictionary = {
	"farm": "Ganhe mais ouro durante a partida.",
	"trades": "Cause mais dano nos confrontos.",
	"builds": "Transforme ouro em mais poder de combate.",
	"macro": "Pressione melhor as torres e a base.",
	"vision": "Antecipe ameaças e sobreviva por mais tempo.",
}

var xp: int = 0
var practice_mode: bool = false
var lifetime_xp: int = 0
var matches: int = 0
var wins: int = 0
var idle_points: int = 0
var collection: Dictionary = {}
var equipped_cards: Array[String] = []
var pulls_without_epic: int = 0
var highest_ladders: Dictionary = {"normal": 0, "ranked": 0}
var last_ip_reward: int = 0
var _card_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var upgrades: Dictionary = {"farm": 0, "trades": 0, "builds": 0, "macro": 0, "vision": 0}
var training_levels: Dictionary = {"videos": 1, "tutoriais": 0, "competicoes": 0, "coach": 0}
# Read-only compatibility view for callers of the old ownership API.
var training_owned: Dictionary:
	get:
		var owned: Dictionary = {}
		for key: String in TRAINING_ORDER:
			owned[key] = int(training_levels[key]) > 0
		return owned
var training_last_at: int = 0
# Fractional XP, stored as the numerator over 3600 seconds.
var training_remainder: int = 0
var last_training_reward: int = 0
var selected_mode: String = "normal"
var ranked_unlocked: bool = false
var ladders: Dictionary = {"normal": 0, "ranked": 0}
var save_path: String = "user://progress.json"
var last_error: String = ""
var time_override: int = -1
var _write_blocked: bool = false
var _load_attempted: bool = false


func load_save() -> void:
	_card_rng.randomize()
	if practice_mode:
		var fresh = get_script().new()
		_restore(fresh._snapshot())
		xp = MAX_COUNTER
		idle_points = PRACTICE_IP
		last_ip_reward = 0
		training_last_at = _now()
		last_training_reward = 0
		last_error = ""
		_write_blocked = false
		_load_attempted = true
		return
	last_error = ""
	_write_blocked = false
	_load_attempted = true
	last_training_reward = 0
	if not FileAccess.file_exists(save_path):
		training_last_at = _now()
		save_game()
		return
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		_block_writes("Não foi possível ler o progresso salvo. O arquivo foi preservado.")
		return
	var source: String = file.get_as_text()
	file.close()
	var parser: JSON = JSON.new()
	if parser.parse(source) != OK or not parser.data is Dictionary:
		_block_writes("O progresso salvo está inválido. O arquivo foi preservado.")
		return
	var data: Dictionary = parser.data
	if _whole_number(data.get("schema_version"), 1, MAX_COUNTER) and int(data["schema_version"]) > SAVE_VERSION:
		_block_writes("Este progresso pertence a uma versão mais recente do jogo. O arquivo foi preservado.")
		return
	if not _valid_snapshot(data):
		_block_writes("O progresso salvo contém dados inválidos. O arquivo foi preservado.")
		return
	# v1 has no training clock; v2 accrues its pending time at the old hourly rate.
	if int(data["schema_version"]) == 1:
		data["training_levels"] = {"videos": 1, "tutoriais": 0, "competicoes": 0, "coach": 0}
		data["training_last_at"] = _now()
		data["training_remainder"] = 0
		data["selected_mode"] = "normal"
		data["ranked_unlocked"] = false
		data["ladders"] = {"normal": 0, "ranked": 0}
		_restore(data)
		if not save_game():
			_write_blocked = true
	elif int(data["schema_version"]) in [2, 3]:
		_migrate_hourly_training(data)
	else:
		_restore(data)
		settle_training()


func save_game() -> bool:
	if practice_mode:
		return true
	if _write_blocked:
		return false
	# Never replace an existing save that the caller has not inspected first.
	if not _load_attempted and FileAccess.file_exists(save_path):
		last_error = "Carregue o progresso existente antes de salvar."
		return false
	var snapshot: Dictionary = _snapshot()
	if not _valid_snapshot(snapshot):
		last_error = "Não foi possível salvar: os dados da sessão estão inválidos."
		return false
	var temporary_path: String = save_path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		last_error = "Não foi possível criar o arquivo de progresso."
		return false
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		last_error = "Não foi possível gravar o progresso. O arquivo anterior foi preservado."
		return false
	# Rename replaces the destination only after the new file is fully written.
	# Never remove the old save as a fallback when replacement fails.
	var rename_error: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(save_path)
	)
	if rename_error != OK:
		last_error = "Não foi possível atualizar o progresso. O arquivo anterior foi preservado."
		return false
	last_error = ""
	_load_attempted = true
	return true


func upgrade_cost(key: String) -> int:
	if not upgrades.has(key) or not SKILL_ORDER.has(key):
		return -1
	var level: int = int(upgrades[key])
	if level < 0 or level >= MAX_LEVEL:
		return -1
	return int(round(60.0 * pow(2.0, float(level))))


func buy_upgrade(key: String) -> bool:
	if _write_blocked:
		return false
	var cost: int = upgrade_cost(key)
	if cost < 0:
		last_error = "Essa melhoria não está disponível."
		return false
	if not can_afford(cost):
		last_error = "XP insuficiente para essa melhoria."
		return false
	var previous_xp: int = xp
	var previous_level: int = int(upgrades[key])
	if not practice_mode:
		xp -= cost
	upgrades[key] = previous_level + 1
	if not save_game():
		xp = previous_xp
		upgrades[key] = previous_level
		return false
	return true


func record_match(won: bool, mode: String = "", match_effects: Dictionary = {}) -> int:
	last_ip_reward = 0
	var actual_mode: String = _mode(mode)
	if _write_blocked or not _mode_available(actual_mode):
		return 0
	var previous: Dictionary = _snapshot()
	# The caller passes the effects frozen at match start, never the current equipment.
	var reward: int = match_reward(won, actual_mode, match_effects)
	reward = _credit_xp(reward)
	matches = mini(MAX_COUNTER, matches + 1)
	if won:
		wins = mini(matches, wins + 1)
	ladders[actual_mode] = clampi(int(ladders[actual_mode]) + (25 if won else -25), 0, ladder_cap(actual_mode))
	var previous_high: int = int(highest_ladders[actual_mode])
	var new_high: int = maxi(previous_high, int(ladders[actual_mode]))
	# First-time divisions only; demotion and re-promotion cannot farm IP.
	var division_limit: int = 28 if actual_mode == "ranked" else 27
	var new_divisions: int = mini(new_high / 100, division_limit) - mini(previous_high / 100, division_limit)
	var new_tiers: int = _tier_index(new_high, actual_mode) - _tier_index(previous_high, actual_mode)
	var ip_reward: int = new_divisions * DIVISION_IP + new_tiers * TIER_IP
	if won and wins > int(previous.wins) and wins % WIN_MILESTONE == 0:
		ip_reward += WIN_MILESTONE_IP
	highest_ladders[actual_mode] = new_high
	ip_reward = mini(ip_reward, MAX_COUNTER - idle_points)
	idle_points += ip_reward
	if not save_game():
		_restore(previous)
		return 0
	last_ip_reward = ip_reward
	return reward


func _tier_index(points: int, mode: String) -> int:
	if mode == "ranked" and points >= 2800:
		return 9 if points >= 3300 else (8 if points >= 3000 else 7)
	return int(points / 400)


func open_card() -> Dictionary:
	if _write_blocked:
		return {}
	if idle_points < Cards.PACK_COST:
		last_error = "IP insuficiente. Conquiste novas divisões ou complete 10 vitórias."
		return {}
	var previous: Dictionary = _snapshot()
	var card: Dictionary = Cards.draw(_card_rng, pulls_without_epic >= Cards.PITY_LIMIT - 1)
	var id: String = str(card.id)
	var duplicate: bool = collection.has(id)
	var refund: int = int(Cards.RARITIES[int(card.rarity)].refund) if duplicate else 0
	idle_points -= Cards.PACK_COST - refund
	collection[id] = mini(MAX_COUNTER, int(collection.get(id, 0)) + 1)
	pulls_without_epic = 0 if int(card.rarity) >= 2 else pulls_without_epic + 1
	if not save_game():
		_restore(previous)
		return {}
	last_error = ""
	return {"card": card, "duplicate": duplicate, "refund": refund}


func toggle_card(id: String) -> bool:
	if _write_blocked or not collection.has(id) or Cards.find_card(id).is_empty():
		return false
	var previous: Dictionary = _snapshot()
	if equipped_cards.has(id):
		equipped_cards.erase(id)
	elif equipped_cards.size() < Cards.MAX_EQUIPPED:
		equipped_cards.append(id)
	else:
		last_error = "Você já equipou 3 cartas. Remova uma para trocar."
		return false
	if not save_game():
		_restore(previous)
		return false
	last_error = ""
	return true


func combat_upgrades() -> Dictionary:
	return upgrades.duplicate(true)


func card_effects() -> Dictionary:
	return Cards.equipped_effects(equipped_cards)


func match_reward(won: bool, mode: String = "", effects: Dictionary = {}) -> int:
	var base: int = victory_reward(mode) if won else (105 if _mode(mode) == "ranked" else 70)
	var bonus: int = int(Cards.sanitize_effects(effects).get("match_xp", 0))
	return int(round(float(base) * (1.0 + float(bonus) / 100.0)))


func rank_division(mode: String = "") -> int:
	return int(int(ladders.get(_mode(mode), 0)) / 100)


func rank_lp(mode: String = "") -> int:
	return int(ladders.get(_mode(mode), 0)) % 100


func rank_name(mode: String = "") -> String:
	var division: int = rank_division(mode)
	if _mode(mode) == "ranked":
		var points: int = int(ladders.ranked)
		if points >= 3300:
			return "Challenger"
		if points >= 3000:
			return "Grão-Mestre"
		if points >= 2800:
			return "Mestre"
		return "%s %s" % [RANKED_NAMES[int(division / 4)], DIVISION_NAMES[division % 4]]
	return "%s %s" % [RANK_NAMES[int(division / 4)], DIVISION_NAMES[division % 4]]


func ladder_cap(mode: String = "") -> int:
	return RANKED_MAX_POINTS if _mode(mode) == "ranked" else MAX_LADDER_POINTS


func rank_points_text(mode: String = "") -> String:
	if _mode(mode) == "ranked" and int(ladders.ranked) >= 2800:
		return "%d pontos · sem divisões" % (int(ladders.ranked) - 2800)
	return "%d/100 pontos" % rank_lp(mode)


func victory_reward(mode: String = "") -> int:
	var base: int = int(round(120.0 * pow(1.16, rank_division(mode))))
	return int(base * 1.5) if _mode(mode) == "ranked" else base


func opponent_level(mode: String = "") -> float:
	return minf(19.5, rank_division(mode) * 0.65 + (2.0 if _mode(mode) == "ranked" else 0.0))


func training_rate() -> int:
	var rate: int = 0
	for key: String in TRAINING_ORDER:
		rate += training_production(key)
	return rate


func training_production(key: String, level: int = -1) -> int:
	if not TRAINING_ORDER.has(key):
		return 0
	if level < 0:
		level = int(training_levels[key])
	level = clampi(level, 0, MAX_TRAINING_LEVEL)
	return int(round(float(TRAINING_RATES[key]) * (pow(TRAINING_GROWTH, level) - 1.0) / (TRAINING_GROWTH - 1.0)))


func training_cost(key: String) -> int:
	if not TRAINING_ORDER.has(key):
		return -1
	var level: int = int(training_levels[key])
	if level < 0 or level >= MAX_TRAINING_LEVEL:
		return -1
	var purchased_levels: int = maxi(0, level - (1 if key == "videos" else 0))
	return int(round(float(TRAINING_COSTS[key]) * pow(TRAINING_COST_GROWTH, float(purchased_levels))))


func settle_training(now: int = -1) -> int:
	if practice_mode:
		return 0
	if _write_blocked:
		return 0
	if now < 0:
		now = _now()
	if now > MAX_TIMESTAMP or now <= training_last_at:
		return 0
	var previous: Dictionary = _snapshot()
	var seconds: int = mini(now - training_last_at, TRAINING_CAP_HOURS * 3600) if training_last_at > 0 else 0
	var numerator: int = seconds * training_rate() * 3600 + training_remainder
	var reward: int = _credit_xp(int(numerator / 3600))
	training_remainder = numerator % 3600
	training_last_at = now
	if not save_game():
		_restore(previous)
		return 0
	last_training_reward = reward
	return reward


func buy_training(key: String) -> bool:
	if _write_blocked:
		return false
	var cost: int = training_cost(key)
	if cost < 0:
		last_error = "Essa atividade não existe ou já atingiu o nível máximo."
		return false
	# Settle the previous rate first; new activities cannot earn retroactive XP.
	last_error = ""
	settle_training()
	if not last_error.is_empty():
		return false
	if not can_afford(cost):
		last_error = "XP insuficiente para essa atividade."
		return false
	var previous: Dictionary = _snapshot()
	if not practice_mode:
		xp -= cost
	training_levels[key] = int(training_levels[key]) + 1
	if not save_game():
		_restore(previous)
		return false
	return true


func can_unlock_ranked() -> bool:
	return not ranked_unlocked and rank_division("normal") >= RANKED_REQUIRED_DIVISION and can_afford(RANKED_COST) and not _write_blocked


func can_afford(cost: int) -> bool:
	return cost >= 0 and (practice_mode or xp >= cost)


func unlock_ranked() -> bool:
	if not can_unlock_ranked():
		last_error = "A Ranked exige Barro IV no Normal e 10.000 XP disponíveis."
		return false
	var previous: Dictionary = _snapshot()
	if not practice_mode:
		xp -= RANKED_COST
	ranked_unlocked = true
	if not save_game():
		_restore(previous)
		return false
	return true


func select_mode(mode: String) -> bool:
	if _write_blocked or not _mode_available(mode):
		return false
	var previous: String = selected_mode
	selected_mode = mode
	if not save_game():
		selected_mode = previous
		return false
	return true


func _mode(mode: String) -> String:
	return selected_mode if mode.is_empty() else mode


func _mode_available(mode: String) -> bool:
	return mode == "normal" or (mode == "ranked" and ranked_unlocked)


func _now() -> int:
	if time_override >= 0:
		return clampi(time_override, 0, MAX_TIMESTAMP)
	return clampi(int(Time.get_unix_time_from_system()), 0, MAX_TIMESTAMP)


func _credit_xp(amount: int) -> int:
	if practice_mode:
		return maxi(0, amount)
	var reward: int = maxi(0, mini(amount, mini(MAX_COUNTER - xp, MAX_COUNTER - lifetime_xp)))
	xp += reward
	lifetime_xp += reward
	return reward


func _snapshot() -> Dictionary:
	return {
		"schema_version": SAVE_VERSION, "xp": xp, "lifetime_xp": lifetime_xp,
		"matches": matches, "wins": wins, "upgrades": upgrades.duplicate(true),
		"training_levels": training_levels.duplicate(true), "training_last_at": training_last_at,
		"training_remainder": training_remainder, "selected_mode": selected_mode,
		"ranked_unlocked": ranked_unlocked, "ladders": ladders.duplicate(true),
		"idle_points": idle_points, "collection": collection.duplicate(true),
		"equipped_cards": equipped_cards.duplicate(), "pulls_without_epic": pulls_without_epic,
		"highest_ladders": highest_ladders.duplicate(true),
	}


func _restore(data: Dictionary) -> void:
	xp = int(data["xp"])
	lifetime_xp = int(data["lifetime_xp"])
	matches = int(data["matches"])
	wins = int(data["wins"])
	for key: String in SKILL_ORDER:
		upgrades[key] = int(data["upgrades"][key])
	for key: String in TRAINING_ORDER:
		training_levels[key] = int(data["training_levels"][key])
	training_last_at = int(data["training_last_at"])
	training_remainder = int(data["training_remainder"])
	selected_mode = str(data["selected_mode"])
	ranked_unlocked = bool(data["ranked_unlocked"])
	for mode: String in ["normal", "ranked"]:
		ladders[mode] = int(data["ladders"][mode])
	# Older saves begin with an empty collection and their existing rank as the high-water mark.
	var has_cards: bool = int(data["schema_version"]) >= 5
	idle_points = int(data["idle_points"]) if has_cards else 0
	collection = {}
	if has_cards:
		for id: String in data["collection"]:
			collection[id] = int(data["collection"][id])
	equipped_cards.clear()
	for id: String in (data["equipped_cards"] if has_cards else []):
		equipped_cards.append(id)
	pulls_without_epic = int(data["pulls_without_epic"]) if has_cards else 0
	for mode: String in ["normal", "ranked"]:
		highest_ladders[mode] = int(data["highest_ladders"][mode]) if has_cards else int(ladders[mode])


func _migrate_hourly_training(data: Dictionary) -> void:
	var hourly_rate: int = 0
	if int(data["schema_version"]) == 2:
		data["training_levels"] = {}
		for key: String in TRAINING_ORDER:
			var owned: bool = bool(data["training_owned"][key])
			data["training_levels"][key] = 1 if owned else 0
			if owned:
				hourly_rate += int(LEGACY_TRAINING_RATES[key])
	else:
		for key: String in TRAINING_ORDER:
			hourly_rate += int(data["training_levels"][key]) * int(TRAINING_RATES[key]) * 3600
	_restore(data)
	var previous: Dictionary = _snapshot()
	var now: int = _now()
	var reward: int = 0
	if now > training_last_at:
		var seconds: int = mini(now - training_last_at, TRAINING_CAP_HOURS * 3600) if training_last_at > 0 else 0
		var numerator: int = seconds * hourly_rate + training_remainder
		reward = _credit_xp(int(numerator / 3600))
		training_remainder = numerator % 3600
		training_last_at = now
	if not save_game():
		_restore(previous)
		# Keep the old file intact and prevent new rates being applied to its old clock.
		_write_blocked = true
		return
	last_training_reward = reward


func _block_writes(message: String) -> void:
	_write_blocked = true
	last_error = message


func _valid_snapshot(data: Dictionary) -> bool:
	if not _whole_number(data.get("schema_version"), 1, SAVE_VERSION):
		return false
	for key: String in ["xp", "lifetime_xp", "matches", "wins"]:
		if not _whole_number(data.get(key), 0, MAX_COUNTER):
			return false
	if int(data["lifetime_xp"]) < int(data["xp"]) or int(data["wins"]) > int(data["matches"]):
		return false
	if not data.get("upgrades") is Dictionary:
		return false
	var saved_upgrades: Dictionary = data["upgrades"]
	for key: String in SKILL_ORDER:
		if not _whole_number(saved_upgrades.get(key), 0, MAX_LEVEL):
			return false
	if int(data["schema_version"]) == 1:
		return true
	if not data.get("ladders") is Dictionary:
		return false
	if int(data["schema_version"]) == 2:
		if not data.get("training_owned") is Dictionary:
			return false
		for key: String in TRAINING_ORDER:
			if typeof(data["training_owned"].get(key)) != TYPE_BOOL:
				return false
		if not bool(data["training_owned"]["videos"]):
			return false
	else:
		if not data.get("training_levels") is Dictionary:
			return false
		for key: String in TRAINING_ORDER:
			if not _whole_number(data["training_levels"].get(key), 1 if key == "videos" else 0, MAX_TRAINING_LEVEL):
				return false
	for mode: String in ["normal", "ranked"]:
		if not _whole_number(data["ladders"].get(mode), 0, ladder_cap(mode) if int(data["schema_version"]) >= 4 else MAX_LADDER_POINTS):
			return false
	if not _whole_number(data.get("training_last_at"), 0, MAX_TIMESTAMP):
		return false
	if not _whole_number(data.get("training_remainder"), 0, 3599):
		return false
	if typeof(data.get("ranked_unlocked")) != TYPE_BOOL:
		return false
	if data.get("selected_mode") not in ["normal", "ranked"]:
		return false
	if not bool(data["ranked_unlocked"]) and (data["selected_mode"] == "ranked" or int(data["ladders"]["ranked"]) > 0):
		return false
	if int(data["schema_version"]) >= 5 and not _valid_cards(data):
		return false
	return true


func _valid_cards(data: Dictionary) -> bool:
	if not _whole_number(data.get("idle_points"), 0, MAX_COUNTER):
		return false
	if not _whole_number(data.get("pulls_without_epic"), 0, Cards.PITY_LIMIT - 1):
		return false
	if not data.get("collection") is Dictionary or not data.get("equipped_cards") is Array:
		return false
	var owned: Dictionary = data["collection"]
	for id: Variant in owned:
		if not id is String or Cards.find_card(id).is_empty() or not _whole_number(owned[id], 1, MAX_COUNTER):
			return false
	var equipped: Array = data["equipped_cards"]
	if equipped.size() > Cards.MAX_EQUIPPED:
		return false
	var seen: Array[String] = []
	for id: Variant in equipped:
		if not id is String or not owned.has(id) or seen.has(id):
			return false
		seen.append(id)
	if not data.get("highest_ladders") is Dictionary:
		return false
	for mode: String in ["normal", "ranked"]:
		if not _whole_number(data["highest_ladders"].get(mode), int(data["ladders"][mode]), ladder_cap(mode)):
			return false
	if not bool(data["ranked_unlocked"]) and int(data["highest_ladders"].ranked) > 0:
		return false
	return true


func _whole_number(value: Variant, minimum: int, maximum: int) -> bool:
	# JSON numbers are floats, while the in-memory snapshot uses integers.
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number: float = float(value)
	return is_finite(number) and number >= minimum and number <= maximum and number == floor(number)
