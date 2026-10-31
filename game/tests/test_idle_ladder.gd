extends SceneTree

const Progression = preload("res://scripts/progression.gd")
const FIXTURE: String = "res://tests/tmp_idle_ladder.json"
const TEST_TIME: int = 1_800_000_000
var failures: int = 0


class FailingMigration:
	extends "res://scripts/progression.gd"
	func save_game() -> bool:
		last_error = "Simulated unavailable storage during migration."
		return false


func _initialize() -> void:
	_test_ladder()
	_test_training()
	_test_cap_boundaries()
	_test_purchases_and_ranked()
	_test_migration_and_validation()
	_test_failed_writes()
	_test_exponential_and_ranked()
	_clean()
	print("PASS idle/ladder: XP/s, activity levels, two-hour boundaries, clock rollback, persistence, purchases, promotion/demotion, ranked, v1/v2 migration, rollback." if failures == 0 else "FAIL idle/ladder: %d assertions" % failures)
	quit(0 if failures == 0 else 1)


func _fresh():
	_clean()
	var progress = _new_progress()
	progress.save_path = FIXTURE
	progress.load_save()
	_check(progress.last_error.is_empty(), "Fresh save initializes successfully.")
	return progress


func _test_ladder() -> void:
	var progress = _fresh()
	_check(progress.rank_name() == "Sal IV" and progress.rank_lp() == 0, "Start at Sal IV, zero LP.")
	progress.record_match(false)
	_check(progress.ladders.normal == 0, "Loss at the floor cannot produce negative LP.")
	for index: int in range(3):
		_check(progress.record_match(true) == 120, "Early wins grant base XP.")
	_check(progress.rank_name() == "Sal IV" and progress.rank_lp() == 75, "Three wins grant 75 LP.")
	_check(progress.record_match(true) == 120, "Promotion match uses the pre-match reward.")
	_check(progress.rank_name() == "Sal III" and progress.rank_lp() == 0, "100 LP promotes to Sal III.")
	_check(progress.victory_reward() == 139 and progress.opponent_level() > 0.0, "Promotion increases reward and enemy strength.")
	progress.record_match(false)
	_check(progress.rank_name() == "Sal IV" and progress.rank_lp() == 75, "A loss at zero LP demotes with 75 LP.")
	progress.ladders.normal = 2790
	progress.record_match(true)
	_check(progress.rank_name() == "Lenda I" and progress.rank_lp() == 99, "Top rank is bounded safely.")


func _test_training() -> void:
	var progress = _fresh()
	var start: int = progress.training_last_at
	_check(progress.training_rate() == 1, "Free video level generates one XP per second.")
	_check(progress.settle_training(start + 1) == 1, "One real second grants one XP.")
	_check(progress.settle_training(start + 2) == 1, "A second settlement grants only newly elapsed time.")
	_check(progress.settle_training(start + 2) == 0 and progress.xp == 2, "Repeated settlement never duplicates XP.")
	_check(progress.settle_training(start - 100) == 0 and progress.training_last_at == start + 2, "Clock rollback cannot rewind the checkpoint.")
	_check(progress.settle_training(start + 2 + 24 * 3600) == 7200, "A long absence grants at most two hours.")
	var restored = _new_progress()
	restored.save_path = FIXTURE
	restored.load_save()
	_check(restored.xp == 7202 and restored.training_last_at == progress.training_last_at, "Reload preserves earned XP and future checkpoint.")
	_check(restored.last_training_reward == 0, "Reload cannot reclaim a previous absence.")
	# A real reopening credits a past interval exactly once.
	progress = _fresh()
	progress.training_last_at -= 3600
	progress.save_game()
	var reopened = _new_progress()
	reopened.save_path = FIXTURE
	reopened.load_save()
	_check(reopened.xp == 3600 and reopened.last_training_reward == 3600, "Opening a save collects the past hour at the same XP/s rate.")
	var reopened_again = _new_progress()
	reopened_again.save_path = FIXTURE
	reopened_again.load_save()
	_check(reopened_again.xp == 3600 and reopened_again.last_training_reward == 0, "Immediate second opening does not pay again.")


func _test_cap_boundaries() -> void:
	for gap: int in [7199, 7200, 7201, 86_400]:
		var progress = _fresh()
		progress.training_levels.videos = 3
		var start: int = progress.training_last_at
		_check(progress.settle_training(start + gap) == mini(gap, 7200) * 5, "Two-hour cap at %d seconds." % gap)
		_check(progress.training_last_at == start + gap, "Checkpoint consumes the full gap, including discarded overflow.")
		_check(progress.settle_training(start + gap) == 0, "Overflow cannot be claimed again.")
		_check(progress.settle_training(start + gap + 1) == 5, "A new second accrues normally after the capped return.")


func _test_purchases_and_ranked() -> void:
	var progress = _fresh()
	_check(not progress.buy_training("tutoriais"), "Training requires XP.")
	progress.xp = 300
	progress.lifetime_xp = 300
	progress.training_last_at -= 10
	_check(progress.buy_training("tutoriais"), "Affordable training unlocks permanently.")
	_check(progress.xp == 10 and progress.training_rate() == 3, "Past time pays old rate; purchase adds two XP/s.")
	_check(progress.training_cost("tutoriais") == 720, "Repeated activity level costs scale by 2.4.")
	_check(not progress.buy_training("tutoriais") and progress.xp == 10, "Repeat purchase still requires sufficient XP.")
	progress.xp = 720
	progress.lifetime_xp = 1000
	_check(progress.buy_training("tutoriais") and progress.training_levels.tutoriais == 2, "An owned activity can be leveled again.")
	_check(progress.training_rate() == 6 and progress.training_cost("tutoriais") == 1728, "Repeated level increases both rate and next cost.")
	progress.xp = 100
	_check(progress.training_cost("videos") == 100 and progress.buy_training("videos"), "The first paid video level costs 100 XP after the free initial level.")
	_check(progress.training_levels.videos == 2 and progress.training_rate() == 8 and progress.training_cost("videos") == 240, "Video levels increase production and scale costs.")
	var checkpoint: int = progress.training_last_at
	_check(progress.settle_training(checkpoint + 1) == 8, "The next second uses the newly purchased combined rate.")
	progress.training_levels.coach = 20
	_check(progress.training_cost("coach") == -1 and not progress.buy_training("coach"), "Training levels stop at 20.")
	_check(not progress.select_mode("ranked"), "Locked Ranked cannot be selected.")
	progress.xp = 10_000
	progress.lifetime_xp = 10_000
	_check(not progress.unlock_ranked(), "XP alone cannot bypass the rank requirement.")
	progress.ladders.normal = 400
	progress.xp = 9999
	_check(not progress.can_unlock_ranked(), "Bronze IV still requires sufficient spendable XP.")
	progress.xp = 10_000
	_check(progress.unlock_ranked() and progress.xp == 0, "Bronze IV and 10,000 XP unlock Ranked.")
	_check(not progress.unlock_ranked() and progress.xp == 0, "Unlock cannot charge twice.")
	_check(progress.select_mode("ranked"), "Unlocked Ranked is selectable.")
	_check(progress.rank_name() == "Ferro IV" and progress.opponent_level() == 2.0, "Ranked has its own ladder and stronger starting enemies.")
	_check(progress.record_match(true) == 180, "Ranked victory earns its reward premium.")
	_check(progress.ladders.normal == 400 and progress.ladders.ranked == 25, "Ranked result affects only its own ladder.")
	var restored = _new_progress()
	restored.save_path = FIXTURE
	restored.load_save()
	_check(restored.ranked_unlocked and restored.selected_mode == "ranked" and restored.training_levels.tutoriais == 2, "Unlocks, selection and training levels survive reload.")


func _test_migration_and_validation() -> void:
	var progress = _fresh()
	var legacy: Dictionary = {"schema_version": 1, "xp": 200, "lifetime_xp": 300, "matches": 4, "wins": 2, "upgrades": {"farm": 1, "trades": 0, "builds": 0, "macro": 0, "vision": 0}}
	_write(JSON.stringify(legacy))
	progress = _new_progress()
	progress.save_path = FIXTURE
	progress.load_save()
	_check(progress.xp == 200 and progress.upgrades.farm == 1 and progress.matches == 4, "v1 migration preserves all player progress.")
	_check(progress.rank_name() == "Sal IV" and progress.last_training_reward == 0 and progress.training_last_at > 0, "Migration starts the new systems without historical income.")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	_check(data.schema_version == 4, "Migrated save uses schema v4.")
	for field: String in ["training_remainder", "training_last_at", "ranked_unlocked", "ladders", "training_levels", "selected_mode"]:
		var invalid: Dictionary = data.duplicate(true)
		invalid[field] = "invalid"
		var raw: String = JSON.stringify(invalid)
		_write(raw)
		var rejected = _new_progress()
		rejected.save_path = FIXTURE
		rejected.load_save()
		_check(not rejected.last_error.is_empty(), "Invalid field rejected: " + field)
		rejected.settle_training()
		rejected.record_match(true)
		_check(FileAccess.get_file_as_string(FIXTURE) == raw, "Invalid original remains preserved: " + field)
	for value: Variant in [-1, 21, 1.5, true, "2", null]:
		var invalid: Dictionary = data.duplicate(true)
		invalid.training_levels.tutoriais = value
		var raw: String = JSON.stringify(invalid)
		_write(raw)
		var rejected = _new_progress()
		rejected.save_path = FIXTURE
		rejected.load_save()
		_check(not rejected.last_error.is_empty() and not rejected.save_game(), "Malformed activity level is blocked: %s" % str(value))
		_check(FileAccess.get_file_as_string(FIXTURE) == raw, "Malformed level leaves original file intact.")
	# Migrate only the old hourly earnings, capped at two hours, then switch rates.
	var hourly: Dictionary = data.duplicate(true)
	hourly.schema_version = 2
	hourly.erase("training_levels")
	hourly.training_owned = {"videos": true, "tutoriais": true, "competicoes": false, "coach": false}
	hourly.training_last_at = TEST_TIME - 86_400
	hourly.training_remainder = 1800
	var hourly_raw: String = JSON.stringify(hourly)
	_write(hourly_raw)
	var failed_migration = FailingMigration.new()
	failed_migration.time_override = TEST_TIME
	failed_migration.save_path = FIXTURE
	failed_migration.load_save()
	_check(failed_migration.xp == 200 and failed_migration.training_last_at == TEST_TIME - 86_400, "Failed migration restores old balance and timestamp.")
	_check(failed_migration.settle_training(TEST_TIME + 1) == 0 and failed_migration.record_match(true) == 0, "Failed migration blocks new-rate earnings until reload.")
	_check(FileAccess.get_file_as_string(FIXTURE) == hourly_raw, "Failed migration preserves the legacy save verbatim.")
	var migrated = _new_progress()
	migrated.save_path = FIXTURE
	migrated.load_save()
	_check(migrated.xp == 380 and migrated.last_training_reward == 180, "v2 pending income uses 90 XP/hour for at most two hours.")
	_check(migrated.training_levels.videos == 1 and migrated.training_levels.tutoriais == 1 and migrated.training_rate() == 3, "v2 ownership becomes one level per owned activity.")
	_check(migrated.training_remainder == 1800, "Legacy fractional XP is preserved during migration.")
	_check(migrated.settle_training(TEST_TIME + 1) == 3, "Only time after migration earns the new per-second rate.")
	var migrated_again = _new_progress()
	migrated_again.save_path = FIXTURE
	migrated_again.load_save()
	_check(migrated_again.xp == 383 and migrated_again.last_training_reward == 0, "Reloading migrated progress cannot claim legacy income again.")


func _test_failed_writes() -> void:
	var progress = _fresh()
	progress.xp = 10_000
	progress.lifetime_xp = 10_000
	progress.ladders.normal = 400
	progress.save_path = "res://tests/missing_idle_test_directory/progress.json"
	var checkpoint: int = progress.training_last_at
	_check(progress.settle_training(checkpoint + 3600) == 0, "Failed offline write does not grant XP.")
	_check(progress.xp == 10_000 and progress.training_last_at == checkpoint, "Failed settlement restores checkpoint and balance.")
	_check(progress.record_match(true) == 0 and progress.matches == 0 and progress.ladders.normal == 400, "Failed match save rolls back stats and LP.")
	_check(not progress.unlock_ranked() and not progress.ranked_unlocked and progress.xp == 10_000, "Failed unlock save restores XP and lock.")
	_check(not progress.buy_training("coach") and not progress.training_owned.coach and progress.xp == 10_000, "Failed training save restores purchase.")


func _write(raw: String) -> void:
	var file: FileAccess = FileAccess.open(FIXTURE, FileAccess.WRITE)
	_check(file != null, "Test fixture can be written.")
	if file != null:
		file.store_string(raw)
		file.close()


func _test_exponential_and_ranked() -> void:
	var progress = _fresh()
	var boundaries: Dictionary = {0: "Ferro IV", 400: "Bronze IV", 800: "Prata IV", 1200: "Ouro IV", 1600: "Platina IV", 2000: "Esmeralda IV", 2400: "Diamante IV", 2775: "Diamante I", 2800: "Mestre", 3000: "Grão-Mestre", 3300: "Challenger"}
	progress.ranked_unlocked = true
	for points: int in boundaries:
		progress.ladders.ranked = points
		_check(progress.rank_name("ranked") == boundaries[points], "Ranked tier boundary %d" % points)
	progress.ladders.ranked = 2800
	progress.record_match(false, "ranked")
	_check(progress.rank_name("ranked") == "Diamante I", "Apex demotion returns to Diamond I.")
	progress.ladders.ranked = 3990
	progress.record_match(true, "ranked")
	_check(progress.ladders.ranked == 3999, "Challenger is bounded independently of Normal.")
	progress.training_levels.videos = 10
	var early_roi: float = 100.0 / progress.training_production("videos", 2)
	var later_roi: float = float(progress.training_cost("videos")) / progress.training_production("videos")
	_check(later_roi > early_roi * 10.0, "Prices outgrow exponential production, slowing later purchases.")
	_check(progress.training_production("videos", 20) > progress.training_production("videos", 10) * 20, "Late production is strongly exponential.")
	progress.xp = 1000
	progress.lifetime_xp = 1000
	progress.ladders.ranked = 0
	progress.training_last_at = TEST_TIME - 7200
	var legacy: Dictionary = progress._snapshot()
	legacy.schema_version = 3
	_write(JSON.stringify(legacy))
	var migrated = _new_progress()
	migrated.save_path = FIXTURE
	migrated.load_save()
	_check(migrated.xp == 73000 and migrated.training_levels.videos == 10, "v3 migration preserves levels and pays only the old linear rate.")
	_check(migrated.settle_training(TEST_TIME + 1) == migrated.training_production("videos"), "New exponential rate starts after migration.")


func _clean() -> void:
	for suffix: String in ["", ".tmp"]:
		if FileAccess.file_exists(FIXTURE + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE + suffix))


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _new_progress():
	var progress = Progression.new()
	progress.time_override = TEST_TIME
	return progress


