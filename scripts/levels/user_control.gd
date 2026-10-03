extends Control

@onready var player: PackedScene = preload("res://scenes/player.tscn")

func _ready() -> void:
	if GameState.main_audio_playback != -1:
		%BackGroundAudio.play(GameState.main_audio_playback)
	GameState.in_game_scene = false
	var screen_center: Vector2 = get_viewport().get_visible_rect().size / 2
		
	for id in range(1, GameState.player_number + 1):
		var p: Player = player.instantiate()
		p.setup_for_player(id)
		# lazy way to spawn each player on an horizontal line
		p.init_position = screen_center
		p.init_position.x += (id-1) * 100
		p.parent_owner = self
		add_child(p)
	
	await Utils.scene_lc(self)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("p_start"):
		await Utils.scene_cl(self)
		GameState.main_audio_playback = %BackGroundAudio.get_playback_position()
		get_tree().change_scene_to_file("res://scenes/menus/main.tscn")

func _exit_tree() -> void:
	# reset variable when leaving scene
	GameState.in_game_scene = true
