extends BaseComponent
class_name SourceComponent

@export var max_power_rating: float = 1.0  # kW
@onready var max_power_out: float = max_power_rating

# PID controller gains.
@export var Kp: float = 2.0
@export var Ki: float = 1.0
@export var Kd: float = 0.1

var integrated_error: float = 0.0
var previous_error: float = 0.0
var working_voltage: float = 0.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	#current_power = (working_voltage*current_demand)/1000.0
	# Compute the voltage error: how far below nominal we are.
	working_voltage = VoltageManager.get_current_voltage()
	current_demand = (current_power*1000.0)/working_voltage if working_voltage > 0.0 else 0.0
	var error = nominal_voltage - working_voltage
	
	# Update the PID controller's integral and derivative terms.
	integrated_error += error * delta
	integrated_error = clamp(integrated_error, -max_power_out/Ki, max_power_out/Ki)
	var derivative = (error - previous_error) / max(delta, 0.00001)
	previous_error = error
	
	# Calculate the control signal (i.e. desired power injection in kW).
	var control_signal = Kp * error + Ki * integrated_error + Kd * derivative
	
	# Only inject power when voltage is low, and clamp to the renewable's maximum capacity.
	var added_power = clamp(control_signal, 0, max_power_out)
	
	# Assume a simple linear relationship: the injected power increases the voltage.
	# 'scale_factor' translates kW to voltage correction (example value).
	var scale_factor = 0.42
	VoltageManager.change_voltage(scale_factor * added_power)
	
	current_power = added_power
