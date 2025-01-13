extends Control

const powerbox_ps: PackedScene = preload("res://scenes/levels/power_up.tscn")

func _ready() -> void:
	for i in range(0, 100):
		var pu: PowerUp = powerbox_ps.instantiate()
		pu.spawn_anim = false
		pu.active_power_up = false
		# reduce dispertion
		pu.linear_damp = 1
		%Box.add_child(pu)
