extends Camera2D

@export var decay: float = 0.8  # How quickly the shaking stops [0, 1].
@export var max_offset: Vector2 = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll: float = 0.1  # Maximum rotation in radians (use sparingly).

var trauma: float = 0  # Current shake strength.
var trauma_power: int = 2  # Trauma exponent. Use [2, 3].

func _process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()

func shake():
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	offset.x = max_offset.x * amount * randf_range(-1, 1)
	offset.y = max_offset.y * amount * randf_range(-1, 1)

func on_fight_started() -> void:
	trauma = 0.3

func on_player_killed() -> void:
	trauma = 0.8
