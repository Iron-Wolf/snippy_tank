extends Control

@onready var winning_score:SpinBox = get_node("%WinningScore")
@onready var player_count:OptionButton = get_node("%PlayerCount")
@onready var control:OptionButton = get_node("%Control")
@onready var shot_cooldown:SpinBox = get_node("%ShotCooldown")
@onready var back_btn:Button = get_node("%BackBtn")

func _ready() -> void:
	back_btn.grab_focus()
	
	#region GENERAL
	winning_score.value = GameState.winning_score
	winning_score.value_changed.connect(func(value: int):
		GameState.winning_score = value)
	
	for i in range(1, GameState.MAX_PLAYER+1):
		player_count.add_item(str(i))
	player_count.select(GameState.player_number-1)
	player_count.item_selected.connect(func(index: int):
		GameState.player_number = index+1)
	#endregion
	
	#region GAMEPLAY
	for ctrl_scheme in PlayerState.Scheme:
		control.add_item(ctrl_scheme)
	control.select(PlayerState.control_scheme)
	control.item_selected.connect(func(index: int):
		PlayerState.control_scheme = index as PlayerState.Scheme)
	
	shot_cooldown.value = PlayerState.shoot_timer
	shot_cooldown.value_changed.connect(func(value: int):
		PlayerState.shoot_timer = float(value) if value != 0 else 0.01)
	#endregion
	
	#region AUDIO
	
	#endregion
	
	back_btn.pressed.connect(func():
		GameState.reset_state()
		hide())

# TODO : does not resolve all controls on gamepad (keyboard is fine by default)
func _input(_event: InputEvent) -> void:
	# trigger GamePad action on Button
	if Input.is_action_just_pressed("p_btn0"):
		var gui = get_viewport().gui_get_focus_owner()
		if gui != null and gui is Button:
			gui.pressed.emit()
