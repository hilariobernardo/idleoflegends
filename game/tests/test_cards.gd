extends SceneTree

const Progression = preload("res://scripts/progression.gd")
const Cards = preload("res://scripts/card_catalog.gd")
const SAVE_PATH: String = "res://tests/tmp_cards.json"
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_cleanup()
	_rewards()
	_draws_and_equipment()
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
	_check(bool(result["duplicate"]) and p.idle_points == int(Cards.RARITIES[rarity].refund), "Duplicates refund the correct rarity amount")
	_check(int(p.collection[result.card.id]) == 2, "Duplicate count is recorded")
	_check(p.toggle_card("blade") and p.toggle_card("duelist") and p.toggle_card("storm"), "Three distinct cards can be equipped")
	_check(not p.toggle_card("coin") and not p.toggle_card("missing"), "Fourth and unknown cards are rejected")
	_check(p.combat_upgrades().trades == 8 and p.upgrades.trades == 0, "Bonuses stack without changing purchased levels")
	p.collection.blade = 100
	_check(p.combat_upgrades().trades == 8, "Duplicate copies do not multiply combat bonuses")
	_check(p.toggle_card("blade") and p.toggle_card("coin"), "Removing a card frees a slot")
	_check(p.combat_upgrades().trades == 7 and p.combat_upgrades().farm == 1, "Changing equipment updates the effective skills")
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
	_check(p.open_card().is_empty() and p._snapshot() == before, "Failed save restores a draw atomically")
	_check(not p.toggle_card("oracle") and p._snapshot() == before, "Failed save restores equipment")
	_check(p.record_match(true) == 0 and p._snapshot() == before and p.last_ip_reward == 0, "Failed save restores match rewards")
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
