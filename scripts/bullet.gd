class_name Bullet extends RigidBody2D

@onready var screen_size = get_viewport_rect().size
@onready var time_before_active: Timer = %TimeBeforeActive
@onready var smoke: CPUParticles2D = %Smoke
@onready var explosion: CPUParticles2D = %Explosion
var origin_body: CharacterBody2D # use for a kill feed (or the end screen)
var bounce_bullet: float = false

const SPEED: float = 1000
const TIME_BEFORE_ACTIVE: float = 0.01 # time (sec) to avoid suicide when spawned
const KEEP_VELOCITY: bool = false

var translate_direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var _spawned: bool = true # prevent stuck bullet on first frame

func _ready() -> void:
	time_before_active.start(TIME_BEFORE_ACTIVE)
	# prevent posibly "circling" bullets (from the physics collision)
	lock_rotation=true
	# continuous forward movement until we hit something
	velocity = -transform.y * SPEED
	# smoke is slower than the explosion
	smoke.connect("finished", func():
		queue_free())
	# prevent self shoot bug
	add_collision_exception_with(origin_body)

func _physics_process(delta: float) -> void:
	if explosion.emitting:
		return
	
	position = Utils.apply_screen_wrap(position, screen_size)
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
	%Sprite.visible = false
	%Collision.set_deferred("disabled", true)
	explosion.emitting = true
	smoke.emitting = false

func respawn_process() -> void:
	# dispawn when level is restarting
	queue_free()
