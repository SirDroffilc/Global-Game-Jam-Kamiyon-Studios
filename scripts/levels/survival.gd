extends Node2D

# --- References ---
@onready var spawn_point: Marker2D = $SpawnPoint # Place a Marker2D in your scene called SpawnPoint
@onready var player: Player = $Player

func _ready() -> void:
	# Initial safety check
	if not is_instance_valid(player) or not is_instance_valid(spawn_point):
		push_error(">>> LEVEL ERROR: Missing Player or SpawnPoint reference!")
		return

	# Set player to starting position on start
	respawn_player()

	# Connect to the global death signal
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_global_player_died)

func _on_global_player_died() -> void:
	# 1. Wait a moment for the death animation/sound to play
	print(">>> Level: Player died. Preparing respawn...")
	await get_tree().create_timer(1.5).timeout
	
	# 2. Reset the game state
	respawn_player()

func respawn_player() -> void:
	# 1. Reset Player Stats via the Autoload
	PlayerManager.reset_health()
	
	# 2. Physically move the player
	# Note: We use global_position to ensure it ignores any parent offsets
	player.global_position = spawn_point.global_position
	
	# 3. Reset the State Machine
	# Assuming your StateMachine has a way to go back to Idle/Initialization
	if player.state_machine:
		# Replace 'idle_state' with whatever your default state node is named
		player.state_machine.change_state(player.get_node("StateMachine/IdleState"))
	
	# 4. Cleanup visuals
	player.velocity = Vector2.ZERO
	player.animated_sprite.modulate = Color.WHITE
	
	print(">>> Level: Player respawned at ", spawn_point.global_position)
