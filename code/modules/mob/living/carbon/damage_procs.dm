/mob/living/carbon/apply_damage_package/apply_damage_package(
	datum/damage_package/package,
	blocked = 0,
	check_armor = FALSE,
	wound_clothing = TRUE,
	should_update = TRUE,
	silent = FALSE,
)
	if (package.spread_damage)
		package.def_zone = null
		return ..()

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
	return ..()

/mob/living/carbon/finalize_package_damage(datum/damage_package/package, wound_clothing = TRUE, should_update = TRUE)
	if (package.damage_type == TOX)
		if(AT_TOXIN_VOMIT_THRESHOLD(src))
			apply_status_effect(/datum/status_effect/tox_vomit)
		return ..()

	if (package.damage_type == OXY || package.damage_type == STAMINA)
		return ..()

	var/list/obj/item/bodypart/parts
	if (isbodypart(package.def_zone))
		var/obj/item/bodypart/part = package.def_zone
		if (!(part.bodytype & package.required_biotype) || part.brute_dam + part.burn_dam >= part.max_damage)
			return 0
		parts = list(part)
	else
		parts = get_damageable_bodyparts(package.required_biotype)
		if (islist(package.def_zone))
			parts = (package.def_zone & parts)
		if (!length(parts))
			return 0

	var/damage_taken = 0
	var/should_update = FALSE
	var/damage_per_part = round(package.amount / length(parts), DAMAGE_PRECISION)
	for (var/i in 1 to length(parts))
		var/obj/item/bodypart/part = parts[i]
		var/cur_damage = part.get_damage()
		should_update |= part.receive_damage(package, amount = damage_per_part, should_update = FALSE) // Smartkar: unfuck this
		var/damage_difference = (part.get_damage() - cur_damage)
		damage_taken += damage_difference
		// Overheal gets given to other limbs
		if (damage_per_part < 0 && damage_per_part < damage_difference)
			damage_per_part += (damage_per_part - damage_difference) / (length(parts) - i + 1)

	if (!damage_taken)
		return 0

	if(should_update)
		updatehealth()
	if(should_update)
		update_damage_overlays()
	// Taking brute or burn to bodyparts gives a damage flash
	damageoverlaytemp += damage_taken
	return damage_taken

/mob/living/carbon/valid_package(datum/damage_package/package)
	return TRUE

/mob/living/carbon/get_incoming_damage_modifier(datum/damage_package/package)
	. = ..()
	if (!dna?.species?.damage_modifier)
		return
	. /= (100 + dna.species.damage_modifier) * 0.01

/*
/mob/living/carbon/human/apply_damage(
	damage = 0,
	damagetype = BRUTE,
	def_zone = null,
	blocked = 0,
	forced = FALSE,
	spread_damage = FALSE,
	wound_bonus = 0,
	bare_wound_bonus = 0,
	sharpness = NONE,
	attack_dir = null,
	attacking_item,
	wound_clothing = TRUE,
)

	// Add relevant DR modifiers into blocked value to pass to parent
	blocked += physiology?.damage_resistance
	blocked += dna?.species?.damage_modifier
	return ..()

/mob/living/carbon/human/get_incoming_damage_modifier(
	damage = 0,
	damagetype = BRUTE,
	def_zone = null,
	sharpness = NONE,
	attack_dir = null,
	attacking_item,
)
	var/final_mod = ..()

	switch(damagetype)
		if(BRUTE)
			final_mod *= physiology.brute_mod
		if(BURN)
			final_mod *= physiology.burn_mod
		if(TOX)
			final_mod *= physiology.tox_mod
		if(OXY)
			final_mod *= physiology.oxy_mod
		if(STAMINA)
			final_mod *= physiology.stamina_mod
		if(BRAIN)
			final_mod *= physiology.brain_mod

	return final_mod

//These procs fetch a cumulative total damage from all bodyparts
/mob/living/carbon/get_brute_loss()
	var/amount = 0
	for(var/X in bodyparts)
		var/obj/item/bodypart/BP = X
		amount += BP.brute_dam
	return amount

/mob/living/carbon/get_burn_loss()
	var/amount = 0
	for(var/X in bodyparts)
		var/obj/item/bodypart/BP = X
		amount += BP.burn_dam
	return amount

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

////////////////////////////////////////////

///Returns a list of damaged bodyparts
/mob/living/carbon/proc/get_damaged_bodyparts(brute = FALSE, burn = FALSE, required_bodytype = NONE, target_zone = null)
	var/list/obj/item/bodypart/parts = list()
	for(var/X in bodyparts)
		var/obj/item/bodypart/BP = X
		if(required_bodytype && !(BP.bodytype & required_bodytype))
			continue
		if(!isnull(target_zone) && BP.body_zone != target_zone)
			continue
		if((brute && BP.brute_dam) || (burn && BP.burn_dam))
			parts += BP
	return parts

///Returns a list of damageable bodyparts
/mob/living/carbon/proc/get_damageable_bodyparts(required_bodytype)
	var/list/obj/item/bodypart/parts = list()
	for(var/X in bodyparts)
		var/obj/item/bodypart/BP = X
		if(required_bodytype && !(BP.bodytype & required_bodytype))
			continue
		if(BP.brute_dam + BP.burn_dam < BP.max_damage)
			parts += BP
	return parts


///Returns a list of bodyparts with wounds (in case someone has a wound on an otherwise fully healed limb)
/mob/living/carbon/proc/get_wounded_bodyparts(required_bodytype)
	var/list/obj/item/bodypart/parts = list()
	for(var/X in bodyparts)
		var/obj/item/bodypart/BP = X
		if(required_bodytype && !(BP.bodytype & required_bodytype))
			continue
		if(LAZYLEN(BP.wounds))
			parts += BP
	return parts
*/
