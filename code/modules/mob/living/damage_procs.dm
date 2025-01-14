
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
 * * forced - "Force" exactly the damage dealt. This means it skips damage modifier from blocked or any armor that could be protecting us from check_armor.
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
 * * should_update - If update_health should be called from within this proc.
 * * silent - Prevents armor messages. Only applies if check_armor is TRUE.
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
	should_update = TRUE,
	silent = FALSE,
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
		amount_multiplier = amount_multiplier,
	)

	return apply_damage_package(package, blocked, check_armor, wound_clothing, should_update, silent)

/** Calculates armor for a damage package, processes it and then calls a proc that applies the damage.
 *
 * * blocked - Percent modifier to damage from armor. 100 = 100% less damage dealt, 50% = 50% less damage dealt. If forced or check_armor are TRUE, does not apply.
 * * wound_clothing - If this should cause damage to clothing.
 * * check_armor - If armor checks should be taken into consideration. Does not apply if forced is TRUE.
 * * should_update - If update_health should be called from within this proc.
 * * silent - Prevents armor messages. Only applies if check_armor is TRUE.
 */
/mob/living/proc/apply_damage_package(
	datum/damage_package/package,
	blocked = 0,
	check_armor = FALSE,
	wound_clothing = TRUE,
	should_update = TRUE,
	silent = FALSE,
)
	SHOULD_CALL_PARENT(TRUE)

	if(!package.forced && HAS_TRAIT(src, TRAIT_GODMODE) && package.amount > 0)
		return 0

	if (SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMAGE, package, blocked, check_armor, wound_clothing, should_update, silent) & COMSIG_MOB_PREVENT_DAMAGE)
		return 0

	if (!valid_package(package)) // Checks biotype for simplemobs
		return 0

	package.amount *= CONFIG_GET(number/damage_multiplier)
	if (!package.forced)
		package.amount_multiplier *= get_incoming_damage_modifier(package)
		package.amount *= package.amount_multiplier
		if (check_armor)
			package.amount *= run_armor_check(package, silent = silent)
		else
			package.amount *= (100 - blocked) * 0.01

	if (abs(package.amount) < DAMAGE_PRECISION)
		return 0

	// I'd prefer if we could NOT do this, but carbons have all the fancy logic that basicmobs lack so *shrug*
	package.amount = finalize_package_damage(package, wound_clothing, should_update)
	SEND_SIGNAL(src, COMSIG_MOB_AFTER_APPLY_DAMAGE, package, blocked, check_armor, wound_clothing, should_update, silent)
	return package.amount

/*
 * Actually applies damage packages to mobs
 *
 * * wound_clothing - If this should cause damage to clothing.
 * * should_update - If update_health should be called from within this proc.
 *
 * Returns the amount of damage dealt - does not modify the package itself!
 */
/mob/living/proc/finalize_package_damage(datum/damage_package/package, wound_clothing = TRUE, should_update = FALSE)
	var/damage_dealt = 0
	switch (package.damage_type)
		if (BRUTE)
			if (!can_adjust_brute_loss(package.amount, package.forced))
				return 0
			var/current_brute = get_brute_loss()
			bruteloss = clamp(current_brute + package.amount, 0, maxHealth * 2)
			damage_dealt = get_brute_loss() - current_brute

		if (BURN)
			if (!can_adjust_burn_loss(package.amount, package.forced))
				return 0
			var/current_burn = get_burn_loss()
			burnloss = clamp(current_burn + package.amount, 0, maxHealth * 2)
			damage_dealt = get_burn_loss() - current_burn

		if (TOX)
			if (!can_adjust_tox_loss(package.amount, package.forced))
				return 0
			var/current_tox = get_tox_loss()
			toxloss = clamp(current_tox + package.amount, 0, maxHealth * 2)
			damage_dealt = get_tox_loss() - current_tox

		if (OXY)
			if (!can_adjust_oxy_loss(package.amount, package.forced))
				return 0
			var/current_oxy = get_oxy_loss()
			oxyloss = clamp(current_oxy + package.amount, 0, maxHealth * 2)
			damage_dealt = get_oxy_loss() - current_oxy

		if (STAMINA)
			if (!can_adjust_stamina_loss(package.amount, package.forced))
				return 0
			var/current_stamina = get_stamina_loss()
			staminaloss = clamp(current_stamina + package.amount, 0, maxHealth * 2)
			damage_dealt = get_stamina_loss() - current_stamina
			if(damage_dealt >= 0)
				received_stamina_damage(staminaloss, damage_dealt)

	if (damage_dealt && should_update)
		updatehealth()
	return damage_dealt

/**
 * Used in tandem with [/mob/living/proc/apply_damage] to calculate modifier applied into incoming damage
 */
/mob/living/proc/get_incoming_damage_modifier(datum/damage_package/package)
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_BE_PURE(TRUE)

	var/list/damage_mods = list()
	SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, damage_mods, damage, damagetype, def_zone, sharpness, attack_dir, attacking_item)

	var/final_mod = 1

	if (package.damage_type == TOX)
		if (HAS_TRAIT(src, TRAIT_TOXINLOVER))
			final_mod *= -1
		else if (HAS_TRAIT(src, TRAIT_TOXIMMUNE))
			return 0
	else if (package.damage_type == OXY)
		if (HAS_TRAIT(src, TRAIT_NOBREATH))
			return 0

	for(var/new_mod in damage_mods)
		final_mod *= new_mod

	return final_mod

/**
 * Simply a wrapper for calling mob getXLoss() procs to get a certain damage type,
 * when you don't know what damage type you're getting exactly.
 */
/mob/living/proc/get_current_damage_of_type(damagetype = BRUTE)
	switch(damagetype)
		if(BRUTE)
			return get_brute_loss()
		if(BURN)
			return get_burn_loss()
		if(TOX)
			return get_tox_loss()
		if(OXY)
			return get_oxy_loss()
		if(STAMINA)
			return get_stamina_loss()

/// Additional per-type checks for package validity
/mob/living/proc/valid_package(datum/damage_package/package)
	if (!(package.required_biotype & mob_biotypes))
		return FALSE
	return TRUE

/// Return the total damage of all types which update your health
/mob/living/proc/get_total_damage()
	return round(get_brute_loss() + get_burn_loss() + get_tox_loss() + get_oxy_loss(), DAMAGE_PRECISION)

/mob/living/proc/get_brute_loss()
	return bruteloss

/mob/living/proc/can_adjust_brute_loss(amount, forced)
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_BRUTE_DAMAGE, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/get_burn_loss()
	return bruteloss

/mob/living/proc/can_adjust_burn_loss(amount, forced)
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_BURN_DAMAGE, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/get_tox_loss()
	return toxloss

/mob/living/proc/can_adjust_tox_loss(amount, forced)
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_TOX_DAMAGE, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/get_oxy_loss()
	return oxyloss

/mob/living/proc/can_adjust_oxy_loss(amount, forced, required_biotype, required_respiration_type)
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_OXY_DAMAGE, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE

	if(forced)
		return TRUE

	if (required_respiration_type)
		var/obj/item/organ/lungs/affected_lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
		if(isnull(affected_lungs))
			if(!(mob_respiration_type & required_respiration_type))  // if the mob has no lungs, use mob_respiration_type
				return FALSE
		else
			if(!(affected_lungs.respiration_type & required_respiration_type)) // otherwise use the lungs' respiration_type
				return FALSE

	return TRUE

/mob/living/proc/get_stamina_loss()
	return staminaloss

/mob/living/proc/can_adjust_stamina_loss(amount, forced)
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_STAMINA_DAMAGE, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/*
 * The mob has received stamina damage
 *
 * * current_level: The mob's current stamina damage amount (to save unnecessary get_stamina_loss() calls)
 * * amount_actual: The amount of stamina damage received, in actuality
 * * For example, if you are taking 50 stamina damage but are at 90, you would actually only receive 30 stamina damage (due to the cap)
 * * amount: The amount of stamina damage received, raw
 */
/mob/living/proc/received_stamina_damage(current_level, amount_actual, amount)
	addtimer(CALLBACK(src, PROC_REF(set_stamina_loss), 0, TRUE, TRUE), stamina_regen_time, TIMER_UNIQUE|TIMER_OVERRIDE)

/// Heal up to amount damage, in a given order
/mob/living/proc/heal_ordered_damage(amount, list/damage_types)
	var/damage_healed = 0
	for(var/damage_type in damage_types)
		var/amount_to_heal = min(abs(amount), get_current_damage_of_type(damage_type)) // Heal only up to the amount of damage we have
		if(!amount_to_heal)
			continue
		damage_healed += -apply_damage(amount_to_heal, amount, spread_damage)
		amount -= amount_to_heal // Remove what we healed from our current amount
		if(!amount)
			break
	return damage_healed

/mob/living/proc/adjust_organ_loss(slot, amount, maximum, required_organ_flag)
	return

/mob/living/proc/set_organ_loss(slot, amount, maximum, required_organ_flag)
	return

/mob/living/proc/get_organ_loss(slot)
	return

/// Applies various common status effects or common hardcoded mob effects
/mob/living/proc/apply_effect(effect = 0,effecttype = EFFECT_STUN, blocked = 0)
	var/hit_percent = (100 - blocked) / 100
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
