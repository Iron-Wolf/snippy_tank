extends CharacterBody2D

# constants
const MAX_SPEED: float = 500.0
const ACCELERATION: float = 1000.0
const DECELERATION: float = 800.0
const ROTATE: float = 5.0
const STOP_THRESHOLD: float = 30.0  # stop when speed is below
const LATERAL_FRICTION: float = 1.0 # Contrôle la réduction du dérapage
const DRIFT_INTENSITY: float = .9

# global variables
var current_speed: float = 0.0
var target_speed: float = 0.0
var classic_dir = Vector2.ZERO
var drift_velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	#var barrel: Sprite2D = get_child(1)
	#barrel.rotate(0.1)
	
	# Appeler les fonctions de mouvement et rotation
	update_target_speed()
	apply_inertia(delta)
	apply_rotation(delta)
	apply_drift(delta)
	velocity += drift_velocity
	move_and_slide()

func _unhandled_input(_event: InputEvent) -> void:
	#direction.x = Input.get_axis("move_left", "move_right")
	#direction.y = Input.get_axis("move_up", "move_down")
	classic_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

# all-in-one "ZQSD/WASD" movement
#func classic_move(delta: float) -> void:
#	var forward_dir = classic_dir.y
#	velocity = transform.y * forward_dir * MAX_SPEED
#	var rotation_dir = classic_dir.x
#	rotation += rotation_dir * ROTATE * delta

# set the speed
func update_target_speed() -> void:
	if classic_dir.y != 0:
		target_speed = MAX_SPEED * classic_dir.y
	else:
		target_speed = 0.0

# use linear interpolation to get current speed
func apply_inertia(delta: float) -> void:
	if target_speed != 0:
		current_speed = lerpf(current_speed, target_speed, ACCELERATION * delta / MAX_SPEED)
	else:
		current_speed = lerpf(current_speed, 0.0, DECELERATION * delta / MAX_SPEED)
	# stop if speed is to low (to avoid an "icy" effect)
	if abs(current_speed) < STOP_THRESHOLD and target_speed == 0:
		current_speed = 0.0
		drift_velocity = Vector2.ZERO
	velocity = transform.y * current_speed

func apply_rotation(delta: float) -> void:
	rotation += classic_dir.x * ROTATE * delta

# Ajoute un effet de dérapage au mouvement
func apply_drift(delta: float) -> void:
	# Calcul de la vitesse latérale en fonction de la direction actuelle
	var sideways_velocity = velocity.project(transform.x)
	# Ajoute un glissement contrôlé (dérapage) lorsque le joueur tourne
	drift_velocity += sideways_velocity * DRIFT_INTENSITY
	# Réduit progressivement la vitesse latérale grâce à une friction
	drift_velocity = drift_velocity.lerp(Vector2.ZERO, LATERAL_FRICTION * delta)
