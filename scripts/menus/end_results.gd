extends Control

func _ready() -> void:
	# order scores by value
	var keys_order: Array[int] = []
	%BottomLabel.visible = false
	
	var max_val: int = 0
	for pi:PlayerInfo in GameState.p_infos.values():
		max_val = pi.score if pi.score > max_val else max_val
	
	for i in range(max_val, -1, -1):
		for k in GameState.p_infos.keys():
			var pi: PlayerInfo = GameState.p_infos[k]
			if pi.score == i: 
				keys_order.push_back(k)
				_add_score(pi)
				_add_stats(pi)

func _add_score(pi: PlayerInfo) -> void:
	var l = Label.new()
	l.text = pi.to_score_format()
	l.add_theme_color_override("font_color", pi.color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%ScoreBoard.add_child(l)

func _add_stats(pi: PlayerInfo) -> void:
	var l = Label.new()
	l.text = pi.to_stats_format()
	l.add_theme_color_override("font_color", pi.color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%GameStats.add_child(l)

func _process(_delta: float) -> void:
	# wait 2s before we resume to the main screen
	await get_tree().create_timer(2).timeout
	%BottomLabel.visible = true
	if Input.is_anything_pressed():
		get_tree().change_scene_to_file("res://scenes/menus/main.tscn")
