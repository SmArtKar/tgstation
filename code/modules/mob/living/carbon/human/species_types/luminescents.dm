///////////////////////////////////LUMINESCENTS//////////////////////////////////////////

//Luminescents are able to consume and use slime extracts, without them decaying.

/datum/species/jelly/luminescent
	name = "Luminescent"
	plural_form = null
	id = SPECIES_LUMINESCENT
	examine_limb_id = SPECIES_LUMINESCENT
	bodypart_overrides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/jelly/luminescent,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/jelly/luminescent,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/jelly/luminescent,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/jelly/luminescent,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/jelly/luminescent,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/jelly/luminescent,
	)
	var/glow_intensity = LUMINESCENT_DEFAULT_GLOW
	var/obj/effect/dummy/luminescent_glow/glow


//Species datums don't normally implement destroy, but JELLIES SUCK ASS OUT OF A STEEL STRAW
/datum/species/jelly/luminescent/Destroy(force, ...)
	QDEL_NULL(glow)
	return ..()


/datum/species/jelly/luminescent/on_species_loss(mob/living/carbon/C)
	..()
	QDEL_NULL(glow)

/datum/species/jelly/luminescent/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	glow = new(C)
	update_glow(C)

/datum/species/jelly/luminescent/proc/update_glow(mob/living/carbon/C, intensity)
	if(intensity)
		glow_intensity = intensity
	glow.set_light_range_power_color(glow_intensity, glow_intensity, C.dna.features["mcolor"])

/obj/effect/dummy/luminescent_glow
	name = "luminescent glow"
	desc = "Tell a coder if you're seeing this."
	icon_state = "nothing"
	light_system = MOVABLE_LIGHT
	light_range = LUMINESCENT_DEFAULT_GLOW
	light_power = 2.5
	light_color = COLOR_WHITE

/obj/effect/dummy/luminescent_glow/Initialize(mapload)
	. = ..()
	if(!isliving(loc))
		return INITIALIZE_HINT_QDEL
