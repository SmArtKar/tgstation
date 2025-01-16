/mob/living/carbon/apply_damage_package(
	datum/damage_package/package,
	blocked = 0,
	check_armor = FALSE,
	wound_clothing = TRUE,
	should_update = TRUE,
	silent = FALSE,
)
	// Smartkar: figure if this is even neccessary or if we can axe this actually
	/*
	if (isbodypart(package.def_zone))
		return ..()

	if (!islist(package.def_zone) && !isbodypart(package.def_zone))
		var/random_zone = check_zone(package.def_zone || get_random_valid_zone())
		package.def_zone = get_bodypart(random_zone) || bodyparts[1]
		return ..()

	var/list/taken_zones = list()
	var/list/new_zones = list()
	for (var/zone in package.def_zone)
		var/zone_lookup = package.def_zone
		if (!zone_lookup || (zone_lookup in taken_zones))
			zone_lookup = get_random_valid_zone(blacklisted_parts = taken_zones)
		var/random_zone = check_zone(zone_lookup)
		var/obj/item/bodypart/part = get_bodypart(random_zone)
		if (part.body_zone in taken_zones) // something went wrong
			continue
		taken_zones += part.body_zone // Before the continue so we don't keep picking invalid zones
		if (!(part.bodytype & package.required_biotype)) // Skip the part if we cannot deal damage to it
			continue
		new_zones += part

	package.def_zone = new_zones
	if (!length(package.def_zone))
		var/obj/item/bodypart/chest = bodyparts[1] // Deal damage to the chest if we cannot find a valid limb
		if (!(chest.bodytype & package.required_biotype)) // If chest is invalid, screw it and skip the damage entirely
			return 0
		package.def_zone = chest
	*/
	return ..()

/mob/living/carbon/finalize_package_damage(datum/damage_package/package, wound_clothing = TRUE, should_update = TRUE)
	if (package.damage_type == TOX)
		. = ..()
		if(AT_TOXIN_VOMIT_THRESHOLD(src))
			apply_status_effect(/datum/status_effect/tox_vomit)
		return .

	if (package.damage_type == OXY || package.damage_type == STAMINA)
		return ..()

	var/list/parts = null
	if (package.def_zone)
		if (!islist(package.def_zone))
			var/obj/item/bodypart/bodypart = get_bodypart(check_zone(package.def_zone))
			if (!bodypart)
				bodypart = bodyparts[1]
				if (!bodypart) // You have more serious problems tbh
					return 0
			if(required_bodytype && !(bodypart.bodytype & required_bodytype))
				return 0
			parts = list(bodypart)
		else
			parts = get_damageable_bodyparts(package.required_biotype, package.def_zone)
	else
		if (package.spread_damage)
			parts = get_damageable_bodyparts(package.required_biotype)
		else
			parts = list(pick(get_damageable_bodyparts(package.required_biotype)))

	if (!length(parts))
		return 0

	var/damage_taken = 0
	var/update_overlays = FALSE
	var/damage_per_part = round(package.amount / length(parts), DAMAGE_PRECISION)
	// Done via indexing for ease of redistributing overheal
	for (var/i in 1 to length(parts))
		var/obj/item/bodypart/part = parts[i]
		var/cur_damage = part.get_damage()
		update_overlays |= part.receive_damage(package, amount = damage_per_part, should_update = FALSE) // Smartkar: unfuck this
		var/damage_difference = (part.get_damage() - cur_damage)
		damage_taken += damage_difference
		// Overheal gets given to other limbs
		if (damage_per_part < 0 && damage_per_part < damage_difference)
			damage_per_part = round(damage_per_part + ((damage_per_part - damage_difference) / (length(parts) - i + 1)), DAMAGE_PRECISION)

	if (!damage_taken)
		return 0

	if(should_update)
		updatehealth()
	if(update_overlays)
		update_damage_overlays()
	// Taking brute or burn to bodyparts gives a damage flash
	damageoverlaytemp += damage_taken
	return damage_taken

/mob/living/carbon/valid_package(datum/damage_package/package)
	return TRUE

/mob/living/carbon/get_incoming_damage_modifier(datum/damage_package/package)
	. = ..()
	if (package.amount < 0 || !dna?.species?.damage_modifier)
		return
	. /= (100 + dna.species.damage_modifier) * 0.01

/mob/living/carbon/get_brute_loss()
	. = 0
	for(var/obj/item/bodypart/part as anything in bodyparts)
		. += part.brute_dam

/mob/living/carbon/get_burn_loss()
	. = 0
	for(var/obj/item/bodypart/part as anything in bodyparts)
		. += part.burn_dam

/mob/living/carbon/received_stamina_damage(current_level, amount_actual, amount)
	. = ..()
	if((maxHealth - current_level) <= crit_threshold && stat != DEAD)
		apply_status_effect(/datum/status_effect/incapacitating/stamcrit)

/**
 * If an organ exists in the slot requested, and we are capable of taking damage (we don't have TRAIT_GODMODE), call the damage proc on that organ.
 *
 * Arguments:
 * * slot - organ slot, like [ORGAN_SLOT_HEART]
 * * amount - damage to be done
 * * maximum - currently an arbitrarily large number, can be set so as to limit damage
 * * required_organ_flag - targets only a specific organ type if set to ORGAN_ORGANIC or ORGAN_ROBOTIC
 *
 * Returns: The net change in damage from apply_organ_damage()
 */

/mob/living/carbon/adjust_organ_loss(slot, amount, maximum, required_organ_flag = NONE)
	var/obj/item/organ/affected_organ = get_organ_slot(slot)
	if(!affected_organ || HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(required_organ_flag && !(affected_organ.organ_flags & required_organ_flag))
		return FALSE
	return affected_organ.apply_organ_damage(amount, maximum)

/**
 * If an organ exists in the slot requested, and we are capable of taking damage (we don't have TRAIT_GODMODE), call the set damage proc on that organ, which can
 * set or clear the failing variable on that organ, making it either cease or start functions again, unlike adjust_organ_loss.
 *
 * Arguments:
 * * slot - organ slot, like [ORGAN_SLOT_HEART]
 * * amount - damage to be set to
 * * required_organ_flag - targets only a specific organ type if set to ORGAN_ORGANIC or ORGAN_ROBOTIC
 *
 * Returns: The net change in damage from set_organ_damage()
 */

/mob/living/carbon/set_organ_loss(slot, amount, required_organ_flag = NONE)
	var/obj/item/organ/affected_organ = get_organ_slot(slot)
	if(!affected_organ || HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(required_organ_flag && !(affected_organ.organ_flags & required_organ_flag))
		return FALSE
	if(affected_organ.damage == amount)
		return FALSE
	return affected_organ.set_organ_damage(amount)

/**
 * If an organ exists in the slot requested, return the amount of damage that organ has
 *
 * Arguments:
 * * slot - organ slot, like [ORGAN_SLOT_HEART]
 */

/mob/living/carbon/get_organ_loss(slot)
	var/obj/item/organ/affected_organ = get_organ_slot(slot)
	if(affected_organ)
		return affected_organ.damage

/mob/living/carbon/proc/get_damaged_bodyparts(brute = FALSE, burn = FALSE, required_bodytype = NONE, target_zones = null)
	var/list/obj/item/bodypart/parts = list()
	for(var/obj/item/bodypart/part as anything in bodyparts)
		if(required_bodytype && !(part.bodytype & required_bodytype))
			continue
		if(!isnull(target_zones) && !(part.body_zone in target_zones))
			continue
		if((brute && part.brute_dam) || (burn && part.burn_dam))
			parts += part
	return parts

/mob/living/carbon/proc/get_damageable_bodyparts(required_bodytype, target_zones = null)
	var/list/obj/item/bodypart/parts = list()
	for(var/obj/item/bodypart/part as anything in bodyparts)
		if(required_bodytype && !(part.bodytype & required_bodytype))
			continue
		if(!isnull(target_zones) && !(part.body_zone in target_zones))
			continue
		if(part.brute_dam + part.burn_dam < part.max_damage)
			parts += part
	return parts

/mob/living/carbon/proc/get_wounded_bodyparts(required_bodytype, target_zones = null)
	var/list/obj/item/bodypart/parts = list()
	for(var/obj/item/bodypart/part as anything in bodyparts)
		if(required_bodytype && !(part.bodytype & required_bodytype))
			continue
		if(!isnull(target_zones) && !(part.body_zone in target_zones))
			continue
		if(LAZYLEN(part.wounds))
			parts += part
	return parts
