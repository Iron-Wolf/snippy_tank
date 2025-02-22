class_name World extends Control

@onready var screen_size: Vector2 = get_viewport_rect().size
# NOTICE: use "load" here, because I have a "bug" with "preload" ("instantiate" not working)
# if we go to the "user_control" scene before this one
@onready var player: PackedScene = load("res://scenes/player.tscn")
@onready var power_up: PackedScene = preload("res://scenes/levels/power_up.tscn")
@onready var t_show_banner: Timer = %ShowBannerTimer
@onready var t_hide_banner: Timer = %HideBannerTimer
@onready var t_spw_item: Timer = %SpawnItemTimer
@onready var t_lightning: Timer = %LightningTimer
@onready var camera: CameraWorld = $Camera2D
var spw_power_up_1:Marker2D # node name : SpawnPowerUp1
var spw_power_up_2:Marker2D # node name : SpawnPowerUp2
var spw_tracks:Marker2D # node name : SpawnTracks

const WIN_BANNER_SPEED: float = 0.05
const TIMER_WIN_BANNER: float = 1.5
const LIGHT_FLASH_ON: Color = Color.WHITE
const LIGHT_FLASH_OFF: Color = Color("#0a0c15")

var _win_banner_base_speed: float = 1
var _players: Array[Player] = []
var _players_dup: Array[Player] = []
var _power_up: PowerUp
var _is_lightning_active: bool = false
var _is_cloud_active: bool = false

func get_background_tilemap() -> TileMapLayer:
	# TODO: I know it's omega dirty, but it will do the work (for now)
	return get_node("%Map").get_child(0).get_child(0).get_child(0)

func _ready() -> void:
	# z_index
	$UI.z_index = 10
	%WinBanner.z_index = 10
	%CloudParticle.z_index = 20
	
	if (GameState.p_infos.is_empty()): 
		GameState.reset_state()
	
	t_hide_banner.wait_time = TIMER_WIN_BANNER
	t_show_banner.wait_time = TIMER_WIN_BANNER
	t_show_banner.start()
	t_show_banner.connect("timeout", func():
		t_hide_banner.start())
	
	t_spw_item.wait_time = GameState.timer_power_up
	t_spw_item.start()
	t_spw_item.connect("timeout", func():
		_spawn_power_up())
	
	t_lightning.connect("timeout", func():
		%WorldShadow.color = LIGHT_FLASH_ON
		%LightningAudio.play()
		# random value for the next flash
		t_lightning.wait_time = randf_range(0.1, 8))
	
	if GameState.player_number >= 1:
		var p:Player = player.instantiate()
		p.name = "P1"
		p.player_id = 1
		p.tank_texture = PlayerState.p1_tank_texture
		p.barrel_texture = PlayerState.p1_barrel_texture
		p.rotate(deg_to_rad(-90))
		_add_common_properties(p)
		add_child(p)
		_players.push_back(p)
		%P1Score.visible = true
	
	if GameState.player_number >= 2:
		var p:Player = player.instantiate()
		p.name = "P2"
		p.player_id = 2
		p.tank_texture = PlayerState.p2_tank_texture
		p.barrel_texture = PlayerState.p2_barrel_texture
		p.rotate(deg_to_rad(-90))
		_add_common_properties(p)
		add_child(p)
		_players.push_back(p)
		%P2Score.visible = true
		
	if GameState.player_number >= 3:
		var p:Player = player.instantiate()
		p.name = "P3"
		p.player_id = 3
		p.tank_texture = PlayerState.p3_tank_texture
		p.barrel_texture = PlayerState.p3_barrel_texture
		p.rotate(deg_to_rad(-90))
		_add_common_properties(p)
		add_child(p)
		_players.push_back(p)
		%P3Score.visible = true
		
	if GameState.player_number >= 4:
		var p:Player = player.instantiate()
		p.name = "P4"
		p.player_id = 4
		p.tank_texture = PlayerState.p4_tank_texture
		p.barrel_texture = PlayerState.p4_barrel_texture
		p.rotate(deg_to_rad(-90))
		_add_common_properties(p)
		add_child(p)
		_players.push_back(p)
		%P4Score.visible = true
	
	_respawn_banner()
	_change_map()

func _process(_delta: float) -> void:
	if GameState.lightning and _is_lightning_active:
		%WorldShadow.color = lerp(%WorldShadow.color, LIGHT_FLASH_OFF, 0.005)
	else:
		%WorldShadow.color = lerp(%WorldShadow.color, LIGHT_FLASH_ON, 0.005)
	
	if t_show_banner.time_left > 0 :
		%WinBanner.visible = true
		%WinnerBack.position.x = \
			lerpf(%WinnerBack.position.x, 0, WIN_BANNER_SPEED)
		%RoundLabel.position.x = \
			lerpf(%RoundLabel.position.x, screen_size.x/2-%RoundLabel.size.x/2, WIN_BANNER_SPEED/2)
		%PlayerLabel.position.x = \
			lerpf(%PlayerLabel.position.x, screen_size.x/2-%PlayerLabel.size.x/2, WIN_BANNER_SPEED/2)
		_win_banner_base_speed = 1
	elif t_hide_banner.time_left > 0 :
		_win_banner_base_speed *= 1.1
		%WinnerBack.position.x = \
			move_toward(%WinnerBack.position.x, -screen_size.x, _win_banner_base_speed)
		%RoundLabel.position.x = \
			move_toward(%RoundLabel.position.x, screen_size.x, _win_banner_base_speed)
		%PlayerLabel.position.x = \
			move_toward(%PlayerLabel.position.x, screen_size.x, _win_banner_base_speed)
	else:
		_respawn_banner()

func _respawn_banner() -> void:
	%WinBanner.visible = false
	%WinnerBack.position.x = screen_size.x
	%RoundLabel.position.x = -%RoundLabel.size.x
	%PlayerLabel.position.x = -%PlayerLabel.size.x

func _add_common_properties(p: Player) -> void:
	p.add_to_group(GameState.GRP_RESPAWN)
	p.parent_owner = self
	# added this because the "MovingWall" doesn't display behind the "WinBanner"
	# so I use "top_level" on the player, the banner and the bullet to keep the effect
	p.top_level = true
	p.z_index = 11
	p.connect("fight_started", $BackgroundAudio.on_fight_started)
	p.connect("fight_started", camera.on_fight_started)
	p.connect("player_killed", camera.on_player_killed)
	p.connect("player_killed", _on_player_killed)

func play_bullet_clash() -> void:
	if !%BulletClash.playing:
		%BulletClash.play(1.1)

func _spawn_power_up() -> void:
	var spw_power_up: Marker2D = _get_rand_spw_power_up()
	if spw_power_up == null or \
		_power_up != null: 
		return
	var pu: PowerUp = power_up.instantiate()
	pu.parent_owner = spw_power_up
	if GameState.current_lvl_id == 6:
		# disable spawn animation on this specific level
		pu.spawn_anim = false
	pu.despawned.connect(func():
		# allow a new power up to spawn
		_power_up = null
		t_spw_item.start())
	pu.duplicated_player.connect(func(op:Player):
		var p:Player = player.instantiate()
		p.name = op.name
		p.player_id = op.player_id
		p.tank_texture = op.tank_texture
		p.barrel_texture = op.barrel_texture
		p.init_position = op.position
		p.is_duplicate = true
		_add_common_properties(p)
		add_child(p)
		_players_dup.push_back(p))
	
	spw_power_up.add_child(pu)
	# only 1 Power Up at a time
	_power_up = pu

# return a random spawn location
func _get_rand_spw_power_up() -> Marker2D:
	match randi_range(1, 2):
		2:
			return spw_power_up_2
		_:
			# default value
			return spw_power_up_1

func _on_player_killed(killer_id: int, killed_id: int) -> void:
	var score_label = "%" + "P%sScore" % killer_id
	get_node(score_label) \
		.push_score(1 if killer_id != killed_id else -1)
	
	var particle = "%" + "P%sParticles" % killer_id
	get_node(particle).emitting = true
	
	var dead_count:int = 0
	# loop on real players (not duplicates):
	# ----+-----+----
	# ply | dup | cnt
	# a:b | x:y | 0:0
	# ----+-----+----
	# 1 . | . . | a . (=1)
	# 1 1 | . . | a b (=2)
	# . . | 1 . | . . (=0)
	# 1 . | 1 . | x . (=1)
	# 1 1 | 1 . | x b (=2)
	for p:Player in _players:
		if p.is_killed:
			# check if player has a duplicate
			var dup: Array[Player] = _players_dup \
				.filter(func(dp): if dp.player_id == p.player_id:
					return dp)
			# increase counter only if the duplicate is dead
			# (player is also dead, so we count 1 death for both)
			if dup.size() > 0:
				if dup.any(func(dp): return dp.is_killed):
					dead_count += 1
			else:
				# no duplicate, count as 1 death
				dead_count += 1
	
	if dead_count >= GameState.player_number - 1:
		# 1 or 0 player left
		_reload_level()

func _change_map() -> void:
	# increase lvl id without exceeding the max number of lvl
	GameState.current_lvl_id = 1 + (GameState.current_lvl_id % GameState.MAX_LVL)
	# cleanup current level
	for child in %Map.get_children():
		%Map.remove_child(child)
	# load next level
	var lvl_scn: PackedScene = load("res://scenes/levels/lvl%s.tscn"%GameState.current_lvl_id)
	var l: Node = lvl_scn.instantiate()
	spw_power_up_1 = l.get_node("%SpawnPowerUp1")
	spw_power_up_2 = l.get_node("%SpawnPowerUp2")
	spw_tracks = l.get_node("SpawnTracks")
	%Map.add_child(l)
	# add players
	for p:Player in _players:
		var spw_player = "%" + "P%sSpawn" % p.player_id
		p.init_position = l.get_node(spw_player).position
		p.spw_tracks = spw_tracks
	# add one of the weather effect
	_is_lightning_active = randi_range(0, 9) == 0
	if _is_lightning_active:
		t_lightning.start()
	else:
		t_lightning.stop()
	_is_cloud_active = !_is_lightning_active and randi_range(0, 9) == 0
	%CloudParticle.emitting = _is_cloud_active

func _reload_level() -> void:
	# wait before reloading/changing the scene
	await get_tree().create_timer(1).timeout
	GameState.current_round += 1
	
	var winner_count: int = GameState.p_infos.values() \
		.filter(func(p: PlayerInfo): 
			return p.score >= GameState.winning_score) \
		.size()
	if winner_count >= 1:
		# at least one player has win
		if get_tree():
			# check the tree, because he can be null (if players kill
			# each other on the "same" frames)
			get_tree().change_scene_to_file("res://scenes/menus/end_results.tscn")
		return
	
	if GameState.current_round % GameState.max_round_by_level == 0:
		_change_map()
	
	var pi = GameState.get_player_perfect_score(_players_dup.size())
	if pi:
		%PlayerLabel.text = "perfect: %s" % pi.name
		%PlayerLabel.add_theme_color_override("font_color", pi.color)
	else:
		%PlayerLabel.text = "..."
		%PlayerLabel.add_theme_color_override("font_color", Color.BLACK)
	
	%RoundLabel.text = "Round %s" % (GameState.current_round + 1)
	t_show_banner.start()
	t_spw_item.start(1 if GameState.current_lvl_id == 6 else GameState.timer_power_up)
	
	# respawn ALL objetcs
	get_tree().call_group(GameState.GRP_RESPAWN, GameState.GRP_RESPAWN)
	$BackgroundAudio.on_round_started()
	if _power_up != null:
		_power_up.dispawn()
	
	for p:Player in _players_dup:
		p.queue_free()
	_players_dup = []
	GameState.reset_score_round()
