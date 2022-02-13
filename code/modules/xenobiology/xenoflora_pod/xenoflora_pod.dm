#define XENOFLORA_MAX_MOLES 3000
#define XENOFLORA_MAX_CHEMS 500

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

	qdel(first)
	qdel(second)
	qdel(third)
	new /obj/machinery/atmospherics/components/binary/xenoflora_pod(get_turf(src))
	qdel(src)

// The pod itself

/obj/machinery/atmospherics/components/binary/xenoflora_pod
	name = "xenoflora pod"
	desc = "A large hydroponics tray with an extendable glass dome in case your green friends need special atmosphere."
	icon = 'icons/obj/xenobiology/xenoflora_pod.dmi'
	icon_state = "pod"
	base_icon_state = "pod"
	density = TRUE
	layer = ABOVE_MOB_LAYER
	bound_width = 64
	bound_height = 64
	initialize_directions = SOUTH|WEST
	var/datum/gas_mixture/internal_gases
	var/datum/xenoflora_plant/plant
	var/dome_extended = TRUE

/obj/machinery/atmospherics/components/binary/xenoflora_pod/Initialize(mapload)
	. = ..()
	internal_gases = new
	plant = new(src)
	create_reagents(XENOFLORA_MAX_CHEMS, TRANSPARENT | REFILLABLE)
	AddComponent(/datum/component/plumbing/xenoflora_pod, TRUE, THIRD_DUCT_LAYER)
	update_icon()

/obj/machinery/atmospherics/components/binary/xenoflora_pod/process_atmos()
	if(!on || !is_operational || !plant)
		return

	inject_gases()
	plant.Life()
	if(!dome_extended)
		spread_gases() //Don't forget to extend the dome when working with plants that require special atmos!
	dump_gases()

/obj/machinery/atmospherics/components/binary/xenoflora_pod/proc/inject_gases()
	if(internal_gases.return_volume() >= XENOFLORA_MAX_MOLES)
		return

	var/datum/gas_mixture/input_gases = airs[2]
	for(var/gas_type in plant.required_gases)
		if(!input_gases.gases[gas_type] || !input_gases.gases[gas_type][MOLES])
			continue

		if(!internal_gases.gases[gas_type] || !internal_gases.gases[gas_type][MOLES])
			continue

		internal_gases.merge(input_gases.remove_specific(gas_type, max(0, min(input_gases.gases[gas_type][MOLES], plant.required_gases[gas_type] - internal_gases.gases[gas_type][MOLES], XENOFLORA_MAX_MOLES - internal_gases.gases[gas_type][MOLES]))))

/obj/machinery/atmospherics/components/binary/xenoflora_pod/proc/spread_gases()
	var/datum/gas_mixture/expelled_gas = internal_gases.remove(internal_gases.total_moles())
	var/turf/turf = get_turf(src)
	turf.assume_air(internal_gases)

/obj/machinery/atmospherics/components/binary/xenoflora_pod/proc/dump_gases()
	var/datum/gas_mixture/output_gases = airs[1]
	if(plant)
		for(var/gas_type in internal_gases.gases)
			if((gas_type in plant.required_gases) || !internal_gases.gases[gas_type][MOLES])
				continue

			output_gases.merge(internal_gases.remove_specific(gas_type, internal_gases.gases[gas_type][MOLES]))
	else
		output_gases.merge(internal_gases.remove(internal_gases.return_volume()))

	internal_gases.garbage_collect()

/obj/machinery/atmospherics/components/binary/xenoflora_pod/attackby(obj/item/I, mob/user, params)
	if(!on)
		if(default_deconstruction_screwdriver(user, "[base_icon_state]-open", "[base_icon_state]-unpowered", I))
			return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/atmospherics/components/binary/xenoflora_pod/update_icon_state()
	. = ..()
	if(panel_open)
		icon_state = "[base_icon_state]-open"
	else if(on && is_operational)
		icon_state = base_icon_state
	else
		icon_state = "[base_icon_state]-unpowered"

/obj/machinery/atmospherics/components/binary/xenoflora_pod/update_overlays()
	. = ..()
	cut_overlays()

	var/mutable_appearance/dome_behind = mutable_appearance(icon, "glass_behind", layer = ABOVE_ALL_MOB_LAYER + 0.1)
	var/mutable_appearance/dome_front = mutable_appearance(icon, "glass_front", layer = ABOVE_ALL_MOB_LAYER + 0.25)

	var/mutable_appearance/pipe_appearance1 = mutable_appearance('icons/obj/atmospherics/pipes/pipe_underlays.dmi', "intact_2_[piping_layer]", layer = GAS_SCRUBBER_LAYER)
	pipe_appearance1.color = COLOR_LIME

	var/mutable_appearance/pipe_appearance2 = mutable_appearance('icons/obj/atmospherics/pipes/pipe_underlays.dmi', "intact_8_[piping_layer]", layer = GAS_SCRUBBER_LAYER)
	pipe_appearance2.color = COLOR_MOSTLY_PURE_RED

	. += pipe_appearance1
	. += pipe_appearance2
	. += dome_behind
	if(plant)
		var/mutable_appearance/ground_overlay = mutable_appearance(plant.icon, "[plant.ground_icon_state]", layer = ABOVE_ALL_MOB_LAYER + 0.15)
		var/mutable_appearance/plant_overlay = mutable_appearance(plant.icon, "[plant.icon_state]-[plant.stage]", layer = ABOVE_ALL_MOB_LAYER + 0.2)
		var/mutable_appearance/screen_overlay = mutable_appearance(icon, "pod-screen", layer = ABOVE_ALL_MOB_LAYER + 0.25)
		. += ground_overlay
		. += plant_overlay
		. += screen_overlay
	. += dome_front

/obj/machinery/atmospherics/components/binary/xenoflora_pod/set_init_directions()
	initialize_directions = SOUTH|WEST

/obj/machinery/atmospherics/components/binary/xenoflora_pod/get_node_connects()
	return list(SOUTH, WEST)
