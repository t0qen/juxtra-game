extends CharacterBody2D

@export var base_speed : int = 120 # base speed of player, on ground
@export var air_speed : int = 80 # it can change in air
@export var jump_height : float = 75.0 # height of player's jump
@export var jump_time_to_peak : float = 0.5
@export var jump_time_to_fall : float = 0.2

# jump maths
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0 
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)) * -1.0

@onready var sprites: AnimatedSprite2D = $Sprites # get the animated sprite node from player
 
enum STATE { # each states of player for finite state machine
	IDLE,
	RUN,
	FLY,
	JUMP,
	WAIT
}

var current_state : STATE # where the current state of player will be stored
var gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_player : int = 1 # wich player this script is for, can change for multiplayer
var current_speed : float = base_speed # store the current speed
var want_to_jump : bool = false # a bool to know if player want to jump
var direction : int = 0 # the direction of player, maybe a Vector2 ? consider jump as direction ?
var want_to_dash : bool = false # same for dash

func _ready() -> void: # first we set the state of player to idle
	_set_state(STATE.IDLE)
	set_player_1()
	
func _physics_process(delta: float) -> void: # each frame we call this function to update player state, for example if he's not on ground we set his state to fall, etc
	get_inputs()
	_update_state(delta)
	Engine.time_scale = 0.1
	
func get_inputs(): # essential function to get player inputs, depend on wich player is 
	if current_player == 1: # if current player is 1 get input with player's 1 inputs
		want_to_jump = Input.is_action_just_pressed("jump_1")
		direction = Input.get_axis("move_left_1", "move_right_1")
		want_to_dash = Input.is_action_just_pressed("dash_1")
	# TODO player 2
		
func _set_state(new_state: STATE) -> void: # simple function to change player's state
	if current_state == new_state: # don't change if the requested state is the same that the current
		return
	_exit_state() # exit transition for example if we exit fall state it means that player is on ground
	current_state = new_state
	_enter_state() # enter transition for example jump : propulse player
	
func _enter_state() -> void: # enter transition, basiclly we play animations
	match current_state:
		STATE.IDLE:
			play_animation("idle")
		STATE.RUN: 
			current_speed = base_speed # set on ground speed
			play_animation("run")
		STATE.JUMP: 
			velocity.y = jump_velocity # apply jump
			play_animation("jump")
		STATE.FLY: 
			current_speed = air_speed # set air speed
			play_animation("fly")

func _exit_state() -> void: # exit transition, nothing for now
	match current_state:
		STATE.IDLE: 
			pass
			
		STATE.RUN:
			pass
			
		STATE.JUMP: 
			pass
			
		STATE.FLY: 
			pass
			
func _update_state(delta: float) -> void:  # every behavior of each states  TO FINISH
	match current_state:
		STATE.IDLE: 
			if direction: # ef left or right is pressed, start walking
				_set_state(STATE.RUN)
			elif !is_on_floor(): # if not on floor, fall down
				_set_state(STATE.FLY)
			elif want_to_jump: # jump action, come with inputs system
				_set_state(STATE.JUMP) # if the jump button is pressed, then jump
			
		STATE.RUN:
			velocity.x = direction * current_speed # Set the move direction
			flip_sprites()
				
			# if not on floor, fall down so fly 
			if want_to_jump:
				_set_state(STATE.JUMP) # if jump is pressed, jump
			else:
				if !is_on_floor(): 
					_set_state(STATE.FLY)
			if velocity.x == 0: # if standing still, then set idle
				_set_state(STATE.IDLE)
				
			move_and_slide() 
			
		STATE.JUMP: 
			velocity.x = direction * current_speed # set the move direction
			flip_sprites() # flip player's sprite with his direction
				
			if !is_on_floor(): # if in the air, apply gravity
				velocity.y += get_current_gravity() * delta
			
			if is_on_floor():
				print("ON FLOOR")		
				if direction:
					_set_state(STATE.RUN)
				else:
					print("set idle")
					_set_state(STATE.IDLE)
					
			move_and_slide()
			
		STATE.FLY: 
			velocity.x = direction * current_speed # Set the move direction
			flip_sprites()
			if is_on_floor(): # If the ground is reached, change back to idle
				_set_state(STATE.IDLE)
			else: # if still in the air, apply gravity
				velocity.y += get_current_gravity() * delta
			move_and_slide()
			
func set_player_1(): # we can choose for player 1 or player 2 when multiplayer, so keyboard will change
	current_player = 1
	
func set_player_2():
	current_player = 2
	
func play_animation(animation: String): # play animation
	if current_player == 1: # aniamtions with player's 1 skin
		print(animation)
		match animation:
			"jump":
				sprites.play("jump_1")
			"run":
				sprites.play("run_1")
			"idle":
				sprites.play("idle_1")
			"fly":
				sprites.play("fly_1")
	elif current_player == 2: # aniamtions with player's 2 skin
		match animation: 
			"jump":
				sprites.play("jump_2")
			"run":
				sprites.play("run_2")
			"idle":
				sprites.play("idle_2")
			"fly":
				sprites.play("fly_2")	
				
func get_current_gravity() -> float: # return gravity
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func flip_sprites():
	if velocity.x > 0: # set Sprite direction
		sprites.flip_h = true
	elif velocity.x < 0:
		sprites.flip_h = false
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
