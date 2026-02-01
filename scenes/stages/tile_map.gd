extends Node2D

# --- Node References ---
# Meticulously using the specific nodes you defined
@onready var tile_map_layer_dark: TileMapLayer = $TileMapLayerDark
@onready var tile_map_layer_light: TileMapLayer = $TileMapLayerLight

# --- Reference to the Player for Signal Connection ---
@export var player: Player

func _ready() -> void:
	# 1. Validation: Ensure TileMapLayers are present
	if not tile_map_layer_dark or not tile_map_layer_light:
		push_error(">>> TILEMAP ERROR: TileMapLayer nodes not found. Check your scene paths!")
		return

	# 2. Connect to the player signal to trigger the world swap
	if player:
		if not player.element_toggled.is_connected(_on_player_element_toggled):
			player.element_toggled.connect(_on_player_element_toggled)
	else:
		push_warning(">>> TILEMAP WARNING: Player not assigned. Visibility will only set once on Load.")

	# 3. Use PlayerManager for initial initialization
	_update_world_visibility(PlayerManager.is_light)

func _on_player_element_toggled(_is_light_signal: bool) -> void:
	# Meticulously use the global PlayerManager state as the source of truth
	_update_world_visibility(PlayerManager.is_light)

func _update_world_visibility(is_light_state: bool) -> void:
	# Light mode: Show light layer, hide dark layer
	# Dark mode: Show dark layer, hide light layer
	tile_map_layer_light.visible = is_light_state
	tile_map_layer_dark.visible = not is_light_state

	print(">>> WORLD MANAGER: Syncing visibility with PlayerManager (is_light = ", is_light_state, ")")
