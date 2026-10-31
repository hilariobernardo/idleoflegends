extends SceneTree

const Simulation = preload("res://scripts/match_sim.gd")
class MemoryProgress:
	extends "res://scripts/progression.gd"
	func save_game() -> bool:
		return true

func _initialize() -> void:
	for speed: int in [1]:
		for run: int in [1, 2, 3]:
			var p = MemoryProgress.new()
			p.time_override = 1800000000
			p.save_path = "res://tests/nonexistent_journey_memory.json"
			p.load_save()
			p.xp = 0
			p.lifetime_xp = 0
			p.matches = 0
			p.wins = 0
			p.ladders = {"normal": 0, "ranked": 0}
			p.upgrades = {"farm": 0, "trades": 0, "builds": 0, "macro": 0, "vision": 0}
			p.training_levels = {"videos": 1, "tutoriais": 0, "competicoes": 0, "coach": 0}
			p.training_last_at = p.time_override
			p.ranked_unlocked = false
			var seconds: int = 0
			var first_buy: int = -1
			var first_division: int = -1
			var barro: int = -1
			for n: int in range(120):
				var sim = Simulation.new()
				sim.start(p.upgrades, run * 1000 + n, p.opponent_level())
				sim.advance(120.0)
				var elapsed: int = int(ceil(sim.elapsed / speed)) + 3
				seconds += elapsed
				p.time_override += elapsed
				p.settle_training()
				p.record_match(sim.winner == 0)
				if first_division < 0 and p.ladders.normal >= 100: first_division = seconds
				if barro < 0 and p.ladders.normal >= 400: barro = seconds
				if p.can_unlock_ranked():
					p.unlock_ranked()
					break
				# While below Barro: reinvest up to half the wallet in the best
				# study payback under ten minutes, then buy cheapest skills up to
				# two levels above current rivals. At Barro, save for Ranked.
				if p.ladders.normal < 400:
					var best: String = ""
					var roi: float = 600.0
					for key: String in p.TRAINING_ORDER:
						var cost: int = p.training_cost(key)
						var gain: int = p.training_production(key, p.training_levels[key] + 1) - p.training_production(key)
						if cost > 0 and cost <= p.xp / 2 and float(cost) / gain < roi:
							best = key
							roi = float(cost) / gain
					if best != "": p.buy_training(best)
					for purchase: int in range(30):
						var cheapest: String = ""
						var price: int = p.xp + 1
						for key: String in p.SKILL_ORDER:
							var cost: int = p.upgrade_cost(key)
							if p.upgrades[key] < ceil(p.opponent_level() + 2) and cost > 0 and cost < price:
								cheapest = key
								price = cost
						if cheapest == "": break
						p.buy_upgrade(cheapest)
						if first_buy < 0: first_buy = seconds
			print("speed=%d seed=%d first_buy=%ds division=%ds Barro=%ds Ranked=%s elapsed=%ds matches=%d wins=%d XP/s=%d" % [speed, run, first_buy, first_division, barro, p.ranked_unlocked, seconds, p.matches, p.wins, p.training_rate()])
	quit()
