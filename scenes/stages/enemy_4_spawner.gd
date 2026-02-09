extends Node2D

# --- Meticulous Scene References ---
@export var boss_scene: PackedScene = preload("res://scenes/enemies/enemy_4.tscn")

@onready var minions: Node2D = get_tree().current_scene.find_child("Minions", true, false)
@onready var boss_container: Node2D = $"../../EnemiesContainer/Boss"
@onready var boss_health_bar: ProgressBar = $"../../HUD/BossHealthBar"

# --- State Variables ---
var current_boss: CharacterBody2D
var initial_boss_pos: Vector2
var player: Player = null
var is_resetting: bool = false
var health_tween: Tween # Meticulous: Keep this at class level to manage overrides

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	current_boss = get_node_or_null("../../EnemiesContainer/Boss/Enemy4")
	
	if current_boss:
		initial_boss_pos = current_boss.global_position
		_setup_boss_ui()
		_connect_to_boss()
	
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_player_died)

# --- UI & Connection Logic ---

func _setup_boss_ui() -> void:
	if not current_boss or not boss_health_bar: return
	
	boss_health_bar.max_value = current_boss.base_health
	boss_health_bar.value = current_boss.current_health
	boss_health_bar.visible = current_boss.is_active

func _connect_to_boss() -> void:
	if not current_boss: return
	
	# Connect Summon Logic
	if current_boss.has_signal("summon") and not current_boss.summon.is_connected(_on_boss_summon):
		current_boss.summon.connect(_on_boss_summon)
	
	# Connect Health Logic
	if current_boss.has_signal("boss_health_changed") and not current_boss.boss_health_changed.is_connected(_on_boss_health_updated):
		current_boss.boss_health_changed.connect(_on_boss_health_updated)
		print(">>> SPAWNER: Boss HUD connected successfully!")
	
	if current_boss.has_signal("boss_visible_on_screen") and not current_boss.boss_visible_on_screen.is_connected(_on_boss_visible_on_screen):
		current_boss.boss_visible_on_screen.connect(_on_boss_visible_on_screen)

func _on_boss_health_updated(new_health: int) -> void:
	if not boss_health_bar: return
	
	# 1. Show the bar on first hit
	if not boss_health_bar.visible:
		boss_health_bar.visible = true
		boss_health_bar.modulate.a = 1.0 # Ensure it's opaque when first shown
			
	# 2. Meticulous Tween Management
	if health_tween:
		health_tween.kill()
	
	health_tween = create_tween()
	
	health_tween.tween_property(boss_health_bar, "value", new_health, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	if new_health <= 0:
		health_tween.parallel().tween_property(boss_health_bar, "modulate:a", 0.0, 1.0)\
			.set_delay(0.2) # Small delay so player sees the bar hit zero
		
		health_tween.chain().tween_callback(func(): boss_health_bar.visible = false)

func _on_boss_visible_on_screen() -> void:
	if boss_health_bar:
		# 1. Ensure it is technically visible but transparent
		boss_health_bar.visible = true
		boss_health_bar.modulate.a = 0.0
		
		# 2. Create the tween
		var tween = create_tween()
		
		tween.tween_property(boss_health_bar, "modulate:a", 1.0, 1.5)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)

func _on_player_died() -> void:
	if is_resetting: return
	is_resetting = true
	
	if boss_health_bar:
		boss_health_bar.visible = false
	
	await get_tree().create_timer(1.0).timeout
	_cleanup_arena()
	_respawn_boss.call_deferred()

func _cleanup_arena() -> void:
	if minions:
		for minion in minions.get_children(): minion.queue_free()
	
	for ghost in get_tree().get_nodes_in_group("Ghosts"): 
		ghost.queue_free()
	
	if is_instance_valid(current_boss):
		current_boss.queue_free()

func _respawn_boss() -> void:
	if not boss_scene:
		is_resetting = false
		return
		
	var new_boss = boss_scene.instantiate()
	boss_container.add_child(new_boss)
	new_boss.global_position = initial_boss_pos
	
	current_boss = new_boss
	_setup_boss_ui()
	_connect_to_boss()
	
	is_resetting = false

func _on_boss_summon(enemy_scene: PackedScene, count: int, interval: float, pos: Vector2) -> void:
	if not enemy_scene or is_resetting: return
	var target_parent = minions if minions else get_parent()
		
	for i in range(count):
		if is_resetting: return
		var new_enemy = enemy_scene.instantiate()
		target_parent.add_child(new_enemy)
		
		# Meticulous Position Logic
		new_enemy.global_position = (player.global_position - Vector2(0, 100)) if player else pos
		new_enemy.global_position.x += randf_range(-30, 30)
		
		if interval > 0: 
			await get_tree().create_timer(interval).timeout
