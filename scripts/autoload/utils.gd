extends Node

@onready var g_screen_size: Vector2 = get_viewport().size

func apply_screen_wrap(position: Vector2, screen_size: Vector2) -> Vector2:
	# basic screen wrap
	#position.x = wrapf(position.x, 0, screen_size.x)
	#position.y = wrapf(position.y, 0, screen_size.y)
	
	# custom screen wrap
	if position.x > screen_size.x:
		position.x = 0
		position.y -= 700
	if position.x < 0:
		position.x = screen_size.x
		position.y += 700
	if position.y > screen_size.y:
		position.x += 800
		position.y = 0
	if position.y < 0:
		position.x -= 800 
		position.y = screen_size.y
	
	return position

func log_error(message: String, with_alert: bool = false) -> void:
	push_error(message)
	if with_alert:
		OS.alert(message, "ALERT !")


func scene_lc(node: Control) -> void:
	node.position.x = -g_screen_size.x
	await ease_out(node, Vector2(0, node.position.y))

func scene_rc(node: Control) -> void:
	node.position.x = g_screen_size.x
	await ease_out(node, Vector2(0, node.position.y))

func scene_uc(node: Control) -> void:
	node.position.y = -g_screen_size.y
	await ease_out(node, Vector2(node.position.x, 0))

func scene_cl(node: Control) -> void:
	await ease_in(node, Vector2(-g_screen_size.x, node.position.y))

func scene_cr(node: Control) -> void:
	await ease_in(node, Vector2(g_screen_size.x, node.position.y))

func scene_cu(node: Control) -> void:
	await ease_in(node, Vector2(node.position.x, -g_screen_size.x))

# move "node" : fast to slow
func ease_out(node: Control, target: Vector2) -> void:
	# "lerp" doesn't always finish on whole number, so we must
	# check if the two Vector are close enough (> 1).
	# Also, we use "length" to compare Vector size (otherwise, Godot
	# will try to compare directions)
	while node != null and abs(node.position.length()) - abs(target.length()) > 1: 
		node.position = lerp(node.position, target, 0.5)
		# timer to actually see the transition
		await get_tree().create_timer(0.01).timeout

# move "node" : slow to fast
func ease_in(node: Control, target: Vector2) -> void:
	var base_speed: float = 1
	while node != null and node.position != target:
		base_speed *= 1.5
		node.position.x = move_toward(node.position.x, target.x, base_speed)
		node.position.y = move_toward(node.position.y, target.y, base_speed)
		# timer to actually see the transition
		await get_tree().create_timer(0.01).timeout
