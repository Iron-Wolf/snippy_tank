# https://www.youtube.com/watch?v=zHYkcJyE52g
extends Node

func _ready() -> void:
	get_node("%PlayBtn").pressed.connect(on_play_pressed)
	get_node("%ExitBtn").pressed.connect(on_exit_pressed)

func on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/world.tscn")

func on_exit_pressed():
	get_tree().quit()
