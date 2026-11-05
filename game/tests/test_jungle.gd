extends SceneTree
const Simulation = preload("res://scripts/match_sim.gd")
var failures: int = 0

func _initialize() -> void:
	var sim = Simulation.new()
	sim.start({}, 7182)
	# Isolate the camp/gank route from Dragon and Baron diversions.
	sim._spawn_index = sim.OBJECTIVE_SCHEDULE.size()
	var previous: Array[int] = [0, 0]
	var seen: Array[int] = [0, 0]
	var arrived: Array[bool] = [false, false]
	for frame: int in range(500):
		var old: Array[Vector2] = [sim.units[1].position, sim.units[6].position]
		sim.advance(0.1)
		for team: int in range(2):
			var j: Dictionary = sim.units[team * 5 + 1]
			if arrived[team]: continue
			_check(Vector2(j.position).distance_to(old[team]) < 0.025, "Jungler travels continuously before first gank")
			if int(j.camp_index) > previous[team]:
				_check(int(j.camp_index) == previous[team] + 1, "Camps cleared in order")
				_check(Vector2(j.position).distance_to(sim.jungle_points(team)[previous[team]]) < 0.001, "Clear requires reaching camp")
				seen[team] += 1
				previous[team] = int(j.camp_index)
			if j.jungle_state == "gank":
				_check(seen[team] == 6 and j.lane >= 0, "Six camps before entering lane")
				arrived[team] = true
			else:
				_check(j.lane == -1, "No lane combat from inside jungle")
		if arrived[0] and arrived[1]: break
	_check(arrived[0] and arrived[1], "Both teams complete route and gank")
	var j: Dictionary = sim.units[1]
	sim._defeat(j)
	sim._respawn(j)
	_check(j.camp_index == 0 and j.lane == -1 and j.jungle_state == "travel", "Respawn restarts jungle route")
	var clock = Simulation.new()
	clock.start({}, 7182)
	clock.advance(1.0)
	_check(is_equal_approx(clock.elapsed, 1.0), "Fast movement does not accelerate clock")
	_check(Vector2(clock.units[0].position).distance_to(clock._sample_lane(0, .04)) > 0.15, "Lane movement uses new baseline")
	var fixed = Simulation.new()
	fixed.start({}, 7182)
	for frame: int in range(10): fixed.advance(0.1)
	_check(fixed.get_summary() == clock.get_summary() and fixed.units == clock.units, "Jungle is deterministic across frame sizes")
	print("PASS jungle: six ordered camps, both teams, continuous travel, gank, respawn, normal clock" if failures == 0 else "FAIL jungle: %d" % failures)
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
