#define NORMAL_VACUUM_PACK_CAPACITY 3
#define UPGRADED_VACUUM_PACK_CAPACITY 6
#define ILLEGAL_VACUUM_PACK_CAPACITY 12

#define NORMAL_VACUUM_PACK_RANGE 2
#define UPGRADED_VACUUM_PACK_RANGE 3
#define ILLEGAL_VACUUM_PACK_RANGE 4

#define VACUUM_PACK_UPGRADE_STASIS "stasis"
#define VACUUM_PACK_UPGRADE_HEALING "healing"
#define VACUUM_PACK_UPGRADE_CAPACITY "capacity"
#define VACUUM_PACK_UPGRADE_RANGE "range"
#define VACUUM_PACK_UPGRADE_PACIFY "pacification"
#define VACUUM_PACK_UPGRADE_BIOMASS "biomass printer"

/obj/item/vacuum_pack
	name = "backpack xenofauna storage"
	desc = "A Xynergy Solutions brand vacuum xenofauna storage with an extendable nozzle. Do not use to practice kissing."
	icon = 'icons/obj/xenobiology/equipment.dmi'
	icon_state = "vacuum_pack"
	inhand_icon_state = "vacuum_pack"
	lefthand_file = 'icons/mob/inhands/equipment/backpack_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/backpack_righthand.dmi'
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	slowdown = 1
	actions_types = list(/datum/action/item_action/toggle_nozzle)
	max_integrity = 200
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF

	var/obj/item/vacuum_nozzle/nozzle
	var/nozzle_type = /obj/item/vacuum_nozzle
	var/list/stored = list()
	var/capacity = NORMAL_VACUUM_PACK_CAPACITY
	var/range = NORMAL_VACUUM_PACK_RANGE
	var/illegal = FALSE
	var/list/upgrades = list()
	var/obj/machinery/biomass_recycler/linked
	var/give_choice = TRUE //If set to true the pack will give the owner a radial selection to choose which object they want to shoot
	var/static/list/storable_objects = list(/mob/living/simple_animal/slime, /mob/living/simple_animal/xenofauna)

/obj/item/vacuum_pack/Initialize(mapload)
	. = ..()
	nozzle = new nozzle_type(src)

/obj/item/vacuum_pack/Destroy()
	QDEL_NULL(nozzle)
	if(VACUUM_PACK_UPGRADE_HEALING in upgrades)
		STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/vacuum_pack/process(delta_time)
	if(!(VACUUM_PACK_UPGRADE_HEALING in upgrades))
		STOP_PROCESSING(SSobj, src)

	for(var/mob/living/simple_animal/animal in stored)
		animal.adjustBruteLoss(-0.5)

/obj/item/vacuum_pack/examine(mob/user)
	. = ..()
	if(LAZYLEN(stored))
		. += span_notice("It has [LAZYLEN(stored)] creatures stored in it.")
	if(LAZYLEN(upgrades))
		for(var/upgrade in upgrades)
			. += span_notice("It has [upgrade] upgrade installed.")

/obj/item/vacuum_pack/attackby(obj/item/item, mob/living/user, params)
	if(user.combat_mode)
		return ..()

	if(istype(item, /obj/item/disk/vacuum_upgrade))
		var/obj/item/disk/vacuum_upgrade/upgrade = item

		if(illegal)
			to_chat(user, span_warning("[src] has no slot to insert [upgrade] into!"))
			return

		if(upgrade.upgrade_type in upgrades)
			to_chat(user, span_warning("[src] already has a [upgrade.upgrade_type] upgrade!"))
			return

		upgrades += upgrade.upgrade_type
		upgrade.on_upgrade(src)
		to_chat(user, span_notice("You install a [upgrade.upgrade_type] upgrade into [src]."))
		playsound(user, 'sound/machines/click.ogg', 30, TRUE)
		qdel(upgrade)
		return

	return ..()

/obj/item/vacuum_pack/ui_action_click(mob/user)
	toggle_nozzle(user)

/obj/item/vacuum_pack/proc/toggle_nozzle(mob/living/user)
	if(!istype(user))
		return

	if(user.get_item_by_slot(user.getBackSlot()) != src)
		to_chat(user, span_warning("[src] must be worn properly to use!"))
		return

	if(user.incapacitated())
		return

	if(QDELETED(nozzle))
		nozzle = new nozzle_type(src)

	if(nozzle in src)
		if(!user.put_in_hands(nozzle))
			to_chat(user, span_warning("You need a free hand to hold [nozzle]!"))
			return
		else
			playsound(user, 'sound/mecha/mechmove03.ogg', 75, TRUE)
	else
		remove_nozzle()

/obj/item/vacuum_pack/item_action_slot_check(slot, mob/user)
	if(slot == user.getBackSlot())
		return TRUE

/obj/item/vacuum_pack/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_BACK)
		remove_nozzle()

/obj/item/vacuum_pack/proc/remove_nozzle()
	if(!QDELETED(nozzle))
		if(ismob(nozzle.loc))
			var/mob/wearer = nozzle.loc
			wearer.temporarilyRemoveItemFromInventory(nozzle, TRUE)
			playsound(loc, 'sound/mecha/mechmove03.ogg', 75, TRUE)
		nozzle.forceMove(src)

/obj/item/vacuum_pack/attack_hand(mob/user, list/modifiers)
	if (user.get_item_by_slot(user.getBackSlot()) == src)
		toggle_nozzle(user)
	else
		return ..()

/obj/item/vacuum_pack/MouseDrop(obj/over_object)
	var/mob/wearer = loc
	if(istype(wearer) && istype(over_object, /atom/movable/screen/inventory/hand))
		var/atom/movable/screen/inventory/hand/hand = over_object
		wearer.putItemFromInventoryInHandIfPossible(src, hand.held_index)
	return ..()

/obj/item/vacuum_pack/attackby(obj/item/W, mob/user, params)
	if(W == nozzle)
		remove_nozzle()
		return 1
	else
		return ..()

/obj/item/vacuum_pack/dropped(mob/user)
	..()
	remove_nozzle()

/obj/item/vacuum_nozzle
	name = "vacuum pack nozzle"
	desc = "A large nozzle attached to a vacuum pack."
	icon = 'icons/obj/xenobiology/equipment.dmi'
	icon_state = "vacuum_nozzle"
	inhand_icon_state = "vacuum_nozzle"
	lefthand_file = 'icons/mob/inhands/equipment/mister_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/mister_righthand.dmi'
	w_class = WEIGHT_CLASS_HUGE
	item_flags = NOBLUDGEON | ABSTRACT
	slot_flags = NONE

	var/obj/item/vacuum_pack/pack

/obj/item/vacuum_nozzle/Initialize(mapload)
	. = ..()
	pack = loc
	if(!istype(pack))
		return INITIALIZE_HINT_QDEL

/obj/item/vacuum_nozzle/doMove(atom/destination)
	if(destination && (destination != pack.loc || !ismob(destination)))
		if (loc != pack)
			to_chat(pack.loc, span_notice("[src] snaps back onto [pack]."))
		destination = pack
	. = ..()

/obj/item/vacuum_nozzle/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()

	if(!(VACUUM_PACK_UPGRADE_BIOMASS in pack.upgrades))
		to_chat(user, span_warning("[pack] does not posess a required upgrade!"))
		return

	var/area/current_area = get_area(get_turf(src))
	if(!(current_area.area_flags & XENOBIOLOGY_COMPATIBLE) && !pack.illegal)
		playsound(src, 'sound/weapons/gun/general/dry_fire.ogg', 50, TRUE)
		to_chat(user, span_warning("[src] clicks as it refuses to operate because of it's area lock!"))
		return

	if(!pack.linked)
		to_chat(user, span_warning("[pack] is not linked to a biomass recycler!"))
		return

	var/list/items = list()
	var/list/item_names = list()
	for(var/printable_type in pack.linked.vacuum_printable_types)
		var/atom/movable/printable = printable_type
		var/image/printable_image = image(icon = initial(printable.icon), icon_state = initial(printable.icon_state))
		items += list(initial(printable.name) = printable_image)
		item_names[initial(printable.name)] = printable_type

	var/pick = show_radial_menu(user, src, items, custom_check = FALSE, require_near = TRUE, tooltips = TRUE)

	if(!pick)
		return

	var/spawn_type = item_names[pick]
	if(pack.linked.stored_matter < pack.linked.vacuum_printable_types[spawn_type])
		to_chat(user, span_warning("[pack.linked] does not have enough stored biomass for that! It currently has [pack.linked.stored_matter] out of [pack.linked.vacuum_printable_types[spawn_type]] unit\s required."))
		return
	var/atom/movable/spawned = new spawn_type(user.loc)
	pack.linked.stored_matter -= pack.linked.vacuum_printable_types[spawn_type]
	playsound(user, 'sound/misc/moist_impact.ogg', 50, TRUE)
	spawned.transform = matrix().Scale(0.5)
	spawned.alpha = 0
	animate(spawned, alpha = 255, time = 8, easing = QUAD_EASING|EASE_OUT, transform = matrix(), flags = ANIMATION_PARALLEL)

	if(isturf(user.loc))
		spawned.throw_at(target, min(get_dist(user, target), (pack.illegal ? 5 : 11)), 1, user)

	user.visible_message(span_warning("[user] shoots [spawned] out their [src]!"), span_notice("You fabricate and shoot [spawned] out of your [src]."))

/obj/item/vacuum_nozzle/afterattack(atom/movable/target, mob/user, proximity, params)
	. = ..()

	if(LAZYACCESS(params2list(params), RIGHT_CLICK))
		return

	if(istype(target, /obj/machinery/biomass_recycler) && target.Adjacent(user))
		if(!(VACUUM_PACK_UPGRADE_BIOMASS in pack.upgrades))
			to_chat(user, span_warning("[pack] does not posess a required upgrade!"))
			return
		pack.linked = target
		to_chat(user, span_notice("You link [pack] to [target]."))
		return

	var/can_store = FALSE
	for(var/storable_type in pack.storable_objects)
		if(istype(target, storable_type))
			can_store = TRUE
			break

	if(pack.linked)
		var/can_recycle
		for(var/recycable_type in pack.linked.recyclable_types)
			if(istype(target, recycable_type))
				can_recycle = recycable_type
				break

		var/target_stat = FALSE
		var/buckled_to = FALSE
		if(isliving(target))
			var/mob/living/living_target = target
			target_stat = living_target.stat
			buckled_to = living_target.buckled

		if(can_recycle && (!can_store || target_stat != CONSCIOUS))
			if(!(VACUUM_PACK_UPGRADE_BIOMASS in pack.upgrades))
				to_chat(user, span_warning("[pack] does not posess a required upgrade!"))
				return

			if(!pack.linked)
				to_chat(user, span_warning("[pack] is not linked to a biomass recycler!"))
				return

			if(!do_after(user, (pack.illegal ? 6 : 12), target, timed_action_flags = IGNORE_TARGET_LOC_CHANGE))
				return

			if(target_stat == CONSCIOUS)
				to_chat(user, span_warning("[target] is struggling far too much for you to suck it in!"))
				return

			if(buckled_to || target.has_buckled_mobs())
				to_chat(user, span_warning("[target] is attached to something!"))
				return

			playsound(src, 'sound/effects/refill.ogg', 50, TRUE)
			var/matrix/animation_matrix = matrix()
			animation_matrix.Scale(0.5)
			animation_matrix.Translate((user.x - target.x) * 32, (user.y - target.y) * 32)
			animate(target, alpha = 0, time = 8, easing = QUAD_EASING|EASE_IN, transform = animation_matrix, flags = ANIMATION_PARALLEL)
			sleep(8)
			user.visible_message(span_warning("[user] sucks [target] into their [pack]!"), span_notice("You successfully suck [target] into your [src] and recycle it."))
			qdel(target)
			playsound(user, 'sound/machines/juicer.ogg', 50, TRUE)
			pack.linked.use_power(500)
			pack.linked.stored_matter += pack.linked.cube_production * pack.linked.recyclable_types[can_recycle]
			return

	if(can_store)
		if(get_dist(user, target) > pack.range)
			to_chat(user, span_warning("[target] is too far away!"))
			return

		var/in_view = FALSE
		for(var/atom/movable/possible_target in view(user, pack.range))
			if(possible_target == target)
				in_view = TRUE
				break

		if(!in_view)
			to_chat(user, span_warning("You can't reach [target]!"))
			return

		if(isslime(target))
			var/mob/living/simple_animal/slime/slime = target
			if(slime.rabid && !pack.illegal && !(VACUUM_PACK_UPGRADE_PACIFY in pack.upgrades))
				to_chat(user, span_warning("[slime] is wiggling far too much for you to suck it in!"))
				return

		if(LAZYLEN(pack.stored) >= pack.capacity)
			to_chat(user, span_warning("[pack] is already filled to the brim!"))
			return

		if(!do_after(user, (pack.illegal ? 6 : 12), target, timed_action_flags = IGNORE_TARGET_LOC_CHANGE))
			return

		playsound(user, 'sound/effects/refill.ogg', 50, TRUE)
		var/matrix/animation_matrix = matrix()
		animation_matrix.Scale(0.5)
		animation_matrix.Translate((user.x - target.x) * 32, (user.y - target.y) * 32)
		animate(target, alpha = 0, time = 8, easing = QUAD_EASING|EASE_IN, transform = animation_matrix, flags = ANIMATION_PARALLEL)
		sleep(8)
		target.forceMove(pack)
		pack.stored += target
		if((VACUUM_PACK_UPGRADE_STASIS in pack.upgrades) && isslime(target))
			var/mob/living/simple_animal/slime/slime = target
			slime.force_stasis = TRUE
		user.visible_message(span_warning("[user] sucks [target] into their [pack]!"), span_notice("You successfully suck [target] into your [src]."))
		return

	var/area/current_area = get_area(get_turf(src))
	if(!(current_area.area_flags & XENOBIOLOGY_COMPATIBLE) && !pack.illegal)
		playsound(src, 'sound/weapons/gun/general/dry_fire.ogg', 50, TRUE)
		to_chat(user, span_warning("[src] clicks as it refuses to operate because of it's area lock!"))
		return

	if(LAZYLEN(pack.stored) == 0)
		to_chat(user, span_warning("[pack] is empty!"))
		return

	var/atom/movable/spewed

	if(pack.give_choice)
		var/list/items = list()
		var/list/items_stored = list()
		for(var/atom/movable/stored_obj in pack.stored)
			var/image/stored_image = image(icon = stored_obj.icon, icon_state = stored_obj.icon_state)
			items += list(stored_obj.name = stored_image)
			items_stored[stored_obj.name] = stored_obj

		var/pick = show_radial_menu(user, src, items, custom_check = FALSE, require_near = TRUE, tooltips = TRUE)

		if(!pick)
			return
		spewed = items_stored[pick]
	else
		spewed = pick(pack.stored)

	playsound(user, 'sound/misc/moist_impact.ogg', 50, TRUE)
	spewed.transform = matrix().Scale(0.5)
	spewed.alpha = 0
	animate(spewed, alpha = 255, time = 8, easing = QUAD_EASING|EASE_OUT, transform = matrix(), flags = ANIMATION_PARALLEL)
	spewed.forceMove(user.loc)

	if(isturf(user.loc))
		spewed.throw_at(target, min(get_dist(user, target), (pack.illegal ? 5 : 11)), 1, user)

	if(isslime(spewed))
		var/mob/living/simple_animal/slime/slime = spewed
		if(VACUUM_PACK_UPGRADE_STASIS in pack.upgrades)
			slime.force_stasis = FALSE

		if(pack.illegal)
			if(slime.docile)
				slime.docile = FALSE
				slime.update_name()
			slime.rabid = TRUE
			slime.set_friendship(user, 20)
			slime.powerlevel = max(slime.powerlevel, 3)
			user.changeNext_move(CLICK_CD_RANGE) //Like a machine gun

		else if(VACUUM_PACK_UPGRADE_PACIFY in pack.upgrades)
			slime.rabid = FALSE
			slime.powerlevel = 0
			slime.attacked = 0 //Completely pacifies and discharges slimes. Useful when there's another tot xenobiologist

	pack.stored -= spewed
	user.visible_message(span_warning("[user] shoots [spewed] out their [src]!"), span_notice("You shoot [spewed] out of your [src]."))

/obj/item/disk/vacuum_upgrade
	name = "vacuum pack upgrade disk"
	desc = "An upgrade disk for a backpack vacuum xenofauna storage."
	icon_state = "rndminordisk"
	var/upgrade_type

/obj/item/disk/vacuum_upgrade/proc/on_upgrade(obj/item/vacuum_pack/pack)

/obj/item/disk/vacuum_upgrade/stasis
	name = "vacuum pack stasis upgrade disk"
	desc = "An upgrade disk for a backpack vacuum xenofauna storage that allows it to keep all slimes inside of it in stasis."
	upgrade_type = VACUUM_PACK_UPGRADE_STASIS

/obj/item/disk/vacuum_upgrade/healing
	name = "vacuum pack healing upgrade disk"
	desc = "An upgrade disk for a backpack vacuum xenofauna storage that makes the pack passively heal all the slimes inside of it."
	upgrade_type = VACUUM_PACK_UPGRADE_HEALING

/obj/item/disk/vacuum_upgrade/healing/on_upgrade(obj/item/vacuum_pack/pack)
	START_PROCESSING(SSobj, pack)

/obj/item/disk/vacuum_upgrade/capacity
	name = "vacuum pack capacity upgrade disk"
	desc = "An upgrade disk for a backpack vacuum xenofauna storage that expands it's internal slime storage."
	upgrade_type = VACUUM_PACK_UPGRADE_CAPACITY

/obj/item/disk/vacuum_upgrade/capacity/on_upgrade(obj/item/vacuum_pack/pack)
	pack.capacity = UPGRADED_VACUUM_PACK_CAPACITY

/obj/item/disk/vacuum_upgrade/range
	name = "vacuum pack range upgrade disk"
	desc = "An upgrade disk for a backpack vacuum xenofauna storage that strengthens it's pump and allows it to reach further."
	upgrade_type = VACUUM_PACK_UPGRADE_RANGE

/obj/item/disk/vacuum_upgrade/capacity/on_upgrade(obj/item/vacuum_pack/pack)
	pack.range = UPGRADED_VACUUM_PACK_RANGE

/obj/item/disk/vacuum_upgrade/pacification
	name = "vacuum pack pacification upgrade disk"
	desc = "An upgrade disk for a backpack vacuum xenofauna storage that allows it to pacify all stored slimes."
	upgrade_type = VACUUM_PACK_UPGRADE_PACIFY

/obj/item/disk/vacuum_upgrade/biomass
	name = "vacuum pack biomass printer upgrade disk"
	desc = "An upgrade disk for a backpack vacuum xenofauna storage that allows it to automatically recycle dead biomass and make living creatures on right click."
	upgrade_type = VACUUM_PACK_UPGRADE_BIOMASS

/obj/item/vacuum_pack/syndicate
	name = "modified backpack xenofauna storage"
	desc = "An illegally modified vacuum backpack xenofauna storage that has much more power, capacity and will make every slime it shoots out rabid."
	icon_state = "vacuum_pack_syndicate"
	inhand_icon_state = "vacuum_pack_syndicate"
	range = ILLEGAL_VACUUM_PACK_RANGE
	capacity = ILLEGAL_VACUUM_PACK_CAPACITY
	illegal = TRUE
	nozzle_type = /obj/item/vacuum_nozzle/syndicate
	upgrades = list(VACUUM_PACK_UPGRADE_HEALING, VACUUM_PACK_UPGRADE_STASIS)
	give_choice = FALSE

/obj/item/vacuum_nozzle/syndicate
	name = "modified vacuum pack nozzle"
	desc = "A large black and red nozzle attached to a vacuum pack."
	icon_state = "vacuum_nozzle_syndicate"
	inhand_icon_state = "vacuum_nozzle_syndicate"

#undef NORMAL_VACUUM_PACK_CAPACITY
#undef UPGRADED_VACUUM_PACK_CAPACITY
#undef ILLEGAL_VACUUM_PACK_CAPACITY

#undef NORMAL_VACUUM_PACK_RANGE
#undef UPGRADED_VACUUM_PACK_RANGE
#undef ILLEGAL_VACUUM_PACK_RANGE

#undef VACUUM_PACK_UPGRADE_STASIS
#undef VACUUM_PACK_UPGRADE_HEALING
#undef VACUUM_PACK_UPGRADE_CAPACITY
#undef VACUUM_PACK_UPGRADE_RANGE
#undef VACUUM_PACK_UPGRADE_PACIFY
