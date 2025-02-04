extends Node

var total_demand_kw: float = 0.0  # Sum of all load demands

signal add_load(component: LoadComponent)
var loads := []

func _ready():
	add_load.connect(_on_add_load)

var time := 0.0
var update_elapsed := 0.25
var update_interval := 0.25
func _physics_process(delta: float) -> void:
	time += delta
	update_elapsed += delta

func _on_add_load(component: LoadComponent):
	if component not in loads:
		loads.append(component)

# Update total demand (called by loads)
func update_total_demand():
	if not update_elapsed >= update_interval:
		return
	update_elapsed = 0.0
	
	total_demand_kw = 0.0
	for load: LoadComponent in loads:
		total_demand_kw += load.get_current_load()

# Return the total demand (used by generators)
func get_total_demand() -> float:
	update_total_demand()
	return total_demand_kw

var current_voltage := 0.0
func get_current_voltage() -> float:
	return current_voltage

func set_current_voltage(voltage: float):
	current_voltage = voltage
