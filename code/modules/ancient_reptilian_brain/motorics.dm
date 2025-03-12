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
	source.changeNext_move(CLICK_CD_MELEE - (level - ASPECT_NEUTRAL_LEVEL) * SAVOIR_FAIRE_ATTACK_SPEED_REDUCTION)

/datum/aspect/savoir_faire/update_effects(prev_level)
	var/mob/living/owner = get_body()
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/savoir_faire, TRUE, (level - ASPECT_NEUTRAL_LEVEL) * SAVOIR_FAIRE_MOVESPEED_MULTIPLIER)

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

/*
/datum/aspect/perception/register_body(datum/mind/source, mob/living/old_current)
	. = ..()
	var/mob/living/owner = get_body()
	RegisterSignal(owner, COMSIG_MOB_EXAMINING, PROC_REF(on_examine))
	RegisterSignal(owner, COMSIG_LIVING_MOB_BUMPED, PROC_REF(on_living_bump))
*/
