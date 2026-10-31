extends SceneTree
const Simulation = preload("res://scripts/match_sim.gd")
const Map = preload("res://scripts/map_layout.gd")
var failures: int = 0

func _initialize() -> void:
	Map.prepare()
	# A graph edge may move only one source-image grid cell, never bridge a forest.
	for edge: Array in Map.data.edges:
		_check(Map.graph.get_point_position(int(edge[0])).distance_to(Map.graph.get_point_position(int(edge[1]))) <= 0.006, "No long edges across terrain")
	for team: int in range(2):
		_check(Map.camps(team).size() == 6, "Six mapped clearings per team")
		for camp: Vector2 in Map.camps(team):
			for lane: int in range(3):
				_check(not Map.route(camp, Map.sample(lane, .5)).is_empty(), "Every camp has an exit to each lane")
	var selected: Array[Dictionary] = [{}, {}]
	for seed_value: int in range(1, 13):
		var sim = Simulation.new()
		sim.start({}, seed_value)
		# Isolate navigation from combat to inspect repeated clear/gank/return cycles.
		for team: int in range(2):
			var j: Dictionary = sim.units[team * 5 + 1]
			var cycles: int = 0
			for frame: int in range(1800):
				var before: Vector2 = j.position
				var state: String = j.jungle_state
				sim._advance_jungle(j)
				_check(before.distance_to(j.position) <= .01901, "Continuous travel including return from gank")
				var nearest: Vector2 = Map.graph.get_point_position(Map.graph.get_closest_point(j.position))
				_check(nearest.distance_to(j.position) <= .006, "Jungler stays on mapped corridors")
				if state != "approach" and j.jungle_state == "approach":
					_check(j.camp_index == 6, "Lane selection only after six camps")
					selected[team][int(j.gank_lane)] = true
					cycles += 1
				if cycles >= 2: break
			_check(cycles >= 2, "Jungler can complete subsequent cycles")
	for team: int in range(2):
		_check(selected[team].size() == 3, "All three gank lanes selected across seeded cycles")
	print("PASS navigation: connected clearings, mapped travel, return paths, random ganks across all lanes" if failures == 0 else "FAIL navigation: %d" % failures)
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
