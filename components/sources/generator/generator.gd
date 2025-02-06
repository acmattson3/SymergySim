extends SourceComponent
class_name Generator

enum FuelType { NONE, DIESEL, GASOLINE }
@export var fuel_type: FuelType = FuelType.NONE
var gallons_fuel_consumed := 0.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	gallons_fuel_consumed = current_energy*0.11
