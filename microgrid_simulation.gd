extends Node2D

# TODO: Add:
# * Renewables (solar, wind, hydro(?))
# * Battery
# * Meter

func _ready() -> void:
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
		components_list.append(child.get_component_info())
	publish_meterstructure(components_list)

func _on_broker_connection_failed():
	print("Broker connection failed!")
	MQTTHandler.connect_to_broker("tcp://test.mosquitto.org:1883")

func _on_received_message(topic, msg):
	pass # For receiving component updates
