/// Attributes, aka groups of aspects
/datum/attribute
	var/name = "Coderbus"
	var/desc = "People you yell at when you see this"
	var/color = "#FFFFFF"

	var/level = 0
	/// Temporary modifier you get from drugs or booze or whatever
	/// Only allows you to level your aspects above this attribute's level
	var/level_modifier = 0
	/// Mind who owns us
	var/datum/mind/owner
	/// List of all aspect datums we own
	var/list/datum/aspect/aspects = list()

/datum/attribute/New(datum/mind/new_owner)
	. = ..()
	owner = new_owner
	RegisterSignal(owner, COMSIG_QDELETING, PROC_REF(on_owner_del))

	for (var/datum/aspect/aspect as anything in subtypesof(/datum/aspect))
		if (initial(aspect.attribute) != type)
			continue
		aspect = new aspect(src)
		aspects += aspect

/datum/attribute/Destroy(force)
	owner = null
	QDEL_LIST(aspects)
	return ..()

/datum/attribute/proc/on_owner_del(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/attribute/proc/adjust_level(change)
	level += change
	for (var/datum/aspect/aspect as anything in aspects)
		aspect.adjust_level(change)

/datum/attribute/proc/set_level(new_level)
	adjust_level(new_level - level)

/datum/attribute/proc/get_aspect(aspect_type)
	RETURN_TYPE(/datum/aspect)
	return locate(aspect_type) in aspects

// Mind procs

/datum/mind/proc/init_attributes()
	for (var/attribute_type in subtypesof(/datum/attribute))
		attributes += new attribute_type(src)

/datum/mind/proc/get_attribute(attribute_type)
	RETURN_TYPE(/datum/attribute)
	return locate(attribute_type) in attributes

/datum/mind/proc/get_aspect(datum/aspect/aspect_type)
	RETURN_TYPE(/datum/aspect)
	var/datum/attribute/linked_attribute = get_attribute(initial(aspect_type.attribute))
	return linked_attribute.get_aspect(aspect_type)

/datum/mind/proc/get_aspect_level(datum/aspect/aspect_type)
	return get_aspect(aspect_type).level

/datum/mind/proc/active_check(aspect_type, difficulty, show_visual = TRUE)
	return get_aspect(aspect_type).active_check(difficulty, show_visual)

/datum/mind/proc/passive_check(aspect_type, difficulty)
	return get_aspect(aspect_type).passive_check(difficulty)
