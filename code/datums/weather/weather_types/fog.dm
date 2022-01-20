/datum/weather/fog
	name = "fog"
	desc = "The planet's thunderstorms are by nature acidic, and will incinerate anyone standing beneath them without protection."
	probability = 0

	telegraph_duration = 200
	telegraph_message = "<span class='boldannounce'>The air is becoming humid and foggy.</span>"

	weather_message = "<span class='boldwarning'><i>The fog is rising and it's becoming hard to see, you should probably go inside.</i></span>"
	weather_duration_lower = 1800
	weather_duration_upper = 3000 //From 3 to 5 minutes
	weather_overlay = "fog"

	end_duration = 200
	end_message = "<span class='boldannounce'>The fog finally clears.</span>"

	weather_color = "#CDE6B3"

	area_type = /area
	protect_indoors = TRUE
	target_trait = ZTRAIT_JUNGLE_WEATHER_SURFACE
	barometer_predictable = TRUE

/datum/weather/fog/weather_act(mob/living/target)
	if(!istype(target))
		return
	target.apply_status_effect(STATUS_EFFECT_FOG)
