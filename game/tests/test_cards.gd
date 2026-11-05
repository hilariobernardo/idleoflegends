extends SceneTree

const Progression = preload("res://scripts/progression.gd")
const Cards = preload("res://scripts/card_catalog.gd")
const Simulation = preload("res://scripts/match_sim.gd")
const SAVE_PATH: String = "res://tests/tmp_cards.json"
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_cleanup()
	_rewards()
	_draws_and_equipment()
	_levels_and_maxed_pool()
	_percentage_effects()
	_persistence_and_rollback()
	_practice_reset()
	_cleanup()
	print("%s cards/IP: %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _fresh():
	_cleanup()
	var progress = Progression.new()
	progress.save_path = SAVE_PATH
	progress.time_override = 1_800_000_000
	progress.load_save()
	return progress

func _rewards() -> void:
	var p = _fresh()
	_check(p.idle_points == 0 and p.open_card().is_empty(), "A fresh player cannot buy without IP")
	for i: int in range(4):
		p.record_match(true)
	_check(p.idle_points == 25 and p.last_ip_reward == 25, "First division grants 25 IP")
	p.record_match(false)
	p.record_match(true)
	_check(p.idle_points == 25 and p.last_ip_reward == 0, "Re-promotion does not duplicate IP")
	p = _fresh()
	for i: int in range(16):
		p.record_match(true)
	_check(p.idle_points == 225, "16 wins: four divisions + one tier + ten-win milestone = 225 IP")
	_check(p.last_ip_reward == 100, "New tier grants 75 IP plus 25 for its division")
	_check(p.upgrades.farm == 0 and p.xp > 0, "IP rewards preserve XP and skill progression")
	p.ranked_unlocked = true
	p.ladders.ranked = 2975
	p.highest_ladders.ranked = 2975
	p.record_match(true, "ranked")
	_check(p.last_ip_reward == 75, "Grandmaster grants tier IP without a fictional division")
	p.ladders.ranked = 3275
	p.highest_ladders.ranked = 3275
	p.record_match(true, "ranked")
	_check(p.last_ip_reward == 75, "Challenger grants 75 IP")
	var before: int = p.idle_points
	p.settle_training(p.training_last_at + 60)
	_check(p.idle_points == before, "Studies do not generate IP")

func _draws_and_equipment() -> void:
	var p = _fresh()
	p.idle_points = 100
	p._card_rng.seed = 42
	var result: Dictionary = p.open_card()
	_check(not result.is_empty() and p.idle_points == 0, "A first draw spends exactly 100 IP")
	_check(p.collection.size() == 1 and not bool(result["duplicate"]), "First draw adds a new card")
	var snapshot: Dictionary = p._snapshot()
	_check(p.open_card().is_empty() and p._snapshot() == snapshot, "Insufficient IP never changes collection or guarantee")
	for card: Dictionary in Cards.CARDS:
		p.collection[card.id] = 1
	p.idle_points = 100
	p.pulls_without_epic = 9
	result = p.open_card()
	var rarity: int = int(result.card.rarity)
	_check(rarity >= 2 and p.pulls_without_epic == 0, "Tenth draw guarantees epic or better and resets pity")
	_check(bool(result["duplicate"]) and p.idle_points == 0, "A duplicate costs 100 IP without a refund")
	_check(int(p.collection[result.card.id]) == 2 and result.previous_level == 1 and result.level == 2, "A duplicate upgrades the card exactly one level")
	for id: String in ["blade", "duelist", "storm"]:
		p.collection[id] = 1
	_check(p.toggle_card("blade") and p.toggle_card("duelist") and p.toggle_card("storm"), "Three distinct cards can be equipped")
	_check(not p.toggle_card("coin") and not p.toggle_card("missing"), "Fourth and unknown cards are rejected")
	_check(p.combat_upgrades() == p.upgrades and p.card_effects() == {"champion_damage": 6, "attack_speed": 12, "crit_chance": 20}, "Cards provide distinct effects without skill levels")
	p.collection.blade = Cards.MAX_CARD_LEVEL
	_check(p.card_effects().champion_damage == 12, "Max-level cards double their base effect without changing skills")
	_check(p.toggle_card("blade") and p.toggle_card("coin"), "Removing a card frees a slot")
	_check(not p.card_effects().has("champion_damage") and p.card_effects().gold_gain == 8 and p.combat_upgrades() == p.upgrades, "Equipment changes effects, never skills")
	# Deterministic samples exercise both ordinary draws and the guaranteed pool.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2026
	var seen: Dictionary = {}
	for i: int in range(1000):
		var card: Dictionary = Cards.draw(rng, false)
		seen[int(card.rarity)] = true
		_check(not Cards.find_card(str(card.id)).is_empty(), "Draw belongs to catalog")
		_check(int(Cards.draw(rng, true).rarity) >= 2, "Guaranteed pool excludes normal and rare")
	_check(seen.size() == 5, "All five rarities are reachable")

func _levels_and_maxed_pool() -> void:
	var p = _fresh()
	for card: Dictionary in Cards.CARDS:
		p.collection[card.id] = Cards.MAX_CARD_LEVEL
	p.collection.erase("harvest")
	p.idle_points = 1000
	p.pulls_without_epic = 9
	var frozen: Dictionary = {}
	for expected_level: int in range(1, Cards.MAX_CARD_LEVEL + 1):
		var before: int = p.idle_points
		var result: Dictionary = p.open_card()
		_check(not result.is_empty() and result.card.id == "harvest", "Only the remaining non-maxed card can be drawn, even when epic+ is exhausted")
		_check(p.idle_points == before - 100 and p.collection.harvest == expected_level, "Each purchase charges once and grants one level")
		_check(result.effects.match_xp == [12, 15, 18, 21, 24][expected_level - 1], "XP bonus grows with the awarded level")
		_check(p.pulls_without_epic == 9, "Exhausted epic pool never overflows the pity counter")
		if expected_level == 1:
			p.toggle_card("harvest")
			frozen = p.card_effects()
	_check(p.card_effects().match_xp == 24 and frozen.match_xp == 12, "Leveling equipment does not mutate an existing match snapshot")
	_check(p.match_reward(true, "normal", frozen) == 134, "Ongoing match XP retains the level from its start")
	var snapshot: Dictionary = p._snapshot()
	var rng_state: int = p._card_rng.state
	_check(p.open_card().is_empty() and p._snapshot() == snapshot and p._card_rng.state == rng_state, "A fully maxed collection spends nothing and consumes no RNG")
	_check(Cards.draw(p._card_rng, true, p.collection).is_empty(), "A complete catalog has no fallback to a maxed card")
	# Pity must still choose an eligible epic+ even when lower rarities are available.
	p.collection.blade = 1
	p.collection.oracle = 4
	p.idle_points = 100
	var guaranteed: Dictionary = p.open_card()
	_check(guaranteed.card.id == "oracle" and p.collection.oracle == 5 and p.pulls_without_epic == 0, "Guarantee respects maxed cards and upgrades the last eligible epic")
	var restored = Progression.new()
	restored.save_path = SAVE_PATH
	restored.time_override = p.time_override
	restored.load_save()
	_check(restored.collection == p.collection and restored.card_effects() == p.card_effects(), "Upgraded effects survive a save and reload")

func _sim(effects: Dictionary = {}):
	var sim = Simulation.new()
	sim.start({"farm": 0, "trades": 0, "builds": 0, "macro": 0, "vision": 0}, 2026, 0.0, "Normal", effects)
	return sim

func _duel(effects: Dictionary = {}):
	var sim = _sim(effects)
	for unit: Dictionary in sim.units:
		unit.alive = int(unit.id) in [0, 5]
		unit.respawn_left = 999.0
		unit.cooldown = 0.0
	sim.units[0].progress = 0.5
	sim.units[5].progress = 0.51
	sim.advance(0.1)
	return sim

func _monster_hit(sim, key: String) -> float:
	var unit: Dictionary = sim.units[0]
	unit.objective = key
	unit.position = sim.objectives[key].position
	unit.cooldown = 0.0
	var damage: Array[float] = []
	damage.resize(10)
	damage.fill(0.0)
	var monster_damage: Dictionary = {"dragon": [0.0, 0.0], "baron": [0.0, 0.0]}
	sim._attack_objective(unit, damage, monster_damage)
	return float(monster_damage[key][0])

func _percentage_effects() -> void:
	var p = _fresh()
	for card: Dictionary in Cards.CARDS:
		p.collection[card.id] = 1
		_check(not card.has("bonus") and not card.has("skill") and not Cards.describe_effects(card.effects).is_empty(), "Every card has independent described effects")
	p.equipped_cards.assign(["coin", "crown", "eternal"])
	_check(p.card_effects() == {"gold_gain": 28, "match_xp": 35, "respawn_reduction": 10}, "Matching percentages add across distinct cards")
	var frozen: Dictionary = p.card_effects()
	p.toggle_card("eternal")
	_check(p.record_match(true, "normal", frozen) == 162, "Victory XP uses the starting loadout (120 + 35%)")
	_check(p.record_match(false, "normal", frozen) == 95, "Defeat XP also gets the frozen bonus with rounding")
	_check(p.idle_points == 0, "XP cards do not inflate IP")
	var base = _sim()
	var richer = _sim({"gold_gain": 28, "movement_speed": 10})
	base.advance(1.0)
	richer.advance(1.0)
	_check(is_equal_approx(richer.units[0].gold, base.units[0].gold * 1.28), "Lane farming gains 28% more gold")
	_check(is_equal_approx(richer.units[5].gold, base.units[5].gold), "Enemy gold stays unchanged")
	_check(is_equal_approx(richer.units[0].progress - 0.04, (base.units[0].progress - 0.04) * 1.1), "Movement effect advances the team 10% faster")
	_check(is_equal_approx(richer.units[5].progress, base.units[5].progress), "Enemy movement stays unchanged")
	richer._grant_team_gold(0, 12.0)
	_check(is_equal_approx(richer.units[0].gold, base.units[0].gold * 1.28 + 15.36), "Kill/structure gold grants also receive the bonus")
	var jungler: Dictionary = richer.units[1]
	var before: float = jungler.gold
	jungler.route = PackedVector2Array()
	jungler.route_index = 0
	jungler.camp_timer = Simulation.CAMP_CLEAR_SECONDS
	richer._advance_jungle(jungler)
	_check(is_equal_approx(jungler.gold - before, 18.0 * 1.28), "Jungle camp gold receives the bonus")
	var healthy = _sim({"max_health": 12, "base_health": 25, "respawn_reduction": 15})
	_check(is_equal_approx(healthy.units[0].max_hp, 145.6) and healthy.units[5].max_hp == 130.0, "Player health increases only on the allied team")
	_check(healthy.base_hp[0] == 1250.0 and healthy.base_max_hp[0] == 1250.0 and healthy.base_hp[1] == 1000.0, "Nexus health and its health bar denominator grow together")
	_check(is_equal_approx(healthy._score(0), healthy._score(1)), "Extra nexus health does not grant unearned tiebreak points")
	healthy._defeat(healthy.units[0])
	_check(is_equal_approx(healthy.units[0].respawn_left, 5.1), "Respawn takes 15% less time")
	healthy._respawn(healthy.units[0])
	_check(is_equal_approx(healthy.units[0].hp, 145.6), "Respawn restores boosted maximum health")
	var ordinary = _duel()
	var empowered = _duel({"champion_damage": 6, "damage_reduction": 5, "attack_speed": 12})
	_check(is_equal_approx(130.0 - empowered.units[5].hp, (130.0 - ordinary.units[5].hp) * 1.06), "Damage against players is 6% higher")
	_check(is_equal_approx(130.0 - empowered.units[0].hp, (130.0 - ordinary.units[0].hp) * 0.95), "Incoming player damage is reduced by 5%")
	_check(is_equal_approx(empowered.units[0].cooldown, 0.85 / 1.12), "Actual attacks use the shorter attack interval")
	var normal_objectives = _sim()
	var hunter = _sim({"objective_damage": 50})
	for key: String in ["dragon", "baron"]:
		_check(is_equal_approx(_monster_hit(hunter, key), _monster_hit(normal_objectives, key) * 1.5), "Objective damage increases against " + key)
	var no_player_bonus = _duel({"objective_damage": 50})
	_check(is_equal_approx(no_player_bonus.units[5].hp, ordinary.units[5].hp), "Objective-only bonus does not increase player damage")
	var sieger = _sim({"structure_damage": 45})
	for sim in [base, sieger]:
		for unit: Dictionary in sim.units:
			unit.alive = int(unit.id) == 0
			unit.respawn_left = 999.0
		sim.units[0].progress = 0.71
		sim.units[0].cooldown = 0.0
		sim.units[0].gold = 0.0
		sim._rng.seed = 42
		sim.advance(0.1)
	_check(is_equal_approx(260.0 - sieger.towers[3].hp, (260.0 - base.towers[3].hp) * 1.45), "Structure damage increases actual tower damage")
	sieger.baron_until[0] = 20.0
	_check(is_equal_approx(sieger._structure_bonus(0), 1.45 * 1.3), "Card and Baron bonuses compose independently")
	var critical = _sim({"crit_chance": 100})
	var plain = _sim()
	_check(is_equal_approx(critical._attack_damage(critical.units[0]), plain._attack_damage(plain.units[0]) * 1.5), "A critical attack deals 50% extra damage")
	var source: Dictionary = {"gold_gain": 20}
	var isolated = _sim(source)
	source.gold_gain = 90
	_check(isolated.card_effects.gold_gain == 20, "Match effects are isolated from later equipment edits")
	isolated.start(p.combat_upgrades(), 2026)
	_check(isolated.card_effects.is_empty() and isolated.base_hp[0] == 1000.0, "Starting a new match clears old card effects")

func _persistence_and_rollback() -> void:
	var p = _fresh()
	p.idle_points = 250
	p.collection = {"oracle": 2}
	p.equipped_cards.assign(["oracle"])
	p.pulls_without_epic = 8
	p.ladders.normal = 375
	p.highest_ladders.normal = 400
	_check(p.save_game(), "New card state saves")
	var restored = Progression.new()
	restored.save_path = SAVE_PATH
	restored.time_override = p.time_override
	restored.load_save()
	for key: String in p._snapshot():
		if restored._snapshot()[key] != p._snapshot()[key]:
			print("Reload mismatch: %s expected=%s actual=%s" % [key, p._snapshot()[key], restored._snapshot()[key]])
	_check(restored._snapshot() == p._snapshot(), "Wallet, collection, equipment, guarantee and records survive reload")
	p.save_path = "res://tests/missing_cards_directory/save.json"
	var before: Dictionary = p._snapshot()
	var rng_state: int = p._card_rng.state
	_check(p.open_card().is_empty() and p._snapshot() == before, "Failed save restores a draw atomically")
	_check(p._card_rng.state == rng_state, "Failed save restores the next draw as well")
	_check(not p.toggle_card("oracle") and p._snapshot() == before, "Failed save restores equipment")
	_check(p.record_match(true) == 0 and p._snapshot() == before and p.last_ip_reward == 0, "Failed save restores match rewards")
	var legacy_cards: Dictionary = restored._snapshot()
	legacy_cards.schema_version = 5
	legacy_cards.collection = {"oracle": 2, "blade": 50}
	_write(legacy_cards)
	restored.load_save()
	_check(restored.collection == {"oracle": 2, "blade": 5} and restored.equipped_cards == ["oracle"] and restored.idle_points == 250, "v5 copies become capped levels while equipment and IP survive")
	var invalid_level: Dictionary = restored._snapshot()
	invalid_level.collection.oracle = Cards.MAX_CARD_LEVEL + 1
	_check(not restored._valid_snapshot(invalid_level), "v6 rejects over-max card levels")
	var legacy: Dictionary = restored._snapshot()
	legacy.schema_version = 4
	for key: String in ["idle_points", "collection", "equipped_cards", "pulls_without_epic", "highest_ladders"]:
		legacy.erase(key)
	_write(legacy)
	restored.load_save()
	_check(restored.idle_points == 0 and restored.collection.is_empty() and restored.highest_ladders.normal == 375, "v4 migration starts empty and preserves current rank")
	restored.record_match(true)
	_check(restored.last_ip_reward == 100, "Migrated player earns only new promotions")
	var invalid: Dictionary = restored._snapshot()
	invalid.equipped_cards = ["not_owned"]
	_write(invalid)
	var raw: String = FileAccess.get_file_as_string(SAVE_PATH)
	restored.load_save()
	_check(not restored.last_error.is_empty() and not restored.save_game(), "Invalid card save blocks writes")
	_check(FileAccess.get_file_as_string(SAVE_PATH) == raw, "Invalid save is preserved")

func _practice_reset() -> void:
	var p = _fresh()
	var raw: String = FileAccess.get_file_as_string(SAVE_PATH)
	p.practice_mode = true
	p.load_save()
	_check(p.idle_points == 300 and p.xp == p.MAX_COUNTER, "Practice starts with finite 300 IP and unlimited XP")
	var result: Dictionary = p.open_card()
	p.toggle_card(str(result.card.id))
	_check(p.idle_points == 200, "Practice still charges IP")
	_check(FileAccess.get_file_as_string(SAVE_PATH) == raw, "Practice cards do not write to disk")
	p.load_save()
	_check(p.idle_points == 300 and p.collection.is_empty() and p.equipped_cards.is_empty() and p.pulls_without_epic == 0, "Reset clears all card state")

func _write(data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _cleanup() -> void:
	for path: String in [SAVE_PATH, SAVE_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
