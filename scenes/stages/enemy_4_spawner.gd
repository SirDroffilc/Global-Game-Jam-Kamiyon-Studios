extends Node2D

# --- Meticulous Scene References ---
@export var boss_scene: PackedScene = preload("res://scenes/enemies/enemy_4.tscn")
@onready var minions: Node2D = get_tree().current_scene.find_child("Minions", true, false)
@onready var boss_container: Node2D = $"../../EnemiesContainer/Boss"

# We use a standard variable for the live boss instance
var current_boss: CharacterBody2D
var initial_boss_pos: Vector2

var player: Player = null

var is_resetting: bool = false

func _ready() -> void:
	# Initial assignment based on the path provided
	player = get_tree().get_first_node_in_group("Player")
	current_boss = get_node_or_null("../../EnemiesContainer/Boss/Enemy4")
	if current_boss:
		initial_boss_pos = current_boss.global_position
	
	_connect_to_boss.call_deferred()
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	if is_resetting:
		return
	is_resetting = true
	print(">>> SPAWNER: Resetting boss fight...")
	
	await get_tree().create_timer(1.0).timeout
	# 1. Clear all minions
	if minions:
		for minion in minions.get_children():
			minion.queue_free()
	
	for ghost in get_tree().get_nodes_in_group("Ghosts"):
		ghost.queue_free()
	
	# 2. Remove the current boss
	if current_boss and is_instance_valid(current_boss):
		current_boss.queue_free()
	
	# 3. Respawn the boss
	_respawn_boss.call_deferred()

func _respawn_boss() -> void:
	if not boss_scene:
		push_error("Spawner: Boss Scene not assigned!")
		is_resetting = false
		return
		
	await get_tree().create_timer(0.2).timeout
	
	var new_boss = boss_scene.instantiate()
	boss_container.add_child(new_boss)
	new_boss.global_position = initial_boss_pos
	
	# Set the new boss as the current reference and reconnect
	current_boss = new_boss
	_connect_to_boss()
	is_resetting = false

func _connect_to_boss() -> void:
	if current_boss:
		if current_boss.has_signal("summon"):
			if not current_boss.summon.is_connected(_on_boss_summon):
				current_boss.summon.connect(_on_boss_summon)
				print(">>> SPAWNER: Summon signal connected successfully!")
		else:
			push_error(">>> SPAWNER: Boss found but missing 'summon' signal!")

func _on_boss_summon(enemy_scene: PackedScene, count: int, interval: float, pos: Vector2) -> void:
	if not enemy_scene:
		return
		
	var target_parent = minions if minions else get_parent()
		
	for i in range(count):
		if is_resetting:
			return
		var new_enemy = enemy_scene.instantiate()
		target_parent.add_child(new_enemy)
		if player:
			new_enemy.global_position = player.global_position - Vector2(0.0, 100.0)
		else:
			new_enemy.global_position = pos
		new_enemy.global_position.x += randf_range(-30, 30)
		
		if interval > 0:
			await get_tree().create_timer(interval).timeout
