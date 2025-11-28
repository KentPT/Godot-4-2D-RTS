extends TileMapLayer
class_name Ground

@onready var buildings: TileMapLayer = $"../Buildings"

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return BuildingManager.is_tile_blocked(coords)

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	if BuildingManager.is_tile_blocked(coords):
		tile_data.set_navigation_polygon(0, null)
