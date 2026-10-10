class_name WallTileMap extends TileMapLayer

@export var is_destructible: bool = false

var _shadow_layer: TileMapLayer

func _ready() -> void:
	z_index = 2
	_shadow_layer = TileMapLayer.new()
	_shadow_layer.name = "ShadowMask"
	_shadow_layer.tile_set = tile_set
	_shadow_layer.collision_enabled = false
	_shadow_layer.z_index = -1
	_shadow_layer.modulate = Color(0.07, 0.09, 0.13, 0.0)
	add_child(_shadow_layer)
	_sync_shadow_cells()

func _process(_delta: float) -> void:
	var world := get_node_or_null("/root/World") as World
	if world == null:
		return

	_shadow_layer.visible = world.shadows_enabled
	var tint: Color = world.shadow_color
	tint.a *= world.shadow_opacity
	_shadow_layer.modulate = tint
	_shadow_layer.position = to_local(
		global_position + _shadow_offset(world.shadow_direction, world.shadow_length)
	)
	_sync_shadow_cells()

func _shadow_offset(direction: Vector2, length: float) -> Vector2:
	return direction.normalized() * length

func _sync_shadow_cells() -> void:
	if _shadow_layer == null:
		return

	for cell: Vector2i in _shadow_layer.get_used_cells():
		if get_cell_source_id(cell) == -1:
			_shadow_layer.erase_cell(cell)

	for cell: Vector2i in get_used_cells():
		var source_id: int = get_cell_source_id(cell)
		var atlas_coords: Vector2i = get_cell_atlas_coords(cell)
		var alternative_tile: int = get_cell_alternative_tile(cell)
		if _shadow_layer.get_cell_source_id(cell) != source_id \
		or _shadow_layer.get_cell_atlas_coords(cell) != atlas_coords \
		or _shadow_layer.get_cell_alternative_tile(cell) != alternative_tile:
			_shadow_layer.set_cell(cell, source_id, atlas_coords, alternative_tile)
