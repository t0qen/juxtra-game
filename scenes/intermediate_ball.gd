extends Node2D

@onready var root_ball: RigidBody2D = $"Root ball"

func ball_apply_central_impulse(force: int):
	root_ball.apply_central_impulse(Vector2(0, force)) 
