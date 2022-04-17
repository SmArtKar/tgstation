/mob/living/basic/slime
	name = "grey baby slime (123)"
	icon = 'icons/mob/slimes.dmi'
	icon_state = "grey"
	icon_living = "grey"
	icon_dead = "grey-dead"
	gender = NEUTER

	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "shoos"
	response_disarm_simple = "shoo"
	response_harm_continuous = "stomps on"
	response_harm_simple = "stomp on"
	speak_emote = list("blorbles")
	bubble_icon = "slime"
	initial_language_holder = /datum/language_holder/slime

	verb_say = "blorbles"
	verb_ask = "inquisitively blorbles"
	verb_exclaim = "loudly blorbles"
	verb_yell = "loudly blorbles"

	maxHealth = 150
	health = 150
	melee_damage_lower = 5
	melee_damage_upper = 25
	obj_damage = 5
	see_in_dark = 8
	attack_sound = 'sound/effects/blobattack.ogg'

	speed = 1
	faction = list("slime","neutral")
	hud_possible = list(HEALTH_HUD, STATUS_HUD, ANTAG_HUD, NUTRITION_HUD)
	pass_flags = PASSTABLE | PASSGRILLE
	status_flags = CANPUSH | CANUNCONSCIOUS

