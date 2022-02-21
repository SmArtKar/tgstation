/datum/slime_color/dark_blue
	color = "dark blue"
	icon_color = "dark_blue"
	coretype = /obj/item/slime_extract/darkblue
	mutations = list(/datum/slime_color/blue, /datum/slime_color/purple, /datum/slime_color/cerulean, /datum/slime_color/cerulean)
	slime_tags = DISCHARGER_WEAKENED

/datum/slime_color/dark_purple
	color = "dark purple"
	icon_color = "dark_purple"
	coretype = /obj/item/slime_extract/darkpurple
	mutations = list(/datum/slime_color/purple, /datum/slime_color/orange, /datum/slime_color/sepia, /datum/slime_color/sepia)
	slime_tags = DISCHARGER_WEAKENED

/datum/slime_color/silver
	color = "silver"
	coretype = /obj/item/slime_extract/silver
	mutations = list(/datum/slime_color/blue, /datum/slime_color/metal, /datum/slime_color/pyrite, /datum/slime_color/pyrite)

/datum/slime_color/yellow
	color = "yellow"
	coretype = /obj/item/slime_extract/yellow
	mutations = list(/datum/slime_color/orange, /datum/slime_color/metal, /datum/slime_color/bluespace, /datum/slime_color/bluespace)

	environmental_req = "Subject will create beams of lightning once fully charged. To safely discharge it you'll need a slime discharger."

/datum/slime_color/yellow/New(slime)
	. = ..()
	ADD_TRAIT(src.slime, TRAIT_SHOCKIMMUNE, ROUNDSTART_TRAIT)
	ADD_TRAIT(src.slime, TRAIT_TESLA_SHOCKIMMUNE, ROUNDSTART_TRAIT)

/datum/slime_color/yellow/remove()
	REMOVE_TRAIT(slime, TRAIT_SHOCKIMMUNE, ROUNDSTART_TRAIT)
	REMOVE_TRAIT(slime, TRAIT_TESLA_SHOCKIMMUNE, ROUNDSTART_TRAIT)

/datum/slime_color/yellow/Life(delta_time, times_fired)
	if(slime.powerlevel >= 5 && DT_PROB(slime.powerlevel * YELLOW_SLIME_ZAP_PROB, delta_time))
		slime.visible_message(span_danger("[slime] overcharges, sending out arcs of lightning!"))

		for(var/obj/machinery/power/energy_accumulator/slime_discharger/discharger in range(2, src))
			if(istype(discharger))
				slime.powerlevel = round(slime.powerlevel / 2)
				slime.Beam(discharger, icon_state="lightning[rand(1,12)]", time = 5)
				return

		tesla_zap(slime, slime.powerlevel * 2, 5000 * (slime.powerlevel - 2), ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE)
		var/datum/effect_system/spark_spread/sparks = new /datum/effect_system/spark_spread
		sparks.set_up(1, 1, src)
		sparks.start()
		slime.powerlevel -= 1
