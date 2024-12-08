extends Node

# === VARIABLES THAT CAN CHANGE ===
# number of player in game
var player_number: int = 2
# track player's info between levels
var p_infos: Dictionary = {
	#1: C.PlayerInfo.new(),
}

# score to win the game
var winning_score: int = 5
# number of round for a level before switching to the next one
var max_round_by_level: int = 4 

# track round number
var current_round: int = 0
# "true" for full feature gameplay scenes 
# and "false" for others (like : user control)
var in_game_scene: bool = true

# === NOT ACCESSIBLE VARIABLES ===
# max number used in the settings
const MAX_PLAYER: int = 4

# === OTHER ===
func reset_state() -> void:
	current_round = 0
	for k in range(1, player_number+1):
		p_infos[k] = C.PlayerInfo.new()
		match k:
			1:
				p_infos[k].name = "P1"
				p_infos[k].color = COLOR_1
			2:
				p_infos[k].name = "P2"
				p_infos[k].color = COLOR_2
			3:
				p_infos[k].name = "P3"
				p_infos[k].color = COLOR_3
			4:
				p_infos[k].name = "P4"
				p_infos[k].color = COLOR_4

var COLOR_1: Color = Color.from_string("#bf4100", Color.RED)
var COLOR_2: Color = Color.from_string("#2f6aff", Color.BLUE)
var COLOR_3: Color = Color.from_string("#978961", Color.BEIGE)
var COLOR_4: Color = Color.from_string("#00892b", Color.FOREST_GREEN)
