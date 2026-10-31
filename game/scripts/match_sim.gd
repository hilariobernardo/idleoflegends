extends RefCounted
## Deterministic, fixed-step simulation. All coordinates are normalized map coordinates.

const Map = preload("res://scripts/map_layout.gd")

const STEP: float = 0.1
const MOVEMENT_MULTIPLIER: float = 3.0
const CAMP_CLEAR_SECONDS: float = 1.5
const GANK_SECONDS: float = 8.0
const BASE_HEALTH: float = 1000.0
const TOWER_HEALTH: float = 260.0
const UNIT_LANES: Array[int] = [0, 0, 1, 2, 2]
const ROLES: Array[String] = ["Topo", "Selva", "Meio", "Atirador", "Suporte"]

var units: Array[Dictionary] = []
var towers: Array[Dictionary] = []
var events: Array[String] = []
var objectives: Dictionary = {}
var dragons: Array[int] = [0, 0]
var barons: Array[int] = [0, 0]
var baron_until: Array[float] = [0.0, 0.0]
var objective_message: String = "Dragon: 00:20 e 00:45 · Baron: 01:05"
var _spawn_index: int = 0
const OBJECTIVE_SCHEDULE: Array[float] = [20.0, 45.0, 65.0]
# Covers the separated attack positions around each river pit.
const OBJECTIVE_RANGE: float = 0.13
var elapsed: float = 0.0
var duration: float = 90.0
var finished: bool = false
var winner: int = -1
var kills: Array[int] = [0, 0]
var team_gold: Array[float] = [0.0, 0.0]
var base_hp: Array[float] = [BASE_HEALTH, BASE_HEALTH]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _upgrades: Dictionary = {}
var _opponent_level: float = 0.0
var _accumulator: float = 0.0
var _started: bool = false


func start(upgrades: Dictionary, seed_value: int = 0, opponent_level: float = 0.0, mode_label: String = "Normal Game") -> void:
	_upgrades = upgrades.duplicate(true)
	_opponent_level = clampf(opponent_level, 0.0, 50.0) if is_finite(opponent_level) else 0.0
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value
	units.clear()
	towers.clear()
	events.clear()
	dragons = [0, 0]
	barons = [0, 0]
	baron_until = [0.0, 0.0]
	_spawn_index = 0
	objective_message = "Dragon: 00:20 e 00:45 · Baron: 01:05"
	objectives = {}
	for key: String in ["dragon", "baron"]:
		var health: float = 300.0 if key == "dragon" else 600.0
		objectives[key] = {"position": Map.objective_position(key), "hp": health,
			"max_hp": health, "alive": false, "owner": -1}
	elapsed = 0.0
	_accumulator = 0.0
	finished = false
	winner = -1
	kills = [0, 0]
	team_gold = [0.0, 0.0]
	base_hp = [BASE_HEALTH, BASE_HEALTH]
	_started = true
	for team: int in range(2):
		# Match-to-match execution varies symmetrically; purchased skills still
		# improve the same stats, but a small level gap is no longer a certain win.
		var team_form: float = _rng.randf_range(0.80, 1.20)
		for slot: int in range(5):
			var max_health: float = 130.0 + _skill(team, "builds") * 5.0
			var progress: float = 0.04 + float(slot % 2) * 0.025
			if team == 1:
				progress = 1.0 - progress
			var unit: Dictionary = {
				"id": team * 5 + slot, "team": team, "lane": UNIT_LANES[slot],
				"position": Vector2.ZERO, "progress": progress, "hp": max_health,
				"max_hp": max_health, "alive": true, "respawn_left": 0.0,
				"objective": "", "returning": false, "role": ROLES[slot], "gold": 0.0, "level": 1,
				"cooldown": _rng.randf_range(0.0, 0.6),
				"power": team_form * _rng.randf_range(0.92, 1.08), "slot": slot,
			}
			_update_position(unit)
			if slot == 1:
				_begin_jungle(unit)
			units.append(unit)
		for lane: int in range(3):
			var tower_progress: float = 0.29 if team == 0 else 0.71
			towers.append({
				"team": team, "lane": lane, "position": _sample_lane(lane, tower_progress),
				"progress": tower_progress, "hp": TOWER_HEALTH,
				"max_hp": TOWER_HEALTH, "cooldown": 0.5,
			})
	_event("%s começou. Boa partida!" % mode_label)


func lane_points(index: int) -> PackedVector2Array:
	return Map.lane_points(index)


func jungle_points(team: int) -> PackedVector2Array:
	return Map.camps(team)


func _set_route(unit: Dictionary, target: Vector2) -> void:
	unit["route"] = Map.route(unit.position, target)
	unit["route_index"] = 0


func _follow_route(unit: Dictionary, distance: float) -> bool:
	var points: PackedVector2Array = unit.route
	while int(unit.route_index) < points.size():
		var target: Vector2 = points[int(unit.route_index)]
		var remaining: float = Vector2(unit.position).distance_to(target)
		if remaining > distance:
			unit.position = Vector2(unit.position).move_toward(target, distance)
			return false
		unit.position = target
		distance -= remaining
		unit.route_index += 1
	return true


func _begin_jungle(unit: Dictionary) -> void:
	unit["lane"] = -1
	unit["jungle_state"] = "travel"
	unit["camp_index"] = 0
	unit["camp_timer"] = 0.0
	unit["gank_timer"] = 0.0
	unit["gank_count"] = int(unit.get("gank_count", 0))
	_set_route(unit, jungle_points(int(unit.team))[0])


func _advance_jungle(unit: Dictionary) -> bool:
	# Return true while off-lane: no remote attacks or tower targeting.
	if unit.jungle_state == "gank":
		unit.gank_timer += STEP
		if unit.gank_timer < GANK_SECONDS:
			return false
		_begin_jungle(unit)
	var team: int = int(unit.team)
	var speed: float = (0.063 + 0.0015 * _skill(team, "macro")) * MOVEMENT_MULTIPLIER
	if unit.jungle_state == "approach":
		if _follow_route(unit, speed * STEP):
			unit.lane = unit.gank_lane
			unit.progress = unit.gank_progress
			unit.jungle_state = "gank"
			unit.gank_timer = 0.0
			unit.gank_count += 1
			_event("%s: jungler chegou para gankar!" % _team_name(team))
		return true
	if not _follow_route(unit, speed * STEP):
		return true
	unit.jungle_state = "clear"
	unit.camp_timer += STEP
	if unit.camp_timer + 0.000001 >= CAMP_CLEAR_SECONDS:
		var reward: float = 18.0 * (1.0 + 0.08 * _skill(team, "farm"))
		unit.gold += reward
		team_gold[team] += reward
		unit.camp_timer = 0.0
		unit.camp_index += 1
		unit.jungle_state = "travel"
		if unit.camp_index == 6:
			unit.jungle_state = "approach"
			unit.gank_lane = _rng.randi_range(0, 2)
			unit.gank_progress = 0.48 if team == 0 else 0.52
			_set_route(unit, _sample_lane(int(unit.gank_lane), float(unit.gank_progress)))
		else:
			_set_route(unit, jungle_points(team)[int(unit.camp_index)])
	return true


func advance(delta: float) -> void:
	if not _started or finished or delta <= 0.0 or not is_finite(delta):
		return
	_accumulator += minf(delta, 600.0)
	while _accumulator + 0.000001 >= STEP and not finished:
		_accumulator -= STEP
		_tick()


func get_summary() -> Dictionary:
	return {
		"blue_dragons": dragons[0], "red_dragons": dragons[1],
		"blue_barons": barons[0], "red_barons": barons[1],
		"winner": winner, "duration": elapsed,
		"blue_kills": kills[0], "red_kills": kills[1],
		"blue_gold": int(team_gold[0]), "red_gold": int(team_gold[1]),
		"blue_base_hp": base_hp[0], "red_base_hp": base_hp[1],
		"blue_towers": _living_towers(0), "red_towers": _living_towers(1),
	}


func _tick() -> void:
	elapsed = minf(elapsed + STEP, duration)
	_spawn_objectives()
	var objective_damage: Dictionary = {"dragon": [0.0, 0.0], "baron": [0.0, 0.0]}
	var unit_damage: Array[float] = []
	unit_damage.resize(units.size())
	unit_damage.fill(0.0)
	var tower_damage: Array[float] = []
	tower_damage.resize(towers.size())
	tower_damage.fill(0.0)
	var base_damage: Array[float] = [0.0, 0.0]
	var movement: Array[float] = []
	movement.resize(units.size())
	movement.fill(-1.0)
	# Respawn first, then resolve every unit against the same positions.
	for unit: Dictionary in units:
		if not bool(unit["alive"]):
			unit["respawn_left"] = maxf(0.0, float(unit["respawn_left"]) - STEP)
			if float(unit["respawn_left"]) <= 0.0:
				_respawn(unit)
	# Move every objective participant before resolving attacks for either team.
	for unit: Dictionary in units:
		if bool(unit.alive):
			_update_objective_movement(unit)
	for unit: Dictionary in units:
		if not bool(unit["alive"]):
			continue
		var team: int = int(unit["team"])
		if not str(unit.objective).is_empty():
			_attack_objective(unit, unit_damage, objective_damage)
			continue
		if bool(unit.returning):
			continue
		if int(unit.slot) == 1 and _advance_jungle(unit):
			unit.level = mini(18, 1 + int(float(unit.gold) / 45.0))
			continue
		var farm_gain: float = STEP * 4.0 * (1.0 + 0.08 * _skill(team, "farm"))
		unit["gold"] = float(unit["gold"]) + farm_gain
		team_gold[team] += farm_gain
		unit["level"] = mini(18, 1 + int(float(unit["gold"]) / 45.0))
		unit["cooldown"] = float(unit["cooldown"]) - STEP
		var target: int = _enemy_in_range(unit, 0.075)
		if target >= 0:
			if float(unit["cooldown"]) <= 0.0:
				var damage: float = _attack_damage(unit)
				var target_team: int = int(units[target]["team"])
				if _rng.randf() < minf(0.25, _skill(target_team, "vision") * 0.012):
					damage *= 0.35
				unit_damage[target] += damage
				unit["cooldown"] = 0.85
			continue
		var tower_index: int = _enemy_tower_in_range(unit)
		if tower_index >= 0:
			if float(unit["cooldown"]) <= 0.0:
				tower_damage[tower_index] += _attack_damage(unit) * (1.0 + _skill(team, "macro") * 0.05) * _structure_bonus(team)
				unit["cooldown"] = 0.85
			continue
		var progress: float = float(unit["progress"])
		var at_enemy_base: bool = progress >= 0.935 if team == 0 else progress <= 0.065
		if at_enemy_base:
			if float(unit["cooldown"]) <= 0.0:
				base_damage[1 - team] += _attack_damage(unit) * 2.0 * _structure_bonus(team)
				unit["cooldown"] = 0.85
			continue
		var direction: float = 1.0 if team == 0 else -1.0
		var lane_length: float = Map.lane_length(int(unit.lane))
		var speed: float = MOVEMENT_MULTIPLIER * (0.063 + 0.0015 * _skill(team, "macro")) / lane_length
		movement[int(unit["id"])] = clampf(progress + direction * speed * STEP, 0.045, 0.955)
	for unit: Dictionary in units:
		var next_progress: float = movement[int(unit["id"])]
		if next_progress >= 0.0:
			unit["progress"] = next_progress
			_update_position(unit)
	for index: int in range(towers.size()):
		var tower: Dictionary = towers[index]
		if float(tower["hp"]) <= 0.0:
			continue
		tower["cooldown"] = float(tower["cooldown"]) - STEP
		if float(tower["cooldown"]) <= 0.0:
			var target: int = _tower_target(tower)
			if target >= 0:
				unit_damage[target] += 17.0
				tower["cooldown"] = 1.2
	# Apply all damage together, so the first team in the array has no first-hit advantage.
	for index: int in range(units.size()):
		var unit: Dictionary = units[index]
		if not bool(unit["alive"]):
			continue
		unit["hp"] = maxf(0.0, float(unit["hp"]) - unit_damage[index])
		if float(unit["hp"]) <= 0.0:
			_defeat(unit)
	for index: int in range(towers.size()):
		var tower: Dictionary = towers[index]
		var previous_health: float = float(tower["hp"])
		tower["hp"] = maxf(0.0, previous_health - tower_damage[index])
		if previous_health > 0.0 and float(tower["hp"]) <= 0.0:
			var attacking_team: int = 1 - int(tower["team"])
			_grant_team_gold(attacking_team, 60.0)
			_event("%s destruiu uma torre!" % _team_name(attacking_team))
	_resolve_objectives(objective_damage)
	for team: int in range(2):
		base_hp[team] = maxf(0.0, base_hp[team] - base_damage[team])
	if base_hp[0] <= 0.0 or base_hp[1] <= 0.0:
		_finish()
	elif elapsed + 0.000001 >= duration:
		elapsed = duration
		_finish()


func _enemy_in_range(unit: Dictionary, attack_range: float) -> int:
	var best_index: int = -1
	var best_distance: float = attack_range
	for enemy: Dictionary in units:
		if not bool(enemy["alive"]) or int(enemy["team"]) == int(unit["team"]) or int(enemy["lane"]) != int(unit["lane"]):
			continue
		var distance: float = absf(float(enemy["progress"]) - float(unit["progress"]))
		if distance <= best_distance:
			best_distance = distance
			best_index = int(enemy["id"])
	return best_index


func _enemy_tower_in_range(unit: Dictionary) -> int:
	for index: int in range(towers.size()):
		var tower: Dictionary = towers[index]
		if int(tower["team"]) == int(unit["team"]) or int(tower["lane"]) != int(unit["lane"]) or float(tower["hp"]) <= 0.0:
			continue
		if absf(float(tower["progress"]) - float(unit["progress"])) <= 0.065:
			return index
	return -1


func _tower_target(tower: Dictionary) -> int:
	var target: int = -1
	var closest: float = 0.105
	for unit: Dictionary in units:
		if not bool(unit["alive"]) or int(unit["team"]) == int(tower["team"]) or int(unit["lane"]) != int(tower["lane"]):
			continue
		var distance: float = absf(float(tower["progress"]) - float(unit["progress"]))
		if distance < closest:
			closest = distance
			target = int(unit["id"])
	return target


func _attack_damage(unit: Dictionary) -> float:
	var team: int = int(unit["team"])
	var item_power: float = 1.0 + floorf(float(unit["gold"]) / 60.0) * (0.10 + _skill(team, "builds") * 0.01)
	return 11.0 * float(unit["power"]) * item_power * (1.0 + _skill(team, "trades") * 0.045) * _rng.randf_range(0.90, 1.10) * (1.0 + 0.08 * dragons[team])


func _defeat(unit: Dictionary) -> void:
	var team: int = int(unit["team"])
	unit["alive"] = false
	unit["respawn_left"] = maxf(3.0, 6.0 - _skill(team, "vision") * 0.08)
	kills[1 - team] += 1
	_grant_team_gold(1 - team, 12.0)
	_event("%s: %s abatido." % [_team_name(team), str(unit["role"])])


func _respawn(unit: Dictionary) -> void:
	var team: int = int(unit["team"])
	unit["objective"] = ""
	unit["returning"] = false
	unit["lane"] = UNIT_LANES[int(unit.slot)]
	unit["alive"] = true
	unit["hp"] = float(unit["max_hp"])
	unit["progress"] = 0.045 if team == 0 else 0.955
	unit["cooldown"] = 0.4
	if int(unit["slot"]) == 1:
		unit["lane"] = 1
	_update_position(unit)
	if int(unit["slot"]) == 1:
		_begin_jungle(unit)


func _grant_team_gold(team: int, amount_per_unit: float) -> void:
	for unit: Dictionary in units:
		if int(unit["team"]) == team:
			unit["gold"] = float(unit["gold"]) + amount_per_unit
			team_gold[team] += amount_per_unit


func _update_position(unit: Dictionary) -> void:
	unit["position"] = _sample_lane(int(unit.lane), float(unit.progress))


func _sample_lane(lane: int, progress: float) -> Vector2:
	return Map.sample(lane, progress)


func _skill(team: int, key: String) -> float:
	if team != 0:
		return _opponent_level
	return clampf(float(_upgrades.get(key, 0)), 0.0, 50.0)


func _living_towers(team: int) -> int:
	var count: int = 0
	for tower: Dictionary in towers:
		if int(tower["team"]) == team and float(tower["hp"]) > 0.0:
			count += 1
	return count


func _score(team: int) -> float:
	return base_hp[team] + float(_living_towers(team)) * 250.0 + float(kills[team]) * 20.0 + team_gold[team] * 0.10


func _finish() -> void:
	finished = true
	if base_hp[0] <= 0.0 and base_hp[1] > 0.0:
		winner = 1
	elif base_hp[1] <= 0.0 and base_hp[0] > 0.0:
		winner = 0
	else:
		var difference: float = _score(0) - _score(1)
		winner = (0 if difference > 0.0 else 1) if absf(difference) > 0.001 else _rng.randi_range(0, 1)
	_event("%s venceu!" % _team_name(winner))


func _team_name(team: int) -> String:
	return "Equipe azul" if team == 0 else "Equipe vermelha"


func _event(message: String) -> void:
	events.push_front(message)
	if events.size() > 8:
		events.resize(8)


func _spawn_objectives() -> void:
	while _spawn_index < OBJECTIVE_SCHEDULE.size() and elapsed + 0.000001 >= OBJECTIVE_SCHEDULE[_spawn_index]:
		var key: String = "baron" if _spawn_index == 2 else "dragon"
		_spawn_index += 1
		var objective: Dictionary = objectives[key]
		if bool(objective.alive):
			continue
		objective.alive = true
		objective.hp = objective.max_hp
		objective.owner = -1
		objective_message = "%s nasceu!" % key.capitalize()
		_event(objective_message)


func _update_objective_movement(unit: Dictionary) -> void:
	var desired: String = ""
	if bool(objectives.baron.alive):
		desired = "baron"
	elif bool(objectives.dragon.alive) and int(unit.slot) in [1, 3, 4]:
		desired = "dragon"
	if desired != str(unit.objective):
		if not desired.is_empty():
			if str(unit.objective).is_empty() and not bool(unit.returning):
				unit["return_lane"] = UNIT_LANES[int(unit.slot)]
				unit["return_progress"] = float(unit.progress)
			unit.objective = desired
			unit.returning = false
			unit.lane = -1
			_set_route(unit, Map.objective_attack_position(desired, int(unit.id)))
		else:
			unit.objective = ""
			if int(unit.slot) == 1:
				_begin_jungle(unit)
			else:
				unit.returning = true
				_set_route(unit, _sample_lane(int(unit.return_lane), float(unit.return_progress)))
	var speed: float = (0.063 + 0.0015 * _skill(int(unit.team), "macro")) * MOVEMENT_MULTIPLIER
	if not desired.is_empty():
		_follow_route(unit, speed * STEP)
	elif bool(unit.returning) and _follow_route(unit, speed * STEP):
		unit.returning = false
		unit.lane = unit.return_lane
		unit.progress = unit.return_progress


func _attack_objective(unit: Dictionary, damage: Array[float], monster_damage: Dictionary) -> void:
	unit.cooldown = float(unit.cooldown) - STEP
	if float(unit.cooldown) > 0.0:
		return
	var target: int = -1
	var distance: float = OBJECTIVE_RANGE
	for enemy: Dictionary in units:
		if not bool(enemy.alive) or int(enemy.team) == int(unit.team) or str(enemy.objective) != str(unit.objective):
			continue
		var separation: float = Vector2(unit.position).distance_to(enemy.position)
		if separation < distance:
			distance = separation
			target = int(enemy.id)
	if target >= 0:
		var hit: float = _attack_damage(unit)
		if _rng.randf() < minf(0.25, _skill(int(units[target].team), "vision") * 0.012):
			hit *= 0.35
		damage[target] += hit
	elif Vector2(unit.position).distance_to(objectives[unit.objective].position) <= OBJECTIVE_RANGE:
		monster_damage[unit.objective][int(unit.team)] += _attack_damage(unit)
	else:
		return
	unit.cooldown = 0.85


func _resolve_objectives(damage: Dictionary) -> void:
	for key: String in objectives:
		var objective: Dictionary = objectives[key]
		if not bool(objective.alive):
			continue
		objective.hp = maxf(0.0, float(objective.hp) - float(damage[key][0]) - float(damage[key][1]))
		if float(objective.hp) > 0.0:
			continue
		var difference: float = float(damage[key][0]) - float(damage[key][1])
		var team: int = (0 if difference > 0.0 else 1) if absf(difference) > 0.001 else _rng.randi_range(0, 1)
		objective.alive = false
		objective.owner = team
		if key == "dragon":
			dragons[team] = mini(2, dragons[team] + 1)
			objective_message = "%s conquistou Dragon! +%d%% de dano." % [_team_name(team), dragons[team] * 8]
		else:
			barons[team] += 1
			baron_until[team] = elapsed + 20.0
			objective_message = "%s conquistou Baron! +30%% contra estruturas por 20s." % _team_name(team)
		_event(objective_message)


func _structure_bonus(team: int) -> float:
	return 1.3 if elapsed < baron_until[team] else 1.0


func objective_status() -> String:
	var lines: PackedStringArray = PackedStringArray([objective_message])
	for team: int in range(2):
		var bonuses: PackedStringArray = PackedStringArray()
		if dragons[team] > 0:
			bonuses.append("Dragon +%d%% dano" % (dragons[team] * 8))
		if elapsed < baron_until[team]:
			bonuses.append("Baron +30%% estruturas (%ds)" % int(ceilf(baron_until[team] - elapsed)))
		if not bonuses.is_empty():
			lines.append("%s: %s" % [_team_name(team), " · ".join(bonuses)])
	return "\n".join(lines)
