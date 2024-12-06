extends Control

func _input(_event: InputEvent) -> void:
	if Input.is_anything_pressed():
		await Utils.scene_cu(self)
		get_tree().change_scene_to_file("res://scenes/menus/main.tscn")
