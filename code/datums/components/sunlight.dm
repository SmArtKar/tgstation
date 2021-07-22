/datum/component/sunlight

/datum/component/sunlight/Initialize()
	if(!isturf(parent))
		return COMPONENT_INCOMPATIBLE

	var/turf/parent_turf = parent
	RegisterSignal(SSsun, COMSIG_SUN_MOVED, .proc/update_lighting)
	parent_turf.set_light_range(3)
	parent_turf.set_light_on(TRUE)
	. = ..()

/datum/component/sunlight/Destroy(force, silent)
	UnregisterSignal(SSsun, COMSIG_SUN_MOVED)
	. = ..()

/datum/component/sunlight/proc/update_lighting()
	SIGNAL_HANDLER

	var/turf/parent_turf = parent
	var/sun_azimuth = (SSsun.azimuth + 90) % 360
	if(sun_azimuth > 180)
		var/sunlight_color = round((1 - abs(sun_azimuth - 270) / 90) * 255)
		parent_turf.set_light_power(0.2)
		parent_turf.set_light_color(rgb(sunlight_color, sunlight_color, sunlight_color))
		return

	var/sunlight_power = 1 - abs(sun_azimuth - 90) / 90
	parent_turf.set_light_color("#FFFFFF")
	parent_turf.set_light_power(sunlight_power * 3 + 0.2)
