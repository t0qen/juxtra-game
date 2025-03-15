extends Area2D


func _on_area_entered(area: Area2D) -> void:
	#print(area)
	if area.is_in_group("ball"):
		print("true")
