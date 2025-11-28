extends Node2D

@onready var ground: TileMapLayer = $Ground
@onready var buildings: TileMapLayer = $Buildings
@onready var preview: TileMapLayer = $Preview

var drawing: bool = false
var start_position = Vector2.ZERO
var end_position = Vector2.ZERO
var selection_rect : Rect2
var width = 0

var source_id: int
var selected_tile: Vector2i

var select_mode: bool = false

var placeable: bool = true:
	set(value):
		placeable = value
		
		if value == false:
			preview.modulate = Color.RED
		else:
			# RGBA
			preview.modulate = Color("ffffff6f")

var preview_tile: Vector2i:
	set(value):
		if preview_tile == value:
			return
			
		preview.erase_cell(preview_tile)
		preview_tile = value
		preview.set_cell(value, source_id, selected_tile)
		
		var atlas_tile : TileSetAtlasSource
		atlas_tile = preview.tile_set.get_source(source_id)
		var tile_size
		if atlas_tile:
			tile_size = atlas_tile.get_tile_size_in_atlas(selected_tile)
			print(tile_size)
			
		placeable = true
		
		# Texture origin offset compensation (same as in ground.gd)
		var tile_size_px = ground.tile_set.tile_size.x if ground.tile_set else 16
		var texture_offset = Vector2i(-16, -16)  # Should match ground.gd TEXTURE_OFFSET_PIXELS
		var tile_offset = Vector2i(
			texture_offset.x / tile_size_px,
			texture_offset.y / tile_size_px
		)
		
		for i in range(tile_size.x):
			for j in range(tile_size.y):
				var building_tile = preview_tile + Vector2i(i, j)
				
				# This is where the building will actually be stored in BuildingManager
				# Ground.gd does: adjusted_coords = coords - tile_offset
				# So we need to check ground at: coords = adjusted_coords + tile_offset
				var ground_check_tile = building_tile + tile_offset
				
				# Check if tile is already occupied by another building
				if building_tile in BuildingManager.used_tiles:
					placeable = false
					break
				
				# Check if ground tile exists at the adjusted position
				if ground.get_cell_source_id(ground_check_tile) == -1:
					placeable = false
					break
				
				# Check if ground tile has navigation layer enabled
				var tile_data = ground.get_cell_tile_data(ground_check_tile)
				if tile_data:
					var nav_polygon = tile_data.get_navigation_polygon(0)
					if nav_polygon == null:
						placeable = false
						break
				else:
					placeable = false
					break
			
			if not placeable:
				break

func _ready() -> void:
	# Connect to building selection signal from UI
	EventSystem.building_selected.connect(_on_building_selected)

func get_snapped_position(global_pos: Vector2) -> Vector2i:
	var local_pos = buildings.to_local(global_pos)
	var tile_pos = buildings.local_to_map(local_pos)

	return tile_pos

func _physics_process(_delta: float) -> void:
	if select_mode:
		preview_tile = get_snapped_position(get_global_mouse_position())

func place_tile(tile_pos: Vector2i):
	buildings.set_cell(tile_pos, source_id, selected_tile)
	preview.erase_cell(tile_pos)
	
	# Use tile_pos instead of preview_tile
	BuildingManager.get_tiles(buildings, selected_tile, tile_pos)
	
	# Rebuild navigation map dynamically
	buildings.update_internals()  # ensures navigation mesh updates
	ground.notify_runtime_tile_data_update()
	EventSystem.building_build.emit()

func cancel_building_placement():
	if select_mode:
		preview.erase_cell(preview_tile)
		select_mode = false
		print("Building placement cancelled")

func _draw() -> void:
	var rect_position = start_position
	var rect_size = end_position - start_position

	if rect_size.x < 0:
		rect_position.x += rect_size.x
		rect_size.x = abs(rect_size.x)

	if rect_size.y < 0:
		rect_position.y += rect_size.y
		rect_size.y = abs(rect_size.y)

	selection_rect = Rect2(rect_position, rect_size)
	draw_rect(selection_rect, Color.WHITE, false, width)

func _input(event: InputEvent) -> void:
	# InputEventMouseButton
	if event is InputEventMouseButton:
		# Left click - place building if in select mode, otherwise start selection box
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if select_mode and placeable:
				# Place the building
				place_tile(preview_tile)
				select_mode = false
				return  # Don't start selection box
			elif not select_mode:
				# Start selection box only if not in building mode
				width = 1
				drawing = true
				start_position = get_global_mouse_position()
				end_position = start_position

		if event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			if not select_mode:  # Only handle selection box release if not building
				width = 0
				drawing = false
				start_position = Vector2.ZERO
				end_position = Vector2.ZERO
				queue_redraw()

		# Right click - cancel building or move units
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if select_mode:
				# Cancel building placement
				cancel_building_placement()
			else:
				# Move selected units
				UnitManager.move_to_position(ground, get_tile_pos(get_global_mouse_position()))

	# InputEventMouseMotion
	if event is InputEventMouseMotion and drawing and not select_mode:
		# Use global mouse position for motion as well
		end_position = get_global_mouse_position()
		queue_redraw()
		UnitManager.selected_rect = selection_rect
		
	# InputEventKey - Keyboard shortcuts
	if event is InputEventKey:
		# ESC to cancel building placement
		if event.pressed and event.keycode == KEY_ESCAPE and select_mode:
			cancel_building_placement()
		
		# Building shortcuts (B + 1-5)
		if event.pressed and event.is_action_pressed("Key_1"):
			if Input.is_action_pressed("Building"):
				select_building(0, Vector2i(0, 12))
				
		if event.pressed and event.is_action_pressed("Key_2"):
			if Input.is_action_pressed("Building"):
				select_building(0, Vector2i(3, 6))
				
		if event.pressed and event.is_action_pressed("Key_3"):
			if Input.is_action_pressed("Building"):
				select_building(0, Vector2i(3, 3))
				
		if event.pressed and event.is_action_pressed("Key_4"):
			if Input.is_action_pressed("Building"):
				select_building(0, Vector2i(3, 0))
				
		if event.pressed and event.is_action_pressed("Key_5"):
			if Input.is_action_pressed("Building"):
				select_building(0, Vector2i(0, 3))

func _on_building_selected(building_type: int, _source_id: int, atlas_coords: Vector2i) -> void:
	print("Building selected from UI: Type=", building_type, " Atlas=", atlas_coords)
	select_building(_source_id, atlas_coords)

func select_building(_source_id: int, atlas_coords: Vector2i) -> void:
	select_mode = true
	source_id = _source_id
	selected_tile = atlas_coords
	print("Building placement mode activated - select_mode=", select_mode)
	print("  Source ID: ", source_id, " Selected Tile: ", selected_tile)
	print("  Left click to place, Right click to cancel")

func get_tile_pos(global_pos):
	var local_pos = ground.to_local(global_pos)
	var tile_pos = ground.local_to_map(local_pos)
	
	return tile_pos
