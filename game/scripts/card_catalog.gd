extends RefCounted
## One roll buys one card. Rates are per rarity, then uniform within that rarity.
const PACK_COST: int = 100
const PITY_LIMIT: int = 10
const MAX_EQUIPPED: int = 3
const MAX_CARD_LEVEL: int = 5
const EFFECT_GROWTH_PER_LEVEL: float = 0.25
const RARITIES: Array[Dictionary] = [
	{"name": "Normal", "weight": 60, "color": "a5b6c4"},
	{"name": "Rara", "weight": 25, "color": "70c5ff"},
	{"name": "Épica", "weight": 10, "color": "c298ff"},
	{"name": "Lendária", "weight": 4, "color": "f1c779"},
	{"name": "Mítica", "weight": 1, "color": "ff818d"},
]
# Percentage-point bonuses. Equal effects add; distinct effects apply independently.
const EFFECT_LABELS: Dictionary = {
	"champion_damage": "+%d%% de dano contra jogadores",
	"gold_gain": "+%d%% de ouro na partida",
	"damage_reduction": "−%d%% de dano recebido pelos jogadores",
	"movement_speed": "+%d%% de velocidade de movimento",
	"max_health": "+%d%% de vida dos jogadores",
	"match_xp": "+%d%% de XP ao terminar partidas",
	"attack_speed": "+%d%% de velocidade de ataque",
	"respawn_reduction": "−%d%% no tempo de renascimento",
	"structure_damage": "+%d%% de dano contra torres e nexo",
	"objective_damage": "+%d%% de dano contra Dragon e Baron",
	"crit_chance": "%d%% de chance de crítico (+50%% de dano)",
	"base_health": "+%d%% de vida do seu nexo",
}
const EFFECT_CAPS: Dictionary = {
	"champion_damage": 100, "gold_gain": 100, "damage_reduction": 50,
	"movement_speed": 100, "max_health": 100, "match_xp": 100,
	"attack_speed": 100, "respawn_reduction": 50, "structure_damage": 100,
	"objective_damage": 100, "crit_chance": 100, "base_health": 100,
}
const CARDS: Array[Dictionary] = [
	{"id": "blade", "name": "Lâmina de treino", "rarity": 0, "sigil": "I", "icon": "trades", "effects": {"champion_damage": 6}},
	{"id": "coin", "name": "Moeda da rota", "rarity": 0, "sigil": "II", "icon": "farm", "effects": {"gold_gain": 8}},
	{"id": "ward", "name": "Sentinela atenta", "rarity": 0, "sigil": "III", "icon": "vision", "effects": {"damage_reduction": 5}},
	{"id": "boots", "name": "Passos do estrategista", "rarity": 1, "sigil": "IV", "icon": "macro", "effects": {"movement_speed": 10}},
	{"id": "shield", "name": "Escudo do guardião", "rarity": 1, "sigil": "V", "icon": "builds", "effects": {"max_health": 12}},
	{"id": "harvest", "name": "Colheita dourada", "rarity": 1, "sigil": "VI", "icon": "farm", "effects": {"match_xp": 12}},
	{"id": "duelist", "name": "Fúria do duelista", "rarity": 2, "sigil": "VII", "icon": "trades", "effects": {"attack_speed": 12}},
	{"id": "oracle", "name": "Olho do oráculo", "rarity": 2, "sigil": "VIII", "icon": "vision", "effects": {"respawn_reduction": 15}},
	{"id": "siege", "name": "Plano de cerco", "rarity": 2, "sigil": "IX", "icon": "macro", "effects": {"structure_damage": 20}},
	{"id": "crown", "name": "Coroa do artífice", "rarity": 3, "sigil": "X", "icon": "builds", "effects": {"gold_gain": 20, "match_xp": 10}},
	{"id": "dragon", "name": "Tesouro do dragão", "rarity": 3, "sigil": "XI", "icon": "farm", "effects": {"objective_damage": 30}},
	{"id": "storm", "name": "Lâmina da tempestade", "rarity": 3, "sigil": "XII", "icon": "trades", "effects": {"crit_chance": 20}},
	{"id": "nexus", "name": "Coração do nexo", "rarity": 4, "sigil": "XIII", "icon": "builds", "effects": {"base_health": 25}},
	{"id": "eternal", "name": "Visão do infinito", "rarity": 4, "sigil": "XIV", "icon": "vision", "effects": {"match_xp": 25, "respawn_reduction": 10}},
	{"id": "sovereign", "name": "Comando soberano", "rarity": 4, "sigil": "XV", "icon": "macro", "effects": {"objective_damage": 20, "structure_damage": 25}},
]

static func level_effects(card: Dictionary, level: int) -> Dictionary:
	if level <= 0:
		return {}
	var multiplier: float = 1.0 + (clampi(level, 1, MAX_CARD_LEVEL) - 1) * EFFECT_GROWTH_PER_LEVEL
	var effects: Dictionary = {}
	for effect: String in card.get("effects", {}):
		effects[effect] = roundi(int(card.effects[effect]) * multiplier)
	return sanitize_effects(effects)

static func equipped_effects(ids: Array[String], levels: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var seen: Array[String] = []
	for id: String in ids:
		if seen.has(id) or seen.size() >= MAX_EQUIPPED:
			continue
		var card: Dictionary = find_card(id)
		if card.is_empty():
			continue
		seen.append(id)
		var effects: Dictionary = level_effects(card, int(levels.get(id, 0)))
		for effect: String in effects:
			result[effect] = int(result.get(effect, 0)) + int(effects[effect])
	return sanitize_effects(result)

static func sanitize_effects(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in EFFECT_CAPS:
		var value: Variant = source.get(key, 0)
		if (typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT) and is_finite(float(value)):
			var amount: int = clampi(int(value), 0, int(EFFECT_CAPS[key]))
			if amount > 0:
				result[key] = amount
	return result

static func describe_effects(effects: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	for key: String in EFFECT_LABELS:
		if int(effects.get(key, 0)) > 0:
			lines.append(str(EFFECT_LABELS[key]) % int(effects[key]))
	return "\n".join(lines)

static func find_card(id: String) -> Dictionary:
	for card: Dictionary in CARDS:
		if card.id == id:
			return card
	return {}

static func available_cards(levels: Dictionary, minimum_rarity: int = 0) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for card: Dictionary in CARDS:
		if int(card.rarity) >= minimum_rarity and int(levels.get(card.id, 0)) < MAX_CARD_LEVEL:
			candidates.append(card)
	return candidates

static func draw(rng: RandomNumberGenerator, guaranteed: bool, levels: Dictionary = {}) -> Dictionary:
	var candidates: Array[Dictionary] = available_cards(levels, 2 if guaranteed else 0)
	# When every epic+ card is maxed, keep improving the remaining rarities.
	if candidates.is_empty() and guaranteed:
		candidates = available_cards(levels)
	if candidates.is_empty():
		return {}
	# Remove maxed cards before drawing: no retries, wasted pulls or extra charges.
	# Keep rarity weights until that entire rarity is maxed, then renormalize.
	var pools: Dictionary = {}
	var total_weight: int = 0
	for card: Dictionary in candidates:
		var rarity: int = int(card.rarity)
		if not pools.has(rarity):
			pools[rarity] = []
			total_weight += int(RARITIES[rarity].weight)
		pools[rarity].append(card)
	var roll: int = rng.randi_range(1, total_weight)
	for rarity: int in pools:
		roll -= int(RARITIES[rarity].weight)
		if roll <= 0:
			var pool: Array = pools[rarity]
			return pool[rng.randi_range(0, pool.size() - 1)].duplicate(true)
	return {}
