///Unit test that spawns all mobs that can be spawned by golden slimes
/datum/unit_test/spawn_mobs

/datum/unit_test/spawn_mobs/Run()
	for(var/_animal in typesof(/mob/living/simple_animal))
		var/mob/living/simple_animal/animal = _animal
		if (initial(animal.mob_spawnable_type) == HOSTILE_SPAWN || initial(animal.mob_spawnable_type) == FRIENDLY_SPAWN)
			allocate(_animal)
