extends Node2D

# TODO: Add:
# * Battery
# * Pole with Transformer (into other voltages) (acts as a load/source to main grid)

@export var camera: Camera2D # Assign your Camera2D node in the inspector
@export var zoom_speed: float = 0.1  # Speed of zooming
@export var min_zoom: float = 0.5  # Minimum zoom level
@export var max_zoom: float = 3.0  # Maximum zoom level
@export var pan_speed: float = 2.0 # Pan speed multiplier

var dragging: bool = false
var prev_mouse_pos: Vector2

func _unhandled_input(event):
	if camera == null:
		return

	# Left-click drag to move camera
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			prev_mouse_pos = get_global_mouse_position()
	
	elif event is InputEventMouseMotion and dragging:
		var mouse_delta = pan_speed*(get_global_mouse_position() - prev_mouse_pos)
		camera.position = lerp(camera.position, camera.position-mouse_delta, 0.35)
		prev_mouse_pos = get_global_mouse_position()
	
	# Scroll to zoom
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom *= (1 - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= (1 + zoom_speed)

		# Clamp zoom level
		camera.zoom.x = clamp(camera.zoom.x, min_zoom, max_zoom)
		camera.zoom.y = clamp(camera.zoom.y, min_zoom, max_zoom)
		scale_component_icons()

var debugging := false
var debug_print_elapsed := 1.0
var debug_print_interval := 1.0
func _physics_process(delta: float) -> void:
	if debugging:
		debug_print_elapsed += delta
		if debug_print_elapsed >= debug_print_interval:
			debug_print_elapsed = 0.0
			for component in $Components.get_children():
				if component is BaseComponent:
					print(component.get_id(), " voltage: ", component.current_voltage)
					print(component.get_id(), " demand: ", component.current_demand)
					print(component.get_id(), " power: ", component.current_power)

const RENEWABLE_SCENE = "res://components/sources/renewable/renewable.tscn"
const GENERATOR_SCENE = "res://components/sources/generator/generator.tscn"
const LOAD_SCENE = "res://components/loads/load_component.tscn"
const POLE_SCENE = "res://components/transmission/pole.tscn"

func load_components_from_kml():
	var file_path = "res://stony_river.kml"  # Ensure this matches the file location
	var components = parse_kml(file_path)
	
	if components.is_empty():
		print("No valid components found in KML.")
		return

	var root = get_tree().get_edited_scene_root()
	if not root:
		print("Error: No edited scene found.")
		return

	for component in components:
		var scene_path = get_scene_path(component["type"])
		if not scene_path:
			continue

		var instance = load(scene_path).instantiate()
		instance.id = component["name"]
		instance.name = component["name"]
		instance.latitude = str(component["latitude"])
		instance.longitude = str(component["longitude"])
		$Components.add_child(instance)
		instance.set_owner(root)  # Ensures the nodes can be saved
	
	print("Nodes successfully created in the editor.")
	
func parse_kml(file_path: String) -> Array:
	var results = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		print("Failed to open KML file!")
		return []
	
	var xml = XMLParser.new()
	xml.open_buffer(file.get_as_text().to_utf8_buffer())
	
	var current_component = {}
	var current_type = ""
	
	while xml.read() == OK:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				var node_name = xml.get_node_name()
				
				if node_name == "Folder":
					current_type = ""  # Reset type when entering a new folder
				elif node_name == "name" and current_type == "":
					xml.read()
					if xml.get_node_type() == XMLParser.NODE_TEXT:
						current_type = categorize_type(xml.get_node_data().strip_edges())
				elif node_name == "Placemark":
					current_component = {"type": current_type}
				elif node_name == "name":
					xml.read()
					if xml.get_node_type() == XMLParser.NODE_TEXT:
						current_component["name"] = xml.get_node_data().strip_edges()
				elif node_name == "coordinates":
					xml.read()
					if xml.get_node_type() == XMLParser.NODE_TEXT:
						var coords = xml.get_node_data().strip_edges()
						var parsed_coords = parse_coordinates(coords)
						var lat = parsed_coords[0]
						var lon = parsed_coords[1]
						current_component["latitude"] = lat
						current_component["longitude"] = lon
						results.append(current_component)
	
	return results

func categorize_type(folder_name: String) -> String:
	match folder_name.to_lower():
		"power":
			return "renewable"
		"generator":
			return "generator"
		"town_loads", "residential":
			return "load"
		"power_poles":
			return "pole"
		_:
			return ""

func parse_coordinates(coord_string: String) -> Array:
	var parts = coord_string.split(",")
	return [parts[1], parts[0]]

func get_scene_path(component_type: String) -> String:
	match component_type:
		"renewable":
			return RENEWABLE_SCENE
		"generator":
			return GENERATOR_SCENE
		"load":
			return LOAD_SCENE
		"pole":
			return POLE_SCENE
		_:
			return ""

func _ready() -> void:
	#load_components_from_kml() # Load the components in from the KML file
	#return
	position_components()
	draw_connections()
	
	MQTTHandler.broker_connected.connect(_on_broker_connected)
	MQTTHandler.received_message.connect(_on_received_message)
	MQTTHandler.broker_connection_failed.connect(_on_broker_connection_failed)
	MQTTHandler.published_messages.connect(_on_published_messages)
	
	MQTTHandler.connect_to_broker("tcp://test.mosquitto.org:1883")

func position_components():
	var components = $Components.get_children()
	if components.is_empty():
		return

	var sum_lat = 0.0
	var sum_lon = 0.0
	var positions = []

	# Collect lat/lon values
	for component in components:
		if component.has_method("get_latitude") and component.has_method("get_longitude"):
			var lat = component.get_latitude()
			var lon = component.get_longitude()
			sum_lat += lat
			sum_lon += lon
			positions.append(Vector2(lon, lat))
	
	# Compute average center
	var count = positions.size()
	if count == 0:
		return

	var avg_lat = sum_lat / count
	var avg_lon = sum_lon / count

	# Adjust positions relative to average
	var adjusted_positions = []
	for i in range(count):
		adjusted_positions.append(Vector2(
			positions[i].x - avg_lon,
			-2*(positions[i].y - avg_lat)
		))

	# Find bounding box
	var min_x = adjusted_positions[0].x
	var max_x = adjusted_positions[0].x
	var min_y = adjusted_positions[0].y
	var max_y = adjusted_positions[0].y

	for pos in adjusted_positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)

	var width = max_x - min_x
	var height = max_y - min_y

	# Get the size of the camera window
	var screen_size = get_viewport_rect().size
	var margin = 0.2  # 10% padding

	# Determine scale to fit within camera view
	var scale_x = (screen_size.x * (1 - margin)) / width if width > 0 else 1
	var scale_y = (screen_size.y * (1 - margin)) / height if height > 0 else 1
	var scale_factor = min(scale_x, scale_y)  # Maintain aspect ratio

	# Apply new positions
	for i in range(count):
		components[i].position = adjusted_positions[i] * scale_factor

func _on_published_messages(_messages):
	pass
	#for message in messages:
	#	print(message)

func publish_meterstructure(components_list):
	var payload = {
		"components": components_list
	}
	
	var json_payload = JSON.stringify(payload)
	if debugging:
		print("Publishing meterstructure: ")
		print(json_payload)
		print()
	# Publish to MQTT with retain=true
	MQTTHandler.publish("symergygrid/meterstructure", json_payload, true)

func _on_broker_connected() -> void:
	print("Connected to broker!")
	var components_list = []
	for child in $Components.get_children():
		if child is not BaseComponent:
			continue
		components_list.append(child.get_component_info())
	publish_meterstructure(components_list)

func _on_broker_connection_failed():
	print("Broker connection failed!")
	MQTTHandler.connect_to_broker("tcp://test.mosquitto.org:1883")

func draw_connections() -> void:
	var existing_connections := {}  # Dictionary to track created connections

	# Iterate over all BaseComponent children
	for component in $Components.get_children():
		if component is not BaseComponent:
			continue  # Skip non-BaseComponent nodes
		for connected_component in component.connections:
			if not connected_component or connected_component is not BaseComponent:
				continue  # Ensure valid connection
			
			# Create a unique key to prevent duplicate connections (order-independent)
			var connection_key = get_connection_key(component, connected_component)
			
			if connection_key in existing_connections:
				continue  # Connection already exists
			
			# Create and configure the Connection2D
			var connection = Connection2D.new()
			connection.width = 2
			connection.connection_a = component
			connection.connection_b = connected_component
			connection.default_color = Color.YELLOW
			connection.points = PackedVector2Array([connection.connection_a.global_position, connection.connection_b.global_position])
			
			# Add to scene and track it
			$Components.add_child(connection)
			#connection.reparent($Components)  # Ensure it's inside $Components
			existing_connections[connection_key] = connection

# Helper function to create a unique key for each connection
func get_connection_key(a: BaseComponent, b: BaseComponent) -> String:
	var sorted_ids = [a.id, b.id]
	sorted_ids.sort()  # Ensures order-independent key
	return sorted_ids[0]+"-"+sorted_ids[1]

func _on_received_message(_topic, _msg):
	pass # For receiving component updates

var base_scale = 0.25
func scale_component_icons():
	for component in $Components.get_children():
		if component is Line2D:
			continue
		var scale_factor: float = base_scale / camera.zoom.x
		component.scale_icon(scale_factor)
