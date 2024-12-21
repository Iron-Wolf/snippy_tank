extends Control

func _ready() -> void:
	%BackGround.play(7.08)
	%BottomLabel.visible = false
	for pi: PlayerInfo in GameState.get_players_by_score():
		_add_score(pi)
		_add_stats(pi)

func _add_score(pi: PlayerInfo) -> void:
	var l = Label.new()
	l.text = pi.to_score_format()
	l.add_theme_color_override("font_color", pi.color)
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%ScoreBoard.add_child(l)

func _add_stats(pi: PlayerInfo) -> void:
	var l = Label.new()
	l.text = pi.to_stats_format()
	l.add_theme_color_override("font_color", pi.color)
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%GameStats.add_child(l)

func _process(_delta: float) -> void:
	# wait 2s before we resume to the main screen
	await get_tree().create_timer(2).timeout
	%BottomLabel.visible = true
	if Input.is_anything_pressed():
		get_tree().change_scene_to_file("res://scenes/menus/main.tscn")
