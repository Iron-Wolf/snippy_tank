class_name Player extends CharacterBody2D

## Id used for input action (like "right_1" for "player 1")
## Need to start at 1 (we use "0" to throw an error)
@export var player_id: int = 0
@export var tank_texture: Texture2D
@export var barrel_texture: Texture2D
var parent_owner # reference to the "level" containing the player
var spw_tracks: Marker2D
signal fight_started
signal player_killed(killer_id: int, killed_id: int)

@onready var screen_size:Vector2 = get_viewport_rect().size 
@onready var init_rotation: float = rotation
@onready var init_barrel_rotation: float = $Barrel.rotation
# NOTICE: can be wrong if we change the position in the object tree
@onready var index_position_in_parent: int = get_index()
const bullet_ps: PackedScene = preload("res://scenes/bullet.tscn")
const bullet_casing_ps: PackedScene = preload("res://scenes/bullet_casing.tscn")
const track_normal: Texture2D = preload("res://assets/Tanks/tracksSmall2.png")
const track_drift: Texture2D = preload("res://assets/Tanks/tracksSmall5.png")
const invert_shader: Shader = preload("res://shader/invert_color.gdshader")
# Need this because "_physics_process" can run during "respawn_process".
# So, "velocity" could receive strange values from "move_and_slide".
# Can be avoided with a high enought KNOCKBACK_ON_COLLIDE or a push back 
# of the collided Node (for now, I just skip "_physics_process"...)
# The Timer is a good middle-ground option, and should be
# hidden behind a "3,2,1 Go" animation at the start of the round.
var time_before_active: SceneTreeTimer

# constants
const STEERING_ANGLE: float = 400
var MAX_SPEED: float = 1000
const FRICTION: float = -55
var DRAG: float = -0.06
const BRAKING_SPEED: float = -800
const STOP_THRESHOLD: float = 30  # stop when speed is below
const KNOCKBACK_ON_COLLIDE: int = 40
var MAX_AMMO: int = 3 # "-1" for infinite
var ANIM_SHAKE_SPEED: int = 15
const KNOCKBACK_ON_SHOOT: int = 0
const INIT_LOB_DISTANCE: float = 200

# variables
var init_position: Vector2:
	set(value): init_position = value; position = value
var is_duplicate: bool = false
var is_killed: bool = false
var is_falling: bool = false
var acceleration: Vector2 = Vector2.ZERO
var steer_direction: float = 0
var move_direction: Vector2 = Vector2.ZERO
var inverse_control: bool = false
var current_speed: float = 0
var aim_direction: Vector2 = Vector2.ZERO
var last_aim_direction: Vector2 = Vector2.ZERO
var held_shot: float = 0 # wait frames then start "hold shot" logic
var ammo_left: int
var shoot_cooldown: float = PlayerState.shoot_timer
var bullet_fired: int = 1 # number of bullet fired on each shot
var _multi_shot_max_angle: int = 15
var bounce_bullet: bool = false
var lob_shot: bool = false
var lob_distance: float = INIT_LOB_DISTANCE
var shot_total: int = 0 # cumulated number of shot
var travel_total: float = 0 # cumulated distance traveled
var travel_place_track: float = 0 # loop to "0" every 100 units
var _current_loaded_tracks: Array[Sprite2D] = []

var debug_dict: Dictionary = {}
const DEBUG: bool = false

#region starting logic
func _ready() -> void:
	var falat_error: bool = false
	if (player_id == 0):
		Utils.log_error("'player_id' is not defined for : " + self.name)
		falat_error = true
	if tank_texture == null or barrel_texture == null:
		Utils.log_error("missing texture for : " + self.name)
		falat_error = true
	if falat_error:
		get_tree().quit()
	
	$Tank.texture = tank_texture
	$Barrel.texture = barrel_texture
	$ShootTimer.wait_time = shoot_cooldown
	$ShootTimer.connect("timeout", func():
		# reload ALL ammo (with the power up, 
		# ammo_left can be reset during a cooldown)
		if ammo_left == 0 or ammo_left == MAX_AMMO:
			ammo_left = MAX_AMMO
			return
		# reload and restart timer, until we are maxed
		ammo_left += 1
		if ammo_left != MAX_AMMO:
			$ShootTimer.start(shoot_cooldown))
	%LobShotTimer.connect("timeout", func():
		lob_shot = true)
	%ReloadBar.value = 0

	respawn_process()
#endregion

func _process(_delta: float) -> void:
	var parent_world: World = parent_owner as World
	if parent_world:
		var tilemap: TileMapLayer = parent_world.get_background_tilemap()
		for track_sprite:Sprite2D in _current_loaded_tracks:
			if !track_sprite: continue
			var cell_coords = tilemap.local_to_map(track_sprite.position * 2)
			if tilemap.get_cell_source_id(cell_coords) == -1:
				track_sprite.queue_free()

func _physics_process(delta) -> void:
	# bullet reloading indicator
	%ReloadBar.position = position
	%ReloadBar.position.x += 20
	%ReloadBar.position.y += 20
	
	if is_falling:
		scale = clamp(scale - Vector2(delta, delta), Vector2.ZERO, Vector2.INF)
		%EngineSmoke.emitting = false
	
	if time_before_active.time_left != 0 or is_killed:
		return
	
	#region movement
	position = Utils.apply_screen_wrap(position, screen_size)
	var position_before = position # must call this AFTER screen warping
	
	# check map tile AFTER warp position
	var parent_world: World = parent_owner as World
	if parent_world:
		var tilemap: TileMapLayer = parent_world.get_background_tilemap()
		# the Sprite is larger than the base cell size, so we scale up the position
		var cell_coords = tilemap.local_to_map(position * 2)
		if tilemap.get_cell_source_id(cell_coords) == -1:
			is_killed = true
			is_falling = true
			# kill logic without the camera effect
			parent_world._on_player_killed(player_id, player_id)
			# move player behind all background
			parent_world.move_child(self, 0)
	
	acceleration = Vector2.ZERO
	match PlayerState.control_scheme:
		PlayerState.Scheme.SIMPLE:
			acceleration = move_direction * MAX_SPEED
			if move_direction:
				apply_rotation_basic(delta)
		PlayerState.Scheme.ARCADE:
			update_accel()
			apply_rotation(delta)
		PlayerState.Scheme.EXPERT:
			var x_axis = Input.get_axis(f("move_down"),f("move_up"))
			var y_axis = Input.get_axis(f("aim_down"),f("aim_up"))
			rotation += (x_axis-y_axis) * deg_to_rad(STEERING_ANGLE/2) * delta
			acceleration = transform.x * (x_axis+y_axis) * MAX_SPEED/2
	
	apply_friction(delta)
	velocity += acceleration * delta

	# actual move and resolve collision
	if move_and_slide():
		apply_collision()
	#endregion
	
	#region aim and shoot
	if aim_direction:
		# apply aim globally
		apply_aim(aim_direction)
		last_aim_direction = aim_direction
	elif PlayerState.last_aim_scheme and last_aim_direction:
		# keep aim to the last inputed direction
		apply_aim(last_aim_direction)
	
	if Input.is_action_pressed(f("shoot")):
		if lob_shot:
			held_shot += 1
			if held_shot > 15: # wait some frames
				lob_distance = lerpf(lob_distance, 500, 0.02)
		else:
			held_shot = 0
			lob_distance = INIT_LOB_DISTANCE
	elif Input.is_action_just_released(f("shoot")):
		shoot_triggered()
		held_shot = 0
		lob_distance = INIT_LOB_DISTANCE
	#endregion
	
	#region miscellaneous feedback
	@warning_ignore("integer_division")
	var shake = 1 \
		if get_tree().get_frame() % ANIM_SHAKE_SPEED*2 > ANIM_SHAKE_SPEED \
		else -1
	$Tank.position.y = shake
	$Barrel.position.y = shake
	
	# animate brightness related to shoot cooldown
	var percent_time_left: float = $ShootTimer.time_left / $ShootTimer.wait_time
	if $ShootTimer.time_left == 0:
		sprite_modulate(Color.WHITE)
	elif ammo_left <= 0 and $ShootTimer.time_left < 0.5:
		$Tank.modulate.v = 1.0 if shake == 1 else 0.3
		$Barrel.self_modulate.v = 1.0 if shake == 1 else 0.3
	elif ammo_left <= 0:
		# increasing value to 1
		var percent_time_opposite: float = 1 - percent_time_left
		$Tank.modulate.v = percent_time_opposite
		$Barrel.self_modulate.v = percent_time_opposite
	%ReloadBar.value = percent_time_left * 100
	
	%EngineSmoke.emitting = move_direction != Vector2.ZERO
	
	var drifting: bool = false
	var vr: Vector2 = Vector2(100, 0) # vector in front on the player
	var angle_rot = vr.angle_to(velocity.rotated(-rotation))
	if abs(angle_rot) > deg_to_rad(60):
		drifting = true
	
	var travel_actual = position_before.distance_to(position)
	travel_total += travel_actual
	if velocity != Vector2.ZERO:
		%LobShotTimer.stop()
		lob_shot = false
		# check if we place a track on the background
		travel_place_track -= travel_actual
		var track_texture = track_normal
		DRAG = -0.06
		if drifting:
			# increase texture placing rate
			# without too much clutering the background
			travel_place_track /= 10
			track_texture = track_drift
			# speedup lob_shot position, with a high DRAG value
			if !move_direction: DRAG = -3
		if travel_place_track < 0:
			# reset to place a track every 30 units
			travel_place_track = 30
			draw_tracks(track_texture)
	else:
		# not moving
		if !lob_shot and %LobShotTimer.is_stopped():
			%LobShotTimer.start()
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
	if lob_shot:
		# draw a target (because I'm a dev, not a designer)
		var offset_spawn_bullet = 55
		var target_center = aim_direction.rotated(-rotation) * (lob_distance+offset_spawn_bullet)
		draw_line(Vector2(target_center.x-10, target_center.y), \
			Vector2(target_center.x+10, target_center.y), \
			Color.WHITE, 5)
		draw_line(Vector2(target_center.x, target_center.y-10), \
			Vector2(target_center.x, target_center.y+10), \
			Color.WHITE, 5)
	
	if debug_dict.size() != 0:
		draw_line(debug_dict["acceleration"], Vector2.ZERO, Color.GREEN, 5)
		draw_line(debug_dict["velocity"], Vector2.ZERO, Color.BLACK, 4)
		# we rotate the full body, so "rotation" is just displayed in front
		draw_line(Vector2(100, 0), Vector2.ZERO, Color.BLUE, 3)
		draw_circle(debug_dict["move_direction"], 10, Color.RED)
		#print(Engine.get_frames_per_second())

# not optimal function (maybe should I use "draw_texture" ?)
func draw_tracks(texture: Texture2D) -> void:
	if (spw_tracks == null): return
	var track_sprite = Sprite2D.new()
	track_sprite.texture = texture
	track_sprite.position = position
	track_sprite.rotation = rotation + deg_to_rad(90)
	track_sprite.modulate = Color(Color.BROWN, 0.3)
	# put texture below the player AND walls
	spw_tracks.add_child(track_sprite)
	_current_loaded_tracks.push_back(track_sprite)

func inverse_color(b: bool) -> void:
	if b:
		var override_material = ShaderMaterial.new()
		override_material.shader = invert_shader
		$Tank.material = override_material
		$Barrel.material = override_material
	else:
		$Tank.material = null
		$Barrel.material = null

#region movement inputs
func _unhandled_input(_event: InputEvent) -> void:
	var old_aim_direction = aim_direction
	move_direction = Input.get_vector(
		f("move_left"), f("move_right"), f("move_up"), f("move_down"))
	aim_direction = Input.get_vector(
		f("aim_left"), f("aim_right"), f("aim_up"), f("aim_down"))
	steer_direction = move_direction.x * deg_to_rad(STEERING_ANGLE)
	
	if inverse_control:
		move_direction *= -1
	
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
func apply_collision() -> void:
	var c:KinematicCollision2D = get_last_slide_collision()
	if c.get_collider() is CharacterBody2D:
		# NOTE : Certainly a one of a kind fix to a weird bug.
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
	if PlayerState.control_scheme == PlayerState.Scheme.EXPERT:
		return
	
	var target_aim: float = direction.rotated(-rotation).angle()
	# offset with tank rotation
	var target_aim_offset: float = target_aim + deg_to_rad(90)
	$Barrel.rotation = lerp_angle($Barrel.rotation, target_aim_offset, 0.8)

func shoot_triggered() -> void:
	# check cooldown
	if ammo_left <= 0 and $ShootTimer.time_left != 0:
		return
	if ammo_left == 0:
		return
	ammo_left -= 1
	shot_total += 1
	
	var spwn_bullet_id: int = 2 if bullet_fired == 1 else 1
	for i:int in range(0, bullet_fired):
		var b:Bullet = bullet_ps.instantiate()
		b.origin_body = self
		b.translate_direction = velocity
		b.bounce_bullet = bounce_bullet
		b.lob_shot = lob_shot
		b.lob_distance = lob_distance
		var spw = get_node("Barrel/SpawnBullet%s"%spwn_bullet_id)
		b.transform = spw.global_transform
		var rand_a: int = 0 # default bullet angle
		if spwn_bullet_id == 1:
			rand_a = randi_range(-_multi_shot_max_angle, 0)
		elif spwn_bullet_id == 3:
			rand_a = randi_range(0, _multi_shot_max_angle)
		b.rotate(deg_to_rad(rand_a))
		# next shot position
		spwn_bullet_id += 1
		b.add_to_group(GameState.GRP_RESPAWN)
		parent_owner.add_child(b)
	
	var bc = bullet_casing_ps.instantiate()
	bc.transform = $Barrel/SpawnBullet2.global_transform
	if (spw_tracks != null):
		spw_tracks.add_child(bc)  
	
	fight_started.emit()
	Input.start_joy_vibration(player_id-1, 0.3, 0, 0.1) # weak vibration  
	$ShootAudio.play(0.4)
	%ShootSmoke.emitting = true
	velocity -= Vector2(KNOCKBACK_ON_SHOOT, 0) \
		.rotated($Barrel.global_rotation - deg_to_rad(90))
	
	if ammo_left == 0:
		$ShootTimer.start(shoot_cooldown * 1.5)
	else:
		$ShootTimer.start(shoot_cooldown * 0.75)

func sprite_modulate(color: Color) -> void:
	$Tank.modulate = color
	$Barrel.self_modulate = color
#endregion

func killed(origin_player_id: int) -> void:
	is_killed = true
	$Barrel.visible = false
	%KillSmoke.emitting = true
	# spread info when all is set
	player_killed.emit(origin_player_id, player_id)
	$KillAudio.play()

func respawn_process() -> void:
	is_killed = false
	is_falling = false
	$Barrel.visible = true
	%KillSmoke.emitting = false
	# reset game logic
	ammo_left = MAX_AMMO
	sprite_modulate(Color.WHITE)
	$ShootTimer.stop()
	time_before_active = get_tree().create_timer(1)
	# reset positions
	velocity = Vector2.ZERO
	position = init_position
	rotation = init_rotation
	$Barrel.rotation = init_barrel_rotation
	parent_owner.move_child(self, index_position_in_parent)
	scale = Vector2(1, 1)
	# free ressources
	#for track_sprite:Sprite2D in _current_loaded_tracks:
	#	track_sprite.queue_free()
	#	pass
	#_current_loaded_tracks = []

func _exit_tree() -> void:
	var pi: PlayerInfo = GameState.p_infos[player_id]
	pi.travel_total = travel_total
	pi.shot_total = shot_total
