//Acid rain is part of the natural weather cycle in the humid forests of Planetstation, and cause acid damage to anyone unprotected.
/datum/weather/acid_rain
	name = "acid rain"
	desc = "The planet's thunderstorms are by nature acidic, and will incinerate anyone standing beneath them without protection."
	probability = 90

	telegraph_duration = 400
	telegraph_message = "<span class='boldwarning'>Thunder rumbles far above. You hear droplets drumming against the canopy. Seek shelter.</span>"
	telegraph_sound = 'sound/ambience/acidrain_start.ogg'
	telegraph_overlay = "rain_low"

	weather_message = "<span class='userdanger'><i>Acidic rain pours down around you! Get inside!</i></span>"
	weather_duration_lower = 600
	weather_duration_upper = 1500
	weather_sound = 'sound/ambience/acidrain_mid.ogg'
	weather_overlay = "rain_high"

	end_duration = 200
	end_message = "<span class='boldannounce'>The downpour gradually slows to a light shower. It should be safe outside now.</span>"
	end_sound = 'sound/ambience/acidrain_end.ogg'
	end_overlay = "rain_low"

	area_type = /area
	protect_indoors = TRUE
	target_trait = ZTRAIT_ACIDRAIN
	weather_color = COLOR_GREEN_GRAY

	immunity_type = TRAIT_ACID_IMMUNE

	barometer_predictable = TRUE


/datum/weather/acid_rain/weather_act(mob/living/L)
	var/resist = L.getarmor(null, ACID)
	if(prob(max(0,100-resist)))
		L.acid_act(20,20)
