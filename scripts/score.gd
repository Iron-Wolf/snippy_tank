extends Label

var score: int = 0
var base_text: String = text

func _ready() -> void:
	text = base_text + str(score)

func push_score(add: int) -> void:
	score += add
	text = base_text + str(score)
