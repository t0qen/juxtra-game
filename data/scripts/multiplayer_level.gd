extends Node2D

#region VARIABLES
# - GLOBAL
enum PLAYERS { # list players, will be useful for scores
	PLAYER_1, 
	PLAYER_2, 
	NOBODY
}

enum GOALS {  # same, but for goal
	GOAL_1, 
	GOAL_2
	}
	
enum WAY_TO_SCORE { # how player has scored
	VOLUNTARY,
	UNVOLUNTARY
	}

# - UI
@export var enable_ui : bool = false # disable/enable ui for debug

# - LIGHT EFFECTS
@export var enable_light_effects : bool = false # disbale/enable light effects

# - NODES
@export_group("Nodes")
# timers
@export_subgroup("Timers")
@export var after_goal_timer : Timer
@export var before_after_goal_timer : Timer # a timer for the time just before "after_goal_timer"
# lights
@export_subgroup("Lights")
# respawn points
@export_subgroup("Markers")
@export var player_1_spawn : Marker2D 
@export var player_2_spawn : Marker2D 
@export var ball_spawn : Marker2D 
# players
@export_subgroup("Players")
@export var player_1 : CharacterBody2D
@export var player_2 : CharacterBody2D
# others
@export_subgroup("Others")
@export var camera : Camera2D

var ball = preload("res://data/scenes/ball.tscn") # preload ball scene so we can queue_free() it 
var current_ball = null # store preloaded ball

# - CAMERA EFFECTS
@export_group("Camera shakes presets") # some presets for camera shakes, like in player.gd

@export var EFFECT_SCORES = {
	"TRAUMA": 0.5,
	"DECAY": 0.8,
	"MAX_OFFSET": Vector2(50, 50),
	"MAX_ROLL": 0.1,
}

@export var EFFECT_RESTARTING = {
	"TRAUMA": 0.5,
	"DECAY": 0.8,
	"MAX_OFFSET": Vector2(50, 50),
	"MAX_ROLL": 0.1,
}

# Goals
@export_subgroup("Goal")
@export var camera_goal_intensity : float = 0.7
@export var camera_goal_duration : float = 1.5
@export var camera_goal_direction : Vector2 = Vector2(1, 0)

# - SCORES
var player_1_score : int = 0 # store player 1 score
var player_2_score : int = 0 # same for player 2
var current_winner_player = PLAYERS # wich players has really win the game, depends on wich player has touch the ball for the last time
var last_touch_ball = PLAYERS # wich player s has touch the ball for the last time
var current_goal = GOALS # in wich goal the ball is 
var current_way_to_score = WAY_TO_SCORE # how player has scored
#endregion

func _ready() -> void:
	if !enable_ui: # hide ui on startup if ui is disabled
		$UI.hide()
	else: # else show texts, etc
		pass
		
	if !enable_light_effects: # hide lights on startup if light effects are disabled
		$light_effects.hide()

	spawn_ball()

func _process(delta: float) -> void:
	pass
	
func spawn_ball(): # instanciate ball scene
	current_ball = ball.instantiate()
	current_ball.global_position = ball_spawn.global_position
	add_child(current_ball)
	
func respawn_players():
	player_1.global_position = player_1_spawn.global_position 
	player_2.global_position = player_2_spawn.global_position 
	
func update_score():
	#player_1_score_text.text = str(player_1_score) TODO
	#player_2_score_text.text = str(player_2_score) TODO
	pass	
	
# - GOALS / SCORES
func _on_goal_1_area_entered(area: Area2D) -> void: # player 2 scores
	if area.is_in_group("ball"): # verify if it's the ball that is in the goal
		manage_scores()
		current_ball.queue_free() # delete the current ball
		before_after_goal_timer.start()
		current_goal = GOALS.GOAL_1
		# print GOAL 
		
func _on_goal_2_area_entered(area: Area2D) -> void: # player 1 scores
	if area.is_in_group("ball"): # verify if it's the ball that is in the goal
		manage_scores()
		current_ball.queue_free() # delete the current ball
		before_after_goal_timer.start()
		current_goal = GOALS.GOAL_2
		# print GOAL 

func manage_scores():
	# check wich player touch the balls for the last time
	if current_ball.is_in_group("player_1"):
		last_touch_ball = PLAYERS.PLAYER_1
	elif current_ball.is_in_group("player_2"):
		last_touch_ball = PLAYERS.PLAYER_2
	else:
		last_touch_ball = PLAYERS.NOBODY # this will probably never be used because ball can't go to a goal without a player touch
	
	# determine wich player wins
	if last_touch_ball == PLAYERS.PLAYER_1 && current_goal == GOALS.GOAL_2: # player 1 has scored in the enemy goal, +4 for him
		current_winner_player = PLAYERS.PLAYER_1
		current_way_to_score = WAY_TO_SCORE.VOLUNTARY
		player_1_score += 4
	elif last_touch_ball == PLAYERS.PLAYER_2 && current_goal == GOALS.GOAL_1: # player 2 has scored in the enemy goal, +4 for him
		current_winner_player = PLAYERS.PLAYER_2
		current_way_to_score = WAY_TO_SCORE.VOLUNTARY
		player_2_score += 4
	elif last_touch_ball == PLAYERS.PLAYER_1 && current_goal == GOALS.GOAL_1: # player 1 has scored in him own goal
		current_winner_player = PLAYERS.PLAYER_2
		current_way_to_score = WAY_TO_SCORE.UNVOLUNTARY
		player_2_score += 1
	elif last_touch_ball == PLAYERS.PLAYER_2 && current_goal == GOALS.GOAL_2: # player 1 has scored in him own goal
		current_winner_player = PLAYERS.PLAYER_1
		current_way_to_score = WAY_TO_SCORE.UNVOLUNTARY
		player_1_score += 1
	
	# TODO
	
# - TIMERS
func _on_after_goal_timeout() -> void:
	# unlock players
	respawn_players()
	player_1.show()
	player_2.show()
	spawn_ball()

func _on_before_after_goal_timeout() -> void:
	# lock players
	player_1.hide()
	player_2.hide()
	after_goal_timer.start() # start the a timer after restarting the game 
