class_name PlayerInfo

var player_id: int = -1
var name: String = ""
var score: int = 0 # number of kill for a game
var score_round: int = 0 # number of kill for a round
var color: Color = Color.WHITE
var travel_total: float = 0
var shot_total: int = 0

func get_travel_meter() -> int:
	# scale travel distance to a somewhat "meter" unit
	return roundi(travel_total * 0.03)

func to_score_format() -> String:
	return str(name, " : ", score)

func to_stats_format() -> String:
	return str(get_travel_meter(), "m|", shot_total)
