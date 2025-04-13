class_name Player
extends CharacterBody2D

#region VARIABLES  
@export_group("Global")
enum PLAYER {
	PLAYER_1,
	PLAYER_2
}
@export var current_player : PLAYER

#region MOVEMENTS
@export_group("Movements")
@export var SPEED : Dictionary = {"GROUND": 400, "AIR": 400, "DASH": 4000}
@export var PUSH_FORCE : Dictionary = {"SOFT": 25, "NORMAL": 150, "HARD": 300}
var current_push_force = PUSH_FORCE["NORMAL"]
@export var friction : float = 0.1
@export var acceleration : float = 0.25

# - RUN
@export_subgroup("Run")
@export var base_speed : int = 120 # base speed of player, on ground
@export var air_speed : int = 80 # it can change in air
var current_speed : float = base_speed # store the current speed

# - JUMP
@export_subgroup("Jump")
@export var jump_height : float = 150 # height of player's jump
@export var jump_time_to_peak : float = 0.25 # time to peak
@export var jump_time_to_fall : float = 0.15 # time to fall
@export var max_jumps : int = 6
var jumps_count : int = 0
@export var different_animation_jump : Array = [7, 8]

# jump math, will be calculated every frame
var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0 
var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)) * -1.0
	
# - DASH
@export_group("Dash")
@export var dash_speed : int = 1600 # speed of a dash
var is_able_to_dash : bool = true
var is_dashing : bool = false
#endregion

@export_group("Custom collisions")
# - CUTSOM COLLOSIONS
@export var push_force : float = 50
@export var push_speed_divid : float = 100
#region CAMERA
# - CAMERA
@export_group("Camera")
@export var enable_camera_effects : bool = true
@export_subgroup("Presets") # presets for camera shakes
# trauma : float = 0.5, changed_decay : float = 0.8, changed_max_offset : Vector2 = Vector2(50, 50), changed_max_roll : float = 0.1

enum SHAKE_PRESETS { # list all presets
	TOUCH_THE_BALL,
	JUMP,
	DASH
}
# presets proprieties

@export var EFFECT_TOUCH_THE_BALL = {
	"TRAUMA": 0.5,
	"DECAY": 0.8,
	"MAX_OFFSET": Vector2(50, 50),
	"MAX_ROLL": 0.1,
}
@export var EFFECT_JUMP = {
	"TRAUMA": 0.5,
	"DECAY": 0.8,
	"MAX_OFFSET": Vector2(50, 50),
	"MAX_ROLL": 0.1,
}
@export var EFFECT_DASH = {
	"TRAUMA": 0.5,
	"DECAY": 0.8,
	"MAX_OFFSET": Vector2(50, 50),
	"MAX_ROLL": 0.1,
}
	

#endregion

#region NODES
@export_group("Nodes")
# - TIMERS
@export_subgroup("Timers")
@export var exit_idle_timer : Timer # cooldown before switch to idle to sleep state
@export var exit_fall_timer : Timer # cooldown to play fall animation before enter state wait, same duration of the animation
@export var exit_wait_timer : Timer # cooldown before switch to wait to idle state 
@export var jump_bug_timer : Timer # little delay after apply jump to prevent bug
@export var dash_time_timer : Timer
@export var dash_delay_timer : Timer
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
	WAIT, # 6
	SLEEP, # 7
	DASH
}
var current_state : STATE = STATE.WAIT
# - OTHERS
var jumping : bool = false # bool to know if player is jumping
var exit_wait : bool = false # bool to store the end of timer
var exit_idle : bool = false # same for idle
var exit_fall : bool = false # same for fall
#endregion

#region INPUTS
var want_to_jump : bool = false # a bool to know if player want to jump
var direction : int = 0 # the direction of player, may a Vector2 ? consider jump as direction ? TODO
var want_to_dash : bool = false # same for dash 
var ball
#endregion
#endregion

#region GLOBAL FUNCTIONS
func _ready() -> void: 
	jump_velocity = ((2.0 * jump_height) / jump_time_to_peak) * -1.0 
	jump_gravity = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
	fall_gravity = ((-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)) * -1.0

func _physics_process(delta: float) -> void: 
	get_inputs() # get players inputs	
	can_dash()
	_update_state(delta) # update the behavior of current state
	
	move_and_slide()
	
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			if current_push_force == PUSH_FORCE["HARD"]:
				ball.get_child(0).play_anim_fast()
			c.get_collider().apply_central_impulse(-c.get_normal() * current_push_force)

func get_inputs(): # essential function to get player inputs, depend on wich player is 
	want_to_jump = Input.is_action_just_pressed("jump_" + str(current_player)) # bool to jump
	direction = Input.get_axis("move_left_" + str(current_player), "move_right_" + str(current_player)) # int to get axis : -1 / 0 / 1
	want_to_dash = Input.is_action_just_pressed("dash_" + str(current_player))
#endregion

#region STATE FUNCTIONS
func _set_state(new_state: STATE, restart : bool = false) -> void: # simple function to change player's state
	# the "force" parameter is here due to a bug with jumps
	# when player did jumps in air, _set_state(STATE.JUMP) is called multiple time without pass to any other state
	# so that player can multiple jump we call _set_state(STATE.JUMP, true) and we bypass the verification below 
	if !restart:
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
			is_able_to_dash = true
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
			play_animation("run")
			
		STATE.JUMP: 
			sprites.stop() # stop current jump animation to restart it
			exit_fall = false # reset exit fall
			stop_idle_timers() # we stop all idle timers, MAY NOT IMPORTANT ? TODO
			jumping = true # set this variable to true to prevent some bug on other functions TODO
			if jumps_count == 1:
				play_animation("jump_roll")
			else:
				play_animation("jump")
	
			camera_shake(SHAKE_PRESETS.JUMP)
			velocity.y = jump_velocity # apply jump
			jump_bug_timer.start() # this timer is here to prevent bug if STATE.JUMP begin to soon
			
		STATE.FLY: 
			exit_fall = false # reset exit fall
			stop_idle_timers() # we stop all idle timers, MAY NOT IMPORTANT ? TODO
			play_animation("fly")

		STATE.DASH:
			play_animation("dash")
			velocity = Vector2(0, 0)
			current_push_force = PUSH_FORCE["HARD"]
			dash_time_timer.start()

func _exit_state() -> void: # exit transition, nothing really important
	match current_state:
		STATE.DASH:
			is_able_to_dash = false
			dash_delay_timer.start()
			
		STATE.WAIT:
			pass
			
		STATE.IDLE: 
			pass
			
		STATE.RUN:
			pass
			
		STATE.JUMP:
			exit_fall = true # say that player just land,to play land animaton also called exit_fall 
			
		STATE.FLY: 
			exit_fall = true 

		STATE.SLEEP:
			pass
			
#endregion

#region UPDATE STATE
func _update_state(delta: float) -> void:  # every behavior of each states updated every physics process
	match current_state:
		STATE.JUMP: 
			move_horizontally(SPEED["AIR"]) # move on x axis with inputs
			can_jump() # jump action, come with inputs system
			if is_on_floor() && !jumping: # if player is on ground after his jump; var jumping is set to false after propulsion and after timer, without it, some bugs
				if direction:
					_set_state(STATE.RUN)
				else:
					_set_state(STATE.WAIT) # set wait; we play exit fall animation
			else:
				apply_gravity(delta) # else apply gravity
			
		STATE.DASH:
			velocity.x = direction * 2000
			can_jump()
			
		STATE.IDLE: 
			can_jump()
			can_run()
			can_fly()
				
		STATE.WAIT:
			#velocity.x = lerp(velocity.x, 0.0, friction)
			velocity = velocity.move_toward(Vector2.ZERO, friction)
			can_jump() 
			can_run()
			can_fly()

		STATE.SLEEP:
			can_jump() 
			can_run()
			can_fly()	

		STATE.RUN:
			move_horizontally(SPEED["GROUND"]) # move on x axis
			can_jump() # verify if player can jump
			if !direction: # if player doesn't move anymore 
				_set_state(STATE.WAIT)
			can_fly()
			
		STATE.FLY: 
			move_horizontally(SPEED["AIR"]) # move on x axis
			can_jump()  # verify if player can jump
			if is_on_floor(): # if player comes back on floor
				if direction:
					_set_state(STATE.RUN)
				else:
					_set_state(STATE.WAIT) # set wait; we play exit fall animation
			else:
				apply_gravity(delta) # else apply gravity
#endregionunlock_player
#endregion

#region OTHER
#region JUMP
func reset_jump(): # reset jump
	jumps_count = 0

func can_jump(): # func to verify if the player can jump
	if !want_to_jump: # first verify if player press jump button
		return false
	else:
		if jumps_count < max_jumps: 
			jumps_count += 1 # add 1 to jump count
			_set_state(STATE.JUMP, true) # go to _set_state func to know why there is a "true" in parameter
		else:
			return false

#endregion

	
func camera_shake(preset: SHAKE_PRESETS) -> void:
	if enable_camera_effects:
		camera.reset_trauma()
		match preset:
			SHAKE_PRESETS.TOUCH_THE_BALL:
				camera.start_shake(EFFECT_TOUCH_THE_BALL["TRAUMA"], EFFECT_TOUCH_THE_BALL["DECAY"], EFFECT_TOUCH_THE_BALL["MAX_OFFSET"], EFFECT_TOUCH_THE_BALL["MAX_ROLL"])
			SHAKE_PRESETS.JUMP:
				camera.start_shake(EFFECT_JUMP["TRAUMA"], EFFECT_JUMP["DECAY"], EFFECT_JUMP["MAX_OFFSET"], EFFECT_JUMP["MAX_ROLL"])
			SHAKE_PRESETS.DASH:
				camera.start_shake(EFFECT_DASH["TRAUMA"], EFFECT_DASH["DECAY"], EFFECT_DASH["MAX_OFFSET"], EFFECT_DASH["MAX_ROLL"])

func apply_gravity(delta : float) -> void: # apply gravity
	var current_gravity : float
	if velocity.y < 0.0:
		current_gravity = jump_gravity
	else:
		current_gravity = fall_gravity
	velocity.y += current_gravity * delta

func can_dash() -> void:
	if !want_to_dash:
		return
	else:
		if is_able_to_dash:
			_set_state(STATE.DASH)
		else:
			return
			
func can_run() -> void:
	if direction: # if left or right is pressed, start walking
		_set_state(STATE.RUN)
		
func can_fly() -> void:
	if !is_on_floor() && !jumping: # if not on floor, fall down and fly (TODO !jumping)
		_set_state(STATE.FLY)

func move_horizontally(speed: float = 400, current_acceleration: float = acceleration): # simple func to move player on x axis
	#velocity.x = lerp(velocity.x, direction * speed, acceleration)
	velocity.x = move_toward(velocity.x, direction * speed, current_acceleration)
	if velocity.x > 0: 
		sprites.flip_h = false
	elif velocity.x < 0:
		sprites.flip_h = true
	
func play_animation(animation: String) -> void: # play animation
	if current_player == PLAYER.PLAYER_1:
		print(animation + "_" + str(current_player))
	sprites.play(animation + "_" + str(current_player))
	#if current_player == 1: # aniamtions with player's 1 skin
		#match animation:
			#"jump":
				#sprites.play("jump_1")
			#"run":
				#sprites.play("run_1")
			#"idle":
				#sprites.play("idle_1")
			#"fly":
				#sprites.play("fly_1")
			#"wait":
				#sprites.play("wait_1")
			#"sleep":
				#sprites.play("sleep_1")
			#"exit_fall":
				#sprites.play("exit_fall_1")
			#"jump_roll":
				#sprites.play("jump_roll_1")
				#
	#elif current_player == 2: # aniamtions with player's 2 skin
		#match animation: 
			#"jump":
				#sprites.play("jump_2")
			#"run":
				#sprites.play("run_2")
			#"idle":
				#sprites.play("idle_2")
			#"fly":
				#sprites.play("fly_2")	
			#"wait":
				#sprites.play("wait_2")
			#"sleep":
				#sprites.play("sleep_2")
			#"exit_fall":
				#sprites.play("exit_fall_2")
			#"jump_roll":velocity = velocity.move_toward(Vector2.ZERO, friction)
				#sprites.play("jump_roll_2")
			
#region SIGNALS
# - TIMERS
func stop_idle_timers() -> void: # must be call on every movments states, stop all current timer
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
	
func _on_dash_time_timeout() -> void:
	velocity.x = 0
	current_push_force = PUSH_FORCE["NORMAL"]
	if is_on_floor():
		_set_state(STATE.WAIT)
	else:
		_set_state(STATE.FLY)

func _on_dash_delay_timeout() -> void:
	is_able_to_dash = true
	
# - OTHERS
func _on_area_area_entered(area: Area2D) -> void: # start a camera shake if player touch the ball
	if area.is_in_group("ball"): # if player touchs the ball
		print("touch ball")
		play_animation("touche_ball")
		camera_shake(SHAKE_PRESETS.TOUCH_THE_BALL)
		var ball = area.get_parent() # get the ball node (rigid body)
		# modify it groups to know wich player has touch it for the last time
		if current_player == PLAYER.PLAYER_1:
			ball.add_to_group("player_1") 
			ball.remove_from_group("player_2")
		elif current_player == PLAYER.PLAYER_2:
			ball.add_to_group("player_2") 
			ball.remove_from_group("player_1")
#endregion
#endregion
