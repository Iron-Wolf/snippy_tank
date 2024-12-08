extends Sprite2D

var speed: float = randf_range(10,15)
var rot: float = randf_range(-3,3)

func _process(_delta: float) -> void:
	if speed < 0:
		return
	
	position += transform.y * speed
	rotation += deg_to_rad(rot)
	speed = lerpf(speed, -0.1, 0.1)
