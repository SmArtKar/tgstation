/datum/weather/solar_flare
	name = "fog"
	desc = "The planet's thunderstorms are by nature acidic, and will incinerate anyone standing beneath them without protection."
	probability = 0

	telegraph_duration = 200
	telegraph_message = "<span class='boldannounce'>The air is becoming humid and foggy.</span>"

	weather_message = "<span class='boldwarning'><i>The fog is rising and it's becoming hard to see, you should probably go inside.</i></span>"
	weather_duration_lower = 1200
	weather_duration_upper = 3000 //From 3 to 5 minutes

	end_duration = 200
	end_message = "<span class='boldannounce'>The fog finally clears.</span>"

	area_type = /area
	protect_indoors = FALSE
	target_trait = ZTRAIT_JUNGLE_WEATHER
	barometer_predictable = TRUE
