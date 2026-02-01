extends Area2D


func _on_body_entered(body: Node2D) -> void:
	PlayerManager.shards_count += 1
	PlayerManager.emit_signal("shards_count_changed")
	print(PlayerManager.shards_count, " shards")
	queue_free()
