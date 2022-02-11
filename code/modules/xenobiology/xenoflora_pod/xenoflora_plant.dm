/datum/xenoflora_plant
	var/name = "Bugplant"
	var/desc = "A strange plant that's made out of colorful rectangles, this species originates from the planet named Coderbus."

	var/icon = 'icons/obj/xenobiology/xenoflora_pod.dmi'
	var/icon_state = "error"

	var/list/required_gases = list()
	var/list/produced_gases = list()

	var/list/required_chems = list() //Don't work for now
	var/list/produced_chems = list() //Don't work for now

	var/max_progress = 100
	var/max_stage

	var/stage = 1
	var/progress = 0

	var/obj/machinery/atmospherics/components/binary/xenoflora_pod/parent_pod

/datum/xenoflora_plant/New(pod)
	. = ..()
	parent_pod = pod

/datum/xenoflora_plant/proc/Life()
	var/gases_satisfied = TRUE

	if(LAZYLEN(required_gases))
		for(var/gas_type in required_gases)
			if(!parent_pod.internal_gases.gases[gas_type] || !parent_pod.internal_gases.gases[gas_type][MOLES] || parent_pod.internal_gases.gases[gas_type][MOLES] < required_gases[gas_type])
				gases_satisfied = FALSE
				continue
			parent_pod.internal_gases.remove_specific(gas_type, required_gases[gas_type])

	if(!gases_satisfied)
		return

	progress += 1

	if(progress >= max_progress)
		stage = min(max_stage, stage + 1)
		parent_pod.update_icon()
