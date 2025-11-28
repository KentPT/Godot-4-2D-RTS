extends Control

enum BuildingType {
	Farm,
	Barracks,
	Stable,
	Townhall,
	Lumbermill,
	Dock,
	Houses
}

enum FormationType {
	Grid,
	Line,
	Wedge,
	Square,
	Triangle,
	Split
}

# Buildings left side
@onready var building_1: Button = %Building1
@onready var building_2: Button = %Building2
@onready var building_3: Button = %Building3
@onready var building_4: Button = %Building4

# Label above 
@onready var wood: Label = %Wood
@onready var food: Label = %Food
@onready var gold: Label = %Gold
@onready var stone: Label = %Stone
@onready var population: Label = %Population

# Formation testing for units
@onready var grid: Button = %Grid
@onready var line: Button = %Line
@onready var wedge: Button = %Wedge
@onready var square: Button = %Square
@onready var triangle: Button = %Triangle

# Resources
var resources = {
	"wood": 100,
	"food": 100,
	"gold": 100,
	"stone": 100,
	"population": 0,
	"max_population": 10
}

# Current selected formation
var selected_formation: String = "grid"

# Building definitions (source_id, atlas_coords)
var building_data = {
	BuildingType.Farm: {"source_id": 0, "atlas_coords": Vector2i(0, 12), "name": "Farm"},
	BuildingType.Barracks: {"source_id": 0, "atlas_coords": Vector2i(3, 6), "name": "Barracks"},
	BuildingType.Stable: {"source_id": 0, "atlas_coords": Vector2i(3, 3), "name": "Stable"},
	BuildingType.Townhall: {"source_id": 0, "atlas_coords": Vector2i(3, 0), "name": "Townhall"}
}

func _ready() -> void:
	# Connect building signals
	EventSystem.building_build.connect(_on_building_built)
	EventSystem.resource_changed.connect(_on_resource_changed)
	
	# Connect building buttons
	building_1.pressed.connect(_on_building_1_pressed)
	building_2.pressed.connect(_on_building_2_pressed)
	building_3.pressed.connect(_on_building_3_pressed)
	building_4.pressed.connect(_on_building_4_pressed)
	
	# Connect formation buttons
	grid.pressed.connect(_on_grid_pressed)
	line.pressed.connect(_on_line_pressed)
	wedge.pressed.connect(_on_wedge_pressed)
	square.pressed.connect(_on_square_pressed)
	triangle.pressed.connect(_on_triangle_pressed)
	
	# Prevent buttons from stealing focus and deselecting units
	building_1.focus_mode = Control.FOCUS_NONE
	building_2.focus_mode = Control.FOCUS_NONE
	building_3.focus_mode = Control.FOCUS_NONE
	building_4.focus_mode = Control.FOCUS_NONE
	
	grid.focus_mode = Control.FOCUS_NONE
	line.focus_mode = Control.FOCUS_NONE
	wedge.focus_mode = Control.FOCUS_NONE
	square.focus_mode = Control.FOCUS_NONE
	triangle.focus_mode = Control.FOCUS_NONE
	
	# Update UI
	update_resource_labels()
	update_formation_buttons()

func _process(_delta: float) -> void:
	pass

# Building button callbacks
func _on_building_1_pressed() -> void:
	select_building(BuildingType.Farm)

func _on_building_2_pressed() -> void:
	select_building(BuildingType.Barracks)

func _on_building_3_pressed() -> void:
	select_building(BuildingType.Stable)

func _on_building_4_pressed() -> void:
	select_building(BuildingType.Townhall)

func select_building(building_type: BuildingType) -> void:
	var data = building_data[building_type]
	print("Selected building: ", data["name"])
	# Emit signal to start building placement mode with preview
	EventSystem.building_selected.emit(building_type, data["source_id"], data["atlas_coords"])

# Formation button callbacks
func _on_grid_pressed() -> void:
	selected_formation = "grid"
	EventSystem.formation_changed.emit("grid")
	update_formation_buttons()
	print("Formation changed to: Grid")

func _on_line_pressed() -> void:
	selected_formation = "line"
	EventSystem.formation_changed.emit("line")
	update_formation_buttons()
	print("Formation changed to: Line")

func _on_wedge_pressed() -> void:
	selected_formation = "wedge"
	EventSystem.formation_changed.emit("wedge")
	update_formation_buttons()
	print("Formation changed to: Wedge")

func _on_square_pressed() -> void:
	selected_formation = "square"
	EventSystem.formation_changed.emit("square")
	update_formation_buttons()
	print("Formation changed to: Square")

func _on_triangle_pressed() -> void:
	selected_formation = "triangle"
	EventSystem.formation_changed.emit("triangle")
	update_formation_buttons()
	print("Formation changed to: Triangle")

func update_formation_buttons() -> void:
	# Visual feedback for selected formation
	grid.disabled = (selected_formation == "grid")
	line.disabled = (selected_formation == "line")
	wedge.disabled = (selected_formation == "wedge")
	square.disabled = (selected_formation == "square")
	triangle.disabled = (selected_formation == "triangle")

# Building built callback
func _on_building_built() -> void:
	print("Building built!")
	# You can track which building was built and deduct resources here
	
# Resource changed callback
func _on_resource_changed(resource_type: String, amount: int) -> void:
	if resource_type in resources:
		resources[resource_type] += amount
		update_resource_labels()

func update_resource_labels() -> void:
	wood.text = "Wood: " + str(resources["wood"])
	food.text = "Food: " + str(resources["food"])
	gold.text = "Gold: " + str(resources["gold"])
	stone.text = "Stone: " + str(resources["stone"])
	population.text = "Pop: " + str(resources["population"]) + "/" + str(resources["max_population"])

# Call this to add resources (e.g., from a timer or building production)
func add_resource(resource_type: String, amount: int) -> void:
	EventSystem.resource_changed.emit(resource_type, amount)
