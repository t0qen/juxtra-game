extends CharacterBody2D
class_name Player

#region VARIABLES
@export_group("Global")
@export var current_player : int = 1 # wich player this script is for, can be changed by other script via func

#region MOVEMENTS
@export_group("Movements")
@export var gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity") # default gravity 

# - RUN
@export_subgroup("Run")
@export var base_speed : int = 120 # base speed of player, on ground
@export var air_speed : int = 80 # it can change in air
var current_speed : float = base_speed # store the current speed

# - JUMP
@export_subgroup("Jump")
@export var jump_height : float = 50.0 # height of player's jump
@export var jump_time_to_peak : float = 0.3
@export var jump_time_to_fall : float = 0.15
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0 # maths
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)) * -1.0
#endregion

#region NODES
@export_group("Nodes")
# - TIMERS
@export_subgroup("Timers")
@export var exit_idle_timer : Timer # cooldown before switch to idle to sleep state
@export var exit_fall_timer : Timer # cooldown to play fall animation before enter state wait
@export var exit_wait_timer : Timer # cooldown before switch to wait to idle state 
@export var jump_bug_timer : Timer # little delay after apply jump to prevent bug

# - OTHERS
@export_subgroup("Others")
@export var sprites : AnimatedSprite2D # get the animated sprite node from player
#endregion

#region STATES
@export_group("States")

enum STATE { # each states of player 
	IDLE,
	RUN,
	FLY,
	JUMP,
	WAIT,
	SLEEP
}

@export var first_state : STATE = STATE.IDLE # with wich state player will begin ?

# - OTHERS
var current_state : STATE # where the current state of player will be stored
var jumping : bool = false # bool to know if player is jumping
var exit_wait : bool = false # bool to store the end of timer
var exit_idle : bool = false # same for idle
var exit_fall : bool = false # same for fall
#endregion

#region INPUTS
var want_to_jump : bool = false # a bool to know if player want to jump
var direction : int = 0 # the direction of player, may a Vector2 ? consider jump as direction ? TODO
var want_to_dash : bool = false # same for dash 

#endregion
#endregion

#region GLOBAL FUNCTIONS

func _ready() -> void: 
	set_player_1() # for test, set player 1
	_set_state(first_state) # set player's state to first state
	
func _physics_process(delta: float) -> void: # each frame we call this function to update player state, for example if he's not on ground we set his state to fall, etc
	get_inputs()
	_update_state(delta) #
#endregion

	
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
			exit_idle = false
			exit_idle_timer.start() # start timer
			
			
		STATE.WAIT:
			if !exit_fall:
				play_animation("wait")
			else:
				play_animation("exit_fall")
				exit_fall_timer.start()
				exit_fall = false
				
			exit_wait = false
			exit_wait_timer.start()
			
			
		STATE.SLEEP:
			play_animation("sleep")	

		STATE.RUN: 
			stop_idle_timers()
			current_speed = base_speed # set on ground speed
			play_animation("run")
			
		STATE.JUMP: 
			stop_idle_timers()
			current_speed = air_speed
			jumping = true
			play_animation("jump")
			velocity.y = jump_velocity # apply jump
			jump_bug_timer.start() # this timer is here to prevent bug if STATE.JUMP begin to soon
			
			
			
		STATE.FLY: 
			stop_idle_timers()
			current_speed = air_speed # set air speed
			play_animation("fly")
			
		

func _exit_state() -> void: # exit transition, nothing for now
	match current_state:
		STATE.IDLE: 
			pass
			
		STATE.RUN:
			pass
			
		STATE.JUMP: 
			jumping = false
			exit_fall = true
			
		STATE.FLY: 
			exit_fall = true

		STATE.SLEEP:
			pass
			
func _update_state(delta: float) -> void:  # every behavior of each states  TO FINISH
	match current_state:
		STATE.JUMP: 
			x_move()
			if is_on_floor() && !jumping: 
				if direction:
					_set_state(STATE.RUN)
				else:
					_set_state(STATE.WAIT)
			else:	
				apply_gravity(delta)
			move_and_slide()
			
		STATE.IDLE: 
			if exit_idle:
				_set_state(STATE.SLEEP)
				
			if direction: # ef left or right is pressed, start walking
				_set_state(STATE.RUN)
				
			elif want_to_jump: # jump action, come with inputs system
				_set_state(STATE.JUMP) # if the jump button is pressed, then jump
				
			elif !is_on_floor() && !jumping: # if not on floor, fall down
				_set_state(STATE.FLY)
				
		STATE.WAIT:
			if exit_wait:
				_set_state(STATE.IDLE)
			if direction: # ef left or right is pressed, start walking
				_set_state(STATE.RUN)
			if want_to_jump: # jump action, come with inputs system
				_set_state(STATE.JUMP) # if the jump button is pressed, then jump	
			if !is_on_floor() && !jumping: # if not on floor, fall down
				print("136")
				_set_state(STATE.FLY)
			
		STATE.SLEEP:
			if direction: # ef left or right is pressed, start walking
				_set_state(STATE.RUN)
				
			elif want_to_jump: # jump action, come with inputs system
				_set_state(STATE.JUMP) # if the jump button is pressed, then jump
				
			elif !is_on_floor() && !jumping: # if not on floor, fall down
				_set_state(STATE.FLY)		
			
		STATE.RUN:
			x_move()
			if !direction: 
				_set_state(STATE.WAIT)
			if want_to_jump:
				_set_state(STATE.JUMP) # if jump is pressed, jump
			if !is_on_floor() && !jumping: 
				_set_state(STATE.FLY)
			
			move_and_slide() 
			
		STATE.FLY: 
			x_move()
			if is_on_floor(): # If the ground is reached, change back to idle
				if direction:
					_set_state(STATE.RUN)
				else:
					_set_state(STATE.WAIT)
			else: 
				apply_gravity(delta)
			move_and_slide()
			
		
				
func set_player_1(): # we can choose for player 1 or player 2 when multiplayer, so keyboard will change
	current_player = 1
	
func set_player_2():
	current_player = 2
	
func play_animation(animation: String): # play animation
	if current_player == 1: # aniamtions with player's 1 skin
		match animation:
			"jump":
				sprites.play("jump_1")
			"run":
				sprites.play("run_1")
			"idle":
				sprites.play("idle_1")
			"fly":
				sprites.play("fly_1")
			"wait":
				sprites.play("wait_1")
			"sleep":
				sprites.play("sleep_1")
			"exit_fall":
				sprites.play("exit_fall_1")
				
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
			"wait":
				sprites.play("wait_2")
			"sleep":
				sprites.play("sleep_2")
			"exit_fall":
				sprites.play("exit_fall_2")
					
func get_current_gravity() -> float: # return gravity
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func flip_sprites():
	if velocity.x > 0: # set Sprite direction
		sprites.flip_h = false
	elif velocity.x < 0:
		sprites.flip_h = true

func x_move():
	velocity.x = direction * current_speed 
	flip_sprites() # flip player's sprite with his direction
	
func apply_gravity(delta):
	velocity.y += get_current_gravity() * delta	
		
func stop_idle_timers(): # must be call on every movments states
	exit_fall_timer.stop()
	exit_idle_timer.stop()
	exit_wait_timer.stop()
		
# timers calls
func _on_exit_idle_timeout() -> void:
	exit_idle = true
	
func _on_exit_fall_timeout() -> void:
	play_animation("wait")
	
func _on_exit_wait_timeout() -> void:
	exit_wait = true

func _on_jump_bug_timeout() -> void:
	jumping = false	
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
