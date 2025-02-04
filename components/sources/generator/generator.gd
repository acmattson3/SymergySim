extends SourceComponent
class_name Generator

enum FuelType { NONE, DIESEL, GASOLINE }
@export var fuel_type: FuelType = FuelType.NONE

var time: float = 0.0
@export var available_capacity_kw: float = 100.0  # Max generator capacity

func _physics_process(delta: float) -> void:
	time += delta
	
	# Get the current total load demand
	var total_demand_kw = LoadManager.get_total_demand()
	
	# Adjust generator output based on demand (cannot exceed max capacity)
	var supplied_power = min(total_demand_kw, available_capacity_kw)
	var power_overflow = total_demand_kw - supplied_power # How much power we can't provide
	
	# Simulate voltage fluctuation (within normal range)
	voltage = 120.0 + 0.2*sin(0.1*time) - 8.0*(power_overflow/(0.1*available_capacity_kw)) # Max voltage drop at +10% rated capacity
	LoadManager.set_current_voltage(voltage)
	
	# Adjust current based on power demand (P = VI -> I = P/V)
	demand = (supplied_power * 1000.0) / voltage
	
	# Send MQTT messages
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "demand"), JSON.stringify({"value": demand, "unit": "A"}))
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "voltage"), JSON.stringify({"value": voltage, "unit": "V"}))
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "power"), JSON.stringify({"value": supplied_power, "unit": "kW"}))
	
	# Energy accumulates over time
	energy = supplied_power * delta * 3600
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "energy"), JSON.stringify({"value": energy, "unit": "kWh"}))
	
	# Generator status (turn off if it can't meet demand)
	status = supplied_power > 0.0
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "status"), JSON.stringify({"value": status, "unit": "bool"}))
