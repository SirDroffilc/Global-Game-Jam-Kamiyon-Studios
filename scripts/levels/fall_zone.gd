extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		PlayerManager.emit_signal("player_died")
		print("player died from fall zone")
	elif body.is_in_group("Enemy"):
		body.queue_free()
		print(body, " died from fall zone")
