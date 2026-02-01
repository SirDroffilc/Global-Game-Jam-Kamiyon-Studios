extends Node2D

@onready var player: Player = $Player
var latest_checkpoint_pos: Vector2

@export var pause_menu_scene: PackedScene = preload("res://scenes/pause.tscn")

# --- TileMap References ---
@onready var tile_map_layer_dark: TileMapLayer = $TileMap/TileMapLayerDark
@onready var tile_map_layer_light: TileMapLayer = $TileMap/TileMapLayerLight
@onready var tile_map_layer_neutral: TileMapLayer = $TileMap/TileMapLayerNeutral

func _ready() -> void:
	# 0. Start with a black fade-in transition
	_fade_from_black()
	
	# Initial visibility sync with PlayerManager
	_update_tilemap_visibility()
	
	AudioManager.play_music("GameSceneMusic")
	
	# 1. Initialize the checkpoint to the player's starting position
	latest_checkpoint_pos = player.global_position
	
	# 2. Connect to all checkpoints in the level
	for checkpoint in get_tree().get_nodes_in_group("Checkpoints"):
		checkpoint.checkpoint_activated.connect(_on_checkpoint_activated)
	
	# 3. Listen for the PlayerManager death signal
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_player_respawn)

func _input(event: InputEvent) -> void:
	# Meticulous Input Check: Toggles world when skill1 is pressed
	if event.is_action_pressed("skill1"):
		PlayerManager.is_light = !PlayerManager.is_light
		_update_tilemap_visibility()
		
	if event.is_action_pressed("ui_cancel"): 
		toggle_pause()

# --- World Logic Functions ---

func _update_tilemap_visibility() -> void:
	# Neutral is ALWAYS visible
	tile_map_layer_neutral.visible = true
	
	# Light Layer: Visible only if is_light is true
	tile_map_layer_light.visible = !PlayerManager.is_light
	
	# Dark Layer: Visible only if is_light is false
	tile_map_layer_dark.visible = PlayerManager.is_light
	
	print(">>> WORLD: Swapped. Light is ", "ON" if PlayerManager.is_light else "OFF")

# --- Transition Functions ---

func _fade_from_black() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100 
	add_child(canvas)
	
	var rect = ColorRect.new()
	canvas.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.color = Color.BLACK
	
	var tween = create_tween()
	tween.tween_interval(1.25)
	tween.tween_property(rect, "modulate:a", 0.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(canvas.queue_free)

# --- Checkpoint & Respawn Logic ---

func _on_checkpoint_activated(pos: Vector2) -> void:
	latest_checkpoint_pos = pos
	print("Checkpoint updated to: ", pos)

func _on_player_respawn() -> void:
	call_deferred("_move_player_to_checkpoint")

func _move_player_to_checkpoint() -> void:
	player._on_death() 
	
	await player.animated_sprite.animation_finished
	
	PlayerManager.reset_health()
	player.global_position = latest_checkpoint_pos
	player.velocity = Vector2.ZERO
	
	player.state_machine.init(player)
	
	# Ensure visibility is correct after respawning
	_update_tilemap_visibility()
	
	print(">>> LEVEL: Respawn sequence complete.")


func toggle_pause() -> void:
	# If the game is already paused, we don't want to spawn another menu
	if get_tree().paused:
		return
	
	# 1. Instantiate and add the menu to the scene
	var pause_menu = pause_menu_scene.instantiate()
	# Using add_child(pause_menu) on the current scene is usually safer 
	# than get_tree().root to keep it within the scene's coordinate space
	add_child(pause_menu) 
	
	# 2. Tell the engine to STOP everything
	get_tree().paused = true
	
	# 3. Ensure the mouse is visible so the player can click buttons
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
