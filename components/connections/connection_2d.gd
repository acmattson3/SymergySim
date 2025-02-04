extends Line2D
class_name Connection2D

var connection_a: BaseComponent = null
var connection_b: BaseComponent = null

func update_color():
	var voltage = LoadManager.get_current_voltage()
	
	if voltage == 0:
		default_color = Color.BLACK  # ⚫ Off/Disconnected
	elif voltage < 100:
		default_color = Color.BLUE   # 🔵 Critical - Too Low
	elif voltage <= 113:
		default_color = lerp_color(Color.BLUE, Color.GREEN, inverse_lerp(100, 113, voltage))  # Blend Blue → Green
	elif voltage <= 120:
		default_color = lerp_color(Color.GREEN, Color.YELLOW, inverse_lerp(114, 120, voltage))  # Blend Green → Yellow
	elif voltage <= 126:
		default_color = Color.YELLOW  # 🟡 Stable Yellow (Normal range)
	elif voltage <= 130:
		default_color = lerp_color(Color.YELLOW, Color.ORANGE, inverse_lerp(127, 130, voltage))  # Blend Yellow → Orange
	elif voltage <= 135:
		default_color = Color.ORANGE  # 🟠 Stable Orange (Warning - High)
	else:
		default_color = lerp_color(Color.ORANGE, Color.RED, inverse_lerp(136, 145, voltage))  # Blend Orange → Red

# Helper function for smooth color blending
func lerp_color(color1: Color, color2: Color, factor: float) -> Color:
	return color1.lerp(color2, clamp(factor, 0.0, 1.0))

var update_color_interval := 0.25
var update_color_elapsed := 0.25
func _physics_process(delta: float):
	if not (connection_a and connection_b):
		return
	update_color_elapsed += delta
	
	if update_color_elapsed >= update_color_interval:
		update_color_elapsed = 0.0
		update_color()
