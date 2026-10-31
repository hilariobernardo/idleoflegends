extends SceneTree

const MatchSimulation = preload("res://scripts/match_sim.gd")
var _failures: int = 0


func _initialize() -> void:
	var first = MatchSimulation.new()
	first.start({}, 7182)
	_check(first.units.size() == 10, "A partida deve ter dez unidades.")
	_check(first.towers.size() == 6, "Cada equipe deve ter três torres.")
	first.advance(120.0)
	_check(first.finished, "A partida deve terminar em até 90 segundos.")
	_check(first.winner in [0, 1], "A partida deve produzir um vencedor válido.")
	_check(first.elapsed <= first.duration, "A duração não deve exceder o limite.")
	var second = MatchSimulation.new()
	second.start({}, 7182)
	for frame: int in range(1800):
		second.advance(0.05)
	_check(first.get_summary() == second.get_summary(), "O resultado deve independer da divisão dos frames.")
	var snapshot: Dictionary = first.get_summary()
	first.advance(20.0)
	_check(first.get_summary() == snapshot, "Uma partida encerrada deve permanecer congelada.")
	for unit: Dictionary in first.units:
		_check(float(unit["hp"]) >= 0.0 and float(unit["hp"]) <= float(unit["max_hp"]), "Vida de unidade fora dos limites.")
	for tower: Dictionary in first.towers:
		_check(float(tower["hp"]) >= 0.0 and float(tower["hp"]) <= float(tower["max_hp"]), "Vida de torre fora dos limites.")
	first.start({}, 7182)
	_check(not first.finished and first.elapsed == 0.0 and first.kills == [0, 0], "Reiniciar deve limpar o resultado anterior.")
	var base_wins: int = 0
	var upgraded_wins: int = 0
	var upgraded_skills: Dictionary = {"farm": 10, "trades": 10, "builds": 10, "macro": 10, "vision": 10}
	for seed_number: int in range(1, 101):
		first.start({}, seed_number)
		first.advance(120.0)
		base_wins += 1 if first.winner == 0 else 0
		second.start(upgraded_skills, seed_number)
		second.advance(120.0)
		upgraded_wins += 1 if second.winner == 0 else 0
	_check(upgraded_wins > base_wins, "Melhorias devem aumentar as vitórias no conjunto determinístico de partidas.")
	var weak_wins: int = 0
	var strong_wins: int = 0
	var strong_skills: Dictionary = {"farm": 8, "trades": 8, "builds": 8, "macro": 8, "vision": 8}
	for seed_number: int in range(1, 101):
		first.start({}, seed_number, 4.0)
		first.advance(120.0)
		weak_wins += 1 if first.winner == 0 else 0
		second.start(strong_skills, seed_number, 4.0)
		second.advance(120.0)
		strong_wins += 1 if second.winner == 0 else 0
	_check(weak_wins < base_wins, "Subir a dificuldade deve reduzir as vitórias de uma equipe fraca.")
	_check(strong_wins > weak_wins, "Investir em habilidades deve permitir superar os mesmos adversários.")
	first.start(strong_skills, 7182, 4.0, "Ranked")
	_check(first.events[0].begins_with("Ranked"), "O evento inicial deve identificar o modo escolhido.")
	first.advance(120.0)
	second.start(strong_skills, 7182, 4.0)
	for frame: int in range(1800):
		second.advance(0.05)
	_check(first.get_summary() == second.get_summary(), "Dificuldade deve preservar determinismo entre frames.")
	first.start({}, 7182, INF)
	_check(first.units[5]["max_hp"] == 130.0, "Dificuldade não finita deve usar o nível inicial.")
	first.start({}, 7182, -4.0)
	_check(first.units[5]["max_hp"] == 130.0, "Dificuldade negativa deve usar o nível inicial.")
	first.start({}, 7182, 100.0)
	_check(first.units[5]["max_hp"] == 380.0, "Dificuldade deve respeitar o limite de habilidades.")
	print("Simulação: %d falhas; vitórias azuis em 100 seeds: base=%d, melhorias nível 10=%d." % [_failures, base_wins, upgraded_wins])
	print("Contra adversários nível 4: equipe fraca=%d/100; equipe nível 8=%d/100." % [weak_wins, strong_wins])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
