extends Control

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("p_start") or \
		Input.is_action_just_pressed("p1_shoot"):
		await Utils.scene_cu(self)
		get_tree().change_scene_to_file("res://scenes/menus/main.tscn")
