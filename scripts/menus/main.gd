extends Control

@onready var screen_size: Vector2 = get_viewport_rect().size
@onready var pvp_mode: Button = %PvpMode
@onready var soon_tm: Label = %SoonTm
@onready var control_btn: Button = %ControlBtn
@onready var settings_btn: Button = %SettingsBtn
@onready var exit_btn: Button = %ExitBtn
@onready var settings_ps: PackedScene = preload("res://scenes/menus/settings.tscn")

var clock_size: float = 0.002
var clock_sign: int = 1

func _ready() -> void:
	GameState.reset_state()
	# alternate sign on each clock cycle
	%Clock.connect("timeout", func():
		clock_sign *= -1)
	
	await Utils.scene_uc(self)
	
	pvp_mode.pressed.connect(on_vs_mode_pressed)
	pvp_mode.grab_focus()
	control_btn.pressed.connect(on_control_pressed)
	settings_btn.pressed.connect(on_settings_pressed)
	exit_btn.pressed.connect(on_exit_pressed)

func _input(_event: InputEvent) -> void:
	# trigger GamePad action on Button
	if Input.is_action_just_pressed("p_btn0"):
		var gui: Button = get_viewport().gui_get_focus_owner()
		if gui != null:
			gui.pressed.emit()

func _process(_delta: float) -> void:
	soon_tm.scale += clock_sign * Vector2(clock_size, clock_size)

func on_vs_mode_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/lvl_1.tscn")

func on_control_pressed():
	await Utils.scene_cr(self)
	get_tree().change_scene_to_file("res://scenes/levels/user_control.tscn")

func on_settings_pressed() -> void:
	# Kind of a hack. I cannot use the Godot designer, 
	# when the root node is a Popup :/
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
