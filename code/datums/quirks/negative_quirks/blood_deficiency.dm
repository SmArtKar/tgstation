/datum/quirk/item_quirk/blood_deficiency
	name = "Blood Deficiency"
	desc = "Your body can't produce enough blood to sustain itself."
	icon = FA_ICON_TINT
	value = -4
	gain_text = span_danger("You feel your vigor slowly fading away.")
	lose_text = span_notice("You feel vigorous again.")
	medical_record_text = "Patient requires regular treatment for blood loss due to low production of blood."
	hardcore_value = 8
	mail_goodies = list(/obj/item/reagent_containers/blood/o_minus) // universal blood type that is safe for all
	/// Minimum amount of blood the paint is set to
	var/min_blood = BLOOD_VOLUME_SAFE - 25 // just barely survivable without treatment

/datum/quirk/item_quirk/blood_deficiency/add_unique(client/client_source)
	give_item_to_holder(new /obj/item/storage/pill_bottle/iron(get_turf(quirk_holder)),
			list(
			LOCATION_LPOCKET = ITEM_SLOT_LPOCKET,
			LOCATION_RPOCKET = ITEM_SLOT_RPOCKET,
			LOCATION_BACKPACK = ITEM_SLOT_BACKPACK,
			LOCATION_HANDS = ITEM_SLOT_HANDS,
			))

/datum/quirk/item_quirk/blood_deficiency/add(client/client_source)
	RegisterSignal(quirk_holder, COMSIG_HUMAN_ON_HANDLE_BLOOD, PROC_REF(lose_blood))
	RegisterSignal(quirk_holder, COMSIG_SPECIES_GAIN, PROC_REF(update_mail))

	var/mob/living/carbon/human/human_holder = quirk_holder
	update_mail(new_species = human_holder.dna.species)

/datum/quirk/item_quirk/blood_deficiency/remove()
	UnregisterSignal(quirk_holder, list(COMSIG_HUMAN_ON_HANDLE_BLOOD, COMSIG_SPECIES_GAIN))

/datum/quirk/item_quirk/blood_deficiency/proc/lose_blood(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	var/mob/living/carbon/human/human_holder = quirk_holder
	if(human_holder.stat == DEAD || human_holder.blood_volume <= min_blood)
		return
	// This exotic blood check is solely to snowflake slimepeople into working with this quirk
	if(HAS_TRAIT(quirk_holder, TRAIT_NOBLOOD) && isnull(human_holder.dna.species.exotic_blood))
		return

	var/drain_volume = human_holder.dna.species.blood_deficiency_drain_rate
	if (human_holder.reagents.has_reagent(/datum/reagent/iron))
		// Makes iron *far* less effective at restoring your blood. Get some saline, buddy!
		drain_volume -= 0.20
	human_holder.blood_volume = max(min_blood, human_holder.blood_volume - drain_volume * seconds_per_tick)

/datum/quirk/item_quirk/blood_deficiency/proc/update_mail(datum/source, datum/species/new_species, datum/species/old_species)
	SIGNAL_HANDLER

	mail_goodies.Cut()

	if(isnull(new_species.exotic_blood) && isnull(new_species.exotic_bloodtype))
		if(TRAIT_NOBLOOD in new_species.inherent_traits)
			return

		mail_goodies += /obj/item/reagent_containers/blood/o_minus
		return

	for(var/obj/item/reagent_containers/blood/blood_bag as anything in typesof(/obj/item/reagent_containers/blood))
		var/right_blood_type = !isnull(new_species.exotic_bloodtype) && initial(blood_bag.blood_type) == new_species.exotic_bloodtype
		var/right_blood_reagent = !isnull(new_species.exotic_blood) && initial(blood_bag.unique_blood) == new_species.exotic_blood
		if(right_blood_type || right_blood_reagent)
			mail_goodies += blood_bag
