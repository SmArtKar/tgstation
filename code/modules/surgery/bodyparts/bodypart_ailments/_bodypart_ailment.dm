/// An ailment currently affecting this limb
/// Used for complex behaviors that are too niche to be on base limb level, but should persist on limbs when detached unlike mob statuses
/datum/bodypart_ailment
	abstract_type = /datum/bodypart_ailment
	/// Is this ailment considered to be negative by mending/healing effects?
	var/negative = FALSE
	/// Bodypart that owns the ailment
	var/obj/item/bodypart/owner = null
	/// List of traits to apply to the bodypart itself
	var/list/limb_traits = null
	/// List of traits to apply to the bodypart's owner when added
	var/list/mob_traits = null

/datum/bodypart_ailment/New(obj/item/bodypart/new_owner)
	. = ..()
	owner = new_owner
	RegisterSignal(owner, COMSIG_BODYPART_ATTACHED, PROC_REF(on_bodypart_attached))
	RegisterSignal(owner, COMSIG_BODYPART_REMOVED, PROC_REF(on_bodypart_removed))
	if (LAZYLEN(limb_traits))
		owner.add_traits(limb_traits, REF(src))
	if (LAZYLEN(mob_traits) && owner.owner)
		owner.owner.add_traits(mob_traits, REF(src))

/datum/bodypart_ailment/Destroy(force)
	if (LAZYLEN(limb_traits))
		owner.remove_traits(limb_traits, REF(src))
	if (LAZYLEN(mob_traits) && owner.owner)
		owner.owner.remove_traits(mob_traits, REF(src))
	owner = null
	return ..()

/datum/bodypart_ailment/proc/on_bodypart_attached(obj/item/bodypart/source, mob/living/carbon/new_owner, special, lazy)
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)

	if (LAZYLEN(mob_traits))
		new_owner.add_traits(mob_traits, REF(src))

/datum/bodypart_ailment/proc/on_bodypart_removed(obj/item/bodypart/source, mob/living/carbon/old_owner, special, dismembered)
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)

	if (LAZYLEN(mob_traits))
		old_owner.remove_traits(mob_traits, REF(src))

/// Text displayed when someone looks at a mob who the limb belongs to
/datum/bodypart_ailment/proc/on_owner_examine(mob/user)
	return

/// Any custom text to be displayed by health analyzers
/datum/bodypart_ailment/proc/get_health_analyzer_desc(mob/user, advanced, tochat)
	return

/// Used to "transfer" the ailment to another limb.
/// This deletes the current ailment, creates a new one, adds it to the passed limb and returns it
/// All additional variables and such should be moved to the new ailment in here
/datum/bodypart_ailment/proc/transfer_to(obj/item/bodypart/new_owner)
	owner.remove_ailment(src)
	return new type(new_owner)
