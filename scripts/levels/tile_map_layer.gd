extends TileMapLayer

const TILE_MAP = {
	"light": Vector2i(0, 1), # If current is dark, switch to this (Light)
	"dark": Vector2i(12, 0) # If current is light, switch to this (Dark)
}

const SOURCE_ID = 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("p2_skill"):
		toggle_world_state()

func toggle_world_state() -> void:
	var all_cells = get_used_cells()
	
	for cell in all_cells:
		# 1. Get the data object for the tile at this coordinate
		var tile_data = get_cell_tile_data(cell)
		
		if tile_data:
			# 2. Read the custom string we set in the editor
			var type = tile_data.get_custom_data("element_type")
			
			# 3. If the type exists in our map, swap it
			if TILE_MAP.has(type):
				var target_coords = TILE_MAP[type]
				set_cell(cell, SOURCE_ID, target_coords)
