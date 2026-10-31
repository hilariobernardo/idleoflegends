extends SceneTree

const Simulation = preload("res://scripts/match_sim.gd")

func _initialize() -> void:
	for level: int in [0, 2, 4, 6, 8]:
		var wins: int = 0
		var total_time: float = 0.0
		var skills: Dictionary = {"farm": level, "trades": level, "builds": level, "macro": level, "vision": level}
		for seed_number: int in range(1, 21):
			var match_sim = Simulation.new()
			match_sim.start(skills, seed_number, 4.0)
			match_sim.advance(120.0)
			wins += 1 if match_sim.winner == 0 else 0
			total_time += match_sim.elapsed
		print("Habilidades %d contra rivais 4: %d/20 vitórias; duração média %.1f s" % [level, wins, total_time / 20.0])
	quit()
