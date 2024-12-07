extends Control

@onready var screen_size: Vector2 = get_viewport().get_visible_rect().size
@onready var player: PackedScene = preload("res://scenes/player.tscn")

func _ready() -> void:
	GameState.in_game_scene = false
	var screen_center: Vector2 = Vector2 \
		(screen_size.x/2, screen_size.y/2)
	
	if GameState.player_number >= 1:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P1"
		p.player_id = 1
		p.tank_texture = PlayerState.p1_tank_texture
		p.barrel_texture = PlayerState.p1_barrel_texture
		p.position = screen_center + Vector2(-100, -100)
		p.parent_owner = self
		add_child(p)
	
	if GameState.player_number >= 2:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P2"
		p.player_id = 2
		p.tank_texture = PlayerState.p2_tank_texture
		p.barrel_texture = PlayerState.p2_barrel_texture
		p.position = screen_center + Vector2(100, -100)
		p.parent_owner = self
		add_child(p)
		
	if GameState.player_number >= 3:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P3"
		p.player_id = 3
		p.tank_texture = PlayerState.p3_tank_texture
		p.barrel_texture = PlayerState.p3_barrel_texture
		p.position = screen_center + Vector2(-100, 100)
		p.parent_owner = self
		add_child(p)
		
	if GameState.player_number >= 4:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P4"
		p.player_id = 4
		p.tank_texture = PlayerState.p4_tank_texture
		p.barrel_texture = PlayerState.p4_barrel_texture
		p.position = screen_center + Vector2(100, 100)
		p.parent_owner = self
		add_child(p)
	
	await Utils.scene_lc(self)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("p_start"):
		await Utils.scene_cl(self)
		get_tree().change_scene_to_file("res://scenes/menus/main.tscn")

func _exit_tree() -> void:
	# reset variable when leaving scene
	GameState.in_game_scene = true
