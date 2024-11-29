# https://www.youtube.com/watch?v=zHYkcJyE52g
extends Node

func _ready() -> void:
	get_node("%VsMode").pressed.connect(on_vs_mode_pressed)
	get_node("%SettingsBtn").pressed.connect(on_settings_pressed)
	get_node("%ExitBtn").pressed.connect(on_exit_pressed)

func on_vs_mode_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/world.tscn")

func on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/settings.tscn")

func on_exit_pressed():
	get_tree().quit()
