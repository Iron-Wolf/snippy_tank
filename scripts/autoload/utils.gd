extends Node

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

# move "node" : fast to slow
func ease_out(node: Control, target_x: float) -> void:
	# "lerp" doesn't always finish on whole number
	while node.position.x - target_x > 1: 
		node.position.x = lerpf(node.position.x, target_x, 0.5)
		# timer to actually see the transition
		await get_tree().create_timer(0.01).timeout

# move "node" : slow to fast
func ease_in(node: Control, target_x: float) -> void:
	var base_speed: float = 1
	while node.position.x != target_x:
		base_speed *= 1.5
		node.position.x = move_toward(node.position.x, target_x, base_speed)
		# timer to actually see the transition
		await get_tree().create_timer(0.01).timeout
