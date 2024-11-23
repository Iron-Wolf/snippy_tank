# https://kidscancode.org/godot_recipes/4.x/2d/2d_shooting/
extends Area2D

@onready var screen_size = get_viewport_rect().size
const sl = preload("res://scripts/static_lib.gd")
@onready var time_before_active = get_tree().create_timer(TIME_BEFORE_ACTIVE)
var origin_shoot: CharacterBody2D # use for a kill feed (or the end screen)

const SPEED: float = 1000
const TIME_BEFORE_ACTIVE: float = 0.02 # time (sec) to avoid suicide when spawned

func _physics_process(delta: float) -> void:
	position += -transform.y * SPEED * delta
	position = sl.apply_screen_wrap(position, screen_size)

func _on_bullet_body_entered(body) -> void:
	# wait before bullet is really active
	if time_before_active.time_left > 0:
		return
	# kill infos
	var o = origin_shoot.name if origin_shoot != null else StringName("UNKNOWN")
	print(o + " kill " + body.name)
	
	if body.name == "player1" or body.name == "player2":
		body.kill();
	
	# remove the bullet from the scene
	queue_free()
