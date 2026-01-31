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
	PlayerManager.reset_health() # Reset stats
	player.global_position = latest_checkpoint_pos
	
	# Optional: Reset player velocity so they don't spawn with 'death momentum'
	player.velocity = Vector2.ZERO
	
	# Optional: If your player has a 'respawn' or 'idle' state, force it here
	if player.state_machine:
		player.state_machine.init(player) # Re-init logic to reset states
		
