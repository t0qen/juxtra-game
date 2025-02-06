extends CharacterBody2D

@export var base_speed : int = 100
@export var air_speed : int = 80
@export var jump_height : float = 15.0
@export var jump_time_to_peak : float = 0.25
@export var jump_time_to_fall : float = 0.15

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)) * -1.0

@onready var sprites: AnimatedSprite2D = $Sprites

enum STATE {
	IDLE,
	RUN,
	FLY,
	JUMP,
	WAIT
}

var current_state : STATE
var gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_player : int = 1
var current_speed : float = base_speed
var want_to_jump : bool = false
var direction : int = 0
var want_to_dash : bool = false

func _ready() -> void:
	_set_state(STATE.IDLE)
	
func _physics_process(delta: float) -> void:
	_update_state(delta)
	
func get_inputs():
	if current_player == 1:
		want_to_jump = Input.is_action_just_pressed("jump_1")
		direction = Input.get_axis("move_left_1", "move_right_1")
		want_to_dash = Input.is_action_just_pressed("dash_1")
		
func _set_state(new_state: STATE) -> void:
	if current_state == new_state:
		return
	_exit_state()
	current_state = new_state
	_enter_state()
	
func _enter_state() -> void:
	match current_state:
		STATE.IDLE: # Enter IDLE state logic
			play_animation("idle")
		STATE.RUN: # Enter WALK state logic
			current_speed = base_speed
			play_animation("walk")
		STATE.JUMP: # Enter JUMP state logic
			velocity.y = jump_velocity
			play_animation("jump")
		STATE.FLY: # Enter FALL state logic
			current_speed = air_speed
			play_animation("fly")

func _exit_state() -> void:
	match current_state:
		STATE.IDLE: # Exit IDLE state logic
			pass
			
		STATE.RUN: # Exit WALK state logic
			pass
			
		STATE.JUMP: # Exit JUMP state logic
			pass
			
		STATE.FLY: # Exit FALL state logic
			pass
			
func _update_state(delta: float) -> void:
	match current_state:
		STATE.IDLE: # Update IDLE state logic
			if direction: # If left or right is pressed, start walking
				_set_state(STATE.RUN)
			elif !is_on_floor(): # if not on floor, fall down
				_set_state(STATE.FLY)
			elif Input.is_action_just_pressed("ui_accept"):
				_set_state(STATE.JUMP) # if the jump button is pressed, then jump
			
		STATE.RUN: # Update WALK state logic
			velocity.x = direction * current_speed # Set the move direction
			flip_sprites()
				
			if !is_on_floor(): # if not on floor, fall down
				_set_state(STATE.FLY)
			elif Input.is_action_just_pressed("ui_accept"):
				_set_state(STATE.JUMP) # if jump is pressed, jump
			elif velocity.x == 0: # if standing still, then set idle
				_set_state(STATE.IDLE)
				
			move_and_slide()
			
		STATE.JUMP: # Update JUMP state logic
			velocity.x = direction * current_speed # Set the move direction
			flip_sprites()
				
			if !is_on_floor(): # if in the air, apply gravity
				velocity.y += get_current_gravity() * delta
				if velocity.y > 0: # after max height, change from JUMP to FALL
					_set_state(STATE.FLY)
				
			move_and_slide()
			
		STATE.FLY: # Update FALL state logic
			velocity.x = direction * current_speed # Set the move direction
			if velocity.x > 0: # Set Sprite direction
				sprites.flip_h = true
			elif velocity.x < 0:
				sprites.flip_h = false
			if is_on_floor(): # If the ground is reached, change back to idle
				_set_state(STATE.IDLE)
			else: # if still in the air, apply gravity
				velocity.y += get_current_gravity() * delta
			move_and_slide()
			
func set_player_1():
	current_player = 1
	
func set_player_2():
	current_player = 2
	
func play_animation(animation: String):
	if  current_player == 1:
		match animation:
			"jump":
				sprites.play("jump")

func get_current_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func flip_sprites():
	if velocity.x > 0: # Set Sprite direction
		sprites.flip_h = true
	elif velocity.x < 0:
		sprites.flip_h = false
