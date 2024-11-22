# https://kidscancode.org/godot_recipes/4.x/2d/car_steering/
extends CharacterBody2D

## Id used for input action (like "right_1" for "player 1")
## Need to start at 1 (we use "0" to throw an error)
@export var player_id: int = 0
@export var tank_texture: Texture2D
@export var barrel_texture: Texture2D
signal fight_started

@onready var screen_size:Vector2 = get_viewport_rect().size
@onready var audio: AudioStreamPlayer = $"../background_audio"
const sl: GDScript = preload("res://scripts/static_lib.gd")
const bullet: PackedScene = preload("res://scenes/bullet.tscn")

# constants
enum Scheme {BASIC, ARCADE, SIMULATION}
const CONTROL_SCHEME: Scheme = Scheme.BASIC
const STEERING_ANGLE: float = 400
const MAX_SPEED: float = 1000
const FRICTION: float = -55
const DRAG: float = -0.06
const BRAKING_SPEED: float = -800
const STOP_THRESHOLD: float = 30.0  # stop when speed is below

# variables
var acceleration: Vector2 = Vector2.ZERO
var steer_direction: float = 0
var move_direction: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.ZERO
var last_aim_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	var falat_error: bool = false
	if player_id == 0:
		sl.log_error("'player_id' is not defined for : " + self.name)
		falat_error = true
	if tank_texture == null or barrel_texture == null:
		sl.log_error("missing texture for : " + self.name)
		falat_error = true
	if falat_error:
		get_tree().quit()
	
	$tank.texture = tank_texture;
	$barrel.texture = barrel_texture;

func _physics_process(delta):
	# move tank
	acceleration = Vector2.ZERO
	if CONTROL_SCHEME == Scheme.BASIC:
		acceleration = move_direction * MAX_SPEED
		if move_direction:
			apply_rotation_basic(delta)
	elif CONTROL_SCHEME == Scheme.ARCADE:
		update_accel()
		apply_rotation(delta)
	
	apply_friction(delta)
	velocity += acceleration * delta
	move_and_slide()
	# wrap after movement
	position = sl.apply_screen_wrap(position, screen_size)
	
	# aim barrel
	if aim_direction:
		# apply aim globally (offset the tank rotation)
		var current_aim_direction = aim_direction.rotated(-rotation)
		$barrel.rotation = current_aim_direction.angle() + PI/2
		last_aim_direction = aim_direction
	
	if Input.is_action_just_pressed(f("shoot")):
		shoot()
	
func _unhandled_input(_event: InputEvent) -> void:
	move_direction = Input.get_vector(
		f("move_left"), f("move_right"), f("move_up"), f("move_down"))
	aim_direction = Input.get_vector(
		f("aim_left"), f("aim_right"), f("aim_up"), f("aim_down"))
	steer_direction = move_direction.x * deg_to_rad(STEERING_ANGLE)

# format action name with the player_id
func f(action: String) -> String:
	return "p%s_"%player_id + action

func update_accel() -> void:
	if Input.is_action_pressed(f("move_up")):
		acceleration = transform.x * MAX_SPEED
	if Input.is_action_pressed(f("move_down")):
		acceleration = transform.x * BRAKING_SPEED

func apply_friction(delta):
	if acceleration == Vector2.ZERO and velocity.length() < STOP_THRESHOLD:
		velocity = Vector2.ZERO
	var friction_force = velocity * FRICTION * delta
	var drag_force = velocity * velocity.length() * DRAG * delta
	acceleration += drag_force + friction_force

func apply_rotation_basic(delta: float) -> void:
	var currentRotation = rotation
	var targetRotation = move_direction.angle()
	rotation = lerp_angle(
		currentRotation, targetRotation, deg_to_rad(STEERING_ANGLE) * delta)

func apply_rotation(delta: float) -> void:
	rotation += steer_direction * delta

func shoot():
	fight_started.emit()
	var b = bullet.instantiate()
	owner.add_child(b)
	b.transform = $barrel/spawn_bullet.global_transform

func _on_area_2d_body_entered(_body: Node2D) -> void:
	# TODO: handle enemy interaction
	pass # Replace with function body.
