extends Label

@export var player_id: int = 0
var init_text: String = text

func _ready() -> void:
	if player_id == 0:
		Utils.log_error("'player_id' is not defined for : " + self.name)
		get_tree().quit()
	_update_score()

func push_score(add: int) -> void:
	GameState.scores[str(player_id)] += add
	_update_score()

func _update_score() -> void:
	text = init_text + str(GameState.scores[str(player_id)])
