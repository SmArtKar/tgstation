#define JUNGLE_MOB_DISTANCE 3
#define COMMON_MOB_DISTANCE 1

///This datum handles the transitioning from a turf to a specific biome, and handles spawning decorative structures and mobs.
/datum/biome
	///Type of turf this biome creates
	var/turf_type
	///Chance of having a structure from the flora types list spawn
	var/flora_density = 0
	///Chance of having a mob from the fauna types list spawn
	var/fauna_density = 0
	///Chance of having a special structure from the special types list spawn
	var/special_density = 0
	///list of type paths of objects that can be spawned when the turf spawns flora
	var/list/flora_types = list(/obj/structure/flora/grass/jungle)
	///list of type paths of mobs that can be spawned when the turf spawns fauna
	var/list/fauna_types = list()
	///list of type paths of mobs that can be spawned when the turf spawns special structures
	var/list/special_types = list()
	///Is this biome exposed to the sun?
	var/natural_light = TRUE
	///Should we generate caves in this biome?
	var/generate_caves = FALSE

///This proc handles the creation of a turf of a specific biome type
/datum/biome/proc/generate_turf(turf/gen_turf)
	gen_turf.ChangeTurf(turf_type, null, CHANGETURF_DEFER_CHANGE)
	if(length(fauna_types) && prob(fauna_density))
		var/mob/fauna = pick_weight(fauna_types)
		var/can_spawn = TRUE

		for(var/mob/living/simple_animal/hostile/thing in orange(8, gen_turf))
			if(!istype(thing))
				continue

			var/trigger_range = COMMON_MOB_DISTANCE
			if(istype(thing, /mob/living/simple_animal/hostile/jungle))
				trigger_range = JUNGLE_MOB_DISTANCE

			if(get_dist(thing, gen_turf) <= trigger_range)
				can_spawn = FALSE
				break

		if(can_spawn)
			new fauna(gen_turf)

	if(length(flora_types) && prob(flora_density))
		var/flora = pick(flora_types)
		new flora(gen_turf)

	if(length(special_types) && prob(special_density))
		var/special_construction = pick(special_types)
		new special_construction(gen_turf)

/datum/biome/mudlands
	turf_type = /turf/open/floor/plating/dirt/jungle/dark
	flora_types = list(/obj/structure/flora/grass/jungle, /obj/structure/flora/grass/jungle/b, /obj/structure/flora/rock/jungle, /obj/structure/flora/rock/pile/largejungle)
	flora_density = 3
	fauna_types = list(/mob/living/simple_animal/hostile/retaliate/snake/jungle = 3, /mob/living/simple_animal/hostile/retaliate/frog/jungle = 2, /mob/living/simple_animal/hostile/lizard/jungle = 2)
	fauna_density = 1

/datum/biome/plains
	turf_type = /turf/open/floor/plating/grass/jungle/green
	flora_types = list(/obj/structure/flora/ash/jungle_plant, /obj/structure/flora/grass/jungle, /obj/structure/flora/grass/jungle/b, /obj/structure/flora/tree/jungle, /obj/structure/flora/rock/jungle, /obj/structure/flora/junglebush, /obj/structure/flora/junglebush/c, /obj/structure/flora/junglebush/large, /obj/structure/flora/rock/pile/largejungle)
	flora_density = 10
	fauna_types = list(/mob/living/carbon/human/species/monkey/jungle = 2, /mob/living/simple_animal/parrot/jungle = 3, /mob/living/simple_animal/hostile/retaliate/snake/jungle = 4, /mob/living/simple_animal/hostile/lizard/jungle = 4, /mob/living/simple_animal/hostile/jungle/leaper = 1, /mob/living/simple_animal/hostile/jungle/seedling = 1, /mob/living/simple_animal/hostile/jungle/snakeman/random = 2)
	fauna_density = 1

/datum/biome/plains/cold
	flora_types = list(/obj/structure/flora/ash/jungle_plant, /obj/structure/flora/grass/jungle, /obj/structure/flora/grass/jungle/b, /obj/structure/flora/rock/jungle, /obj/structure/flora/junglebush, /obj/structure/flora/junglebush/c, /obj/structure/flora/junglebush/large, /obj/structure/flora/rock/pile/largejungle)
	flora_density = 1.5
	fauna_types = list(/mob/living/carbon/human/species/monkey/jungle = 2, /mob/living/simple_animal/parrot/jungle = 3, /mob/living/simple_animal/hostile/retaliate/snake/jungle = 4, /mob/living/simple_animal/hostile/lizard/jungle = 4, /mob/living/simple_animal/hostile/jungle/leaper = 1, /mob/living/simple_animal/hostile/jungle/mook = 1, /mob/living/simple_animal/hostile/jungle/seedling = 1, /mob/living/simple_animal/hostile/jungle/snakeman/random = 2)
	fauna_density = 1.2

/datum/biome/jungle
	turf_type = /turf/open/floor/plating/grass/jungle
	flora_types = list(/obj/structure/flora/ash/jungle_plant, /obj/structure/flora/grass/jungle, /obj/structure/flora/grass/jungle/b, /obj/structure/flora/tree/jungle, /obj/structure/flora/rock/jungle, /obj/structure/flora/junglebush, /obj/structure/flora/junglebush/c, /obj/structure/flora/junglebush/large, /obj/structure/flora/rock/pile/largejungle)
	flora_density = 40

	fauna_types = list(/mob/living/simple_animal/hostile/gorilla/jungle = 2, /mob/living/carbon/human/species/monkey/jungle = 2, /mob/living/simple_animal/parrot/jungle = 3, /mob/living/simple_animal/hostile/retaliate/snake/jungle = 4, /mob/living/simple_animal/hostile/lizard/jungle = 4, /mob/living/simple_animal/hostile/jungle/mook = 1, /mob/living/simple_animal/hostile/jungle/seedling = 1, /mob/living/simple_animal/hostile/jungle/mega_arachnid = 1, /mob/living/simple_animal/hostile/jungle/snakeman/random = 2)
	fauna_density = 2

/datum/biome/jungle/deep
	flora_density = 65
	fauna_types = list(/mob/living/simple_animal/hostile/gorilla/jungle = 2, /mob/living/carbon/human/species/monkey/jungle = 2, /mob/living/simple_animal/parrot/jungle = 3, /mob/living/simple_animal/hostile/retaliate/snake/jungle = 4, /mob/living/simple_animal/hostile/lizard/jungle = 4, /mob/living/simple_animal/hostile/jungle/leaper = 1, /mob/living/simple_animal/hostile/jungle/mook = 1, /mob/living/simple_animal/hostile/jungle/mega_arachnid = 1, /mob/living/simple_animal/hostile/jungle/snakeman/random = 2)
	fauna_density = 3

/datum/biome/wasteland
	turf_type = /turf/open/floor/plating/dirt/jungle/wasteland
	flora_density = 2
	flora_types = list(/obj/structure/flora/rock, /obj/structure/flora/rock/pile)

/datum/biome/water
	turf_type = /turf/open/water/jungle
	flora_types = list()
	fauna_types = list(/mob/living/simple_animal/hostile/retaliate/snake/jungle = 3, /mob/living/simple_animal/hostile/retaliate/frog/jungle = 2)
	fauna_density = 0.1

/datum/biome/mountain
	turf_type = /turf/closed/mineral/random/jungle
	natural_light = FALSE
	generate_caves = TRUE

/datum/biome/mountain/high/generate_turf(turf/gen_turf)
	. = ..()
	var/turf/top_turf = locate(gen_turf.x, gen_turf.y, gen_turf.z + 1)
	if(top_turf)
		top_turf.ChangeTurf(turf_type, null, CHANGETURF_DEFER_CHANGE)

#undef JUNGLE_MOB_DISTANCE
#undef COMMON_MOB_DISTANCE
