/// Attributes, aka groups of aspects
/datum/attribute
	var/name = "Coderbus"
	var/desc = "People you yell at when you see this"
	var/color = "#FFFFFF"

	var/level = 0
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
	for (var/datum/aspect/aspect as anything in aspects)
		aspect.adjust_level(change)

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

/mob/proc/aspect_check(aspect_type, difficulty, modifier, skill_modifier, crit_fail_modifier = -10, show_visual = FALSE, die_delay = 0.6 SECONDS)
	RETURN_TYPE(/datum/check_result)
	if (mind)
		var/datum/aspect/rolled_aspect = get_aspect(aspect_type)
		var/level_modifier = rolled_aspect.get_level() - ASPECT_NEUTRAL_LEVEL
		return rolled_aspect.roll_check(difficulty + modifier, level_modifier + skill_modifier, crit_fail_modifier, show_visual, die_delay)

	difficulty += modifier
	var/dice_roll = roll("3d6")
	var/roll_value = dice_roll + ASPECT_NEUTRAL_LEVEL
	var/crit_fail = max(difficulty + crit_fail_modifier, 4)
	var/crit_success = min(difficulty + 7, 17)

	var/result
	// 3 always fails, 18 always wins
	if (roll_value >= difficulty && dice_roll != 3 || dice_roll == 18)
		if (roll_value >= crit_success)
			result = CHECK_CRIT_SUCCESS
		else
			result = CHECK_SUCCESS
	else
		if (roll_value <= crit_fail)
			result = CHECK_CRIT_FAILURE
		else
			result = CHECK_FAILURE

	return new /datum/check_result(result, aspect_type, difficulty, dice_roll, ASPECT_NEUTRAL_LEVEL, crit_fail, crit_success)

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

/mob/proc/examine_check(check_id = "nothing", difficulty = SKILLCHECK_MEDIUM, aspect = /datum/aspect/perception, show_visual = TRUE)
	if (!aspect_ready("[check_id]_examine"))
		return null
	var/datum/check_result/result = aspect_check(aspect, difficulty, show_visual = show_visual)
	if (result.outcome < CHECK_SUCCESS)
		aspect_cooldown("[check_id]_examine", 30 SECONDS)
		return result
	aspect_cooldown("[check_id]_examine", 10 SECONDS)
	return result

/mob/dead/aspect_ready(cooldown_id)
	return TRUE

/mob/dead/aspect_cooldown(cooldown_id, duration)
	return

/mob/dead/examine_check(id, difficulty, aspect)
	return null
