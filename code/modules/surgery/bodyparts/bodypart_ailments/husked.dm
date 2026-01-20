/// Shared base for all husking effects, we usually check for that when looking at if the limb has been desiccated or not
/datum/bodypart_ailment/husked
	abstract_type = /datum/bodypart_ailment/husked
	negative = TRUE
	// Husked limbs do not display underwear on themselves
	limb_traits = list(TRAIT_NO_UNDERWEAR)

/datum/bodypart_ailment/husked/New(obj/item/bodypart/new_owner)
	// Husked heads cannot be recognized
	if (istype(new_owner, /obj/item/bodypart/head))
		limb_traits |= TRAIT_DISFIGURED
	return ..()

/datum/bodypart_ailment/husked/on_owner_examine(mob/user)
	return span_danger("[owner.owner.p_Their()] [owner.plaintext_zone] has been reduced to a grotesque husk!")

/datum/bodypart_ailment/husked/get_health_analyzer_desc(mob/user, advanced, tochat)
	if (!advanced)
		return "<td><span class='alert ml-1'>Limb has been husked.</span></td>"
	return "<td><span class='alert ml-1'>Limb has been husked by unknown causes.</span></td>"

/// Limb is husked from extreme burn damage
/datum/bodypart_ailment/husked/burn

/datum/bodypart_ailment/husked/burn/get_health_analyzer_desc(mob/user, advanced, tochat)
	if (!advanced)
		return "<td><span class='alert ml-1'>Limb has been husked.</span></td>"
	return "<td><span class='alert ml-1'>Limb has been husked by [conditional_tooltip("severe burns", "Tend burns and apply a de-husking agent, such as [/datum/reagent/medicine/c2/synthflesh::name].", tochat)].</span></td>"

/datum/bodypart_ailment/husked/burn/on_owner_examine(mob/user)
	return span_danger("[owner.owner.p_Their()] [owner.plaintext_zone] has been charred to the bone!")

/// Limb is husked from being turned into a capri-sun by a changeling
/datum/bodypart_ailment/husked/changeling_drain

/datum/bodypart_ailment/husked/changeling_drain/get_health_analyzer_desc(mob/user, advanced, tochat)
	if (!advanced)
		return "<td><span class='alert ml-1'>Limb has been husked.</span></td>"
	return "<td><span class='alert ml-1'>Subject has been husked by [conditional_tooltip("desiccation", "Irreparable. Under normal circumstances, revival can only proceed via brain transplant.", tochat)].</span></td>"

/datum/bodypart_ailment/husked/changeling_drain/on_owner_examine(mob/user)
	return span_danger("[owner.owner.p_Their()] [owner.plaintext_zone] is completely dry and desiccated!")
