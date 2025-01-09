#define MAXIMUM_SEARCH_DIST 30
#define MAX_WIDTH 5

/proc/get_steps_in(turf/source, dir, dist)
	for (var/i in 1 to dist)
		source = get_step(source, dir)
	return source

/mob/verb/spartial_refraction()
	set name = "spartial"
	var/turf/first_spawn = loc //find_maintenance_spawn()
	var/turf/second_spawn = client.holder.marked_datum

	to_chat(world, span_admin("Spartial refraction attempted at [ADMIN_COORDJMP(first_spawn)] and [ADMIN_COORDJMP(second_spawn)]"))

	var/list/valid_refractions = list()
	var/asked_dir = text2num(input(src, "Input dir"))
	var/asked_width = text2num(input(src, "Input width"))
	var/list/located_valid_first = list(asked_dir, asked_width, 0, TRUE) //list(lookup_dir, lookup_width, lookup_offset, first_valid)
	var/list/located_valid_second = list(asked_dir, asked_width, 0, TRUE)
	/*
	for (var/lookup_dir in GLOB.cardinals)
		var/list/side_dirs = (GLOB.cardinals.Copy() - lookup_dir - REVERSE_DIR(lookup_dir))
		var/true_dir = lookup_dir
		if (true_dir == SOUTH || true_dir == WEST)
			true_dir = REVERSE_DIR(true_dir)

		for (var/lookup_width in 1 to MAX_WIDTH)
			for (var/lookup_offset in -MAXIMUM_SEARCH_DIST to MAXIMUM_SEARCH_DIST)
				// Border turfs must be walls, otherwise the illusion breaks
				var/turf/border_one = get_steps_in(first_spawn, lookup_dir, lookup_offset)
				var/turf/border_two = get_steps_in(first_spawn, lookup_dir, lookup_offset + lookup_width + 1)
				if (!isclosedturf(border_one))
					continue

				var/first_valid = isclosedturf(get_step(border_one, side_dirs[1]))
				var/second_valid = isclosedturf(get_step(border_one, side_dirs[2]))

				if (!first_valid && !second_valid)
					continue

				if (!isclosedturf(border_two))
					continue

				if (first_valid && !isclosedturf(get_step(border_two, side_dirs[1])))
					first_valid = FALSE

				if (second_valid && !isclosedturf(get_step(border_two, side_dirs[2])))
					second_valid = FALSE

				if (!first_valid && !second_valid)
					continue

				for (var/inner_offset in 1 to lookup_width)
					var/turf/inner_turf = get_steps_in(first_spawn, lookup_dir, inner_offset)
					var/turf/first_turf = get_step(inner_turf, side_dirs[1])
					var/turf/second_turf = get_step(inner_turf, side_dirs[2])

					if (inner_turf.is_blocked_turf_ignore_climbable())
						first_valid = FALSE
						second_valid = FALSE
						break

					if (first_valid && first_turf.is_blocked_turf_ignore_climbable())
						first_valid = FALSE

					if (second_valid && second_turf.is_blocked_turf_ignore_climbable())
						second_valid = FALSE

					if (!first_valid && !second_valid)
						break

				if (!first_valid && !second_valid)
					continue

				if (!valid_refractions["[true_dir]"])
					valid_refractions["[true_dir]"] = list()

				var/list/dir_list = valid_refractions["[true_dir]"]
				dir_list["[lookup_width]"] = list(lookup_dir, lookup_width, lookup_offset, first_valid, second_valid)
				break

			if (!valid_refractions["[true_dir]"])
				to_chat(world, "[true_dir] [lookup_width]")
				continue

			var/list/dir_list = valid_refractions["[true_dir]"]
			if (!dir_list["[lookup_width]"])
				continue

			var/list/prev_return = dir_list["[lookup_width]"]

			for (var/lookup_offset in -MAXIMUM_SEARCH_DIST to MAXIMUM_SEARCH_DIST)
				// Border turfs must be walls, otherwise the illusion breaks
				var/turf/border_one = get_steps_in(second_spawn, lookup_dir, lookup_offset)
				var/turf/border_two = get_steps_in(second_spawn, lookup_dir, lookup_offset + lookup_width + 1)
				if (!isclosedturf(border_one))
					continue

				var/first_valid = isclosedturf(get_step(border_one, side_dirs[1]))
				var/second_valid = isclosedturf(get_step(border_one, side_dirs[2]))

				if (!first_valid && !second_valid)
					continue

				if (!isclosedturf(border_two))
					continue

				if (first_valid && !isclosedturf(get_step(border_two, side_dirs[1])))
					first_valid = FALSE

				if (second_valid && !isclosedturf(get_step(border_two, side_dirs[2])))
					second_valid = FALSE

				if (!first_valid && !second_valid)
					continue

				for (var/inner_offset in 1 to lookup_width)
					var/turf/inner_turf = get_steps_in(second_spawn, lookup_dir, inner_offset)
					var/turf/first_turf = get_step(inner_turf, side_dirs[1])
					var/turf/second_turf = get_step(inner_turf, side_dirs[2])

					if (inner_turf.is_blocked_turf_ignore_climbable())
						first_valid = FALSE
						second_valid = FALSE
						break

					if (first_valid && first_turf.is_blocked_turf_ignore_climbable())
						first_valid = FALSE

					if (second_valid && second_turf.is_blocked_turf_ignore_climbable())
						second_valid = FALSE

					if (!first_valid && !second_valid)
						break

				if (first_valid || second_valid)
					located_valid_first = prev_return
					located_valid_second = list(lookup_dir, lookup_width, lookup_offset, first_valid, second_valid)

			if (located_valid_first)
				break

		if (located_valid_first)
			break

	if (!located_valid_first)
		return
	*/

	// Dirs can differ
	var/first_dir = located_valid_first[1]
	var/second_dir = located_valid_second[1]
	var/mirage_width = located_valid_first[2]
	var/list/side_dirs = (GLOB.cardinals.Copy() - first_dir - REVERSE_DIR(first_dir))
	// Decide in which side to step, as mirages are actually two tiles wide
	var/first_side = located_valid_first[4] ? side_dirs[1] : side_dirs[2]
	var/second_side = located_valid_second[4] ? side_dirs[1] : side_dirs[2]

	to_chat(world, span_admin("Spartial refraction activated at [ADMIN_COORDJMP(get_steps_in(first_spawn, first_dir, located_valid_first[3]))] and [ADMIN_COORDJMP(get_steps_in(second_spawn, second_dir, located_valid_first[3]))]"))

	// Start creating the actual mirage
	for (var/mirage_offset in located_valid_first[3] + 1 to located_valid_first[3] + mirage_width)
		var/turf/first_render_turf = get_steps_in(first_spawn, first_dir, mirage_offset)
		var/turf/first_source_turf = get_step(first_render_turf, SOUTH)

		var/turf/second_render_turf = get_steps_in(second_spawn, first_dir, mirage_offset)
		var/turf/second_source_turf = get_step(second_render_turf, NORTH)

		create_spartial_mirage(first_render_turf, second_source_turf, NORTH)
		create_spartial_mirage(second_source_turf, first_render_turf, SOUTH)

		create_spartial_mirage(first_source_turf, second_render_turf, SOUTH)
		create_spartial_mirage(second_render_turf, first_source_turf, NORTH)

		/*
		var/extras = NONE
		if (mirage_offset == located_valid_first[3] + 1)
			extras |= REVERSE_DIR(first_dir)

		if (mirage_offset == located_valid_first[3] + mirage_width)
			extras |= first_dir
		*/

		/*
		create_spartial_mirage(first_source_turf, second_render_turf, SOUTH, extra_extend = extras)
		create_spartial_mirage(first_render_turf, second_source_turf, REVERSE_DIR(SOUTH), extra_extend = extras)
		create_spartial_mirage(second_source_turf, first_render_turf, NORTH, extra_extend = extras)
		create_spartial_mirage(second_render_turf, first_source_turf, REVERSE_DIR(NORTH), extra_extend = extras)
		*/

/mob/verb/mirage()
	set name = "mirage"
	create_spartial_mirage(loc, client.holder.marked_datum, text2num(input(src, "Input dir")))

/proc/create_spartial_mirage(turf/source, turf/destination, mirage_dir, mirage_length = world.view, extra_extend = NONE)
	// Set the source to opaque so you only see the mirage, then create a refraction teleporter for smooth transitions
	source.opacity = TRUE
	new /obj/effect/spartial_refraction(source, destination, mirage_dir)

	// Now's the tricky part - create the mirage itself. Uses improved mirage_border code
	var/atom/movable/mirage_holder/holder = new(source)
	var/x = destination.x
	var/y = destination.y
	var/z = clamp(destination.z, 1, world.maxz)
	var/turf/southwest = locate(clamp(x - (mirage_dir & WEST ? mirage_length : 0), 1, world.maxx), clamp(y - (mirage_dir & SOUTH ? mirage_length : 0), 1, world.maxy), z)
	var/turf/northeast = locate(clamp(x + (mirage_dir & EAST ? mirage_length : 0), 1, world.maxx), clamp(y + (mirage_dir & NORTH ? mirage_length : 0), 1, world.maxy), z)

	if (extra_extend & (SOUTH|WEST))
		southwest = get_steps_in(southwest, (extra_extend & (SOUTH|WEST)), mirage_dir)
	if (extra_extend & (NORTH|EAST))
		northeast = get_steps_in(northeast, (extra_extend & (NORTH|EAST)), mirage_dir)

	holder.vis_contents += block(southwest, northeast)
	if (mirage_dir & NORTH)
		holder.pixel_y += ICON_SIZE_Y
	if (mirage_dir & SOUTH)
		holder.pixel_y -= ICON_SIZE_Y * (1 + mirage_length)
	if (mirage_dir & EAST)
		holder.pixel_x += ICON_SIZE_X
	if (mirage_dir & WEST)
		holder.pixel_x -= ICON_SIZE_X * (1 + mirage_length)










/obj/effect/spartial_refraction
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	var/turf/target_turf
	var/mirage_dir

/obj/effect/spartial_refraction/Initialize(mapload, target_turf, mirage_dir)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_EXIT = PROC_REF(on_exit),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	src.target_turf = target_turf
	src.mirage_dir = mirage_dir

/obj/effect/spartial_refraction/proc/on_exit(datum/source, atom/movable/poor_soul, direction)
	SIGNAL_HANDLER

	if(!poor_soul || !(direction & mirage_dir) || !target_turf || poor_soul == src || poor_soul.invisibility >= INVISIBILITY_ABSTRACT || istype(poor_soul, /atom/movable/mirage_holder))
		return

	var/old_px = poor_soul.pixel_x
	var/old_py = poor_soul.pixel_y

	if (direction & EAST)
		poor_soul.pixel_x -= ICON_SIZE_X
	else if (direction & WEST)
		poor_soul.pixel_x += ICON_SIZE_X

	if (direction & NORTH)
		poor_soul.pixel_y -= ICON_SIZE_Y
	else if (direction & SOUTH)
		poor_soul.pixel_y += ICON_SIZE_Y

	var/glide_time = ICON_SIZE_ALL * GLOB.glide_size_multiplier * world.tick_lag / poor_soul.glide_size
	animate(poor_soul, pixel_x = old_px, pixel_y = old_py, time = glide_time, flags = ANIMATION_PARALLEL)
	poor_soul.forceMove(target_turf)
	var/mob/living/living_soul = poor_soul

	if(!istype(living_soul) || !living_soul.client)
		return COMPONENT_ATOM_BLOCK_EXIT

	old_px = living_soul.client.pixel_x
	old_py = living_soul.client.pixel_y
	if (direction & EAST)
		living_soul.client.pixel_x -= ICON_SIZE_X
	else if (direction & WEST)
		living_soul.client.pixel_x += ICON_SIZE_X

	if (direction & NORTH)
		living_soul.client.pixel_y -= ICON_SIZE_Y
	else if (direction & SOUTH)
		living_soul.client.pixel_y += ICON_SIZE_Y

	animate(living_soul.client, pixel_x = old_px, pixel_y = old_py, time = glide_time, flags = ANIMATION_PARALLEL)
	return COMPONENT_ATOM_BLOCK_EXIT

/obj/effect/spartial_refraction/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if (!.)
		return

	for (var/atom/something as anything in (target_turf.contents + target_turf))
		if (istype(something, /obj/effect/spartial_refraction)) // Infinite recursion is bad
			continue

		if (!something.CanPass(mover, border_dir))
			return FALSE

/obj/effect/spartial_refraction/Bumped(atom/movable/bumped_atom)
	for (var/atom/something as anything in (target_turf.contents + target_turf))
		if (istype(something, /obj/effect/spartial_refraction))  // Infinite recursion is bad
			continue

		if (!something.CanPass(bumped_atom, get_dir(src, bumped_atom)))
			bumped_atom.Bump(something)
			return
