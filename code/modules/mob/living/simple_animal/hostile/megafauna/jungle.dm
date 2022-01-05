/**
 * Jungle megafauna has one specific feature: When killed, they drop loot for each person that killed them
 * Loot is divided into 3 categories: Unique(only 1 drop), rare(1 drop per X people, if less then X drops 1) and common(drops for every gamer)
 * This system is made to motivate miners to cooperate and kill hard bosses together.
 * Why? Because dying together is more fun than dying alone!
 */

#define ARMOR_PER_ENEMY 0.15

/mob/living/simple_animal/hostile/megafauna/jungle
	faction = list("boss", "jungle")
	weather_immunities = list(TRAIT_ACID_IMMUNE)

	var/list/rare_loot = list()
	var/list/rare_crusher_loot = list()
	var/rarity = 1

	var/list/common_loot = list()
	var/list/common_crusher_loot = list()
	damage_coeff = list(BRUTE = 1, BURN = 0.5, TOX = 0.75, CLONE = 1, STAMINA = 0, OXY = 1)

	var/list/former_targets = list()
	var/former_target_vision_range = 18
	var/spawns_minions = FALSE
	crusher_damage_required = 0.3 //Because if you kill the boss with a team it won't really be super high if there's a PKA user

/mob/living/simple_animal/hostile/megafauna/jungle/Life(delta_time, times_fired)
	. = ..()
	for(var/former_target in former_targets)
		if(get_dist(former_target, src) > former_target_vision_range)
			former_targets.Remove(former_target)
			update_armor()

/mob/living/simple_animal/hostile/megafauna/jungle/proc/update_armor()
	var/enemies = 0
	for(var/mob/living/possible_enemy in range(aggro_vision_range, get_turf(src)))
		if((ishuman(possible_enemy) || possible_enemy.mind) && (possible_enemy in former_targets))
			enemies += 1

	enemies -= 1 //So we don't gain armor from a single guy

	if(enemies <= 1)
		return

	damage_coeff = initial(damage_coeff)
	for(var/coeff in damage_coeff)
		damage_coeff[coeff] = max(damage_coeff[coeff] - ARMOR_PER_ENEMY * enemies, 0.2)

/mob/living/simple_animal/hostile/megafauna/jungle/GiveTarget(new_target) //Even if you hit once, you'll count
	. = ..()
	if(!(new_target in former_targets))
		former_targets.Add(new_target)
		update_armor()

/mob/living/simple_animal/hostile/megafauna/jungle/CanAttack(atom/the_target)
	. = ..()
	if(robust_searching)
		if(isliving(the_target))
			var/mob/living/possible_corpse = the_target
			if(possible_corpse.stat == DEAD && (possible_corpse in former_targets))
				former_targets.Remove(possible_corpse)
				update_armor()

/mob/living/simple_animal/hostile/megafauna/jungle/loot_manipulation()
	. = ..()
	var/killers = 0
	for(var/mob/living/former_target in former_targets)
		if(former_target in range(aggro_vision_range, get_turf(src)))
			killers += 1

	var/datum/status_effect/crusher_damage/crusher_dmg = has_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
	var/crusher_kill = FALSE
	if(crusher_dmg && crusher_loot && crusher_dmg.total_damage >= maxHealth * crusher_damage_required)
		crusher_kill = TRUE

	var/rare_loot_amount = min(1, round(killers / rarity))
	var/rare_loot_list = (crusher_kill && LAZYLEN(rare_crusher_loot) ? rare_crusher_loot : rare_loot)
	for(var/i = 1 to rare_loot_amount)
		for(var/rare_looty in rare_loot_list)
			loot.Add(rare_looty)

	var/common_loot_list = (crusher_kill && LAZYLEN(common_crusher_loot) ? common_crusher_loot : common_loot)
	for(var/i = 1 to killers)
		for(var/common_looty in common_loot_list)
			loot.Add(common_looty)

/mob/living/simple_animal/hostile/megafauna/jungle/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NO_FLOATING_ANIM, INNATE_TRAIT)

#undef ARMOR_PER_ENEMY
