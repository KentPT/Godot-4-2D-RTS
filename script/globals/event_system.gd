extends Node
# Custom signals

# Building signals
signal building_build
signal building_selected(building_type: int, source_id: int, atlas_coords: Vector2i)

# Formation signals
signal formation_changed(formation_type: String)

# Resource signals
signal resource_changed(resource_type: String, amount: int)
