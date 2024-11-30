# https://www.youtube.com/watch?v=zHYkcJyE52g
extends Node

@onready var pvp_mode: Button = get_node("%PvpMode")
@onready var settings_btn: Button = get_node("%SettingsBtn")
@onready var exit_btn: Button = get_node("%ExitBtn")
@onready var settings_ps: PackedScene = preload("res://scenes/menus/settings.tscn")

func _ready() -> void:
	pvp_mode.pressed.connect(on_vs_mode_pressed)
	settings_btn.pressed.connect(on_settings_pressed)
	exit_btn.pressed.connect(on_exit_pressed)

func on_vs_mode_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/world.tscn")

func on_settings_pressed() -> void:
	# Kind of a hack just because I can't design the settings
	# in Godot, when the root node is a Popup :/
	# So, I create a Popup here add put the scene inside.
	var p = Popup.new()
	p.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	p.size = Vector2i(1480, 830)
	p.transparent = true
	p.visible = true
	add_child(p)
	var s = settings_ps.instantiate()
	s.connect("tree_exited", func():
		# kill object containing the scene, when she is exited
		p.queue_free())
	p.add_child(s)

func on_exit_pressed():
	get_tree().quit()
