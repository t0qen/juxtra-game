extends Node2D
enum game_mode {
	LOCAL,
	MULTI
}
@onready var respawn_ball_point = $Spawn/RespawnPoint
@onready var player_2_spawn: Marker2D = $"Spawn/Player 2 spawn"
@onready var player_1_spawn: Marker2D = $"Spawn/Player 1 spawn"


var current_game_mode : game_mode
var ball = preload("res://scenes/ball.tscn")
var player = preload("res://scenes/player.tscn")
var current_ball = null
var player_1

func _ready() -> void:
	spawn_ball()
	if current_game_mode == game_mode.LOCAL:
		initalize_local()
	elif current_game_mode == game_mode.MULTI:
		initialize_multi()
	else:
		print("error no initialize game mode : no game mode")	
		
func _physics_process(delta: float) -> void:
	print(current_game_mode)
	
func spawn_ball():
	current_ball = ball.instantiate()
	current_ball.global_position = respawn_ball_point.global_position
	add_child(current_ball)

func _on_goal_2_area_entered(area: Area2D) -> void:
	if area.is_in_group("ball"):
		print("ball in right goal")
		current_ball.queue_free()
		spawn_ball()
		
func _on_goal_area_entered(area: Area2D) -> void:
	if area.is_in_group("ball"):
		print("ball in left goal")
		current_ball.queue_free()
		spawn_ball()

func set_game_mode(mode : game_mode):
	current_game_mode = mode
	
		
func initialize_local_players():
	print("initialize player 1")
	player_1 = player.instantiate()
	player_1.set_player_1()
	player_1.global_position = player_1_spawn.global_position
	add_child(player_1)
	
func initalize_local():
	initialize_local_players()

func initialize_multi():
	pass
