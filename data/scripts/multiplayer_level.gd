extends Node2D

#region VARIABLES

# - GAME MODE
enum GAME_MODE { # differents game mode of this map
	LOCAL, 
	ONLINE
}
var current_game_mode : GAME_MODE # store the current game mode wich is set by root.gd

# - UI
@export var enable_ui : bool = false # disable/enable ui for debug

# - LIGHT EFFECTS
@export var enable_light_effects : bool = false # disbale/enable light effects

# - NODES
@export_group("Nodes")
# timers
@export_subgroup("Timers")
@export var after_goal_timer : Timer
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
@export_group("Camera effects")
# Goals
@export_subgroup("Goal")
@export var camera_goal_intensity : float = 0.7
@export var camera_goal_duration : float = 1.5
@export var camera_goal_direction : Vector2 = Vector2(1, 0)

# - SCORES
var player_1_score : int = 0 # store player 1 score
var player_2_score : int = 0 # same for player 2
#endregion

func _ready() -> void:
	if !enable_ui: # hide ui on startup if ui is disabled
		$UI.hide()
	else: # else show texts, etc
		pass
		
	if !enable_light_effects: # hide lights on startup if light effects are disabled
		$light_effects.hide()

	spawn_ball()

	if current_game_mode == GAME_MODE.LOCAL:
		initalize_local()
	elif current_game_mode == GAME_MODE.ONLINE:
		initialize_online()
	else:
		print("error on initialize game mode : no game mode")	
		
func _process(delta: float) -> void:
	pass
	
# - GAME MODES / INITIALISATIONS / INSTANCIATE
func set_game_mode(game_mode : GAME_MODE):  # func called by root.gd to set the game mode
	current_game_mode = game_mode

func initalize_local():
	pass
	
func initialize_online(): # nothing there, come with the online multiplayer
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
		player_2_score = player_2_score + 1
		current_ball.queue_free() # delete the current ball
		# lock players
		player_1.lock_player() 
		player_2.lock_player()
		respawn_players()
		after_goal_timer.start() # start the a timer after restarting the game 
		
		
func _on_goal_2_area_entered(area: Area2D) -> void: # player 1 scores
	if area.is_in_group("ball"): # verify if it's the ball that is in the goal
		player_1_score = player_1_score + 1
		current_ball.queue_free() # delete the current ball
		# lock players
		player_1.lock_player()
		player_2.lock_player()
		respawn_players()
		after_goal_timer.start() # start the a timer after restarting the game 
		


# - TIMERS
func _on_after_goal_timeout() -> void:
	# unlock players
	player_1.unlock_player()
	player_2.unlock_player()
	spawn_ball()
