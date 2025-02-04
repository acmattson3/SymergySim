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
	var test_voltage = 120.0 + 0.2*sin(0.1*time) - 8.0*(power_overflow/(0.1*available_capacity_kw)) # Max voltage drop at +10% rated capacity
	#print("Voltage: ", test_voltage)
	#print("Demand: ", total_demand_kw)
	#if test_voltage <= 112.0:
	#	print("Scary voltage!")
	
	# Adjust current based on power demand (P = VI -> I = P/V)
	var test_demand = (supplied_power * 1000.0) / test_voltage
	
	# Send MQTT messages
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "demand"), JSON.stringify({"value": test_demand, "unit": "A"}))
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "voltage"), JSON.stringify({"value": test_voltage, "unit": "V"}))
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "power"), JSON.stringify({"value": supplied_power, "unit": "kW"}))
	
	# Energy accumulates over time
	var test_energy = supplied_power * delta + 500.0 * (sin(0.05 * time) + cos(0.02 * 2.3 * time))
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "energy"), JSON.stringify({"value": test_energy, "unit": "kWh"}))
	
	# Generator status (turn off if it can't meet demand)
	var test_status = supplied_power > 0.0
	MQTTHandler.queue_message(TopicHandler.get_component_topic(id, "status"), JSON.stringify({"value": test_status, "unit": "bool"}))
