/datum/xenoflora_plant
	var/name = "Bugplant"
	var/desc = "A strange plant that's made out of colorful rectangles, this species originates from the planet named Coderbus."

	var/icon = 'icons/obj/xenobiology/xenoflora_pod.dmi'
	var/icon_state = "error"
	var/ground_icon_state = "dirt"

	var/list/required_gases = list()
	var/list/produced_gases = list()
	var/min_safe_temp = T0C
	var/max_safe_temp = T0C + 100

	var/list/required_chems = list()
	var/list/produced_chems = list()

	var/max_progress = 100
	var/max_stage = 4

	var/max_health = 300
	var/hitpoints = 300

	var/stage = 1
	var/progress = 0

	var/obj/machinery/atmospherics/components/binary/xenoflora_pod/parent_pod

/datum/xenoflora_plant/New(pod)
	. = ..()
	parent_pod = pod

/datum/xenoflora_plant/proc/Life()
	var/gases_satisfied = TRUE
	var/chems_satisfied = TRUE

	if(LAZYLEN(required_gases))
		for(var/gas_type in required_gases)
			if(!parent_pod.internal_gases.gases[gas_type] || !parent_pod.internal_gases.gases[gas_type][MOLES] || parent_pod.internal_gases.gases[gas_type][MOLES] < required_gases[gas_type])
				gases_satisfied = FALSE
				continue
			parent_pod.internal_gases.remove_specific(gas_type, required_gases[gas_type])

	if(LAZYLEN(required_chems))
		for(var/chem_type in required_chems)
			if(!parent_pod.reagents.remove_reagent(chem_type, required_chems[chem_type]))
				chems_satisfied = FALSE

	if(!gases_satisfied)
		health = max(0, health - 1)
		return FALSE

	if(!chems_satisfied)
		health = max(0, health - 1)
		return FALSE

	if(parent_pod.internal_gases.return_temperature() >= max_safe_temp || parent_pod.internal_gases.return_temperature() <= min_safe_temp)
		health = max(0, health - 3)
		return FALSE

	health = min(max_health, health + 1)
	progress += 1

	if(progress >= max_progress)
		progress = 0
		stage = min(max_stage, stage + 1)
		parent_pod.update_icon()

	if(LAZYLEN(produced_gases))
		for(var/gas_type in produced_gases)
			if(parent_pod.internal_gases.return_volume() >= XENOFLORA_MAX_MOLES)
				break

			parent_pod.internal_gases.add_gas(gas_type)
			parent_pod.internal_gases.gases[gas_type][MOLES] += produced_gases[gas_type]


	if(LAZYLEN(required_chems))
		for(var/chem_type in required_chems)
			parent_pod.reagents.add_reagent(chem_type, required_chems[chem_type])

	return TRUE
