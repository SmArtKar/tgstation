#define DASH_COOLDOWN 5 SECONDS
#define DASH_COOLDOWN_HIT 7 SECONDS //So you can still be killed by chaining a few attacks
#define DASH_RANGE_PERFECT 3
#define DASH_RANGE 5

#define MAX_CULMINATION_CHARGE 100
#define CHARGE_DRAINED_PER_SECOND 3

/obj/item/clothing/head/hooded/cloakhood/demonslayer
	name = "helmet of the demonslayer"
	icon_state = "demonslayer"
	desc = "A helmet fashioned from parts of everything you've killed along your path through this jungle."
	armor = list(MELEE = 30, BULLET = 20, LASER = 20, ENERGY = 20, BOMB = 50, BIO = 50, FIRE = 100, ACID = 100)
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL | SNUG_FIT
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	flash_protect = FLASH_PROTECTION_WELDER
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH | PEPPERPROOF
	resistance_flags = FIRE_PROOF | ACID_PROOF | FREEZE_PROOF | LAVA_PROOF
	actions_types = list(/datum/action/item_action/culmination)
	var/culmination_charge = 0
	var/culmination_active = FALSE
	var/list/tracked_mobs = list()

/obj/item/clothing/head/hooded/cloakhood/demonslayer/examine()
	. = ..()
	. += span_notice("Culmination is [culmination_charge]% charged.")

/obj/item/clothing/head/hooded/cloakhood/demonslayer/process(delta_time)
	. = ..()
	if(culmination_active)
		culmination_charge = clamp(culmination_charge - CHARGE_DRAINED_PER_SECOND * delta_time, 0, MAX_CULMINATION_CHARGE)
		if(culmination_charge == 0)
			if(ishuman(loc))
				end_culmination(loc)

/obj/item/clothing/head/hooded/cloakhood/demonslayer/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/clothing/head/hooded/cloakhood/demonslayer/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/clothing/head/hooded/cloakhood/demonslayer/dropped(mob/user)
	. = ..()
	end_culmination(user)

/obj/item/clothing/head/hooded/cloakhood/demonslayer/proc/culmination(mob/living/carbon/human/user)
	to_chat(user, span_warning("You start the Culmination."))
	playsound(user, 'sound/magic/ethereal_enter.ogg', 50)
	culmination_active = TRUE

	for(var/shoot_dir in GLOB.cardinals)
		var/turf/target = get_step(get_turf(user), shoot_dir)
		shoot_projectile(target)

/obj/item/clothing/head/hooded/cloakhood/demonslayer/proc/shoot_projectile(turf/marker, set_angle)
	if(!ishuman(loc))
		return
	var/mob/living/carbon/human/owner = loc
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/turf/startloc = get_turf(owner)
	var/obj/projectile/P = new /obj/projectile/demonslayer_orb(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = owner
	P.fire(set_angle)

/obj/item/clothing/head/hooded/cloakhood/demonslayer/proc/end_culmination(mob/living/carbon/human/user)
	if(!culmination_active)
		return
	culmination_active = FALSE
	if(QDELETED(user))
		return
	to_chat(user, span_warning("You finish the Culmination."))
	playsound(user, 'sound/magic/summonitems_generic.ogg', 50)

/obj/item/clothing/suit/hooded/cloak/demonslayer //Basically ancient AI modsuit but cooler, as it's dashes are instant, are automatically performed to prevent getting hit and you can also cast two cool spells. If you can make it then you're totally worthy, as it's very unlikely someone will defeat all bosses in one round without dying
	name = "armor of the demonslayer"
	desc = "A suit of armor fashioned from parts of everything you've killed along your path through this jungle."
	icon_state = "demonslayer"
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/mining_scanner, /obj/item/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator, /obj/item/pickaxe, /obj/item/spear, /obj/item/kinetic_crusher)
	armor = list(MELEE = 30, BULLET = 20, LASER = 20, ENERGY = 20, BOMB = 50, BIO = 50, FIRE = 100, ACID = 100) ///Armor is not that high but instead you get dashes to dodge the attack
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/demonslayer
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	resistance_flags = FIRE_PROOF | ACID_PROOF | FREEZE_PROOF | LAVA_PROOF
	transparent_protection = HIDEGLOVES|HIDESUITSTORAGE|HIDEJUMPSUIT|HIDESHOES

	var/dash_cooldown = 0
	var/dash_active = FALSE
	var/obj/effect/proc_holder/spell/chasers

/obj/item/clothing/suit/hooded/cloak/demonslayer/Initialize(mapload)
	. = ..()
	chasers = new /obj/effect/proc_holder/spell/targeted/demonic_chasers()
	START_PROCESSING(SSobj, src)

/obj/item/clothing/suit/hooded/cloak/demonslayer/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/clothing/suit/hooded/cloak/demonslayer/process()
	if(dash_cooldown < world.time && dash_active == FALSE)
		dash_active = TRUE
		if(ishuman(loc))
			balloon_alert(loc, "demonic dash recharged")


/obj/item/clothing/suit/hooded/cloak/demonslayer/proc/can_activate()
	if(!ishuman(loc))
		return FALSE

	var/mob/living/carbon/human/owner = loc
	if(owner.get_item_by_slot(ITEM_SLOT_OCLOTHING) != src)
		return FALSE

	if(owner.get_item_by_slot(ITEM_SLOT_HEAD) != hood)
		return FALSE
	return TRUE

/obj/item/clothing/suit/hooded/cloak/demonslayer/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(dash_cooldown > world.time || !can_activate())
		dash_cooldown = world.time + DASH_COOLDOWN_HIT //You need to not get hit in 7 seconds for it to work
		return FALSE

	var/turf/destination_holder = get_turf(owner)
	var/turf/destination

	for(var/i = 1 to DASH_RANGE)
		destination_holder = get_step(destination_holder, owner.dir)
		if(i > DASH_RANGE_PERFECT && destination)
			break
		if(istype(destination_holder, /turf/closed)) //So it doesn't phase you through walls
			break
		if(!destination_holder.is_blocked_turf())
			destination = destination_holder

	if(!destination)
		return FALSE

	var/possible_destinations = list()
	for(var/turf/target in range(1, destination))
		if(!target.is_blocked_turf())
			possible_destinations += target

	destination = pick(possible_destinations)

	playsound(get_turf(owner), "sparks", 50, TRUE)
	new /obj/effect/temp_visual/dir_setting/cult/phase/demonslayer/out(get_turf(owner), owner.dir)

	if(do_teleport(owner, destination, channel = TELEPORT_CHANNEL_CULT)) //Technically it uses a cult demon stone soooo
		new /obj/effect/temp_visual/dir_setting/cult/phase/demonslayer(destination, owner.dir)
		playsound(destination, 'sound/effects/phasein.ogg', 25, TRUE)
		playsound(destination, "sparks", 50, TRUE)
		dash_active = FALSE
		dash_cooldown = world.time + DASH_COOLDOWN
		return TRUE
	return FALSE

/obj/effect/temp_visual/dir_setting/cult/phase/demonslayer
	icon = 'icons/effects/effects.dmi'
	name = "phase glow"
	duration = 7
	icon_state = "demonslayer_in"
	layer = ABOVE_ALL_MOB_LAYER

/obj/effect/temp_visual/dir_setting/cult/phase/demonslayer/out
	icon_state = "demonslayer_out"

/obj/item/clothing/suit/hooded/cloak/demonslayer/ToggleHood()
	. = ..()
	if(hood_up)
		if(!ishuman(loc))
			return
		var/mob/living/carbon/human/owner = loc
		RegisterSignal(owner, COMSIG_MOB_MIDDLECLICKON, .proc/phase)
		if(owner.mind)
			owner.mind.AddSpell(chasers)

/obj/item/clothing/suit/hooded/cloak/demonslayer/RemoveHood()
	. = ..()
	if(!ishuman(loc))
		return

	var/mob/living/carbon/human/owner = loc
	UnregisterSignal(owner, COMSIG_MOB_MIDDLECLICKON)
	if(owner.mind)
		owner.mind.RemoveSpell(chasers)

/obj/item/clothing/suit/hooded/cloak/demonslayer/proc/phase(mob/living/carbon/owner, atom/target)
	if(dash_cooldown > world.time || !can_activate())
		return

	var/turf/destination

	var/counter = 0
	for(var/turf/destination_holder in get_line(get_turf(owner), get_turf(target)))
		if(istype(destination_holder, /turf/closed) || counter > DASH_RANGE)
			break
		if(!destination_holder.is_blocked_turf())
			destination = destination_holder

		counter += 1

	if(!destination)
		return

	var/possible_destinations = list()
	for(var/turf/target_turf in range(1, destination))
		if(!target_turf.is_blocked_turf())
			possible_destinations += target_turf

	destination = pick(possible_destinations)

	playsound(get_turf(owner), "sparks", 50, TRUE)
	new /obj/effect/temp_visual/dir_setting/cult/phase/demonslayer/out(get_turf(owner), owner.dir)

	if(do_teleport(owner, destination, channel = TELEPORT_CHANNEL_CULT)) //Technically it uses a cult demon stone soooo
		new /obj/effect/temp_visual/dir_setting/cult/phase/demonslayer(destination, owner.dir)
		playsound(destination, 'sound/effects/phasein.ogg', 25, TRUE)
		playsound(destination, "sparks", 50, TRUE)
		dash_cooldown = world.time + DASH_COOLDOWN
		dash_active = FALSE

/obj/effect/temp_visual/hierophant/chaser/demonslayer
	icon_state = "demonic_blast_warning_quick"
	speed = 2

/obj/effect/temp_visual/hierophant/chaser/demonslayer/make_blast()
	new /obj/effect/temp_visual/demonic_blast/demonslayer(loc, caster)

/obj/effect/proc_holder/spell/targeted/demonic_chasers
	name = "Summon Chasers"
	desc = "Summon demonic chasers that will go after all enemies in view."
	action_icon_state = "demonic_chasers"
	action_background_icon_state = "bg_demon"
	clothes_req = FALSE
	school = SCHOOL_FORBIDDEN
	invocation = "R'HA NRAT"
	invocation_type = INVOCATION_SHOUT
	charge_max = 20 SECONDS
	range = -1
	include_user = TRUE

/obj/effect/proc_holder/spell/targeted/demonic_chasers/cast(list/targets, mob/user = usr)
	. = ..()
	for(var/mob/living/target in range(8, get_turf(user)))
		if(target == user || user.faction_check_mob(target) || target.stat == DEAD)
			continue
		new /obj/effect/temp_visual/hierophant/chaser/demonslayer(get_turf(user), user, target)

/obj/projectile/demonslayer_orb
	name = "blood orb"
	icon_state = "blood_orb"
	damage = 0
	nodamage = TRUE
	speed = 16

/obj/projectile/demonslayer_orb/proc/shoot_projectile(turf/marker, set_angle)
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/turf/startloc = get_turf(src)
	var/obj/projectile/P = new /obj/projectile/demonic_energy/nohuman(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = firer
	P.fire(set_angle)

/obj/projectile/demonslayer_orb/fire(angle, atom/direct_target)
	. = ..()
	addtimer(CALLBACK(src, .proc/spiral_shoot), 2 SECONDS)

/obj/projectile/demonslayer_orb/on_hit(atom/target, blocked, pierce_hit) //So you can't face eat them
	set_angle(rand(0, 360))
	return BULLET_ACT_FORCE_PIERCE

/obj/projectile/demonslayer_orb/proc/spiral_shoot(negative = pick(TRUE, FALSE))
	STOP_PROCESSING(SSprojectiles, src) //So it doesn't move while shooting
	var/turf/start_turf = get_step(src, pick(GLOB.alldirs))
	for(var/counter in 0 to 8)
		if(negative)
			counter--
		else
			counter++
		shoot_projectile(start_turf, counter * 11.25)
		shoot_projectile(start_turf, counter * 11.25 + 90)
		shoot_projectile(start_turf, counter * 11.25 + 180)
		shoot_projectile(start_turf, counter * 11.25 + 270)
		sleep(1)
	qdel(src)

/datum/action/item_action/culmination
	name = "Culmination"
	desc = "Increase melee speed and melee armor for a short amount of time, as well as shoots four blood orbs that split into more projectiles for area-wide damage."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "berserk_mode"
	background_icon_state = "bg_demon"

/datum/action/item_action/culmination/Trigger()
	if(istype(target, /obj/item/clothing/head/hooded/cloakhood/demonslayer))
		var/obj/item/clothing/head/hooded/cloakhood/demonslayer/demonslayer = target
		if(demonslayer.culmination_active)
			to_chat(owner, span_warning("Culmination is already active!"))
			return
		if(demonslayer.culmination_charge < MAX_CULMINATION_CHARGE)
			to_chat(owner, span_warning("You don't have a full charge."))
			return
		demonslayer.culmination(owner)
		return
	..()


#undef DASH_COOLDOWN
#undef DASH_RANGE
#undef DASH_COOLDOWN_HIT
#undef DASH_RANGE_PERFECT

#undef MAX_CULMINATION_CHARGE
#undef CHARGE_DRAINED_PER_SECOND
