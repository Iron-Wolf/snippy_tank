class_name SpriteShadow extends Sprite2D

var source_sprite: Sprite2D
var world: World

func configure(source: Sprite2D, shadow_world: World) -> void:
	source_sprite = source
	world = shadow_world
	z_as_relative = source.z_as_relative
	z_index = source.z_index - 1
	texture_filter = source.texture_filter
	var shadow_material := ShaderMaterial.new()
	shadow_material.shader = preload("res://shader/sprite_shadow.gdshader")
	material = shadow_material
	_sync_source()

func _process(_delta: float) -> void:
	if not is_instance_valid(source_sprite) or not source_sprite.is_inside_tree():
		queue_free()
		return
	_sync_source()

func _sync_source() -> void:
	texture = source_sprite.texture
	centered = source_sprite.centered
	offset = source_sprite.offset
	flip_h = source_sprite.flip_h
	flip_v = source_sprite.flip_v
	hframes = source_sprite.hframes
	vframes = source_sprite.vframes
	frame = source_sprite.frame
	region_enabled = source_sprite.region_enabled
	region_rect = source_sprite.region_rect
	visible = world.shadows_enabled and source_sprite.visible
	z_as_relative = source_sprite.z_as_relative
	z_index = source_sprite.z_index - 1
	self_modulate = Color(1.0, 1.0, 1.0, source_sprite.self_modulate.a)

	var shadow_material := material as ShaderMaterial
	shadow_material.set_shader_parameter("shadow_color", world.shadow_color)
	shadow_material.set_shader_parameter("shadow_opacity", world.shadow_opacity)
	shadow_material.set_shader_parameter("softness_pixels", world.shadow_softness)

	var direction: Vector2 = world.shadow_direction.normalized()
	global_position = source_sprite.global_position + direction * world.shadow_length
	global_rotation = source_sprite.global_rotation
	global_scale = source_sprite.global_scale
