/datum/quirk/caffeine_junkie
	name = "Caffeine Junkie"
	desc = "You just can't get enough of that sweet, delicious bitter juice in your life. You need caffeine in your system to function properly, but also metabolize it significantly slower and suffer less sideeffects"
	icon = FA_ICON_COFFEE
	value = 0
	gain_text = span_notice("You feel a strong craving for bitter bean juice.")
	lose_text = span_danger("You realize that maybe bitter bean juice is just a tad bit too bitter for you.")
	medical_record_text = "Patient has developed an abnormal tolerance to caffeine and struggles to function without it."
	mob_trait = TRAIT_SLOW_CAFFEINE_METABOLISM
	quirk_flags = QUIRK_HUMAN_ONLY|QUIRK_MOODLET_BASED|QUIRK_PROCESSES
	// How much caffeine d we have stored so far from having caffeine in our system
	var/caffeine = 0
	// How much caffeine charge are we adding every tick, tracked via comsigs for performance reasons
	var/caffeine_charge_per_tick = 0

/datum/quirk/caffeine_junkie/add(client/client_source)
	if (!quirk_holder.reagents)
		return
	RegisterSignals(quirk_holder.reagents, list(
		COMSIG_REAGENTS_ADD_REAGENT,
		COMSIG_REAGENTS_CLEAR_REAGENTS,
		COMSIG_REAGENTS_DEL_REAGENT,
		COMSIG_REAGENTS_NEW_REAGENT,
		COMSIG_REAGENTS_REM_REAGENT,
	), PROC_REF(on_reagents_changed))

/datum/quirk/caffeine_junkie/remove()
	if (!quirk_holder.reagents)
		return
	UnregisterSignals(quirk_holder.reagents, list(
		COMSIG_REAGENTS_ADD_REAGENT,
		COMSIG_REAGENTS_CLEAR_REAGENTS,
		COMSIG_REAGENTS_DEL_REAGENT,
		COMSIG_REAGENTS_NEW_REAGENT,
		COMSIG_REAGENTS_REM_REAGENT,
	))

/datum/quirk/caffeine_junkie/process(seconds_per_tick)
	if (HAS_TRAIT(quirk_holder, TRAIT_LIVERLESS_METABOLISM))
		return

	var/mob/living/carbon/human/owner = quirk_holder

/datum/quirk/caffeine_junkie/proc/on_reagents_changed(datum/reagents/source)
	SIGNAL_HANDLER
	caffeine
