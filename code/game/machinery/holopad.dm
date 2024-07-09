#define HOLOPAD_PASSIVE_POWER_USAGE 1
#define HOLOGRAM_POWER_USAGE 2

/obj/machinery/holopad
	name = "holopad"
	desc = "A flood-mounted communication device capable of projecting holographic images."
	icon = 'icons/obj/machines/floor.dmi'
	icon_state = "holopad0"
	base_icon_state = "holopad"
	layer = MAP_SWITCH(ABOVE_OPEN_TURF_LAYER, LOW_OBJ_LAYER)
	plane = MAP_SWITCH(FLOOR_PLANE, GAME_PLANE)
	// Staff with this access (Heads of Staff by default) will forcibly connect to this holopad if its not secure, without ringing.
	req_access = list(ACCESS_KEYCARD_AUTH)
	max_integrity = 300
	armor_type = /datum/armor/machinery_holopad
	circuit = /obj/item/circuitboard/machine/holopad
	interaction_flags_atom = parent_type::interaction_flags_atom | INTERACT_ATOM_IGNORE_MOBILITY
	interaction_flags_click = ALLOW_SILICON_REACH
	processing_flags = START_PROCESSING_MANUALLY
	light_power = 0.8
	light_color = LIGHT_COLOR_LIGHT_CYAN
	voice_filter = "alimiter=0.9,acompressor=threshold=0.2:ratio=20:attack=10:release=50:makeup=2,highpass=f=1000"

	/// Secure holopads cannot be forcefully connected to even with required access
	var/secure = FALSE
	/// Can this holopad request AI's presence? Also used by request cooldown timers.
	var/can_request_ai = TRUE
	/// This holopad's starting frequency. Determines what holocomm network they can access
	var/holocomm_freq = HOLO_FREQ_NANOTRASEN
	/// Device datum used by this holopad
	var/datum/holocomm_device/holopad/holocomms
	/// Associated list of AIs -> their holograms. Handled separately because it makes no sense to use calls to do so.
	var/list/obj/effect/overlay/holocall_projection/ai_holograms = list()
	/// Same as ai_holograms, but for holorays.
	var/list/obj/effect/overlay/holoray/ai_holorays = list()

	/// Currently inserted record disk
	var/obj/item/disk/holodisk/disk
	/// Record that's currently playing
	var/datum/holorecord/record
	/// If the currently playing recording should loop
	var/looping = FALSE
	/// Currently recording
	var/record_mode = FALSE

	/// TTS all holopads use this round
	var/static/holopad_tts

/datum/armor/machinery_holopad
	melee = 50
	bullet = 20
	laser = 20
	energy = 20
	fire = 50

/obj/machinery/holopad/Initialize(mapload)
	. = ..()
	var/static/list/hovering_mob_typechecks = list(/mob/living/silicon = list(SCREENTIP_CONTEXT_ALT_LMB = "Disconnect all active calls"))
	holocomms = new(src)
	AddElement(/datum/element/contextual_screentip_mob_typechecks, hovering_mob_typechecks)
	set_frequency(holocomm_freq)
	if(SStts.tts_enabled)
		if (!holopad_tts)
			holopad_tts = pick(SStts.available_speakers)
	 	voice = holopad_tts

/obj/machinery/holopad/secure
	name = "secure holopad"
	desc = "A flood-mounted communication device capable of projecting holographic images. This one will refuse to auto-connect incoming calls."
	secure = TRUE

/obj/machinery/holopad/secure/Initialize(mapload)
	. = ..()
	var/obj/item/circuitboard/machine/holopad/board = circuit
	board.secure = TRUE
	board.build_path = /obj/machinery/holopad/secure

/obj/machinery/holopad/proc/set_frequency(new_freq)
	if (holocomms.frequency != new_freq)
		say("Holocomm network frequency updated!")
	holocomms.set_frequency(new_freq)

/obj/machinery/holopad/emag_act(mob/user, obj/item/card/emag/emag_card)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE
	obj_flags |= EMAGGED
	set_frequency(HOLO_FREQ_SYNDICATE)
	return TRUE

/obj/machinery/holopad/examine(mob/user)
	. = ..()
	if(isAI(user))
		. += span_notice("The status display reads: Current projection range: <b>[holocomms.range]</b> units. Use :h to speak through the projection. Right-click to project or cancel a projection. Alt-click to hangup all active and incomming calls. Ctrl-click to end projection without jumping to your last location.")
		return
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Current projection range: <b>[holocomms.range]</b> units.")

/obj/machinery/holopad/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/holopad/attackby(obj/item/item, mob/user, params)
	if(default_deconstruction_screwdriver(user, "holopad_open", "holopad0", item))
		return

	if(default_pry_open(item, close_after_pry = TRUE, closed_density = FALSE))
		return

	if(default_deconstruction_crowbar(item))
		return

	if(istype(item,/obj/item/disk/holodisk))
		if(disk)
			to_chat(user,span_warning("There's already a disk inside [src]!"))
			return
		if (!user.transferItemToLoc(item,src))
			return
		balloon_alert(user, "inserted disk")
		disk = item
		playsound(src, 'sound/machines/card_slide.ogg', 50)
		return

	return ..()

/obj/machinery/holopad/proc/on_call_received(datum/holocall/holocall)
	update_power()
	if (istype(holocall, /datum/holocall/full_presence))
		say("Incoming call from [holocall.caller]!")
	say("Incoming call from [holocall.devices[1].get_name()]!")
	begin_processing()

/obj/machinery/holopad/proc/on_call_end(datum/holocall/holocall)
	update_power()
	end_processing()
	if (!powered())
		return
	if (istype(holocall, /datum/holocall/full_presence) && holocall.devices[1].owner != src)
		say("[holocall.caller] disconnected.")
		return
	say("Disconnected from holocall.")

/obj/machinery/holopad/proc/on_call_accepted(datum/holocall/holocall, forced = FALSE)
	update_power()
	end_processing()
	if (forced)
		say("Administrator access detected. Forwarding the call.")

/obj/machinery/holopad/update_overlays()
	. = ..()
	if (holocomms.ringing_call || holocomms.active_calls.len)
		. += emissive_appearance(icon, "[icon_state]_emissive", src)

/obj/machinery/holopad/update_icon_state()
	if(panel_open)
		icon_state = "[base_icon_state]_open"
		return ..()

	if(holocomms.ringing_call)
		icon_state = "[base_icon_state]_ringing"
		return ..()

	// No answered calls
	if(holocomms.get_awaiting_calls().len == holocomms.active_calls.len)
		icon_state = "[base_icon_state]_calling"
		return ..()

	icon_state = "[base_icon_state][holocomms.active_calls.len ? 1 : 0]"
	return ..()

/obj/machinery/holopad/power_change()
	. = ..()
	if (!powered())
		holocomms.end_all_calls()
	update_power()

/obj/machinery/holopad/atom_break()
	. = ..()
	holocomms.end_all_calls()
	update_power()

/obj/machinery/holopad/set_anchored(anchorvalue)
	. = ..()
	if(isnull(.) || anchorvalue)
		return

	holocomms.end_all_calls()
	update_power()

/obj/machinery/holopad/proc/update_power()
	update_use_power(holocomms.active_calls.len > 0 ? ACTIVE_POWER_USE : IDLE_POWER_USE)
	update_mode_power_usage(ACTIVE_POWER_USE, initial(active_power_usage) + HOLOPAD_PASSIVE_POWER_USAGE + (HOLOGRAM_POWER_USAGE * holocomms.active_calls.len))
	var/active = holocomms.ringing_call || holocomms.active_calls.len
	if(active && !(machine_stat & (BROKEN | NOPOWER)))
		set_light(2)
	else
		set_light(0)
	update_appearance()

/obj/machinery/holopad/process()
	if (holocomms.ringing_call)
		playsound(src, 'sound/machines/twobeep.ogg', 100)

/obj/machinery/holopad/proc/connect_ai(mob/living/silicon/ai/ai)
	if (ai_holograms[ai])
		return

	var/turf/holo_turf = get_turf(src)
	ai_holograms[ai] = create_holocall_projection(ai, holo_turf)
	ai_holorays[ai] = new(holo_turf)
	holocomms.update_holoray(ai_holograms[ai], ai_holorays[ai], holo_turf)
	ai.current = src

/obj/machinery/holopad/proc/move_ai_hologram(mob/living/silicon/ai/ai, turf/new_turf)
	return holocomms.move_hologram(ai_holograms[ai], ai_holorays[ai], new_turf)

/obj/machinery/holopad/proc/clear_ai_hologram(mob/living/silicon/ai/ai)
	qdel(ai_holograms[ai])
	qdel(ai_holorays[ai])
	ai_holograms -= ai
	ai_holorays -= ai

/obj/machinery/holopad/AICtrlClick(mob/living/silicon/ai/user)
	if (!istype(user))
		return

	if(!ai_holograms[user]) //If there is no hologram, then this button does nothing.
		return

	user.lastloc = null
	clear_ai_hologram(user)

/obj/machinery/holopad/attack_ai_secondary(mob/living/silicon/ai/user)
	if (!istype(user))
		return SECONDARY_ATTACK_CONTINUE_CHAIN
	if (holocomms.frequency != HOLO_FREQ_NANOTRASEN)
		return SECONDARY_ATTACK_CONTINUE_CHAIN

	if(!ai_holograms[user])
		connect_ai(user)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	clear_ai_hologram(user)
	if(user.lastloc)
		user.eyeobj.setLoc(user.lastloc)
		user.lastloc = null

	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/*
 *
 *      Holocall VFX
 *
 */

/obj/effect/overlay/holocall_projection
	// Adds KEEP_TOGETHER to ensure we render overlays right
	appearance_flags = TILE_BOUND|PIXEL_SCALE|LONG_GLIDE|KEEP_TOGETHER
	initial_language_holder = /datum/language_holder/universal
	voice_filter = "alimiter=0.9,acompressor=threshold=0.2:ratio=20:attack=10:release=50:makeup=2,highpass=f=1000"
	/// Atom that this projection represents
	var/atom/movable/owner
	/// Holocomms device this projection belongs to
	var/datum/holocomm_device/device

/obj/effect/overlay/holocall_projection/Destroy()
	owner = null
	device = null
	return ..()

/obj/effect/overlay/holocall_projection/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return TRUE

/obj/effect/overlay/holocall_projection/examine(atom/movable/user)
	if(owner)
		return owner.examine(user)
	return ..()

/obj/effect/overlay/holocall_projection/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods = list(), message_range)
	. = ..()
	if (speaker && isAI(owner) && radio_freq) // Prevents AI from hearing radio/intercom stuff through holopads
		return
	owner.Hear(message, speaker, message_language, raw_message, radio_freq, spans, message_mods, message_range)

/proc/create_holocall_projection(atom/movable/target, holo_loc)
	var/atom/to_represent = target
	if (isAI(target))
		var/mob/living/silicon/ai/ai = target
		to_represent = ai.hologram_appearance

	var/obj/effect/overlay/holocall_projection/hologram = new (holo_loc)
	hologram.icon = to_represent.icon
	hologram.icon_state = to_represent.icon_state
	hologram.copy_overlays(to_represent, TRUE)
	hologram.make_hologram()

	if (isAI(target))
		var/mob/living/silicon/ai/ai = target
		ai.eyeobj.setLoc(get_turf(hologram))
	else
		hologram.owner = target

	hologram.mouse_opacity = MOUSE_OPACITY_TRANSPARENT // So you can't click on it.
	hologram.layer = FLY_LAYER // Above all the other objects/mobs. Or the vast majority of them.
	SET_PLANE_EXPLICIT(hologram, ABOVE_GAME_PLANE, target)
	hologram.set_anchored(TRUE) // So space wind cannot drag it.
	hologram.name = "[target.name] (Hologram)" // If someone decides to right click.
	hologram.voice = target.voice
	hologram.visible_message(span_notice("A holographic image of [target] flickers to life before your eyes!"))
	hologram.become_hearing_sensitive(INNATE_TRAIT)
	return hologram

/obj/effect/overlay/holoray
	name = "holoray"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "holoray"
	layer = FLY_LAYER
	plane = ABOVE_GAME_PLANE
	density = FALSE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_x = -32
	pixel_y = -32
	alpha = 100
	var/atom/movable/render_step/emissive/glow

/obj/effect/overlay/holoray/Initialize(mapload)
	. = ..()
	if(!render_target)
		var/static/uid = 0
		render_target = "holoray#[uid]"
		uid++
	// Let's GLOW BROTHER! (Doing it like this is the most robust option compared to duped overlays)
	glow = new(null, src)
	// We need to counteract the pixel offset to ensure we don't double offset (I hate byond)
	glow.pixel_x = 32
	glow.pixel_y = 32
	add_overlay(glow)
	LAZYADD(update_overlays_on_z, glow)

/obj/effect/overlay/holoray/Destroy(force)
	. = ..()
	QDEL_NULL(glow)
