extends Node2D
enum game_mode {
	LOCAL,
	MULTI
}
@export var tab_timer : Timer
var tab_timer_finished : bool = false
@export var score_timer : Timer
var score_timer_finished : bool = false
@export var intro_text_timer : Timer

@onready var respawn_ball_point = $Spawn/RespawnPoint
@onready var player_2_spawn: Marker2D = $"Spawn/Player 2 spawn"
@onready var player_1_spawn: Marker2D = $"Spawn/Player 1 spawn"
@onready var camera_spawn: Marker2D = $Spawn/Camera_spawn
@onready var player_1_score_text: Label = $UI/Player1Score
@onready var player_2_score_text: Label = $UI/Player2Score
@onready var intro_text: Label = $UI/Intro_text

# Goal camera effect
@export var goal_intensity : float = 0.7
@export var goal_duration : float = 1.5
@export var goal_direction : Vector2 = Vector2(1, 0)

var current_game_mode : game_mode
var ball = preload("res://scenes/ball.tscn")
var player = preload("res://scenes/player.tscn")
var camera = preload("res://scenes/camera.tscn")
var current_ball = null
var current_camera = null
var player_1
var player_2
var player_1_score : int = 0
var player_2_score : int = 0

func _ready() -> void:
	hide_score()
	
	spawn_ball()
	spawn_camera()
	if current_game_mode == game_mode.LOCAL:
		initalize_local()
	elif current_game_mode == game_mode.MULTI:
		initialize_multi()
	else:
		print("error no initialize game mode : no game mode")	
	
	intro_text_timer.start()
	player_1.player_1_text.hide()
	player_2.player_2_text.hide()
	
func _process(delta: float) -> void:
	update_score()
	if Input.is_action_just_pressed("tab"):
		tab_timer_finished = false
		player_1.player_1_text.show()
		player_2.player_2_text.show()
		tab_timer.start()
	
	if tab_timer_finished:
		player_1_score_text.hide()
		player_1.player_1_text.hide()
		player_2.player_2_text.hide()
		
func spawn_camera():
	current_camera = camera.instantiate()
	current_camera.global_position = camera_spawn.global_position
	add_child(current_camera)
	
	
func spawn_ball():
	current_ball = ball.instantiate()
	current_ball.global_position = respawn_ball_point.global_position
	add_child(current_ball)

func _on_goal_2_area_entered(area: Area2D) -> void:
	if area.is_in_group("ball"):
		print("ball in right goal")
		current_ball.queue_free()
		respawn_players()
		spawn_ball()
		player_1.camera_shake(goal_intensity, goal_duration, goal_direction)
		player_1_score = player_1_score+1
		show_score()
		score_timer.start()
		
func _on_goal_area_entered(area: Area2D) -> void:
	if area.is_in_group("ball"):
		print("ball in left goal")
		current_ball.queue_free()
		respawn_players()
		spawn_ball()
		player_1.camera_shake(goal_intensity, goal_duration, goal_direction)
		player_2_score = player_2_score+1
		show_score()
		score_timer.start()

func set_game_mode(mode : game_mode):
	current_game_mode = mode
	
func update_score():
	player_1_score_text.text = str(player_1_score)
	player_2_score_text.text = str(player_2_score)
		
func show_score():
	player_1_score_text.show()
	player_2_score_text.show()
	
func hide_score():
	player_1_score_text.hide()
	player_2_score_text.hide()
	
func initialize_local_players():
	print("initialize player 1")
	player_1 = player.instantiate()
	player_1.set_camera(current_camera)
	player_1.set_player_1()
	player_1.global_position = player_1_spawn.global_position
	add_child(player_1)
	
	print("initialize player 2")
	player_2 = player.instantiate()
	player_2.set_camera(current_camera)
	player_2.set_player_2()
	player_2.global_position = player_2_spawn.global_position
	add_child(player_2)
	
func initalize_local():
	initialize_local_players()

func initialize_multi():
	pass

func respawn_players():
	player_1.global_position = player_1_spawn.global_position
	player_1.sprites.flip_h = false
	player_2.global_position = player_2_spawn.global_position
	player_2.sprites.flip_h = true


func _on_tab_timer_timeout() -> void:
	tab_timer_finished = true

func _on_show_score_timeout() -> void:
	hide_score()

func _on_text_intro_timeout() -> void:
	intro_text.hide()
