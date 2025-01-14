
/**
 * Applies damage to this mob.
 *
 * Sends [COMSIG_MOB_APPLY_DAMAGE]
 *
 * Arguments:
 * * damage - Amount of damage
 * * damage_type - Type of damage dealt, can be BRUTE, BURN, TOX, OXY and STAMINA.
 * * damage_flag - Armor which would've protected from this damage, determines the sort of damage we're dealing with.
 * * attack_flags - What sort of an attack this is, melee, blob, ranged, etc.
 * * def_zone - What body zone is being hit. Or a reference to what bodypart is being hit.
 * * blocked - Percent modifier to damage from armor. 100 = 100% less damage dealt, 50% = 50% less damage dealt. If forced or check_armor are TRUE, does not apply.
 * * attack_dir - Direction of the attack from the self to attacker. // SMARTKAR TODO: reverse all directions because this was written by someone with too much free time
 * * armor_penetration - Flat reduction from armor, only works when check_armor is TRUE.
 * * armor_multiplier - Armor multiplier, applied before armor_penetration and only works when check_armor is TRUE.
 * * forced - "Force" exactly the damage dealt. This means it skips damage modifier from blocked.
 * * hit_by - Item, mob or projectile that dealt the damage.
 * * source - Who actually dealt the damage - turret that fired the gun, greyshirt hit you with a toolbox, punched you, etc.
 * * spread_damage - For carbons, spreads the damage across all bodyparts rather than just the targeted zone.
 * * wound_bonus - Bonus modifier for wound chance.
 * * bare_wound_bonus - Bonus modifier for wound chance on bare skin.
 * * sharpness - Sharpness of the weapon.
 * * required_biotype - Biotype that the mob/bodypart must posess to be able to take this damage.
 * * amount_multiplier - Total damage multiplier, done last after everything else. Does not apply if forced is true.
 * * check_armor - If armor checks should be taken into consideration. Does not apply if forced is TRUE.
 * * wound_clothing - If this should cause damage to clothing.
 * * no_update - Prevents update_health calls from within this proc.
 *
 * Returns the amount of damage dealt.
 */


/mob/living/proc/apply_damage(
	amount = 0,
	damage_type = BRUTE,
	damage_flag = null,
	attack_flags = NONE,
	def_zone = null,
	blocked = 0,
	attack_dir = NONE,
	armor_penetration = 0,
	armor_multiplier = 1,
	forced = FALSE,
	atom/hit_by = null,
	atom/source = null,
	spread_damage = FALSE,
	wound_bonus = 0,
	bare_wound_bonus = 0,
	sharpness = NONE,
	required_biotype = ALL,
	amount_multiplier = 1,
	check_armor = FALSE,
	wound_clothing = TRUE,
	ignore_undamageable = FALSE,
	no_update = FALSE,
)
	// This is merely a wrapper, and thus should not be overriden
	SHOULD_NOT_OVERRIDE(TRUE)

	var/datum/damage_package/package = new(
		amount = amount,
		damage_type = damage_type,
		damage_flag = damage_flag,
		attack_flags = attack_flags,
		def_zone = def_zone,
		attack_dir = attack_dir,
		armor_penetration = armor_penetration,
		armor_multiplier = armor_multiplier,
		forced = forced,
		hit_by = hit_by,
		source = source,
		spread_damage = spread_damage,
		wound_bonus = wound_bonus,
		bare_wound_bonus = bare_wound_bonus,
		sharpness = sharpness,
		required_biotype = required_biotype,
		ignore_undamageable = ignore_undamageable,
		amount_multiplier = amount_multiplier,
	)

	return apply_damage_package(package, blocked, check_armor, wound_clothing, no_update)

/** Calculates armor for a damage package, processes it and then applies the damage.
 *
 * * blocked - Percent modifier to damage from armor. 100 = 100% less damage dealt, 50% = 50% less damage dealt. If forced or check_armor are TRUE, does not apply.
 * * wound_clothing - If this should cause damage to clothing.
 * * check_armor - If armor checks should be taken into consideration. Does not apply if forced is TRUE.
 * * no_update - Prevents update_health calls from within this proc.
 */
/mob/living/proc/apply_damage_package(
	datum/damage_package/package,
	blocked = 0,
	check_armor = FALSE,
	wound_clothing = TRUE,
	no_update = FALSE,
)
	SHOULD_CALL_PARENT(TRUE)

	if (SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMAGE, package, blocked, check_armor, wound_clothing, no_update) & COMSIG_MOB_PREVENT_DAMAGE)
		return 0

	if (package.spread_damage)
		package.def_zone = null
	else if (islist(package.def_zone))
		var/list/taken_zones = list()
		var/list/new_zones = list()
		for (var/zone in package.def_zone)
			var/zone_lookup = package.def_zone
			if (!zone_lookup || (zone_lookup in taken_zones))
				zone_lookup = get_random_valid_zone(blacklisted_parts = taken_zones)
			var/random_zone = check_zone(zone_lookup)
			var/obj/item/bodypart/part = get_bodypart(random_zone)
			if (!part)
				part = bodyparts[1]
			if (part.body_zone in taken_zones)
				break
			taken_zones += part.body_zone
			new_zones += part
		package.def_zone = new_zones
		if (!length(package.def_zone))
			package.def_zone = null
	else if (!isbodypart(package.def_zone))
		var/random_zone = check_zone(package.def_zone || get_random_valid_zone())
		package.def_zone = get_bodypart(random_zone) || bodyparts[1]

	if (!package.forced)
		package.amount_multiplier *= get_incoming_damage_modifier(package)
		package.amount *= package.amount_multiplier
		if (check_armor)
			run_armor_check(package)
		else
			package.amount *= (100 - blocked) * 0.01

	if (!valid_package(package))
		return 0

	if(package.amount < DAMAGE_PRECISION)
		return 0



	SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMAGE, package, blocked, check_armor, wound_clothing, no_update)
	return damage_dealt

	/*
	var/damage_amount = damage
	if(!forced)
		damage_amount *= ((100 - blocked) / 100)
		damage_amount *= get_incoming_damage_modifier(damage_amount, damage_type, def_zone, sharpness, attack_dir, hit_by)
	if(damage_amount <= 0)
		return 0

	var/damage_dealt = 0
	switch(damage_type)
		if(BRUTE)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				if(actual_hit.receive_damage(
					brute = damage_amount,
					burn = 0,
					forced = forced,
					wound_bonus = wound_bonus,
					bare_wound_bonus = bare_wound_bonus,
					sharpness = sharpness,
					attack_dir = attack_dir,
					damage_source = hit_by,
					wound_clothing = wound_clothing,
				))
					update_damage_overlays()
				damage_dealt = actual_hit.get_damage() - delta // Unfortunately bodypart receive_damage doesn't return damage dealt so we do it manually
			else
				damage_dealt = -1 * adjustBruteLoss(damage_amount, forced = forced)
		if(BURN)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				if(actual_hit.receive_damage(
					brute = 0,
					burn = damage_amount,
					forced = forced,
					wound_bonus = wound_bonus,
					bare_wound_bonus = bare_wound_bonus,
					sharpness = sharpness,
					attack_dir = attack_dir,
					damage_source = hit_by,
					wound_clothing = wound_clothing,
				))
					update_damage_overlays()
				damage_dealt = actual_hit.get_damage() - delta // See above
			else
				damage_dealt = -1 * adjustFireLoss(damage_amount, forced = forced)
		if(TOX)
			damage_dealt = -1 * adjustToxLoss(damage_amount, forced = forced)
		if(OXY)
			damage_dealt = -1 * adjustOxyLoss(damage_amount, forced = forced)
		if(STAMINA)
			damage_dealt = -1 * adjustStaminaLoss(damage_amount, forced = forced)

	SEND_SIGNAL(src, COMSIG_MOB_AFTER_APPLY_DAMAGE, damage_dealt, damage_type, def_zone, blocked, wound_bonus, bare_wound_bonus,sharpness, attack_dir, hit_by, wound_clothing)
	return damage_dealt

/**
 * Used in tandem with [/mob/living/proc/apply_damage] to calculate modifier applied into incoming damage
 */
/mob/living/proc/get_incoming_damage_modifier(
	damage = 0,
	damagetype = BRUTE,
	def_zone = null,
	sharpness = NONE,
	attack_dir = null,
	attacking_item,
)
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_BE_PURE(TRUE)

	var/list/damage_mods = list()
	SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, damage_mods, damage, damagetype, def_zone, sharpness, attack_dir, attacking_item)

	var/final_mod = 1
	for(var/new_mod in damage_mods)
		final_mod *= new_mod
	return final_mod

/**
 * Simply a wrapper for calling mob adjustXLoss() procs to heal a certain damage type,
 * when you don't know what damage type you're healing exactly.
 */
/mob/living/proc/heal_damage_type(heal_amount = 0, damagetype = BRUTE)
	heal_amount = abs(heal_amount) * -1

	switch(damagetype)
		if(BRUTE)
			return adjustBruteLoss(heal_amount)
		if(BURN)
			return adjustFireLoss(heal_amount)
		if(TOX)
			return adjustToxLoss(heal_amount)
		if(OXY)
			return adjustOxyLoss(heal_amount)
		if(STAMINA)
			return adjustStaminaLoss(heal_amount)

/// return the damage amount for the type given
/**
 * Simply a wrapper for calling mob getXLoss() procs to get a certain damage type,
 * when you don't know what damage type you're getting exactly.
 */
/mob/living/proc/get_current_damage_of_type(damagetype = BRUTE)
	switch(damagetype)
		if(BRUTE)
			return getBruteLoss()
		if(BURN)
			return getFireLoss()
		if(TOX)
			return getToxLoss()
		if(OXY)
			return getOxyLoss()
		if(STAMINA)
			return getStaminaLoss()

/// return the total damage of all types which update your health
/mob/living/proc/get_total_damage(precision = DAMAGE_PRECISION)
	return round(getBruteLoss() + getFireLoss() + getToxLoss() + getOxyLoss(), precision)

/// applies various common status effects or common hardcoded mob effects
/mob/living/proc/apply_effect(effect = 0,effecttype = EFFECT_STUN, blocked = 0)
	var/hit_percent = (100-blocked)/100
	if(!effect || (hit_percent <= 0))
		return FALSE
	switch(effecttype)
		if(EFFECT_STUN)
			Stun(effect * hit_percent)
		if(EFFECT_KNOCKDOWN)
			Knockdown(effect * hit_percent)
		if(EFFECT_PARALYZE)
			Paralyze(effect * hit_percent)
		if(EFFECT_IMMOBILIZE)
			Immobilize(effect * hit_percent)
		if(EFFECT_UNCONSCIOUS)
			Unconscious(effect * hit_percent)

	return TRUE

/**
 * Applies multiple effects at once via [/mob/living/proc/apply_effect]
 *
 * Pretty much only used for projectiles applying effects on hit,
 * don't use this for anything else please just cause the effects directly
 */
/mob/living/proc/apply_effects(
		stun = 0,
		knockdown = 0,
		unconscious = 0,
		slur = 0 SECONDS, // Speech impediment, not technically an effect
		stutter = 0 SECONDS, // Ditto
		eyeblur = 0 SECONDS,
		drowsy = 0 SECONDS,
		blocked = 0, // This one's not an effect, don't be confused - it's block chance
		stamina = 0, // This one's a damage type, and not an effect
		jitter = 0 SECONDS,
		paralyze = 0,
		immobilize = 0,
	)

	if(blocked >= 100)
		return FALSE

	if(stun)
		apply_effect(stun, EFFECT_STUN, blocked)
	if(knockdown)
		apply_effect(knockdown, EFFECT_KNOCKDOWN, blocked)
	if(unconscious)
		apply_effect(unconscious, EFFECT_UNCONSCIOUS, blocked)
	if(paralyze)
		apply_effect(paralyze, EFFECT_PARALYZE, blocked)
	if(immobilize)
		apply_effect(immobilize, EFFECT_IMMOBILIZE, blocked)

	if(stamina)
		apply_damage(stamina, STAMINA, null, blocked)

	if(drowsy)
		adjust_drowsiness(drowsy)
	if(eyeblur)
		adjust_eye_blur(eyeblur)
	if(jitter && !check_stun_immunity(CANSTUN))
		adjust_jitter(jitter)
	if(slur)
		adjust_slurring(slur)
	if(stutter)
		adjust_stutter(stutter)

	return TRUE

/// Returns a multiplier to apply to a specific kind of damage
/mob/living/proc/get_damage_mod(damage_type)
	switch(damage_type)
		if (OXY)
			return HAS_TRAIT(src, TRAIT_NOBREATH) ? 0 : 1
		if (TOX)
			if (HAS_TRAIT(src, TRAIT_TOXINLOVER))
				return -1
			return HAS_TRAIT(src, TRAIT_TOXIMMUNE) ? 0 : 1
	return 1

/mob/living/proc/getBruteLoss()
	return bruteloss

/mob/living/proc/can_adjust_brute_loss(amount, forced, required_bodytype)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_BRUTE_DAMAGE, BRUTE, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if (!can_adjust_brute_loss(amount, forced, required_bodytype))
		return 0
	. = bruteloss
	bruteloss = clamp((bruteloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= bruteloss
	if(!.) // no change, no need to update
		return 0
	if(updating_health)
		updatehealth()


/mob/living/proc/setBruteLoss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	. = bruteloss
	bruteloss = amount

	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()
	. -= bruteloss

/mob/living/proc/getOxyLoss()
	return oxyloss

/mob/living/proc/can_adjust_oxy_loss(amount, forced, required_biotype, required_respiration_type)
	if(!forced)
		if(HAS_TRAIT(src, TRAIT_GODMODE))
			return FALSE
		if (required_respiration_type)
			var/obj/item/organ/lungs/affected_lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
			if(isnull(affected_lungs))
				if(!(mob_respiration_type & required_respiration_type))  // if the mob has no lungs, use mob_respiration_type
					return FALSE
			else
				if(!(affected_lungs.respiration_type & required_respiration_type)) // otherwise use the lungs' respiration_type
					return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_OXY_DAMAGE, OXY, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjustOxyLoss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL, required_respiration_type = ALL)
	if(!can_adjust_oxy_loss(amount, forced, required_biotype, required_respiration_type))
		return 0
	. = oxyloss
	oxyloss = clamp((oxyloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= oxyloss
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/mob/living/proc/setOxyLoss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL, required_respiration_type = ALL)
	if(!forced)
		if(HAS_TRAIT(src, TRAIT_GODMODE))
			return FALSE

		var/obj/item/organ/lungs/affected_lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
		if(isnull(affected_lungs))
			if(!(mob_respiration_type & required_respiration_type))
				return FALSE
		else
			if(!(affected_lungs.respiration_type & required_respiration_type))
				return FALSE
	. = oxyloss
	oxyloss = amount
	. -= oxyloss
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/mob/living/proc/getToxLoss()
	return toxloss

/mob/living/proc/can_adjust_tox_loss(amount, forced, required_biotype = ALL)
	if(!forced && (HAS_TRAIT(src, TRAIT_GODMODE) || !(mob_biotypes & required_biotype)))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_TOX_DAMAGE, TOX, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjustToxLoss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL)
	if(!can_adjust_tox_loss(amount, forced, required_biotype))
		return 0

	if(!forced && HAS_TRAIT(src, TRAIT_TOXINLOVER)) //damage becomes healing and healing becomes damage
		amount = -amount
		if(HAS_TRAIT(src, TRAIT_TOXIMMUNE)) //Prevents toxin damage, but not healing
			amount = min(amount, 0)
		if(blood_volume)
			if(amount > 0)
				blood_volume = max(blood_volume - (5 * amount), 0)
			else
				blood_volume = max(blood_volume - amount, 0)

	else if(!forced && HAS_TRAIT(src, TRAIT_TOXIMMUNE)) //Prevents toxin damage, but not healing
		amount = min(amount, 0)

	. = toxloss
	toxloss = clamp((toxloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= toxloss

	if(!.) // no change, no need to update
		return FALSE

	if(updating_health)
		updatehealth()


/mob/living/proc/setToxLoss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(!forced && !(mob_biotypes & required_biotype))
		return FALSE
	. = toxloss
	toxloss = amount
	. -= toxloss
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/mob/living/proc/getFireLoss()
	return fireloss

/mob/living/proc/can_adjust_fire_loss(amount, forced, required_bodytype)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_BURN_DAMAGE, BURN, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjustFireLoss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if(!can_adjust_fire_loss(amount, forced, required_bodytype))
		return 0
	. = fireloss
	fireloss = clamp((fireloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= fireloss
	if(. == 0) // no change, no need to update
		return
	if(updating_health)
		updatehealth()

/mob/living/proc/setFireLoss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return 0
	. = fireloss
	fireloss = amount
	. -= fireloss
	if(. == 0) // no change, no need to update
		return 0
	if(updating_health)
		updatehealth()

/mob/living/proc/adjustOrganLoss(slot, amount, maximum, required_organ_flag)
	return

/mob/living/proc/setOrganLoss(slot, amount, maximum, required_organ_flag)
	return

/mob/living/proc/get_organ_loss(slot)
	return

/mob/living/proc/getStaminaLoss()
	return staminaloss

/mob/living/proc/can_adjust_stamina_loss(amount, forced, required_biotype = ALL)
	if(!forced && (!(mob_biotypes & required_biotype) || HAS_TRAIT(src, TRAIT_GODMODE)))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_STAMINA_DAMAGE, STAMINA, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjustStaminaLoss(amount, updating_stamina = TRUE, forced = FALSE, required_biotype = ALL)
	if(!can_adjust_stamina_loss(amount, forced, required_biotype))
		return 0
	var/old_amount = staminaloss
	staminaloss = clamp((staminaloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, max_stamina)
	var/delta = old_amount - staminaloss
	if(delta <= 0)
		// need to check for stamcrit AFTER canadjust but BEFORE early return here
		received_stamina_damage(staminaloss, -1 * delta)
	if(delta == 0) // no change, no need to update
		return 0
	if(updating_stamina)
		updatehealth()
	return delta

/mob/living/proc/setStaminaLoss(amount, updating_stamina = TRUE, forced = FALSE, required_biotype = ALL)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return 0
	if(!forced && !(mob_biotypes & required_biotype))
		return 0
	var/old_amount = staminaloss
	staminaloss = amount
	var/delta = old_amount - staminaloss
	if(delta <= 0 && amount >= DAMAGE_PRECISION)
		received_stamina_damage(staminaloss, -1 * delta, amount)
	if(delta == 0) // no change, no need to update
		return 0
	if(updating_stamina)
		updatehealth()
	return delta

/// The mob has received stamina damage
///
/// - current_level: The mob's current stamina damage amount (to save unnecessary getStaminaLoss() calls)
/// - amount_actual: The amount of stamina damage received, in actuality
/// For example, if you are taking 50 stamina damage but are at 90, you would actually only receive 30 stamina damage (due to the cap)
/// - amount: The amount of stamina damage received, raw
/mob/living/proc/received_stamina_damage(current_level, amount_actual, amount)
	addtimer(CALLBACK(src, PROC_REF(setStaminaLoss), 0, TRUE, TRUE), stamina_regen_time, TIMER_UNIQUE|TIMER_OVERRIDE)

/**
 * heal ONE external organ, organ gets randomly selected from damaged ones.
 *
 * returns the net change in damage
 */
/mob/living/proc/heal_bodypart_damage(brute = 0, burn = 0, updating_health = TRUE, required_bodytype = NONE, target_zone = null)
	. = (adjustBruteLoss(-abs(brute), updating_health = FALSE) + adjustFireLoss(-abs(burn), updating_health = FALSE))
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/// damage ONE external organ, organ gets randomly selected from damaged ones.
/mob/living/proc/take_bodypart_damage(brute = 0, burn = 0, updating_health = TRUE, required_bodytype, check_armor = FALSE, wound_bonus = 0, bare_wound_bonus = 0, sharpness = NONE)
	. = (adjustBruteLoss(abs(brute), updating_health = FALSE) + adjustFireLoss(abs(burn), updating_health = FALSE))
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/// heal MANY bodyparts, in random order. note: stamina arg nonfunctional for carbon mobs
/mob/living/proc/heal_overall_damage(brute = 0, burn = 0, stamina = 0, required_bodytype, updating_health = TRUE, forced = FALSE)
	. = (adjustBruteLoss(-abs(brute), updating_health = FALSE, forced = forced) + \
			adjustFireLoss(-abs(burn), updating_health = FALSE, forced = forced) + \
			adjustStaminaLoss(-abs(stamina), updating_stamina = FALSE, forced = forced))
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/// damage MANY bodyparts, in random order. note: stamina arg nonfunctional for carbon mobs
/mob/living/proc/take_overall_damage(brute = 0, burn = 0, stamina = 0, updating_health = TRUE, forced = FALSE, required_bodytype)
	. = (adjustBruteLoss(abs(brute), updating_health = FALSE, forced = forced) + \
			adjustFireLoss(abs(burn), updating_health = FALSE, forced = forced) + \
			adjustStaminaLoss(abs(stamina), updating_stamina = FALSE, forced = forced))
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

///heal up to amount damage, in a given order
/mob/living/proc/heal_ordered_damage(amount, list/damage_types)
	. = 0 //we'll return the amount of damage healed
	for(var/damagetype in damage_types)
		var/amount_to_heal = min(abs(amount), get_current_damage_of_type(damagetype)) //heal only up to the amount of damage we have
		if(amount_to_heal)
			. += heal_damage_type(amount_to_heal, damagetype)
			amount -= amount_to_heal //remove what we healed from our current amount
		if(!amount)
			break
*/
