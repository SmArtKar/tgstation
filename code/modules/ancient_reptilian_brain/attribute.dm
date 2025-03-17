/// Attributes, aka groups of aspects
/datum/attribute
	var/name = "Coderbus"
	var/desc = "People you yell at when you see this"
	var/color = "#FFFFFF"

	var/level = ASPECT_LEVEL_NEUTRAL
	/// Temporary modifier you get from drugs or booze or whatever
	/// Only allows you to level your aspects above this attribute's level
	var/level_modifier = 0
	/// Mind who owns us
	var/datum/mind/owner
	/// List of all aspect datums we own
	var/list/datum/aspect/aspects = list()

/datum/attribute/New(datum/mind/new_owner)
	. = ..()
	owner = new_owner
	RegisterSignal(owner, COMSIG_QDELETING, PROC_REF(on_owner_del))

	for (var/datum/aspect/aspect as anything in subtypesof(/datum/aspect))
		if (initial(aspect.attribute) != type)
			continue
		aspect = new aspect(src)
		aspects += aspect

/datum/attribute/Destroy(force)
	QDEL_LIST(aspects)
	owner = null
	return ..()

/datum/attribute/proc/on_owner_del(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/attribute/proc/adjust_level(change)
	level += change

/datum/attribute/proc/set_level(new_level)
	adjust_level(new_level - level)

/datum/attribute/proc/get_aspect(aspect_type)
	RETURN_TYPE(/datum/aspect)
	return locate(aspect_type) in aspects

// Mind and mob procs

/datum/mind/proc/init_attributes()
	for (var/attribute_type in subtypesof(/datum/attribute))
		attributes += new attribute_type(src)

/mob/proc/get_attribute(attribute_type)
	RETURN_TYPE(/datum/attribute)
	return locate(attribute_type) in mind?.attributes

/mob/proc/get_aspect(datum/aspect/aspect_type)
	RETURN_TYPE(/datum/aspect)
	var/datum/attribute/linked_attribute = get_attribute(initial(aspect_type.attribute))
	return linked_attribute?.get_aspect(aspect_type)

/mob/proc/get_aspect_level(datum/aspect/aspect_type)
	return get_aspect(aspect_type)?.get_level()

/mob/proc/aspect_check(aspect_type, difficulty, modifier, skill_modifier, crit_fail_modifier = -10, show_visual = FALSE, die_delay = 0.6 SECONDS, exp_modifier = 1)
	RETURN_TYPE(/datum/check_result)
	if (mind)
		var/datum/aspect/rolled_aspect = get_aspect(aspect_type)
		var/level_modifier = rolled_aspect.get_level() - ASPECT_LEVEL_NEUTRAL
		return rolled_aspect.roll_check(difficulty + modifier, level_modifier + skill_modifier, crit_fail_modifier, show_visual, die_delay, exp_modifier)

	difficulty += modifier
	var/dice_roll = roll("3d6")
	var/roll_value = dice_roll + ASPECT_LEVEL_NEUTRAL
	var/crit_fail = max(difficulty + crit_fail_modifier, 4)
	var/crit_success = min(difficulty + 7, 17)
	var/force_failure = (dice_roll == 3 && skill_modifier < difficulty)

	var/result
	// 3 always fails, 18 always wins
	if ((roll_value >= difficulty|| dice_roll == 18) && !force_failure )
		if (roll_value >= crit_success)
			result = CHECK_CRIT_SUCCESS
		else
			result = CHECK_SUCCESS
	else
		if (roll_value <= crit_fail)
			result = CHECK_CRIT_FAILURE
		else
			result = CHECK_FAILURE

	return new /datum/check_result(result, aspect_type, difficulty, dice_roll, ASPECT_LEVEL_NEUTRAL, crit_fail, crit_success)

/mob/proc/add_aspect_modifier(aspect_type, value, source)
	get_aspect(aspect_type).add_modifier(value, source)

/mob/proc/remove_aspect_modifier(aspect_type, source)
	get_aspect(aspect_type).remove_modifier(source)

// Use generic names like wraith_examine when looking for titbits of lore or doing generic actions, and refs when looking for object-specific details
/mob/proc/aspect_ready(cooldown_id)
	return COOLDOWN_FINISHED(src, mind?.aspect_cooldowns[cooldown_id])

/mob/proc/aspect_cooldown(cooldown_id, duration)
	if (!mind)
		return
	COOLDOWN_START(src, mind.aspect_cooldowns[cooldown_id], duration)

/mob/proc/aspect_reset(cooldown_id)
	if (mind)
		mind.aspect_cooldowns -= cooldown_id

/mob/proc/aspect_stash(check_id, datum/check_result/result, duration)
	mind?.aspect_stash_push(check_id, result, duration)

/mob/proc/aspect_stash_get(check_id)
	var/datum/check_result/result = mind?.aspect_stash[check_id]
	result.refresh() // Refresh the result so it shows its tooltip again
	return result

/datum/mind/proc/aspect_stash_push(check_id, datum/check_result/result, duration)
	aspect_stash[check_id] = result
	addtimer(CALLBACK(src, PROC_REF(aspect_stash_pop), check_id), duration, TIMER_UNIQUE|TIMER_OVERRIDE)

/datum/mind/proc/aspect_stash_pop(check_id)
	QDEL_NULL(aspect_stash[check_id])
	aspect_stash -= check_id

// Examine checks "buffer" your check result for a certain amount of time, allowing you to skip repeated checks if you won the previous one
/mob/proc/examine_check(check_id = "nothing", difficulty = SKILLCHECK_MEDIUM, aspect = /datum/aspect/perception, skill_modifier = 0, cooldown_mult = 1, show_visual = FALSE)
	var/check_key = "[check_id]_[aspect]_[difficulty]_examine"

	if (!aspect_ready(check_key))
		return aspect_stash_get(check_key) || new /datum/check_result(CHECK_FAILURE, get_aspect(aspect), difficulty, difficulty - 1, 0, 0, INFINITY)

	var/datum/check_result/result = aspect_check(aspect, difficulty, 0, skill_modifier, show_visual = show_visual, exp_modifier = 0.1)
	if (result.outcome < CHECK_SUCCESS)
		aspect_cooldown(check_key, 30 SECONDS * cooldown_mult)
		aspect_stash(check_key, result, 30 SECONDS * cooldown_mult)
		return result

	aspect_cooldown(check_key, 180 SECONDS * cooldown_mult)
	aspect_stash(check_key, result, 180 SECONDS * cooldown_mult)
	return result

/mob/dead/aspect_ready(cooldown_id)
	return TRUE

/mob/dead/aspect_cooldown(cooldown_id, duration)
	return

/mob/dead/examine_check(check_id = "nothing", difficulty = SKILLCHECK_MEDIUM, aspect = /datum/aspect/perception, skill_modifier = 0, cooldown_mult = 1, show_visual = TRUE)
	return new /datum/check_result(CHECK_CRIT_SUCCESS, get_aspect(aspect), difficulty, 18, difficulty, 0, 99)
