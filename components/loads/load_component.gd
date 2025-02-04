extends BaseComponent
class_name LoadComponent

@export var base_demand_kw := 50.0
@export var fluctuation := 20.0
var demand := base_demand_kw
var voltage := 0.0

func _ready():
	LoadManager.add_load.emit(self)

var time: float = randf_range(0.0, 120.0)
func _physics_process(delta): # Can be overwritten by children
	voltage = LoadManager.get_current_voltage()
	
	time += delta
	demand = base_demand_kw + fluctuation * (sin(0.1 * time) + cos(0.08 * 1.5 * time))
	
	var demand_payload = JSON.stringify({"value": demand, "unit": "kW"})
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "power"), demand_payload)

func get_current_load():
	return demand
