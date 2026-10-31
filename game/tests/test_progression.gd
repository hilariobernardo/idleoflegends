extends SceneTree

const Progression = preload("res://scripts/progression.gd")
const TEST_PATH: String = "res://tests/tmp_progression_isolated.json"
var failures: int = 0


func _initialize() -> void:
	_cleanup()
	_test_roundtrip_and_purchase()
	_test_malformed_and_invalid_saves()
	_test_future_schema()
	_test_save_failure_rolls_back_purchase()
	_cleanup()
	if failures == 0:
		print("PASS progression: rewards, purchases, roundtrip, validation, future schema, failed-write rollback")
	else:
		push_error("FAIL progression: %d assertion(s)" % failures)
	quit(0 if failures == 0 else 1)


func _test_roundtrip_and_purchase() -> void:
	var progress = _new_progress()
	progress.save_path = TEST_PATH
	progress.load_save()
	_expect(progress.xp == 0 and progress.last_error.is_empty(), "Missing save starts clean")
	_expect(not progress.buy_upgrade("farm"), "Cannot spend missing XP")
	_expect(progress.xp == 0, "Rejected purchase never makes XP negative")
	_expect(progress.record_match(true) == 120, "Victory earns provisional 120 XP")
	_expect(progress.record_match(false) == 70, "Defeat earns provisional 70 XP")
	_expect(progress.buy_upgrade("farm"), "Affordable upgrade succeeds")
	_expect(progress.xp == 130 and progress.upgrades["farm"] == 1, "Purchase deducts exact cost")
	_expect(progress.upgrade_cost("farm") == 120, "Next upgrade price scales")
	_expect(not progress.buy_upgrade("unknown"), "Unknown skills are rejected")
	_expect(progress.xp == 130, "Invalid skill does not spend XP")
	var restored = _new_progress()
	restored.save_path = TEST_PATH
	restored.load_save()
	_expect(restored.last_error.is_empty(), "Saved data validates")
	_expect(restored.xp == 130 and restored.lifetime_xp == 190, "XP balance and total survive reload")
	_expect(restored.matches == 2 and restored.wins == 1, "Results survive reload")
	_expect(restored.upgrades["farm"] == 1, "Upgrades survive reload")
	progress.upgrades["farm"] = 20
	_expect(progress.upgrade_cost("farm") == -1 and not progress.buy_upgrade("farm"), "Level cap is enforced")


func _test_malformed_and_invalid_saves() -> void:
	_write_raw("{this is not json")
	var corrupt = _new_progress()
	corrupt.save_path = TEST_PATH
	corrupt.load_save()
	_expect(not corrupt.last_error.is_empty(), "Malformed JSON produces a visible error")
	corrupt.record_match(true)
	_expect(_read_raw() == "{this is not json", "Malformed original is preserved")
	var base: Dictionary = _snapshot()
	var invalid_values: Array = [-1, 2.5, "120", true, null, 9_000_000_000_001]
	for value: Variant in invalid_values:
		var data: Dictionary = base.duplicate(true)
		data["xp"] = value
		var raw: String = JSON.stringify(data)
		_write_raw(raw)
		var invalid = _new_progress()
		invalid.save_path = TEST_PATH
		invalid.load_save()
		_expect(invalid.xp == 0 and not invalid.last_error.is_empty(), "Invalid XP rejected: %s" % str(value))
		_expect(not invalid.save_game() and _read_raw() == raw, "Invalid save remains intact")
	var invalid_upgrade: Dictionary = base.duplicate(true)
	invalid_upgrade["upgrades"]["vision"] = 21
	_write_raw(JSON.stringify(invalid_upgrade))
	var invalid_level = _new_progress()
	invalid_level.save_path = TEST_PATH
	invalid_level.load_save()
	_expect(not invalid_level.last_error.is_empty(), "Out-of-range skill level rejected")
	var impossible_results: Dictionary = base.duplicate(true)
	impossible_results["wins"] = 5
	_write_raw(JSON.stringify(impossible_results))
	var invalid_results = _new_progress()
	invalid_results.save_path = TEST_PATH
	invalid_results.load_save()
	_expect(not invalid_results.last_error.is_empty(), "Wins cannot exceed matches")


func _test_future_schema() -> void:
	var data: Dictionary = _snapshot()
	data["schema_version"] = 99
	data["future_field"] = "preserve this"
	var raw: String = JSON.stringify(data)
	_write_raw(raw)
	var future = _new_progress()
	future.save_path = TEST_PATH
	future.load_save()
	_expect(future.last_error.contains("mais recente"), "Future schema has explicit error")
	future.record_match(false)
	_expect(not future.buy_upgrade("farm"), "Cannot overwrite future save through purchase")
	_expect(not future.save_game() and _read_raw() == raw, "Future save is never overwritten")
	var unread = _new_progress()
	unread.save_path = TEST_PATH
	_expect(not unread.save_game() and _read_raw() == raw, "Unloaded existing save is protected")


func _test_save_failure_rolls_back_purchase() -> void:
	var progress = _new_progress()
	progress.save_path = "res://tests/missing_progression_test_directory/progress.json"
	progress.load_save()
	progress.xp = 120
	progress.lifetime_xp = 120
	_expect(not progress.buy_upgrade("farm"), "Failed disk write rejects purchase")
	_expect(progress.xp == 120 and progress.upgrades["farm"] == 0, "Failed purchase restores balance and level")


func _snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"xp": 120,
		"lifetime_xp": 120,
		"matches": 1,
		"wins": 1,
		"upgrades": {"farm": 0, "trades": 0, "builds": 0, "macro": 0, "vision": 0},
	}


func _write_raw(value: String) -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file == null:
		_expect(false, "Test fixture can be written")
		return
	file.store_string(value)
	file.close()


func _read_raw() -> String:
	return FileAccess.get_file_as_string(TEST_PATH)


func _cleanup() -> void:
	for path: String in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _new_progress():
	var progress = Progression.new()
	progress.time_override = 1_800_000_000
	return progress


