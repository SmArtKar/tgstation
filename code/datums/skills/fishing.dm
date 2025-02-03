/**
 * skill associated with the fishing feature. It modifies the fishing minigame difficulty
 * and is gained each time one is completed.
 */
/datum/skill/fishing
	name = "Fishing"
	title = "Angler"
	desc = "How empty and alone you are on this barren Earth."
	modifiers = list(SKILL_VALUE_MODIFIER = list(1, 0, -1, -3, -5, -7, -10))
	skill_item_path = /obj/item/clothing/head/soft/fishing_hat

/datum/skill/fishing/New()
	. = ..()
	levelUpMessages[SKILL_LEVEL_NOVICE] = span_nicegreen("I'm starting to figure out what [name] really is! I can guess a fish size and weight at a glance.")
	levelUpMessages[SKILL_LEVEL_APPRENTICE] = span_nicegreen("I'm getting a little better at [name]! I can tell if a fish is hungry, dying and otherwise.")
	levelUpMessages[SKILL_LEVEL_JOURNEYMAN] = span_nicegreen("I feel like I've become quite proficient at [name]! I can tell what fishes I can catch at any given fishing spot.")
	levelUpMessages[SKILL_LEVEL_MASTER] = span_nicegreen("I've begun to truly understand the surprising depth behind [name]. As a master [title], I can guess what I'm going to catch now!")

/datum/skill/fishing/level_gained(datum/mind/mind, new_level, old_level, silent)
	. = ..()
	if(new_level >= SKILL_LEVEL_NOVICE && old_level < SKILL_LEVEL_NOVICE)
		ADD_TRAIT(mind, TRAIT_EXAMINE_FISH, SKILL_TRAIT)
		RegisterSignal(mind, COMSIG_MIND_TRANSFERRED, PROC_REF(transfer_mind))
		RegisterSignal(mind.current, COMSIG_MOB_BEGIN_FISHING, PROC_REF(on_minigame_started))
	if(new_level >= SKILL_LEVEL_APPRENTICE && old_level < SKILL_LEVEL_APPRENTICE)
		ADD_TRAIT(mind, TRAIT_EXAMINE_DEEPER_FISH, SKILL_TRAIT)
	if(new_level >= SKILL_LEVEL_JOURNEYMAN && old_level < SKILL_LEVEL_JOURNEYMAN)
		ADD_TRAIT(mind, TRAIT_EXAMINE_FISHING_SPOT, SKILL_TRAIT)
	if(new_level >= SKILL_LEVEL_MASTER && old_level < SKILL_LEVEL_MASTER)
		ADD_TRAIT(mind, TRAIT_REVEAL_FISH, SKILL_TRAIT)

/datum/skill/fishing/level_lost(datum/mind/mind, new_level, old_level, silent)
	. = ..()
	if(old_level >= SKILL_LEVEL_MASTER && new_level < SKILL_LEVEL_MASTER)
		REMOVE_TRAIT(mind, TRAIT_REVEAL_FISH, SKILL_TRAIT)
		UnregisterSignal(mind, COMSIG_MIND_TRANSFERRED)
		UnregisterSignal(mind.current, COMSIG_MOB_BEGIN_FISHING)
		var/datum/fishing_challenge/challenge = GLOB.fishing_challenges_by_user[mind.current]
		if (challenge)
			UnregisterSignal(challenge, COMSIG_FISHING_CHALLENGE_GET_DIFFICULTY)
	if(old_level >= SKILL_LEVEL_JOURNEYMAN && new_level < SKILL_LEVEL_JOURNEYMAN)
		REMOVE_TRAIT(mind, TRAIT_EXAMINE_FISHING_SPOT, SKILL_TRAIT)
	if(old_level >= SKILL_LEVEL_APPRENTICE && new_level < SKILL_LEVEL_APPRENTICE)
		REMOVE_TRAIT(mind, TRAIT_EXAMINE_DEEPER_FISH, SKILL_TRAIT)
	if(old_level >= SKILL_LEVEL_NOVICE && new_level < SKILL_LEVEL_NOVICE)
		REMOVE_TRAIT(mind, TRAIT_EXAMINE_FISH, SKILL_TRAIT)

/datum/skill/fishing/proc/transfer_mind(datum/mind/source, mob/old_current)
	SIGNAL_HANDLER
	UnregisterSignal(old_current, COMSIG_MOB_BEGIN_FISHING)
	var/datum/fishing_challenge/challenge = GLOB.fishing_challenges_by_user[old_current]
	if (challenge)
		UnregisterSignal(challenge, COMSIG_FISHING_CHALLENGE_GET_DIFFICULTY)
	RegisterSignal(source.current, COMSIG_MOB_BEGIN_FISHING, PROC_REF(on_minigame_started))

/datum/skill/fishing/proc/on_minigame_started(mob/living/source, datum/fishing_challenge/challenge)
	SIGNAL_HANDLER
	RegisterSignal(challenge, COMSIG_FISHING_CHALLENGE_GET_DIFFICULTY, PROC_REF(adjust_difficulty), TRUE)

/datum/skill/fishing/proc/adjust_difficulty(datum/fishing_challenge/challenge, reward_path, obj/item/fishing_rod/rod, mob/living/user, list/holder)
	SIGNAL_HANDLER
	holder[1] -= 2 * (user.mind?.get_skill_level(type) - 1)
