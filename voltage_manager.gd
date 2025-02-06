extends Node

var current_voltage := 0.0:
	set(value):
		current_voltage = max(0.0, value)

func change_voltage(value: float) -> void:
	current_voltage = lerpf(current_voltage, current_voltage+value, 0.5)

func get_current_voltage():
	return current_voltage
