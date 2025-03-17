// Motorics: Move fast, swing faster. Also determines shooting and attention to details.

/datum/attribute/motorics
	name = "Motorics"
	desc = "Your senses, how agile you are. How well you move your body."
	color = "#d8b653"

// Aspects

// Allows you to dodge punches, and sometimes even bullets
/datum/aspect/reaction_speed
	name = "Reaction Speed"
	desc = "The quickest to react. An untouchable man."
	attribute = /datum/attribute/motorics

// Increases your melee attack and movement speed
/datum/aspect/savoir_faire
	name = "Savoir Faire"
	desc = "Sneak under their noses. Stun with immense panache."
	attribute = /datum/attribute/motorics

/datum/aspect/savoir_faire/register_body(datum/mind/source, mob/living/old_current)
	. = ..()
	var/mob/living/owner = get_body()
	RegisterSignals(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_ATTACK_ATOM, COMSIG_MOB_ATTACK_HAND), PROC_REF(adjust_melee_cd))

/datum/aspect/savoir_faire/unregister_body(mob/living/old_body)
	UnregisterSignal(old_body, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_ATTACK_ATOM, COMSIG_MOB_ATTACK_HAND))
	old_body.remove_movespeed_modifier(/datum/movespeed_modifier/savoir_faire)

/datum/aspect/savoir_faire/proc/adjust_melee_cd(mob/living/source)
	SIGNAL_HANDLER
	source.changeNext_move(CLICK_CD_MELEE - (level - ASPECT_LEVEL_NEUTRAL) * SAVOIR_FAIRE_ATTACK_SPEED_REDUCTION)

/datum/aspect/savoir_faire/update_effects(prev_level)
	var/mob/living/owner = get_body()
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/savoir_faire, TRUE, (level - ASPECT_LEVEL_NEUTRAL) * SAVOIR_FAIRE_MOVESPEED_MULTIPLIER)

// Improves your firing skills, high levels can give you autoaim
// Also allows you to automatically catch stuff
/datum/aspect/hand_eye_coordination
	name = "Hand/Eye Coordination"
	desc = "Ready? Aim and fire."
	attribute = /datum/attribute/motorics

/datum/aspect/hand_eye_coordination/update_effects(prev_level)
	var/mob/living/owner = get_body()

	if (get_level() >= HAND_EYE_FREE_WIELD_LEVEL)
		ADD_TRAIT(owner, TRAIT_HEAVY_GUNNER, ASPECT_TRAIT)
	else
		REMOVE_TRAIT(owner, TRAIT_HEAVY_GUNNER, ASPECT_TRAIT)

	if (get_level() >= HAND_EYE_AKIMBO_ANY_LEVEL)
		ADD_TRAIT(owner, TRAIT_ANY_DUAL_WIELD, ASPECT_TRAIT)
	else
		REMOVE_TRAIT(owner, TRAIT_ANY_DUAL_WIELD, ASPECT_TRAIT)

/datum/aspect/hand_eye_coordination/unregister_body(mob/living/old_body)
	. = ..()
	REMOVE_TRAIT(old_body, TRAIT_HEAVY_GUNNER, ASPECT_TRAIT)
	REMOVE_TRAIT(old_body, TRAIT_ANY_DUAL_WIELD, ASPECT_TRAIT)

// Gives you dark vision, can sometimes drop info about people and their posessions when you examine, or go by them.
/datum/aspect/perception
	name = "Perception"
	desc = "See, hear and smell everything. Let no detail go unnoticed."
	attribute = /datum/attribute/motorics

/datum/aspect/perception/register_body(datum/mind/source, mob/living/old_current)
	. = ..()
	var/mob/living/owner = get_body()
	RegisterSignal(owner, COMSIG_MOB_EXAMINING, PROC_REF(on_examine))

/datum/aspect/perception/unregister_body(mob/living/old_body)
	. = ..()
	UnregisterSignal(old_body, COMSIG_MOB_EXAMINING)
	var/obj/item/organ/eyes/eyes = old_body.get_organ_by_type(/obj/item/organ/eyes)
	if (eyes)
		eyes.lighting_cutoff -= clamp((get_level() - ASPECT_LEVEL_NEUTRAL) * PERCEPTION_NIGHTVIS_MULT, 0, 100)

/datum/aspect/perception/update_effects(prev_level)
	. = ..()
	var/mob/living/owner = get_body()
	var/obj/item/organ/eyes/eyes = owner.get_organ_by_type(/obj/item/organ/eyes)
	if (!eyes)
		return
	if (!isnull(prev_level))
		eyes.lighting_cutoff -= clamp((prev_level - ASPECT_LEVEL_NEUTRAL) * PERCEPTION_NIGHTVIS_MULT, 0, 100)
	eyes.lighting_cutoff += clamp((get_level() - ASPECT_LEVEL_NEUTRAL) * PERCEPTION_NIGHTVIS_MULT, 0, 100)
	eyes.refresh()

/datum/aspect/perception/proc/on_examine(mob/source, atom/target, list/examine_strings)
	SIGNAL_HANDLER
	if (!ishuman(target) || get_level() <= 0)
		return

	var/datum/check_result/result = source.aspect_check(type, SKILLCHECK_MEDIUM, show_visual = TRUE)
	if (result.outcome < CHECK_SUCCESS)
		return

	var/mob/living/carbon/human/inspected = target
	var/list/equipment = inspected.get_equipped_items()
	var/list/dept_enzymes = list()
	for(var/datum/mind/crewmember as anything in get_crewmember_minds())
		var/mob/living/carbon/human/human_to_check = crewmember.current
		if(!istype(human_to_check)|| !human_to_check.dna || !length(crewmember.assigned_role?.departments_list & attribute.owner.assigned_role?.departments_list) || human_to_check == target || human_to_check == source)
			continue
		dept_enzymes[human_to_check.dna.unique_enzymes] = TRUE

	var/blood_line = FALSE
	var/contraband_line = FALSE

	for (var/i in 1 to get_level())
		var/obj/item/stuff = pick_n_take(equipment)
		if (!stuff)
			break

		if (!contraband_line && HAS_TRAIT(stuff, TRAIT_CONTRABAND))
			contraband_line = TRUE

		if (blood_line)
			continue

		for(var/blood in GET_ATOM_BLOOD_DNA(stuff))
			if (dept_enzymes[blood])
				blood_line = TRUE
				break

	if (blood_line)
		result = source.aspect_check(/datum/aspect/esprit_de_labos, SKILLCHECK_CHALLENGING)
		if (result.outcome >= CHECK_SUCCESS)
			examine_strings += result.show_message("Soaked in <b><i>their</i></b> blood. Blood of your colleagues, your family.")

	if (contraband_line)
		result = source.aspect_check(/datum/aspect/authority, SKILLCHECK_MEDIUM)
		if (result.outcome >= CHECK_SUCCESS)
			examine_strings += result.show_message("Wearing something they shouldn't possess.")

// Allows you to handle emergencies better
/datum/aspect/in_and_out
	name = "In and Out"
	desc = "Dash through fires and breaches. Save the day."
	attribute = /datum/attribute/motorics
	/// Are we currently holding our breath?
	var/holding_breath = FALSE

/datum/aspect/in_and_out/update_effects(prev_level)
	. = ..()
	var/mob/living/owner = get_body()
	if (get_level() >= IN_AND_OUT_HOLD_BREATH_LEVEL)
		if (prev_level < IN_AND_OUT_HOLD_BREATH_LEVEL)
			RegisterSignal(owner, COMSIG_CARBON_ATTEMPT_BREATHE, PROC_REF(attempt_breath))
	else if (prev_level >= IN_AND_OUT_HOLD_BREATH_LEVEL)
		UnregisterSignal(owner, COMSIG_CARBON_ATTEMPT_BREATHE)

/datum/aspect/in_and_out/unregister_body(mob/living/old_body)
	. = ..()
	UnregisterSignal(old_body, COMSIG_CARBON_ATTEMPT_BREATHE)

/datum/aspect/in_and_out/proc/attempt_breath(mob/living/carbon/source, datum/gas_mixture/breath)
	SIGNAL_HANDLER

	if (holding_breath)
		if (should_hold_breath(source, breath))
			// Take oxyloss when you fail to breathe, less if you "know" how to hold your breath "properly", whatever that means
			source.adjustOxyLoss(1 / log(IN_AND_OUT_HOLD_BREATH_LEVEL, get_level()))
			return COMSIG_CARBON_BLOCK_BREATH

		source.balloon_alert("you stop holding your breath")
		to_chat(source, span_motorics("You stop holding your breath."))
		source.remove_movespeed_modifier(/datum/movespeed_modifier/in_and_out)
		return

	// Don't start holding your breath if you're struggling to breathe - also prevents message spam
	if (source.getOxyLoss() >= 10 + get_level() * 2.5)
		return

	if (!should_hold_breath(source, breath))
		return

	source.balloon_alert("you hold your breath!")
	source.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/in_and_out, TRUE, (level - IN_AND_OUT_HOLD_BREATH_LEVEL) * IN_AND_OUT_MOVESPEED_MULTIPLIER)
	to_chat(source, span_motorics_bold("A tingling sensation in your lungs, a thin layer of plaque on your fingers, slight fog in the air. Every single one of your instincts says you should get out of here, stat."))
	holding_breath = TRUE
	return COMSIG_CARBON_BLOCK_BREATH

/datum/aspect/in_and_out/proc/should_hold_breath(mob/living/carbon/user, datum/gas_mixture/breath)
	// Breathing from internals
	if (user.internal || user.external)
		return FALSE

	// Knocked out
	if (user.stat >= UNCONSCIOUS)
		return FALSE

	// Far too exhausted - checking oxyloss separately from the rest of HP, can continue holding our breath until 79 damage total
	if (user.maxHealth - user.health + user.getOxyLoss() >= 40 || user.getOxyLoss() >= 40)
		return FALSE

	if (!breath)
		return FALSE

	for (var/datum/gas/gas_type as anything in breath.gases)
		if (!initial(gas_type.dangerous))
			continue

		if (breath[gas_type][MOLES] >= MOLES_GAS_VISIBLE)
			return TRUE

	return FALSE

// The actual hacking/power handling skill
/datum/aspect/wire_rat
	name = "Wire Rat"
	desc = "Cut the right wires. Chew through the wrong ones."
	attribute = /datum/attribute/motorics

/datum/aspect/wire_rat/proc/perform_hack(atom/target, mob/user, list/modifiers)
	if (!isliving(user))
		target.wires.interact(user)
		return

	var/list/wires = list()
	var/datum/check_result/result = user.examine_check("[REF(target)]_wires", SKILLCHECK_PRIMITIVE, /datum/aspect/encyclopedia)
	if (result?.outcome >= CHECK_SUCCESS)
		var/skipped = FALSE
		for (var/wire in target.wires.wires)
			// Skip duds
			if (wire[1] == "_")
				continue

			if (prob((result.roll + result.modifier) * 8)) // 13 roll guarantees all wires
				wires += "<a href='byond://?src=[REF(src)];target=[REF(target)];wire=[wire];examine_time=[world.time]' style='border-bottom: 1px dotted;color: inherit;text-decoration: none;'>[wire]</a>"
			else
				skipped = TRUE

		if (length(wires))
			wires.Insert(1, result.show_message("You recall [skipped ? "some of " : ""]the following wires being present on [target]..."))

	var/list/wire_states = list()
	for (var/color in target.wires.colors)
		var/color_line = "<a href='byond://?src=[REF(src)];target=[REF(target)];wire_color=[color];examine_time=[world.time]' style='border-bottom: 1px dotted;color: inherit;text-decoration: none;'>[color]</a>"
		if (target.wires.is_attached(color))
			wire_states += "The [color_line] wire has \a [target.wires.get_attached(color)] attached to it."
		else
			wire_states += "The [color_line] wire is [target.wires.is_color_cut(color) ? "cut" : "intact"]"

	to_chat(user, custom_boxed_message("motorics", "[jointext(wires, "<br>")][length(wires) ? "<br><br>" : ""][jointext(wire_states, "<br>")]"))

/datum/aspect/wire_rat/Topic(href, list/href_list)
	var/mob/living/user = get_body()
	if (usr != user || !istype(user))
		return

	if (!href_list["wire"] && !href_list["wire_color"])
		return

	var/atom/target = locate(href_list["target"])
	if (!target || !user.CanReach(target))
		return

	if (text2num(href_list["examine_time"]) + 3 MINUTES < world.time)
		return

	var/obj/item/held_tool = user.get_active_held_item()
	if (!isassembly(held_tool))
		if (!is_wire_tool(held_tool.tool_behaviour))
			held_tool = user.is_holding_tool_quality(TOOL_MULTITOOL) || user.is_holding_tool_quality(TOOL_WIRECUTTER)
		else
			held_tool = user.is_holding_tool_quality(held_tool.tool_behaviour)

	if (!held_tool)
		return

	var/datum/check_result/result = user.aspect_check(type, href_list["wire"] ? SKILLCHECK_MEDIUM : SKILLCHECK_PRIMITIVE, floor(length(target.wires.wires) / WIRE_RAT_WIRES_PER_DIFFICULTY), target.wires.can_reveal_wires(user) ? WIRE_RAT_KNOWLEDGE_BOOST : 0, show_visual = TRUE)
	var/used_wire = result.outcome >= CHECK_SUCCESS ? (href_list["wire_color"] || target.wires.get_color_of_wire(href_list["wire"])) : pick(target.wires.colors)
	var/action = "stare at"
	if (isassembly(held_tool))
		action = "attach [held_tool] to"
		if (target.wires.is_attached(used_wire))
			used_wire = pick(target.wires.colors - flatten_list(target.wires.assemblies))
		target.wires.attach_assembly(used_wire, held_tool)
	else if (held_tool.tool_behaviour == TOOL_MULTITOOL)
		action = "pulse"
		target.wires.pulse_color(used_wire, user)
	else if (held_tool.tool_behaviour == TOOL_WIRECUTTER)
		if (target.wires.is_attached(used_wire))
			var/obj/item/assembly = target.wires.detach_assembly(used_wire)
			action = "detach [assembly] from"
			user.put_in_hands(assembly)
		else
			if (target.wires.is_color_cut(used_wire))
				action = "mend"
			else
				action = "cut"
			target.wires.cut_color(used_wire, user)

	to_chat(user, result.show_message("You [action] the [used_wire] wire[result.outcome == CHECK_FAILURE ? ", but something doesn't feel right.." : ""]."))
