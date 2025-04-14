extends RigidBody2D
var is_able = true

func _physics_process(delta: float) -> void:
	if linear_velocity.x > 0: 
		$sprites.flip_h = true
	elif linear_velocity.x < 0:
		$sprites.flip_h = false
	#if abs(linear_velocity.x) > 50:
		#if is_able:
			#is_able = false
			#$sprites.play("fast")
			#await get_tree().create_timer(4.0).timeout
			#is_able = true
	#else:
		#$sprites.play("default")
	
	#print(get_groups())

func play_anim_fast():
	$sprites.play("fast")
