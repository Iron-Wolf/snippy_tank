extends Label

@export var player_id: int = 0

func _ready() -> void:
	if player_id == 0:
		Utils.log_error("'player_id' is not defined for : " + self.name)
		get_tree().quit()
	_update_score()

func push_score(add: int) -> void:
	GameState.p_infos[player_id].score += add
	_update_score()

func _update_score() -> void:
	if GameState.p_infos.has(player_id):
		var pi: PlayerInfo = GameState.p_infos[player_id]
		text = pi.to_score_format()
