/atom
	///any atom that uses integrity and can be damaged must set this to true, otherwise the integrity procs will throw an error
	var/uses_integrity = FALSE

	VAR_PROTECTED/datum/armor/armor_type = /datum/armor/none
	VAR_PRIVATE/datum/armor/armor

	VAR_PRIVATE/atom_integrity //defaults to max_integrity
	var/max_integrity = 500
	var/integrity_failure = 0 //0 if we have no special broken behavior, otherwise is a percentage of at what point the atom breaks. 0.5 being 50%
	///Damage under this value will be completely ignored
	var/damage_deflection = 0

	var/resistance_flags = NONE // INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ON_FIRE | UNACIDABLE | ACID_PROOF

/// Wrapper for taking damage - ensures that the atom is in a valid state to take damage, and then assembles and processes a damage package
/// Returns the final taken package!
/atom/proc/take_damage(DAMAGE_PROC_ARGS, datum/damage_package/direct_package = null, sound_effect = TRUE)
	if(!uses_integrity)
		CRASH("[src] had /atom/proc/take_damage() called on it without it being a type that has uses_integrity = TRUE!")

	if(QDELETED(src))
		CRASH("[src] taking damage after deletion")

	if(atom_integrity <= 0)
		CRASH("[src] taking damage while having <= 0 integrity")

	if(sound_effect)
		play_attack_sound(amount, damage_type, damage_flag)

	if(resistance_flags & INDESTRUCTIBLE)
		return

	var/datum/damage_package/package = direct_package || new(DAMAGE_PROC_PASSING)

	if(SEND_SIGNAL(src, COMSIG_ATOM_TAKE_DAMAGE, package) & COMPONENT_NO_TAKE_DAMAGE)
		return

	return process_damage_package(package)

/// Proc that is actually applies damage based on a damage package
/atom/proc/process_damage_package(datum/damage_package/package)
	run_atom_armor(package)

	if(package.amount < DAMAGE_PRECISION)
		return

	if(SEND_SIGNAL(src, COMSIG_ATOM_PROCESSING_DAMAGE_PACKAGE, package) & COMPONENT_CANCEL_DAMAGE_PACKAGE)
		return

	var/previous_atom_integrity = atom_integrity
	update_integrity(atom_integrity - package.amount)
	var/integrity_failure_amount = integrity_failure * max_integrity

	//BREAKING FIRST
	if(integrity_failure && previous_atom_integrity > integrity_failure_amount && atom_integrity <= integrity_failure_amount)
		atom_break(package.damage_flag)

	//DESTROYING SECOND
	if(atom_integrity <= 0 && previous_atom_integrity > 0)
		atom_destruction(package.damage_flag)
	return package

/// Proc for recovering atom_integrity. Returns the amount repaired by
/atom/proc/repair_damage(amount)
	if(amount <= 0) // We only recover here
		return
	var/new_integrity = min(max_integrity, atom_integrity + amount)
	. = new_integrity - atom_integrity

	update_integrity(new_integrity)

	if(integrity_failure && atom_integrity > integrity_failure * max_integrity)
		atom_fix()

/// Handles the integrity of an atom changing. This must be called instead of changing integrity directly.
/atom/proc/update_integrity(new_value)
	SHOULD_NOT_OVERRIDE(TRUE)
	if(!uses_integrity)
		CRASH("/atom/proc/update_integrity() was called on [src] when it doesnt use integrity!")
	var/old_value = atom_integrity
	new_value = max(0, new_value)
	if(atom_integrity == new_value)
		return
	atom_integrity = new_value
	on_update_integrity(old_value, new_value)
	return new_value

/// Handle updates to your atom's integrity
/atom/proc/on_update_integrity(old_value, new_value)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ATOM_INTEGRITY_CHANGED, old_value, new_value)

/// This mostly exists to keep atom_integrity private. Might be useful in the future.
/atom/proc/get_integrity()
	SHOULD_BE_PURE(TRUE)
	return atom_integrity

/// Similar to get_integrity, but returns the percentage as [0-1] instead.
/atom/proc/get_integrity_percentage()
	SHOULD_BE_PURE(TRUE)
	return round(atom_integrity / max_integrity, 0.01)

/// Modifies a damage package based on atom armor
/atom/proc/run_atom_armor(datum/damage_package/package)
	RETURN_TYPE(/datum/damage_package)
	if(!uses_integrity)
		CRASH("/atom/proc/run_atom_armor was called on [src] without being implemented as a type that uses integrity!")

	if(package.damage_flag == MELEE && package.amount < damage_deflection)
		return

	if(package.damage_type != BRUTE && package.damage_type != BURN)
		return

	var/armor_protection = 0

	if(package.damage_flag)
		armor_protection = get_armor_rating(package.damage_flag)

	if(armor_protection) //Only apply weak-against-armor/hollowpoint effects if there actually IS armor.
		armor_protection = clamp(PENETRATE_ARMOR(armor_protection * package.armor_multiplier, package.armor_penetration), min(armor_protection, 0), 100)

	package.amount = round(package.amount * (100 - armor_protection) * 0.01, DAMAGE_PRECISION)
	return package

///the sound played when the atom is damaged.
/atom/proc/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(damage_amount)
				playsound(src, 'sound/items/weapons/smash.ogg', 50, TRUE)
			else
				playsound(src, 'sound/items/weapons/tap.ogg', 50, TRUE)
		if(BURN)
			playsound(src.loc, 'sound/items/tools/welder.ogg', 100, TRUE)

///Called to get the damage that hulks will deal to the atom.
/atom/proc/hulk_damage()
	return 150 //the damage hulks do on punches to this atom, is affected by melee armor

/atom/proc/attack_generic(DAMAGE_PROC_ARGS, datum/damage_package/direct_package = null, mob/user, sound_effect = TRUE)
	if(!uses_integrity)
		CRASH("unimplemented /atom/proc/attack_generic()!")

	user.do_attack_animation(src)
	user.changeNext_move(CLICK_CD_MELEE)
	return take_damage(DAMAGE_PROC_PASSING, direct_package = direct_package, sound_effect = sound_effect)

/// Called after the atom takes damage and integrity is below integrity_failure level
/atom/proc/atom_break(damage_flag)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ATOM_BREAK, damage_flag)

/// Called when integrity is repaired above the breaking point having been broken before
/atom/proc/atom_fix()
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ATOM_FIX)

///what happens when the atom's integrity reaches zero.
/atom/proc/atom_destruction(damage_flag)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ATOM_DESTRUCTION, damage_flag)

///changes max_integrity while retaining current health percentage, returns TRUE if the atom got broken.
/atom/proc/modify_max_integrity(new_max, can_break = TRUE, damage_type = BRUTE)
	if(!uses_integrity)
		CRASH("/atom/proc/modify_max_integrity() was called on [src] when it doesnt use integrity!")
	var/current_integrity = atom_integrity
	var/current_max = max_integrity

	if(current_integrity != 0 && current_max != 0)
		var/percentage = current_integrity / current_max
		current_integrity = max(1, round(percentage * new_max)) //don't destroy it as a result
		atom_integrity = current_integrity

	max_integrity = new_max

	if(can_break && integrity_failure && current_integrity <= integrity_failure * max_integrity)
		atom_break(damage_type)
		return TRUE
	return FALSE

/// A cut-out proc for [/atom/proc/bullet_act] so living mobs can have their own armor behavior checks without causing issues with needing their own on_hit call
/atom/proc/check_projectile_armor(def_zone, obj/projectile/impacting_projectile, is_silent)
	if(uses_integrity)
		return clamp(PENETRATE_ARMOR(get_armor_rating(impacting_projectile.armor_flag), impacting_projectile.armor_penetration), 0, 100)
	return 0
