/mob/living/carbon/human/get_movespeed_modifiers()
	var/list/considering = ..()
	if(HAS_TRAIT(src, TRAIT_IGNORESLOWDOWN))
		. = list()
		for(var/id in considering)
			var/datum/movespeed_modifier/M = considering[id]
			if(M.flags & IGNORE_NOSLOW || M.multiplicative_slowdown < 0)
				.[id] = M
		return
	return considering

/mob/living/carbon/human/slip(knockdown_amount, obj/slipped_on, lube_flags, paralyze, daze, force_drop = FALSE, check_difficulty = SKILLCHECK_LEGENDARY)
	if(HAS_TRAIT(src, TRAIT_NO_SLIP_ALL))
		return FALSE

	if(HAS_TRAIT(src, TRAIT_NO_SLIP_WATER) && !(lube_flags & GALOSHES_DONT_HELP))
		return FALSE

	if(HAS_TRAIT(src, TRAIT_NO_SLIP_ICE) && (lube_flags & SLIDE_ICE))
		return FALSE

	var/datum/check_result/result = aspect_check(/datum/aspect/savoir_faire, check_difficulty, move_intent == MOVE_INTENT_RUN ? 1 : 0)
	switch (result.outcome)
		if (CHECK_SUCCESS, CHECK_CRIT_SUCCESS)
			to_chat(src, result.show_message("You manage to keep your balance."))
			return FALSE
	. = ..()
	if (. && result.outcome == CHECK_CRIT_FAILURE)
		to_chat(src, result.show_message("You feel something in your body snap as you slip and roughly land on \the [get_turf(src)]."))
		take_bodypart_damage(rand(5, 10))

/mob/living/carbon/human/mob_negates_gravity()
	return dna.species.negates_gravity(src) || ..()

/mob/living/carbon/human/Move(NewLoc, direct)
	. = ..()
	if(shoes && body_position == STANDING_UP && has_gravity(loc))
		if((. && !moving_diagonally) || (!. && moving_diagonally == SECOND_DIAG_STEP))
			SEND_SIGNAL(shoes, COMSIG_SHOES_STEP_ACTION)

