# https://www.youtube.com/watch?v=be-Xjg8oPbQ
extends Control

@onready var back_btn:Button = get_node("%BackBtn")
@onready var control:OptionButton = get_node("%Control")

func _ready() -> void:
	back_btn.pressed.connect(on_back_pressed)
	
	control.item_selected.connect(on_control_selected)
	for ctrl_scheme in PlayerState.Scheme:
		control.add_item(ctrl_scheme)
	control.select(PlayerState.control_scheme)

func on_control_selected(index: int) -> void:
	PlayerState.control_scheme = index as PlayerState.Scheme

func on_back_pressed() -> void:
	queue_free()
