extends SourceComponent
class_name Renewable

enum RenewableType { NONE, SOLAR, WIND, HYDRO }
@export var renewable_type: RenewableType = RenewableType.NONE

var update_interval := 10.0
var update_elapsed  := 10.0
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	update_elapsed += delta
	if update_elapsed >= update_interval:
		update_elapsed = 0.0
		match renewable_type:
			RenewableType.SOLAR:
				max_power_out = max_power_rating*get_solar_radiation(get_latitude(), get_longitude())
			RenewableType.WIND:
				var efficiency = 0.4 # Efficiency factor
				var power_coefficient = 0.5 * efficiency
				max_power_out = max_power_rating * power_coefficient * pow(get_wind_speed(), 3)
			RenewableType.HYDRO:
				var flow = get_hydro_flow()
				var efficiency = 0.8
				var gravity = 9.81
				var head_height = 2.0 # Height of water fall (m)
				max_power_out = efficiency * flow * gravity * head_height
				#print("Attempted power: ", efficiency * flow * gravity * head_height)
				#print("Current power: ", max_power_out)
				#print("Current percent of max: ", max_power_out/max_power_rating)
			_:
				pass

func get_wind_speed() -> float:
	# Wind speed fluctuates with time of day, random variations, and max radiation
	var base_speed = 1.2 + 1.2 * get_solar_radiation(get_latitude(), get_longitude()) # Scaled to typical values
	var random_variation = 0.3*randf_range(-1.0, 1.0) # Random gusts
	return max(base_speed + random_variation, 0.0) # Ensure non-negative wind speed

func get_hydro_flow() -> float:
	# Base flow with additional water from solar radiation (simulating snowmelt)
	var base_flow = 5.0 + 0.3*randf_range(-1.0, 1.0) # Base river flow rate
	var extra_flow = 2.0 * get_solar_radiation(get_latitude(), get_longitude()) # Scale influence of sunlight
	return base_flow + extra_flow

func get_solar_radiation(lat: float, lon: float) -> float:
	var solar_angle = get_solar_angle(lat, lon)
	#print(solar_angle)
	if solar_angle <= 0.0:
		return 0.0  # No sunlight if the sun is below the horizon
	return sin(deg_to_rad(solar_angle))  # Normalize intensity from 0.0 to 1.0

func get_solar_angle(lat: float, lon: float) -> float:
	var datetime = Time.get_datetime_dict_from_system()
	var year = datetime.year
	var month = datetime.month
	var day = datetime.day
	var hour = datetime.hour
	var minute = datetime.minute
	var second = datetime.second

	# Convert local time (system time) to UTC
	var utc_offset = Time.get_time_zone_from_system().bias / 60.0  # Convert minutes to hours
	var utc_hour = hour - utc_offset
	if utc_hour < 0:
		day -= 1  # Adjust for previous day if necessary
		utc_hour += 24
	elif utc_hour >= 24:
		day += 1  # Adjust for next day if necessary
		utc_hour -= 24

	# Get day of the year
	var N = get_day_of_year(year, month, day) + (utc_hour + minute / 60.0 + second / 3600.0) / 24.0

	# Earth's axial tilt (obliquity of the ecliptic)
	var obliquity = deg_to_rad(23.44)

	# Solar Mean Anomaly (approximate position of the sun in orbit)
	var M = deg_to_rad(357.5291 + 0.98560028 * N)

	# Equation of Center (correction for elliptical orbit)
	var C = deg_to_rad(1.9148) * sin(M) + deg_to_rad(0.02) * sin(2 * M) + deg_to_rad(0.0003) * sin(3 * M)

	# True Solar Longitude
	var lambda_sun = deg_to_rad(280.4665 + 0.98564736 * N) + C

	# Solar Declination (latitude where the sun is directly overhead)
	var declination = asin(sin(obliquity) * sin(lambda_sun))

	# Equation of Time (correction for solar time)
	var y = pow(tan(obliquity / 2.0), 2)
	var EoT = 4 * rad_to_deg(y * sin(2 * lambda_sun) - 2 * 0.0167 * sin(M) + 
							4 * 0.0167 * y * sin(M) * cos(2 * lambda_sun) - 
							0.5 * pow(y, 2) * sin(4 * lambda_sun) - 
							1.25 * pow(0.0167, 2) * sin(2 * M))

	# Compute Solar Noon (when the sun is highest in the sky)
	var solar_noon = 12.0 - (lon / 15.0) - (EoT / 60.0)

	# Compute Hour Angle (HA)
	var solar_time = utc_hour + minute / 60.0 + second / 3600.0
	var hour_angle = deg_to_rad(15.0 * (solar_time - solar_noon))

# Convert latitude to radians
	var lat_rad = deg_to_rad(lat)
	
	# Calculate Solar Altitude Angle (θ)
	var solar_altitude = asin(sin(lat_rad) * sin(declination) + 
 							   cos(lat_rad) * cos(declination) * cos(hour_angle))
	
	return rad_to_deg(solar_altitude)  # Convert result to degrees

func get_day_of_year(year: int, month: int, day: int) -> int:
	var days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	
	# Leap year check
	if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
		days_in_month[1] = 29  # February has 29 days in a leap year
	
	var day_of_year = 0
	for i in range(month - 1):
		day_of_year += days_in_month[i]
	
	return day_of_year + day

func get_category() -> String:
	match renewable_type:
		RenewableType.SOLAR:
			return "solar"
		RenewableType.WIND:
			return "wind"
		RenewableType.HYDRO:
			return "hydro"
		_:
			return "none"
