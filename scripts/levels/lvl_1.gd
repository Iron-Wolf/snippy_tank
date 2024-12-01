extends Node

@onready var screen_size: Vector2 = get_viewport().get_visible_rect().size
@onready var player: PackedScene = preload("res://scenes/player.tscn")
@onready var p1_tank_texture: Texture2D = preload("res://assets/Tanks/tankRed.png")
@onready var p1_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelRed_outline.png")
@onready var p2_tank_texture: Texture2D = preload("res://assets/Tanks/tankBlue.png")
@onready var p2_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelBlue_outline.png")
@onready var p3_tank_texture: Texture2D = preload("res://assets/Tanks/tankBeige.png")
@onready var p3_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelBeige_outline.png")
@onready var p4_tank_texture: Texture2D = preload("res://assets/Tanks/tankGreen.png")
@onready var p4_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelGreen_outline.png")

var players: Array[CharacterBody2D] = []

func _ready() -> void:
	if GameState.player_number >= 1:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P1"
		p.player_id = 1
		p.tank_texture = p1_tank_texture
		p.barrel_texture = p1_barrel_texture
		p.position = Vector2(100, screen_size.y/2) # middle left
		_add_common_properties(p)
		add_child(p)
		players.push_back(p)
		get_node("%P1Score").visible = true
	
	if GameState.player_number >= 2:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P2"
		p.player_id = 2
		p.tank_texture = p2_tank_texture
		p.barrel_texture = p2_barrel_texture
		p.position = Vector2(screen_size.x - 100, screen_size.y/2) # middle right
		p.rotate(deg_to_rad(180))
		_add_common_properties(p)
		add_child(p)
		players.push_back(p)
		get_node("%P2Score").visible = true
		
	if GameState.player_number >= 3:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P3"
		p.player_id = 3
		p.tank_texture = p3_tank_texture
		p.barrel_texture = p3_barrel_texture
		p.position = Vector2(screen_size.x/2, 100) # middle up
		p.rotate(deg_to_rad(90))
		_add_common_properties(p)
		add_child(p)
		players.push_back(p)
		get_node("%P3Score").visible = true
		
	if GameState.player_number >= 4:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P4"
		p.player_id = 4
		p.tank_texture = p4_tank_texture
		p.barrel_texture = p4_barrel_texture
		p.position = Vector2(screen_size.x/2, screen_size.y-100) # middle down
		p.rotate(deg_to_rad(-90))
		_add_common_properties(p)
		add_child(p)
		players.push_back(p)
		get_node("%P4Score").visible = true

func _add_common_properties(p: CharacterBody2D) -> void:
	p.add_to_group("respawn")
	p.parent_owner = self
	p.connect("fight_started", $BackgroundAudio.on_fight_started)
	p.connect("fight_started", $Camera2D.on_fight_started)
	p.connect("player_killed", $Camera2D.on_player_killed)
	p.connect("player_killed", _on_player_killed)

func _on_player_killed() -> void:
	var dead_count:int = players.filter(func(body2d): return body2d.is_killed).size()
	if dead_count >= GameState.player_number - 1:
		# 1 or 0 player left
		_reload_level()

func _reload_level() -> void:
	# wait before reloading/changing the scene
	await get_tree().create_timer(1).timeout
	
	GameState.current_round += 1
	if GameState.scores.values().max() >= GameState.winning_score:
		get_tree().change_scene_to_file("res://scenes/menus/end_results.tscn")
		return
	
	elif GameState.current_round % GameState.max_round_by_level == 0:
		print("changing level... when there will be more...")
	get_tree().call_group("respawn", "respawn_process")# respawn ALL objetcs
	$BackgroundAudio.on_round_started()
