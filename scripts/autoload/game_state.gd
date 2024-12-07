extends Node

# === VARIABLES THAT CAN CHANGE ===
# number of player in game
var player_number: int = 2
# track player's info between levels
var p_infos: Dictionary = {
	1: PlayerInfo.new(),
	2: PlayerInfo.new(),
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
class PlayerInfo:
	var name: String = ""
	var score: int = 0
	var travel_total: float = 0

func reset_state() -> void:
	current_round = 0
	for k in range(1, MAX_PLAYER+1):
		p_infos[k] = PlayerInfo.new()
