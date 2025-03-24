# A little bit of that code from Claude 3.7
extends RigidBody2D

@export var max_speed: float = 800.0  # Vitesse maximale
@export var propulsion_force: float = 200.0  # Force de propulsion en l'air
@export var stop_threshold: float = 50  # Seuil pour considérer que le corps est à l'arrêt
var is_on_area_propulsion = false

func _physics_process(delta: float) -> void:
	if abs(linear_velocity.y) > max_speed:
		
		linear_velocity = linear_velocity.normalized() * max_speed

		
	if linear_velocity.length() < stop_threshold && is_on_area_propulsion:
		print("TRUUUUUUUUUUE")
		apply_central_impulse(Vector2.UP * propulsion_force)
	

func _on_ball_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("propulsion"):
		is_on_area_propulsion = true


func _on_ball_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("propulsion"):
		is_on_area_propulsion = false
