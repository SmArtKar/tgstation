/**
 * Rainbow trail is used by "Rainbow Dash" xenobio effect - user leaves a trail that lingers for a full minute and transports anybody who steps onto it like a very speedy conveyor
 */

/datum/component/rainbow_trail
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/turf/move_to

/datum/component/rainbow_trail/Initialize(trail_color, turf/target_turf)
	if(!isturf(parent) || !target_turf || !isturf(target_turf))
		return COMPONENT_INCOMPATIBLE

	var/datum/component/rainbow_trail/trail = target_turf.GetComponent(type)
	if(trail && trail.move_to == parent) //No 1 tile cycles
		return COMPONENT_INCOMPATIBLE

	var/turf/parent_turf = parent
	addtimer(CALLBACK(parent_turf, /atom.proc/add_atom_colour, trail_color, TEMPORARY_COLOUR_PRIORITY), 0.1)
	RegisterSignal(parent_turf, COMSIG_ATOM_ENTERED, .proc/on_entered)
	QDEL_IN(src, 1 MINUTES)
	move_to = target_turf

/datum/component/rainbow_trail/Destroy(force, silent)
	var/turf/parent_turf = parent
	parent_turf.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)
	UnregisterSignal(parent_turf, COMSIG_ATOM_ENTERED)
	return ..()

/datum/component/rainbow_trail/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	if(arrived.anchored)
		return
	addtimer(CALLBACK(src, .proc/move_target, arrived), 0.5)

/datum/component/rainbow_trail/proc/move_target(atom/movable/arrived)
	if(arrived.loc != parent) //They moved
		return

	for(var/turf/another_turf in range(1, parent))
		if(prob(15))
			new /obj/effect/temp_visual/rainbow_sparkles(another_turf)

	if(isitem(arrived))
		arrived.throw_at(move_to, 1, 3)
		return

	arrived.Move(move_to)
