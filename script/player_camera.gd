extends Camera2D
class_name PlayerCamera

# edge margin: if the mouse go to the edge it will move the camera
var edge_margin: int = 7 
var camera_speed: float = 200.0
var map_size: Vector2 = Vector2(1920, 1080)
var viewport_size: Vector2 = Vector2(480, 240)
var un_zoomed_viewport_size: Vector2 = Vector2(480, 240)
var zoom_x: float = 0.8
var zoom_y: float = 0.8

var mouse_position: Vector2
var pre_zoom_value: Vector2  # Added missing variable

# Zoom limits
var min_zoom: float = 0.8
var max_zoom: float = 4.0
var zoom_step: float = 0.25

func _ready() -> void:
	# Set initial zoom
	zoom = Vector2(zoom_x, zoom_y)
	
	# Enable camera limits (optional but recommended)
	limit_left = 0
	limit_top = 0
	limit_right = int(map_size.x)
	limit_bottom = int(map_size.y)

func _process(delta: float) -> void:
	# Edge scrolling
	mouse_position = get_viewport().get_mouse_position()
	var move_vector = Vector2.ZERO
	
	if mouse_position.x <= edge_margin:
		move_vector.x = -camera_speed * delta
	elif mouse_position.x >= un_zoomed_viewport_size.x - edge_margin:
		move_vector.x = camera_speed * delta
		
	if mouse_position.y <= edge_margin:
		move_vector.y = -camera_speed * delta
	elif mouse_position.y >= un_zoomed_viewport_size.y - edge_margin:
		move_vector.y = camera_speed * delta
	
	# arrow key movement:
	if Input.is_action_pressed("Arrow_left"):
		move_vector.x = -camera_speed * delta
	if Input.is_action_pressed("Arrow_right"):
		move_vector.x = camera_speed * delta
		
	if Input.is_action_pressed("Arrow_up"):
		move_vector.y = -camera_speed * delta
	if Input.is_action_pressed("Arrow_down"):
		move_vector.y = camera_speed * delta
	
	position += move_vector
	
	# Clamp camera position to map bounds
	var half_viewport = (un_zoomed_viewport_size / zoom) / 2
	position.x = clamp(position.x, half_viewport.x, map_size.x - half_viewport.x)
	position.y = clamp(position.y, half_viewport.y, map_size.y - half_viewport.y)

func _input(event: InputEvent) -> void:
	# Zoom out (scroll down)
	if event.is_action_pressed("MouseWheelDown"):
		if zoom_x > min_zoom:
			mouse_position = get_viewport().get_mouse_position()
			pre_zoom_value = zoom
			zoom_x -= zoom_step
			zoom_y -= zoom_step
			zoom_x = max(zoom_x, min_zoom)  # Clamp to minimum
			zoom_y = max(zoom_y, min_zoom)
			zoom = Vector2(zoom_x, zoom_y)
			# Zoom towards mouse position
			position += (mouse_position - position) * (Vector2.ONE - pre_zoom_value / zoom)
	
	# Zoom in (scroll up) - Fixed: this was incorrectly nested before
	elif event.is_action_pressed("MouseWheelUp"):
		if zoom_x < max_zoom:
			mouse_position = get_viewport().get_mouse_position()
			pre_zoom_value = zoom
			zoom_x += zoom_step
			zoom_y += zoom_step
			zoom_x = min(zoom_x, max_zoom)  # Clamp to maximum
			zoom_y = min(zoom_y, max_zoom)
			zoom = Vector2(zoom_x, zoom_y)
			# Zoom towards mouse position
			position += (mouse_position - position) * (Vector2.ONE - pre_zoom_value / zoom)
