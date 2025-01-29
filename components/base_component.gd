extends Node2D
class_name BaseComponent

enum ComponentType { NONE, GENERATOR }

# Component information
@export var id: StringName = ""
@export var type: ComponentType = ComponentType.NONE
# name property acts as component name
@export var latitude: String = "0.0"
@export var longitude: String = "0.0"
@export var altitude: String = "0.0"
var connections: Array = []

func get_component_info():
	var formatted_info = {
	  "id": id,
	  "type": get_type_string(),
	  "name": name,
	  "coordinates": {"lat": latitude.to_float(), "lon": longitude.to_float(), "alt": altitude.to_float()},
	  "connections": connections
	}
	return formatted_info

func get_type_string():
	match type:
		ComponentType.GENERATOR:
			return "generator"
		_:	
			return "none"
