class_name Bullet extends Area2D

@onready var screen_size = get_viewport_rect().size
@onready var time_before_active: Timer = %TimeBeforeActive
@onready var smoke: CPUParticles2D = %Smoke
@onready var explosion: CPUParticles2D = %Explosion
var origin_body: CharacterBody2D # use for a kill feed (or the end screen)
var bounce_buller: float = false

const SPEED: float = 1000
const TIME_BEFORE_ACTIVE: float = 0.5 # time (sec) to avoid suicide when spawned
const KEEP_VELOCITY: bool = false

var translate_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	time_before_active.start(TIME_BEFORE_ACTIVE)
	connect("area_entered", _on_area_entered)
	connect("body_entered", _on_body_entered)
	# smoke is slower than the explosion
	smoke.connect("finished", func():
		queue_free())

func _physics_process(delta: float) -> void:
	if explosion.emitting:
		return
	# continuous forward movement until we hit something
	position += -transform.y * SPEED * delta
	position = Utils.apply_screen_wrap(position, screen_size)
	if KEEP_VELOCITY:
		# apply player momentum to the bullet
		translate(translate_direction * delta)

# handle collision for other Bullet (they are not RigidBody or stuff like that)
func _on_area_entered(area: Area2D) -> void:
	if area as Bullet:
		area.goodbye_little_one()

func _on_body_entered(collided_body: Node2D) -> void:
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
	
	# check if a player is killed
	var p: Player = collided_body as Player
	if p and !p.is_killed:
		p.killed(origin_body.player_id)
	
	if collided_body.name == "Walls":
		print(rad_to_deg(rotation))
		pass
	
	goodbye_little_one()

func goodbye_little_one() -> void:
	# remove the bullet from the scene
	%Sprite.visible = false
	%Collision.set_deferred("disabled", true)
	explosion.emitting = true
	smoke.emitting = false
