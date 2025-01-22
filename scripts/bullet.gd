class_name Bullet extends RigidBody2D

@onready var screen_size = get_viewport_rect().size
@onready var smoke: CPUParticles2D = %Smoke
@onready var explosion: CPUParticles2D = %Explosion
@onready var barrel_part: PackedScene = preload("res://scenes/levels/barrel_part.tscn")
var upward_txt: Texture2D = preload("res://assets/Bullets/bulletBeigeSilver_outline_upward.png")
var downward_txt: Texture2D = preload("res://assets/Bullets/bulletBeigeSilver_outline_downward.png")
@onready var position_before: Vector2 = position
var origin_body: CharacterBody2D # use for a kill feed (or the end screen)
var bounce_bullet: bool
var lob_shot: bool: # keep track of the bullet behaviour when created
	set(value):
		lob_shot = value
		lob_shot_process = value
var lob_shot_process: bool = false # used for the "_physics_process" logic
var lob_distance: float = 300 # maximum distance for the lobbed shot

const SPEED: float = 1000
const KEEP_VELOCITY: bool = false

var translate_direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var _spawned: bool = true # prevent stuck bullet on first frame
var init_position: Vector2 # starting position (lobbed shot)
var target_position: Vector2 # target position (lobbed shot)
var travel_total: float = 0 # cumulated distance traveled (lobbed shot)
var _lob_scale: Vector2 = Vector2(0.1, 0.1) # scale size factor, during the lobbed movement

var debug_dict: Array[Vector2] # offset position used in TileMap cell detection
const DEBUG: bool = false

func _ready() -> void:
	# prevent posibly "circling" bullets (from the physics collision)
	lock_rotation=true
	# continuous forward movement until we hit something
	if lob_shot_process:
		%Collision.disabled = true
		bounce_bullet = false
		velocity = -transform.y * SPEED/2
	else:
		velocity = -transform.y * SPEED
	init_position = position
	target_position = init_position + (-transform.y * lob_distance)
	# smoke is slower than the explosion
	smoke.connect("finished", func():
		queue_free())
	# prevent self shoot bug (not really a true omegafix, but... T_T)
	add_collision_exception_with(origin_body)

func _physics_process(delta: float) -> void:
	if DEBUG:
		queue_redraw()
	
	if explosion.emitting:
		return
	
	# because the "move_and_collide" doesn't actually move the object,
	# we must handle travel positin before applying the screen warp
	travel_total += position_before.distance_to(position)
	position = Utils.apply_screen_wrap(position, screen_size)
	if KEEP_VELOCITY:
		# apply player momentum to the bullet
		translate(translate_direction * delta)
	
	# the movement is provided by linear_velocity (not "move_and_collide")
	var col_info: KinematicCollision2D = move_and_collide(Vector2.ZERO)
	if col_info:
		_on_body_entered(col_info.get_collider(), col_info.get_collider_rid())
		_apply_bounce(col_info.get_normal())
	else:
		remove_collision_exception_with(origin_body)
	_spawned = false # must be set ASAP after the first collision check
	
	# Must be set AFTER "move_and_collide" (otherwise, collisions will be borked)
	# Without this value, the velocity will not be transmitted correctly to
	# other bodies (like the Power Up)
	linear_velocity = velocity
	position_before = position
	
	if !lob_shot_process:
		return
	
	var progress: float = _get_progress(travel_total, init_position, target_position)
	if progress == 100:
		# disable "lob" logic for all remaining frames
		# (otherwise, we will trigger the "explosion" animation everytime)
		lob_shot_process = false
		var bodies:Array[Node2D] = %AreaLobbed.get_overlapping_bodies()
		if bodies.size() == 0:
			goodbye_little_one() # lob hit nothing
			return
		for b in bodies:
			_on_body_entered(b) # lob hit something
		return
	if progress < 50:
		%Sprite.texture = upward_txt
		%Sprite.scale += _lob_scale
		smoke.scale += _lob_scale
	else:
		%Sprite.texture = downward_txt
		%Sprite.scale -= _lob_scale
		smoke.scale -= _lob_scale

func _draw() -> void:
	# this function is always called when the node is created
	if !DEBUG:
		return
	# draw a circle in front of the bullet (on the nose)
	draw_circle(Vector2(0,-20), 5, Color.VIOLET)
	# bullet center position
	draw_circle(Vector2.ZERO, 5, Color.BLACK)
	for entry in debug_dict:
		draw_line(entry, \
			Vector2.ZERO, \
			Color.BLUE_VIOLET, 3)
		

func _get_progress(travel: float, start: Vector2, end: Vector2) -> float:
	var total_dist = start.distance_to(end)
	if total_dist == 0:
		return 100 if travel >= total_dist else 0
	else:
		var prog = (travel / total_dist) * 100
		# limit value if we overshoot
		return clamp(prog, 0, 100)

func _apply_bounce(normal: Vector2) -> void:
	if !bounce_bullet:
		return
	var v_before = velocity
	velocity = velocity.bounce(normal)
	translate_direction = translate_direction.bounce(normal)
	var ro = v_before.angle_to(velocity)
	rotate(ro)

func _on_body_entered(collided_body, rid: RID = RID()) -> void:
	if !GameState.in_game_scene:
		# doing nothing
		queue_free()
		return
	
	# kill infos
	var origin_name:String = origin_body.name \
		if origin_body != null \
		else StringName("UNKNOWN")
	print(origin_name, " hit ", collided_body.name)
	
	# check if a player is killed
	var p: Player = collided_body as Player
	if p and !p.is_killed:
		p.killed(origin_body.player_id)
	
	# bounce logic
	var w: WallTileMap = collided_body as WallTileMap
	var m: MovingWall = collided_body as MovingWall
	if (w or m) and bounce_bullet:
		# avoid infinite bounce inside a wall
		if _spawned: queue_free()
		# let's "_physics_process()" handle the bounce
		return
	
	# world destruction
	if w and w.is_destructible:
		destroy_tile(w, rid)
	
	# other bullet
	var b: Bullet = collided_body as Bullet
	if b:
		# TODO : change this because the sound is played 2 times
		%BulletHitBullet.play(1.1)
	
	goodbye_little_one()

func goodbye_little_one() -> void:
	# remove the bullet from the scene
	velocity = Vector2.ZERO
	linear_velocity = Vector2.ZERO # dont wait the _physics_proces loop
	%Collision.set_deferred("disabled", true)
	%Sprite.visible = false
	if DEBUG: return
	
	explosion.emitting = true
	smoke.emitting = false

func destroy_tile(tilemap: WallTileMap, rid: RID) -> void:
	var cell_coords: Vector2i
	if (rid.is_valid()):
		# only when : straight shot on a Collision Node (physic collision)
		cell_coords = tilemap.get_coords_for_body_rid(rid)
	else:
		# on a lob shot, we don't want to offset the bullet position
		var offset_front: Vector2 = Vector2.ZERO
		if !lob_shot:
			# DEPRECATED : with the RID, this part should not be called anymore !
			# with the classic shot, the bullet position is not in a wall cell
			# so, we push it into the wall to detect which cell we hit
			offset_front = -transform.y*30
		# debug mode need a rotation to be accurate
		debug_dict.push_back(offset_front.rotated(-rotation))
		# for the cell, we use a function that doesn't need the rotation
		cell_coords = tilemap.local_to_map(position + offset_front)
	
	# check if it is actually a part of tilemap
	var cell_source_id: int = tilemap.get_cell_source_id(cell_coords)
	if cell_source_id != -1:
		# set to -1, to delete tiled    
		tilemap.set_cell(cell_coords, -1)
		# spawn a damaged barrel on the position
		var parent: World = get_parent()
		if parent:
			var bp: RigidBody2D = barrel_part.instantiate()
			# random start value to simulate the explosion momentum
			var randx: int = randi_range(-500,500)
			var randy: int = randi_range(-500,500)
			bp.linear_velocity = Vector2(randx, randy)
			bp.angular_velocity = randi_range(-10, 10)
			# spawn position in the world
			var cell_center_pos = tilemap.map_to_local(cell_coords)
			bp.position = cell_center_pos
			# add it to the map (will be destroyed when lvl change)
			parent.get_node("%Map").add_child(bp)

func respawn_process() -> void:
	# dispawn when level is restarting
	queue_free()
