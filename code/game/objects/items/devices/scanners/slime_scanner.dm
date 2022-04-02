/obj/item/slime_scanner
	name = "slime scanner"
	desc = "A device that analyzes a slime's internal composition and measures its stats."
	icon = 'icons/obj/device.dmi'
	icon_state = "slime"
	inhand_icon_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron=30, /datum/material/glass=20)
	var/advanced = FALSE

/obj/item/slime_scanner/attack(mob/living/M, mob/living/user)
	if(user.stat || user.is_blind())
		return
	if (!isslime(M))
		to_chat(user, span_warning("This device can only scan slimes!"))
		return
	var/mob/living/simple_animal/slime/T = M
	slime_scan(T, user, advanced)
	flick("[initial(icon_state)]-scan", src)

/obj/item/slime_scanner/advanced
	name = "advanced slime scanner"
	desc = "An advanced version of a slime scanner, capable of precise measurements and ranged scans."
	icon_state = "slime_adv"
	advanced = TRUE

/obj/item/slime_scanner/advanced/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(target.Adjacent(user))
		return

	if(user.stat || user.is_blind())
		return

	if (!isslime(target))
		to_chat(user, span_warning("This device can only scan slimes!"))
		return

	var/mob/living/simple_animal/slime/slime = target
	slime_scan(slime, user, advanced)
	flick("[initial(icon_state)]-scan", src)

/proc/slime_scan(mob/living/simple_animal/slime/T, mob/living/user, advanced = FALSE)
	var/to_render = "========================\
					\n<b>Slime scan results:</b>\
					\n[span_notice("[T.slime_color.color] [T.is_adult ? "adult" : "baby"] slime")]\
					\nNutrition: [T.nutrition]/[T.get_max_nutrition()]"
	if (T.nutrition < T.get_starve_nutrition())
		to_render += "\n[span_warning("Warning: slime is starving!")]"
	else if (T.nutrition < T.get_hunger_nutrition())
		to_render += "\n[span_warning("Warning: slime is hungry")]"
	to_render += "\nElectric change strength: [T.powerlevel]\nHealth: [round(T.health/T.maxHealth,0.01)*100]%"
	if (T.slime_color.mutations[4] == T.slime_color.type)
		to_render += "\nThis slime does not evolve any further."
	else
		var/datum/slime_color/first = T.slime_color.mutations[1]
		var/datum/slime_color/second = T.slime_color.mutations[2]
		var/datum/slime_color/third = T.slime_color.mutations[3]
		var/datum/slime_color/forth = T.slime_color.mutations[4]

		if (T.slime_color.mutations[3] == T.slime_color.mutations[4])
			if (T.slime_color.mutations[2] == T.slime_color.mutations[1])
				to_render += "\nPossible mutation: [initial(third.color)]\
							  [advanced ? "\n Genetic instability: [T.mutation_chance/2] % chance of mutation on splitting" : ""]"
			else
				to_render += "\nPossible mutations: [initial(first.color)], [initial(second.color)], [initial(third.color)] (x2)\
							  [advanced ? "\n Genetic instability: [T.mutation_chance] % chance of mutation on splitting"  : ""]"
		else
			to_render += "\nPossible mutations: [initial(first.color)], [initial(second.color)], [initial(third.color)], [initial(forth.color)]\
							  [advanced ? "\n Genetic instability: [T.mutation_chance] % chance of mutation on splitting"  : ""]"
	if (T.cores > 1 && advanced)
		to_render += "\nMultiple cores detected"
	if(T.slime_color.food_types)
		to_render += "\n Prefered food types:"
		for(var/food_type in T.slime_color.food_types)
			var/atom/food = food_type
			to_render += "\n [icon2html(icon(initial(food.icon), initial(food.icon_state)), user)] [initial(food.name)]"
	to_render += "\nGrowth progress: [T.amount_grown]/[SLIME_EVOLUTION_THRESHOLD]"
	to_chat(user, to_render + "\n========================")
