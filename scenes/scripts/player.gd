extends CharacterBody2D
class_name Player

#region VARIABLES  -
@export_group("Global")
@export var current_player : int = 1 # wich player this script is for, can be changed by other script via func

#region MOVEMENTS
@export_group("Movements")
@export var gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity") # default gravity 

# - PROPULSE DOWN
@export_subgroup("Propulse down")
@export var propulsion_down_force : int = 50 # with wich force player will be propulsed down

# - DASH
@export_subgroup("Dash")
@export var dash_force : int
@export var max_dashs : int = 3

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
@export var max_jumps : int = 2
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0 # maths
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)) * -1.0
enum JUMP {
	NO,
	JUMP,
	JUMP_2,
	JUMP_3
}
var current_jump = JUMP.JUMP # store the current what jump player is actually perform
#endregion

#region NODES
@export_group("Nodes")
# - TIMERS
@export_subgroup("Timers")
@export var exit_idle_timer : Timer # cooldown before switch to idle to sleep state
@export var exit_fall_timer : Timer # cooldown to play fall animation before enter state wait
@export var exit_wait_timer : Timer # cooldown before switch to wait to idle state 
@export var jump_bug_timer : Timer # little delay after apply jump to prevent bug
@export var before_dash_timer : Timer

# - OTHERS
@export_subgroup("Others")
@export var sprites : AnimatedSprite2D # get the animated sprite node from player
#endregion

#region STATES
@export_group("States")
enum STATE { # each states of player 
	IDLE, # 0
	RUN, # 1 
	FLY, # 2
	JUMP, # 3
	JUMP_2, # 4
	JUMP_3, # 5
	WAIT, # 6
	SLEEP, # 7
	DASH # 8
}
@export var current_state : STATE = STATE.WAIT # where the current state of player will be stored, can stored to first state

# - OTHERS
var jumping : bool = false # bool to know if player is jumping
var exit_wait : bool = false # bool to store the end of timer
var exit_idle : bool = false # same for idle
var exit_fall : bool = false # same for fall
var before_dash_finish : bool = false
#endregion

#region INPUTS
var want_to_jump : bool = false # a bool to know if player want to jump
var direction : int = 0 # the direction of player, may a Vector2 ? consider jump as direction ? TODO
var want_to_dash : bool = false # same for dash 
var dash_dir : Vector2 # dash direction
var propulsion_down : bool = false # a bool to know if player want to be propulsed down

#endregion
#endregion

#region GLOBAL FUNCTIONS
func _ready() -> void: 
	set_player_1() # for test, set player 1
	
func _physics_process(delta: float) -> void: # each frame we call this function to update player state, for example if he's not on ground we set his state to fall, etc
	#Engine.time_scale = 0.1
	get_inputs() # first get inputs	
	_update_state(delta) # update the behavior of current state
	
func get_inputs(): # essential function to get player inputs, depend on wich player is 
	if current_player == 1: # if current player is 1 get input with player's 1 inputs
		want_to_jump = Input.is_action_just_pressed("jump_1") # bool to jump
		direction = Input.get_axis("move_left_1", "move_right_1") # int to get axis : -1 / 0 / 1
		want_to_dash = Input.is_action_just_pressed("dash_1")
		propulsion_down = Input.is_action_pressed("down_1")
		dash_dir.x = Input.get_axis("move_left_1", "move_right_1")
		dash_dir.y = Input.get_axis("jump_1", "down_1")
	# TODO player 2
#endregion	

#region STATE FUNCTIONS
func _set_state(new_state: STATE) -> void: # simple function to change player's state
	if current_state == new_state: # don't change if the requested state is the same that the current
		return
	_exit_state() # exit transition, for example if we exit fall state it means that player is on ground
	current_state = new_state # setnew state
	_enter_state() # enter transition, for example jump : propulse player
	
#region TRANSITIONS
func _enter_state() -> void: # enter transition, basiclly we play animations
	match current_state:
		STATE.IDLE:
			play_animation("idle")
			exit_idle_timer.start() # start timer, after end, set exit_idle to true
			
		STATE.WAIT:
			reset_jump()
			if !exit_fall: # if player wasn't falling before
				play_animation("wait") # play basic animation
			else: # if player was landng before, after jump or fly, play first exit fall animation
				play_animation("exit_fall") 
				exit_fall_timer.start() # start a timer to have the time to play exit fall animation
				
			exit_wait_timer.start() # on the end of this timer, exit wait will be true
			
		STATE.SLEEP: # nothing important here
			play_animation("sleep")	

		STATE.RUN: 
			reset_jump()
			exit_fall = false # reset exit fall
			stop_idle_timers() # we stop all idle timers, MAY NOT IMPORTANT ? TODO
			current_speed = base_speed # set on ground speed
			play_animation("run")
			
		STATE.JUMP: 
			current_jump = JUMP.JUMP
			perform_jump(1)
			
		STATE.JUMP_2: 
			current_jump = JUMP.JUMP_2
			perform_jump(1)
			
		STATE.JUMP_3: 
			current_jump = JUMP.JUMP_3
			perform_jump(1.25)	
			
		STATE.FLY: 
			exit_fall = false # reset exit fall
			stop_idle_timers() # we stop all idle timers, MAY NOT IMPORTANT ? TODO
			current_speed = air_speed # set air speed
			play_animation("fly")
			
		STATE.DASH: # TODO
			play_animation("before_dash")
			before_dash_finish = false
			before_dash_timer.start()
			while before_dash_finish != true:
				print("PRESS INPUTS")
			#velocity = vector2().normalized() × speed
			
			
func _exit_state() -> void: # exit transition, nothing really important
	match current_state:
		STATE.WAIT:
			pass
			
		STATE.IDLE: 
			pass
			
		STATE.RUN:
			pass
			
		STATE.JUMP: 
			exit_fall = true # say that player just land,to play land animaton also called exit_fall 
			
		STATE.FLY: 
			exit_fall = true # say that player just land,to play land animaton also called exit_fall 

		STATE.SLEEP:
			pass
			
		STATE.DASH:
			pass
#endregion

#region UPDATE STATE
func _update_state(delta: float) -> void:  # every behavior of each states updated every physics process
	match current_state:
		STATE.JUMP: 
			jump_update(delta)
		
		STATE.JUMP_2: 
			jump_update(delta)
			
		STATE.JUMP_3: 
			jump_update(delta)
				
		STATE.IDLE: 
			if direction: # if left or right is pressed, start walking
				_set_state(STATE.RUN)
				
			can_jump()
				
			if !is_on_floor() && !jumping: # if not on floor, fall down and fly TODO
				_set_state(STATE.FLY)
				
		STATE.WAIT:
				
			if direction: # ef left or right is pressed, start walking
				_set_state(STATE.RUN)
				
			can_jump()
				
			if !is_on_floor() && !jumping: # if not on floor, fall down and fly (TODO !jumping)
				_set_state(STATE.FLY)
			
		STATE.SLEEP:
			if direction: # if left or right is pressed, start walking
				_set_state(STATE.RUN)
				
			can_jump()
				
			if !is_on_floor() && !jumping: # if not on floor, fall down TODO
				_set_state(STATE.FLY)		
			
		STATE.RUN:
			x_move() # move on x axis
			
			if !direction: # if player doesn't move anymore 
				_set_state(STATE.WAIT)
				
			can_jump()
				
			if !is_on_floor() && !jumping: #  # if not on floor, fall down TODO
				_set_state(STATE.FLY)
			
			move_and_slide() # move
			
		STATE.FLY: 
			x_move() # move on x axis
			current_state
			can_jump()
				
			if is_on_floor(): # if player comes back on floor
				if direction: # if he want to move
					_set_state(STATE.RUN)
				else: # else
					_set_state(STATE.WAIT)
			else:
				if propulsion_down:
					apply_gravity(get_current_gravity() * propulsion_down_force, delta)
				else:
					apply_gravity(get_current_gravity(), delta) # else apply gravity
				 
			move_and_slide() # move
			
		STATE.DASH: # jump action, come with inputs system
			pass
#endregion
#endregion

#region OTHER
func reset_jump():
	current_jump = JUMP.NO
	
func perform_jump(coef: float): # func to do a jump
	exit_fall = false # reset exit fall
	stop_idle_timers() # we stop all idle timers, MAY NOT IMPORTANT ? TODO
	current_speed = air_speed # set in air speed
	jumping = true # set this variable to true to prevent some bug on other functions TODO
	play_animation("jump")
	velocity.y = jump_velocity * coef # apply jump
	jump_bug_timer.start() # this timer is here to prevent bug if STATE.JUMP begin to soon

func jump_update(delta): # basic func wich control jump int state update 
	x_move() # move on x axis with inputs
	can_jump() # jump action, come with inputs system
	if is_on_floor() && !jumping: # if player is on ground after his jump; var jumping is set to false after propulsion and after timer, without it, some bugs
		print("here")
		if direction: # if he want to run
			_set_state(STATE.RUN) # run
		else: # else
			_set_state(STATE.WAIT) # set wait; we play exit fall animation
			
	else:	
		if propulsion_down:
			apply_gravity(get_current_gravity() * propulsion_down_force, delta)
		else:
			apply_gravity(get_current_gravity(), delta) # else apply gravity
			
	move_and_slide() # move

func can_jump(): # TODO
	if !want_to_jump:
		return false
	else:
		if current_jump == JUMP.JUMP_3:
			return false
		else:
			print("can jump")
			if current_jump == JUMP.NO:
				#print("0")
				_set_state(STATE.JUMP)
			elif current_jump == JUMP.JUMP:
				#print("1")
				_set_state(STATE.JUMP_2)
			elif current_jump == JUMP.JUMP_2:
				#print("2")
				_set_state(STATE.JUMP_3)
			else:
				print("error line 364")			

func set_player_1(): # we can choose for player 1 or player 2 when multiplayer, so keyboard will change
	current_player = 1
	
func set_player_2(): # same for player 2
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
			"before_dash":
				sprites.play("before_dash_1")
			"dash":
				sprites.play("dash_1")
				
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
			"before_dash":
				sprites.play("before_dash_2")
			"dash":
				sprites.play("dash_2")
					
func can_dash(): # TODO
	pass
				
func get_current_gravity() -> float: # return gravity
	return jump_gravity if velocity.y < 0.0 else fall_gravity # if player's velocity < 0, it means that player is jumping so return jump gravity

func apply_gravity(current_gravity : float, delta : float ): # apply gravity
	velocity.y += current_gravity * delta	
	
func flip_sprites(): # simple func to automaticlly flip player sprite with the player's x velocity
	if velocity.x > 0: 
		sprites.flip_h = false
		
	elif velocity.x < 0:
		sprites.flip_h = true

func x_move(): # simple func to move player on x axis
	velocity.x = direction * current_speed 
	flip_sprites() # flip player's sprite with his direction
	
#region TIMERS
func stop_idle_timers(): # must be call on every movments states, stop all current timer
	exit_fall_timer.stop()
	exit_idle_timer.stop()
	exit_wait_timer.stop()
		
func _on_exit_idle_timeout() -> void: # called when idle timer is finished
	_set_state(STATE.SLEEP) # so set sleep state

func _on_exit_wait_timeout() -> void: # same for wait state
	_set_state(STATE.IDLE)
	
func _on_exit_fall_timeout() -> void: # called when this timer is finish, it lasts 1.5s, the time to play exit fall animation
	exit_fall = false # set exit fall to false
	play_animation("wait") # play wait animation after
	
func _on_jump_bug_timeout() -> void: # prevent bugs
	jumping = false
	
func _on_before_dash_timeout() -> void:
	before_dash_finish = true
#endregion
#endregion
