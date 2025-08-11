#define BEAM_INACTIVE 0
#define BEAM_CHARGING 1
#define BEAM_CHANNELING 2

/obj/item/gun/energy/anomacore_channeler
	name = "anomacore channeler"
	desc = "A ."
	icon_state = "taiyo"
	inhand_icon_state = "taiyo"
	worn_icon_state = null
	automatic_charge_overlays = FALSE
	ammo_type = list(/obj/item/ammo_casing/energy)
	/// Anomaly core currently inserted into the gun
	var/obj/item/assembly/signaler/anomaly/installed_core = null
	/// Chargeup delay for the anomabeam attack
	var/beam_chargeup_delay = 1.5 SECONDS
	/// Maximum distance a beam can travel, in tiles
	var/beam_distance = 64
	/// Speed at which the beam can turn, in degrees per tick
	var/turn_speed = 15

	/// Are we currently charging an anomabeam?
	var/charging_beam = BEAM_INACTIVE
	/// Currently tracked target
	var/atom/cur_target = null
	// Desired pixel offsets for the beam
	var/target_x = 0
	var/target_y = 0
	// Current tile coordinates for the beam
	var/beam_x = -1
	var/beam_y = -1
	// Current pixel offsets for the beam
	var/beam_pixel_x = ICON_SIZE_X / 2
	var/beam_pixel_y = ICON_SIZE_Y / 2
	/// Active beam visual
	var/datum/beam/active_beam = null

/obj/item/gun/energy/anomacore_channeler/Initialize(mapload)
	. = ..()
	if (!isliving(loc))
		return
	var/mob/living/user = loc
	if (user.get_active_held_item() == src)
		click_track(user)

/obj/item/gun/energy/anomacore_channeler/Destroy()
	if (isliving(loc))
		stop_tracking(loc)
	QDEL_NULL(installed_core)
	return ..()

/obj/item/gun/energy/anomacore_channeler/equipped(mob/user, slot, initial)
	. = ..()
	if ((slot & ITEM_SLOT_HANDS) && user.get_active_held_item() == src)
		click_track(user)

/obj/item/gun/energy/anomacore_channeler/dropped(mob/user, silent)
	. = ..()
	stop_tracking(user)

/obj/item/gun/energy/anomacore_channeler/proc/click_track(mob/living/user)
	RegisterSignal(user, COMSIG_MOB_SWAP_HANDS, PROC_REF(on_swap_hands))
	RegisterSignal(user, COMSIG_MOB_LOGIN, PROC_REF(on_login))
	if (user.client)
		RegisterSignal(user.client, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(on_mouse_down))

/obj/item/gun/energy/anomacore_channeler/proc/stop_tracking(mob/living/user)
	UnregisterSignal(user, list(COMSIG_MOB_SWAP_HANDS, COMSIG_MOB_LOGIN))
	if (user.client)
		UnregisterSignal(user.client, COMSIG_CLIENT_MOUSEDOWN)
	stop_beaming()

/obj/item/gun/energy/anomacore_channeler/proc/on_login(mob/living/source)
	SIGNAL_HANDLER

	if(!source.client) // BYOND client jank
		return

	if(source.get_active_held_item() == src)
		RegisterSignal(source.client, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(on_mouse_down))

/obj/item/gun/energy/anomacore_channeler/proc/on_swap_hands(mob/living/source)
	SIGNAL_HANDLER

	if(source.get_active_held_item() == src)
		if (source.client)
			RegisterSignal(source.client, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(on_mouse_down))
	else
		UnregisterSignal(source.client, COMSIG_CLIENT_MOUSEDOWN)
		stop_beaming()

/obj/item/gun/energy/anomacore_channeler/update_overlays()
	. = ..()
	if (installed_core)
		. += mutable_appearance(icon, "[icon_state]_[installed_core.channeler_color]")
		. += emissive_appearance(icon, "[icon_state]_[installed_core.channeler_color]", src, alpha = 200)

/obj/item/gun/energy/anomacore_channeler/separate_worn_overlays(mutable_appearance/standing, mutable_appearance/draw_target, isinhands, icon_file)
	. = ..()
	if (!isinhands || !installed_core)
		return
	. += mutable_appearance(icon_file, "[icon_state]_[installed_core.channeler_color]")
	. += emissive_appearance(icon_file, "[inhand_icon_state]_[installed_core.channeler_color]", src, alpha = 200)

/obj/item/gun/energy/anomacore_channeler/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if (!istype(tool, /obj/item/assembly/signaler/anomaly))
		return NONE

	if (installed_core)
		to_chat(user, span_warning("[src] already has \a [installed_core] installed!"))
		return ITEM_INTERACT_BLOCKING

	if (!user.transferItemToLoc(tool, src))
		to_chat(user, span_warning("You fail to install [tool] into [src]!"))
		return ITEM_INTERACT_BLOCKING

	installed_core = tool
	to_chat(user, span_notice("You install [installed_core] into [src]."))
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	update_appearance()
	user.update_held_items()
	return ITEM_INTERACT_SUCCESS

/obj/item/gun/energy/anomacore_channeler/try_fire_gun(atom/target, mob/living/user, params)
	// Right click fires anomacore pellets, left click channels a beam
	// Clientless mobs also just shoot the pellets
	// Left clicks are handled via mouse down/up, so we just don't do anything on those
	if (LAZYACCESS(params2list(params), RIGHT_CLICK) || !user.client || !can_trigger_gun(user) || !can_shoot(user))
		return ..()

/obj/item/gun/energy/anomacore_channeler/proc/on_mouse_down(client/source, atom/target, turf/location, control, params)
	var/list/modifiers = params2list(params)
	var/mob/living/user = source.mob
	if (!istype(user))
		return

	if(LAZYACCESS(modifiers, SHIFT_CLICK))
		return
	if(LAZYACCESS(modifiers, CTRL_CLICK))
		return
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		return
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		return
	if(LAZYACCESS(modifiers, ALT_CLICK))
		return

	if(!isturf(user.loc) || user.throw_mode || get_dist(user, target) < 2)
		return

	if (!can_trigger_gun(user) || !can_shoot(user))
		return

	if (charging_beam) // what
		return

	if(isnull(location) || istype(target, /atom/movable/screen)) //Clicking on a screen object.
		if(target.plane != CLICKCATCHER_PLANE) //The clickcatcher is a special case. We want the click to trigger then, under it.
			return //If we click and drag on our worn backpack, for example, we want it to open instead.
		target = parse_caught_click_modifiers(modifiers, get_turf(source.eye), source)
		if(!target)
			CRASH("Failed to get the turf under clickcatcher")

	source.click_intercept_time = world.time // From this point onwards Click() will no longer be triggered.
	user.balloon_alert_to_viewers("charging an anomabeam!")
	charging_beam = BEAM_CHARGING
	RegisterSignal(user, COMSIG_MOB_LOGOUT, PROC_REF(on_logout))
	RegisterSignal(source, COMSIG_CLIENT_MOUSEUP, PROC_REF(on_mouse_up))
	if (!do_after(user, beam_chargeup_delay, src, extra_checks = CALLBACK(src, PROC_REF(check_beam_fire), user)))
		charging_beam = BEAM_INACTIVE
		return

	RegisterSignal(source, COMSIG_CLIENT_MOUSEDRAG, PROC_REF(on_mouse_drag))
	set_target(target, modifiers)
	beam_x = cur_target.x
	beam_y = cur_target.y
	beam_pixel_x = target_x
	beam_pixel_y = target_y
	send_tracer()
	charging_beam = BEAM_CHANNELING
	START_PROCESSING(SSfastprocess, src)

/obj/item/gun/energy/anomacore_channeler/proc/check_beam_fire(mob/living/user)
	// Don't need to check for user.client as charging_beam will be set to inactive on logout automatically
	return can_trigger_gun(user) && can_shoot() && charging_beam

/obj/item/gun/energy/anomacore_channeler/proc/on_mouse_up(client/source, object, location, control, params)
	SIGNAL_HANDLER
	// Stops the beam automatically
	stop_beaming()
	UnregisterSignal(source, list(COMSIG_CLIENT_MOUSEUP, COMSIG_CLIENT_MOUSEDRAG))
	UnregisterSignal(source.mob, COMSIG_MOB_LOGOUT)

/obj/item/gun/energy/anomacore_channeler/proc/on_logout(mob/living/source)
	SIGNAL_HANDLER
	// Stops the beam automatically
	stop_beaming()
	// Don't need to clean up the client as it gets deleted on cleanup
	UnregisterSignal(source, COMSIG_MOB_LOGOUT)

/obj/item/gun/energy/anomacore_channeler/proc/on_mouse_drag(client/source, atom/src_object, atom/over_object, turf/src_location, turf/over_location, src_control, over_control, params)
	SIGNAL_HANDLER

	var/list/modifiers = params2list(params)
	if(!isnull(over_location)) //This happens when the mouse is over an inventory or screen object, or on entering deep darkness, for example.
		set_target(over_object, modifiers)
		return

	var/new_target = parse_caught_click_modifiers(modifiers, get_turf(source.eye), source)
	if(!new_target)
		// Something went wrong, swap to their turf just in case
		set_target(get_turf(cur_target), modifiers)
	else
		set_target(new_target, modifiers)

/obj/item/gun/energy/anomacore_channeler/proc/set_target(atom/new_target, list/modifiers)
	if (cur_target)
		UnregisterSignal(cur_target, COMSIG_QDELETING)

	cur_target = new_target
	if (!new_target || (!isturf(new_target) && !isturf(new_target.loc)))
		cut_beam()
		return

	target_x = text2num(LAZYACCESS(modifiers, ICON_X)) || ICON_SIZE_X / 2
	target_y = text2num(LAZYACCESS(modifiers, ICON_Y)) || ICON_SIZE_Y / 2
	RegisterSignal(cur_target, COMSIG_QDELETING, PROC_REF(on_target_deleted))

/obj/item/gun/energy/anomacore_channeler/proc/on_target_deleted(datum/source)
	SIGNAL_HANDLER
	set_target(get_turf(cur_target))

/obj/item/gun/energy/anomacore_channeler/proc/stop_beaming()
	set_target(null)

/obj/item/gun/energy/anomacore_channeler/proc/cut_beam()
	charging_beam = BEAM_INACTIVE
	STOP_PROCESSING(SSfastprocess, src)
	QDEL_NULL(active_beam)

/obj/item/gun/energy/anomacore_channeler/process(seconds_per_tick)
	. = ..()
	if (cur_target && charging_beam == BEAM_CHANNELING)
		send_tracer()

/obj/item/gun/energy/anomacore_channeler/proc/send_tracer()
	var/turf/owner_turf = get_turf(loc)
	var/atom/active_target = locate(beam_x, beam_y, owner_turf.z)
	var/active_x = beam_pixel_x
	var/active_y = beam_pixel_y

	if (!active_target)
		stop_beaming()
		CRASH("Channeler was unable to locate its target at [beam_x], [beam_y], [owner_turf.z]!")

	var/cur_angle = SIMPLIFY_DEGREES(ATAN2((beam_x - owner_turf.x) * ICON_SIZE_X + beam_pixel_x - (loc.pixel_x - loc.base_pixel_x), (beam_y - owner_turf.y) * ICON_SIZE_Y + beam_pixel_y - (loc.pixel_y - loc.base_pixel_y)))
	var/target_angle = SIMPLIFY_DEGREES(ATAN2((cur_target.x - owner_turf.x) * ICON_SIZE_X + target_x - (loc.pixel_x - loc.base_pixel_x), (cur_target.y - owner_turf.y) * ICON_SIZE_Y + target_y - (loc.pixel_y - loc.base_pixel_y)))
	// If the difference between current and targeted angles is equal or less than our turn speed, just target our real target
	if (abs(target_angle - cur_angle) <= turn_speed || abs(target_angle - cur_angle) >= (360 - turn_speed))
		active_target = cur_target
		active_x = target_x
		active_y = target_y
	else
		var/new_angle = SIMPLIFY_DEGREES(cur_angle + turn_speed * SIGN(closer_angle_difference(cur_angle, target_angle)))
		// Okay so this is mildly cursed, but instead of trying to find a line intersection we can just consider the line between the two as straight vertical line
		// in which case we just need to find the distance between intersection of arccos(turn_angle) and the line, and that would be our target distance
		var/cur_dist = sqrt(((beam_x - owner_turf.x) * ICON_SIZE_X + beam_pixel_x - (loc.pixel_x - loc.base_pixel_x)) ** 2 + ((beam_y - owner_turf.y) * ICON_SIZE_Y + beam_pixel_y - (loc.pixel_y - loc.base_pixel_y)) ** 2)
		// Distance to the intersection, i.e. distance to our target. Boom.
		var/beam_dist = cur_dist / cos(turn_speed)
		var/x_offset = owner_turf.x * ICON_SIZE_X + (loc.pixel_x - loc.base_pixel_x) + beam_dist * cos(new_angle)
		var/y_offset = owner_turf.y * ICON_SIZE_Y + (loc.pixel_y - loc.base_pixel_y) + beam_dist * sin(new_angle)
		active_x = floor(MODULUS(x_offset, ICON_SIZE_X))
		active_y = floor(MODULUS(y_offset, ICON_SIZE_Y))
		var/target_x_pos = floor(x_offset / ICON_SIZE_X)
		var/target_y_pos = floor(y_offset / ICON_SIZE_Y)
		beam_x = target_x_pos
		beam_y = target_y_pos
		beam_pixel_x = active_x
		beam_pixel_y = active_y
		active_target = locate(target_x_pos, target_y_pos, owner_turf.z)

	// God forgive me for this, but sending projectiles out is actually the cleanest, albeit not the most performance-friendly
	// way to handle continious beam attacks like this. Gives us both a way to apply effects to targets, and allows objects to handle pass logic themselves
	var/obj/projectile/anomacore_tracer/tracer = new(owner_turf)
	tracer.original = active_target
	tracer.firer = loc
	tracer.fired_from = src
	tracer.range = beam_distance
	tracer.aim_projectile(active_target, loc, list(ICON_X = active_x, ICON_Y = active_y))
	tracer.fire()

/obj/item/gun/energy/anomacore_channeler/proc/update_beam(atom/hit_object, impact_x, impact_y)
	QDEL_NULL(active_beam)
	active_beam = loc.Beam(hit_object, "2-full", override_target_pixel_x = impact_x, override_target_pixel_y = impact_y)

/obj/projectile/anomacore_tracer
	name = "anomacore beam"
	icon_state = null
	hitscan = TRUE
	invisibility = INVISIBILITY_ABSTRACT

/obj/projectile/anomacore_tracer/on_range()
	var/obj/item/gun/energy/anomacore_channeler/channeler = fired_from
	channeler.update_beam(get_turf(src), entry_x + movement_vector?.pixel_x * rand(0, ICON_SIZE_X / 2), entry_y + movement_vector?.pixel_y * rand(0, ICON_SIZE_Y / 2))
	return ..()

/obj/projectile/anomacore_tracer/pre_target_impact(atom/target, impact_mode)
	if (impact_mode != PROJECTILE_PIERCE_NONE)
		return BULLET_ACT_FORCE_PIERCE
	var/obj/item/gun/energy/anomacore_channeler/channeler = fired_from
	var/impact_x = target.pixel_x + p_x - ICON_SIZE_X / 2
	var/impact_y = target.pixel_y + p_y - ICON_SIZE_Y / 2
	if(target != original)
		impact_x = entry_x + movement_vector?.pixel_x * rand(0, ICON_SIZE_X / 2)
		impact_y = entry_y + movement_vector?.pixel_y * rand(0, ICON_SIZE_Y / 2)
	channeler.update_beam(target, impact_x, impact_y)
	return BULLET_ACT_HIT

#undef BEAM_INACTIVE
#undef BEAM_CHARGING
#undef BEAM_CHANNELING
