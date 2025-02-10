extends Node

var current_voltage := 0.0:
	set(value):
		current_voltage = max(0.0, value)
var avg_voltage := 0.0

var print_elapsed: float = 0.5
var print_interval: float = 0.5
var time: float = 0.0
func _process(delta: float) -> void:
	print_elapsed += delta
	if print_elapsed >= print_interval:
		print_elapsed = 0.0
		print("Avg: ", avg_voltage)

func _physics_process(delta: float) -> void:
	time += delta
	avg_voltage = closest_voltage + 0.1*sin(0.1*time)

var curr_diff := 1000.0
var closest_voltage := 0.0
func change_voltage(value: float) -> void:
	current_voltage = lerpf(current_voltage, current_voltage+value, 0.55)
	var new_diff = abs(current_voltage - 120.0)
	if new_diff < curr_diff:
		curr_diff = new_diff
		closest_voltage = current_voltage

func get_current_voltage():
	return current_voltage

func get_average_voltage():
	return avg_voltage
