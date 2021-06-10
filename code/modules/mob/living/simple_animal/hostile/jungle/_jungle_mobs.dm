/mob/living/simple_animal/hostile/jungle
	vision_range = 5
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	faction = list("jungle")
	weather_immunities = list(ACID)
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

/obj/effect/spawner/jungle/cave_mob_spawner
	name = "cave mob spawner"
	var/land_mobs = list(/obj/effect/spawner/jungle/cave_spider_nest = 3, /obj/effect/spawner/jungle/cave_bat_nest = 5)
	var/water_most = list()

/obj/effect/spawner/jungle/cave_mob_spawner/Initialize()
	. = ..()
	if(istype(get_turf(src), /turf/open/water/jungle))
		if(LAZYLEN(water_most))
			var/spawn_type = pickweight(water_most)
			new spawn_type(get_turf(src))
		return INITIALIZE_HINT_QDEL

	if(LAZYLEN(land_mobs))
		var/spawn_type = pickweight(land_mobs)
		new spawn_type(get_turf(src))
	return INITIALIZE_HINT_QDEL
