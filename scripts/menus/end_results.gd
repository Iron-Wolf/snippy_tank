extends Control

var COLOR_1: Color = Color.from_string("#bf4100", Color.RED)
var COLOR_2: Color = Color.from_string("#2f6aff", Color.BLUE)
var COLOR_3: Color = Color.from_string("#978961", Color.BEIGE)
var COLOR_4: Color = Color.from_string("#00892b", Color.FOREST_GREEN)

func _ready() -> void:
	# order scores by value
	var keys_order: Array[int] = []
	%BottomLabel.visible = false
	
	var max_val: int = 0
	for k in GameState.p_infos.keys():
		var pi: GameState.PlayerInfo = GameState.p_infos[k]
		max_val = pi.score if pi.score > max_val else max_val
	
	for i in range(max_val, -1, -1):
		for k in GameState.p_infos.keys():
			var pi: GameState.PlayerInfo = GameState.p_infos[k]
			if pi.score == i: 
				keys_order.push_back(k)
				if GameState.player_number >= 1 and k == 1:
					_add_score("RED: "+str(i), COLOR_1)
					_add_stats(str(roundi(pi.travel_total)), COLOR_1)
				elif GameState.player_number >= 2 and k == 2:
					_add_score("BLUE: "+str(i), COLOR_2)
					_add_stats(str(roundi(pi.travel_total)), COLOR_2)
				elif GameState.player_number >= 3 and k == 3:
					_add_score("WHITE: "+str(i), COLOR_3)
					_add_stats(str(roundi(pi.travel_total)), COLOR_3)
				elif GameState.player_number >= 4 and k == 4:
					_add_score("GREEN: "+str(i), COLOR_4)
					_add_stats(str(roundi(pi.travel_total)), COLOR_4)

func _add_score(txt: String, color: Color) -> void:
	var l = Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	get_node("%ScoreBoard").add_child(l)

func _add_stats(txt: String, color: Color) -> void:
	var l = Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	get_node("%GameStats").add_child(l)

func _process(_delta: float) -> void:
	# wait 2s before we resume to the main screen
	await get_tree().create_timer(2).timeout
	%BottomLabel.visible = true
	if Input.is_anything_pressed():
		get_tree().change_scene_to_file("res://scenes/menus/main.tscn")
