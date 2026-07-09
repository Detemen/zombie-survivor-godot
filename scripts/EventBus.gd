## Global signal bus for events that cross scene boundaries.
extends Node

signal run_started
signal run_finished(victory: bool)
signal player_health_changed(current_health: float, max_health: float)
signal player_level_changed(level: int)
signal player_xp_changed(current_xp: int, required_xp: int)
signal kill_count_changed(kill_count: int)
