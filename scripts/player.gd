# https://kidscancode.org/godot_recipes/4.x/2d/car_steering/
extends CharacterBody2D

## Id used for input action (like "right_1" for "player 1")
## Need to start at 1 (we use "0" to throw an error)
@export var player_id: int = 0
@export var tank_texture: Texture2D
@export var barrel_texture: Texture2D
var parent_owner: Node # reference to the scene (the level) containing the player
signal fight_started
signal player_killed

@onready var screen_size:Vector2 = get_viewport_rect().size
@onready var init_position: Vector2 = position
@onready var init_rotation: float = rotation
@onready var init_barrel_rotation: float = $Barrel.rotation
const bullet_ps: PackedScene = preload("res://scenes/bullet.tscn")
const track_normal: Texture2D = preload("res://assets/Tanks/tracksSmall2.png")
const track_drift: Texture2D = preload("res://assets/Tanks/tracksSmall5.png")
const explosion_ps: PackedScene = preload("res://scenes/explosion.tscn")
# Need this because "_physics_process" can run during "respawn_process".
# So, "velocity" could receive strange values from "move_and_slide".
# Can be avoided with a high enought KNOCKBACK_ON_COLLIDE or a push back 
# of the collided Node (or when "_physics_process" is skipped...)
# The Timer is a good middle-ground option, and should be
# hidden behind a "3,2,1 Go" animation at the start of the round.
var time_before_active: SceneTreeTimer

# constants
const STEERING_ANGLE: float = 400
const MAX_SPEED: float = 1000
const FRICTION: float = -55
const DRAG: float = -0.06
const BRAKING_SPEED: float = -800
const STOP_THRESHOLD: float = 30  # stop when speed is below
const KNOCKBACK_ON_COLLIDE: int = 40
const SHOOT_TIMER: float = 3 # cooldown (sec) before each shoot
const START_AMMO: int = -1 # "-1" for infinite
const ANIM_SHAKE_SPEED: int = 15
const KNOCKBACK_ON_SHOOT: int = 0

# variables
var is_killed: bool = false
var acceleration: Vector2 = Vector2.ZERO
var steer_direction: float = 0
var move_direction: Vector2 = Vector2.ZERO
var current_speed: float = 0
var aim_direction: Vector2 = Vector2.ZERO
var last_aim_direction: Vector2 = Vector2.ZERO
var ammo_left: int
var travel_total: float = 0 # cumulated distance traveled
var travel_total_previous: float = 0 # detect if player has moved
var travel_place_track: float = 0 # loop to "0" every 100 units
var current_loaded_tracks: Array = []

var debug_dict: Dictionary = {}
const DEBUG: bool = false

#region starting logic
func _ready() -> void:
	var falat_error: bool = false
	if player_id == 0:
		Utils.log_error("'player_id' is not defined for : " + self.name)
		falat_error = true
	if tank_texture == null or barrel_texture == null:
		Utils.log_error("missing texture for : " + self.name)
		falat_error = true
	if falat_error:
		get_tree().quit()
	
	$Tank.texture = tank_texture
	$Barrel.texture = barrel_texture
	$ShootTimer.wait_time = SHOOT_TIMER
	$ShootTimer.connect("timeout", func():
		_shoot_cooldown(Color.WHITE))

	respawn_process()
#endregion

func _physics_process(delta):
	if time_before_active.time_left != 0 or is_killed:
		return
	
	#region movement
	var position_before = position
	acceleration = Vector2.ZERO
	match PlayerState.control_scheme:
		PlayerState.Scheme.SIMPLE:
			acceleration = move_direction * MAX_SPEED
			if move_direction:
				apply_rotation_basic(delta)
		PlayerState.Scheme.ARCADE:
			update_accel()
			apply_rotation(delta)
	
	apply_friction(delta)
	velocity += acceleration * delta

	# actual move and resolve collision
	if move_and_slide():
		apply_collistion()
	
	# screen wrap after movement
	# TODO : move this in each level's script
	position = Utils.apply_screen_wrap(position, screen_size)
	#endregion
	
	#region aim and shoot
	if aim_direction:
		# apply aim globally
		apply_aim(aim_direction)
		last_aim_direction = aim_direction
	elif PlayerState.last_aim_scheme and last_aim_direction:
		# keep aim to the last inputed direction
		apply_aim(last_aim_direction)
	
	if Input.is_action_just_pressed(f("shoot")):
		shoot_triggered()
	#endregion
	
	#region miscellaneous feedback
	@warning_ignore("integer_division")
	var shake = 1 \
		if get_tree().get_frame() % ANIM_SHAKE_SPEED*2 > ANIM_SHAKE_SPEED \
		else -1
	$Tank.position.y = shake
	$Barrel.position.y = shake
	
	$Smoke.emitting = move_direction != Vector2.ZERO
	
	var drifting: bool = false
	var vr: Vector2 = Vector2(100, 0) # vector in front on the player
	var angle_rot = vr.angle_to(velocity.rotated(-rotation))
	if abs(angle_rot) > deg_to_rad(60):
		drifting = true
	
	travel_total += position_before.distance_to(position)
	if travel_total > travel_total_previous:
		# actually in movement
		var travel_actual = travel_total - travel_total_previous
		travel_total_previous = travel_total
		# track placement logic
		travel_place_track -= travel_actual
		var track_texture = track_normal
		if drifting:
			# increase texture placing rate
			# without too much clutering the background
			travel_place_track /= 10
			track_texture = track_drift
		if travel_place_track < 0:
			# reset to place a track every 30 units
			travel_place_track = 30
			draw_tracks(track_texture)
	#endregion
	
	current_speed = Vector2.ZERO.distance_to(velocity)
	if DEBUG:
		update_debug({
			"velocity" = velocity.rotated(-rotation),
			"move_direction" = move_direction.rotated(-rotation) * 100,
			"acceleration" = acceleration.rotated(-rotation),
		})
	queue_redraw()

func update_debug(dict: Dictionary) -> void:
	for key in dict:
		debug_dict[key] = dict[key]
	
func _draw() -> void:
	if debug_dict.size() == 0:
		return
	draw_line(debug_dict["acceleration"], Vector2.ZERO, Color.GREEN, 5)
	draw_line(debug_dict["velocity"], Vector2.ZERO, Color.BLACK, 4)
	# we rotate the full body, so "rotation" is just displayed in front
	draw_line(Vector2(100, 0), Vector2.ZERO, Color.BLUE, 3)
	draw_circle(debug_dict["move_direction"], 10, Color.RED)
	#print(Engine.get_frames_per_second())

# not optimal function (maybe should I use "draw_texture" ?)
func draw_tracks(texture: Texture2D) -> void:
	var track_sprite = Sprite2D.new()
	track_sprite.texture = texture
	track_sprite.position = position
	track_sprite.rotation = rotation + deg_to_rad(90)
	track_sprite.modulate = Color.BROWN
	parent_owner.add_child(track_sprite)
	# move texture below the player AND walls
	parent_owner.move_child(track_sprite, 1)
	current_loaded_tracks.push_back(track_sprite)

#region movement inputs
func _unhandled_input(_event: InputEvent) -> void:
	var old_aim_direction = aim_direction
	move_direction = Input.get_vector(
		f("move_left"), f("move_right"), f("move_up"), f("move_down"))
	aim_direction = Input.get_vector(
		f("aim_left"), f("aim_right"), f("aim_up"), f("aim_down"))
	steer_direction = move_direction.x * deg_to_rad(STEERING_ANGLE)
	
	if PlayerState.slingshot_scheme and \
		old_aim_direction and !aim_direction:
		shoot_triggered()

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

# code is from : https://catlikecoding.com/godot/true-top-down-2d/3-movable-objects/
func apply_collistion() -> void:
	var c:KinematicCollision2D = get_last_slide_collision()
	if c.get_collider() is CharacterBody2D:
		# Certainly a one of a kind fix to a weird bug.
		# CharacterBody2D must have :
		# 	- Motion Mode to "Grounded" (better game feel)
		#   - Moving Plateform "On Leave" to "Do Nothing" (we are top down)
		# Guess what! The "velocity" is still transfered to other objects
		# when "move_and_slide()" is called (with absurd values).
		# So, we move backward (applying inverse colision vector),
		# as a countermeasure to Godot's moving logic.
		velocity -= KNOCKBACK_ON_COLLIDE * c.get_normal().rotated(deg_to_rad(180))
		# We can apply a "push" movement if we want
		# (friction will be handled by player's logic)
		c.get_collider().velocity -= 0 * c.get_normal()
	#region test with RigidBody2D (must have gravity to 0)
	#elif c.get_collider() is RigidBody2D:
		#velocity -= 40 * c.get_normal().rotated(deg_to_rad(180))
		#c.get_collider().apply_force(-10000.0 * c.get_normal())
	#endregion

func apply_rotation_basic(delta: float) -> void:
	var currentRotation: float = rotation
	var targetRotation: float = move_direction.angle()
	rotation = lerp_angle(
		currentRotation, targetRotation, deg_to_rad(STEERING_ANGLE) * delta)

func apply_rotation(delta: float) -> void:
	rotation += steer_direction * delta
#endregion

#region aim and shoot inputs
func apply_aim(direction: Vector2) -> void:
	var target_aim: float = direction.rotated(-rotation).angle()
	# offset with tank rotation
	var target_aim_offset: float = target_aim + deg_to_rad(90)
	$Barrel.rotation = lerp_angle($Barrel.rotation, target_aim_offset, 0.8)

func shoot_triggered() -> void:
	# check cooldown
	if $ShootTimer.time_left != 0:
		return
	if ammo_left == 0:
		return
	ammo_left -= 1
	var b:Area2D = bullet_ps.instantiate()
	b.origin_body = self
	b.translate_direction = velocity
	parent_owner.add_child(b)
	b.transform = $Barrel/SpawnBullet.global_transform
	
	fight_started.emit()
	$ShootAudio.play(0.4)
	velocity -= Vector2(KNOCKBACK_ON_SHOOT, 0) \
		.rotated($Barrel.global_rotation - deg_to_rad(90))
	
	# TODO : should be a property in the "bullet" object
	var explosion: CPUParticles2D = explosion_ps.instantiate()
	explosion.transform = $Barrel/SpawnBullet.global_transform
	explosion.gravity = Vector2(1000, 0) \
		.rotated($Barrel/SpawnBullet.global_rotation - deg_to_rad(90))
	explosion.speed_scale = 2
	parent_owner.add_child(explosion)
	explosion.emitting = true
	$ShootTimer.start()
	_shoot_cooldown(Color.DIM_GRAY)

func _shoot_cooldown(color: Color) -> void:
	$Tank.modulate = color
	$Barrel.modulate = color
#endregion

func killed(origin_player_id: int) -> void:
	var score_label = "%" + "P%sScore" % origin_player_id
	parent_owner \
		.get_node(score_label) \
		.push_score(1 if origin_player_id != player_id else -1)
	
	# TODO : handle this with signals ?
	var explosion: CPUParticles2D = explosion_ps.instantiate()
	explosion.transform = transform
	explosion.scale = Vector2(2,2)
	parent_owner.add_child(explosion)
	explosion.emitting = true
	
	is_killed = true
	$Barrel.visible = false
	# spread info when all is set
	player_killed.emit()
	$KillAudio.play()

func respawn_process() -> void:
	is_killed = false
	$Barrel.visible = true
	# reset game logic
	ammo_left = START_AMMO
	$ShootTimer.start()
	_shoot_cooldown(Color.DIM_GRAY)
	time_before_active = get_tree().create_timer(0.3)
	# reset positions
	velocity = Vector2.ZERO
	position = init_position
	rotation = init_rotation
	$Barrel.rotation = init_barrel_rotation
	# free ressources
	for track_sprite:Sprite2D in current_loaded_tracks:
		track_sprite.queue_free()
	current_loaded_tracks = []
	
