/datum/map_generator/cave_generator/jungle
	open_turf_types =  list(/turf/open/floor/plating/dirt/jungle = 1)
	closed_turf_types =  list(/turf/closed/mineral/random/jungle = 1)

	mob_spawn_list = list(/obj/effect/spawner/jungle/cave_mob_spawner = 1) //We use a single spawner so it can separate water and land mobs
	//megafauna_spawn_list = list()
	flora_spawn_list = list(/obj/structure/flora/rock = 2, /obj/structure/flora/rock/pile = 4, /obj/structure/flora/grass/jungle/b = 2, /obj/structure/flora/rock/jungle = 1)
	//feature_spawn_list = list()

	flora_spawn_chance = 4
	mob_spawn_chance = 6

	var/special_turfs = list(/turf/open/floor/plating/grass/jungle = 2, /turf/open/floor/plating/grass/jungle/green = 1, /turf/open/floor/plating/dirt/jungle/wasteland = 1)
	var/special_turf_chance = 0 //Currently set to 0, maybe if somebody makes it look good we can use it.

/datum/map_generator/cave_generator/jungle/generate_terrain(list/turfs)
	var/start_time = REALTIMEOFDAY
	string_gen = rustg_cnoise_generate("[initial_closed_chance]", "[smoothing_iterations]", "[birth_limit]", "[death_limit]", "[world.maxx]", "[world.maxy]") //Generate the raw CA data

	var/list/special_gen_turfs = list()

	for(var/i in turfs)
		var/turf/gen_turf = i

		var/area/A = gen_turf.loc
		if(!(A.area_flags & CAVES_ALLOWED))
			continue

		var/closed = text2num(string_gen[world.maxx * (gen_turf.y - 1) + gen_turf.x])

		var/stored_flags
		if(gen_turf.turf_flags & NO_RUINS)
			stored_flags |= NO_RUINS

		var/turf/new_turf = pick_weight(closed ? closed_turf_types : open_turf_types)

		new_turf = gen_turf.ChangeTurf(new_turf, initial(new_turf.baseturfs), CHANGETURF_DEFER_CHANGE)

		new_turf.flags_1 |= stored_flags

		if(!closed)
			var/turf/open/new_open_turf = new_turf

			//FLORA SPAWNING HERE
			var/atom/spawned_flora
			if(flora_spawn_list && prob(flora_spawn_chance))
				var/can_spawn = TRUE

				if(!(A.area_flags & FLORA_ALLOWED))
					can_spawn = FALSE
				if(can_spawn)
					spawned_flora = pick_weight(flora_spawn_list)
					spawned_flora = new spawned_flora(new_open_turf)

			//FEATURE SPAWNING HERE
			var/atom/spawned_feature
			if(feature_spawn_list && prob(feature_spawn_chance))
				var/can_spawn = TRUE

				if(!(A.area_flags & FLORA_ALLOWED))
					can_spawn = FALSE

				var/atom/picked_feature = pick_weight(feature_spawn_list)

				for(var/obj/structure/F in range(7, new_open_turf))
					if(istype(F, picked_feature))
						can_spawn = FALSE

				if(istype(new_open_turf, /turf/open/water/jungle))
					can_spawn = FALSE

				if(can_spawn)
					spawned_feature = new picked_feature(new_open_turf)

			if(prob(special_turf_chance))
				special_gen_turfs[new_open_turf] = pick_weight(special_turfs)

			//MOB SPAWNING HERE

			if(mob_spawn_list && !spawned_flora && !spawned_feature && prob(mob_spawn_chance))
				var/can_spawn = TRUE

				if(!(A.area_flags & MOB_SPAWN_ALLOWED))
					can_spawn = FALSE

				var/atom/picked_mob = pick_weight(mob_spawn_list)

				if(picked_mob == SPAWN_MEGAFAUNA)
					if((A.area_flags & MEGAFAUNA_SPAWN_ALLOWED) && megafauna_spawn_list?.len)
						picked_mob = pick_weight(megafauna_spawn_list)
					else
						picked_mob = pick_weight(mob_spawn_list - SPAWN_MEGAFAUNA)

				for(var/thing in urange(12, new_open_turf))
					if(!ishostile(thing) && !istype(thing, /obj/effect/spawner))
						continue

					if((ispath(picked_mob, /mob/living/simple_animal/hostile/megafauna) || ismegafauna(thing)) && get_dist(new_open_turf, thing) <= 7)
						can_spawn = FALSE
						break

					if((ispath(picked_mob, /mob/living/simple_animal/hostile) && !ispath(picked_mob, /mob/living/simple_animal/hostile/megafauna)) || (istype(thing, /mob/living/simple_animal/hostile) && !ismegafauna(thing)))
						can_spawn = FALSE
						break

					if((ispath(picked_mob, /obj/effect/spawner/jungle) || istype(thing, /obj/effect/spawner/jungle)) && get_dist(new_open_turf, thing) <= 5)
						can_spawn = FALSE
						break

					if((ispath(picked_mob, /obj/structure/spawner) || istype(thing, /obj/structure/spawner)) && get_dist(new_open_turf, thing) <= 2)
						can_spawn = FALSE
						break

				if(can_spawn)
					new picked_mob(new_open_turf)
		CHECK_TICK

	for(var/turf/special_turf in special_gen_turfs)
		var/turf_range = rand(2, 5)
		for(var/turf/genturf in range(turf_range, special_turf))
			if(!isopenturf(genturf) || sqrt((genturf.x - special_turf.x) ** 2 + (genturf.z - special_turf.z) ** 2) > turf_range) //I want a circle, not a square
				continue

			genturf.ChangeTurf(special_gen_turfs[special_turf], initial(special_gen_turfs[special_turf].baseturfs), CHANGETURF_IGNORE_AIR) //We generate some patches of grass and wasteland in caves so they don't look plain

	spawn_rivers(turfs[1].z, 4, /turf/open/water/jungle/underground, /area/mine/unexplored/planetgeneration_caves)

	var/message = "[name] finished in [(REALTIMEOFDAY - start_time)/10]s!"
	to_chat(world, "<span class='boldannounce'>[message]</span>")
	log_world(message)

/datum/map_generator/cave_generator/jungle/surface
	feature_spawn_chance = 2
	feature_spawn_list = list(/obj/structure/ladder/dirt_hole = 100, /obj/structure/geyser/jungle/wittel = 6, /obj/structure/geyser/jungle/random = 2, /obj/structure/geyser/jungle/plasma_oxide = 10, /obj/structure/geyser/jungle/protozine = 10, /obj/structure/geyser/jungle/hollowwater = 10)

/datum/map_generator/cave_generator/jungle/deep
	flora_spawn_list = list(/obj/structure/flora/rock = 2, /obj/structure/flora/rock/pile = 4, /obj/structure/flora/grass/jungle/b = 2, /obj/structure/flora/rock/jungle = 1, /obj/structure/flora/ash/jungle_plant/beerroot = 2, /obj/structure/flora/ash/jungle_plant/bagelshroom = 1)
	mob_spawn_chance = 6
	feature_spawn_chance = 0.1
	feature_spawn_list = list(/obj/structure/ladder/dirt_hole = 10, /obj/structure/geyser/jungle/wittel = 6, /obj/structure/geyser/jungle/random = 2, /obj/structure/geyser/jungle/plasma_oxide = 10, /obj/structure/geyser/jungle/protozine = 10, /obj/structure/geyser/jungle/hollowwater = 10)

/datum/map_generator/cave_generator/jungle/deep/bottom
	feature_spawn_chance = 0.05
	feature_spawn_list = list(/obj/structure/ladder/dirt_hole = 5, /obj/structure/geyser/jungle/wittel = 6, /obj/structure/geyser/jungle/random = 2, /obj/structure/geyser/jungle/plasma_oxide = 10, /obj/structure/geyser/jungle/protozine = 10, /obj/structure/geyser/jungle/hollowwater = 10)
	closed_turf_types =  list(/turf/closed/mineral/random/jungle/strong = 1) //These walls make plasmacutters almost useless, you'll need to make use of your KA.
