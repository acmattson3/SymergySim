extends SourceComponent
class_name Generator

enum FuelType { NONE, DIESEL, GASOLINE, NATURAL_GAS, COAL }
@export var fuel_type: FuelType = FuelType.NONE
var fuel_consumed := 0.0
@onready var consumption_unit: String = ["null", "gal", "gal", "gal", "kg"][fuel_type]

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	match fuel_type:
		FuelType.DIESEL, FuelType.GASOLINE:
			fuel_consumed = current_energy*0.11
		_:
			pass

func get_category() -> String:
	match fuel_type:
		FuelType.DIESEL:
			return "diesel"
		FuelType.GASOLINE:
			return "gasoline"
		FuelType.NATURAL_GAS:
			return "natural_gas"
		FuelType.COAL:
			return "coal"
		_:
			return "none"
