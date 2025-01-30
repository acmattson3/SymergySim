extends Node

const BASE_TOPIC = "symergygrid/"

func get_component_topic(component_id: String, category: String, metric: String = "") -> String:
	var topic = BASE_TOPIC+"components/"+component_id+"/"+category
	topic += "/"+metric if metric != "" else ""
	return topic
