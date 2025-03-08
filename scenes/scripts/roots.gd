extends Node

var local_multi_map = preload("res://scenes/local_multi.tscn")
var current_map

enum global_game_mode {
	LOCAL,
	MULTI,
	SOLO
}

func _ready() -> void:
	begin_local_multi(global_game_mode.LOCAL)

func begin_local_multi(mode : global_game_mode):
	current_map = local_multi_map.instantiate()
	current_map.global_position = Vector2(0, 0)
	current_map.set_game_mode(global_game_mode.LOCAL)
	add_child(current_map)
