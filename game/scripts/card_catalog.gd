extends RefCounted
## One roll buys one card. Rates are per rarity, then uniform within that rarity.
const PACK_COST: int = 100
const PITY_LIMIT: int = 10
const MAX_EQUIPPED: int = 3
const RARITIES: Array[Dictionary] = [
	{"name": "Normal", "weight": 60, "color": "a5b6c4", "refund": 10},
	{"name": "Rara", "weight": 25, "color": "70c5ff", "refund": 20},
	{"name": "Épica", "weight": 10, "color": "c298ff", "refund": 35},
	{"name": "Lendária", "weight": 4, "color": "f1c779", "refund": 50},
	{"name": "Mítica", "weight": 1, "color": "ff818d", "refund": 75},
]
const CARDS: Array[Dictionary] = [
	{"id": "blade", "name": "Lâmina de treino", "rarity": 0, "sigil": "I", "skill": "trades", "bonus": 1},
	{"id": "coin", "name": "Moeda da rota", "rarity": 0, "sigil": "II", "skill": "farm", "bonus": 1},
	{"id": "ward", "name": "Sentinela atenta", "rarity": 0, "sigil": "III", "skill": "vision", "bonus": 1},
	{"id": "boots", "name": "Passos do estrategista", "rarity": 1, "sigil": "IV", "skill": "macro", "bonus": 2},
	{"id": "shield", "name": "Escudo do guardião", "rarity": 1, "sigil": "V", "skill": "builds", "bonus": 2},
	{"id": "harvest", "name": "Colheita dourada", "rarity": 1, "sigil": "VI", "skill": "farm", "bonus": 2},
	{"id": "duelist", "name": "Fúria do duelista", "rarity": 2, "sigil": "VII", "skill": "trades", "bonus": 3},
	{"id": "oracle", "name": "Olho do oráculo", "rarity": 2, "sigil": "VIII", "skill": "vision", "bonus": 3},
	{"id": "siege", "name": "Plano de cerco", "rarity": 2, "sigil": "IX", "skill": "macro", "bonus": 3},
	{"id": "crown", "name": "Coroa do artífice", "rarity": 3, "sigil": "X", "skill": "builds", "bonus": 4},
	{"id": "dragon", "name": "Tesouro do dragão", "rarity": 3, "sigil": "XI", "skill": "farm", "bonus": 4},
	{"id": "storm", "name": "Lâmina da tempestade", "rarity": 3, "sigil": "XII", "skill": "trades", "bonus": 4},
	{"id": "nexus", "name": "Coração do nexo", "rarity": 4, "sigil": "XIII", "skill": "builds", "bonus": 5},
	{"id": "eternal", "name": "Visão do infinito", "rarity": 4, "sigil": "XIV", "skill": "vision", "bonus": 5},
	{"id": "sovereign", "name": "Comando soberano", "rarity": 4, "sigil": "XV", "skill": "macro", "bonus": 5},
]

static func find_card(id: String) -> Dictionary:
	for card: Dictionary in CARDS:
		if card.id == id:
			return card
	return {}

static func draw(rng: RandomNumberGenerator, guaranteed: bool) -> Dictionary:
	# On the guaranteed draw, normalize the 10:4:1 epic/legendary/mythic weights.
	var roll: int = rng.randi_range(1, 15 if guaranteed else 100)
	var rarity: int = 2 if guaranteed else 0
	while roll > int(RARITIES[rarity].weight):
		roll -= int(RARITIES[rarity].weight)
		rarity += 1
	var candidates: Array[Dictionary] = []
	for card: Dictionary in CARDS:
		if int(card.rarity) == rarity:
			candidates.append(card)
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)
