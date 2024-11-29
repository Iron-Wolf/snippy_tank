# https://www.youtube.com/watch?v=be-Xjg8oPbQ
extends Control

func _ready() -> void:
	get_node("%BackBtn").pressed.connect(on_back_pressed)

func on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main.tscn")
