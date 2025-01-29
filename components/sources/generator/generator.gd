extends SourceComponent
class_name Generator

enum FuelType { NONE, DIESEL, GASOLINE }
@export var fuel_type: FuelType = FuelType.NONE

var time: float = 0.0
func _physics_process(delta: float) -> void:
	time += delta
	
	var test_demand = 200.0 + 50.0 * (sin(0.15 * time) + cos(0.1 * 1.8 * time))
	var demand_payload = JSON.stringify({"value": test_demand, "unit": "A"})
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "demand"), demand_payload)
	
	var test_voltage = 120.0 + 2.0 * (sin(0.2 * time) + cos(0.14 * 1.62 * time))
	var voltage_payload = JSON.stringify({"value": test_voltage, "unit": "V"})
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "voltage"), voltage_payload)
	
	var test_power = (test_voltage*test_demand)/1000.0
	var power_payload = JSON.stringify({"value": test_power, "unit": "kW"})
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "power"), power_payload)
	
	var test_energy = 15000.0 + 500.0 * (sin(0.05 * time) + cos(0.02 * 2.3 * time))
	var energy_payload = JSON.stringify({"value": test_energy, "unit": "kWh"})
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "energy"), energy_payload)
	
	var test_status = true
	var status_payload = JSON.stringify({"value": test_status, "unit": "bool"})
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "status"), status_payload)
	
