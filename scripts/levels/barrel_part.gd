extends RigidBody2D

@onready var parent: World = get_node("/root/World")
var tilemap: TileMapLayer

func _ready() -> void:
	if parent:
		tilemap = parent.get_background_tilemap()

func _process(delta: float) -> void:
	if tilemap:
		# the Sprite is larger than the base cell size, so we scale up the position
		var cell_coords = tilemap.local_to_map(position * 2)
		if tilemap.get_cell_source_id(cell_coords) == -1:
			%Sprite.scale = clamp(%Sprite.scale - Vector2(delta, delta), 
				Vector2.ZERO, Vector2.INF)
