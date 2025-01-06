class_name PowerUp extends RigidBody2D

# used to replace the power-up in the original scene
var parent_owner: Node
signal despawned
signal duplicated_player

@onready var screen_size: Vector2 = get_viewport_rect().size
@onready var player_ps: PackedScene = preload("res://scenes/player.tscn")
@onready var parent: World = get_node("/root/World")

var type: PlayerState.PowerUpType = randi_range(0, 5) as PlayerState.PowerUpType
const ANIM_SHAKE_SPEED: int = 15
var spawn_anim: bool = true
var spawn_anim_size: float = 200
var _snap_player: Player # reference to the player getting the power-up
var tilemap: TileMapLayer

var _reset_shoot_cooldown: float
var _reset_max_speed: float
var _reset_max_ammo: int

func _ready() -> void:
	if parent:
		tilemap = parent.get_background_tilemap()
	%Sprite.visible = false
	modulate.a = 0
	collision_layer = 0
	collision_mask = 1
	# wait the starting animation before colliding
	%Collision.disabled = true
	# setup mandatory properties to have collisions
	contact_monitor = true
	max_contacts_reported = 1
	connect("body_entered", _on_body_entered)
	# draw the circle
	queue_redraw()

func _physics_process(delta: float) -> void:
	if spawn_anim:
		queue_redraw()
		return
	if !%Sprite.visible:
		_spawn_item()
	
	if tilemap:
		# need "global_position" because we are a child of a Marker2D, so the
		# "position" will be relative to this Node, instead of the "World" scene
		var cell_coords = tilemap.local_to_map(global_position * 2)
		if tilemap.get_cell_source_id(cell_coords) == -1:
			print(position, " ", cell_coords)
			%Sprite.scale = clamp(%Sprite.scale - Vector2(delta, delta), 
				Vector2.ZERO, Vector2.INF)
			return
	
	var col_info = move_and_collide(Vector2.ZERO)
	if col_info:
		apply_central_impulse(-transform.y)
	
	var shake: float = 0.05 \
		if get_tree().get_frame() % ANIM_SHAKE_SPEED*2 > ANIM_SHAKE_SPEED \
		else -0.05
	$Sprite.scale.x = 1 + shake
	$Sprite.scale.y = 1 - shake

func _draw() -> void:
	if spawn_anim and spawn_anim_size > 0:
		spawn_anim_size -= 1
		modulate.a = lerpf(modulate.a, 1, 0.05)
		draw_circle(position, spawn_anim_size, Color.WHITE, false, 4)
	else:
		spawn_anim = false

func _spawn_item() -> void:
	%Sprite.visible = true
	modulate.a = 1
	%Collision.disabled = false

func _disable_collision() -> void:
	%Collision.disabled = true
	# snap object to the default position
	rotation = 0
	position = Vector2.ZERO
	$Sprite.scale = Vector2(1, 1)
	process_mode = Node.PROCESS_MODE_DISABLED
	disconnect("body_entered", _on_body_entered)
	
	get_tree().create_timer(10).connect("timeout", func():
		dispawn()
		return
		# some shitty code, to test some stuff...
		linear_velocity = Vector2.ZERO
		angular_velocity = 0
		%Collision.disabled = false
		process_mode = Node.PROCESS_MODE_INHERIT
		call_deferred("reparent", parent_owner)
		get_tree().create_timer(2).connect("timeout", func():
			connect("body_entered", _on_body_entered)))

func _on_body_entered(collided_body: Node) -> void:
	_snap_player = collided_body as Player
	if _snap_player == null:
		return
	
	_reset_shoot_cooldown = _snap_player.shoot_cooldown
	_reset_max_speed = _snap_player.MAX_SPEED
	_reset_max_ammo = _snap_player.MAX_AMMO
	match type:
		PlayerState.PowerUpType.BOUNCE_BULLET:
			call_deferred("_bounce_bullet")
		PlayerState.PowerUpType.DUPLICATE_PLAYER:
			call_deferred("_duplicate_player")
		PlayerState.PowerUpType.INFINITE_AMMO:
			call_deferred("_infinite_ammo")
		PlayerState.PowerUpType.MOVE_SPEED:
			call_deferred("_move_speed")
		PlayerState.PowerUpType.INVERSE_CONTROL:
			call_deferred("_inverse_control")
		PlayerState.PowerUpType.TRIPLE_SHOT:
			call_deferred("_triple_shot")

func _bounce_bullet() -> void:
	_snap_player.bounce_bullet = true
	# reparent to leave transform logic to the player's body
	reparent(_snap_player.get_node("%PowerUpSnap"))
	_disable_collision()

func _duplicate_player() -> void:
	%Sprite.visible = false
	disconnect("body_entered", _on_body_entered)
	process_mode = Node.PROCESS_MODE_DISABLED
	duplicated_player.emit(_snap_player)
	get_tree().create_timer(10).connect("timeout", func():
		print("end 'duplicate' power up")
		dispawn())

func _infinite_ammo() -> void:
	_snap_player.shoot_cooldown = 0.1
	# trigger an infinite reload animation
	# (during the "ShootTimer" timeout function of the player)
	_snap_player.MAX_AMMO = -1
	_snap_player.ammo_left = 99
	_snap_player.sprite_modulate(Color.WHITE)
	reparent(_snap_player.get_node("%PowerUpSnap"))
	_disable_collision()

func _move_speed() -> void:
	_snap_player.MAX_SPEED *= 2
	_snap_player.ANIM_SHAKE_SPEED /= 2
	reparent(_snap_player.get_node("%PowerUpSnap"))
	_disable_collision()

func _inverse_control() -> void:
	_snap_player.inverse_control = true
	_snap_player.inverse_color(true)
	reparent(_snap_player.get_node("%PowerUpSnap"))
	_disable_collision()

func _triple_shot() -> void:
	_snap_player.bullet_fired = 3
	reparent(_snap_player.get_node("%PowerUpSnap"))
	_disable_collision()

# also call by the WORLD scene, to reset vars on each round
func dispawn() -> void:
	if _snap_player:
		_snap_player.bounce_bullet = false
		_snap_player.bullet_fired = 1
		_snap_player.shoot_cooldown = _reset_shoot_cooldown
		_snap_player.MAX_SPEED = _reset_max_speed
		_snap_player.MAX_AMMO = _reset_max_ammo
		_snap_player.ammo_left = _reset_max_ammo
		_snap_player.ANIM_SHAKE_SPEED *= 2
		_snap_player.inverse_control = false
		_snap_player.inverse_color(false)
		
	# notify the level that we can spawn a new power up
	despawned.emit()
	queue_free()
