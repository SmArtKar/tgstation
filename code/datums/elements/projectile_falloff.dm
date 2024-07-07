/// Reduces projectile damage, stamina damage and would chance when it passes a tile
/datum/element/projectile_falloff
	element_flags = ELEMENT_BESPOKE
	argument_hash_start_idx = 2

	var/damage_falloff
	var/stamina_falloff
	var/wound_falloff

/datum/element/projectile_falloff/Attach(datum/target, damage_falloff = 0, stamina_falloff = 0, wound_falloff = 0)
	. = ..()
	if (!isprojectile(target))
		return ELEMENT_INCOMPATIBLE

	src.damage_falloff = damage_falloff
	src.stamina_falloff = stamina_falloff
	src.wound_falloff = wound_falloff
	RegisterSignal(target, COMSIG_PROJECTILE_AFTER_MOVE, PROC_REF(after_move))

/datum/element/projectile_falloff/proc/after_move(obj/projectile/source, distance_moved)
	SIGNAL_HANDLER

	source.damage -= damage_falloff * distance_moved
	source.stamina -= stamina_falloff * distance_moved
	source.wound_bonus -= wound_falloff * distance_moved
	source.bare_wound_bonus -= wound_falloff * distance_moved
