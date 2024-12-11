extends RigidBody2D

# reference to the player getting the power-up
var player: CharacterBody2D 
# used to replace the power-up in the original scene
var parent_owner: Node

@onready var screen_size: Vector2 = get_viewport_rect().size

var can_collide: bool = true
var start_animation: bool = false
var size_animation: float = 200

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

func _process(_delta: float) -> void:
	if start_animation:
		queue_redraw()
		return
	if !%Sprite.visible:
		_spawn_item()
	%Collision.disabled = !can_collide
	#_set_collision(can_collide)

func _draw() -> void:
	if start_animation and size_animation > 0:
		size_animation -= 0.5
		modulate.a = lerpf(modulate.a, 1, 0.05)
		draw_circle(position, size_animation, Color.WHITE, false, 4)
	else:
		start_animation = false

func _spawn_item() -> void:
	%Sprite.visible = true
	modulate.a = 1
	can_collide = true

func _set_collision(enabled: bool) -> void:
	#%Collision.disabled = !enabled
	can_collide = enabled
	process_mode = Node.PROCESS_MODE_INHERIT if enabled \
		else Node.PROCESS_MODE_DISABLED
	disconnect("body_entered", _on_body_entered)
	
	#if(!enabled):
	#	move_and_collide(Vector2.ZERO)
	#	disconnect("body_entered", _on_body_entered)
	
	get_tree().create_timer(10).connect("timeout", func():
		queue_free()
		return
		linear_velocity = Vector2.ZERO
		angular_velocity = 0
		can_collide = true
		process_mode = Node.PROCESS_MODE_INHERIT
		call_deferred("reparent", parent_owner)
		get_tree().create_timer(2).connect("timeout", func():
			connect("body_entered", _on_body_entered)))

func _on_body_entered(collided_body: Node) -> void:
	var p: Player = collided_body as Player
	if p:
		p.bounce_bullet = true
		call_deferred("reparent", collided_body.get_node("Tank"))
		call_deferred("_set_collision", false)
