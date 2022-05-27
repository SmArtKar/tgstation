/datum/species/jelly
	// Entirely alien beings that seem to be made entirely out of gel. They have three eyes and a skeleton visible within them.
	name = "\improper Jellyperson"
	plural_form = "Jellypeople"
	id = SPECIES_JELLYPERSON
	species_traits = list(MUTCOLORS, EYECOLOR, NOBLOOD, NO_UNDERWEAR, HAS_FLESH)
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_CAN_STRIP,
		TRAIT_TOXINLOVER,
	)
	meat = /obj/item/food/meat/slab/human/mutant/slime
	exotic_blood = /datum/reagent/toxin/slime_jelly
	damage_overlay_type = ""
	var/datum/action/innate/regenerate_limbs/regenerate_limbs
	liked_food = TOXIC | RAW | MEAT | BUGS
	disliked_food = NONE
	toxic_food = NONE
	coldmod = 6   // = 3x cold damage because of limb damage modifier
	heatmod = 0.5 // = 1/4x heat damage because of limb damage modifier
	payday_modifier = 0.75
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN
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

	mutantbrain = /obj/item/organ/brain/slime
	mutantheart = /obj/item/organ/heart/slime
	mutantlungs = /obj/item/organ/lungs/slime
	mutanteyes = /obj/item/organ/eyes/slime
	mutantears = /obj/item/organ/ears/slime
	mutanttongue = /obj/item/organ/tongue/slime
	mutantliver = /obj/item/organ/liver/slime
	mutantstomach = /obj/item/organ/stomach/slime
	mutantappendix = /obj/item/organ/appendix/slime

	/// Are we currently in RAINBOW MOOOOODE?
	var/rainbow_active = FALSE
	/// Current hue for RAINBOW MOOOOODE
	var/current_hue = 0
	/// Original color stored for stopping rainbow mode
	var/original_mcolor
	/// Timer for rainbow effect removal
	var/rainbow_timer

/datum/species/jelly/on_species_loss(mob/living/carbon/old_jellyperson)
	if(regenerate_limbs)
		regenerate_limbs.Remove(old_jellyperson)
	old_jellyperson.RemoveElement(/datum/element/soft_landing)
	stop_rainbow(old_jellyperson)
	return ..()

/datum/species/jelly/on_species_gain(mob/living/carbon/new_jellyperson, datum/species/old_species)
	. = ..()
	if(new_jellyperson.dna)
		var/mutcolor = "#[num2hex(rand(85, 255), 2)][num2hex(rand(85, 255), 2)][num2hex(rand(85, 255), 2)]"
		var/datum/status_effect/jelly_color_tracker/tracker = new_jellyperson.has_status_effect(/datum/status_effect/jelly_color_tracker)
		if(tracker)
			mutcolor = tracker.mutcolor
		new_jellyperson.dna.features["mcolor"] = mutcolor
		for(var/obj/item/organ/slime_organ in new_jellyperson.internal_organs)
			if(!slime_organ.GetComponent(/datum/component/hydrophobic)) //somehow got non slime organ
				continue
			slime_organ.add_atom_colour(mutcolor, FIXED_COLOUR_PRIORITY)
	if(ishuman(new_jellyperson))
		regenerate_limbs = new
		regenerate_limbs.Grant(new_jellyperson)
	new_jellyperson.AddElement(/datum/element/soft_landing)

/datum/species/jelly/proc/change_color(mob/living/carbon/jellyman, new_color = null)
	if(!new_color)
		new_color = "#[num2hex(rand(85, 255), 2)][num2hex(rand(85, 255), 2)][num2hex(rand(85, 255), 2)]"

	jellyman.dna.features["mcolor"] = new_color
	for(var/obj/item/organ/slime_organ in jellyman.internal_organs)
		if(!slime_organ.GetComponent(/datum/component/hydrophobic)) //somehow got non slime organ
			continue
		slime_organ.remove_atom_colour(FIXED_COLOUR_PRIORITY)
		slime_organ.add_atom_colour(new_color, FIXED_COLOUR_PRIORITY)

	jellyman.update_body(TRUE)

/datum/species/jelly/proc/consume_extract(mob/living/carbon/jellyman, obj/item/slime_extract/extract)
	playsound(jellyman,'sound/items/eatfood.ogg', 50, TRUE)
	jellyman.visible_message(span_notice("[jellyman] consumes [extract]."), span_notice("You consume [extract]."))
	if(extract.jelly_color)
		change_color(jellyman, extract.jelly_color)

	if(istype(extract, /obj/item/slime_extract/special/rainbow))
		start_rainbow(jellyman, 5 MINUTES)
	else if(rainbow_active)
		stop_rainbow(jellyman)
	qdel(extract)

/datum/species/jelly/spec_life(mob/living/carbon/human/human_owner, delta_time, times_fired)
	if(human_owner.stat == DEAD) //can't farm slime jelly from a dead slime/jelly person indefinitely
		return

	if(human_owner.blood_volume < BLOOD_VOLUME_BAD)
		cannibalize_body(human_owner)

	if(DT_PROB(0.25, delta_time))
		pop_robo_limb(human_owner)

	if(regenerate_limbs)
		regenerate_limbs.UpdateButtons()

/datum/species/jelly/proc/pop_robo_limb(mob/living/carbon/human/human_owner)
	var/list/limbs_to_pop = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG) - human_owner.get_missing_limbs()
	var/list/popping_limbs = list()
	for(var/pop_zone in limbs_to_pop)
		var/obj/item/bodypart/bodypart = human_owner.get_bodypart(pop_zone)
		if(bodypart && (bodypart.bodytype & BODYTYPE_ROBOTIC))
			popping_limbs += bodypart

	if(!LAZYLEN(popping_limbs))
		return

	var/obj/item/bodypart/popped_limb = pick(popping_limbs)
	popped_limb.drop_limb()
	playsound(get_turf(human_owner), 'sound/effects/blobattack.ogg', 100, TRUE)
	to_chat(human_owner, span_userdanger("Your [popped_limb] suddenly pops off as your body rejects it!"))

/datum/species/jelly/proc/cannibalize_body(mob/living/carbon/human/human_owner)
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
	human_owner.blood_volume += 50
	playsound(get_turf(human_owner), 'sound/effects/blobattack.ogg', 100, TRUE)

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
	background_icon_state = "bg_slime"

/datum/action/innate/regenerate_limbs/IsAvailable()
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/human_owner = owner
	var/list/limbs_to_heal = human_owner.get_missing_limbs()
	if(!length(limbs_to_heal))
		return FALSE
	if(human_owner.blood_volume >= BLOOD_VOLUME_OKAY + 40)
		return TRUE

/datum/action/innate/regenerate_limbs/Activate()
	var/mob/living/carbon/human/human_owner = owner
	var/list/limbs_to_heal = human_owner.get_missing_limbs()
	if(!length(limbs_to_heal))
		to_chat(human_owner, span_notice("You feel intact enough as it is."))
		return
	to_chat(human_owner, span_notice("You focus intently on your missing [length(limbs_to_heal) >= 2 ? "limbs" : "limb"]..."))
	playsound(get_turf(human_owner), 'sound/effects/blobattack.ogg', 100, TRUE)
	if(human_owner.blood_volume >= 40 * length(limbs_to_heal) + BLOOD_VOLUME_OKAY)
		human_owner.regenerate_limbs()
		human_owner.blood_volume -= 40 * length(limbs_to_heal)
		to_chat(human_owner, span_notice("...and after a moment you finish reforming!"))
		return
	else if(human_owner.blood_volume >= 40)//We can partially heal some limbs
		while(human_owner.blood_volume >= BLOOD_VOLUME_OKAY + 40)
			var/healed_limb = pick(limbs_to_heal)
			human_owner.regenerate_limb(healed_limb)
			limbs_to_heal -= healed_limb
			human_owner.blood_volume -= 40
		to_chat(human_owner, span_warning("...but there is not enough of you to fix everything! You must attain more mass to heal completely!"))
		return
	to_chat(human_owner, span_warning("...but there is not enough of you to go around! You must attain more mass to heal!"))

/datum/species/jelly/proc/start_rainbow(mob/living/carbon/jellyman, duration = null)
	rainbow_active = TRUE
	original_mcolor = jellyman.dna.features["mcolor"]
	deltimer(rainbow_timer)
	if(duration)
		rainbow_timer = addtimer(CALLBACK(src, .proc/stop_rainbow, jellyman), duration, TIMER_STOPPABLE)
	INVOKE_ASYNC(src, .proc/handle_rainbow, jellyman)

/datum/species/jelly/proc/stop_rainbow(mob/living/carbon/jellyman)
	rainbow_active = FALSE
	if(!original_mcolor)
		return
	jellyman.dna.features["mcolor"] = original_mcolor
	jellyman.update_body(TRUE)

/datum/species/jelly/proc/handle_rainbow(mob/living/carbon/jellyman)
	if(!rainbow_active)
		return
	current_hue = (current_hue + 5) % 360
	var/light_shift = 60 + abs(current_hue % 120 - 60) / 4
	var/new_color = rgb(current_hue, 100, light_shift, space = COLORSPACE_HSL)
	change_color(jellyman, new_color)
	addtimer(CALLBACK(src, .proc/handle_rainbow, jellyman), 1)
