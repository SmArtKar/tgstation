/mob/living/silicon/robot/examine(mob/user)
	. = list()
	if(desc)
		. += "[desc]"

	var/datum/check_result/result = user.examine_check(REF(src), SKILLCHECK_CHALLENGING, /datum/aspect/four_legged_wheelbarrel)
	if (result.outcome <= CHECK_CRIT_FAILURE)
		return . + ..()

	var/model_name = model ? "\improper [model.name]" : "\improper Default"
	. += result.show_message("It is currently <b>\a [model_name]-type</b> cyborg.")

	var/obj/act_module = get_active_held_item()
	if(act_module)
		. += result.show_message("It is holding [icon2html(act_module, user)] \a [act_module].")

	if (result.outcome >= CHECK_SUCCESS)
		var/list/statuses = get_status_effect_examinations()
		for (var/status in statuses)
			. += result.show_message(status)

	var/assumed_health = maxHealth
	if (result.outcome < CHECK_SUCCESS)
		assumed_health *= rand(1.5, -1.5)

	if (getBruteLoss())
		if (getBruteLoss() < assumed_health*0.5)
			. += result.show_message("It looks slightly dented.")
		else
			. += span_boldwarning("It looks severely dented!")

	if (getFireLoss() || getToxLoss())
		var/overall_fireloss = getFireLoss() + getToxLoss()
		if (overall_fireloss < assumed_health * 0.5)
			. += result.show_message("It looks slightly charred.")
		else
			. += result.show_message("It looks severely burnt and heat-warped!")

	if (health < -assumed_health*0.5)
		. += result.show_message("It looks barely operational.")

	if (fire_stacks < 0)
		. += result.show_message("It's covered in water.")
	else if (fire_stacks > 0)
		. += result.show_message("It's coated in something flammable.")

	if(opened)
		. += result.show_message("Its cover is open and the power cell is [cell ? "installed" : "missing"].")
	else
		. += result.show_message("Its cover is closed[locked ? "" : ", and looks unlocked"].")

	if(cell && cell.charge <= 0)
		. += result.show_message("Its battery indicator is blinking red!")

	switch(stat)
		if(CONSCIOUS)
			if(shell)
				. += result.show_message("It appears to be an [deployed ? "active" : "empty"] AI shell.")
			else if(!client)
				. += result.show_message("It appears to be in stand-by mode.") //afk
		if(SOFT_CRIT, UNCONSCIOUS, HARD_CRIT)
			. += result.show_message("It doesn't seem to be responding.")
		if(DEAD)
			. += result.show_message("It looks like its system is corrupted and requires a reset.")

	. += ..()
