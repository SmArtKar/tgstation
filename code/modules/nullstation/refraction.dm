GLOBAL_LIST_EMPTY(spartial_refractions)
/// Creates a two-way portal based on IDs set. Don't fuck up the directions on these
/obj/effect/abstract/spartial_refraction
	icon = 'icons/effects/mapping_helpers.dmi'
	icon_state = "spartial_refraction"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	var/link_id = "error"
	var/width = 1
	var/obj/effect/abstract/spartial_refraction/partner

/obj/effect/abstract/spartial_refraction/Initialize(mapload)
	. = ..()
	startup()

	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/abstract/spartial_refraction/Destroy(force)
	. = ..()
	var/turf/turf_one = loc
	var/turf/turf_two = loc
	var/obj/effect/abstract/spartial_refraction/effect
	for (var/i in 1 to 3)
		turf_one = get_step(turf_one, turn(dir, 90))
		turf_two = get_step(turf_two, turn(dir, -90))
		effect = locate() in turf_one
		if (effect)
			qdel(effect)
		effect = locate() in turf_one
		if (effect)
			qdel(effect)

/obj/effect/abstract/spartial_refraction/proc/startup()
	if (!GLOB.spartial_refractions[link_id])
		GLOB.spartial_refractions[link_id] = src
		return

	partner = GLOB.spartial_refractions[link_id]
	GLOB.spartial_refractions -= link_id
	var/turf/cur_turf = get_turf(src)
	var/turf/partner_turf = get_turf(partner)
	var/mutable_appearance/old_apperance = partner_turf.appearance
	partner.set_partner(src, cur_turf.appearance)
	set_partner(partner, old_apperance)

/obj/effect/abstract/spartial_refraction/proc/set_partner(new_partner, mutable_appearance/partner_appearance)
	var/turf/cur_turf = get_turf(src)
	cur_turf.appearance = partner_appearance
	partner = new_partner
	create_visuals()

/obj/effect/abstract/spartial_refraction/proc/create_visuals()
	var/turf/cur_turf = get_turf(src)
	var/turf/partner_turf = get_turf(partner)
	cur_turf.AddElement(/datum/element/mirage_border, partner_turf, dir)
	if (width <= 1)
		return
	var/extra_x = 0
	var/extra_y = 0
	if (dir & NORTH)
		extra_y += 32
	else if (dir & SOUTH)
		extra_y -= 32
	if (dir & EAST)
		extra_x += 32
	else if (dir & WEST)
		extra_x -= 32
	for (var/i in 1 to (width - 1) / 2)
		var/turf/turf_one = get_step(partner, turn(dir, 90))
		var/turf/turf_two = get_step(partner, turn(dir, -90))
		cur_turf.AddElement(/datum/element/mirage_border, turf_one, dir, extra_x = extra_x + (turf_one.x - partner_turf.x) * ICON_SIZE_X, extra_y = extra_y + (turf_one.y - partner_turf.y) * ICON_SIZE_Y)
		cur_turf.AddElement(/datum/element/mirage_border, turf_two, dir, extra_x = extra_x + (turf_two.x - partner_turf.x) * ICON_SIZE_X, extra_y = extra_y + (turf_two.y - partner_turf.y) * ICON_SIZE_Y)

/obj/effect/abstract/spartial_refraction/proc/on_entered(datum/source, atom/movable/entering, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	if(!entering || entering == src || old_loc == partner.loc || entering.invisibility >= INVISIBILITY_ABSTRACT || istype(entering, /atom/movable/mirage_holder))
		return

	var/glide_dir = get_dir(src, old_loc)
	var/glide_time = ICON_SIZE_ALL * GLOB.glide_size_multiplier * world.tick_lag / entering.glide_size
	entering.forceMove(partner.loc)
	var/old_x = entering.pixel_x
	var/old_y = entering.pixel_y
	if (glide_dir & NORTH)
		entering.pixel_y += 32
	else if (glide_dir & SOUTH)
		entering.pixel_y -= 32
	if (glide_dir & EAST)
		entering.pixel_x += 32
	else if (glide_dir & WEST)
		entering.pixel_x -= 32
	animate(entering, pixel_x = old_x, pixel_y = old_y, time = glide_time, flags = ANIMATION_PARALLEL)

	if (!ismob(entering))
		return

	var/mob/as_mob = entering
	var/client/mob_client = as_mob.client
	if (!mob_client)
		return

	old_x = mob_client.pixel_x
	old_y = mob_client.pixel_y
	if (glide_dir & NORTH)
		mob_client.pixel_y += 32
	else if (glide_dir & SOUTH)
		mob_client.pixel_y -= 32
	if (glide_dir & EAST)
		mob_client.pixel_x += 32
	else if (glide_dir & WEST)
		mob_client.pixel_x -= 32
	animate(mob_client, pixel_x = old_x, pixel_y = old_y, time = glide_time, flags = ANIMATION_PARALLEL)

/obj/effect/abstract/spartial_refraction/endpoint
	icon_state = "spartial_refraction_endpoint"

/obj/effect/abstract/spartial_refraction/endpoint/create_visuals()
	return

/obj/effect/abstract/spartial_refraction/endpoint/on_entered(datum/source, atom/movable/entering, atom/old_loc, list/atom/old_locs)
	return

/obj/effect/abstract/spartial_refraction/trigger
	icon_state = "spartial_refraction_loop"
	var/triggers_required = 1
	var/triggered = FALSE
	var/trigger_list = list()

/obj/effect/abstract/spartial_refraction/trigger/on_entered(datum/source, atom/movable/entering, atom/old_loc, list/atom/old_locs)
	if(!entering || entering == src || old_loc == partner.loc || entering.invisibility >= INVISIBILITY_ABSTRACT || istype(entering, /atom/movable/mirage_holder))
		return

	if (!triggered)
		if (!(entered in trigger_list))
			trigger_list[entered] = 0
		trigger_list[entered] += 1

		if (trigger_list[entered] >= triggers_required)
			trigger()
			return

	if (!partner)
		return

	return ..()

/obj/effect/abstract/spartial_refraction/trigger/proc/trigger()
	triggered = TRUE
	qdel(src)

/obj/effect/abstract/spartial_refraction/trigger/activate/trigger()
	triggered = TRUE
	startup()

/obj/effect/abstract/spartial_refraction/trigger/activate/startup()
	if (!triggered)
		return
	return ..()

