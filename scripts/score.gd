extends Label

var score: int = 0
var base_text: String = text

func _ready() -> void:
	text = base_text + str(score)

func increase_score() -> void:
	score += 1
	text = base_text + str(score)
