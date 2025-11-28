extends CharacterBody2D
class_name Unit

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D  # Reference to sprite (optional)

var speed: int = 50
var rotation_speed: float = 8.0  # Rotation interpolation speed

var selection_rect : Rect2
var selection_width : int
var unit_name: String = "Unit"

# Movement state
enum State { IDLE, MOVING }
var current_state: State = State.IDLE
var current_direction: Vector2 = Vector2.DOWN
var target_rotation: float = 0.0

# Rotation settings
var snap_rotation: bool = false  # Set to true for 8-directional rotation like AoE2
var rotation_angles: Array = [0, 45, 90, 135, 180, -135, -90, -45]  # 8 directions

# select_mode: setter flag variable for selection of unit
var select_mode : bool = false:
	set(value):
		select_mode = value
		if value:
			selection_rect = Rect2(Vector2(-8,-8), Vector2(16, 16))
			selection_width = 1
		else:
			selection_rect = Rect2(0,0,0,0)
			selection_width = 0
		queue_redraw()

func _ready() -> void:
	name = unit_name
	input_pickable = true
	
	# Set navigation agent properties for smoother movement
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0

# func draw
func _draw() -> void:
	draw_rect(selection_rect, Color.GREEN, false, selection_width)

func _physics_process(delta: float) -> void:
	# Check if unit reached destination
	if nav_agent.is_navigation_finished():
		if current_state == State.MOVING:
			current_state = State.IDLE
			velocity = Vector2.ZERO
		return

	current_state = State.MOVING
	
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	
	# Update rotation based on movement direction
	if direction.length() > 0.01:
		update_rotation(direction, delta)
	
	# Move the unit
	velocity = direction * speed
	move_and_slide()

func update_rotation(direction: Vector2, delta: float) -> void:
	"""Update unit rotation to face movement direction"""
	
	# Calculate target angle from direction
	var angle = direction.angle()
	
	if snap_rotation:
		# Snap to nearest 8-direction (like AoE2)
		angle = get_nearest_direction_angle(angle)
	
	# Smoothly interpolate to target rotation
	if sprite:
		# Rotate sprite only
		sprite.rotation = lerp_angle(sprite.rotation, angle, rotation_speed * delta)
	else:
		# Rotate entire body
		rotation = lerp_angle(rotation, angle, rotation_speed * delta)

func get_nearest_direction_angle(angle: float) -> float:
	"""Snap angle to nearest 8-directional angle (AoE2 style)"""
	var angle_deg = rad_to_deg(angle)
	var nearest_angle = 0.0
	var min_difference = 360.0
	
	for dir_angle in rotation_angles:
		var difference = abs(angle_deg - dir_angle)
		if difference < min_difference:
			min_difference = difference
			nearest_angle = dir_angle
	
	return deg_to_rad(nearest_angle)

# select()
func select() -> void:
	select_mode = true

# deselect()
func deselect() -> void:
	select_mode = false

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Deselect all other units
			for unit in UnitManager.unit_selected:
				if unit != self:
					unit.deselect()
			
			# Select this unit
			select_mode = true
			UnitManager.unit_selected = [self]
			
			# Mark event as handled so selection box doesn't trigger
			get_viewport().set_input_as_handled()

func move_to(target_position):
	nav_agent.target_position = target_position
	current_state = State.MOVING
