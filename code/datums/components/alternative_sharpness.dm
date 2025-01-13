/// Allows items and mobs to have different sharpness for right click attacks
/datum/component/alternative_sharpness
	/// Sharpness we change the attack to
	var/alt_sharpness = NONE
	/// Overrides for continuous attack verbs when performing an alt attack
	var/verbs_continuous = null
	/// Overrides for simple attack verbs when performing an alt attack
	var/verbs_simple = null
	/// Value by which we offset our force during the attack
	var/force_mod = 0
	/// Trait required for us to trigger
	var/required_trait = null

/datum/component/alternative_sharpness/Initialize(alt_sharpness, verbs_continuous = null, verbs_simple = null, force_mod = 0, required_trait = null)
	if (!isitem(parent) && !isliving(parent))
		return COMPONENT_INCOMPATIBLE

	src.alt_sharpness = alt_sharpness
	src.verbs_continuous = verbs_continuous
	src.verbs_simple = verbs_simple
	src.force_mod = force_mod
	src.required_trait = required_trait

/datum/component/alternative_sharpness/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_CREATED_DAMAGE_PACKAGE, PROC_REF(item_package_created))
	RegisterSignal(parent, COMSIG_MOB_CREATED_DAMAGE_PACKAGE, PROC_REF(mob_package_created))

/datum/component/alternative_sharpness/proc/item_package_created(obj/item/source, datum/damage_package/package, atom/target, mob/living/user, list/modifiers)
	SIGNAL_HANDLER

	if (!LAZYACCESS(modifiers, RIGHT_CLICK))
		return

	if (required_trait && !HAS_TRAIT(source, required_trait))
		return

	package.amount += force_mod
	package.sharpness = alt_sharpness

	if (isnull(verbs_continuous))
		return

	var/verb_index = rand(1, length(verbs_continuous))
	var/verb_simple = verbs_simple[verb_index]
	var/verb_continuous = verbs_continuous[verb_index]
	var/no_damage_feedback = null

	if (isobj(target))
		var/obj/as_obj = target
		if (source.demolition_mod < 1)
			verb_simple = "ineffectively " + verb_simple
			verb_continuous = "ineffectively " + verb_continuous
		if (package.amount < as_obj.damage_deflection)
			no_damage_feedback = ", [as_obj.no_damage_feedback]"

	package.attack_message_spectator = span_danger("[user] [verb_continuous] [target] with [source][no_damage_feedback]!")
	package.attack_message_attacker = span_danger("You [verb_simple] [target] with [source][no_damage_feedback]!")

/datum/component/alternative_sharpness/proc/mob_package_created(mob/living/source, datum/damage_package/package, atom/target, amount, damtype, forced, ignore_custom, list/modifiers)
	SIGNAL_HANDLER

	if (!LAZYACCESS(modifiers, RIGHT_CLICK))
		return

	if (required_trait && !HAS_TRAIT(source, required_trait))
		return

	package.amount += force_mod
	package.sharpness = alt_sharpness

	if (isnull(verbs_continuous))
		return

	var/verb_index = rand(1, length(verbs_continuous))
	var/no_damage_feedback = null

	if (isobj(target))
		var/obj/as_obj = target
		if (package.amount < as_obj.damage_deflection)
			no_damage_feedback = ", [as_obj.no_damage_feedback]"

	package.attack_message_spectator = span_danger("[source] [verbs_continuous[verb_index]] [src][no_damage_feedback]!")
	package.attack_message_attacker = span_danger("You [verbs_simple[verb_index]] [src][no_damage_feedback]!")
