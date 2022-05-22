/mob/living/simple_animal/hostile/slime_blorbie
	name = "slime blorbie"
	desc = "A small piece of silver-colored living slime."
	icon = 'icons/mob/slimes.dmi'
	icon_state = "silver-blorbie"
	icon_living = "silver-blorbie"
	icon_dead = "silver-blorbie"
	icon_gib = "silver-blorbie"
	speak_chance = 0
	turns_per_move = 5
	speed = 2
	response_help_continuous = "brushes"
	response_help_simple = "brush"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "push"
	faction = list("hostile", "slime")
	maxHealth = 10
	health = 10
	mob_size = MOB_SIZE_TINY
	density = FALSE
	initial_language_holder = /datum/language_holder/slime

	melee_damage_lower = 3
	melee_damage_upper = 3
	attack_verb_continuous = "glomps"
	attack_verb_simple = "glomps"
	attack_sound = 'sound/misc/splort.ogg'

	attack_vis_effect = ATTACK_EFFECT_PUNCH
	speak_emote = list("blorbles")
	bubble_icon = "slime"

	deathmessage = "deflates into a small puddle of silver slime."
	del_on_death = 1

/mob/living/simple_animal/hostile/slime_blorbie/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
	AddComponent(/datum/component/clickbox, x_offset = -2, y_offset = -2)
	AddComponent(/datum/component/swarming)
	RegisterSignal(src, COMSIG_LIVING_APPLY_WATER, .proc/apply_water)

/mob/living/simple_animal/hostile/slime_blorbie/Destroy()
	UnregisterSignal(src, COMSIG_LIVING_APPLY_WATER)
	return ..()

/mob/living/simple_animal/hostile/slime_blorbie/proc/apply_water(datum/source)
	SIGNAL_HANDLER
	adjustBruteLoss(10) //Instant death on water

/mob/living/simple_animal/hostile/slime_blorbie/adjustFireLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced)
		amount = -abs(amount)
	return ..() //Heals them

/mob/living/simple_animal/hostile/slime_blorbie/bullet_act(obj/projectile/Proj, def_zone, piercing_hit = FALSE)
	if((Proj.damage_type == BURN))
		adjustBruteLoss(-abs(Proj.damage)) //fire projectiles heals slimes.
		Proj.on_hit(src, 0, piercing_hit)
	else
		. = ..(Proj)
	. = . || BULLET_ACT_BLOCK

/mob/living/simple_animal/hostile/slime_blorbie/player
	AIStatus = AI_OFF
	stop_automated_movement = TRUE
	icon_state = "silver-blorbie-eye"
	icon_living = "silver-blorbie-eye"
	icon_dead = "silver-blorbie-eye"
	icon_gib = "silver-blorbie-eye"
