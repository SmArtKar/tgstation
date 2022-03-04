/datum/slime_color/purple
	color = "purple"
	coretype = /obj/item/slime_extract/purple
	mutations = list(/datum/slime_color/dark_blue, /datum/slime_color/dark_purple, /datum/slime_color/green, /datum/slime_color/green)
	food_types = list(/obj/item/food/xenoflora/broombush = 1)
	slime_tags = DISCHARGER_WEAKENED

	environmental_req = "Subject requires N2O in the atmosphere."

/datum/slime_color/purple/Life(delta_time, times_fired)
	. = ..()
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix.gases[/datum/gas/nitrous_oxide] && our_mix.gases[/datum/gas/nitrous_oxide][MOLES] > PURPLE_SLIME_N2O_REQUIRED)
		slime.rabid = FALSE
		fitting_environment = TRUE
		return

	slime.adjustBruteLoss(5)
	slime.rabid = TRUE
	fitting_environment = FALSE

/datum/slime_color/blue
	color = "blue"
	coretype = /obj/item/slime_extract/blue
	mutations = list(/datum/slime_color/dark_blue, /datum/slime_color/silver, /datum/slime_color/pink, /datum/slime_color/pink)
	temperature_modifier = TCRYO
	food_types = list(/obj/item/food/xenoflora/cubomelon = 4, /obj/item/food/xenoflora/cubomelon_slice = 1)
	slime_tags = DISCHARGER_WEAKENED

	environmental_req = "Subject requires low temperatures ranging from -40° to -10° Celsius."

/datum/slime_color/blue/Life(delta_time, times_fired)
	. = ..()
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix?.temperature <= BLUE_SLIME_DANGEROUS_TEMP)
		fitting_environment = TRUE
		return

	slime.adjustBruteLoss(10)
	fitting_environment = FALSE

/datum/slime_color/blue/finished_digesting(food)
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	our_mix.assert_gas(/datum/gas/water_vapor)
	our_mix.gases[/datum/gas/water_vapor][MOLES] += BLUE_SLIME_PUFF_AMOUNT

/datum/slime_color/metal
	color = "metal"
	coretype = /obj/item/slime_extract/metal
	mutations = list(/datum/slime_color/yellow, /datum/slime_color/silver, /datum/slime_color/gold, /datum/slime_color/gold)
	food_types = list(/mob/living/basic/cockroach/rockroach = 4, /obj/item/rockroach_shell = 0.2)
	environmental_req = "Subject requires CO2 in the atmosphere."

/datum/slime_color/metal/Life(delta_time, times_fired)
	. = ..()
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix.gases[/datum/gas/carbon_dioxide] && our_mix.gases[/datum/gas/carbon_dioxide][MOLES] > METAL_SLIME_CO2_REQUIRED)
		fitting_environment = TRUE
		return

	slime.adjustBruteLoss(5)
	fitting_environment = FALSE

/datum/slime_color/orange
	color = "orange"
	coretype = /obj/item/slime_extract/orange
	mutations = list(/datum/slime_color/yellow, /datum/slime_color/dark_purple, /datum/slime_color/red, /datum/slime_color/red)
	food_types = list()
	environmental_req = "Subject requires temperatures higher than 60° Celsius."

/datum/slime_color/orange/Life(delta_time, times_fired)
	. = ..()
	var/turf/our_turf = get_turf(slime)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix?.temperature >= ORANGE_SLIME_UNHAPPY_TEMP)
		fitting_environment = TRUE
		return

	slime.adjust_nutrition(-10 * delta_time)
	fitting_environment = FALSE
	if(slime.nutrition <= 0)
		slime.set_nutrition(0)

	if(our_mix?.temperature >= ORANGE_SLIME_DANGEROUS_TEMP)
		return

	slime.adjustBruteLoss(10)
