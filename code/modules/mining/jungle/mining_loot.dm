
/// Boomerang

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
		H.throw_mode_on(THROW_MODE_TOGGLE) //so they can catch it on the return.
	return ..()

/obj/item/boomerang/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(isanimal(hit_atom))
		throwforce = 30
	var/mob/thrown_by = thrownby?.resolve()
	if(thrown_by)
		addtimer(CALLBACK(src, /atom/movable.proc/throw_at, thrown_by, throw_range+2, throw_speed, null, TRUE), 1)
	. = ..()
	throwforce = initial(throwforce)

/// Mechanical Alloy armor

#define RESONANCE_COOLDOWN 10 SECONDS

/obj/item/clothing/suit/hooded/alloy_armor
	name = "mechanical alloy armor"
	desc = "A suit made out of mechanicall alloy plates sewed together with bat sinew."
	icon_state = "mechanical_alloy"
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/mining_scanner, /obj/item/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator, /obj/item/pickaxe, /obj/item/spear)
	armor = list(MELEE = 45, BULLET = 20, LASER = 10, ENERGY = 10, BOMB = 50, BIO = 60, FIRE = 100, ACID = 100)
	hoodtype = /obj/item/clothing/head/hooded/alloy_armor
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	resistance_flags = FIRE_PROOF | ACID_PROOF
	transparent_protection = HIDEGLOVES|HIDESUITSTORAGE|HIDEJUMPSUIT|HIDESHOES

/obj/item/clothing/suit/hooded/alloy_armor/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/clothing/suit/hooded/alloy_armor/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/clothing/suit/hooded/alloy_armor/process(delta_time)
	var/new_slowdown = 0
	if(!lavaland_equipment_pressure_check(get_turf(src)))
		new_slowdown = 1.5

	if(slowdown != new_slowdown)
		slowdown = new_slowdown
		if(ismob(loc))
			var/mob/owner = loc
			owner.update_equipment_speed_mods()

/obj/item/clothing/head/hooded/alloy_armor
	name = "mechanical alloy helmet"
	desc = "A helmet made out of mechanical alloy and bat sinew. \n Resonance effect can be also activated using middle click."
	icon_state = "mechanical_alloy"
	armor = list(MELEE = 45, BULLET = 20, LASER = 10, ENERGY = 10, BOMB = 50, BIO = 60, FIRE = 100, ACID = 100)
	clothing_flags = SNUG_FIT
	resistance_flags = FIRE_PROOF | ACID_PROOF
	actions_types = list(/datum/action/item_action/alloy_resonance)
	var/resonance_cooldown

/obj/item/clothing/head/hooded/alloy_armor/proc/resonate(mob/user, atom/targeting)
	if(resonance_cooldown > world.time)
		to_chat(span_warning("[src] is not ready to resonate yet!"))
		return

	if(!lavaland_equipment_pressure_check(get_turf(user)))
		to_chat(span_warning("Pressure here is too high for [src] to resonate with enough power!"))
		return

	user.visible_message(span_warning("[user]'s [src] starts resonating and emitting a high-pitched sound!"))
	playsound(get_turf(user), 'sound/effects/clockcult_gateway_disrupted.ogg', 100, TRUE)
	resonance_cooldown = world.time + RESONANCE_COOLDOWN

	for(var/mob/living/simple_animal/target in view(9, get_turf(user)))
		if(faction_check(user.faction, target.faction))
			continue
		target.Stun(1 SECONDS + 0.15 SECONDS * (9 - get_dist(user, target)))
		target.throw_at(get_edge_target_turf(user, get_dir(user, get_step_away(target, user))), 2, 1, user)
		if(ishostile(target))
			var/mob/living/simple_animal/hostile/hostile = target
			hostile.ranged_cooldown += 1 SECONDS + 0.15 SECONDS * (9 - get_dist(user, target))

	for(var/obj/projectile/proj in view(9, get_turf(user)))
		proj.fire(get_angle(user, proj))

/obj/item/clothing/head/hooded/alloy_armor/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HEAD)
		RegisterSignal(user, COMSIG_MOB_MIDDLECLICKON, .proc/resonate)

/obj/item/clothing/head/hooded/alloy_armor/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_MIDDLECLICKON)

#undef RESONANCE_COOLDOWN
