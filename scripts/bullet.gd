# https://kidscancode.org/godot_recipes/4.x/2d/2d_shooting/
extends Area2D

@onready var screen_size = get_viewport_rect().size
@onready var time_before_active: Timer = %TimeBeforeActive
var origin_body: CharacterBody2D # use for a kill feed (or the end screen)

const SPEED: float = 1000
const TIME_BEFORE_ACTIVE: float = 0.5 # time (sec) to avoid suicide when spawned
const KEEP_VELOCITY: bool = false

var translate_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	time_before_active.start(TIME_BEFORE_ACTIVE)
	connect("body_entered", _on_bullet_body_entered)

func _physics_process(delta: float) -> void:
	# continuous forward movement until we hit something
	position += -transform.y * SPEED * delta
	position = Utils.apply_screen_wrap(position, screen_size)
	if KEEP_VELOCITY:
		# apply player momentum to the bullet
		translate(translate_direction * delta)

func _on_bullet_body_entered(collided_body) -> void:
	if !GameState.in_game_scene:
		# doing nothing
		queue_free()
		return
	
	# kill infos
	var origin_name:String = origin_body.name \
		if origin_body != null \
		else StringName("UNKNOWN")
	print(origin_name + " kill " + collided_body.name)
	
	# wait before bullet is really active
	if origin_name == collided_body.name \
		and time_before_active.time_left > 0:
		return
	
	var player_array = ["P1", "P2", "P3", "P4"]
	if collided_body.name in player_array and !collided_body.is_killed:
		collided_body.killed(origin_body.player_id);
	
	# remove the bullet from the scene
	queue_free()
