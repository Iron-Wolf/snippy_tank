class_name CameraWorld extends Camera2D

## How quickly the shaking stops [0, 1]
@export var decay: float = 0.8
## Maximum hor/ver shake in pixels
@export var max_offset: Vector2 = Vector2(100, 75)
## Maximum rotation in radians (use sparingly)
@export var max_roll: float = 0.1  

var trauma: float = 0  # Current shake strength.
var trauma_power: int = 2  # Trauma exponent. Use [2, 3].
var _player_to_follow: Player

func _process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()
	if _player_to_follow:
		print(zoom)
		position = _player_to_follow.position
		zoom = lerp(zoom, Vector2(1.5, 1.5), delta)

func shake():
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	offset.x = max_offset.x * amount * randf_range(-1, 1)
	offset.y = max_offset.y * amount * randf_range(-1, 1)

func on_fight_started() -> void:
	trauma = 0.3

func on_player_killed(_killer_id: int, _killed_id: int) -> void:
	trauma = 0.8
	for p: PlayerInfo in GameState.p_infos.values():
		Input.start_joy_vibration(p.player_id-1, 0, 1, 0.5) # strong vibration

func follow_player(players: Array[Player]) -> void:
	var winner_id: int = GameState.get_players_by_score()[0].player_id
	var winner_players: Array[Player] = players.filter(func(p:Player): 
		if p.player_id == winner_id: 
			return p)
	# follow only the first on for now
	_player_to_follow = winner_players[0]
	anchor_mode = AnchorMode.ANCHOR_MODE_DRAG_CENTER

func unfollow_player() -> void:
	_player_to_follow = null
	zoom = Vector2(1, 1)
	position = Vector2.ZERO
	anchor_mode = AnchorMode.ANCHOR_MODE_FIXED_TOP_LEFT
