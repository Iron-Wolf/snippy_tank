extends Node

# === EXPOSED VARIABLES ===
# number of player in game
var player_number: int = 2
# score to win the game
var winning_score: int = 5
# number of round for a level before switching to the next one
var max_round_by_level: int = 4 

# === INTERNAL VARIABLES ===
# track player's info between levels
var p_infos: Dictionary = {
	#1: PlayerInfo.new(),
}
# track round number
var current_round: int = 0
# "true" for full feature gameplay scenes 
# and "false" for others (like : user control)
var in_game_scene: bool = true
# max number (used in the settings)
const MAX_PLAYER: int = 4

# === OTHER ===
func reset_state() -> void:
	current_round = 0
	for k in range(1, player_number+1):
		var pi: PlayerInfo = PlayerInfo.new()
		match k:
			1:
				pi.name = "P1"
				pi.color = COLOR_1
			2:
				pi.name = "P2"
				pi.color = COLOR_2
			3:
				pi.name = "P3"
				pi.color = COLOR_3
			4:
				pi.name = "P4"
				pi.color = COLOR_4
		p_infos[k] = pi

var COLOR_1: Color = Color.from_string("#bf4100", Color.RED)
var COLOR_2: Color = Color.from_string("#2f6aff", Color.BLUE)
var COLOR_3: Color = Color.from_string("#978961", Color.BEIGE)
var COLOR_4: Color = Color.from_string("#00892b", Color.FOREST_GREEN)
