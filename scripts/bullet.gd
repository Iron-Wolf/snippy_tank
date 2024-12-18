class_name Bullet extends RigidBody2D

@onready var screen_size = get_viewport_rect().size
@onready var smoke: CPUParticles2D = %Smoke
@onready var explosion: CPUParticles2D = %Explosion
var origin_body: CharacterBody2D # use for a kill feed (or the end screen)
var bounce_bullet: float = false
var lob_shot: float = false
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

func _ready() -> void:
	# prevent posibly "circling" bullets (from the physics collision)
	lock_rotation=true
	# continuous forward movement until we hit something
	if lob_shot:
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
	if explosion.emitting:
		return
	
	position = Utils.apply_screen_wrap(position, screen_size)
	var position_before = position # call this AFTER screen warping
	if KEEP_VELOCITY:
		# apply player momentum to the bullet
		translate(translate_direction * delta)
	
	var col_info = move_and_collide(velocity * delta)
	if col_info:
		_on_body_entered(col_info.get_collider())
		_apply_bounce(col_info.get_normal())
	else:
		remove_collision_exception_with(origin_body)
	_spawned = false
	
	if !lob_shot:
		return
	
	travel_total += position_before.distance_to(position)
	var progress: float = _get_progress(travel_total, init_position, target_position)
	if progress == 100:
		# disable "lob" logic for all remaining frames
		# (otherwise, we will trigger the "explosion" animation everytime)
		lob_shot = false
		var bodies:Array[Node2D] = %AreaLobbed.get_overlapping_bodies()
		if bodies.size() == 0:
			goodbye_little_one()
			return
		for b in bodies:
			_on_body_entered(b)
		return
	if progress < 50:
		%Sprite.scale += _lob_scale
		smoke.scale += _lob_scale
	else :
		%Sprite.scale -= _lob_scale
		smoke.scale -= _lob_scale

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

func _on_body_entered(collided_body) -> void:
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
	
	if collided_body.name == "Walls" and bounce_bullet:
		# avoid infinite bounce inside a wall
		if _spawned: queue_free()
		# let's "_physics_process()" handle the bounce
		return
	
	goodbye_little_one()

func goodbye_little_one() -> void:
	# remove the bullet from the scene
	velocity = Vector2.ZERO
	%Sprite.visible = false
	%Collision.set_deferred("disabled", true)
	explosion.emitting = true
	smoke.emitting = false

func respawn_process() -> void:
	# dispawn when level is restarting
	queue_free()
