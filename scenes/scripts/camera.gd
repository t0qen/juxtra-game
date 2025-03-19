# *Some code here might be genrated by Claude 3.7
extends Camera2D

# - TREMBLE
@export_group("Tremble")
@export var decay_rate: float = 2.0  # Vitesse à laquelle le tremblement diminue
@export var max_offset: Vector2 = Vector2(100, 75)  # Déplacement maximum de la caméra
@export var max_roll: float = 0.05  # Rotation maximale (en radians)
@export var noise_speed: float = 15.0  # Vitesse du bruit pour avoir un mouvement aléatoire fluide

var noise: FastNoiseLite
var noise_position: Vector2 = Vector2.ZERO
var trauma: float = 0.0  # Niveau de trauma (0.0 à 1.0)
var trauma_direction: Vector2 = Vector2(1.0, 1.0)  # Direction du tremblement
var trauma_time_remaining: float = 0.0

func _ready() -> void:
	# Initialisation du générateur de bruit pour un mouvement pseudo-aléatoire fluide
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 4.0
	noise.fractal_octaves = 1

func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = max(trauma - decay_rate * delta, 0.0)
	
	if trauma_time_remaining > 0:
		trauma_time_remaining -= delta
		if trauma_time_remaining <= 0:
			trauma = 0.0
	
	var shake_amount = trauma * trauma
	
	noise_position.x += delta * noise_speed
	noise_position.y += delta * noise_speed
	
	var offset = Vector2.ZERO
	offset.x = max_offset.x * shake_amount * trauma_direction.x * get_noise_value(noise_position.x)
	offset.y = max_offset.y * shake_amount * trauma_direction.y * get_noise_value(noise_position.y + 100.0)
	
	var roll = max_roll * shake_amount * get_noise_value(noise_position.x + 200.0)
	
	offset = offset
	rotation = roll

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

func shake(intensity: float = 0.5, duration: float = 0.5, direction: Vector2 = Vector2(1.0, 1.0)) -> void:
	stop_shake()
	trauma = max(trauma, intensity)
	trauma_time_remaining = duration
	trauma_direction = direction.normalized()

func stop_shake() -> void:
	trauma = 0.0
	trauma_time_remaining = 0.0
	offset = Vector2.ZERO
	rotation = 0.0

func get_noise_value(pos: float) -> float:
	return noise.get_noise_1d(pos) * 2.0
