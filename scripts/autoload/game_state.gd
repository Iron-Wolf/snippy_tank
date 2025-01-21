extends Node

# === EXPOSED VARIABLES ===
# number of player in game
var player_number: int = 2
# score to win the game
var winning_score: int = 20
# number of round for a level before switching to the next one
var max_round_by_level: int = 3
# time to wait before a Power Up is spawned
var timer_power_up: int = 30

# === INTERNAL VARIABLES ===
# track player's info between levels
var p_infos: Dictionary = {
	#1: PlayerInfo.new(),
}
# track round number (displayed on screen)
var current_round: int = 0
# curent loaded level
var current_lvl_id: int = 0
# max number of lvl (used to warp around to the first one, if needed)
const MAX_LVL: int = 14
# "true" for full feature gameplay scenes 
# and "false" for others (like : user control)
var in_game_scene: bool = true
# max number (used in the settings)
const MAX_PLAYER: int = 4
# keep track of the main screen audio playback position
var main_audio_playback: float = -1

# === OTHER ===
func reset_state() -> void:
	current_round = 0
	current_lvl_id = 0
	for k in range(1, player_number+1):
		var pi: PlayerInfo = PlayerInfo.new()
		match k:
			1:
				pi.player_id = 1
				pi.name = "P1"
				pi.color = COLOR_1
			2:
				pi.player_id = 2
				pi.name = "P2"
				pi.color = COLOR_2
			3:
				pi.player_id = 3
				pi.name = "P3"
				pi.color = COLOR_3
			4:
				pi.player_id = 4
				pi.name = "P4"
				pi.color = COLOR_4
		p_infos[k] = pi

var COLOR_1: Color = Color.from_string("#bf4100", Color.RED)
var COLOR_2: Color = Color.from_string("#2f6aff", Color.BLUE)
var COLOR_3: Color = Color.from_string("#978961", Color.BEIGE)
var COLOR_4: Color = Color.from_string("#00892b", Color.FOREST_GREEN)

var GRP_RESPAWN = "respawn_process"

func get_players_by_score() -> Array[PlayerInfo]:
	var order: Array[PlayerInfo] = []
	var max_val: int = 0
	# find max value of each player's score
	for pi:PlayerInfo in GameState.p_infos.values():
		max_val = pi.score if pi.score > max_val else max_val
	# order player from top to bottom
	for i in range(max_val, -1, -1):
		for pi:PlayerInfo in GameState.p_infos.values():
			if pi.score == i: 
				order.push_back(pi)
	return order

## one player killed every other one
func get_player_perfect_score(duplicate: int = 0) -> PlayerInfo:
	for pi:PlayerInfo in GameState.p_infos.values():
		if pi.score_round == (player_number-1) + duplicate:
			return pi
	return null

func reset_score_round() -> void:
	for pi:PlayerInfo in GameState.p_infos.values():
		pi.score_round = 0
