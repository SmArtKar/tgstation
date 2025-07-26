/// Curse brain trauma that makes someone space textured, mute, pacifist and forbids them from entering space
/datum/brain_trauma/voided
	name = "Voided"
	desc = "They've seen the secrets of the cosmos, in exchange for a curse that keeps them chained."
	scan_desc = "cosmic neural pattern"
	gain_text = ""
	lose_text = ""
	resilience = TRAUMA_RESILIENCE_LOBOTOMY
	random_gain = FALSE
	/// Type for the bodypart texture we add
	var/bodypart_overlay_type = /datum/bodypart_overlay/texture/spacey
	/// Color in which we paint the space texture
	var/space_color = COLOR_WHITE
	///traits we give on gain
	var/list/traits_to_apply = list(TRAIT_PACIFISM)
	/// Do we ban the person from entering space?
	var/ban_from_space = TRUE
	/// Chance we'll get a color from space_colors
	var/coloring_chance = 50
	/// Statis list of all possible space colors
	var/static/list/space_colors = list("#00ccff","#b12bff","#ff7f3a","#ff1c55","#ff7597","#28ff94","#0fcfff","#ff8b4c","#ffc425","#2dff96","#1770ff","#ff3f31","#ffba3b")
	/// Frequency at which we do a space vomit
	var/vomit_frequency = 2
	/// We take a little extra damage, cause we're like glass or something
	var/brute_mod = 1.1

/datum/brain_trauma/voided/on_gain()
	. = ..()

	if(prob(coloring_chance))
		space_color = pick(space_colors)

	owner.add_traits(traits_to_apply, REF(src))
	if(ban_from_space)
		owner.AddComponent(/datum/component/banned_from_space)

	if(!is_on_a_planet(owner))
		owner.AddComponent(/datum/component/planet_allergy)

	owner.AddComponent(/datum/component/debris_bleeder, \
		list(/obj/effect/spawner/random/glass_shards = 20, /obj/effect/spawner/random/glass_debris = 0), \
		BRUTE, SFX_SHATTER, sound_threshold = 20)

	RegisterSignal(owner, COMSIG_CARBON_ATTACH_LIMB, PROC_REF(texture_limb)) //also catch new limbs being attached
	RegisterSignal(owner, COMSIG_CARBON_REMOVE_LIMB, PROC_REF(untexture_limb)) //and remove it from limbs if they go away
	RegisterSignal(owner, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(on_equipped))
	RegisterSignal(owner, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_unequipped))

	for(var/obj/item/bodypart as anything in owner.bodyparts)
		texture_limb(owner, bodypart)

	if(ishuman(owner))
		var/mob/living/carbon/human/human = owner
		human.physiology.brute_mod *= brute_mod

	//your underwear is belong to us
	if(ishuman(owner))
		var/mob/living/carbon/human/human = owner //CARBON WILL NEVER BE REAL!!!!!
		human.underwear = "Nude"
		human.undershirt = "Nude"
		human.socks = "Nude"

	owner.update_body()
	for(var/obj/item/thing as anything in owner.get_equipped_items())
		on_equipped(owner, thing, owner.get_slot_by_item(thing))

/datum/brain_trauma/voided/on_lose()
	. = ..()

	owner.remove_traits(traits_to_apply, REF(src))
	UnregisterSignal(owner, list(COMSIG_CARBON_ATTACH_LIMB, COMSIG_CARBON_REMOVE_LIMB))
	if(ban_from_space)
		qdel(owner.GetComponent(/datum/component/banned_from_space))
	qdel(owner.GetComponent(/datum/component/planet_allergy))
	qdel(owner.GetComponent(/datum/component/debris_bleeder))

	if(ishuman(owner))
		var/mob/living/carbon/human/human = owner
		human.physiology.brute_mod /= brute_mod

	for(var/obj/item/bodypart/bodypart as anything in owner.bodyparts)
		untexture_limb(owner, bodypart)
	owner.update_body()

/datum/brain_trauma/voided/on_life(seconds_per_tick, times_fired)
	. = ..()

	if(prob(vomit_frequency))
		owner.vomit(MOB_VOMIT_KNOCKDOWN, vomit_type = /obj/effect/decal/cleanable/vomit/nebula, distance = 0)

/// Apply the space texture
/datum/brain_trauma/voided/proc/texture_limb(atom/source, obj/item/bodypart/limb)
	SIGNAL_HANDLER

	// Not updating because on_gain/on_lose() call it down the line, and calls coming from comsigs update the owner's body themselves
	limb.add_bodypart_overlay(new bodypart_overlay_type(), update = FALSE)
	limb.add_color_override(space_color, LIMB_COLOR_VOIDWALKER_CURSE)
	if(istype(limb, /obj/item/bodypart/head))
		var/obj/item/bodypart/head/head = limb
		head.head_flags &= ~HEAD_EYESPRITES
		RegisterSignal(head, COMSIG_BODYPART_HAIR_GENERATED, PROC_REF(on_hair_generated))

/datum/brain_trauma/voided/proc/untexture_limb(atom/source, obj/item/bodypart/limb)
	SIGNAL_HANDLER

	var/overlay = locate(bodypart_overlay_type) in limb.bodypart_overlays
	if(overlay)
		limb.remove_bodypart_overlay(overlay, update = FALSE)
		limb.remove_color_override(LIMB_COLOR_VOIDWALKER_CURSE)

	if(istype(limb, /obj/item/bodypart/head))
		var/obj/item/bodypart/head/head = limb
		head.head_flags = initial(head.head_flags)
		UnregisterSignal(head, COMSIG_BODYPART_HAIR_GENERATED)

/datum/brain_trauma/voided/on_death()
	. = ..()

	if(is_on_a_planet(owner))
		qdel(src)

/datum/brain_trauma/voided/proc/on_equipped(mob/source, obj/item/picked_up, slot)
	SIGNAL_HANDLER
	RegisterSignal(picked_up, COMSIG_ITEM_GET_WORN_OVERLAYS, PROC_REF(on_worn_overlays))
	source.update_clothing(slot)

/datum/brain_trauma/voided/proc/on_worn_overlays(obj/item/source, list/overlays, mutable_appearance/standing, isinhands, icon_file)
	SIGNAL_HANDLER
	standing.add_filter("black", 1, color_matrix_filter(list(0,0,0,0,0,0,0,0,0)))
	standing.add_filter("stars", 2, layering_filter(icon('icons/mob/human/textures.dmi', "spacey"), blend_mode = BLEND_INSET_OVERLAY))
	standing.add_filter("white", 3, outline_filter(1, COLOR_WHITE, OUTLINE_SHARP))

/datum/brain_trauma/voided/proc/on_hair_generated(obj/item/bodypart/head/head, list/overlays)
	SIGNAL_HANDLER
	for (var/mutable_appearance/overlay as anything in overlays)
		overlay.add_filter("black", 1, color_matrix_filter(list(0,0,0,0,0,0,0,0,0)))
		overlay.add_filter("stars", 2, layering_filter(icon('icons/mob/human/textures.dmi', "spacey"), blend_mode = BLEND_INSET_OVERLAY))
		overlay.add_filter("white", 3, outline_filter(1, COLOR_WHITE, OUTLINE_SHARP))

/datum/brain_trauma/voided/proc/on_unequipped(mob/source, obj/item/dropped_item, force, new_location)
	SIGNAL_HANDLER
	UnregisterSignal(dropped_item, COMSIG_ITEM_GET_WORN_OVERLAYS)

/// Positive version of the previous. Get space immunity and the ability to slowly move through glass (but you still get muted)
/datum/brain_trauma/voided/stable
	scan_desc = "stable cosmic neural pattern"
	traits_to_apply = list(TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTCOLD)
	ban_from_space = FALSE
	vomit_frequency = 0

/datum/brain_trauma/voided/stable/on_gain()
	. = ..()

	owner.AddComponent(/datum/component/glass_passer, 2 SECONDS, 2 SECONDS)

/datum/brain_trauma/voided/stable/on_lose()
	. = ..()

	qdel(owner.GetComponent(/datum/component/glass_passer))
