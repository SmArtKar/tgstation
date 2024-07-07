/// Container for corral-related data.
/datum/corral_data
	/// Turfs inside the corral
	var/list/turf/corral_turfs = list()
	/// All pylons attached to the corral
	var/list/obj/machinery/corral_generator/generators = list()
	/// All barriers forming the corral
	var/list/obj/structure/corral_fence/fences = list()
	/// All slimes currently inside the corral
	var/list/mob/living/basic/slime/slimes = list()
	/// Linked interface
	var/obj/item/slime_corral_interface/interface

/datum/corral_data/New(obj/item/slime_corral_interface/interface)
	. = ..()
	src.interface = interface

/// Called when the corral is successfully set up
/datum/corral_data/proc/created()
	for (var/turf/display in corral_turfs)
		new /obj/effect/temp_visual/corral_confirm(display)
		RegisterSignal(display, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
		RegisterSignal(display, COMSIG_ATOM_EXITED, PROC_REF(on_exited))

/datum/corral_data/proc/on_entered(turf/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if (!isslime(arrived))
		return

	slimes |= arrived

/datum/corral_data/proc/on_exited(turf/source, atom/movable/gone, direction)
	SIGNAL_HANDLER

	if ((gone in slimes) && !(gone.loc in corral_turfs))
		slimes -= gone
