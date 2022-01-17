/**
 * Jungle megafauna has one specific feature: When killed, they drop loot for each person that killed them
 * Loot is divided into 3 categories: Unique(only 1 drop), rare(1 drop per X people, if less then X drops 1) and common(drops for every gamer)
 * This system is made to motivate miners to cooperate and kill hard bosses together.
 * Why? Because dying together is more fun than dying alone!
 */

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

	var/static/list/king_awards = list(/datum/award/achievement/boss/spider_queen_kill, /datum/award/achievement/boss/mud_worm_kill, \
									   /datum/award/achievement/boss/demonic_miner_kill, /datum/award/achievement/boss/vine_kraken_kill, \
									   /datum/award/achievement/boss/time_crystal_kill, /datum/award/achievement/boss/bluespace_spirit_kill, \
									   /datum/award/achievement/boss/ancient_ai_kill) // Awards you need to have to get a jungle king award

	var/list/initial_damage_coeff

/mob/living/simple_animal/hostile/megafauna/jungle/Life(delta_time, times_fired)
	. = ..()
	for(var/former_target in former_targets)
		if(get_dist(former_target, src) > former_target_vision_range)
			former_targets.Remove(former_target)
			update_armor()

/mob/living/simple_animal/hostile/megafauna/jungle/grant_achievement(medaltype, scoretype, crusher_kill, list/grant_achievement = list())
	if(!achievement_type || (flags_1 & ADMIN_SPAWNED_1) || !SSachievements.achievements_enabled)
		return FALSE
	if(!grant_achievement.len)
		for(var/mob/living/former_target in former_targets)
			grant_achievement += former_target
	for(var/mob/living/cool_guy in grant_achievement)
		if(cool_guy.stat || !cool_guy.client)
			continue
		cool_guy?.mind.add_memory(MEMORY_MEGAFAUNA_KILL, list(DETAIL_PROTAGONIST = cool_guy, DETAIL_DEUTERAGONIST = src), STORY_VALUE_LEGENDARY, memory_flags = MEMORY_CHECK_BLIND_AND_DEAF)
		cool_guy.client.give_award(/datum/award/achievement/boss/boss_killer, cool_guy)
		cool_guy.client.give_award(achievement_type, cool_guy)
		if(crusher_kill && istype(cool_guy.get_active_held_item(), /obj/item/kinetic_crusher))
			cool_guy.client.give_award(crusher_achievement_type, cool_guy)
		cool_guy.client.give_award(/datum/award/score/boss_score, cool_guy)
		cool_guy.client.give_award(score_achievement_type, cool_guy)

		for(var/award_type in king_awards)
			if(!cool_guy.client.get_award_status(award_type))
				return TRUE

		if(!cool_guy.client.get_award_status(/datum/award/achievement/boss/jungle_king))
			cool_guy.client.give_award(/datum/award/achievement/boss/jungle_king, cool_guy)

	return TRUE

/mob/living/simple_animal/hostile/megafauna/jungle/proc/update_armor()
	var/enemies = 0
	for(var/mob/living/possible_enemy in range(aggro_vision_range, get_turf(src)))
		if((ishuman(possible_enemy) || possible_enemy.mind) && (possible_enemy in former_targets))
			enemies += 1

	if(enemies <= 0)
		return

	damage_coeff = initial_damage_coeff
	for(var/coeff in damage_coeff)
		damage_coeff[coeff] = damage_coeff[coeff] / enemies

/mob/living/simple_animal/hostile/megafauna/jungle/GiveTarget(new_target) //Even if you hit once, you'll count
	if(!new_target && LAZYLEN(former_targets))
		return GiveTarget(pick(former_targets))
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
	initial_damage_coeff = damage_coeff.Copy()
	ADD_TRAIT(src, TRAIT_NO_FLOATING_ANIM, INNATE_TRAIT)
