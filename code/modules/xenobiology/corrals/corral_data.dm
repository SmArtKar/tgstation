/// Container for corral-related data.
/datum/corral_data
	/// Turfs inside the corral
	var/list/turf/corral_turfs = list()
	/// All pylons attached to the corral
	var/list/obj/machinery/corral_generator/generators = list()
	/// All barriers forming the corral
	var/list/obj/structure/corral_fence/fences = list()

