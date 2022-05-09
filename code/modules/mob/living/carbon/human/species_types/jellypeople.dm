/datum/species/jelly
	// Entirely alien beings that seem to be made entirely out of gel. They have three eyes and a skeleton visible within them.
	name = "\improper Jellyperson"
	plural_form = "Jellypeople"
	id = SPECIES_JELLYPERSON
	default_color = "00FF90"
	say_mod = "chirps"
	species_traits = list(MUTCOLORS,EYECOLOR,NOBLOOD,NO_UNDERWEAR)
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_CAN_STRIP,
		TRAIT_TOXINLOVER,
	)
	mutantlungs = /obj/item/organ/lungs/slime
	meat = /obj/item/food/meat/slab/human/mutant/slime
	exotic_blood = /datum/reagent/toxin/slimejelly
	damage_overlay_type = ""
	var/datum/action/innate/regenerate_limbs/regenerate_limbs
	liked_food = MEAT
	toxic_food = NONE
	coldmod = 6   // = 3x cold damage
	heatmod = 0.5 // = 1/4x heat damage
	burnmod = 0.5 // = 1/2x generic burn damage
	payday_modifier = 0.75
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT
	species_language_holder = /datum/language_holder/jelly
	ass_image = 'icons/ass/assslime.png'

	bodypart_overrides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/jelly,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/jelly,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/jelly,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/jelly,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/jelly,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/jelly,
	)

/datum/species/jelly/on_species_loss(mob/living/carbon/old_jellyperson)
	if(regenerate_limbs)
		regenerate_limbs.Remove(old_jellyperson)
	old_jellyperson.RemoveElement(/datum/element/soft_landing)
	..()

/datum/species/jelly/on_species_gain(mob/living/carbon/new_jellyperson, datum/species/old_species)
	..()
	if(ishuman(new_jellyperson))
		regenerate_limbs = new
		regenerate_limbs.Grant(new_jellyperson)
	new_jellyperson.AddElement(/datum/element/soft_landing)

/datum/species/jelly/spec_life(mob/living/carbon/human/human_owner, delta_time, times_fired)
	if(human_owner.stat == DEAD) //can't farm slime jelly from a dead slime/jelly person indefinitely
		return

	if(!human_owner.blood_volume)
		human_owner.blood_volume += 2.5 * delta_time
		human_owner.adjustBruteLoss(2.5 * delta_time)
		to_chat(human_owner, span_danger("You feel empty!"))

	if(human_owner.blood_volume < BLOOD_VOLUME_NORMAL)
		if(human_owner.nutrition >= NUTRITION_LEVEL_STARVING)
			human_owner.blood_volume += 1.5 * delta_time
			human_owner.adjust_nutrition(-1.25 * delta_time)

	if(human_owner.blood_volume < BLOOD_VOLUME_OKAY)
		if(DT_PROB(2.5, delta_time))
			to_chat(human_owner, span_danger("You feel drained!"))

	if(human_owner.blood_volume < BLOOD_VOLUME_BAD)
		Cannibalize_Body(human_owner)

	if(regenerate_limbs)
		regenerate_limbs.UpdateButtons()

/datum/species/jelly/proc/Cannibalize_Body(mob/living/carbon/human/human_owner)
	var/list/limbs_to_consume = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG) - human_owner.get_missing_limbs()
	var/obj/item/bodypart/consumed_limb
	if(!length(limbs_to_consume))
		human_owner.losebreath++
		return
	if(human_owner.num_legs) //Legs go before arms
		limbs_to_consume -= list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM)
	consumed_limb = human_owner.get_bodypart(pick(limbs_to_consume))
	consumed_limb.drop_limb()
	to_chat(human_owner, span_userdanger("Your [consumed_limb] is drawn back into your body, unable to maintain its shape!"))
	qdel(consumed_limb)
	human_owner.blood_volume += 20

// Slimes have both NOBLOOD and an exotic bloodtype set, so they need to be handled uniquely here.
// They may not be roundstart but in the unlikely event they become one might as well not leave a glaring issue open.
/datum/species/jelly/create_pref_blood_perks()
	var/list/to_add = list()

	to_add += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
		SPECIES_PERK_ICON = "tint",
		SPECIES_PERK_NAME = "Jelly Blood",
		SPECIES_PERK_DESC = "[plural_form] don't have blood, but instead have toxic [initial(exotic_blood.name)]! \
			Jelly is extremely important, as losing it will cause you to lose limbs. Having low jelly will make medical treatment very difficult.",
	))

	return to_add

/datum/action/innate/regenerate_limbs
	name = "Regenerate Limbs"
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "slimeheal"
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_alien"

/datum/action/innate/regenerate_limbs/IsAvailable()
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/human_owner = owner
	var/list/limbs_to_heal = human_owner.get_missing_limbs()
	if(!length(limbs_to_heal))
		return FALSE
	if(human_owner.blood_volume >= BLOOD_VOLUME_OKAY+40)
		return TRUE

/datum/action/innate/regenerate_limbs/Activate()
	var/mob/living/carbon/human/human_owner = owner
	var/list/limbs_to_heal = human_owner.get_missing_limbs()
	if(!length(limbs_to_heal))
		to_chat(human_owner, span_notice("You feel intact enough as it is."))
		return
	to_chat(human_owner, span_notice("You focus intently on your missing [length(limbs_to_heal) >= 2 ? "limbs" : "limb"]..."))
	if(human_owner.blood_volume >= 40 * length(limbs_to_heal) + BLOOD_VOLUME_OKAY)
		human_owner.regenerate_limbs()
		human_owner.blood_volume -= 40 * length(limbs_to_heal)
		to_chat(human_owner, span_notice("...and after a moment you finish reforming!"))
		return
	else if(human_owner.blood_volume >= 40)//We can partially heal some limbs
		while(human_owner.blood_volume >= BLOOD_VOLUME_OKAY+40)
			var/healed_limb = pick(limbs_to_heal)
			human_owner.regenerate_limb(healed_limb)
			limbs_to_heal -= healed_limb
			human_owner.blood_volume -= 40
		to_chat(human_owner, span_warning("...but there is not enough of you to fix everything! You must attain more mass to heal completely!"))
		return
	to_chat(human_owner, span_warning("...but there is not enough of you to go around! You must attain more mass to heal!"))
