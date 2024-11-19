# https://kidscancode.org/godot_recipes/4.x/2d/car_steering/
extends CharacterBody2D

## Projectile fired by the player
@export var Bullet: PackedScene

# constants
const STEERING_ANGLE: float = 300
const MAX_SPEED: float = 1000
const FRICTION: float = -55
const DRAG: float = -0.06
const BRAKING_SPEED: float = -800
const STOP_THRESHOLD: float = 30.0  # stop when speed is below

# variables
var acceleration: Vector2 = Vector2.ZERO
var steer_direction: float = 0
var aim_direction: Vector2 = Vector2.ZERO
var last_aim_direction: Vector2 = Vector2.ZERO

func _physics_process(delta):
	# move tank
	acceleration = Vector2.ZERO
	update_accel()
	apply_friction(delta)
	apply_rotation(delta)
	velocity += acceleration * delta
	move_and_slide()
	
	# aim barrel
	#var barrel: Sprite2D = get_node("barrel")
	if (aim_direction != Vector2.ZERO):
		# apply aim globally (offset the tank rotation)
		var current_aim_direction = aim_direction.rotated(-rotation)
		$barrel.rotation = current_aim_direction.angle() + PI/2
		last_aim_direction = aim_direction
	else:
		# keep aim to the last inputed direction
		var current_aim_direction = last_aim_direction.rotated(-rotation)
		$barrel.rotation = current_aim_direction.angle() + PI/2
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
func _unhandled_input(_event: InputEvent) -> void:
	var tank_turn = Input.get_axis("move_left", "move_right")
	steer_direction = tank_turn * deg_to_rad(STEERING_ANGLE)
	aim_direction = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")

func update_accel() -> void:
	if Input.is_action_pressed("move_fw"):
		acceleration = transform.x * MAX_SPEED
	if Input.is_action_pressed("move_bw"):
		acceleration = transform.x * BRAKING_SPEED

func apply_friction(delta):
	if acceleration == Vector2.ZERO and velocity.length() < STOP_THRESHOLD:
		velocity = Vector2.ZERO
	var friction_force = velocity * FRICTION * delta
	var drag_force = velocity * velocity.length() * DRAG * delta
	acceleration += drag_force + friction_force

func apply_rotation(delta: float) -> void:
	rotation += steer_direction * delta

func shoot():
	var b = Bullet.instantiate()
	owner.add_child(b)
	b.transform = $barrel/spawn_bullet.global_transform


func _on_area_2d_body_entered(body: Node2D) -> void:
	# TODO: handle enemy interaction
	pass # Replace with function body.
