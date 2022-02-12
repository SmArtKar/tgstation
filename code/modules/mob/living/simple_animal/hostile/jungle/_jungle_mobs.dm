/mob/living/simple_animal/hostile/jungle
	vision_range = 4
	aggro_vision_range = 8
	atmos_requirements = list("min_oxy" = 3, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	faction = list("jungle")
	obj_damage = 30
	environment_smash = ENVIRONMENT_SMASH_WALLS
	minbodytemp = 0
	maxbodytemp = 450
	response_harm_continuous = "strikes"
	response_harm_simple = "strike"
	status_flags = NONE
	combat_mode = TRUE
	see_in_dark = 4
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	mob_size = MOB_SIZE_LARGE
	weather_immunities = list(TRAIT_ACID_IMMUNE)

	var/crusher_loot
	var/crusher_drop_mod = 25
	var/throw_message = "bounces off of"

/mob/living/simple_animal/hostile/jungle/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_CRUSHER_VUNERABLE, INNATE_TRAIT)

/mob/living/simple_animal/hostile/jungle/bullet_act(obj/projectile/P)//Reduces damage from laser projectiles to curb off-screen kills. If some rogue miner brings them to the station they still can be killed with shotguns and WTs
	if(!stat)
		Aggro()

	if(P.damage < 30 && P.damage_type != BRUTE)
		P.damage = (P.damage / 3)
		visible_message("<span class='danger'>[P] has a reduced effect on [src]!</span>")
	. = ..()

/mob/living/simple_animal/hostile/jungle/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum) //No floor tiling them to death, wiseguy
	if(istype(AM, /obj/item))
		var/obj/item/T = AM
		if(!stat)
			Aggro()
		if(T.throwforce <= 20)
			visible_message("<span class='notice'>The [T.name] [throw_message] [src.name]!</span>")
			return
	. = ..()

/mob/living/simple_animal/hostile/jungle/death(gibbed)
	SSblackbox.record_feedback("tally", "mobs_killed_mining", 1, type)
	var/datum/status_effect/crusher_damage/C = has_status_effect(/datum/status_effect/crusher_damage)
	if(C && crusher_loot && prob((C.total_damage/maxHealth) * crusher_drop_mod)) //on average, you'll need to kill 4 creatures before getting the item
		spawn_crusher_loot()
	..(gibbed)

/mob/living/simple_animal/hostile/jungle/proc/spawn_crusher_loot()
	if(butcher_results && LAZYLEN(butcher_results))
		butcher_results[crusher_loot] = 1
	else
		loot[crusher_loot] = 1

/obj/effect/spawner/jungle/cave_mob_spawner
	name = "cave mob spawner"
	var/land_mobs = list(/obj/effect/spawner/jungle/cave_spider_nest = 300, /obj/effect/spawner/jungle/cave_bat_nest = 500, /mob/living/simple_animal/hostile/jungle/snakeman/random = 400, /mob/living/simple_animal/hostile/giant_spider/hunter/scrawny/jungle = 100, /mob/living/simple_animal/hostile/giant_spider/tarantula/scrawny/jungle = 50, /mob/living/simple_animal/hostile/jungle/mega_arachnid = 100, \
	/obj/structure/spawner/jungle = 10, /obj/structure/spawner/jungle/bat = 10, /obj/structure/spawner/jungle/mega_arachnid = 2, /obj/structure/spawner/jungle/snakeman = 8, /obj/structure/spawner/jungle/spider_big = 6, SPAWN_MEGAFAUNA = 22)
	var/megafauna = list(/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal = 1, /mob/living/simple_animal/hostile/megafauna/jungle/spider_queen = 2, /mob/living/simple_animal/hostile/megafauna/jungle/mud_worm = 2)
	var/water_mobs = list(/mob/living/simple_animal/hostile/retaliate/snake/jungle = 3, /mob/living/simple_animal/hostile/retaliate/frog/jungle = 2)

/obj/effect/spawner/jungle/cave_mob_spawner/Initialize()
	. = ..()
	if(istype(get_turf(src), /turf/open/water/jungle))
		if(LAZYLEN(water_mobs))
			var/spawn_type = pick_weight(water_mobs)
			new spawn_type(get_turf(src))
		return INITIALIZE_HINT_QDEL

	if(LAZYLEN(land_mobs))
		var/spawn_type = pick_weight(land_mobs)
		if(spawn_type == SPAWN_MEGAFAUNA)
			spawn_type = pick_weight(megafauna)
		new spawn_type(get_turf(src))
	return INITIALIZE_HINT_QDEL
