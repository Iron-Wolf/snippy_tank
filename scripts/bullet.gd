# https://kidscancode.org/godot_recipes/4.x/2d/2d_shooting/
extends Area2D

@onready var screen_size = get_viewport_rect().size
@onready var time_before_active = get_tree().create_timer(TIME_BEFORE_ACTIVE)
var origin_body: CharacterBody2D # use for a kill feed (or the end screen)

const SPEED: float = 1000
const TIME_BEFORE_ACTIVE: float = 0.02 # time (sec) to avoid suicide when spawned
const KEEP_VELOCITY: bool = false

var translate_direction: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# continuous forward movement until we hit something
	position += -transform.y * SPEED * delta
	position = Utils.apply_screen_wrap(position, screen_size)
	if KEEP_VELOCITY:
		# apply player momentum to the bullet
		translate(translate_direction * delta)

func _on_bullet_body_entered(collided_body) -> void:
	# wait before bullet is really active
	if time_before_active.time_left > 0:
		return
	# kill infos
	var origin_name:String = origin_body.name if origin_body != null else StringName("UNKNOWN")
	print(origin_name + " kill " + collided_body.name)
	
	if collided_body.name == "Player1" \
		or collided_body.name == "Player2":
		collided_body.killed(origin_body.player_id);
	
	# remove the bullet from the scene
	queue_free()
