extends BaseComponent
class_name Pole

func get_category():
	return "poles"

#func _ready() -> void:
	#id = name

#var calc_values_interval := 0.25 + randf_range(0.0, 0.5)
#var calc_values_elapsed := 0.75
#func _physics_process(delta: float) -> void:
	#calc_values_elapsed += delta
	#if calc_values_elapsed >= calc_values_interval:
		#calc_values_elapsed = 0.0
		#current_voltage = VoltageManager.get_current_voltage()
		#
		#var all_poles: bool = true
		#for component: BaseComponent in connections:
			#if component is not Pole:
				#all_poles = false
				#break
		#
		#if all_poles:
			#var max_voltage := 0.0
			#for component in connections:
				#if component.current_voltage >= max_voltage:
					#max_voltage = component.current_voltage
			#current_voltage = max_voltage
		#else:
			## Average connected values
			#var all_voltages := 0.0
			#var all_demands := 0.0
			#var all_powers := 0.0
			#for component: BaseComponent in connections:
				#all_voltages += component.current_voltage
				#all_demands += component.current_demand
				#all_powers += component.current_power
			#current_voltage = all_voltages / float(len(connections))
			#current_demand = all_demands / float(len(connections))
			#current_power = all_powers / float(len(connections))
