extends Node

@onready var tile_map_layer_dark: TileMapLayer = $TileMapLayerDark
@onready var tile_map_layer_light: TileMapLayer = $TileMapLayerLight
@onready var tile_map_layer_neutral: TileMapLayer = $TileMapLayerNeutral

func _ready() -> void:
	# Wait one frame to ensure the Player has finished spawning in the Stage
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		# If already connected (to prevent double connections), disconnect first
		if player.element_toggled.is_connected(_on_player_toggle):
			player.element_toggled.disconnect(_on_player_toggle)
			
		player.element_toggled.connect(_on_player_toggle)
		_update_layers(player.is_light)
		print(">>> TileManager: Connected to Player successfully.")
	else:
		print(">>> ERROR: TileManager could not find Player! Is the Player node in the 'Player' group?")

func _on_player_toggle(is_light: bool) -> void:
	_update_layers(is_light)

func _update_layers(is_light: bool) -> void:
	# Defensive programming: ensure nodes aren't null before changing visibility
	if tile_map_layer_neutral: tile_map_layer_neutral.visible = true
	if tile_map_layer_light: tile_map_layer_light.visible = is_light
	if tile_map_layer_dark: tile_map_layer_dark.visible = !is_light
