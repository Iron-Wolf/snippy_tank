class_name MovingWall extends RigidBody2D

@onready var screen_size:Vector2 = get_viewport_rect().size
enum Direction {
	LEFT, 
	RIGHT, 
	UP,
	DOWN
}

@export var move_direction: Direction
@export_range(0, 100) var move_speed: int = 0
@export_range(-1, 1) var rotate_direction: int = 0
@export_range(0, 180) var rotate_deg: int = 0
## number of wall elements
@export var wall_size: int = 0
## time to wait before moving the Node
@export_range(0, 100) var wait_start: int = 0
## time to wait when stoping the Node
@export_range(0, 100) var wait_stop: int = 0
var stop_moving: bool = false

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	contact_monitor = true
	max_contacts_reported = 1
	
	if wait_stop != 0:
		get_tree().create_timer(wait_stop).connect("timeout", func():
			stop_moving = true
		)
	
	if wall_size == 0:
		return
	
	for idx in range(1, wall_size):
		_duplicate_sprite(1, idx)
		_duplicate_sprite(-1, idx)

func _duplicate_sprite(dir: int, index: int) -> void:
	var c: CollisionShape2D = %Collision.duplicate()
	c.position.y = dir * c.shape.get_rect().size.y * index
	add_child(c)
	move_child(c, 0)
	var s:Sprite2D = %Sprite2D.duplicate()
	s.position.y = dir * s.texture.get_size().y * index
	add_child(s)
	move_child(s, 0)

func _physics_process(delta: float) -> void:
	if stop_moving:
		return
	await get_tree().create_timer(wait_start).timeout
	position = Utils.apply_screen_wrap(position, screen_size	)
	
	rotate(deg_to_rad(rotate_deg * rotate_direction * delta))
	
	var velocity:Vector2
	match move_direction:
		Direction.LEFT:
			velocity = Vector2(-move_speed, 0)
		Direction.RIGHT:
			velocity = Vector2(move_speed, 0)
		Direction.UP:
			velocity = Vector2(0, -move_speed)
		Direction.DOWN:
			velocity = Vector2(0, move_speed)
	
	var col_info = move_and_collide(velocity * delta)
	var bodies = get_colliding_bodies()
	# NOTE : colliding with a moving wall will "snap" the player to it
	# we must apply a knockback to fix this
	for body in bodies:
		var n: Node2D = body as Node2D
		if n:
			n.translate(velocity * (delta+0.005))
