# https://www.youtube.com/watch?v=zHYkcJyE52g
extends Control

@onready var screen_size: Vector2 = get_viewport_rect().size
@onready var pvp_mode: Button = %PvpMode
@onready var soon_tm: Label = %SoonTm
@onready var settings_btn: Button = %SettingsBtn
@onready var exit_btn: Button = %ExitBtn
@onready var settings_ps: PackedScene = preload("res://scenes/menus/settings.tscn")

var clock_size: float = 0.002
var clock_sign: int = 1

func _ready() -> void:
	# reset global variables
	GameState.current_round = 0
	for k in GameState.scores.keys():
		GameState.scores[k] = 0
	pvp_mode.pressed.connect(on_vs_mode_pressed)
	settings_btn.pressed.connect(on_settings_pressed)
	exit_btn.pressed.connect(on_exit_pressed)
	# alternate sign on each clock cycle
	%Clock.connect("timeout", func():
		clock_sign *= -1)

func _process(_delta: float) -> void:
	soon_tm.scale += clock_sign * Vector2(clock_size, clock_size)

func on_vs_mode_pressed() -> void:
	await Utils.ease_in(self, -screen_size.x)
	get_tree().change_scene_to_file("res://scenes/levels/user_control.tscn")

func on_settings_pressed() -> void:
	# Kind of a hack just because I can't design the settings
	# in Godot, when the root node is a Popup :/
	# So, I create a Popup here add put the scene inside.
	var s = settings_ps.instantiate()
	var p = Popup.new()
	p.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	p.size = Vector2i(s.size.x, s.size.y)
	p.transparent = true
	p.visible = true
	s.connect("hidden", func():
		# kill popup containing the scene, when she is exited
		p.queue_free())
	p.add_child(s)
	add_child(p)

func on_exit_pressed():
	get_tree().quit()
