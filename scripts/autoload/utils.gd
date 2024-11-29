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
