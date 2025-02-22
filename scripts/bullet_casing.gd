extends Sprite2D

@onready var parent: World = get_node("/root/World")

var rand_speed: float = randf_range(10,15)
var rand_rotation: float = randf_range(-3,3)
var tilemap: TileMapLayer

func _ready() -> void:
	if parent:
		tilemap = parent.get_background_tilemap()

func _process(delta: float) -> void:
	if tilemap:
		# the Sprite is larger than the base cell size, so we scale up the position
		var cell_coords = tilemap.local_to_map(position * 2)
		if tilemap.get_cell_source_id(cell_coords) == -1:
			scale = clamp(scale - Vector2(delta, delta), Vector2.ZERO, Vector2.INF)
	
	if rand_speed < 0:
		return
	
	position += transform.y * rand_speed
	rotation += deg_to_rad(rand_rotation)
	rand_speed = lerpf(rand_speed, -0.1, 0.1)
