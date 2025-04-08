extends Node2D

var multiplayer_map = preload("res://data/scenes/multiplayer_level.tscn") # preload the multiplayer map in this variabble
var current_map = null # store the current map, so depends on game mode

enum GLOBAL_GAME_MODE { # store all game mode 
	MULTI, # multi map
	SOLO # solo map
}

var current_game_mode = GLOBAL_GAME_MODE.MULTI # store the current game mode

func _ready() -> void:
	# since the menu isn't created, we begin directly with the multiplayer map in local game mode
	if current_game_mode == GLOBAL_GAME_MODE.MULTI:
		begin_multiplayer(current_game_mode) # calls the func with GLOBAL_GAME_MODE.LOCAL

func begin_multiplayer(game_mode : GLOBAL_GAME_MODE): # func to initialize multiplayer map with specific game mode
	current_map = multiplayer_map.instantiate() # "spawn" the scene
	current_map.global_position = Vector2(0, 0) # set it position to (0, 0)
	add_child(current_map) # add scene to root so we can see it
