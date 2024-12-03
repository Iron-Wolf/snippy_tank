extends Node

@onready var screen_size: Vector2 = get_viewport().get_visible_rect().size
@onready var player: PackedScene = preload("res://scenes/player.tscn")

const WIN_BANNER_SPEED: float = 0.05
const TIMER_SHOW_WIN_BANNER: int = 2

var players: Array[CharacterBody2D] = []
var show_win_banner:bool = true

func _ready() -> void:
	%TimerShowBanner.wait_time = TIMER_SHOW_WIN_BANNER
	%TimerShowBanner.start()
	
	if GameState.player_number >= 1:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P1"
		p.player_id = 1
		p.tank_texture = PlayerState.p1_tank_texture
		p.barrel_texture = PlayerState.p1_barrel_texture
		p.position = Vector2(100, screen_size.y/2) # middle left
		_add_common_properties(p)
		add_child(p)
		players.push_back(p)
		%P1Score.visible = true
	
	if GameState.player_number >= 2:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P2"
		p.player_id = 2
		p.tank_texture = PlayerState.p2_tank_texture
		p.barrel_texture = PlayerState.p2_barrel_texture
		p.position = Vector2(screen_size.x - 100, screen_size.y/2) # middle right
		p.rotate(deg_to_rad(180))
		_add_common_properties(p)
		add_child(p)
		players.push_back(p)
		%P2Score.visible = true
		
	if GameState.player_number >= 3:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P3"
		p.player_id = 3
		p.tank_texture = PlayerState.p3_tank_texture
		p.barrel_texture = PlayerState.p3_barrel_texture
		p.position = Vector2(screen_size.x/2, 100) # middle up
		p.rotate(deg_to_rad(90))
		_add_common_properties(p)
		add_child(p)
		players.push_back(p)
		%P3Score.visible = true
		
	if GameState.player_number >= 4:
		var p:CharacterBody2D = player.instantiate()
		p.name = "P4"
		p.player_id = 4
		p.tank_texture = PlayerState.p4_tank_texture
		p.barrel_texture = PlayerState.p4_barrel_texture
		p.position = Vector2(screen_size.x/2, screen_size.y-100) # middle down
		p.rotate(deg_to_rad(-90))
		_add_common_properties(p)
		add_child(p)
		players.push_back(p)
		%P4Score.visible = true

func _process(_delta: float) -> void:
	if %TimerShowBanner.time_left > 0 :
		%WinnerBack.position.x = lerpf(%WinnerBack.position.x, 0, WIN_BANNER_SPEED)
		%RoundLabel.position.x = lerpf(%RoundLabel.position.x, screen_size.x/2, WIN_BANNER_SPEED/4)
		%PlayerLabel.position.x = lerpf(%PlayerLabel.position.x, screen_size.x/2, WIN_BANNER_SPEED/4)
	else:
		%WinnerBack.position.x = lerpf(%WinnerBack.position.x, screen_size.x+50, WIN_BANNER_SPEED)
		%RoundLabel.position.x = lerpf(%RoundLabel.position.x, 0 - %RoundLabel.size.x-50, WIN_BANNER_SPEED)
		%PlayerLabel.position.x = lerpf(%PlayerLabel.position.x, screen_size.x+50, WIN_BANNER_SPEED)

func _add_common_properties(p: CharacterBody2D) -> void:
	p.add_to_group("respawn")
	p.parent_owner = self
	p.connect("fight_started", $BackgroundAudio.on_fight_started)
	p.connect("fight_started", $Camera2D.on_fight_started)
	p.connect("player_killed", $Camera2D.on_player_killed)
	p.connect("player_killed", _on_player_killed)

func _on_player_killed() -> void:
	var dead_count:int = players.filter(func(body2d): 
		return body2d.is_killed).size()
	if dead_count >= GameState.player_number - 1:
		# 1 or 0 player left
		_reload_level()

func _reload_level() -> void:
	# wait before reloading/changing the scene
	await get_tree().create_timer(1).timeout
	
	GameState.current_round += 1
	%RoundLabel.text = "Round %s" % (GameState.current_round + 1)
	%TimerShowBanner.start()
	
	if GameState.scores.values().max() >= GameState.winning_score:
		get_tree().change_scene_to_file("res://scenes/menus/end_results.tscn")
		return
	
	elif GameState.current_round % GameState.max_round_by_level == 0:
		print("changing level... when there will be more...")
	get_tree().call_group("respawn", "respawn_process")# respawn ALL objetcs
	$BackgroundAudio.on_round_started()
