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
	var/level = 0
	var/stored_exp = 0
	/// Attribute we are bound to, or its type (initially)
	var/datum/attribute/attribute = /datum/attribute
	/// List of currently active modifiers, source -> value
	var/list/modifiers = list()

/datum/aspect/New(datum/attribute/new_attribute)
	. = ..()
	attribute = new_attribute

/datum/aspect/Destroy(force)
	attribute = null
	return ..()

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
	update_effects(get_level())

/datum/aspect/proc/update_effects(prev_level)
	return

/datum/aspect/proc/get_body()
	RETURN_TYPE(/mob/living)
	return attribute.owner.current

/// Passive skillchecks that shouldn't affect you too much, as you can fail them purely by being too low level
/// Return simple TRUE or FALSE, no critical failures or successes
/datum/aspect/proc/passive_check(difficulty)
	if (difficulty > 2 + get_level() * 3)
		return FALSE

	var/pass_required = PASS_BASE_VALUE + difficulty
	var/result = (rand(1, 20) + get_level()) >= pass_required
	if (result)
		gain_exp(PASSIVE_CHECK_SUCCESS_EXP)

	return result

/// Active checks reserved for actions, can pop up a die visual.
/// Capable of critical failures and successes, so returns aren't binary
/datum/aspect/proc/active_check(difficulty, show_visual = TRUE)
	var/pass_required = PASS_BASE_VALUE + difficulty
	var/die_roll = rand(1, 20)
	var/result = CHECK_FAILURE
	if (die_roll == 1)
		result = CHECK_CRIT_FAILURE
	else if (die_roll == 20)
		result = CHECK_CRIT_SUCCESS
	else if (die_roll + get_level() > pass_required)
		result = CHECK_SUCCESS

	if (result >= CHECK_SUCCESS)
		gain_exp(ACTIVE_CHECK_SUCCESS_EXP)

	if (!show_visual)
		return result

	SEND_SOUND(attribute.owner.current, sound('sound/items/dice_roll.ogg', volume = 50))
	var/obj/effect/abstract/die_back/die = new(attribute.owner)
	var/obj/effect/abstract/die_number/number = new(attribute.owner)
	QDEL_IN(die, 0.7 SECONDS)
	QDEL_IN(number, 0.7 SECONDS)

	die.vis_contents += number
	die.pixel_y += 1
	attribute.owner.current.vis_contents += die

	animate(die, pixel_y = 28, alpha = 175, time = 0.5 SECONDS, easing = SINE_EASING|EASE_OUT)
	if (result == CHECK_CRIT_FAILURE)
		animate(color = "#101010", time = 0)
	else if (result == CHECK_CRIT_SUCCESS)
		animate(color = "#ffe600", time = 0)
	animate(alpha = 0, pixel_y = 32, time = 0.2 SECONDS)

	animate(number, icon_state = "d20-[rand(1, 20)]", time = 0.1 SECONDS)
	for (var/i in 1 to 2)
		animate(icon_state = "d20-[rand(1, 20)]", time = 0.1 SECONDS)
	animate(icon_state = "d20-[die_roll]", time = 0)
	return result

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
