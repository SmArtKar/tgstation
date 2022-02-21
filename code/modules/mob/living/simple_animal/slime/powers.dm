#define SIZE_DOESNT_MATTER -1
#define BABIES_ONLY 0
#define ADULTS_ONLY 1

#define NO_GROWTH_NEEDED 0
#define GROWTH_NEEDED 1

/datum/action/innate/slime
	check_flags = AB_CHECK_CONSCIOUS
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_alien"
	var/needs_growth = NO_GROWTH_NEEDED

/datum/action/innate/slime/IsAvailable()
	. = ..()
	if(!.)
		return
	var/mob/living/simple_animal/slime/S = owner
	if(needs_growth == GROWTH_NEEDED)
		if(S.amount_grown >= SLIME_EVOLUTION_THRESHOLD)
			return TRUE
		return FALSE
	return TRUE

/mob/living/simple_animal/slime/verb/Feed()
	set category = "Slime"
	set desc = "This will let you feed on any valid food in the surrounding area. This should also be used to halt the feeding process."

	if(stat)
		return FALSE

	var/list/choices = list()
	for(var/mob/living/nearby_mob in view(1,src))
		if(nearby_mob != src && Adjacent(nearby_mob))
			choices += nearby_mob

	for(var/obj/possible_food in view(1,src))
		if(Adjacent(possible_food) && CanFeedon(possible_food, TRUE))
			choices += possible_food

	var/choice = tgui_input_list(src, "Who do you wish to feed on?", "Slime Feed", sort_names(choices))
	if(isnull(choice))
		return FALSE

	if(!CanFeedon(choice))
		return FALSE

	if(!isliving(choice))
		gobble_up(choice)
		return TRUE

	var/mob/living/victim = choice
	Feedon(victim)
	return TRUE

/mob/living/simple_animal/slime/proc/gobble_up(atom/movable/food)
	if(!CanFeedon(food, TRUE))
		return

	var/matrix/animation_matrix = matrix()
	animation_matrix.Scale(0.7)
	animation_matrix.Translate((x - food.x) * 32, (y - food.y) * 32)
	animate(food, alpha = 0, time = 6, easing = QUAD_EASING|EASE_IN, transform = animation_matrix, flags = ANIMATION_PARALLEL)
	sleep(6)
	food.forceMove(src)
	Digesting = food
	digestion_progress = 0

	digestion_underlay = mutable_appearance(food.icon, food.icon_state)
	digestion_underlay.pixel_x = pixel_x
	digestion_underlay.pixel_y = pixel_y
	digestion_underlay.transform = matrix().Scale(0.7)
	digestion_underlay.color = food.color
	underlays += digestion_underlay
	next_underlay_scale = 0.6

/datum/action/innate/slime/feed
	name = "Feed"
	button_icon_state = "slimeeat"

/datum/action/innate/slime/feed/Activate()
	var/mob/living/simple_animal/slime/S = owner
	S.Feed()

/mob/living/simple_animal/slime/proc/CanFeedon(atom/movable/M, silent = FALSE)
	if(!Adjacent(M))
		return FALSE

	if(buckled && !silent)
		Feedstop()
		return FALSE

	if(issilicon(M))
		return FALSE

	if(isanimal(M))
		var/mob/living/simple_animal/S = M
		if(S.damage_coeff[TOX] <= 0 && S.damage_coeff[CLONE] <= 0) //The creature wouldn't take any damage, it must be too weird even for us.
			if(silent)
				return FALSE
			to_chat(src, "<span class='warning'>[pick("This subject is incompatible", \
			"This subject does not have life energy", "This subject is empty", \
			"I am not satisified", "I can not feed from this subject", \
			"I do not feel nourished", "This subject is not food")]!</span>")
			return FALSE

	if(isslime(M))
		if(silent)
			return FALSE
		to_chat(src, span_warning("<i>I can't latch onto another slime...</i>"))
		return FALSE

	if(docile)
		if(silent)
			return FALSE
		to_chat(src, span_notice("<i>I'm not hungry anymore...</i>"))
		return FALSE

	if(Digesting)
		if(silent)
			return FALSE
		to_chat(src, span_notice("<i>I'm already digesting something...</i>"))
		return FALSE

	if(stat)
		if(silent)
			return FALSE
		to_chat(src, span_warning("<i>I must be conscious to do this...</i>"))
		return FALSE

	if(isliving(M))
		var/mob/living/victim = M
		if(victim.stat == DEAD)
			if(silent)
				return FALSE
			to_chat(src, span_warning("<i>This subject does not have a strong enough life energy...</i>"))
			return FALSE

	if(locate(/mob/living/simple_animal/slime) in M.buckled_mobs)
		if(silent)
			return FALSE
		to_chat(src, span_warning("<i>Another slime is already feeding on this food...</i>"))
		return FALSE

	var/is_food = FALSE
	if(ishuman(M))
		var/mob/living/carbon/human/victim = M
		if(!ismonkey(victim) || (victim.dna.species.type in slime_color.food_types))
			is_food = TRUE

	if(!is_food)
		for(var/food_type in slime_color.food_types)
			if(istype(M, food_type))
				is_food = TRUE
				break

	if(!is_food)
		if(silent)
			return FALSE
		to_chat(src, span_warning("<i>I don't like this food....</i>"))
		return FALSE

	if(isitem(M) && M.anchored)
		if(silent)
			return FALSE
		to_chat(src, span_warning("<i>It's stuck to the floor...</i>"))
		return FALSE

	return TRUE

/mob/living/simple_animal/slime/proc/Feedon(mob/living/M)
	M.unbuckle_all_mobs(force=1) //Slimes rip other mobs (eg: shoulder parrots) off (Slimes Vs Slimes is already handled in CanFeedon())
	if(M.buckle_mob(src, force=TRUE))
		layer = M.layer+0.01 //appear above the target mob
		M.visible_message(span_danger("[name] latches onto [M]!"), \
						span_userdanger("[name] latches onto [M]!"))
	else
		to_chat(src, span_warning("<i>I have failed to latch onto the subject!</i>"))

/mob/living/simple_animal/slime/proc/Feedstop(silent = FALSE, living=1)
	if(buckled)
		if(!living)
			to_chat(src, "<span class='warning'>[pick("This subject is incompatible", \
			"This subject does not have life energy", "This subject is empty", \
			"I am not satisified", "I can not feed from this subject", \
			"I do not feel nourished", "This subject is not food")]!</span>")
			slime_color.finished_digesting_living(buckled)
		if(!silent)
			visible_message(span_warning("[src] lets go of [buckled]!"), \
							span_notice("<i>I stopped feeding.</i>"))
		layer = initial(layer)
		buckled.unbuckle_mob(src,force=TRUE)

/mob/living/simple_animal/slime/verb/Evolve()
	set category = "Slime"
	set desc = "This will let you evolve from baby to adult slime."

	if(stat)
		to_chat(src, "<i>I must be conscious to do this...</i>")
		return
	if(!is_adult)
		if(amount_grown >= SLIME_EVOLUTION_THRESHOLD)
			is_adult = 1
			maxHealth = 200
			amount_grown = 0
			for(var/datum/action/innate/slime/evolve/E in actions)
				E.Remove(src)
			var/datum/action/innate/slime/reproduce/reproduce_action = new
			reproduce_action.Grant(src)
			regenerate_icons()
			update_name()
		else
			to_chat(src, "<i>I am not ready to evolve yet...</i>")
	else
		to_chat(src, "<i>I have already evolved...</i>")

/datum/action/innate/slime/evolve
	name = "Evolve"
	button_icon_state = "slimegrow"
	needs_growth = GROWTH_NEEDED

/datum/action/innate/slime/evolve/Activate()
	var/mob/living/simple_animal/slime/S = owner
	S.Evolve()

/mob/living/simple_animal/slime/verb/Reproduce()
	set category = "Slime"
	set desc = "This will make you split into four Slimes."

	if(stat)
		to_chat(src, "<i>I must be conscious to do this...</i>")
		return

	if(is_adult)
		if(amount_grown >= SLIME_EVOLUTION_THRESHOLD)
			if(stat)
				to_chat(src, "<i>I must be conscious to do this...</i>")
				return

			var/list/babies = list()
			var/new_nutrition = round(nutrition * 0.9)
			var/new_powerlevel = round(powerlevel / 4)
			var/turf/drop_loc = drop_location()

			for(var/i in 1 to 4)
				var/child_color
				if(prob(mutation_chance))
					child_color = slime_color.mutations[rand(1,4)]
				else
					child_color = slime_color.type
				var/mob/living/simple_animal/slime/M
				M = new(drop_loc, child_color)
				if(ckey)
					M.set_nutrition(new_nutrition) //Player slimes are more robust at spliting. Once an oversight of poor copypasta, now a feature!
				M.powerlevel = new_powerlevel
				if(i != 1)
					step_away(M,src)
				M.set_friends(Friends)
				babies += M
				M.mutation_chance = clamp(mutation_chance+(rand(5,-5)),0,100)
				M.cores = max(1, round(cores / 2))
				SSblackbox.record_feedback("tally", "slime_babies_born", 1, M.slime_color.color)

			var/mob/living/simple_animal/slime/new_slime = pick(babies)
			new_slime.set_combat_mode(TRUE)
			if(src.mind)
				src.mind.transfer_to(new_slime)
			else
				new_slime.key = src.key
			qdel(src)
		else
			to_chat(src, "<i>I am not ready to reproduce yet...</i>")
	else
		to_chat(src, "<i>I am not old enough to reproduce yet...</i>")

/datum/action/innate/slime/reproduce
	name = "Reproduce"
	button_icon_state = "slimesplit"
	needs_growth = GROWTH_NEEDED

/datum/action/innate/slime/reproduce/Activate()
	var/mob/living/simple_animal/slime/S = owner
	S.Reproduce()
