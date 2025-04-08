class_name Player
extends CharacterBody2D

#region VARIABLES  
@export_group("Global")
@export var current_player : int  # wich player this script is for, can be changed by other script via func
var player_set : bool = false # a var that is true if current_player is set, player's script don't start if this var isn't true

#region MOVEMENTS
@export_group("Movements")
@export var gravity : int = 10000000 # default gravity 

# - RUN
@export_subgroup("Run")
@export var base_speed : int = 120 # base speed of player, on ground
@export var air_speed : int = 80 # it can change in air
var current_speed : float = base_speed # store the current speed

# - JUMP
@export_subgroup("Jump")
@export var jump_height : float = 50.0 # height of player's jump
@export var jump_time_to_peak : float = 0.25 # time to peak
@export var jump_time_to_fall : float = 0.15 # time to fall

# cutsom per jumps forces
@export_subgroup("Jump forces")
@export var jump_1_force : float = 1.5
@export var jump_2_force : float = 2.0
@export var jump_3_force : float = 1.75
@export var jump_4_force : float = 1.25
@export var jump_5_force : float = 1.0

enum JUMP { # all jumps
	NO,
	JUMP,
	JUMP_2,
	JUMP_3,
	JUMP_4,
	JUMP_5
}
var current_jump = JUMP.JUMP # store the current what jump player is actually perform

# jump math, will be calculated every frame
var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0 
var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)) * -1.0
	
# - DASH
@export_group("Dash")
@export var dash_speed : int = 1600 # speed of a dash
#endregion

@export_group("Custom collisions")
# - CUTSOM COLLOSIONS
@export var push_force : float = 50
@export var push_speed_divid : float = 100

#region CAMERA
# - CAMERA
@export_group("Camera")
@export var enable_camera_effects : bool = true
@export_subgroup("Presets")
# TODO

#endregion

#region NODES
@export_group("Nodes")
# - TIMERS
@export_subgroup("Timers")
@export var exit_idle_timer : Timer # cooldown before switch to idle to sleep state
@export var exit_fall_timer : Timer # cooldown to play fall animation before enter state wait, same duration of the animation
@export var exit_wait_timer : Timer # cooldown before switch to wait to idle state 
@export var jump_bug_timer : Timer # little delay after apply jump to prevent bug

# - OTHERS
@export_subgroup("Others")
@export var camera : Camera2D # store camera
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
	JUMP_4, # 8
	JUMP_5, # 9
	LOCKED # 10 "stop" state is a state where player can't do any movements
}
@export var current_state : STATE = STATE.WAIT # where the current state of player will be stored, can stored to first state

# - OTHERS
var jumping : bool = false # bool to know if player is jumping
var exit_wait : bool = false # bool to store the end of timer
var exit_idle : bool = false # same for idle
var exit_fall : bool = false # same for fall
var dash_levitation : bool = false
var before_dash_finish : bool = false
#endregion

#region INPUTS
var want_to_jump : bool = false # a bool to know if player want to jump
var direction : int = 0 # the direction of player, may a Vector2 ? consider jump as direction ? TODO
var want_to_dash : bool = false # same for dash 
var propulsion_down : bool = false # a bool to know if player want to be propulsed down

#endregion
#endregion

#region GLOBAL FUNCTIONS
func _ready() -> void: 
	if current_player == 1:
		pass # nothing to do for now
	else:
		sprites.flip_h = true # flip player 2 sprite 
		

func _physics_process(delta: float) -> void: # each frame we call this function to update player state, for example if he's not on ground we set his state to fall, etc
	#Engine.time_scale = 0.1
	
	# jump maths, calculated every frame, for debug only
	jump_velocity = ((2.0 * jump_height) / jump_time_to_peak) * -1.0 
	jump_gravity = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
	fall_gravity = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)) * -1.0
	
	get_inputs() # get players inputs	
	_update_state(delta) # update the behavior of current state

	move_and_slide()
	
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			print("NOMRAL : ", -c.get_normal() * push_force)
			print("AFTER : ", -c.get_normal() * (push_force * (current_speed / push_speed_divid)))
			c.get_collider().apply_central_impulse(-c.get_normal() * (push_force * (current_speed / push_speed_divid)))

func get_inputs(): # essential function to get player inputs, depend on wich player is 
	if current_player == 1: # if current player is 1 get input with player's 1 inputs
		want_to_jump = Input.is_action_just_pressed("jump_1") # bool to jump
		direction = Input.get_axis("move_left_1", "move_right_1") # int to get axis : -1 / 0 / 1
		want_to_dash = Input.is_action_just_pressed("dash_1")
	elif current_player == 2:
		want_to_jump = Input.is_action_just_pressed("jump_2") # bool to jump
		direction = Input.get_axis("move_left_2", "move_right_2") # int to get axis : -1 / 0 / 1
		want_to_dash = Input.is_action_just_pressed("dash_2")
	else:
		print("Error l. 147 : Unknow player")
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
			reset_jump() # reset jumps, because if state is wait, it means that player is on ground
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
			perform_jump(jump_1_force)
			
		STATE.JUMP_2: 
			sprites.stop() # stop current jump animation to restart it
			current_jump = JUMP.JUMP_2
			perform_jump(jump_2_force)
			
		STATE.JUMP_3: 
			sprites.stop() # stop current jump animation to restart it
			current_jump = JUMP.JUMP_3
			perform_jump(jump_3_force)
		
		STATE.JUMP_4:
			sprites.stop() # stop current jump animation to restart it
			current_jump = JUMP.JUMP_4
			perform_jump(jump_4_force)
			
		STATE.JUMP_5:
			sprites.stop() # stop current jump animation to restart it
			current_jump = JUMP.JUMP_5
			perform_jump(jump_5_force)
			
		STATE.FLY: 
			exit_fall = false # reset exit fall
			stop_idle_timers() # we stop all idle timers, MAY NOT IMPORTANT ? TODO
			current_speed = air_speed # set air speed
			play_animation("fly")
			
		STATE.LOCKED:
			play_animation("wait") # play wait animation to prevent animation bugs

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
			
		STATE.JUMP_2:
			exit_fall = true
			
		STATE.JUMP_3:
			exit_fall = true
		
		STATE.JUMP_4:
			exit_fall = true
			
		STATE.JUMP_5:
			exit_fall = true
			
		STATE.FLY: 
			exit_fall = true 

		STATE.SLEEP:
			pass
			
		STATE.LOCKED:
			pass
#endregion

#region UPDATE STATE
func _update_state(delta: float) -> void:  # every behavior of each states updated every physics process
	match current_state:
		STATE.JUMP: 
			jump_update(delta) # update jump
		
		STATE.JUMP_2: 
			jump_update(delta) # update jump
			
		STATE.JUMP_3: 
			jump_update(delta) # update jump
				
		STATE.JUMP_4: 
			jump_update(delta) # update jump
		
		STATE.JUMP_5: 
			jump_update(delta) # update jump
			
		STATE.IDLE: 
			can_jump() # verify if player can jump
			if direction: # if left or right is pressed, start walking
				_set_state(STATE.RUN)
			
			if !is_on_floor() && !jumping: # if not on floor, fall down and fly TODO
				
				_set_state(STATE.FLY)
				
		STATE.WAIT:
			can_jump() # verify if player can jump
			if direction: # ef left or right is pressed, start walking
				_set_state(STATE.RUN)
			
			if !is_on_floor() && !jumping: # if not on floor, fall down and fly (TODO !jumping)
				_set_state(STATE.FLY)

		STATE.SLEEP:
			can_jump() # verify if player can jump
			if direction: # if left or right is pressed, start walking
				_set_state(STATE.RUN)
				
			if !is_on_floor() && !jumping: # if not on floor, fall down TODO
				_set_state(STATE.FLY)		

		STATE.RUN:
			x_move() # move on x axis
			can_jump() # verify if player can jump
			if !direction: # if player doesn't move anymore 
				_set_state(STATE.WAIT)

			if !is_on_floor() && !jumping: #  # if not on floor, fall down TODO
				_set_state(STATE.FLY)
			
		STATE.FLY: 
			x_move() # move on x axis
			can_jump()  # verify if player can jump
			if is_on_floor(): # if player comes back on floor
				if direction: # if he want to move
					_set_state(STATE.RUN)
				else: # else
					_set_state(STATE.WAIT)
			else:
				apply_gravity(get_current_gravity(), delta) # else apply gravity

		STATE.LOCKED:
			print("player is locked !")
#endregion
#endregion

#region OTHER
#region JUMP

func reset_jump(): # reset jump
	current_jump = JUMP.NO

func perform_jump(coef: float): # func to do a jump
	exit_fall = false # reset exit fall
	stop_idle_timers() # we stop all idle timers, MAY NOT IMPORTANT ? TODO
	current_speed = air_speed # set in air speed
	jumping = true # set this variable to true to prevent some bug on other functions TODO
	play_animation("jump")
	velocity.y = jump_velocity * coef # apply jump
	jump_bug_timer.start() # this timer is here to prevent bug if STATE.JUMP begin to soon
	
func jump_update(delta): # basic func wich control jump in state update 
	x_move() # move on x axis with inputs
	can_jump() # jump action, come with inputs system
	if is_on_floor() && !jumping: # if player is on ground after his jump; var jumping is set to false after propulsion and after timer, without it, some bugs
		if direction: # if he want to run
			_set_state(STATE.RUN) # run
		else: # else
			_set_state(STATE.WAIT) # set wait; we play exit fall animation
			
	else:
		apply_gravity(get_current_gravity(), delta) # else apply gravity

func can_jump(): # func to verify if the player can jump
	if !want_to_jump: # first verify if player press jump button
		return false
	else: # if true so :
		if current_jump == JUMP.JUMP_5: # if player has already did 5 jumps, he can't do an other jump
			return false
		else:
			# set jump depending on wich current jump 
			if current_jump == JUMP.NO:
				_set_state(STATE.JUMP)
				
			elif current_jump == JUMP.JUMP:
				_set_state(STATE.JUMP_2)
				
			elif current_jump == JUMP.JUMP_2:
				_set_state(STATE.JUMP_3)
				
			elif current_jump == JUMP.JUMP_3:
				_set_state(STATE.JUMP_4)
				
			elif current_jump == JUMP.JUMP_4:
				_set_state(STATE.JUMP_5)
				
			else:
				print("error line 364")			
#endregion
func get_current_gravity() -> float: # return gravity
	return jump_gravity if velocity.y < 0.0 else fall_gravity # if player's velocity < 0, it means that player is jumping so return jump gravity

func apply_gravity(current_gravity : float, delta : float ): # apply gravity
	velocity.y += current_gravity * delta	

func lock_player(): # func called generaly from different scripts to prevent player moving
	_set_state(STATE.LOCKED)
	
func unlock_player(): # func to unlock player after lock_player()
	_set_state(STATE.WAIT)
	
func set_player_1(): # we can choose for player 1 or player 2 when multiplayer, so keyboard will change
	print("PLAYER 1 initialized")
	current_player = 1
	player_set = true
	
func set_player_2(): # same for player 2
	print("PLAYER 2 initialized")
	current_player = 2
	player_set = true

func flip_sprites(): # simple func to automaticlly flip player sprite with the player's x velocity
	if velocity.x > 0: 
		sprites.flip_h = false
		
	elif velocity.x < 0:
		sprites.flip_h = true

func x_move(): # simple func to move player on x axis
	velocity.x = direction * current_speed 
	flip_sprites() # flip player's sprite with his direction
	
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

func _push_away_rigid_bodies(): # cutsom collision script, more customizable, from https://gist.github.com/majikayogames/cf013c3091e9a313e322889332eca109
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			var push_dir = -c.get_normal()
			# How much velocity the object needs to increase to match player velocity in the push direction
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			# Only count velocity towards push dir, away from character
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			# Objects with more mass than us should be harder to push. But doesn't really make sense to push faster than we are going
			const MY_APPROX_MASS_KG = 50.0
			var mass_ratio = min(1., MY_APPROX_MASS_KG / c.get_collider().mass)
			# Optional add: Don't push object at all if it's 4x heavier or more
			if mass_ratio < 0.25:
				continue
			# Don't push object from above/below
			push_dir.y = 0
			# 5.0 is a magic number, adjust to your needs
			var push_force = mass_ratio * 5.0
			c.get_collider().apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, c.get_position() - c.get_collider().global_position)
			
#region SIGNALS
# - TIMERS
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

# - OTHERS
func _on_area_area_entered(area: Area2D) -> void: # start a camera shake if player touch the ball
	pass
#endregion
#endregion
