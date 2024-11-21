# https://kidscancode.org/godot_recipes/4.x/2d/2d_shooting/
extends Area2D

@onready var screen_size = get_viewport_rect().size
const sl = preload("res://scripts/static_lib.gd")

const SPEED: float = 1000

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position += -transform.y * SPEED * delta
	position = sl.apply_screen_wrap(position, screen_size)

func _on_bullet_body_entered(body):
	# TODO : handle collision with other players
	#if body.is_in_group("mobs"):
	#	body.queue_free()
	#queue_free()
	
	# we are colliding with a wall or something
	if body.name != "player1" && body.name != "player2":
		queue_free()
	pass
