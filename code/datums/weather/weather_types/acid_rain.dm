//Acid rain is part of the natural weather cycle in the humid forests of JungleStation, and cause acid damage to anyone unprotected.
/datum/weather/acid_rain
	name = "acid rain"
	desc = "The planet's thunderstorms are by nature acidic, and will incinerate anyone standing beneath them without protection."
	probability = 50

	telegraph_duration = 400
	telegraph_message = "<span class='boldwarning'>You hear droplets drumming against the canopy. Seek shelter.</span>"
	telegraph_sound = 'sound/ambience/acidrain_start.ogg'
	telegraph_overlay = "rain_telegraph"

	weather_message = "<span class='userdanger'><i>Acidic rain pours down around you! Get inside!</i></span>"
	weather_duration_lower = 600
	weather_duration_upper = 1500
	weather_sound = 'sound/ambience/acidrain_mid.ogg'
	weather_overlay = "rain_high"

	end_duration = 200
	end_message = "<span class='boldannounce'>The downpour gradually slows to a light shower. It should be safe outside now.</span>"
	end_sound = 'sound/ambience/acidrain_end.ogg'
	end_overlay = "rain_telegraph"

	weather_color = COLOR_GREEN_GRAY

	immunity_type = TRAIT_ACID_IMMUNE

	area_type = /area
	protect_indoors = TRUE
	target_trait = ZTRAIT_JUNGLE_WEATHER_SURFACE
	barometer_predictable = TRUE

/datum/weather/acid_rain/weather_act(mob/living/L)
	L.acid_act(20, 20)
	L.adjustFireLoss(3)

/datum/weather/acid_rain/can_weather_act(mob/living/mob_to_check)
	. = ..()
	if(!.)
		return
	if(mob_to_check.getarmor(null, ACID) >= 100)
		return FALSE

/datum/weather/acid_rain/light
	name = "light acid rain"
	weather_overlay = "rain_med"

	probability = 20

/datum/weather/acid_rain/light/weather_act(mob/living/L)
	L.acid_act(10, 20)
	L.adjustFireLoss(1)

/datum/weather/acid_rain/thunderstorm
	name = "acid storm"
	weather_overlay = "rain_storming"

	probability = 10

	telegraph_message = "<span class='boldwarning'>You hear thunder rumbling not so far from you and air starts reeking of acid. Storm is coming, seek shelter!</span>"
	telegraph_overlay = "rain_telegraph_med"

	var/list/possible_hit_turfs = list()

/datum/weather/acid_rain/thunderstorm/weather_act(mob/living/L)
	L.acid_act(30, 30)
	L.adjustFireLoss(6)

/datum/weather/acid_rain/thunderstorm/telegraph()
	. = ..()
	for(var/area/impacted_area in impacted_areas)
		possible_hit_turfs += get_area_turfs(impacted_area.type)

/datum/weather/acid_rain/thunderstorm/event_tick()
	for(var/i = 1 to rand(1, 3))
		addtimer(CALLBACK(src, .proc/telegraph_thunder), rand(0, 1 SECONDS * 10) / 10) //Don't want those hitting all at the same time

/datum/weather/acid_rain/thunderstorm/proc/telegraph_thunder()
	var/turf/target_turf = pick(possible_hit_turfs)
	playsound(target_turf, 'sound/magic/lightningshock.ogg', 10, TRUE, extrarange = MEDIUM_RANGE_SOUND_EXTRARANGE, falloff_distance = 0)
	addtimer(CALLBACK(src, .proc/thunder_hit, target_turf), 1.5 SECONDS)

/datum/weather/acid_rain/thunderstorm/proc/thunder_hit(turf/target_turf)
	var/turf/original_target = target_turf

	for(var/mob/living/carbon/human/player in spiral_range(original_target, 3))
		if(player.client) //It's not funny if nobody's there to get hit
			target_turf = get_turf(player)
			break

	for(var/mob/living/silicon/borgo in spiral_range(original_target, 5))
		if(borgo.client)
			target_turf = get_turf(borgo)
			break

	for(var/obj/machinery/power/energy_accumulator/rod in spiral_range(original_target, 5)) //Rods have more priority than silicons, silicons have more priority than humans
		if(rod.anchored)
			target_turf = get_turf(rod)
			tesla_zap(target_turf, 1, 12000, ZAP_GENERATES_POWER) //You can harvest a lot of power if you collect the thunderbolts
			break

	new /obj/effect/temp_visual/thunderbolt(target_turf)
	var/list/affected_turfs = list(target_turf)
	for(var/direction in GLOB.alldirs)
		var/turf_to_add = get_step(target_turf, direction)
		if(!turf_to_add)
			continue
		affected_turfs += turf_to_add

	for(var/turf/turf as anything in affected_turfs)
		new /obj/effect/temp_visual/electricity(turf)
		for(var/mob/living/hit_mob in turf)
			var/jungle_mob = FALSE
			if(istype(hit_mob, /mob/living/simple_animal/hostile/jungle))
				jungle_mob = TRUE
			to_chat(hit_mob, span_userdanger("You've been struck by lightning!"))
			hit_mob.electrocute_act(60 * (turf == target_turf ? 2 : 1) * (jungle_mob ? 0.2 : 1), src, flags = SHOCK_TESLA | SHOCK_NOGLOVES)
		for(var/obj/hit_thing in turf)
			if(istype(hit_thing, /obj/structure/flora))
				continue
			hit_thing.take_damage(40, BURN, ENERGY, FALSE)

	playsound(target_turf, 'sound/magic/lightningbolt.ogg', 100, TRUE)
	target_turf.visible_message(span_danger("A thunderbolt strikes [target_turf]!"))

#undef MAX_THUNDERS_PER_SECOND
#undef NORMAL_RAIN_CHANCE
#undef WEAK_RAIN_CHANCE
#undef THUNDERSTORM_CHANCE
