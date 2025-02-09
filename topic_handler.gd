extends Node

const BASE_TOPIC = "symergygrid/"

func get_component_topic(component_id: String, type: String, category: String, metric: String = "") -> String:
	var topic = BASE_TOPIC+"components/"+type+"/"+component_id+"/"+category
	topic += "/"+metric if metric != "" else ""
	return topic
