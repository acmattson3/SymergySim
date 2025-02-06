extends Node2D
class_name BaseComponent

enum ComponentType { NONE, SOURCE, LOAD }

# Nominal grid parameters.
var nominal_voltage: float = 120.0
var droop_coefficient: float = 2.0  # How much voltage drops per unit of demand.

# Current grid info.
var current_voltage: float = 0.0 # V
var current_demand: float  = 0.0 # A
var current_power: float   = 0.0 # kW
var current_energy: float  = 0.0 # kWh
var current_status: bool = true

@export var latitude := "0.0"
@export var longitude := "0.0"

var queue_interval := 1.0
var queue_elapsed := 0.0
func _process(delta: float) -> void:
	queue_elapsed += delta
	if queue_elapsed >= queue_interval:
		queue_elapsed = 0.0
		MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "voltage"), JSON.stringify({"value": current_voltage, "unit": "V"}))
		MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "demand"), JSON.stringify({"value": current_demand, "unit": "A"}))
		MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "power"), JSON.stringify({"value": current_power, "unit": "kW"}))
		MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "energy"), JSON.stringify({"value": current_energy, "unit": "kWh"}))
		MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "status"), JSON.stringify({"value": current_status, "unit": "bool"}))

func _physics_process(delta: float) -> void:
	current_energy += current_power*(delta/3600.0)

func get_latitude():
	return latitude.to_float()
func get_longitude():
	return longitude.to_float()

# Component information
@export var id: StringName = ""
@export var type: ComponentType = ComponentType.NONE
# name property acts as component name
@export var connections: Array[BaseComponent] = []

func get_connections() -> Array[BaseComponent]:
	return connections

func get_component_info() -> Dictionary:
	var formatted_connections = []
	for connection in connections:
		formatted_connections.append(connection.get_id())
	
	var formatted_info = {
	  "id": id,
	  "type": get_type_string(),
	  "name": name,
	  "coordinates": {"lat": get_latitude(), "lon": get_longitude(), "alt": 0.0},
	  "connections": formatted_connections
	}
	return formatted_info

func get_type_string() -> String:
	match type:
		ComponentType.SOURCE:
			return "source"
		ComponentType.LOAD:
			return "load"
		_:	
			return "none"

func get_id() -> String:
	return id
