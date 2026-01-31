extends Node2D

@onready var player: Player = $Player
var latest_checkpoint_pos: Vector2

func _ready() -> void:
	# 1. Initialize the checkpoint to the player's starting position
	latest_checkpoint_pos = player.global_position
	
	# 2. Connect to all checkpoints in the level
	# Meticulous Note: Ensure all your checkpoint nodes are in a Group called "Checkpoints"
	for checkpoint in get_tree().get_nodes_in_group("Checkpoints"):
		checkpoint.checkpoint_activated.connect(_on_checkpoint_activated)
	
	# 3. Listen for the PlayerManager death signal
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_player_respawn)

func _on_checkpoint_activated(pos: Vector2) -> void:
	# Update the respawn point
	latest_checkpoint_pos = pos
	print("Checkpoint updated to: ", pos)

func _on_player_respawn() -> void:
	# Meticulously move the player to the saved position
	# We use a small delay or call_deferred to ensure physics don't break
	call_deferred("_move_player_to_checkpoint")

func _move_player_to_checkpoint() -> void:
	# 1. Trigger the death state first to play the animation
	player._on_death() 
	
	# 2. Wait for the animation within the AnimatedSprite
	await player.animated_sprite.animation_finished
	
	# 3. Perform the reset and teleport
	PlayerManager.reset_health()
	player.global_position = latest_checkpoint_pos
	player.velocity = Vector2.ZERO
	
	# 4. CRITICAL: Re-init the state machine to return to IdleState
	player.state_machine.init(player)
	
	print(">>> LEVEL: Respawn sequence complete.")
