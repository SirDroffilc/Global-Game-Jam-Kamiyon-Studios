extends Node2D

@onready var player: Player = $Player
var latest_checkpoint_pos: Vector2

func _ready() -> void:
	# 0. Start with a black fade-in transition
	_fade_from_black()
	
	AudioManager.play_music("GameSceneMusic")
	
	# 1. Initialize the checkpoint to the player's starting position
	latest_checkpoint_pos = player.global_position
	
	# 2. Connect to all checkpoints in the level
	for checkpoint in get_tree().get_nodes_in_group("Checkpoints"):
		checkpoint.checkpoint_activated.connect(_on_checkpoint_activated)
	
	# 3. Listen for the PlayerManager death signal
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_player_respawn)

# --- Transition Functions ---

func _fade_from_black() -> void:
	# 1. Create the temporary CanvasLayer and ColorRect
	var canvas = CanvasLayer.new()
	canvas.layer = 100 
	add_child(canvas)
	
	var rect = ColorRect.new()
	canvas.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.color = Color.BLACK
	
	# 2. Setup the Meticulous Tween Sequence
	var tween = create_tween()
	
	# Hold the screen black for 2 seconds
	tween.tween_interval(1.25)
	
	# SLOW FADE: Changed 1.0 to 3.0 for a slower transition
	# (Alpha 1.0 -> 0.0 over 3.0 seconds)
	tween.tween_property(rect, "modulate:a", 0.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Remove transition nodes once finished
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
	
	print(">>> LEVEL: Respawn sequence complete.")
