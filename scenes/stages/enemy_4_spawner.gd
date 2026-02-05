extends Node2D

@onready var minions: Node2D = get_tree().current_scene.find_child("Minions", true, false)
@onready var boss: CharacterBody2D = $"../../EnemiesContainer/Boss/Enemy4"

func _ready() -> void:
	# Wait until the end of the frame to ensure the Boss has joined its group
	_connect_to_boss.call_deferred()

func _connect_to_boss() -> void:
	if boss:
		if boss.has_signal("summon"):
			# Ensure we don't connect twice if this is called multiple times
			if not boss.summon.is_connected(_on_boss_summon):
				boss.summon.connect(_on_boss_summon)
				print(">>> SPAWNER: Summon signal successfully connected!")
		else:
			push_error(">>> SPAWNER: Found Boss, but it has no 'summon' signal!")
	else:
		push_warning(">>> SPAWNER: Boss not found in group 'EnemiesContainer/Boss'. Retrying in 1 second...")
		# Optional: Retry if the boss is spawned dynamically later
		await get_tree().create_timer(1.0).timeout
		_connect_to_boss()
		

func _on_boss_summon(enemy_scene: PackedScene, count: int, interval: float, pos: Vector2) -> void:
	if not enemy_scene:
		push_error("Spawner: No enemy scene provided!")
		return
		
	# Fallback if find_child failed to find the Minions node
	var target_parent = minions if minions else get_parent()
		
	for i in range(count):
		var new_enemy = enemy_scene.instantiate()
		
		# Meticulously adding as a child of the Minions container
		target_parent.add_child(new_enemy)
		new_enemy.global_position = pos
		
		# Randomized offset to prevent sprite stacking
		new_enemy.global_position.x += randf_range(-30, 30)
		
		print(new_enemy, " spawned")
		if interval > 0:
			await get_tree().create_timer(interval).timeout
