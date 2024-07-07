#define SLIME_EXTRA_SHOCK_COST 3
#define SLIME_EXTRA_SHOCK_THRESHOLD 8
#define SLIME_BASE_SHOCK_PERCENTAGE 10
#define SLIME_SHOCK_PERCENTAGE_PER_LEVEL 7

/mob/living/basic/slime
	name = "grey baby slime (123)"
	icon = 'icons/mob/simple/slimes.dmi'
	icon_state = "grey-baby"
	pass_flags = PASSTABLE | PASSGRILLE | PASSFLAPS
	gender = NEUTER
	faction = list(FACTION_SLIME)

	icon_living = "grey-baby"
	icon_dead = "grey-baby-dead"

	attack_sound = 'sound/weapons/bite.ogg'

	//Base physiology

	maxHealth = 150
	health = 150
	mob_biotypes = MOB_SLIME
	melee_damage_lower = 5
	melee_damage_upper = 25
	wound_bonus = -45
	can_buckle_to = FALSE

	damage_coeff = list(BRUTE = 1, BURN = -1, TOX = 1, STAMINA = 0, OXY = 1) //Healed by fire
	unsuitable_cold_damage = 15
	unsuitable_heat_damage = 0
	maximum_survivable_temperature = INFINITY
	habitable_atmos = null

	//Messages

	attack_verb_simple = "glomp"
	attack_verb_continuous = "glomps"

	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "shoos"
	response_disarm_simple = "shoo"
	response_harm_continuous = "stomps on"
	response_harm_simple = "stomp on"

	//Speech

	speak_emote = list("blorbles")
	bubble_icon = "slime"
	initial_language_holder = /datum/language_holder/slime

	verb_say = "blorbles"
	verb_ask = "inquisitively blorbles"
	verb_exclaim = "loudly blorbles"
	verb_yell = "loudly blorbles"

	/// Slime's current nutrition, (0 ~ 100), default 25
	nutrition = SLIME_STARTING_NUTRITION
	/// Slime's current happiness, (0 ~ 100), default 20
	var/happiness = SLIME_STARTING_HAPPINESS
	/// How many cores the slime currently holds. Cores can be picked out by hand
	var/slime_cores = 0
	/// Progress to the next core forming
	var/core_progress = 0
	/// Current amount of charge the slime has
	/// Whenever a slime is "stabilized" which freezes its hunger and conditions
	var/stabilized = FALSE
	/// Slime's shape. Changes if slime overeats or has too many cores
	var/current_shape = SLIME_SHAPE_NORMAL
	/// Slime's current displayed emotion
	var/current_mood = SLIME_MOOD_NONE

	/// The datum that handles the slime appearance, behavior, core and special abilities
	var/datum/slime_type/slime_type

	// AI related traits
	/// AI controller
	ai_controller = /datum/ai_controller/basic_controller/slime
	/// Instructions you can give to slimes
	var/static/list/pet_commands = list(
		/datum/pet_command/idle,
		/datum/pet_command/free,
		/datum/pet_command/follow,
		/datum/pet_command/point_targeting/attack/slime,
	)

/mob/living/basic/slime/Initialize(mapload, new_type = /datum/slime_type/grey)
	. = ..()

	AddComponent(/datum/component/health_scaling_effects, min_health_slowdown = 2)
	AddComponent(/datum/component/obeys_commands, pet_commands)

	AddElement(/datum/element/ai_retaliate)
	AddElement(/datum/element/basic_health_examine, light_damage_message = "It has some punctures in its flesh!", heavy_damage_message = span_bold("It has severe punctures and tears in its flesh!"), heavy_threshold = 0.4)
	AddElement(/datum/element/footstep, footstep_type = FOOTSTEP_MOB_SLIME)
	AddElement(/datum/element/soft_landing)
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_SLIME, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 5)

	add_traits(list(TRAIT_CANT_RIDE, TRAIT_VENTCRAWLER_ALWAYS), INNATE_TRAIT)

	RegisterSignal(src, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, PROC_REF(on_slime_pre_attack))
	RegisterSignal(src, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_attack_hand))

/*
 *   Information and visuals
 */

/mob/living/basic/slime/update_name()
	var/static/regex/slime_name_regex = new("\\w+ slime \\(\\d+\\)")
	if(slime_name_regex.Find(name))
		var/slime_id = rand(1, 1000)
		name = "[slime_type.color] slime ([slime_id])"
		real_name = name
	return ..()

/mob/living/basic/slime/regenerate_icons()
	cut_overlays()
	icon_state = "[slime_type.color][current_shape == SLIME_SHAPE_OBESE ? "-fat" : ""]"
	icon_dead = "[icon_state]-dead"

	if (stat == DEAD)
		icon_state = icon_dead
		return ..()

	if (current_mood != SLIME_MOOD_NONE)
		add_overlay("emote-[current_mood]")

	return ..()

/mob/living/basic/slime/get_status_tab_items()
	. = ..()

	if (stabilized)
		return

	. += "Nutrition: [nutrition]/[SLIME_MAX_NUTRITION]"
	. += "Happiness: [happiness]/[SLIME_MAX_HAPPINESS]"

/mob/living/basic/slime/get_mob_buckling_height(mob/seat)
	. = ..()
	if(. != 0)
		return 3

/mob/living/basic/slime/resist_buckle()
	if(isliving(buckled))
		buckled.unbuckle_mob(src, force=TRUE)
		return
	return ..()

/mob/living/basic/slime/examine(mob/user)
	. = ..()
	if (current_shape == SLIME_SHAPE_OBESE)
		if (nutrition == SLIME_MAX_NUTRITION) // yeah don't
			. += span_warning("It's morbidly obese[happiness == 0 ? " and begging for the sweet release of death" : ""].")
		else
			. += "It's looking pretty fat[slime_cores >= SLIME_CORES_FAT ? ", full of cores ready to be harvested" : ""]."

/// Handles slime attacking restrictions, and any extra effects that would trigger
/mob/living/basic/slime/proc/on_slime_pre_attack(mob/living/basic/slime/our_slime, atom/target, proximity, modifiers)
	SIGNAL_HANDLER

	if(LAZYACCESS(modifiers, RIGHT_CLICK) && isliving(target) && target != src && usr == src)
		if(our_slime.can_feed_on(target))
			our_slime.start_feeding(target)
		return COMPONENT_HOSTILE_NO_ATTACK

	// The AI is not tasty!
	if(isAI(target))
		target.balloon_alert(our_slime, "not tasty!")
		return COMPONENT_HOSTILE_NO_ATTACK

	// If you try to attack the creature you are latched on, you instead cancel feeding
	if(our_slime.buckled == target)
		our_slime.stop_feeding()
		return COMPONENT_HOSTILE_NO_ATTACK

	if (iscyborg(target))
		var/mob/living/silicon/robot/borg = target
		borg.flash_act()
		do_sparks(5, TRUE, borg)
		our_slime.do_attack_animation(borg)
		borg.visible_message(span_danger("[our_slime] fails to hurt [borg]!"), span_userdanger("[our_slime] failed to hurt you!"))
		return COMPONENT_HOSTILE_NO_ATTACK


