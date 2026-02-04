extends Area2D


func _on_body_entered(_body: Node2D) -> void:
	PlayerManager.emit_signal("player_died")
	print("player died from fall zone")
