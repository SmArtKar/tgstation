#define ASPECT_LEVEL_EXP_FLOOR 1000
#define ASPECT_LEVEL_EXP_ADDITIONAL 250
#define ASPECT_LEVEL_EXP_POWER 1.5

/// Aspect datum, represents a skill which can be used for passive/active/dialogue checks
/// Aspects can be leveled by performing actions in-round, (normally) up to their Attribute's cap.
/// You get some leveling points roundstart to distribute how you want.
/datum/aspect
	var/name = "Shitcoding"
	var/desc = "The aspect of Shitcoding, existing solely so you can yell at coders."
	var/icon_state = ""
	var/level = ASPECT_NEUTRAL_LEVEL
	var/stored_exp = 0
	/// Attribute we are bound to, or its type (initially)
	var/datum/attribute/attribute = /datum/attribute
	/// List of currently active modifiers, source -> value
	var/list/modifiers = list()

/datum/aspect/New(datum/attribute/new_attribute)
	. = ..()
	attribute = new_attribute
	RegisterSignal(attribute.owner, COMSIG_MIND_TRANSFERRED, PROC_REF(register_body))

/datum/aspect/Destroy(force)
	unregister_body(get_body())
	attribute = null
	return ..()

/datum/aspect/proc/register_body(datum/mind/source, mob/living/old_current)
	if (isliving(old_current))
		unregister_body(old_current)
	update_effects()

/datum/aspect/proc/unregister_body(mob/living/old_body)
	return

/datum/aspect/proc/adjust_level(change)
	var/prev_level = get_level()
	level += change
	update_effects(prev_level)

/datum/aspect/proc/get_level()
	. = level
	for (var/modifier in flatten_list(modifiers))
		. += modifier

/datum/aspect/proc/gain_exp(exp_gained, can_level = TRUE, show_level_message = TRUE)
	stored_exp += exp_gained
	var/required_exp = get_exp_to_level()
	if (stored_exp < required_exp || !can_level)
		return
	if (attribute.level + attribute.level_modifier <= level)
		return
	stored_exp -= required_exp
	adjust_level(1)
	if (show_level_message)
		to_chat(attribute.owner, "<span style='color:[attribute.color]'>[get_levelup_message()]</span>")

/datum/aspect/proc/get_levelup_message()
	return "You feel yourself becoming more attuned to [name]!"

/datum/aspect/proc/get_exp_to_level()
	return ASPECT_LEVEL_EXP_FLOOR + ASPECT_LEVEL_EXP_ADDITIONAL * (level ** ASPECT_LEVEL_EXP_POWER)

/datum/aspect/proc/add_modifier(value, source)
	var/prev_level = get_level()
	modifiers[source] = value
	update_effects(prev_level)

/datum/aspect/proc/remove_modifier(source)
	var/prev_level = get_level()
	modifiers -= source
	update_effects(prev_level)

/datum/aspect/proc/update_effects(prev_level)
	return

/datum/aspect/proc/get_body()
	RETURN_TYPE(/mob/living)
	return attribute.owner.current

/// Roll for success on a skillcheck, optionally with a die visual
/// Capable of critical failures and successes, so returns aren't binary
/datum/aspect/proc/roll_check(difficulty, crit_fail_modifier = -10, show_visual = FALSE, die_delay = 0.5 SECONDS)
	var/dice_roll = roll("3d6")
	var/level = get_level() - ASPECT_NEUTRAL_LEVEL
	var/roll_value = dice_roll + level
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

	if (result >= CHECK_SUCCESS)
		gain_exp(SKILLCHECK_SUCCESS_EXP + SKILLCHECK_DIFFICULTY_BONUS * difficulty)

	var/datum/check_result/check_result = new(result, src, difficulty, dice_roll, level, crit_fail, crit_success)
	if (!show_visual)
		return check_result

	SEND_SOUND(attribute.owner.current, sound('sound/items/dice_roll.ogg', volume = 25))
	var/obj/effect/abstract/die_back/die = new(attribute.owner)
	die.color = attribute.color
	var/obj/effect/abstract/die_number/number = new(attribute.owner)
	QDEL_IN(die, die_delay + 0.2 SECONDS)
	QDEL_IN(number, die_delay + 0.2 SECONDS)

	die.vis_contents += number
	die.pixel_y += 1
	attribute.owner.current.vis_contents += die

	animate(die, pixel_y = 28, alpha = 175, time = die_delay, easing = SINE_EASING|EASE_OUT)
	if (result == CHECK_CRIT_FAILURE)
		animate(color = "#101010", time = 0)
	else if (result == CHECK_CRIT_SUCCESS)
		animate(color = "#ffe600", time = 0)
	animate(alpha = 0, pixel_y = 32, time = 0.2 SECONDS)

	animate(number, icon_state = "d20-[roll("3d6")]", time = (die_delay) / 5)
	for (var/i in 1 to 2)
		animate(icon_state = "d20-[roll("3d6")]", time = (die_delay) / 5)
	animate(icon_state = "d20-[dice_roll]", time = 0)
	return check_result

/// Check result datum, used for easier message formatting

/datum/check_result
	/// Return value of the check
	var/outcome = CHECK_FAILURE
	/// Aspect utilized to make the check
	var/datum/aspect/aspect
	/// Difficulty of the check
	var/difficulty
	/// Value rolled on the die
	var/roll
	/// Value at or below which we get a critical failure
	var/crit_fail
	/// Value at or above which we get a critical success
	var/crit_success
	/// Aspect level + additional modifiers
	var/modifier

/datum/check_result/New(outcome, aspect, difficulty, roll, modifier, crit_fail, crit_success)
	. = ..()
	src.outcome = outcome
	src.aspect = aspect
	src.difficulty = difficulty
	src.roll = roll
	src.modifier = modifier
	src.crit_fail = crit_fail
	src.crit_success = crit_success

/datum/check_result/proc/show_message(text)
	var/success_prob = round(dice_roll_probabilbity(3, 6, difficulty - modifier), 0.1)

	var/diff_string = "Error"
	switch(success_prob)
		if(0)
			diff_string = "Impossible"
		if(0.1 to 12)
			diff_string = "Godly"
		if(13 to 24)
			diff_string = "Legendary"
		if(25 to 36)
			diff_string = "Formidable"
		if(37 to 48)
			diff_string = "Challenging"
		if(49 to 60)
			diff_string = "Hard"
		if(61 to 72)
			diff_string = "Medium"
		if(73 to 84)
			diff_string = "Easy"
		if(85 to 100)
			diff_string = "Trivial"

	var/outcome_string = "Error"
	switch (outcome)
		if (CHECK_CRIT_FAILURE)
			outcome_string = "Critical Failure"
		if (CHECK_FAILURE)
			outcome_string = "Failure"
		if (CHECK_SUCCESS)
			outcome_string = "Success"
		if (CHECK_CRIT_SUCCESS)
			outcome_string = "Critical Success"

	var/tooltip = span_tooltip("<b>[success_prob]</b>% | Result: <b>[roll]</b> (+<b>[modifier]</b>) | Check: <b>[difficulty]</b>", span_italics("\[[diff_string]: [outcome_string]\]"))
	return "<span style='color:[aspect.attribute.color]'>[aspect.name] [tooltip]<i>:</i> [text]</span>"

/proc/dice_roll_probabilbity(dice, sides, difficulty)
	var/static/list/probability_cache
	var/static/list/dice_roll_cache
	if (isnull(dice_roll_cache))
		dice_roll_cache = list()
	else if (dice_roll_cache["[dice]d[sides]d[difficulty]"])
		return dice_roll_cache["[dice]d[sides]d[difficulty]"]

	if (difficulty <= dice)
		return 100

	if (difficulty > dice * sides)
		return 0

	if (isnull(probability_cache))
		var/list/dice_cache = dice_map(3, 6)
		var/chance_value = 100
		probability_cache = new(18)
		for (var/i in 3 to 18)
			probability_cache[i] = chance_value
			chance_value -= dice_cache[i] * 100 / (dice ** sides)

	var/result = round(probability_cache[difficulty], 0.1)
	dice_roll_cache["[dice]d[sides]d[difficulty]"] = result
	return result

/proc/dice_map(dice, sides)
	var/static/list/dice_cache
	if (isnull(dice_cache))
		dice_cache = list()
	else if (dice_cache["[dice]d[sides]"])
		return dice_cache["[dice]d[sides]"]
	var/list/outcomes = new(sides)
	var/list/next
	for (var/i in 1 to sides)
		outcomes[i] = 1
	for (var/i in 2 to dice)
		next = new(i * sides)
		for (var/j in 1 to (i - 1))
			next[j] = 0
		for (var/j in 1 to sides)
			for (var/k in (i - 1) to length(outcomes))
				next[j + k] += outcomes[k]
		outcomes = next
	dice_cache["[dice]d[sides]"] = outcomes
	return outcomes

// VFX objects

/obj/effect/abstract/die_back
	icon = 'icons/obj/toys/dice.dmi'
	icon_state = "d20"
	alpha = 200
	appearance_flags = KEEP_APART|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM|PIXEL_SCALE

/obj/effect/abstract/die_back/update_overlays()
	. = ..()
	. += emissive_appearance(icon, icon_state, alpha = 100) // Glows a bit

/obj/effect/abstract/die_number
	icon = 'icons/obj/toys/dice.dmi'
	icon_state = "d20-1"

#undef ASPECT_LEVEL_EXP_FLOOR
#undef ASPECT_LEVEL_EXP_ADDITIONAL
#undef ASPECT_LEVEL_EXP_POWER
