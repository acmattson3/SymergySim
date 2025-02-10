extends BaseComponent
class_name LoadComponent

signal demand_change(new_demand: float)

@export var base_demand_kw := 50.0
@export var fluctuation := 20.0
@export var pull_coefficient: float = 0.05  # Voltage drop per kW of load

@onready var try_change_demand_interval: float = 30.0 + randf_range(0.0, 15.0)
@onready var try_change_demand_elapsed: float = try_change_demand_interval

var add_fluctuation = false
@onready var time: float = randf_range(0.0, 45.0)
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	time += delta
	try_change_demand_elapsed += delta
	
	# Calculate the instantaneous load (in kW)
	current_demand = base_demand_kw + 2.0*sin(0.1 * time)
	current_demand += fluctuation if add_fluctuation else 0.0
	# Every set time, check if fluctuation is added.
	if try_change_demand_elapsed >= try_change_demand_interval:
		try_change_demand_elapsed = 0.0
		add_fluctuation = true if randf() < 0.5 else false

	# Compute the voltage drop caused by this load.
	# (For example, if pull_coefficient is 0.05 V per kW, a 60 kW load pulls down 3 V.)
	var voltage_diff = pull_coefficient * current_demand
	VoltageManager.change_voltage(-voltage_diff)
	
	# Update power (for debug/visualization, for example).
	current_power = (current_demand * current_voltage) / 1000.0
