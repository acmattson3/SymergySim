extends Node

var current_voltage := 0.0:
	set(value):
		current_voltage = max(0.0, value)
var avg_voltage := 0.0

#var print_elapsed: float = 0.25
#var print_interval: float = 0.25
#func _process(delta: float) -> void:
	#print_elapsed += delta
	#if print_elapsed >= print_interval:
		#print_elapsed = 0.0
		#print(current_voltage)

func _physics_process(delta: float) -> void:
	avg_voltage = current_voltage

func change_voltage(value: float) -> void:
	current_voltage = lerpf(current_voltage, current_voltage+value, 0.5)

func get_current_voltage():
	return current_voltage

func get_average_voltage():
	return avg_voltage
