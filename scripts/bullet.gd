# https://kidscancode.org/godot_recipes/4.x/2d/2d_shooting/
extends Area2D

const SPEED: float = 1000

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position += -transform.y * SPEED * delta

func _on_Bullet_body_entered(body):
	pass
	# TODO : handle colision with other players
	#if body.is_in_group("mobs"):
	#	body.queue_free()
	#queue_free()
