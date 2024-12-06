extends Node

var player_number: int = 2

# track score of players between levels
var scores: Dictionary = {
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

class PlayerInfo:
	var name: String = ""
	var score: int = 0
	var travel_total: float = 0
	
