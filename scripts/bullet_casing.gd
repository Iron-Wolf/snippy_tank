extends Sprite2D

var rand_speed: float = randf_range(10,15)
var rand_rotation: float = randf_range(-3,3)

func _process(_delta: float) -> void:
	if rand_speed < 0:
		return
	
	position += transform.y * rand_speed
	rotation += deg_to_rad(rand_rotation)
	rand_speed = lerpf(rand_speed, -0.1, 0.1)
