/mob/living/silicon/ai/examine(mob/user)
	. = list()

	var/datum/check_result/result = user.examine_check(REF(src), SKILLCHECK_CHALLENGING, /datum/aspect/four_legged_wheelbarrel)
	if (result?.outcome <= CHECK_CRIT_FAILURE)
		return ..()

	if(stat == DEAD)
		. += result.show_message("It appears to be powered-down.")

	. += result.show_message("Its floor <b>bolts</b> are [is_anchored ? "tightened" : "loose"].")

	if(is_anchored)
		if(!opened)
			if(!emagged)
				. += result.show_message("Its access panel is [stat == DEAD ? "damaged" : "closed and locked"], but could be <b>pried</b> open.")
			else
				. += result.show_message("Its access panel lock is sparking, the cover can be <b>pried</b> open.")
		else
			. += result.show_message("Its neural network connection could be <b>cut</b>, its access panel cover can be <b>pried</b> back into place.")

	var/check_value = 30
	if (result.outcome < CHECK_SUCCESS)
		check_value = rand(1, 60)

	if(stat != DEAD)
		if (getBruteLoss())
			if (getBruteLoss() < check_value)
				. += result.show_message("It looks slightly dented.")
			else
				. += result.show_message("<B>It looks severely dented!</B>")

		if (getFireLoss())
			if (getFireLoss() < check_value)
				. += result.show_message("It looks slightly charred.")
			else
				. += result.show_message("<B>Its casing is melted and heat-warped!</B>")

		if(deployed_shell && result.outcome >= CHECK_SUCCESS)
			. += result.show_message("The wireless networking light is blinking.")
		else if (!shunted && !client)
			. += result.show_message("[src]Core.exe has stopped responding! NTOS is searching for a solution to the problem...")

	. += ..()
