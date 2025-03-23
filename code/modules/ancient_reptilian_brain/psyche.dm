// Psyche: reading people, intimidation, paranormal effects

/datum/attribute/psyche
	name = "Psyche"
	desc = "Sensitivity, how emotionally intelligent you are. Your power to influence yourself and others."
	color = "#817aa6"

// Aspects

// Medical knowledge, ability to determine state that someone is in at a glance, patching people up with your bare hands
/datum/aspect/faveur_de_lame // TODO: Add barehanded healing
	name = "Faveur de l'Âme"
	desc = "Feel the heartbeat, the rhytm of the soul. Revive the dead, and cure the living."
	attribute = /datum/attribute/psyche

// Looting maintenance, tiding departments, sort-of-hacking-related but in a weirder way
/datum/aspect/grey_tide
	name = "Grey Tide"
	desc = "Toolbelt, to store your tools. Toolbox, to apply to skulls."
	attribute = /datum/attribute/psyche
	// Partially stolen from darkness adaptation
	/// Tracks last eye strength to avoid unnecessary updates / eye nerfs
	VAR_FINAL/last_eye_strength = 0
	/// When we're moving around, skip any constant tick updates
	COOLDOWN_DECLARE(skip_tick_update)
	/// Cooldown for our loot seeker ability
	COOLDOWN_DECLARE(loot_seeker_cd)

/datum/aspect/grey_tide/register_body(datum/mind/source, mob/living/old_current)
	. = ..()
	var/mob/living/owner = get_body()
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(owner, COMSIG_CARBON_GAIN_ORGAN, PROC_REF(eye_implanted))
	RegisterSignal(owner, COMSIG_CARBON_LOSE_ORGAN, PROC_REF(eye_removed))
	update_eye_status()
	START_PROCESSING(SSprocessing, src)

/datum/aspect/grey_tide/unregister_body(mob/living/old_body)
	. = ..()
	UnregisterSignal(old_body, list(COMSIG_MOVABLE_MOVED, COMSIG_CARBON_GAIN_ORGAN, COMSIG_CARBON_LOSE_ORGAN))
	STOP_PROCESSING(SSprocessing, src)

/datum/aspect/grey_tide/proc/get_eye_strength()
	var/turf/owner_turf = get_turf(get_body())
	var/darkness = istype(owner_turf) ? owner_turf.get_lumcount() : 1
	var/vision = clamp(LIGHTING_CUTOFF_MEDIUM * clamp((get_level() - ASPECT_LEVEL_NEUTRAL) / (GREY_TIDE_NIGHTVIS_LEVEL - ASPECT_LEVEL_NEUTRAL), 0, 1) - ((darkness - LIGHTING_TILE_IS_DARK) * LIGHTING_CUTOFF_MEDIUM + 5), 0, LIGHTING_CUTOFF_MEDIUM + 5)
	if (istype(get_area(owner_turf), /area/station/maintenance))
		vision += max(get_level() - ASPECT_LEVEL_NEUTRAL, 0) * GREY_TIDE_MAINT_NIGHTVIS
	return vision

/datum/aspect/grey_tide/proc/on_moved(datum/source, atom/old_loc)
	SIGNAL_HANDLER

	update_eye_status()
	COOLDOWN_START(src, skip_tick_update, 0.5 SECONDS)
	if (COOLDOWN_FINISHED(src, loot_seeker_cd))
		seek_loot()

/datum/aspect/grey_tide/proc/eye_implanted(mob/living/source, obj/item/organ/gained, special)
	SIGNAL_HANDLER

	if(istype(gained, /obj/item/organ/eyes))
		update_eye_status(gained)

/datum/aspect/grey_tide/proc/eye_removed(mob/living/source, obj/item/organ/removed, special)
	SIGNAL_HANDLER

	if(istype(removed, /obj/item/organ/eyes) && last_eye_strength > 0)
		nerf_eyes(removed)
		last_eye_strength = 0

/datum/aspect/grey_tide/process(seconds_between_ticks)
	if(COOLDOWN_FINISHED(src, skip_tick_update))
		update_eye_status()

	if (COOLDOWN_FINISHED(src, loot_seeker_cd))
		seek_loot()

/datum/aspect/grey_tide/proc/seek_loot()
	var/static/list/loot_typecache
	if (isnull(loot_typecache))
		var/list/loot_copy = list()
		var/list/to_process = GLOB.maintenance_loot.Copy() // No need to deep copy as we're not going to be modifying lists inside of it
		while (length(to_process))
			var/elem = to_process[1]
			to_process -= elem
			if (islist(elem))
				to_process += elem
			else
				loot_copy += elem

		loot_typecache = typecacheof(loot_copy)

	COOLDOWN_START(src, loot_seeker_cd, max(GREY_TIDE_SEEKER_CD - GREY_TIDE_SEEKER_CD_REDUCTION * (get_level() - ASPECT_LEVEL_NEUTRAL), 15 SECONDS))
	var/check_prob = GREY_TIDE_SEEKER_BASE + GREY_TIDE_SEEKER_SCALING * (get_level() - ASPECT_LEVEL_NEUTRAL)
	var/mob/living/owner = get_body()
	if (!istype(get_area(owner), /area/station/maintenance))
		check_prob -= GREY_TIDE_SEEKER_PENALTY

	if (check_prob <= 0)
		return

	for (var/obj/thing in view(5, owner))
		var/list/loots = thing + thing.contents // One deep, to find stuff inside of crates and closets
		for (var/atom/something as anything in loots)
			if (!is_type_in_typecache(something, loot_typecache))
				continue

			var/image/particles = image(icon = 'icons/effects/effects.dmi', icon_state = "blessed", loc = get_turf(thing), layer = ABOVE_OBJ_LAYER)
			particles.alpha = 150
			particles.appearance_flags |= KEEP_APART|RESET_ALPHA
			SET_PLANE_EXPLICIT(particles, ABOVE_GAME_PLANE, thing)
			owner.client.images += particles
			QDEL_IN(particles, 3 SECONDS)
			break

/datum/aspect/grey_tide/proc/update_eye_status(obj/item/organ/eyes/eyes = get_body()?.get_organ_by_type(/obj/item/organ/eyes))
	if(!istype(eyes))
		last_eye_strength = 0
		return
	var/new_eye_strength = get_eye_strength()
	if(last_eye_strength == new_eye_strength)
		return
	buff_eyes(eyes, new_eye_strength)
	last_eye_strength = new_eye_strength

/datum/aspect/grey_tide/proc/buff_eyes(obj/item/organ/eyes/eyes, new_strength = get_eye_strength())
	eyes.lighting_cutoff = new_strength
	if(new_strength >= LIGHTING_CUTOFF_MEDIUM)
		eyes.flash_protect = max(eyes.flash_protect += 1, FLASH_PROTECTION_WELDER)
	else if(last_eye_strength >= LIGHTING_CUTOFF_MEDIUM)
		eyes.flash_protect = max(eyes.flash_protect -= 1, FLASH_PROTECTION_HYPER_SENSITIVE)
	get_body()?.update_sight()

/datum/aspect/grey_tide/proc/nerf_eyes(obj/item/organ/eyes/eyes)
	eyes.lighting_cutoff = initial(eyes.lighting_cutoff)
	if(last_eye_strength >= LIGHTING_CUTOFF_MEDIUM)
		eyes.flash_protect = max(eyes.flash_protect -= 1, FLASH_PROTECTION_HYPER_SENSITIVE)
	get_body()?.update_sight()

// Intimidating others, being more efficient in stun combat
/datum/aspect/command // TODO: More interactions
	name = "Command"
	desc = "Intimidate the public. Assert yourself."
	attribute = /datum/attribute/psyche

// Gives you constant information about the state of your department and your colleagues
/datum/aspect/esprit_de_labos // TODO: THIS
	name = "Esprit de Labōs"
	desc = "Connect to your department. Understand the spacer culture."
	attribute = /datum/attribute/psyche

// Decreases effects of low sanity or negative moodlets, helps with addictions
/datum/aspect/morale
	name = "Morale"
	desc = "Hold yourself together. Keep your Sanity up."
	attribute = /datum/attribute/psyche

// See stuff that happened previously, useful for detectives or when you want to hunt someone down
/datum/aspect/rewind // TODO: THIS
	name = "Rewind"
	desc = "Move back in time, just a bit. Here, a drop of blood was spilled."
	attribute = /datum/attribute/psyche
