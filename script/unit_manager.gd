extends Node2D

var selected_rect : Rect2:
	set(value):
		selected_rect = value
		check_unit()

# Unit selected
var unit_selected : Array = []

# Control group
var control_group_1 : Array = []
var control_group_2 : Array = []
var control_group_3 : Array = []

# Formation type
var current_formation: String = "grid"

func _ready() -> void:
	# Connect to formation change signal
	EventSystem.formation_changed.connect(_on_formation_changed)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		# Only handle control groups if NOT in building mode
		if event.pressed and event.is_action_pressed("Key_1"):
			if not Input.is_action_pressed("Building"):  # Don't interfere with building shortcuts
				if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META):
					control_group_1 = unit_selected.duplicate(true)
				else:
					select_in(control_group_1)
					unit_selected = control_group_1.duplicate(true)

		if event.pressed and event.is_action_pressed("Key_2"):
			if not Input.is_action_pressed("Building"):
				if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META):
					control_group_2 = unit_selected.duplicate(true)
				else:
					select_in(control_group_2)
					unit_selected = control_group_2.duplicate(true)

		if event.pressed and event.is_action_pressed("Key_3"):
			if not Input.is_action_pressed("Building"):
				if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META):
					control_group_3 = unit_selected.duplicate(true)
				else:
					select_in(control_group_3)
					unit_selected = control_group_3.duplicate(true)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var clicked_unit = null

		# Check if a unit is under the mouse
		for unit in get_tree().get_nodes_in_group("Unit"):
			var unit_rect = Rect2(unit.global_position - Vector2(8, 8), Vector2(16, 16))
			if unit_rect.has_point(mouse_pos):
				clicked_unit = unit
				break

		if clicked_unit:
			# Deselect previous units
			for unit in unit_selected:
				unit.deselect()
			unit_selected.clear()

			# Select the clicked one
			clicked_unit.select()
			unit_selected.append(clicked_unit)
			return

		if unit_selected.size() > 0:
			for unit in unit_selected:
				unit.deselect()
			unit_selected.clear()
			return

func check_unit() -> void:
	unit_selected = []
	for unit in get_tree().get_nodes_in_group("Unit"):
		if selected_rect.has_point(unit.global_position):
			unit.select()
			unit_selected.append(unit)
		else:
			unit.deselect()

func get_formation(tile_pos, direction: Vector2 = Vector2.ZERO):
	match current_formation:
		"grid":
			return get_grid_formation(tile_pos, direction)
		"line":
			return get_line_formation(tile_pos, direction)
		"wedge":
			return get_wedge_formation(tile_pos, direction)
		"square":
			return get_square_formation(tile_pos, direction)
		"triangle":
			return get_triangle_formation(tile_pos, direction)
		_:
			return get_grid_formation(tile_pos, direction)

func get_grid_formation(tile_pos, direction: Vector2):
	var formation = []
	var unit_count = unit_selected.size()
	
	if unit_count == 0:
		return formation
	
	# Calculate grid dimensions (roughly square)
	var cols = ceil(sqrt(unit_count))
	var rows = ceil(float(unit_count) / cols)
	
	# Calculate rotation angle from direction
	var angle = 0.0
	if direction.length() > 0:
		angle = direction.angle()
	
	var index = 0
	
	# Create grid centered around tile_pos
	for row in range(rows):
		for col in range(cols):
			if index >= unit_count:
				break
			
			# Calculate offset from center
			var x_offset = col - (cols - 1) / 2.0
			var y_offset = row - (rows - 1) / 2.0
			
			# Apply rotation
			var offset = Vector2(x_offset, y_offset).rotated(angle)
			
			# Round to nearest tile
			var final_pos = tile_pos + Vector2i(round(offset.x), round(offset.y))
			formation.append(final_pos)
			index += 1
		
		if index >= unit_count:
			break
	
	return formation

func get_line_formation(tile_pos, direction: Vector2):
	"""Firing line - perpendicular to movement direction"""
	var formation = []
	var unit_count = unit_selected.size()
	
	if unit_count == 0:
		return formation
	
	# Calculate perpendicular angle for line (90 degrees to movement)
	var angle = PI / 2  # Default horizontal
	if direction.length() > 0:
		angle = direction.angle() + PI / 2
	
	# Create line perpendicular to movement with proper spacing
	for i in range(unit_count):
		var offset_distance = i - (unit_count - 1) / 2.0
		var offset = Vector2(offset_distance * 1.5, 0).rotated(angle)  # Added spacing multiplier
		var final_pos = tile_pos + Vector2i(round(offset.x), round(offset.y))
		
		# Add position even if duplicate (we'll handle collisions in pathfinding)
		formation.append(final_pos)
	
	return formation

func get_wedge_formation(tile_pos, direction: Vector2):
	"""Flying wedge / Triangle formation - tip points toward enemy"""
	var formation = []
	var unit_count = unit_selected.size()
	
	if unit_count == 0:
		return formation
	
	# Calculate rotation angle
	var angle = 0.0
	if direction.length() > 0:
		angle = direction.angle()
	
	# Build wedge from tip backwards
	var row = 0
	var units_placed = 0
	
	while units_placed < unit_count:
		var units_in_row = row + 1
		
		for col in range(units_in_row):
			if units_placed >= unit_count:
				break
			
			# Center units in each row
			var x_offset = col - (units_in_row - 1) / 2.0
			var y_offset = -row  # Negative so tip points forward
			
			# Apply rotation
			var offset = Vector2(x_offset, y_offset).rotated(angle)
			var final_pos = tile_pos + Vector2i(round(offset.x), round(offset.y))
			
			# Ensure no duplicate positions
			if final_pos not in formation:
				formation.append(final_pos)
				units_placed += 1
		
		row += 1
	
	return formation

func get_square_formation(tile_pos, direction: Vector2):
	"""Hollow square - units form perimeter of a square"""
	var formation = []
	var unit_count = unit_selected.size()
	
	if unit_count == 0:
		return formation
	
	if unit_count < 4:
		# Not enough units for hollow square, use line instead
		return get_line_formation(tile_pos, direction)
	
	# Calculate rotation angle
	var angle = 0.0
	if direction.length() > 0:
		angle = direction.angle()
	
	# Calculate side length to fit all units around perimeter
	# Perimeter = 4 * side_length - 4 (corners counted once)
	# side_length ≈ (units + 4) / 4
	var side_length = max(2, ceil((unit_count + 4) / 4.0))
	var units_placed = 0
	
	# Make sure we have enough space
	while (side_length * 4 - 4) < unit_count:
		side_length += 1
	
	# Top side (left to right)
	for i in range(side_length):
		if units_placed >= unit_count:
			break
		var x = i - (side_length - 1) / 2.0
		var y = -(side_length - 1) / 2.0
		var offset = Vector2(x, y).rotated(angle)
		var final_pos = tile_pos + Vector2i(round(offset.x), round(offset.y))
		formation.append(final_pos)
		units_placed += 1
	
	# Right side (top to bottom, skip corner)
	for i in range(1, side_length):
		if units_placed >= unit_count:
			break
		var x = (side_length - 1) / 2.0
		var y = i - (side_length - 1) / 2.0
		var offset = Vector2(x, y).rotated(angle)
		var final_pos = tile_pos + Vector2i(round(offset.x), round(offset.y))
		formation.append(final_pos)
		units_placed += 1
	
	# Bottom side (right to left, skip corner)
	for i in range(side_length - 2, -1, -1):
		if units_placed >= unit_count:
			break
		var x = i - (side_length - 1) / 2.0
		var y = (side_length - 1) / 2.0
		var offset = Vector2(x, y).rotated(angle)
		var final_pos = tile_pos + Vector2i(round(offset.x), round(offset.y))
		formation.append(final_pos)
		units_placed += 1
	
	# Left side (bottom to top, skip both corners)
	for i in range(side_length - 2, 0, -1):
		if units_placed >= unit_count:
			break
		var x = -(side_length - 1) / 2.0
		var y = i - (side_length - 1) / 2.0
		var offset = Vector2(x, y).rotated(angle)
		var final_pos = tile_pos + Vector2i(round(offset.x), round(offset.y))
		formation.append(final_pos)
	
	# If we still don't have enough positions, fill the interior
	while formation.size() < unit_count:
		var extra_offset = Vector2(formation.size() % 3 - 1, formation.size() / 3 - 1)
		var rotated = extra_offset.rotated(angle)
		formation.append(tile_pos + Vector2i(round(rotated.x), round(rotated.y)))
	
	return formation

func get_triangle_formation(tile_pos, direction: Vector2):
	"""Triangle formation - broad base facing enemy direction"""
	var formation = []
	var unit_count = unit_selected.size()
	
	if unit_count == 0:
		return formation
	
	# Calculate rotation angle (triangle points forward)
	var angle = 0.0
	if direction.length() > 0:
		angle = direction.angle()
	
	# Calculate triangle dimensions to fit all units
	# For a triangle: total units ≈ (base * (base + 1)) / 2
	# Solve for base: base ≈ sqrt(2 * units)
	var base_width = max(1, ceil(sqrt(2.0 * unit_count)))
	
	var units_placed = 0
	var row = 0
	
	# Build triangle from base (widest) to tip (point)
	while units_placed < unit_count:
		var units_in_row = max(1, base_width - row)
		
		for col in range(units_in_row):
			if units_placed >= unit_count:
				break
			
			# Center units in each row
			var x_offset = col - (units_in_row - 1) / 2.0
			var y_offset = -row  # Negative so base is at back, tip forward
			
			# Apply rotation
			var offset = Vector2(x_offset, y_offset).rotated(angle)
			var final_pos = tile_pos + Vector2i(round(offset.x), round(offset.y))
			
			formation.append(final_pos)
			units_placed += 1
		
		row += 1
		
		if units_in_row <= 0:
			break
	
	return formation

func get_split_formation(tile_pos, direction: Vector2):
	"""Split formation - divides units into two groups on either side"""
	var formation = []
	var unit_count = unit_selected.size()
	
	if unit_count == 0:
		return formation
	
	if unit_count == 1:
		formation.append(tile_pos)
		return formation
	
	# Calculate rotation angle
	var angle = 0.0
	if direction.length() > 0:
		angle = direction.angle()
	
	# Split units evenly (or as close as possible)
	var left_count = unit_count / 2
	var right_count = unit_count - left_count
	
	var units_placed = 0
	var spacing = 1  # Gap between the two groups
	
	# Left group
	var left_rows = ceil(sqrt(left_count))
	var left_cols = ceil(float(left_count) / left_rows)
	
	for row in range(left_rows):
		for col in range(left_cols):
			if units_placed >= left_count:
				break
			
			# Position on left side
			var x_offset = -spacing - left_cols + col
			var y_offset = row - (left_rows - 1) / 2.0
			
			var offset = Vector2(x_offset, y_offset).rotated(angle)
			var final_pos = tile_pos + Vector2i(round(offset.x), round(offset.y))
			
			if final_pos not in formation:
				formation.append(final_pos)
				units_placed += 1
		
		if units_placed >= left_count:
			break
	
	# Right group
	var right_rows = ceil(sqrt(right_count))
	var right_cols = ceil(float(right_count) / right_rows)
	units_placed = 0
	
	for row in range(right_rows):
		for col in range(right_cols):
			if units_placed >= right_count:
				break
			
			# Position on right side
			var x_offset = spacing + col
			var y_offset = row - (right_rows - 1) / 2.0
			
			var offset = Vector2(x_offset, y_offset).rotated(angle)
			var final_pos = tile_pos + Vector2i(round(offset.x), round(offset.y))
			
			if final_pos not in formation:
				formation.append(final_pos)
				units_placed += 1
		
		if units_placed >= right_count:
			break
	
	return formation

func move_to_position(layer: TileMapLayer, tile_pos):
	if unit_selected.size() == 0:
		return
	
	# Calculate average position of selected units
	var center_pos = Vector2.ZERO
	for unit in unit_selected:
		center_pos += unit.global_position
	center_pos /= unit_selected.size()
	
	# Calculate direction from units to target
	var target_world_pos = layer.map_to_local(tile_pos)
	var direction = (target_world_pos - center_pos).normalized()
	
	# Get formation with rotation
	var formation = get_formation(tile_pos, direction)
	
	# Safety check: ensure formation has enough positions
	if formation.size() < unit_selected.size():
		print("Warning: Formation only has ", formation.size(), " positions for ", unit_selected.size(), " units. Filling with grid.")
		# Fill remaining positions with grid formation
		var remaining = unit_selected.size() - formation.size()
		var offset = formation.size()
		for i in range(remaining):
			formation.append(tile_pos + Vector2i(i + offset, 0))
	
	for i in range(unit_selected.size()):
		if i < formation.size():
			unit_selected[i].move_to(layer.map_to_local(formation[i]))
		else:
			# Fallback: place unit near target
			unit_selected[i].move_to(target_world_pos + Vector2(i * 16, 0))
		
func select_in(group):
	for unit in get_tree().get_nodes_in_group("Unit"):
		if unit in group:
			unit.select()
		else:
			unit.deselect()

func _on_formation_changed(formation_type: String) -> void:
	current_formation = formation_type
	print("Formation changed to: ", current_formation)
