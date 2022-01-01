//the random offset applied to square coordinates, causes intermingling at biome borders
#define BIOME_RANDOM_SQUARE_DRIFT 2
//Used to select "zoom" level into the perlin noise, higher numbers result in slower transitions
#define PERLIN_NOISE_ZOOM 65
//Defines the level at which mountains spawn
#define MOUNTAIN_LEVEL 0.85
#define HIGH_MOUNTAIN_LEVEL 0.87

/datum/map_generator/jungle_generator
	///2D list of all biomes based on heat and humidity combos.
	var/list/possible_biomes = list(
	BIOME_LOW_HEAT = list(
		BIOME_LOW_HUMIDITY = /datum/biome/plains,
		BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/plains/cold,
		BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/mudlands,
		BIOME_HIGH_HUMIDITY = /datum/biome/water
		),
	BIOME_LOWMEDIUM_HEAT = list(
		BIOME_LOW_HUMIDITY = /datum/biome/plains,
		BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/plains/cold,
		BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/jungle,
		BIOME_HIGH_HUMIDITY = /datum/biome/mudlands
		),
	BIOME_HIGHMEDIUM_HEAT = list(
		BIOME_LOW_HUMIDITY = /datum/biome/plains,
		BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/plains,
		BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/jungle/deep,
		BIOME_HIGH_HUMIDITY = /datum/biome/jungle
		),
	BIOME_HIGH_HEAT = list(
		BIOME_LOW_HUMIDITY = /datum/biome/wasteland,
		BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/plains,
		BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/jungle,
		BIOME_HIGH_HUMIDITY = /datum/biome/jungle/deep
		)
	)

///Seeds the rust-g perlin noise with a random number.
/datum/map_generator/jungle_generator/generate_terrain(list/turfs)
	. = ..()
	var/height_seed = rand(0, 50000)
	var/humidity_seed = rand(0, 50000)
	var/heat_seed = rand(0, 50000)

	var/area/mine/planetgeneration_caves/cave_area = new()

	for(var/t in turfs) //Go through all the turfs and generate them
		var/turf/gen_turf = t
		var/drift_x = (gen_turf.x + rand(-BIOME_RANDOM_SQUARE_DRIFT, BIOME_RANDOM_SQUARE_DRIFT)) / PERLIN_NOISE_ZOOM
		var/drift_y = (gen_turf.y + rand(-BIOME_RANDOM_SQUARE_DRIFT, BIOME_RANDOM_SQUARE_DRIFT)) / PERLIN_NOISE_ZOOM

		var/height = text2num(rustg_noise_get_at_coordinates("[height_seed]", "[drift_x]", "[drift_y]"))


		var/datum/biome/selected_biome
		if(height <= MOUNTAIN_LEVEL) //If height is less than MOUNTAIN_LEVEL, we generate biomes based on the heat and humidity of the area.
			var/humidity = text2num(rustg_noise_get_at_coordinates("[humidity_seed]", "[drift_x]", "[drift_y]"))
			var/heat = text2num(rustg_noise_get_at_coordinates("[heat_seed]", "[drift_x]", "[drift_y]"))
			var/heat_level //Type of heat zone we're in LOW-MEDIUM-HIGH
			var/humidity_level  //Type of humidity zone we're in LOW-MEDIUM-HIGH

			switch(heat)
				if(0 to 0.25)
					heat_level = BIOME_LOW_HEAT
				if(0.25 to 0.5)
					heat_level = BIOME_LOWMEDIUM_HEAT
				if(0.5 to 0.75)
					heat_level = BIOME_HIGHMEDIUM_HEAT
				if(0.75 to 1)
					heat_level = BIOME_HIGH_HEAT
			switch(humidity)
				if(0 to 0.25)
					humidity_level = BIOME_LOW_HUMIDITY
				if(0.25 to 0.5)
					humidity_level = BIOME_LOWMEDIUM_HUMIDITY
				if(0.5 to 0.75)
					humidity_level = BIOME_HIGHMEDIUM_HUMIDITY
				if(0.75 to 1)
					humidity_level = BIOME_HIGH_HUMIDITY
			selected_biome = possible_biomes[heat_level][humidity_level]
		else if(height < HIGH_MOUNTAIN_LEVEL) //Over MOUNTAIN_LEVEL; It's a mountain
			selected_biome = /datum/biome/mountain
		else
			selected_biome = /datum/biome/mountain/high

		selected_biome = SSmapping.biomes[selected_biome] //Get the instance of this biome from SSmapping
		selected_biome.generate_turf(gen_turf)
		if(selected_biome.natural_light)
			gen_turf.set_light_on(TRUE)
			gen_turf.set_light_power(8)
			gen_turf.set_light_range(3)
			//gen_turf.AddComponent(/datum/component/sunlight)

		if(selected_biome.generate_caves)
			var/area/old_area = gen_turf.loc
			cave_area.contents += gen_turf
			gen_turf.change_area(old_area, cave_area)

		CHECK_TICK

	cave_area.RunGeneration()

	spawn_rivers(turfs[1].z, 4, /turf/open/water/jungle, /area/mine/planetgeneration) ///Uncomment if you want to spawn rivers as well. Do not uncomment unless lighting shit is reworked.

/turf/open/genturf
	name = "ungenerated turf"
	desc = "If you see this, and you're not a ghost, yell at coders"
	icon = 'icons/turf/debug.dmi'
	icon_state = "genturf"

/area/mine/planetgeneration
	name = "planet generation area"

	area_flags = VALID_TERRITORY | UNIQUE_AREA | NO_ALERTS | FLORA_ALLOWED | MOB_SPAWN_ALLOWED

	map_generator = /datum/map_generator/jungle_generator
	static_lighting = FALSE
	base_lighting_alpha = 255
	outdoors = TRUE

/area/mine/planetgeneration_caves
	name = "planet caves generation area"

	area_flags = VALID_TERRITORY | UNIQUE_AREA | NO_ALERTS | CAVES_ALLOWED | FLORA_ALLOWED | MOB_SPAWN_ALLOWED
	map_generator = /datum/map_generator/cave_generator/jungle/surface
	base_lighting_alpha = 0

/area/mine/planetgeneration_caves/deep
	name = "jungle caves generation area"
	map_generator = /datum/map_generator/cave_generator/jungle/deep
	base_lighting_alpha = 0

/area/mine/planetgeneration_caves/deep/bottom
	name = "deep jungle caves generation area"
	map_generator = /datum/map_generator/cave_generator/jungle/deep/bottom

#undef PERLIN_NOISE_ZOOM
#undef BIOME_RANDOM_SQUARE_DRIFT
#undef MOUNTAIN_LEVEL
