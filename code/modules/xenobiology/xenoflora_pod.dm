/obj/machinery/xenoflora_pod_part
	name = "xenoflora pod shell"
	desc = "A part of a xenoflora pod shell. Combine four of these and you'll get a full pod."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "xenoflora_pod"

/obj/machinery/xenoflora_pod_part/Initialize(mapload)
	. = ..()
	for(var/obj/machinery/xenoflora_pod_part/pod_part in range(1, src))
		pod_part.attempt_assembly()

/obj/machinery/xenoflora_pod_part/proc/attempt_assembly()
	var/turf/first_turf = locate(x + 1, y, z)
	var/turf/second_turf = locate(x, y + 1, z)
	var/turf/third_turf = locate(x + 1, y + 1, z)

	var/obj/machinery/xenoflora_pod_part/first = locate(/obj/machinery/xenoflora_pod_part) in first_turf
	var/obj/machinery/xenoflora_pod_part/second = locate(/obj/machinery/xenoflora_pod_part) in second_turf
	var/obj/machinery/xenoflora_pod_part/third = locate(/obj/machinery/xenoflora_pod_part) in third_turf

	if(!first || !second || !third)
		return

	self.invisibility = INVISIBILITY_ABSTRACT
	first.invisibility = INVISIBILITY_ABSTRACT
	second.invisibility = INVISIBILITY_ABSTRACT
	third.invisibility = INVISIBILITY_ABSTRACT
	new /obj/machinery/xenoflora_pod(get_turf(src), list(src, first, second, third))

/obj/machinery/xenoflora_pod
	name = "xenoflora pod"
	desc = "A big hydroponics tray with a glass dome."
	icon = 'icons/obj/xenobiology/xenoflora_pod.dmi'
	icon_state = "pod"
	var/list/pod_parts = list()

/obj/machinery/xenoflora_pod/Initialize(mapload, parts)
	. = ..()
	pod_parts = parts
