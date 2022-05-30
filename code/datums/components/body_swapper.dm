/// Minds/mobs with this component are capable of switching bodies at will.
/datum/component/body_swapper
	var/datum/hivemind_handler/network
	var/hivemind_type = /datum/hivemind_handler

/datum/component/body_swapper/Initialize(datum/hivemind_handler/new_network)
	if(!istype(parent, /datum/mind) && !isliving(parent))
		return COMPONENT_INCOMPATIBLE

	if(new_network)
		network = new_network
	else
		network = new hivemind_type()

	if(istype(parent, /datum/mind))
		network.add_mind(parent)
		return

	network.add_body(parent)

/datum/component/body_swapper/slime
	hivemind_type = /datum/hivemind_handler/slime

/datum/hivemind_handler
	var/list/bodies = list()
	var/list/total_bodies = list()
	var/list/minds = list()
	var/list/actions = list()
	var/intruding_allowed = FALSE

/datum/hivemind_handler/Destroy(force, ...)
	for(var/mob/living/body in bodies)
		remove_body(body)

	for(var/datum/mind/mind in minds)
		remove_mind(mind)

/datum/hivemind_handler/proc/add_mind(datum/mind/new_mind)
	if(new_mind in minds)
		return FALSE

	minds += new_mind

	RegisterSignal(new_mind, COMSIG_MIND_TRANSFERRED, .proc/on_mind_transfer)
	RegisterSignal(new_mind, COMSIG_PARENT_QDELETING, .proc/on_mind_deletion)
	to_chat(new_mind, span_big("<font color=\"#008CA2\">You suddenly feel connected to something bigger...</font>"))

	if(new_mind.current)
		add_body(new_mind.current)
		handle_sentient_body(new_mind.current)
	return TRUE

/datum/hivemind_handler/proc/add_body(mob/living/new_body)
	if(new_body in bodies)
		return FALSE

	if(!(new_body in total_bodies))
		total_bodies += new_body

	bodies += new_body
	RegisterSignal(new_body, COMSIG_MOB_MIND_TRANSFERRED_INTO, .proc/possible_mindswap)
	RegisterSignal(new_body, COMSIG_PARENT_QDELETING, .proc/on_body_deletion)

	var/datum/action/innate/swap_body/swap_action = new()
	swap_action.Grant(new_body)
	actions[new_body] = swap_action

	handle_sentient_body(new_body)
	return TRUE

/datum/hivemind_handler/proc/on_mind_transfer(datum/mind/source, mob/previous_body)
	SIGNAL_HANDLER

	UnregisterSignal(previous_body, COMSIG_LIVING_DEATH)

	var/mob/living/new_body = source.current
	handle_sentient_body(new_body)

	if(new_body in bodies)
		return

	add_body(new_body)

/datum/hivemind_handler/proc/handle_sentient_body(mob/living/new_body)
	if(!new_body.mind)
		return

	RegisterSignal(new_body, COMSIG_LIVING_DEATH, .proc/on_death)

/datum/hivemind_handler/proc/on_mind_deletion(datum/mind/source, forced)
	SIGNAL_HANDLER

	remove_mind(source)

/datum/hivemind_handler/proc/on_body_deletion(mob/living/source, forced)
	SIGNAL_HANDLER

	remove_body(source)

/datum/hivemind_handler/proc/possible_mindswap(mob/living/swap_victim)
	SIGNAL_HANDLER

	if(swap_victim.mind in minds)
		return

	if(!intruding_allowed)
		remove_body(swap_victim)
		return

	add_mind(swap_victim.mind)

/datum/hivemind_handler/proc/on_death(mob/living/dead_body, gibbed)
	SIGNAL_HANDLER

	if(!dead_body.mind) //Somehow
		return

	var/list/possible_swaps = list()
	for(var/mob/living/swap_body in bodies)
		if(can_swap(swap_body))
			possible_swaps += swap_body

	if(!LAZYLEN(possible_swaps))
		return

	transfer_mind(dead_body.mind, pick(possible_swaps))

/datum/hivemind_handler/proc/remove_mind(datum/mind/removed_mind)
	minds -= removed_mind
	UnregisterSignal(removed_mind, COMSIG_MIND_TRANSFERRED)
	UnregisterSignal(removed_mind, COMSIG_PARENT_QDELETING)
	if(removed_mind.current)
		UnregisterSignal(removed_mind.current, COMSIG_LIVING_DEATH)

/datum/hivemind_handler/proc/remove_body(mob/living/removed_body)
	var/datum/action/innate/swap_body/swap_action = actions[removed_body]
	bodies -= removed_body
	actions -= removed_body
	UnregisterSignal(removed_body, COMSIG_MOB_MIND_TRANSFERRED_INTO)
	UnregisterSignal(removed_body, COMSIG_PARENT_QDELETING)
	UnregisterSignal(removed_body, COMSIG_LIVING_DEATH)
	QDEL_NULL(swap_action)

/datum/hivemind_handler/proc/can_swap(mob/living/swap_to)
	if(QDELETED(swap_to))
		return FALSE

	if(swap_to.stat == DEAD)
		return FALSE

	if(swap_to.mind)
		return FALSE

	if(!(swap_to in bodies))
		return FALSE

	return TRUE

/datum/hivemind_handler/proc/transfer_mind(datum/mind/swapping, mob/living/swap_to)
	if(!can_swap(swap_to)) //Sanity
		return

	if(swapping.current.stat == CONSCIOUS)
		swapping.current.visible_message(span_notice("[swapping.current] stops moving and starts staring vacantly into space."), span_notice("You stop moving this body..."))
	else
		to_chat(swapping.current, span_notice("You abandon this body..."))

	swapping.current.transfer_trait_datums(swap_to)
	swapping.transfer_to(swap_to)
	swap_to.visible_message(span_notice("[swap_to] blinks and looks around."), span_notice("...and move this one instead."))
	SStgui.close_uis(actions[swapping.current])

/datum/hivemind_handler/slime/add_body(mob/living/new_body)
	. = ..()
	if(!.)
		return

	if(!isslimeperson(new_body))
		return

	RegisterSignal(new_body, COMSIG_SPECIES_GAIN, .proc/on_species_gain)

/datum/hivemind_handler/slime
	intruding_allowed = TRUE

/datum/hivemind_handler/slime/remove_body(mob/living/removed_body)
	. = ..()
	if(!isslimeperson(removed_body))
		return

	UnregisterSignal(removed_body, COMSIG_SPECIES_GAIN)

/datum/hivemind_handler/slime/proc/on_species_gain(mob/living/carbon/human/source, datum/species/new_species, datum/species/old_species)
	SIGNAL_HANDLER

	if(isslimeperson(source))
		return

	qdel(source.GetComponent(/datum/component/body_swapper))
	remove_body(source)
	if(source.mind)
		remove_mind(source.mind)

/datum/action/innate/swap_body
	name = "Swap Body"
	check_flags = NONE
	button_icon_state = "slimeswap"
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_slime"

/datum/action/innate/swap_body/Activate()
	ui_interact(owner)

/datum/action/innate/swap_body/ui_host(mob/user)
	return owner

/datum/action/innate/swap_body/ui_state(mob/user)
	return GLOB.always_state

/datum/action/innate/swap_body/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BodySwapper", name)
		ui.open()

/datum/action/innate/swap_body/ui_data(mob/user)
	var/list/data = list()
	data["bodies"] = list()

	var/datum/component/body_swapper/swapper = owner.GetComponent(/datum/component/body_swapper)
	var/datum/hivemind_handler/network = swapper.network
	for(var/mob/living/body in network.bodies)
		var/list/body_data = list()
		body_data["area"] = get_area_name(body, TRUE)

		var/stat = "Error"
		switch(body.stat)
			if(CONSCIOUS)
				stat = "Conscious"
			if(SOFT_CRIT to HARD_CRIT)
				stat = "Unconscious"
			if(DEAD)
				stat = "Dead"

		body_data["status"] = stat
		body_data["name"] = body.real_name
		body_data["ref"] = "[REF(body)]"
		body_data["swappable"] = network.can_swap(body)
		body_data["body_color"] = "#FFFFFF"

		var/occupant = "Free"
		if(body == owner)
			occupant = "Current body"
		else if(body.mind)
			occupant = "Occupied by [body.mind.name]"

		body_data["occupied"] = occupant

		if(!ishuman(body))
			body_data["type"] = "simple"
			data["bodies"] += list(body_data)
			continue

		body_data["type"] = "human"
		var/mob/living/carbon/human/human_body = body
		body_data["blood_volume"] = human_body.blood_volume
		body_data["brute"] = human_body.getBruteLoss()
		body_data["burn"] = human_body.getFireLoss()
		body_data["toxin"] = human_body.getToxLoss()
		body_data["oxy"] = human_body.getOxyLoss()

		if(human_body.dna)
			body_data["body_color"] = human_body.dna.features["mcolor"]

		data["bodies"] += list(body_data)

	return data

/datum/action/innate/swap_body/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(!owner.mind)
		return

	var/datum/component/body_swapper/swapper = owner.GetComponent(/datum/component/body_swapper)
	if(!swapper || !swapper.network)
		return

	var/datum/hivemind_handler/network = swapper.network

	switch(action)
		if("swap")
			var/mob/living/carbon/human/selected = locate(params["ref"]) in network.bodies
			if(!network.can_swap(selected))
				return

			SStgui.close_uis(src)
			network.transfer_mind(owner.mind, selected)
