/mob/living/simple_animal/hostile/jungle/bat //These are constantly healing while attacking you in swarms, dangerous guys. If you want to kill them, you'll have to use high-damage weapons so you kill them before they regenerate.
	name = "cave bat"
	desc = "Some rare species of bats are known to attack their targets in large numbers and suck their blood afterwards. This is one of them."
	icon_state = "bat"
	icon_living = "bat"
	icon_dead = "bat_dead"
	icon_gib = "bat_dead"
	turns_per_move = 2
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

/mob/living/simple_animal/hostile/jungle/bat/Initialize()
	. = ..()
	AddElement(/datum/element/simple_flying)
	AddComponent(/datum/component/swarming)
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

/mob/living/simple_animal/hostile/jungle/bat/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/projectile/destabilizer))
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
		new /mob/living/simple_animal/hostile/jungle/bat(get_turf(src))

	for(var/turf/open/T in range(1, src))
		if(prob(15))
			new /mob/living/simple_animal/hostile/jungle/bat(T)

	return INITIALIZE_HINT_QDEL

/obj/item/crusher_trophy/bat_wing //Basically an alternative version of demon claws that requires you to detonate your mark first and doesn't give x5 effect on mark detonation, but you get more healing and also regenerate your blood.
	name = "cave bat wing"
	desc = "A wing of some bat. Suitable as a trophy for a kinetic crusher."
	icon_state = "bat_wing"
	denied_type = /obj/item/crusher_trophy/bat_wing

/obj/item/crusher_trophy/bat_wing/effect_desc()
	return "mark detonation to apply a bloody mark to the target. For each hit you land at the marked creature will regenerate some of your health and blood"

/obj/item/crusher_trophy/bat_wing/on_mark_detonation(mob/living/target, mob/living/user)
	target.apply_status_effect(STATUS_EFFECT_BLOODYMARK)

/obj/item/crusher_trophy/bat_wing/on_melee_hit(mob/living/target, mob/living/user)
	if(target.has_status_effect(STATUS_EFFECT_BLOODYMARK))
		user.heal_ordered_damage(2, list(BRUTE, BURN, OXY))
		if(iscarbon(user))
			var/mob/living/carbon/carbie = user
			carbie.blood_volume += carbie.blood_volume >= BLOOD_VOLUME_NORMAL ? 0 : 10
