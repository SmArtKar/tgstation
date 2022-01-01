/obj/structure/spawner/jungle
	name = "cave entrance"
	desc = "A hole in the ground, filled with monsters ready to defend it."
	icon = 'icons/mob/nest.dmi'
	icon_state = "hole"
	faction = list("jungle")
	max_mobs = 3
	spawn_time = 15 SECONDS
	max_integrity = 250
	mob_types = list(/mob/living/simple_animal/hostile/jungle/cave_spider)
	move_resist = INFINITY
	anchored = TRUE

/obj/structure/spawner/jungle/Initialize()
	. = ..()
	AddComponent(/datum/component/gps, "Unstable Signal")

/obj/structure/spawner/jungle/deconstruct(disassembled)
	destroy_effect()
	drop_loot()
	return ..()

/obj/structure/spawner/jungle/proc/destroy_effect()
	playsound(loc,'sound/effects/explosionfar.ogg', 200, TRUE)
	visible_message(span_boldannounce("[src] collapses, sealing everything inside!</span>\n<span class='warning'>A wooden chest fall out of the cave as it is destroyed!"))

/obj/structure/spawner/jungle/proc/drop_loot()
	new /obj/structure/closet/crate/necropolis/tendril/jungle(loc)

/obj/structure/spawner/jungle/bat
	max_mobs = 8
	spawn_time = 5 SECONDS
	mob_types = list(/mob/living/simple_animal/hostile/jungle/bat)

/obj/structure/spawner/jungle/mega_arachnid
	max_mobs = 1
	spawn_time = 120 SECONDS
	mob_types = list(/mob/living/simple_animal/hostile/jungle/mega_arachnid)

/obj/structure/spawner/jungle/snakeman
	max_mobs = 3
	spawn_time = 20 SECONDS
	mob_types = list(/mob/living/simple_animal/hostile/jungle/snakeman)

/obj/structure/spawner/jungle/spider_big
	max_mobs = 3
	spawn_time = 20 SECONDS
	mob_types = list(/mob/living/simple_animal/hostile/giant_spider/hunter/scrawny/jungle, /mob/living/simple_animal/hostile/giant_spider/tarantula/scrawny/jungle)

/obj/structure/closet/crate/necropolis/tendril/jungle
	name = "dusty wooden chest"
	desc = "An old wooden chest. It requires a key to open."
	icon_state = "wooden"

/obj/structure/closet/crate/necropolis/tendril/jungle/try_spawn_loot(datum/source, obj/item/item, mob/user, params) ///proc that handles key checking and generating loot
	SIGNAL_HANDLER

	if(!istype(item, /obj/item/skeleton_key) || spawned_loot)
		return FALSE
	var/loot = rand(1,20)
	switch(loot)
		if(1)
			new /obj/item/shared_storage/red(src)
		if(2)
			new /obj/item/soulstone/anybody/mining(src)
		if(3)
			new /obj/item/organ/cyberimp/arm/katana(src)
		if(4)
			new /obj/item/clothing/glasses/godeye(src)
		if(5)
			new /obj/item/reagent_containers/glass/bottle/potion/flight(src)
		if(6)
			new /obj/item/clothing/gloves/gauntlets(src)
		if(7)
			var/mod = rand(1,4)
			switch(mod)
				if(1)
					new /obj/item/disk/design_disk/modkit_disc/resonator_blast(src)
				if(2)
					new /obj/item/disk/design_disk/modkit_disc/rapid_repeater(src)
				if(3)
					new /obj/item/disk/design_disk/modkit_disc/mob_and_turf_aoe(src)
				if(4)
					new /obj/item/disk/design_disk/modkit_disc/bounty(src)
		if(8)
			new /obj/item/rod_of_asclepius(src)
		if(9)
			new /obj/item/organ/heart/cursed/wizard(src)
		if(10)
			new /obj/item/ship_in_a_bottle(src)
		if(11)
			new /obj/item/clothing/suit/hooded/berserker(src)
		if(12)
			new /obj/item/jacobs_ladder(src)
		if(13)
			new /obj/item/boomerang(src)
		if(14)
			new /obj/item/warp_cube/red(src)
		if(15)
			new /obj/item/wisp_lantern(src)
		if(16)
			new /obj/item/immortality_talisman(src)
		if(17)
			new /obj/item/book/granter/spell/summonitem(src)
		if(18)
			new /obj/item/book_of_babel(src)
		if(19)
			new /obj/item/borg/upgrade/modkit/lifesteal(src)
			new /obj/item/bedsheet/cult(src)
		if(20)
			new /obj/item/clothing/neck/necklace/memento_mori(src)
	spawned_loot = TRUE
	qdel(item)
	to_chat(user, span_notice("You disable the magic lock, revealing the loot."))
	return TRUE
