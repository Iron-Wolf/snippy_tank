# https://www.youtube.com/watch?v=zHYkcJyE52g
extends Control

@onready var pvp_mode: Button = get_node("%PvpMode")
@onready var soon_tm_label: Label = get_node("%SoonTm")
@onready var settings_btn: Button = get_node("%SettingsBtn")
@onready var exit_btn: Button = get_node("%ExitBtn")
@onready var settings_ps: PackedScene = preload("res://scenes/menus/settings.tscn")

var scale_sign: int = 1
var scale_switch: float = 0.5
var scale_speed: float = 0.01
var scale_size: float = 0.002

func _ready() -> void:
	# reset global variables
	GameState.current_round = 0
	for k in GameState.scores.keys():
		GameState.scores[k] = 0
	pvp_mode.pressed.connect(on_vs_mode_pressed)
	settings_btn.pressed.connect(on_settings_pressed)
	exit_btn.pressed.connect(on_exit_pressed)

func _process(_delta: float) -> void:
	soon_tm_label.scale += scale_sign * Vector2(scale_size,scale_size)
	scale_switch -= scale_speed
	if scale_switch < 0:
		scale_sign *= -1
		scale_switch = 0.5

func on_vs_mode_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/user_control.tscn")

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
	s.connect("hidden", func():
		# kill popup containing the scene, when she is exited
		p.queue_free())
	p.add_child(s)

func on_exit_pressed():
	get_tree().quit()
