extends Node2D
class_name BaseComponent

enum ComponentType { NONE, GENERATOR, LOAD }

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
	  "coordinates": {"lat": global_position.x, "lon": global_position.y, "alt": 0.0},
	  "connections": formatted_connections
	}
	return formatted_info

func get_type_string() -> String:
	match type:
		ComponentType.GENERATOR:
			return "generator"
		ComponentType.LOAD:
			return "load"
		_:	
			return "none"

func get_id() -> String:
	return id
