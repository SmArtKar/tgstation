/**
 * Tattoo component
 * Applied to bodypart, and grants their owner fancy tattoos. Someone can have up to 3 small, 2 medium, or 1 large tattoo on a bodypart.
 * Tattoos applied to the owner on their natural (matching their species) limbs that they keep to roundend will persist
 * if they have that option enabled.
 */
/datum/component/tattoo
	dupe_mode = COMPONENT_DUPE_SOURCES
	/// Description of the tattoo
	var/tattoo_description

/datum/component/tattoo/Initialize(tattoo_description)
	. = ..()
	if(!isbodypart(parent))
		return COMPONENT_INCOMPATIBLE

	var/obj/item/bodypart/tatted_limb = parent
	if(!tattoo_description)
		return COMPONENT_INCOMPATIBLE

	src.tattoo_description = tattoo_description
	tatted_limb.AddElement(/datum/element/art/commoner, 15)

	if(tatted_limb.owner)
		setup_tatted_owner(tatted_limb.owner)

/datum/component/tattoo/Destroy(force)
	if(!parent)
		return ..()
	var/obj/item/bodypart/tatted_limb = parent
	if(tatted_limb.owner)
		clear_tatted_owner(tatted_limb.owner)
	parent.RemoveElement(/datum/element/art/commoner)
	return ..()

/datum/component/tattoo/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_BODYPART_ATTACHED, PROC_REF(on_attached))
	RegisterSignal(parent, COMSIG_BODYPART_REMOVED, PROC_REF(on_detached))
	parent.AddComponentFrom(src, /datum/component/tattoo_owner)

/datum/component/tattoo/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ATOM_EXAMINE, COMSIG_BODYPART_ATTACHED, COMSIG_BODYPART_REMOVED))
	parent.RemoveComponentSource(src, /datum/component/tattoo_owner)

/datum/component/tattoo/proc/on_attached(datum/source, mob/living/carbon/human/new_owner)
	SIGNAL_HANDLER
	setup_tatted_owner(new_owner)

/datum/component/tattoo/proc/on_detached(datum/source, mob/living/carbon/human/old_owner)
	SIGNAL_HANDLER
	clear_tatted_owner(old_owner)

/datum/component/tattoo/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_boldnotice(tattoo_description)

/datum/component/tattoo/proc/setup_tatted_owner(mob/living/carbon/new_owner)
	RegisterSignal(new_owner, COMSIG_ATOM_EXAMINE_MORE, PROC_REF(on_bodypart_owner_examine))

/datum/component/tattoo/proc/clear_tatted_owner(mob/living/carbon/old_owner)
	UnregisterSignal(old_owner, COMSIG_ATOM_EXAMINE_MORE)

/datum/component/tattoo/proc/is_visible()
	var/obj/item/bodypart/tatted_limb = parent
	for(var/obj/item/clothing/possibly_blocking in tatted_limb.owner?.get_equipped_items())
		if(possibly_blocking.body_parts_covered & tatted_limb.body_part) //check to see if something is obscuring their tattoo.
			return FALSE
	return TRUE

/datum/component/tattoo/proc/on_bodypart_owner_examine(mob/living/carbon/bodypart_owner, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if (!is_visible())
		return
	examine_list += span_notice("<a href='byond://?src=[REF(src)];examine_time=[world.time]'>[parent]</a> of [bodypart_owner] has a tattoo!")
	examine_list += span_boldnotice(tattoo_description)

/datum/component/tattoo/proc/Topic(href, list/href_list)
	. = ..()
	if (!href_list["examine_time"])
		return
	var/obj/item/bodypart/limb = parent
	var/mob/viewer = usr
	var/still_seeing = limb.owner && (viewer in viewers(limb.owner))
	if (href_list["examine_time"] + (still_seeing ? 3 MINUTES : 1 MINUTES) <= world.time)
		viewer.examinate(limb)

/// Holder component for a mob that has tattoos, does nothing except keep track of how many
///	tattoos they have and display an examine line based on that
/datum/component/tattoo_owner
	dupe_mode = COMPONENT_DUPE_SOURCES

/datum/component/tattoo_owner/Initialize()
	. = ..()
	if (!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/tattoo_owner/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/datum/component/tattoo_owner/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATOM_EXAMINE)

/datum/component/tattoo_owner/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/list/visible_tats = list()
	for (var/datum/component/tattoo/tattoo as anything in sources)
		if (tattoo.is_visible())
			visible_tats += tattoo

	switch (length(visible_tats))
		if (1)
			var/datum/component/tattoo/tattoo = visible_tats[1]
			var/obj/item/bodypart/part = tattoo.parent
			. += span_tinynoticeital("[parent.p_They()] [parent.p_have()] a tattoo on [parent.p_their()] [parse_zone(part.body_zone)], you can look again to take a closer look...")
		if (2 to 3)
			. += span_smallnoticeital("[parent.p_They()] [parent.p_have()] a few visible tattoos, you can look again to take a closer look...")
		if (4 to 6)
			. += span_notice("<i>[parent.p_They()] [parent.p_have()] several tattoos on [parent.p_them()], you can look again to take a closer look...</i>")
		if (7 to INFINITY)
			. += span_notice("<b><i>[parent.p_They()] [parent.p_are()] covered in a multitude of tattoos, you can look again to take a closer look...</i></b>")

