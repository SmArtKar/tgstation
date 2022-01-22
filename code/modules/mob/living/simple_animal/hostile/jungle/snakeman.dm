/mob/living/simple_animal/hostile/jungle/snakeman
	name = "snakeman"
	desc = "A hostile primitive that looks like human and snake hybrid. It's wearing some light armor made out of jungle wood and wield a spear."
	icon = 'icons/mob/jungle/jungle_monsters.dmi'
	icon_state = "snakeman"
	icon_living = "snakeman"
	icon_dead = "snakeman_dead"
	mob_biotypes = MOB_ORGANIC | MOB_REPTILE | MOB_HUMANOID
	speed = 8
	move_to_delay = 8
	butcher_results = list(/obj/item/food/meat/slab/xeno = 2, /obj/item/stack/sheet/bone = 2)
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/goliath_hide/snakeman_hide = 1)
	speak_emote = list("roars")
	maxHealth = 480 //240 in anger
	health = 480
	melee_damage_lower = 20
	melee_damage_upper = 20
	attack_sound = 'sound/weapons/pierce_slow.ogg'
	response_harm_continuous = "impales"
	response_harm_simple = "impale"
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	ranged = TRUE
	ranged_cooldown_time = 8 SECONDS
	turns_per_move = 3
	footstep_type = FOOTSTEP_HARD_BAREFOOT
	crusher_loot = /obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs
	var/anger_state = FALSE

/mob/living/simple_animal/hostile/jungle/snakeman/alpha
	name = "alpha snakeman"
	desc = "A snow-white snakeman with an axe in it's hands, this one is clearly leader of one of their tribes."
	icon_state = "snakeman_leader"
	icon_living = "snakeman_leader"
	icon_dead = "snakeman_leader_dead"

	response_harm_continuous = "cleaves"
	response_harm_simple = "cleaves"
	speed = 10
	move_to_delay = 10
	ranged_cooldown_time = 3 SECONDS

	maxHealth = 560 //280 in anger
	health = 560
	melee_damage_lower = 25
	melee_damage_upper = 25
	attack_sound = 'sound/weapons/bladeslice.ogg'
	crusher_loot = /obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs/alpha

	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/goliath_hide/snakeman_hide = 3)

/mob/living/simple_animal/hostile/jungle/snakeman/alpha/OpenFire()
	if(anger_state || prob(65))
		axe_smack()
		return

	enter_anger()

/mob/living/simple_animal/hostile/jungle/snakeman/alpha/proc/axe_smack()
	playsound(get_turf(src), 'sound/effects/meteorimpact.ogg', 50, TRUE)
	visible_message("<span class='boldwarning'>[src] smashes it's axe into the ground!</span>")
	SLEEP_CHECK_DEATH(1, src)
	var/target_turf = get_turf(target)
	var/end_turf = get_ranged_target_turf_direct(src, target_turf, 40, 0)
	var/turf_line = get_line(get_turf(src), end_turf) - get_turf(src)
	var/list/hit_things = list()
	for(var/turf/targeting_turf in turf_line)
		if(isclosedturf(targeting_turf))
			return
		new /obj/effect/temp_visual/small_smoke/halfsecond(targeting_turf)
		for(var/mob/living/victim in targeting_turf.contents)
			if(victim != src && !(victim in hit_things) && !faction_check(victim.faction, faction))
				var/throwtarget = get_edge_target_turf(targeting_turf, get_dir(targeting_turf, victim))
				victim.throw_at(throwtarget, 4, 1, src)
				victim.apply_damage_type(15, BRUTE)
				hit_things += victim
		SLEEP_CHECK_DEATH(1, src)

/mob/living/simple_animal/hostile/jungle/snakeman/OpenFire()
	if(anger_state) //Somehow
		return

	enter_anger()

/mob/living/simple_animal/hostile/jungle/snakeman/proc/enter_anger()
	add_atom_colour("#FF0000", FIXED_COLOUR_PRIORITY)
	visible_message("<span class='danger'>[src] roars, their skin turning red!</span>")
	speed = 4
	move_to_delay = 4
	anger_state = TRUE
	damage_coeff = list(BRUTE = 2, BURN = 2, TOX = 2, CLONE = 2, STAMINA = 0, OXY = 2)
	addtimer(CALLBACK(src, .proc/exit_anger), 2 SECONDS)

/mob/living/simple_animal/hostile/jungle/snakeman/proc/exit_anger()
	visible_message("<span class='notice'>[src]'s skin slowly turns back to normal color.</span>")
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
	speed = initial(speed)
	move_to_delay = initial(move_to_delay)
	anger_state = FALSE
	remove_atom_colour(FIXED_COLOUR_PRIORITY)

/mob/living/simple_animal/hostile/jungle/snakeman/Move()
	if(anger_state)
		new /obj/effect/temp_visual/decoy/fading/halfsecond(get_turf(src), src)
	. = ..()

/obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs
	name = "adrenaline sacs"
	desc = "Sliced-off adrenaline sacs. Suitable as a trophy for a kinetic crusher."
	icon_state = "adrenaline_sacs"
	denied_type = /obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs

/obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs/alpha
	name = "purple adrenaline sacs"
	desc = "Purple adrenaline sacs sliced off from an alpha snakeman. Suitable as a trophy for a kinetic crusher."
	icon_state = "purple_adrenaline_sacs"
	bonus_value = 4

/mob/living/simple_animal/hostile/jungle/snakeman/random/Initialize()
	. = ..()
	if(prob(3))
		new /mob/living/simple_animal/hostile/jungle/snakeman/alpha(loc)
		return INITIALIZE_HINT_QDEL
