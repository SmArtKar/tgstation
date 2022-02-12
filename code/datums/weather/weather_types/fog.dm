#define FOGBEAST_PROBABILITY 100 //1

/datum/weather/fog
	name = "fog"
	desc = "Due to the high humidity of the planet, lightly acidic fog isn't a rare guest in these lush jungles. Just remember that there's no fogbeast and all stories about half-eaten miner corpses are just myths."
	probability = 20

	telegraph_duration = 400
	telegraph_message = "<span class='boldwarning'>The air is becoming humid and foggy.</span>"

	weather_message = "<span class='boldannounce'><i>The fog is rising and it's becoming hard to see, you should probably go inside.</i></span>"
	weather_duration_lower = 1800
	weather_duration_upper = 6000 //From 3 to 10 minutes
	weather_overlay = "fog"
	weather_sound = 'sound/misc/ghosty_wind.ogg'

	end_duration = 200
	end_message = "<span class='boldnotice'>The fog finally clears.</span>"

	weather_color = "#CDE6B3"

	area_type = /area
	protect_indoors = TRUE
	target_trait = ZTRAIT_JUNGLE_WEATHER_SURFACE
	barometer_predictable = TRUE

/datum/weather/fog/weather_act(mob/living/target)
	if(!istype(target))
		return
	target.apply_status_effect(/datum/status_effect/thick_fog)

/datum/weather/fog/start()
	. = ..()

	if(!prob(FOGBEAST_PROBABILITY))
		return

	var/list/foggers = list()

	for(var/z_level in impacted_z_levels)
		for(var/mob/living/carbon/player as anything in SSmobs.clients_by_zlevel[z_level])
			var/turf/mob_turf = get_turf(player)
			if(!mob_turf || !(get_area(player) in impacted_areas))
				continue
			foggers += player

	if(!LAZYLEN(foggers))
		return

	for(var/i = 1 to rand(1, min(5, LAZYLEN(foggers))))
		var/mob/living/carbon/fogger = pick_n_take(foggers)
		fogger.gain_trauma(/datum/brain_trauma/magic/fogbeast)

#define FOGBEAST_PROBABILITY
