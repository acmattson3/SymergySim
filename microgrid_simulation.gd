extends Node2D

# TODO: Add:
# * Renewables (solar, wind, hydro(?))
# * Battery
# * Meter

func _ready() -> void:
	draw_connections()
	
	MQTTHandler.broker_connected.connect(_on_broker_connected)
	MQTTHandler.received_message.connect(_on_received_message)
	MQTTHandler.broker_connection_failed.connect(_on_broker_connection_failed)
	MQTTHandler.published_messages.connect(_on_published_messages)
	
	MQTTHandler.connect_to_broker("tcp://test.mosquitto.org:1883")

func _on_published_messages(messages):
	pass
	#for message in messages:
	#	print(message)

func publish_meterstructure(components_list):
	var payload = {
		"components": components_list
	}
	
	var json_payload = JSON.stringify(payload)
	
	# Publish to MQTT with retain=true
	MQTTHandler.publish("symergygrid/meterstructure", json_payload, true)

func _on_broker_connected() -> void:
	print("Connected to broker!")
	var components_list = []
	for child in $Components.get_children():
		if child is not BaseComponent:
			return
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

func _on_received_message(topic, msg):
	pass # For receiving component updates
