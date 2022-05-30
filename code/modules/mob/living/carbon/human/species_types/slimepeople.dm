#define DEFAULT_SPLIT_VOLUME 1100
#define SPLIT_PENALTY 25

/datum/species/jelly/slime
	name = "\improper Slimeperson"
	plural_form = "Slimefolk"
	id = SPECIES_SLIMEPERSON
	species_traits = list(MUTCOLORS, EYECOLOR, HAIR, FACEHAIR, NOBLOOD, NO_UNDERWEAR, HAS_FLESH)
	hair_color = "mutcolor"
	hair_alpha = 200 //Like their bodies
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | RACE_SWAP | ERT_SPAWN

	bodypart_overrides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/jelly/slime,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/jelly/slime,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/jelly/slime,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/jelly/slime,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/jelly/slime,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/jelly/slime,
	)

	var/datum/action/innate/split_body/slime_split

/datum/species/jelly/slime/on_species_gain(mob/living/carbon/new_jellyperson, datum/species/old_species)
	. = ..()
	if(!ishuman(new_jellyperson))
		return

	var/mob/living/carbon/human/jellyman = new_jellyperson
	slime_split = new
	slime_split.Grant(jellyman)

	if(!jellyman.dna)
		return

	jellyman.hair_color = jellyman.dna.features["mcolor"]
	jellyman.facial_hair_color = jellyman.dna.features["mcolor"]
	jellyman.dna.update_ui_block(DNA_HAIR_COLOR_BLOCK)
	jellyman.dna.update_ui_block(DNA_FACIAL_HAIR_COLOR_BLOCK)
	if(!jellyman.GetComponent(/datum/component/body_swapper))
		jellyman.AddComponent(/datum/component/body_swapper/slime)

/datum/species/jelly/slime/on_species_loss(mob/living/carbon/jellyman)
	QDEL_NULL(slime_split)
	return ..()

/datum/species/jelly/slime/change_color(mob/living/carbon/jellyman, new_color = null)
	. = ..()
	if(!ishuman(jellyman))
		return
	var/mob/living/carbon/human/jellyhuman = jellyman
	jellyhuman.hair_color = jellyhuman.dna.features["mcolor"]
	jellyhuman.facial_hair_color = jellyhuman.dna.features["mcolor"]
	jellyman.update_body(TRUE)

/datum/species/jelly/slime/spec_life(mob/living/carbon/human/jellyman, delta_time, times_fired)
	. = ..()
	slime_split.UpdateButtons()

	if(!DT_PROB(2.5, delta_time) || !jellyman.mind)
		return

	if(jellyman.blood_volume >= slime_split.get_split_cost(jellyman))
		to_chat(jellyman, span_notice("You feel very bloated!"))

/datum/action/innate/split_body
	name = "Split Body"
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "slimesplit"
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_slime"

/datum/action/innate/split_body/proc/get_split_cost(mob/living/carbon/human/jellyman)
	var/datum/component/body_swapper/body_swapper = jellyman.GetComponent(/datum/component/body_swapper)
	if(!body_swapper)
		return DEFAULT_SPLIT_VOLUME

	if(isjellyperson(jellyman))
		var/datum/species/jelly/jelly_species = jellyman.dna.species
		if(jelly_species.rainbow_active)
			return DEFAULT_SPLIT_VOLUME

	return DEFAULT_SPLIT_VOLUME + SPLIT_PENALTY * (LAZYLEN(body_swapper.network.total_bodies) / max(1, LAZYLEN(body_swapper.network.minds))) ** 2

/datum/action/innate/split_body/IsAvailable()
	. = ..()
	if(!. || !ishuman(owner))
		return

	var/mob/living/carbon/human/jellyman = owner
	var/datum/component/body_swapper/body_swapper = jellyman.GetComponent(/datum/component/body_swapper)
	if(!body_swapper)
		return FALSE

	if(jellyman.blood_volume >= get_split_cost(jellyman))
		return TRUE

	return FALSE

/datum/action/innate/split_body/Activate()
	var/mob/living/carbon/human/jellyman = owner
	CHECK_DNA_AND_SPECIES(jellyman)
	var/datum/component/body_swapper/body_swapper = jellyman.GetComponent(/datum/component/body_swapper)
	if(!body_swapper)
		return

	jellyman.visible_message(span_notice("[jellyman] gains a look of concentration while standing perfectly still."), span_notice("You focus intently on moving your body while standing perfectly still..."))
	jellyman.notransform = TRUE

	if(!do_after(jellyman, delay = 6 SECONDS, target = jellyman, timed_action_flags = IGNORE_HELD_ITEM))
		to_chat(jellyman, span_warning("...but you fail to stand perfectly still!"))
		jellyman.notransform = FALSE
		return

	if(jellyman.blood_volume < get_split_cost(jellyman))
		to_chat(jellyman, span_warning("...but there is not enough of you to go around! You must attain more mass to split!"))
		return

	split_body()

/datum/action/innate/split_body/proc/split_body()
	var/mob/living/carbon/human/jellyman = owner
	CHECK_DNA_AND_SPECIES(jellyman)

	var/mob/living/carbon/human/spare = new(jellyman.loc)
	var/datum/component/body_swapper/body_swapper = jellyman.GetComponent(/datum/component/body_swapper)
	spare.AddComponent(/datum/component/body_swapper/slime, body_swapper.network)

	spare.underwear = "Nude"
	jellyman.dna.transfer_identity(spare, transfer_SE=1)
	spare.dna.features["mcolor"] = "#[num2hex(rand(85, 255), 2)][num2hex(rand(85, 255), 2)][num2hex(rand(85, 255), 2)]"
	spare.dna.update_uf_block(DNA_MUTANT_COLOR_BLOCK)
	spare.hair_color = spare.dna.features["mcolor"]
	spare.facial_hair_color = spare.dna.features["mcolor"]
	jellyman.dna.update_ui_block(DNA_HAIR_COLOR_BLOCK)
	jellyman.dna.update_ui_block(DNA_FACIAL_HAIR_COLOR_BLOCK)
	spare.real_name = spare.dna.real_name
	spare.name = spare.dna.real_name
	spare.updateappearance(mutcolor_update=1)
	spare.domutcheck()
	jellyman.blood_volume *= 0.45
	spare.blood_volume = jellyman.blood_volume
	spare.Move(get_step(jellyman.loc, pick(GLOB.cardinals)))
	for(var/disease in jellyman.diseases)
		spare.ForceContractDisease(disease)

	jellyman.notransform = 0
	jellyman.mind.transfer_to(spare)
	spare.visible_message(span_warning("[jellyman] distorts as a new body \"steps out\" of [jellyman.p_them()]."), span_notice("...and after a moment of disorentation, you're besides yourself!"))
