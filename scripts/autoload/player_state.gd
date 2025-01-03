extends Node

# === EXPOSED VARIABLES ===
var control_scheme: Scheme = Scheme.SIMPLE
 # cooldown (sec) before each shoot
var shoot_timer: float = 3

# === INTERNAL VARIABLES ===
# movement
enum Scheme {
	SIMPLE, 
	ARCADE, 
	EXPERT,
}
# keep the aim at the last known position
var last_aim_scheme: bool = false
# shot when the aim is released (need adjustment ?)
var slingshot_scheme: bool = false

enum PowerUpType {
	BOUNCE_BULLET, # 0
	DUPLICATE_PLAYER, # 1
	INFINITE_AMMO, # 2
	MOVE_SPEED, # 3
	INVERSE_CONTROL, # 4
	TRIPLE_SHOT, # 5
}

# === OTHER ===
var p1_tank_texture: Texture2D = preload("res://assets/Tanks/tankRed.png")
var p1_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelRed_outline.png")
var p2_tank_texture: Texture2D = preload("res://assets/Tanks/tankBlue.png")
var p2_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelBlue_outline.png")
var p3_tank_texture: Texture2D = preload("res://assets/Tanks/tankBeige.png")
var p3_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelBeige_outline.png")
var p4_tank_texture: Texture2D = preload("res://assets/Tanks/tankGreen.png")
var p4_barrel_texture: Texture2D = preload("res://assets/Tanks/barrelGreen_outline.png")
