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
		if(!istype(human_to_check)|| !human_to_check.dna || !length(crewmember.assigned_role?.departments_list, attribute.owner.assigned_role?.departments_list) || human_to_check == target || human_to_check == source)
			continue
		dept_enzymes[human_to_check.dna.unique_enzymes] = TRUE

	var/blood_line = FALSE
	var/contraband_line = FALSE

	for (var/i in 1 to get_level())
		var/obj/item/stuff = pick_n_take(equipment)
		if (!contraband_line && HAS_TRAIT(stuff, TRAIT_CONTRABAND))
			examine_strings += result.show_message("Wearing something they shouldn't possess.")
			contraband_line = TRUE

		if (blood_line)
			continue

		for(var/blood in GET_ATOM_BLOOD_DNA(stuff))
			if (dept_enzymes[blood])
				blood_line = TRUE
				break

	if (blood_line)
		result = source.aspect_check(/datum/aspect/esprit_de_opus, SKILLCHECK_CHALLENGING)
		if (result.outcome >= CHECK_SUCCESS)
			examine_strings += result.show_message("Covered in <b><i>their</i></b> blood. Blood of your colleagues, your family.")

// Allows you to handle emergencies better
/datum/aspect/in_and_out
	name = "In and Out"
	desc = "Dash through fires and breaches. Save the day."
	attribute = /datum/attribute/motorics

// The actual hacking/power handling skill
/datum/aspect/wire_rat
	name = "Wire Rat"
	desc = "Cut the right wires. Chew through the wrong ones."
	attribute = /datum/attribute/motorics
