/mob/living/simple_animal/hostile/jungle/snakeman
	name = "snakeman"
	desc = "A hostile primitive that looks like human and snake hybrid. It's wearing some light armor made out of jungle wood and wield a spear."
	icon_state = "snakeman"
	icon_living = "snakeman"
	icon_dead = "snakeman_dead"
	mob_biotypes = MOB_ORGANIC | MOB_REPTILE | MOB_HUMANOID
	speed = 1
	move_to_delay = 4
	butcher_results = list(/obj/item/food/meat/slab/xeno = 2, /obj/item/stack/sheet/bone = 2)
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/goliath_hide/snakeman_hide = 1)
	speak_emote = list("roars")
	maxHealth = 190
	health = 190
	melee_damage_lower = 20
	melee_damage_upper = 20
	attack_sound = 'sound/weapons/pierce_slow.ogg'
	response_harm_continuous = "impales"
	response_harm_simple = "impales"
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	ranged = TRUE
	ranged_cooldown_time = 6 SECONDS
	turns_per_move = 3
	footstep_type = FOOTSTEP_HARD_BAREFOOT
	crusher_loot = /obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs
	var/anger_state = FALSE

/mob/living/simple_animal/hostile/jungle/snakeman/OpenFire()
	if(anger_state) //Somehow
		return

	enter_anger()

/mob/living/simple_animal/hostile/jungle/snakeman/proc/enter_anger()
	add_atom_colour("#FF0000", FIXED_COLOUR_PRIORITY)
	visible_message("<span class='danger'>[src] roars, their skin turning red!</span>")
	add_movespeed_modifier(/datum/movespeed_modifier/slaughter)
	anger_state = TRUE
	damage_coeff = list(BRUTE = 2, BURN = 2, TOX = 2, CLONE = 2, STAMINA = 0, OXY = 2)
	addtimer(CALLBACK(src, .proc/exit_anger), 2 SECONDS)

/mob/living/simple_animal/hostile/jungle/snakeman/proc/exit_anger()
	visible_message("<span class='notice'>[src]'s skin slowly turns back to normal color.</span>")
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
	remove_movespeed_modifier(/datum/movespeed_modifier/slaughter)
	anger_state = FALSE
	remove_atom_colour(FIXED_COLOUR_PRIORITY)

/mob/living/simple_animal/hostile/jungle/snakeman/Move()
	if(anger_state)
		var/obj/effect/temp_visual/snakeman_dash/dash = new(get_turf(src))
		dash.dir = dir
	. = ..()

/obj/effect/temp_visual/snakeman_dash
	name = "snakeman dash"
	icon = 'icons/mob/animal.dmi'
	icon_state = "snakeman"
	duration = 5

/obj/effect/temp_visual/snakeman_dash/Initialize()
	. = ..()
	START_PROCESSING(SSfastprocess, src)

/obj/effect/temp_visual/snakeman_dash/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	. = ..()

/obj/effect/temp_visual/snakeman_dash/process()
	alpha -= 50

/obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs
	name = "adrenaline sacs"
	desc = "Sliced-off adrenaline sacs. Suitable as a trophy for a kinetic crusher."
	icon_state = "adrenaline_sacs"
	denied_type = /obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs
