extends Node

@onready var time_before_active = get_tree().create_timer(1)

func _input(_event: InputEvent) -> void:
	if time_before_active.time_left > 0:
		return
	get_tree().change_scene_to_file("res://scenes/menus/main.tscn")
