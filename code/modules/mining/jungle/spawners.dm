/obj/structure/spawner/jungle
	name = "cave entrance"
	desc = "A hole in the ground, filled with monsters ready to defend it."
	icon = 'icons/mob/nest.dmi'
	icon_state = "hole"
	faction = list("jungle")
	max_mobs = 4
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
	max_mobs = 10
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
	var/loot = rand(1,23)
	switch(loot)
		if(1)
			new /obj/item/shared_storage/red(src)
		if(2)
			new /obj/item/boomerang(src)
		if(3)
			new /obj/item/katana/cursed(src)
		if(4)
			new /obj/item/clothing/glasses/godeye(src)
		if(5)
			new /obj/item/reagent_containers/glass/bottle/potion/flight(src)
		if(6)
			new /obj/item/dash_knife(src)
		if(7)
			new /obj/item/disk/design_disk/modkit_disc/resonator_blast(src)
		if(8)
			new /obj/item/disk/design_disk/modkit_disc/rapid_repeater(src)
		if(9)
			new /obj/item/disk/design_disk/modkit_disc/mob_and_turf_aoe(src)
		if(10)
			new /obj/item/disk/design_disk/modkit_disc/bounty(src)
		if(11)
			new /obj/item/rod_of_asclepius(src)
		if(12)
			new /obj/item/organ/heart/cursed/wizard(src)
		if(13)
			new /obj/item/slime_extract/adamantine(loc)
		if(14)
			new /obj/item/clothing/suit/space/hardsuit/berserker(src)
		if(15)
			new /obj/item/jacobs_ladder(loc)
		if(16)
			new /obj/item/guardiancreator/miner(src)
		if(17)
			new /obj/item/warp_cube/red(src)
		if(18)
			new /obj/item/wisp_lantern(src)
		if(19)
			new /obj/item/immortality_talisman(src)
		if(20)
			new /obj/item/book/granter/spell/summonitem(src)
		if(21)
			new /obj/item/jacobs_ladder(loc)
		if(22)
			new /obj/item/borg/upgrade/modkit/lifesteal(src)
			new /obj/item/bedsheet/cult(src)
		if(23)
			new /obj/item/clothing/neck/necklace/memento_mori(src)
	spawned_loot = TRUE
	qdel(item)
	to_chat(user, span_notice("You disable the magic lock, revealing the loot."))
	return TRUE






/obj/item/boomerang
	name = "boomerang"
	desc = "A wooden boomerang with a bit of vine growing on it. Just be careful to catch it when thrown!"
	throw_speed = 2
	icon_state = "boomerang_jungle"
	inhand_icon_state = "boomerang_jungle"
	force = 5
	throwforce = 10
	throw_range = 10
	custom_materials = list(/datum/material/wood = 10000)

/obj/item/boomerang/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE)
	if(ishuman(thrower))
		var/mob/living/carbon/human/H = thrower
		H.throw_mode_off(THROW_MODE_TOGGLE) //so they can catch it on the return.
	return ..()

/obj/item/boomerang/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(isanimal(hit_atom))
		throwforce = 30
	var/mob/thrown_by = thrownby?.resolve()
	if(thrown_by)
		addtimer(CALLBACK(src, /atom/movable.proc/throw_at, thrown_by, throw_range+2, throw_speed, null, TRUE), 1)
	. = ..()
	throwforce = initial(throwforce)

/obj/item/dash_knife
	name = "posessed knife"
	desc = "A small wooden knife posessed by some kind of spirit. Right-click while holding it in an offhand to perform a dash with a cooldown."
	icon_state = "crysknife"
	inhand_icon_state = "crysknife"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 10
	w_class = WEIGHT_CLASS_SMALL
	sharpness = SHARP_EDGED
	slot_flags = ITEM_SLOT_BELT
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")
	var/atom/second_item
	var/dash_cooldown = 0

/obj/item/dash_knife/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 50, 100) //COMSIG_RIGHT_CLICK_USE COMSIG_ITEM_PRE_UNEQUIP

/obj/item/dash_knife/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		check_other_equip()
		RegisterSignal(user, COMSIG_MOB_EQUIPPED_ITEM, .proc/check_other_equip)

/obj/item/dash_knife/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_EQUIPPED_ITEM)

/obj/item/dash_knife/proc/check_other_equip()
	SIGNAL_HANDLER

	if(!ismob(loc))
		return
	var/mob/user = loc
	var/atom/target
	if(user.get_inactive_held_item() == src)
		target = user.get_active_held_item()
	else
		target = user.get_inactive_held_item()

	if(!target)
		return

	second_item = target
	RegisterSignal(target, COMSIG_RIGHT_CLICK_USE, .proc/dash, override = TRUE)
	RegisterSignal(target, COMSIG_ITEM_PRE_UNEQUIP, .proc/unequipped_other_item)

/obj/item/dash_knife/proc/unequipped_other_item()
	SIGNAL_HANDLER

	UnregisterSignal(second_item, COMSIG_RIGHT_CLICK_USE)
	UnregisterSignal(second_item, COMSIG_ITEM_PRE_UNEQUIP)
	second_item = null

/obj/item/dash_knife/proc/dash(atom/target)
	SIGNAL_HANDLER

	if(dash_cooldown > world.time || !ismob(loc))
		return

	var/mob/user = loc
	dash_cooldown = world.time += 10 SECONDS
	ADD_TRAIT(user, TRAIT_STUNIMMUNE, GENERIC_ITEM_TRAIT)
	user.throw_at(target, get_dist(target, user) - 1, 1, user, FALSE, TRUE, callback = CALLBACK(src, .proc/charging_end))

/obj/item/dash_knife/proc/charging_end()
	if(!ismob(loc))
		return

	var/mob/user = loc
	REMOVE_TRAIT(user, TRAIT_STUNIMMUNE, GENERIC_ITEM_TRAIT)
