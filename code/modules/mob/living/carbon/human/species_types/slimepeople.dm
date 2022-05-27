////////////////////////////////////////////////////////SLIMEPEOPLE///////////////////////////////////////////////////////////////////

//Slime people are able to split like slimes, retaining a single mind that can swap between bodies at will, even after death.

#define DEFAULT_SPLIT_VOLUME 1100
#define SPLIT_PENALTY 25

/datum/species/jelly/slime
	name = "\improper Slimeperson"
	plural_form = "Slimepeople"
	id = SPECIES_SLIMEPERSON
	species_traits = list(MUTCOLORS, EYECOLOR, HAIR, FACEHAIR, NOBLOOD, NO_UNDERWEAR, HAS_FLESH)
	hair_color = "mutcolor"
	hair_alpha = 200
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | RACE_SWAP | ERT_SPAWN
	var/datum/action/innate/split_body/slime_split
	var/list/mob/living/carbon/bodies
	var/datum/action/innate/swap_body/swap_body

	bodypart_overrides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/jelly/slime,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/jelly/slime,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/jelly/slime,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/jelly/slime,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/jelly/slime,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/jelly/slime,
	)
	var/splits = 0

/datum/species/jelly/slime/on_species_loss(mob/living/carbon/jellyman)
	if(slime_split)
		slime_split.Remove(jellyman)
	if(swap_body)
		swap_body.Remove(jellyman)
	bodies -= jellyman // This means that the other bodies maintain a link
	// so if someone mindswapped into them, they'd still be shared.
	bodies = null
	jellyman.blood_volume = min(jellyman.blood_volume, BLOOD_VOLUME_NORMAL)
	return ..()

/datum/species/jelly/slime/on_species_gain(mob/living/carbon/new_jellyperson, datum/species/old_species)
	. = ..()
	if(ishuman(new_jellyperson))
		var/mob/living/carbon/human/jellyman = new_jellyperson
		slime_split = new
		slime_split.Grant(jellyman)
		swap_body = new
		swap_body.Grant(jellyman)

		if(!bodies || !length(bodies))
			bodies = list(jellyman)
		else
			bodies |= jellyman

		if(jellyman.dna)
			jellyman.hair_color = jellyman.dna.features["mcolor"]
			jellyman.dna.update_ui_block(DNA_HAIR_COLOR_BLOCK)
			jellyman.facial_hair_color = jellyman.dna.features["mcolor"]
			jellyman.dna.update_ui_block(DNA_FACIAL_HAIR_COLOR_BLOCK)

/datum/species/jelly/slime/spec_death(gibbed, mob/living/carbon/human/jellyman)
	if(slime_split)
		if(!jellyman.mind || !jellyman.mind.active)
			return

		var/list/available_bodies = (bodies - jellyman)
		for(var/mob/living/body in available_bodies)
			if(!swap_body.can_swap(body))
				available_bodies -= body

		if(!LAZYLEN(available_bodies))
			return

		swap_body.swap_to_dupe(jellyman.mind, pick(available_bodies))

//If you're cloned you get your body pool back
/datum/species/jelly/slime/copy_properties_from(datum/species/jelly/slime/old_species)
	bodies = old_species.bodies

/datum/species/jelly/slime/change_color(mob/living/carbon/jellyman, new_color = null)
	. = ..()
	if(!ishuman(jellyman))
		return
	var/mob/living/carbon/human/jellyhuman = jellyman
	jellyhuman.hair_color = jellyhuman.dna.features["mcolor"]
	jellyhuman.facial_hair_color = jellyhuman.dna.features["mcolor"]
	jellyman.update_body(TRUE)

/datum/species/jelly/slime/spec_life(mob/living/carbon/human/jellyman, delta_time, times_fired)
	if(jellyman.blood_volume >= (DEFAULT_SPLIT_VOLUME + (!rainbow_active) * SPLIT_PENALTY * splits ** 2))
		if(DT_PROB(2.5, delta_time))
			to_chat(jellyman, span_notice("You feel very bloated!"))

	return ..()

/datum/action/innate/split_body
	name = "Split Body"
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "slimesplit"
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_slime"

/datum/action/innate/split_body/IsAvailable()
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/human_owner = owner
	if(!isslimeperson(human_owner))
		return FALSE
	var/datum/species/jelly/slime/slime_species = human_owner.dna.species
	if(human_owner.blood_volume >= (DEFAULT_SPLIT_VOLUME + (!slime_species.rainbow_active) * SPLIT_PENALTY * slime_species.splits ** 2))
		return TRUE
	return FALSE

/datum/action/innate/split_body/Activate()
	var/mob/living/carbon/human/human_owner = owner
	if(!isslimeperson(human_owner))
		return
	var/datum/species/jelly/slime/slime_species = human_owner.dna.species
	CHECK_DNA_AND_SPECIES(human_owner)
	human_owner.visible_message(span_notice("[human_owner] gains a look of concentration while standing perfectly still."), span_notice("You focus intently on moving your body while standing perfectly still..."))
	human_owner.notransform = TRUE

	if(do_after(human_owner, delay = 6 SECONDS, target = human_owner, timed_action_flags = IGNORE_HELD_ITEM))
		if(human_owner.blood_volume >= (DEFAULT_SPLIT_VOLUME + (!slime_species.rainbow_active) * SPLIT_PENALTY * slime_species.splits ** 2))
			make_dupe()
		else
			to_chat(human_owner, span_warning("...but there is not enough of you to go around! You must attain more mass to split!"))
	else
		to_chat(human_owner, span_warning("...but you fail to stand perfectly still!"))

	human_owner.notransform = FALSE

/datum/action/innate/split_body/proc/make_dupe()
	var/mob/living/carbon/human/human_owner = owner
	CHECK_DNA_AND_SPECIES(human_owner)

	var/mob/living/carbon/human/spare = new /mob/living/carbon/human(human_owner.loc)

	spare.underwear = "Nude"
	human_owner.dna.transfer_identity(spare, transfer_SE=1)
	spare.dna.features["mcolor"] = "#[num2hex(rand(85, 255), 2)][num2hex(rand(85, 255), 2)][num2hex(rand(85, 255), 2)]"
	spare.dna.update_uf_block(DNA_MUTANT_COLOR_BLOCK)
	spare.real_name = spare.dna.real_name
	spare.name = spare.dna.real_name
	spare.updateappearance(mutcolor_update=1)
	spare.domutcheck()
	spare.Move(get_step(human_owner.loc, pick(GLOB.cardinals)))
	for(var/disease in human_owner.diseases)
		spare.ForceContractDisease(disease)

	human_owner.blood_volume *= 0.45
	human_owner.notransform = 0

	var/datum/species/jelly/slime/origin_datum = human_owner.dna.species
	origin_datum.bodies |= spare
	origin_datum.splits += 1

	for(var/mob/living/carbon/human/jellyman in (origin_datum.bodies - human_owner))
		if(!jellyman.dna || !jellyman.dna.species)
			continue
		var/datum/species/jelly/slime/jellyman_species = jellyman.dna.species
		jellyman_species.splits = origin_datum.splits
		jellyman_species.bodies = origin_datum.bodies

	human_owner.transfer_trait_datums(spare)
	human_owner.mind.transfer_to(spare)
	spare.visible_message(span_warning("[human_owner] distorts as a new body \"steps out\" of [human_owner.p_them()]."), span_notice("...and after a moment of disorentation, you're besides yourself!"))

/datum/action/innate/swap_body
	name = "Swap Body"
	check_flags = NONE
	button_icon_state = "slimeswap"
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_slime"

/datum/action/innate/swap_body/Activate()
	if(!isslimeperson(owner))
		to_chat(owner, span_warning("You are not a slimeperson."))
		Remove(owner)
		return

	ui_interact(owner)

/datum/action/innate/swap_body/ui_host(mob/user)
	return owner

/datum/action/innate/swap_body/ui_state(mob/user)
	return GLOB.always_state

/datum/action/innate/swap_body/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SlimeBodySwapper", name)
		ui.open()

/datum/action/innate/swap_body/ui_data(mob/user)
	var/mob/living/carbon/human/jellyman = owner
	if(!isslimeperson(jellyman))
		return

	var/datum/species/jelly/slime/slime_species = jellyman.dna.species

	var/list/data = list()
	data["bodies"] = list()
	for(var/mob/living/carbon/human/body in slime_species.bodies)
		if(!body || QDELETED(body) || !isslimeperson(body))
			slime_species.bodies -= body
			continue

		var/list/body_data = list()
		body_data["htmlcolor"] = body.dna.features["mcolor"]
		body_data["area"] = get_area_name(body, TRUE)
		var/stat = "error"
		switch(body.stat)
			if(CONSCIOUS)
				stat = "Conscious"
			if(SOFT_CRIT to HARD_CRIT) // Also includes UNCONSCIOUS
				stat = "Unconscious"
			if(DEAD)
				stat = "Dead"
		var/occupied
		if(body == jellyman)
			occupied = "owner"
		else if(body.mind && body.mind.active)
			occupied = "stranger"
		else
			occupied = "available"

		body_data["status"] = stat
		body_data["exoticblood"] = body.blood_volume
		body_data["name"] = body.name
		body_data["ref"] = "[REF(body)]"
		body_data["occupied"] = occupied
		var/button
		if(occupied == "owner")
			button = "selected"
		else if(occupied == "stranger")
			button = "danger"
		else if(can_swap(body))
			button = null
		else
			button = "disabled"

		body_data["swap_button_state"] = button
		body_data["swappable"] = (occupied == "available") && can_swap(body)

		data["bodies"] += list(body_data)

	return data

/datum/action/innate/swap_body/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/human_owner = owner
	if(!isslimeperson(owner))
		return
	if(!human_owner.mind || !human_owner.mind.active)
		return
	switch(action)
		if("swap")
			var/datum/species/jelly/slime/slime_species = human_owner.dna.species
			var/mob/living/carbon/human/selected = locate(params["ref"]) in slime_species.bodies
			if(!can_swap(selected))
				return
			SStgui.close_uis(src)
			swap_to_dupe(human_owner.mind, selected)

/datum/action/innate/swap_body/proc/can_swap(mob/living/carbon/human/dupe)
	var/mob/living/carbon/human/human_owner = owner
	if(!isslimeperson(human_owner))
		return FALSE
	var/datum/species/jelly/slime/slime_species = human_owner.dna.species

	if(QDELETED(dupe)) //Is there a body?
		slime_species.bodies -= dupe
		return FALSE

	if(!isslimeperson(dupe)) //Is it a slimeperson?
		slime_species.bodies -= dupe
		return FALSE

	if(dupe.stat == DEAD) //Is it alive?
		return FALSE

	if(dupe.stat != CONSCIOUS) //Is it awake?
		return FALSE

	if(dupe.mind && dupe.mind.active) //Is it unoccupied?
		return FALSE

	if(!(dupe in slime_species.bodies)) //Do we actually own it?
		return FALSE

	return TRUE

/datum/action/innate/swap_body/proc/swap_to_dupe(datum/mind/owner_mind, mob/living/carbon/human/dupe)
	if(!can_swap(dupe)) //sanity check
		return
	if(owner_mind.current.stat == CONSCIOUS)
		owner_mind.current.visible_message(span_notice("[owner_mind.current] stops moving and starts staring vacantly into space."), span_notice("You stop moving this body..."))
	else
		to_chat(owner_mind.current, span_notice("You abandon this body..."))
	owner_mind.current.transfer_trait_datums(dupe)
	owner_mind.transfer_to(dupe)
	dupe.visible_message(span_notice("[dupe] blinks and looks around."), span_notice("...and move this one instead."))

#undef DEFAULT_SPLIT_VOLUME
#undef SPLIT_PENALTY
