//Basic slime color datum along with grey and rainbow slimes here, other colors are split into files by tiers

/datum/slime_color
	var/color = "error" //I hate british people, there was C O L O U R everywhere
	var/icon_color //In case we have two or three words as our color
	var/coretype = /obj/item/slime_extract
	var/list/mutations
	var/list/food_types = list() //Mob nutrition value is based on their health, while items' is always the same and only depends on the coeff
	var/temperature_modifier = T0C
	var/environmental_req
	var/slime_tags

	var/fitting_environment = TRUE
	var/core_generation = 0

	var/mob/living/simple_animal/slime/slime

/datum/slime_color/New(slime)
	if(!icon_color)
		icon_color = color
	. = ..()
	src.slime = slime
	if(!mutations)
		mutations = list(type, type, type, type)

/datum/slime_color/proc/Life(delta_time, times_fired) //For handling special behavior
	if(slime.cores < slime.max_cores && slime.stat != DEAD)
		if((core_generation >= SLIME_MAX_CORE_GENERATION && fitting_environment) || slime.is_adult)
			slime.cores += 1
			core_generation = 0
		else
			core_generation += 1

/datum/slime_color/proc/finished_digesting(food)

/datum/slime_color/proc/finished_digesting_living(food)

/datum/slime_color/proc/remove()

/datum/slime_color/grey
	color = "grey"
	coretype = /obj/item/slime_extract/grey
	mutations = list(/datum/slime_color/orange, /datum/slime_color/metal, /datum/slime_color/blue, /datum/slime_color/purple)
	food_types = list(/datum/species/monkey = 1)

/datum/slime_color/rainbow
	color = "rainbow"
	coretype = /obj/item/slime_extract/rainbow
	mutations = null
