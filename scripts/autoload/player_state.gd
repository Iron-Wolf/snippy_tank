extends Node

# movement
enum Scheme {SIMPLE, 
	ARCADE, 
	#EXPERT,
}
var control_scheme: Scheme = Scheme.SIMPLE

# aim
var last_aim_scheme: bool = false
var slingshot_scheme: bool = false
var shoot_timer: float = 3 # cooldown (sec) before each shoot

var p1_tank_texture: Texture2D = preload("res://assets/Tanks/tankRed.png")
var p1_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelRed_outline.png")
var p2_tank_texture: Texture2D = preload("res://assets/Tanks/tankBlue.png")
var p2_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelBlue_outline.png")
var p3_tank_texture: Texture2D = preload("res://assets/Tanks/tankBeige.png")
var p3_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelBeige_outline.png")
var p4_tank_texture: Texture2D = preload("res://assets/Tanks/tankGreen.png")
var p4_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelGreen_outline.png")
