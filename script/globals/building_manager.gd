extends Node2D
 
var used_tiles: Array = []

# Track buildings for resource production
var buildings_list: Array = []

# Production timer
var production_timer: Timer

func _ready() -> void:
	# Create production timer
	production_timer = Timer.new()
	production_timer.wait_time = 5.0  # Produce resources every 5 seconds
	production_timer.timeout.connect(_on_production_timer_timeout)
	add_child(production_timer)
	production_timer.start()

func get_tiles(layer : TileMapLayer, selected_tile : Vector2i, tile_pos : Vector2i):
	var source_id = layer.get_cell_source_id(tile_pos)
	var atlas_tile : TileSetAtlasSource
	var tile_size
 
	if source_id != -1:
		atlas_tile = layer.tile_set.get_source(source_id)
	
	if atlas_tile:
		tile_size = atlas_tile.get_tile_size_in_atlas(selected_tile)
		print("Tile size: ", tile_size)
		print("Tile position: ", tile_pos)
 
	# Changed loop order to match X then Y
	for i in range(tile_size.x):
		for j in range(tile_size.y):
			var tile = tile_pos + Vector2i(i, j)
			if tile not in used_tiles:
				used_tiles.append(tile)
	
	# Track building type based on atlas coordinates
	var building_info = {
		"position": tile_pos,
		"atlas_coords": selected_tile,
		"type": get_building_type(selected_tile)
	}
	buildings_list.append(building_info)
 
	print("Used tiles: ", used_tiles)
	print("Layer used cells: ", layer.get_used_cells())

func is_tile_blocked(tile_pos: Vector2i) -> bool:
	return tile_pos in used_tiles

func get_building_type(atlas_coords: Vector2i) -> String:
	# Map atlas coordinates to building types
	if atlas_coords == Vector2i(0, 12):
		return "Farm"
	elif atlas_coords == Vector2i(3, 6):
		return "Barracks"
	elif atlas_coords == Vector2i(3, 3):
		return "Stable"
	elif atlas_coords == Vector2i(3, 0):
		return "Townhall"
	elif atlas_coords == Vector2i(0, 3):
		return "Lumbermill"
	else:
		return "Unknown"

func _on_production_timer_timeout() -> void:
	# Produce resources based on building types
	for building in buildings_list:
		match building["type"]:
			"Farm":
				EventSystem.resource_changed.emit("food", 5)
				print("Farm produced 5 food")
			"Lumbermill":
				EventSystem.resource_changed.emit("wood", 3)
				print("Lumbermill produced 3 wood")
			"Townhall":
				EventSystem.resource_changed.emit("gold", 2)
				print("Townhall produced 2 gold")
