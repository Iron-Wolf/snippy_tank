extends Node

var player_number: int = 2

# track score of players between levels
var scores: Dictionary = {
	"1" = 0,
	"2" = 0,
	"3" = 0,
	"4" = 0,
}

# score to win the game
var winning_score: int = 5
# number of round for a level before switching to the next one
var max_round_by_level: int = 4 
# track round number
var current_round: int = 0

# "true" for full feature gameplay scenes 
# and "false" for others (like : user control)
var in_game_scene = true
