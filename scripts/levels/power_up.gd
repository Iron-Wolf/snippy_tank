class_name PowerUp extends RigidBody2D

# reference to the player getting the power-up
var player: CharacterBody2D 
# used to replace the power-up in the original scene
var parent_owner: Node
signal powerup_despawned

@onready var screen_size: Vector2 = get_viewport_rect().size

const ANIM_SHAKE_SPEED: int = 15
var start_animation: bool = true
var size_animation: float = 200
var _snap_player: Player

func _ready() -> void:
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

func _physics_process(_delta: float) -> void:
	if start_animation:
		queue_redraw()
		return
	if !%Sprite.visible:
		_spawn_item()
	
	var col_info = move_and_collide(Vector2.ZERO)
	if col_info:
		apply_central_impulse(-transform.y)
	
	var shake: float = 0.05 \
		if get_tree().get_frame() % ANIM_SHAKE_SPEED*2 > ANIM_SHAKE_SPEED \
		else -0.05
	$Sprite.scale.x = 1 + shake
	$Sprite.scale.y = 1 - shake

func _draw() -> void:
	if start_animation and size_animation > 0:
		size_animation -= 1
		modulate.a = lerpf(modulate.a, 1, 0.05)
		draw_circle(position, size_animation, Color.WHITE, false, 4)
	else:
		start_animation = false

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
		
		linear_velocity = Vector2.ZERO
		angular_velocity = 0
		%Collision.disabled = false
		process_mode = Node.PROCESS_MODE_INHERIT
		call_deferred("reparent", parent_owner)
		get_tree().create_timer(2).connect("timeout", func():
			connect("body_entered", _on_body_entered)))

func _on_body_entered(collided_body: Node) -> void:
	_snap_player = collided_body as Player
	if _snap_player:
		_snap_player.bounce_bullet = true
		# reparent to leave transform logic to the player's body
		call_deferred("reparent", collided_body.get_node("%PowerUpSnap"))
		call_deferred("_disable_collision")

func dispawn() -> void:
	if _snap_player:
		_snap_player.bounce_bullet = false
	powerup_despawned.emit()
	queue_free()
