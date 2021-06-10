/mob/living/simple_animal/hostile/jungle/bat //These are constantly healing while attacking you in swarms, dangerous guys. If you want to kill them, you'll have to use high-damage weapons so you kill them before they regenerate.
	name = "cave bat"
	desc = "Some rare species of bats are known to attack their targets in large numbers and suck their blood afterwards. This is one of them."
	icon_state = "bat"
	icon_living = "bat"
	icon_dead = "bat_dead"
	icon_gib = "bat_dead"
	turns_per_move = 0
	move_to_delay = 0
	response_help_continuous = "brushes aside"
	response_help_simple = "brush aside"
	response_disarm_continuous = "flails at"
	response_disarm_simple = "flail at"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak_chance = 0
	maxHealth = 30
	health = 30
	see_in_dark = 10
	harm_intent_damage = 10
	melee_damage_lower = 10
	melee_damage_upper = 10
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

/mob/living/simple_animal/hostile/jungle/bat/Initialize()
	. = ..()
	AddElement(/datum/element/simple_flying)
	AddComponent(/datum/component/swarming)
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

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
			adjustBruteLoss(-10)
			L.blood_volume -= 5 //Not a lot, but they attack in swarms
			return

		maxHealth = min(maxHealth + 10, initial(maxHealth) * 2) //Full heal and +10 maxHP for the bat that secures the kill
		adjustBruteLoss(-maxHealth)
		L.blood_volume -= 40

/obj/effect/spawner/jungle/cave_bat_nest
	name = "cave bat nest spawner"
	icon = 'icons/mob/animal.dmi'
	icon_state = "bat"

/obj/effect/spawner/jungle/cave_bat_nest/Initialize()
	. = ..()
	for(var/i = 1 to rand(2, 3))
		new /mob/living/simple_animal/hostile/jungle/bat(get_turf(src))

	for(var/turf/open/T in range(1, src))
		if(prob(15))
			new /mob/living/simple_animal/hostile/jungle/bat(T)

	return INITIALIZE_HINT_QDEL
