#define CORRAL_INTERFACE_NORTH_OFFSET 3

/obj/item/slime_corral_interface
	name = "corral management interface"
	desc = "A specialized tablet fitted with a multitude of xenobiological scanners, intended to keep track of living organisms in a small area."
	icon = 'icons/obj/science/xenobiology.dmi'
	icon_state = "corral_interface_item"
	base_icon_state = "corral_interface_item"

	/// ID for mappers. Allows to set up pens roundstart using corral helpers
	var/mapping_id
	/// Pylon that we are currently attached to, if any
	var/obj/machinery/corral_generator/generator
	/// Linked corral data
	var/datum/corral_data/corral

/obj/item/slime_corral_interface/Initialize(mapload)
	. = ..()
	desc += " It has [span_boldnotice("pylon attachment points")] and [span_boldnotice("small bolts for securing it to the floor or a wall")]."
	update_appearance()

/obj/item/slime_corral_interface/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_emissive", src)

/obj/item/slime_corral_interface/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if (!istype(interacting_with, /obj/machinery/corral_generator))
		return NONE

	generator = interacting_with
	var/attach_dir = get_dir(generator, user)
	switch (attach_dir)
		if (SOUTHEAST, SOUTHWEST)
			if (isnull(generator.other_generators["[SOUTH]"]))
				attach_dir = SOUTH
		if (NORTHWEST)
			if (isnull(generator.other_generators["[WEST]"]))
				attach_dir = WEST
		if (NORTHEAST)
			if (isnull(generator.other_generators["[EAST]"]))
				attach_dir = EAST
	if (!isnull(generator.other_generators["[attach_dir]"]))
		balloon_alert(user, "side occupied")
		return ITEM_INTERACT_FAILURE
	forceMove(generator)
	balloon_alert(user, "interface attached")
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	generator.attached_interface = src
	generator.interface_direction = attach_dir
	generator.corner_status["[attach_dir]"] = FALSE
	setDir(attach_dir)
	generator.setDir(attach_dir)
	update_appearance()
	generator.update_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/item/slime_corral_interface/update_icon_state()
	if (isnull(generator))
		icon_state = base_icon_state
		return ..()

	icon_state = "corral_interface"
	pixel_x = 0
	pixel_w = 0
	pixel_y = (generator.interface_direction == NORTH ? CORRAL_INTERFACE_NORTH_OFFSET : 0)
	pixel_z = 0
	return ..()

/obj/item/slime_corral_interface/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CorralInterface", name)
		ui.open()

/obj/item/slime_corral_interface/attack_self_secondary(mob/user, modifiers)
	. = ..()
	if(.)
		return
	corral_setup(get_turf(src))

// Ugly but we lack a floodfill that could fit this usecase
/obj/item/slime_corral_interface/proc/corral_setup(turf/starting_turf, mob/user = null)
	var/list/turf/turf_cache = list(starting_turf)
	var/list/turf/checked_turfs = list()
	var/invalid_break = FALSE
	corral = new()

	while (turf_cache.len)
		var/turf/check_turf = turf_cache[1]
		turf_cache -= check_turf
		corral.corral_turfs += check_turf

		var/open_directions = list(NORTH, SOUTH, EAST, WEST)

		for (var/obj/blocker in check_turf)
			if (!blocker.anchored || (!blocker.density && !istype(blocker, /obj/machinery/door)))
				continue

			if ((blocker.dir in open_directions) && (blocker.flags_1 & ON_BORDER_1))
				open_directions -= blocker.dir

		for (var/direction in open_directions)
			var/turf/new_turf = get_step(check_turf, direction)

			if (get_dist(new_turf, starting_turf) > CORRAL_MAXIMUM_SEARCH_RANGE)
				invalid_break = TRUE
				break

			if ((new_turf in turf_cache) || (new_turf in corral.corral_turfs) || (new_turf in checked_turfs))
				continue

			if (isclosedturf(new_turf))
				continue

			var/found_blocker = FALSE

			for (var/obj/blocker in new_turf)
				if (istype(blocker, /obj/structure/corral_fence))
					var/obj/structure/corral_fence/fence = blocker
					corral.fences += fence
					corral.generators |= fence.generator1
					corral.generators |= fence.generator2
					found_blocker = TRUE
					break

				if (!blocker.anchored || (!blocker.density && !istype(blocker, /obj/machinery/door)))
					continue

				// Slimes could pass through this, probably
				if (blocker.pass_flags_self & (PASSTABLE|PASSGRILLE|PASSBLOB|PASSMOB|PASSFLAPS|PASSVEHICLE|PASSITEM))
					continue

				if ((blocker.flags_1 & ON_BORDER_1) && (blocker.dir != REVERSE_DIR(direction)))
					continue

				found_blocker = TRUE

			if (found_blocker)
				continue

			if (isopenspaceturf(new_turf) || isspaceturf(new_turf))
				invalid_break = TRUE
				break

			turf_cache += new_turf

		if (invalid_break)
			break

	if (invalid_break)
		QDEL_NULL(corral)
		playsound(src, 'sound/machines/scanbuzz.ogg', 100, FALSE)
		if (user)
			balloon_alert(user, "invalid area")
		return

	balloon_alert(user, "corral located")
	playsound(src, 'sound/machines/high_tech_confirm.ogg', 50, FALSE)

	for (var/turf/display in corral.corral_turfs)
		new /obj/effect/temp_visual/corral_confirm(display)

/obj/effect/temp_visual/corral_confirm
	name = "corral confirmation marker"
	layer = BELOW_MOB_LAYER
	plane = GAME_PLANE
	duration = 6
	icon_state = "blip"
	color = "#9B5995"

#undef CORRAL_INTERFACE_NORTH_OFFSET
