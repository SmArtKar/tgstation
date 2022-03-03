/datum/slime_color/dark_blue
	color = "dark blue"
	icon_color = "dark_blue"
	coretype = /obj/item/slime_extract/darkblue
	mutations = list(/datum/slime_color/blue, /datum/slime_color/purple, /datum/slime_color/cerulean, /datum/slime_color/cerulean)
	temperature_modifier = 213.15
	slime_tags = DISCHARGER_WEAKENED
	var/core_lose = 0

/datum/slime_color/dark_blue/Life(delta_time, times_fired)
	. = ..()
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix?.temperature <= DARK_BLUE_SLIME_DANGEROUS_TEMP && our_mix.gases[/datum/gas/water_vapor] && our_mix.gases[/datum/gas/water_vapor][MOLES] > DARK_BLUE_SLIME_VAPOR_REQUIRED)
		fitting_environment = TRUE
		core_lose = 0
		return

	slime.adjustBruteLoss(5)
	fitting_environment = FALSE
	core_lose += 1
	if(core_lose >= DARK_BLUE_SLIME_CORE_LOSE && slime.cores > 0)
		slime.cores -= 1
		core_lose = 0

/datum/slime_color/dark_purple
	color = "dark purple"
	icon_color = "dark_purple"
	coretype = /obj/item/slime_extract/darkpurple
	mutations = list(/datum/slime_color/purple, /datum/slime_color/orange, /datum/slime_color/sepia, /datum/slime_color/sepia)
	slime_tags = DISCHARGER_WEAKENED

/datum/slime_color/dark_purple/Life(delta_time, times_fired)
	. = ..()
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix.gases[/datum/gas/plasma] && our_mix.gases[/datum/gas/plasma][MOLES] > DARK_PURPLE_SLIME_PLASMA_REQUIRED && !(our_mix.gases[/datum/gas/oxygen] && our_mix.gases[/datum/gas/oxygen][MOLES]))
		fitting_environment = TRUE
		return

	slime.adjustBruteLoss(5)
	fitting_environment = FALSE
	if(DT_PROB(DARK_PURPLE_SLIME_PUFF_PROBABILITY, delta_time))
		our_turf.atmos_spawn_air("plasma=10;TEMP=1000")

/datum/slime_color/silver
	color = "silver"
	coretype = /obj/item/slime_extract/silver
	mutations = list(/datum/slime_color/blue, /datum/slime_color/metal, /datum/slime_color/pyrite, /datum/slime_color/pyrite)

	environmental_req = "Subject's vacuole is unstable and it will always seek for food regardless of it's size and nutrition. Vacuole stabilizators required to avoid implosion."

/datum/slime_color/silver/New(slime)
	. = ..()
	src.slime.nutrition_control = FALSE

/datum/slime_color/silver/remove()
	slime.nutrition_control = initial(slime.nutrition_control)

/datum/slime_color/silver/Life(delta_time, times_fired)
	. = ..()
	for(var/obj/machinery/vacuole_stabilizer/stabilizer in range(3, get_turf(slime)))
		if(stabilizer.on)
			fitting_environment = TRUE
			return

	fitting_environment = FALSE

	if(DT_PROB(SILVER_SLIME_IMPLODE_PROB, delta_time)) //You should consider putting a stabilizer into the cold room
		slime.visible_message(span_danger("[slime]'s vacuole implodes, tearing it apart into a few small blorbies!"))
		for(var/i = 1 to rand(2, 4))
			new /mob/living/simple_animal/hostile/slime_blorbie(get_turf(slime))
		playsound(get_turf(slime), 'sound/effects/meatslap.ogg', 100)
		qdel(slime)

/datum/slime_color/yellow
	color = "yellow"
	coretype = /obj/item/slime_extract/yellow
	mutations = list(/datum/slime_color/orange, /datum/slime_color/metal, /datum/slime_color/bluespace, /datum/slime_color/bluespace)
	food_types = list(/mob/living/simple_animal/xenofauna/wobble_chicken = 8, /mob/living/simple_animal/xenofauna/wobble_chicken/chick = 5, /obj/item/food/wobble_egg = 2, /obj/item/food/meat/slab/chicken/wobble = 2)

	environmental_req = "Subject will create beams of lightning once fully charged. To safely discharge it you'll need a slime discharger."

/datum/slime_color/yellow/New(slime)
	. = ..()
	ADD_TRAIT(src.slime, TRAIT_SHOCKIMMUNE, ROUNDSTART_TRAIT)
	ADD_TRAIT(src.slime, TRAIT_TESLA_SHOCKIMMUNE, ROUNDSTART_TRAIT)

/datum/slime_color/yellow/remove()
	REMOVE_TRAIT(slime, TRAIT_SHOCKIMMUNE, ROUNDSTART_TRAIT)
	REMOVE_TRAIT(slime, TRAIT_TESLA_SHOCKIMMUNE, ROUNDSTART_TRAIT)

/datum/slime_color/yellow/Life(delta_time, times_fired)
	. = ..()
	if(slime.powerlevel >= 5 && DT_PROB(slime.powerlevel * YELLOW_SLIME_ZAP_PROB, delta_time))
		slime.visible_message(span_danger("[slime] overcharges, sending out arcs of lightning!"))

		for(var/obj/machinery/power/energy_accumulator/slime_discharger/discharger in range(2, src))
			if(istype(discharger) && discharger.on)
				slime.powerlevel = round(slime.powerlevel / 2)
				slime.Beam(discharger, icon_state="lightning[rand(1,12)]", time = 5)
				fitting_environment = TRUE
				return

		fitting_environment = FALSE
		tesla_zap(slime, slime.powerlevel * 2, 5000 * (slime.powerlevel - 2), ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE)
		var/datum/effect_system/spark_spread/sparks = new /datum/effect_system/spark_spread
		sparks.set_up(1, 1, src)
		sparks.start()
		slime.powerlevel -= 1
