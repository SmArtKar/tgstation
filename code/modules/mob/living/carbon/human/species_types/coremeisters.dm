#define MAX_CORES_CONSUMED 5

/datum/species/jelly/coremeister
	name = "Coremeister"
	plural_form = null
	id = SPECIES_COREMEISTER
	examine_limb_id = SPECIES_COREMEISTER
	bodypart_overrides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/jelly,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/jelly,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/jelly/coremeister,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/jelly,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/jelly,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/jelly,
	)

	var/obj/effect/dummy/coremeister_glow/glow
	var/datum/action/innate/use_extract/extract_minor
	var/datum/action/innate/use_extract/major/extract_major
	var/datum/action/innate/core_menu/core_menu

	var/glow_intensity = 0

	var/obj/item/slime_extract/current_core
	var/list/extract_storage = list()

	COOLDOWN_DECLARE(core_swap_cooldown)
	var/list/core_type_cooldowns = list()

/datum/species/jelly/coremeister/spec_life(mob/living/carbon/human/jellyman, delta_time, times_fired)
	. = ..()
	if(current_core)
		current_core.coremeister_life(jellyman, src, delta_time, times_fired)

	for(var/core_type in core_type_cooldowns)
		core_type_cooldowns[core_type] -= delta_time SECONDS
		if(core_type_cooldowns[core_type] <= 0)
			core_type_cooldowns -= core_type
			extract_minor.UpdateButtons()
			extract_major.UpdateButtons()

//Species datums don't normally implement destroy, but JELLIES SUCK ASS OUT OF A STEEL STRAW
/datum/species/jelly/coremeister/Destroy(force, ...)
	QDEL_NULL(glow)
	QDEL_NULL(extract_major)
	QDEL_NULL(extract_minor)
	QDEL_NULL(core_menu)
	return ..()

/datum/species/jelly/coremeister/on_species_loss(mob/living/carbon/jellyman)
	. = ..()
	QDEL_NULL(glow)
	QDEL_NULL(extract_major)
	QDEL_NULL(extract_minor)
	QDEL_NULL(core_menu)
	UnregisterSignal(jellyman, COMSIG_MOB_MIDDLECLICKON)
	if(current_core)
		current_core.coremeister_discarded(jellyman, src)

/datum/species/jelly/coremeister/on_species_gain(mob/living/carbon/jellyman, datum/species/old_species)
	. = ..()
	glow = new(jellyman)
	update_glow(jellyman)
	RegisterSignal(jellyman, COMSIG_MOB_MIDDLECLICKON, .proc/core_swap)
	extract_minor = new(src)
	extract_major = new(src)
	core_menu = new(src)
	core_menu.Grant(jellyman)

/datum/species/jelly/coremeister/proc/update_glow(mob/living/carbon/jellyman, intensity)
	if(intensity)
		glow_intensity = intensity
	glow.set_light_range_power_color(glow_intensity, glow_intensity, jellyman.dna.features["mcolor"])

/datum/species/jelly/coremeister/change_color(mob/living/carbon/jellyman, new_color = null)
	. = ..()
	update_glow(jellyman)

/datum/species/jelly/coremeister/handle_rainbow(mob/living/carbon/jellyman)
	. = ..()
	update_glow(jellyman)

/datum/species/jelly/coremeister/start_rainbow(mob/living/carbon/jellyman, duration)
	. = ..()
	glow_intensity = COREMEISTER_RAINBOW_GLOW

/datum/species/jelly/coremeister/stop_rainbow(mob/living/carbon/jellyman)
	. = ..()
	glow_intensity = 0
	update_glow(jellyman)

/datum/species/jelly/coremeister/consume_extract(mob/living/carbon/jellyman, obj/item/slime_extract/extract)
	if(LAZYLEN(extract_storage) >= MAX_CORES_CONSUMED)
		to_chat(jellyman, span_warning("You can't consume more slime extracts until you vomit some of your current ones out!"))
		return

	playsound(jellyman,'sound/items/eatfood.ogg', 50, TRUE)
	jellyman.visible_message(span_notice("[jellyman] consumes [extract]."), span_notice("You consume [extract]."))
	extract_storage += extract
	extract.forceMove(jellyman)

/datum/species/jelly/coremeister/proc/core_swap(mob/living/carbon/jellyman, atom/clicked, params)
	if(!COOLDOWN_FINISHED(src, core_swap_cooldown) && !rainbow_active) //Rainbow mode completely removes swap cooldown
		clicked.balloon_alert(jellyman, "core swap is not ready!")
		return

	var/list/core_picker = list()
	var/list/cores = list()
	for(var/obj/item/slime_extract/extract in extract_storage)
		cores[extract.name] = extract
		var/image/slime_image = image(icon = 'icons/mob/slimes.dmi', icon_state = "[initial(extract.icon_state)]-dead")
		if(extract.type in core_type_cooldowns)
			slime_image.color = rgb(128,0,0)
		slime_image.pixel_y = 3
		core_picker[extract.name] = slime_image

	var/pick = show_radial_menu(jellyman, clicked, core_picker, radial_slice_icon = "slime_bg")
	if(!pick || !(pick in cores))
		return

	var/obj/item/slime_extract/picked_extract = cores[pick]
	if(picked_extract.type in core_type_cooldowns)
		clicked.balloon_alert(jellyman, "[pick] is not ready!")
		return

	select_extract(jellyman, picked_extract)

/datum/species/jelly/coremeister/proc/select_extract(mob/living/carbon/jellyman, obj/item/slime_extract/picked_extract)
	if(istype(picked_extract, /obj/item/slime_extract/special/rainbow))
		start_rainbow(jellyman, 5 MINUTES)
		qdel(picked_extract)
		return

	if(current_core)
		current_core.coremeister_discarded(jellyman, src)
		core_type_cooldowns[current_core.type] = 5 MINUTES

	current_core = picked_extract
	COOLDOWN_START(src, core_swap_cooldown, 3 MINUTES)
	change_color(jellyman, current_core.jelly_color)
	playsound(jellyman, 'sound/magic/magic_missile.ogg', 50, TRUE)
	current_core.coremeister_chosen(jellyman, src)

/datum/action/innate/use_extract
	name = "Extract Minor Activation"
	desc = "Pulse the slime extract with energized jelly to activate it."
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "slimeuse1"
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_slime"

/datum/action/innate/use_extract/IsAvailable()
	if(!..() || !iscoremeister(owner))
		return

	var/mob/living/carbon/human/jellyman = owner
	var/datum/species/jelly/coremeister/species = jellyman.dna.species
	return species.current_core && !(species.current_core.type in species.core_type_cooldowns)

/datum/action/innate/use_extract/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force)
	..(current_button, TRUE)

	if(!iscoremeister(owner))
		return

	var/mob/living/carbon/human/jellyman = owner
	var/datum/species/jelly/coremeister/species = jellyman.dna.species

	if(species.current_core)
		current_button.add_overlay(mutable_appearance(species.current_core.icon, species.current_core.icon_state))

/datum/action/innate/use_extract/Activate()
	if(!iscoremeister(owner))
		return

	var/mob/living/carbon/human/jellyman = owner
	var/datum/species/jelly/coremeister/species = jellyman.dna.species

	if(!species.current_core)
		return

	if(species.current_core.type in species.core_type_cooldowns)
		return

	if(!(species.current_core.use_types & CORE_USE_MINOR))
		return

	species.current_core.coremeister_minor(jellyman, species)

/datum/action/innate/use_extract/major
	name = "Extract Major Activation"
	desc = "Pulse the slime extract with plasma jelly to activate it."
	button_icon_state = "slimeuse2"

/datum/action/innate/use_extract/major/Activate()
	if(!iscoremeister(owner))
		return

	var/mob/living/carbon/human/jellyman = owner
	var/datum/species/jelly/coremeister/species = jellyman.dna.species

	if(!species.current_core)
		return

	if(species.current_core.type in species.core_type_cooldowns)
		return

	if(!(species.current_core.use_types & CORE_USE_MAJOR))
		return

	species.current_core.coremeister_major(jellyman, species)

/obj/effect/dummy/coremeister_glow
	name = "coremeister glow"
	desc = "Tell a coder if you're seeing this."
	icon_state = "nothing"
	light_system = MOVABLE_LIGHT
	light_range = 0
	light_power = 2.5
	light_color = COLOR_WHITE

/obj/effect/dummy/coremeister_glow/Initialize(mapload)
	. = ..()
	if(!isliving(loc))
		return INITIALIZE_HINT_QDEL

/datum/action/innate/core_menu
	name = "Slime Extract Menu"
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "core_menu"
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_slime"

/datum/action/innate/core_menu/Activate()
	if(!iscoremeister(owner))
		to_chat(owner, span_warning("You are not a walking glowstick, get out of my swamp."))
		Remove(owner)
		return

	ui_interact(owner)

/datum/action/innate/core_menu/ui_host(mob/user)
	return owner

/datum/action/innate/core_menu/ui_state(mob/user)
	return GLOB.always_state

/datum/action/innate/core_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CoremeisterMenu", name)
		ui.open()

/datum/action/innate/core_menu/ui_data(mob/user)
	var/mob/living/carbon/human/jellyman = owner
	if(!iscoremeister(jellyman))
		return

	var/datum/species/jelly/coremeister/glowstick = jellyman.dna.species

	var/list/data = list()
	data["swap_cooldown"] = DisplayTimeText(COOLDOWN_TIMELEFT(glowstick, core_swap_cooldown))
	data["swap_availible"] = COOLDOWN_FINISHED(glowstick, core_swap_cooldown)
	data["cores"] = list()
	for(var/obj/item/slime_extract/extract in glowstick.extract_storage)
		var/list/core_data = list()
		core_data["name"] = extract.name
		core_data["desc"] = extract.coremeister_description
		core_data["color"] = extract.jelly_color
		core_data["chosen"] = (extract == glowstick.current_core)
		core_data["ref"] = "[REF(extract)]"
		if(extract.type in glowstick.core_type_cooldowns)
			core_data["cooldown"] = DisplayTimeText(glowstick.core_type_cooldowns[extract.type])
			core_data["select_cooldown"] = DisplayTimeText(max(glowstick.core_type_cooldowns[extract.type], COOLDOWN_TIMELEFT(glowstick, core_swap_cooldown)))
			core_data["select_availible"] = FALSE
		else
			core_data["select_cooldown"] = DisplayTimeText(COOLDOWN_TIMELEFT(glowstick, core_swap_cooldown))
			core_data["select_availible"] = COOLDOWN_FINISHED(glowstick, core_swap_cooldown)

		core_data["use_minor"] = extract.use_types & CORE_USE_MINOR
		core_data["use_major"] = extract.use_types & CORE_USE_MAJOR

		data["cores"] += list(core_data)

	return data

/datum/action/innate/core_menu/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/living/carbon/human/jellyman = owner
	if(!iscoremeister(jellyman))
		return

	var/datum/species/jelly/coremeister/glowstick = jellyman.dna.species
	var/obj/item/slime_extract/extract = locate(params["ref"]) in glowstick.extract_storage
	if(!extract)
		return

	switch(action)
		if("minor")
			if(extract != glowstick.current_core || (extract.type in glowstick.core_type_cooldowns) || !(extract.use_types & CORE_USE_MINOR))
				return

			glowstick.current_core.coremeister_minor(jellyman, glowstick)

		if("major")
			if(extract != glowstick.current_core || (extract.type in glowstick.core_type_cooldowns) || !(extract.use_types & CORE_USE_MAJOR))
				return

			glowstick.current_core.coremeister_major(jellyman, glowstick)

		if("eject")
			if(!COOLDOWN_FINISHED(glowstick, core_swap_cooldown))
				return

			to_chat(jellyman, span_notice("You eject [extract]."))
			glowstick.extract_storage -= extract
			if(glowstick.current_core == extract)
				extract.coremeister_discarded(jellyman, glowstick)
				glowstick.current_core = null
				if(glowstick.initial_mcolor)
					glowstick.change_color(glowstick.initial_mcolor)
			extract.forceMove(get_turf(jellyman))
			jellyman.put_in_hands(extract)

		if("select")
			if(!COOLDOWN_FINISHED(glowstick, core_swap_cooldown))
				return

			if(extract == glowstick.current_core || (extract.type in glowstick.core_type_cooldowns))
				return

			glowstick.select_extract(jellyman, extract)

#undef MAX_CORES_CONSUMED
