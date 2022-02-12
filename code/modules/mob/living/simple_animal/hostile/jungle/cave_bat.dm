/mob/living/simple_animal/hostile/jungle/bat //These are constantly healing while attacking you in swarms, dangerous guys.
	name = "cave bat"
	desc = "Some rare species of bats are known to attack their targets in large numbers and drink their blood afterwards."
	icon_state = "bat"
	icon_living = "bat"
	icon_dead = "bat_dead"
	icon_gib = "bat_dead"
	speed = 2
	move_to_delay = 2
	response_help_continuous = "brushes aside"
	response_help_simple = "brush aside"
	response_disarm_continuous = "flails at"
	response_disarm_simple = "flail at"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak_chance = 0
	maxHealth = 10
	health = 10
	see_in_dark = 10
	harm_intent_damage = 5
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	butcher_results = list(/obj/item/food/meat/slab = 1)
	pass_flags = PASSTABLE
	density = FALSE
	faction = list("jungle")
	attack_sound = 'sound/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	mob_size = MOB_SIZE_TINY
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	speak_emote = list("squeaks")
	crusher_drop_mod = 5 //They spawn in large amounts, up to 11 in a pack.
	crusher_loot = /obj/item/crusher_trophy/bat_wing
	butcher_results = list(/obj/item/food/meat/slab = 1, /obj/item/stack/sheet/sinew/bat = 1, /obj/item/stack/sheet/bone = 1)
	move_resist = MOVE_RESIST_DEFAULT
	move_force = MOVE_FORCE_DEFAULT
	pull_force = PULL_FORCE_DEFAULT
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)

/mob/living/simple_animal/hostile/jungle/bat/Initialize()
	. = ..()
	AddElement(/datum/element/simple_flying)
	AddComponent(/datum/component/swarming)
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

/mob/living/simple_animal/hostile/jungle/bat/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/projectile)) //Else it's pixelhunting hell to fight them
		return FALSE

/mob/living/simple_animal/hostile/jungle/bat/albino
	name = "albino cave bat"
	desc = "A rare variant of cave bat that's colored pure white."
	icon_state = "bat_white"
	icon_living = "bat_white"
	icon_dead = "bat_white_dead"
	icon_gib = "bat_white_dead"
	crusher_drop_mod = 30
	crusher_loot = /obj/item/crusher_trophy/white_bat_wing
	var/list/friend_beams = list()

/mob/living/simple_animal/hostile/jungle/bat/albino/Life(delta_time, times_fired)
	. = ..()
	for(var/mob/living/simple_animal/friend in friend_beams)
		if(get_dist(src, friend) > 5 || friend.stat == DEAD)
			qdel(friend_beams[friend])
			friend.damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
			friend_beams -= friend
		else
			friend.adjustBruteLoss(-1) //Heals all other bats around it and gives them armor, forcing player to kill it first

	for(var/mob/living/simple_animal/hostile/jungle/bat/friend in range(5, src))
		if(!(friend in friend_beams) && friend != src)
			friend.damage_coeff = list(BRUTE = 0.1, BURN = 0.1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
			friend_beams[friend] = Beam(friend, icon_state = "blood_mid_light")

/mob/living/simple_animal/hostile/jungle/bat/albino/death(gibbed)
	for(var/mob/living/simple_animal/friend in friend_beams)
		qdel(friend_beams[friend])
		friend.damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
	. = ..()

/mob/living/simple_animal/hostile/jungle/bat/random/Initialize()
	. = ..()
	if(prob(1))
		new /mob/living/simple_animal/hostile/jungle/bat/albino(loc)
		return INITIALIZE_HINT_QDEL

/mob/living/simple_animal/hostile/jungle/bat/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/projectile/destabilizer))
		return FALSE
	if(istype(mover, /obj/projectile/kinetic))
		return FALSE

/mob/living/simple_animal/hostile/jungle/bat/AttackingTarget()
	. = ..()

	if(. && isliving(target))
		var/mob/living/L = target

		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(NOBLOOD in H.dna.species.species_traits)
				return

		if(L.blood_volume <= 0 || HAS_TRAIT(L, TRAIT_NOBLEED) || HAS_TRAIT(L, TRAIT_HUSK))
			return

		if(L.stat != DEAD)
			maxHealth = min(maxHealth + 1, initial(maxHealth) * 2) //These can stack their max HP up to x2. With each victim they become more powerful
			adjustBruteLoss(-2)
			L.blood_volume -= 5 //Not a lot, but they attack in swarms
			return

		maxHealth = min(maxHealth + 5, initial(maxHealth) * 2) //Full heal and +10 maxHP for the bat that secures the kill
		adjustBruteLoss(-maxHealth)
		L.blood_volume -= 40

/obj/effect/spawner/jungle/cave_bat_nest
	name = "cave bat nest spawner"
	icon = 'icons/mob/animal.dmi'
	icon_state = "bat"

/obj/effect/spawner/jungle/cave_bat_nest/Initialize()
	. = ..()
	for(var/i = 1 to rand(2, 3))
		new /mob/living/simple_animal/hostile/jungle/bat/random(get_turf(src))

	for(var/turf/open/T in range(1, src))
		if(prob(15))
			new /mob/living/simple_animal/hostile/jungle/bat/random(T)

	return INITIALIZE_HINT_QDEL
