# Shake code is made by queble :
# https://github.com/QuebleGameDev/Godot-Screen-Shake

extends Camera2D

# - SHAKE PARAMETERS
@export var decay : float = 0.8 # Time it takes to reach 0% of trauma
@export var max_offset : Vector2 = Vector2(100, 75) # Max hor/ver shake in pixels
@export var max_roll : float = 0.1 # Maximum rotation in radians (use sparingly)
var trauma : float = 0.0 # Current shake strength
var trauma_power : int = 2 # Trauma exponent. Increase for more extreme shaking

func _ready() -> void:
	randomize() # Randomize the game seed

func _process(delta : float) -> void:
	if trauma: # If the camera is currently shaking
		trauma = max(trauma - decay * delta, 0) # Decay the shake strength
		shake() # Shake the camera

# - SHAKE FUNCS
func add_trauma(amount : float) -> void: ## The function to use for adding trauma (screen shake)
	trauma = min(trauma + amount, 1.0) # Add the amount of trauma (capped at 1.0)

func shake() -> void: ## This function is used to actually apply the shake to the camera
	#? Set the camera's rotation and offset based on the shake strength
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	offset.x = max_offset.x * amount * randf_range(-1, 1)
	offset.y = max_offset.y * amount * randf_range(-1, 1)

func start_shake(trauma : float = 0.5, changed_decay : float = 0.8, changed_max_offset : Vector2 = Vector2(50, 50), changed_max_roll : float = 0.1) -> void:  # func that start a shake
	# changed first parameters with func parameters
	decay = changed_decay 
	max_offset = changed_max_offset
	max_roll = changed_max_roll
	add_trauma(trauma) # finally start the shake

func reset_trauma():
	trauma = 0
