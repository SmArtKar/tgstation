
/// Lists of all holocommunication devices on a certain frequency
GLOBAL_LIST_INIT(holocomms_networks, list(
	HOLO_FREQ_NANOTRASEN = list(),
	HOLO_FREQ_SYNDICATE = list(),
	HOLO_FREQ_CHARLIE = list(),
	HOLO_FREQ_CENTCOM = list(),
))

/// Represents a holocomms network device - MODsuits, MODlinks or holopads.
/datum/holocomm_device
	/// Name for the multitool buffer
	var/name = "ERROR"
	/// Holocomms network frequency. Only devices on the same network can be called
	var/frequency
	/// Unique ID for the device
	var/id
	/// The holocomms device that holds this datum
	var/atom/movable/owner
	/// Range in which this device picks up living beings / allows holograms to travel
	var/range = 5
	/// Types of calls that this device can receive
	var/list/valid_call_types = list()

	/// All currently existing calls
	var/list/datum/holocall/active_calls = list()
	/// All calls that are currently awaiting answering at this device
	var/list/datum/holocall/ringing_calls = list()
	/// Call that is currently awaiting from this device
	var/datum/holocall/outgoing_call

/datum/holocomm_device/New(atom/movable/owner, start_frequency)
	. = ..()
	src.owner = owner
	set_frequency(start_frequency)

/// Used to generate an ID for the holocomms network. Should only be called after set_frequency has been called at least once!
/// By default fills itself with random numbers
/datum/holocomm_device/proc/generate_id()
	var/attempts = 0
	var/digits_to_make = 3
	do
		if(attempts == 10)
			attempts = 0
			digits_to_make++
		id = ""
		for(var/i in 1 to digits_to_make)
			id += num2text(rand(0,9))
		attempts++
	while(GLOB.holocomms_networks[frequency][id])

/// Returns name to be used in holocomm requests
/datum/holocomm_device/proc/get_name()
	return id

/// Changes the holocomm frequency and updates the network lists
/datum/holocomm_device/proc/set_frequency(new_freq)
	if (!isnull(frequency))
		GLOB.holocomms_networks[frequency] -= id
	frequency = new_freq
	GLOB.holocomms_networks[frequency][id] = src

	if (isnull(id) || GLOB.holocomms_networks[frequency][id])
		generate_id()
	end_all_calls()

/datum/holocomm_device/proc/end_all_calls()
	while (active_calls.len)
		active_calls[1].end_call()

	while (ringing_calls.len)
		ringing_calls[1].end_call()

	if (!isnull(outgoing_call))
		outgoing_call.end_call()

/// Handles logic that happens upon receiving a call, ringing or automatically accepting it.
/// Returns failure reason string or FALSE in case the call passed through
/datum/holocomm_device/proc/receive_call(datum/holocomm_device/caller, datum/holocall/holocall)

	if (!isnull(outgoing_call))
		return CALL_REJECT_BUSY

	if (caller.frequency != frequency)
		return CALL_REJECT_FREQ

	// We are currently calling someone with a full presence call, user won't be able to see anything on this holopad
	if (using_full_presence())
		return CALL_REJECT_FULL_PRESENCE

	ringing_calls += holocall

/// Returns TRUE if there's an outgoing full presence call
/datum/holocomm_device/proc/using_full_presence()
	for (var/datum/holocall/existing_holocall as anything in active_calls)
		if (istype(existing_holocall, /datum/holocall/full_presence) && existing_holocall.initiator == src)
			return TRUE
	return FALSE

/// Accept call passed to it. Forced means it's been pushed through by someone with command access.
/datum/holocomm_device/proc/accept_call(accepted_call, forced = FALSE)
	if (!(accepted_call in ringing_calls) && !forced)
		return

	ringing_calls -= accepted_call
	if (QDELETED(accepted_call))
		return

	accepted_call.start_call()

/// What happens when a call ends
/// Should not be called by anything other than holocall's end_call, call that to end the call itself.
/datum/holocomm_device/proc/end_call(datum/holocall/holocall)
	if (holocall in active_calls)
		active_calls -= holocall
	if (holocall in ringing_calls)
		ringing_calls -= holocall
	if (outgoing_call == holocall)
		outgoing_call = null

/datum/holocomm_device/proc/move_hologram(obj/effect/overlay/holocall_projection/hologram, obj/effect/overlay/holoray, turf/new_turf)
	if (get_dist(get_turf(owner), new_turf) > range)
		return FALSE

	hologram.forceMove(new_turf)
	update_holoray(hologram, holoray, new_turf)
	return TRUE

/datum/holocomm_device/proc/update_holoray(obj/effect/overlay/holocall_projection/hologram, obj/effect/overlay/holoray/holoray, turf/new_turf)
	var/dist_x = hologram.x - holoray.x
	var/dist_y = hologram.y - holoray.y
	var/newangle
	if(!dist_y)
		if(dist_x >= 0)
			newangle = 90
		else
			newangle = 270
	else
		newangle = arctan(dist_x/dist_y)
		if(dist_y < 0)
			newangle += 180
		else if(dist_x < 0)
			newangle += 360

	var/matrix/M = matrix()
	if (get_dist(get_turf(hologram), new_turf) <= 1)
		animate(holoray, transform = turn(M.Scale(1,sqrt(dist_x*dist_x+dist_y*dist_y)),newangle),time = 1)
		return

	holoray.transform = turn(M.Scale(1,sqrt(dist_x*dist_x+dist_y*dist_y)),newangle)

/*
 *      Holopad device
 */

/// Holopad holocomm device. Stationary and uses an animation to signal ringing.

/datum/holocomm_device/holopad
	valid_call_types = list(
		/datum/holocall/full_presence,
	)

/datum/holocomm_device/holopad/receive_call(datum/holocomm_device/caller, datum/holocall/holocall)
	. = ..()
	if (.)
		return
	var/obj/machinery/holopad/holopad = owner
	holopad.on_call_received(holocall)
	if (holopad.allowed(holocall.caller))
		accept_call(TRUE)

/datum/holocomm_device/holopad/accept_call(forced = FALSE)
	. = ..()
	var/obj/machinery/holopad/holopad = owner
	holopad.on_call_accepted(active_calls[active_calls.len], forced)

/datum/holocomm_device/holopad/end_call(datum/holocall/holocall)
	. = ..()
	if (!holocall.answered)
		return
	var/obj/machinery/holopad/holopad = owner
	holopad.on_call_end(holocall)

// Holopads add their area and name to the ID
/datum/holocomm_device/holopad/get_name()
	return "[get_area(owner)] [owner.name] ([id])"

/*
 *
 *      Holocalls
 *
 */

/// Holocall datum, holds and handles the call
/// Abstract type, subtypes handle actual call logic for their specific call modes
/datum/holocall
	/// Mob that initiated the call
	var/mob/living/caller
	/// Device that the call was initiated from
	var/datum/holocomm_device/initiator
	/// Device that is receiving the call
	var/datum/holocomm_device/receiver
	/// Has this call been answered?
	var/answered = FALSE

/datum/holocall/New(mob/living/caller, datum/holocomm_device/initiator, datum/holocomm_device/receiver)
	. = ..()
	src.caller = caller
	src.initiator = initiator
	src.receiver = receiver

/datum/holocall/Destroy()
	end_call()
	. = ..()

/// Fully initializes the call, call when its answered (or forces itself through)
/datum/holocall/proc/start_call()
	answered = TRUE

/// Call to stop the call.
/datum/holocall/proc/end_call(reason = null)
	answered = FALSE
	initiator.end_call(src, reason)
	receiver.end_call(src, reason)

/*
 *      Full Presence calls
 */

/// "Full Presence" holocalls - caller gets projected as a hologram for the end device
/datum/holocall/full_presence
	/// Caller's eye
	var/mob/camera/holocall/eye
	/// Caller's hologram
	var/obj/effect/overlay/holocall_projection/hologram
	/// Ray VFX
	var/obj/effect/overlay/holoray/holoray
	/// Action to end the call
	var/datum/action/innate/end_holocall/hangup_action

/datum/holocall/full_presence/Destroy()
	QDEL_NULL(eye)
	QDEL_NULL(hangup_action)
	if (!QDELETED(hologram))
		QDEL_NULL(hologram)
		QDEL_NULL(holoray)
	. = ..()

/datum/holocall/full_presence/start_call()
	. = ..()
	var/turf/holopad_loc = get_turf(receiver.owner)
	eye = new(holopad_loc, caller, initiator, src)
	hangup_action = new (eye, src)
	RegisterSignal(caller, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(caller, COMSIG_QDELETING, PROC_REF(on_deleted))

	hologram = create_holocall_projection(holopad_loc)
	holoray = new(holopad_loc)
	receiver.update_holoray(holopad_loc)

/datum/holocall/full_presence/proc/move_hologram(turf/new_turf)
	return receiver.move_hologram(hologram, holoray, new_turf)

/datum/holocall/full_presence/proc/on_deleted(atom/source)
	SIGNAL_HANDLER
	end_call()

/datum/holocall/full_presence/proc/on_moved(atom/movable/source, turf/old_loc)
	SIGNAL_HANDLER
	// End the call if the user got moved away from the holopad/modlink
	if (source.loc != initiator.owner.loc || initiator.owner.loc != source)
		end_call()

/// Handles eye deactivation and all additional logic behind it
/datum/holocall/full_presence/proc/disable_presence_call(mob/living/user, mob/camera/holocall/camera)
	user.reset_perspective(null)
	user.client.view_size.unsupress()
	user.remote_control = null

/*
 *
 *      Holocall camera
 *
 */

/mob/camera/holocall
	name = "holocall camera"
	icon = 'icons/mob/silicon/cameramob.dmi'
	icon_state = "generic_camera"
	invisibility = INVISIBILITY_MAXIMUM

	/// Who is using this camera
	var/mob/living/user
	/// Device that the user is using to connect
	var/datum/holocomm_device/device
	/// Call linked to this
	var/datum/holocall/full_presence/linked_call

/mob/camera/holocall/Initialize(mapload, mob/living/user, datum/holocomm_device/device, datum/holocall/linked_call)
	. = ..()
	src.user = user
	src.device = device
	src.linked_call = linked_call

	name = "[name] ([user.name])"
	user.remote_control = src
	user.reset_perspective(src)

/mob/camera/holocall/Destroy()
	if(linked_call && user?.client)
		linked_call.disable_presence_call(user, src)
	. = ..()

/mob/camera/holocall/update_remote_sight(mob/living/call_user)
	call_user.set_invis_see(SEE_INVISIBLE_LIVING)
	return TRUE

/mob/camera/holocall/relaymove(mob/living/user, direction)
	var/turf/step_turf = get_turf(get_step(src, direction))
	if (step_turf && linked_call.move_hologram(step_turf))
		forceMove(step_turf)

/datum/action/innate/end_holocall
	name = "End Holocall"
	button_icon = 'icons/mob/actions/actions_silicon.dmi'
	button_icon_state = "end_call"
	var/datum/holocall/linked_call

/datum/action/innate/end_holocall/New(target, datum/holocall/holocall)
	..()
	linked_call = holocall

/datum/action/innate/end_holocall/Activate()
	linked_call.end_call()
