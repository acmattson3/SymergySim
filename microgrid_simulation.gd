extends Node2D

# TODO: Add:
# * Battery
# * Pole (without transformer)
# * Pole with Transformer (into other voltages) (acts as a load/source to main grid)

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

func _ready() -> void:
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
			-(positions[i].y - avg_lat)
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
			connection.connection_a = component
			connection.connection_b = connected_component
			connection.default_color = Color.YELLOW
			connection.points = PackedVector2Array([connection.connection_a.global_position, connection.connection_b.global_position])
			
			# Add to scene and track it
			$Components.add_child(connection)
			connection.reparent($Components)  # Ensure it's inside $Components
			existing_connections[connection_key] = connection

# Helper function to create a unique key for each connection
func get_connection_key(a: BaseComponent, b: BaseComponent) -> String:
	var sorted_ids = [a.id, b.id]
	sorted_ids.sort()  # Ensures order-independent key
	return sorted_ids[0]+"-"+sorted_ids[1]

func _on_received_message(_topic, _msg):
	pass # For receiving component updates
