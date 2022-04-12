/datum/slime_color/red
	color = "red"
	coretype = /obj/item/slime_extract/red
	mutations = list(/datum/slime_color/red, /datum/slime_color/red, /datum/slime_color/oil, /datum/slime_color/oil)
	slime_tags = SLIME_BZ_IMMUNE

	environmental_req = "Subject is quite violent and will become rabid when hungry, causing all red slimes around it to also go rabid."

/datum/slime_color/red/Life(delta_time, times_fired)
	. = ..()
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	var/bz_percentage =0
	if(our_mix.gases[/datum/gas/bz])
		bz_percentage = our_mix.gases[/datum/gas/bz][MOLES] / our_mix.total_moles()
	var/stasis = bz_percentage >= 0.05 && slime.bodytemperature < (temperature_modifier + 100)
	if(stasis)
		slime.powerlevel = 0
		slime.rabid = FALSE //Can be calmed by BZ but not stasis-ed

	if(DT_PROB(65, delta_time) && slime.nutrition > slime.get_hunger_nutrition() + 100) //Even snowflakier because of hunger
		slime.adjust_nutrition(-1 * (1 + slime.is_adult))

	for(var/mob/living/simple_animal/slime/friend in view(5, get_turf(slime)))
		if(friend.slime_color.type != type)
			continue

		if(friend.nutrition <= friend.get_hunger_nutrition() - 100)
			fitting_environment = FALSE
			slime.rabid = TRUE
			return

	if(slime.nutrition > slime.get_hunger_nutrition() - 100) //Doesn't stop it's rabid rage when fed, you gotta do it using BZ or backpacks
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.rabid = TRUE

/datum/slime_color/green
	color = "green"
	coretype = /obj/item/slime_extract/green
	mutations = list(/datum/slime_color/green, /datum/slime_color/green, /datum/slime_color/black, /datum/slime_color/black)
	slime_tags = SLIME_DISCHARGER_WEAKENED

/datum/slime_color/pink
	color = "pink"
	coretype = /obj/item/slime_extract/pink
	mutations = list(/datum/slime_color/pink, /datum/slime_color/pink, /datum/slime_color/light_pink, /datum/slime_color/light_pink)
	slime_tags = SLIME_DISCHARGER_WEAKENED

/datum/slime_color/gold
	color = "gold"
	coretype = /obj/item/slime_extract/gold
	mutations = list(/datum/slime_color/gold, /datum/slime_color/gold, /datum/slime_color/adamantine, /datum/slime_color/adamantine)
	slime_tags = SLIME_BLUESPACE_CONNECTION
