/**
 *
 * Time Crystal
 *
 * A sentient amber crystal with time manipulation abilities.
 * It actually has only one attack actually related to time but I don't care.
 *
 * Attack patterns:
 * 1. 3 small orbiting crystals are released. These crystals will float to random positions around the main crystal and shoot player with amber shards until destroyed.
 * 2. Time Crystal start shooting wave-like patterns of amber shards in all directions
 * 3. Crystal shoots a few slow chronospheres that stop time around them after a few seconds.
 * 4. If distance between crystal and player is too big crystal dashes towards the player, leaving timestop fields behind itself
 * 5. Crystal falls into the ground and starts preparing a powerful laser attack. After it's ready, it shoots into the sky and several player-following lasers are created, damaging everything in their path.
 *
 * Melee attack just shoots amber shards point-blank
 *
 * It's loot consists of an Amber Core(which is used for crafting) and either Crystal Gauntlets that allow you to shoot crystal shards with your hands OR a one-use crystal fruit that completely aheals you and gives you 50% damage reduction for 30 seconds.
 * When killed with crusher it also drops a crystal shard that stuns and makes creatures vunerable for a bit.
 *
 * Intended difficulty: Hard
 *
 */

#define AMBER_TIMESTOP_RANGE 1
#define AMBER_TIMESTOP_DURATION 3 SECONDS

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal
	name = "time crystal"
	desc = "An enourmous crystal of amber with strange time-manipulating properties."
	health = 2500
	maxHealth = 2500
	icon_state = "crystal"
	icon_living = "crystal"
	icon_dead = "crystal_dropped"
	friendly_verb_continuous = "stares down"
	friendly_verb_simple = "stare down"
	icon = 'icons/mob/jungle/amber_crystal_big.dmi'
	faction = list("boss", "jungle")
	speak_emote = list("vibrates")
	mob_biotypes = MOB_MINERAL | MOB_BEAST | MOB_EPIC
	speed = 14
	move_to_delay = 14
	ranged = TRUE
	ranged_cooldown_time = 20
	aggro_vision_range = 18

	loot = list(/obj/effect/spawner/lootdrop/time_crystal, /obj/item/amber_core)
	crusher_loot = list(/obj/effect/spawner/lootdrop/time_crystal, /obj/item/amber_core, /obj/item/crusher_trophy/crystal_shard)

	wander = FALSE
	gps_name = "Vibrating Signal"
	del_on_death = FALSE
	light_color = LIGHT_COLOR_ORANGE

	var/has_orbiting = TRUE
	var/dropped = FALSE
	var/beaming = FALSE

	var/obj/effect/temp_visual/crystal_killbeam/beam

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/SpinAnimation(speed = 10, loops = -1, clockwise = 1, segments = 3, parallel = TRUE) //No spins from rocket hits
	return

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/Move()
	if(dropped)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/update_icon(updates)
	if(dropped)
		if(beaming)
			icon_state = "crystal_beam"
		else
			icon_state = "crystal_dropped"
	else
		if(has_orbiting)
			icon_state = "crystal"
		else
			icon_state = "crystal_single"

	if(stat == DEAD)
		icon_state = "crystal_dropped"

	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/shoot_projectile(turf/marker, set_angle, proj_type = /obj/projectile/crystal_shards, homing = FALSE, turf/startloc = get_turf(src))
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/obj/projectile/proj = new proj_type(startloc)
	proj.preparePixelProjectile(marker, startloc)
	proj.firer = src

	if(target)
		proj.original = target
		if(proj.homing)
			proj.homing_target = target

	proj.fire(set_angle)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/spiral_shoot(negative = pick(TRUE, FALSE), counter_start = 8)
	var/turf/start_turf = get_step(src, pick(GLOB.alldirs))
	var/counter = counter_start
	playsound(get_turf(src), 'sound/effects/ethereal_revive_fail.ogg', 100)
	for(var/i in 1 to 48)
		if(negative)
			counter--
		else
			counter++

		if(counter > 16)
			counter = 1

		if(counter < 1)
			counter = 16
		shoot_projectile(start_turf, counter * 22.5, proj_type = /obj/projectile/crystal_shards/slow)
		SLEEP_CHECK_DEATH(1)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/AttackingTarget(atom/attacked_target) //It just point-blanks you in melee
	shoot_projectile(get_turf(attacked_target), proj_type = pick(/obj/projectile/amber_crystal, /obj/projectile/chronosphere))

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/chronospheres()
	var/turf/start_turf = get_step(src, pick(GLOB.alldirs))
	playsound(get_turf(src), 'sound/effects/ethereal_revive.ogg', 100) //Fits pretty well I guess?
	for(var/i in 1 to 5)
		shoot_projectile(start_turf, i * 72, proj_type = /obj/projectile/chronosphere, homing = TRUE)
		SLEEP_CHECK_DEATH(3)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/OpenFire()
	anger_modifier =  (1 -(health / maxHealth)) * 100
	ranged_cooldown = world.time + 2 SECONDS

	if(beaming || dropped)
		return

	if(get_dist(src, target) > 10)
		do_dash()
		return

	if(prob(clamp((140 - anger_modifier), 10, 30)))
		if(get_dist(src, target) > 3) //No point-blank chronospheres
			chronospheres()
			return
	else
		spawn_turrets()
		return

	if(prob(25))
		drop_n_beam()
		return

	if(prob(80))
		spiral_shoot()
	else
		do_dash()

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/spawn_turrets()
	if(!has_orbiting)
		return

	has_orbiting = FALSE
	update_icon()

	var/list/possible_turfs = list()
	for(var/turf/open/possible_turret in range(6, src))
		if(!possible_turret.is_blocked_turf_ignore_climbable())
			possible_turfs.Add(possible_turret)

	var/mob/living/simple_animal/hostile/jungle/crystal_turret/turret = new(pick_n_take(possible_turfs))
	turret.GiveTarget(turret)

	turret = new /mob/living/simple_animal/hostile/jungle/crystal_turret/second(pick_n_take(possible_turfs))
	turret.GiveTarget(turret)

	turret = new /mob/living/simple_animal/hostile/jungle/crystal_turret/third(pick_n_take(possible_turfs))
	turret.GiveTarget(turret)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/drop_n_beam()
	if(has_orbiting)
		spawn_turrets()

	dropped = TRUE
	ranged_cooldown = world.time + 15 SECONDS //We don't want other attacks while beaming
	update_icon()
	flick("crystal_drop", src)
	SLEEP_CHECK_DEATH(3)
	flick("crystal_beam_telegraph", src)
	addtimer(CALLBACK(src, .proc/start_beaming), 3 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/start_beaming()
	beaming = TRUE
	update_icon()
	flick("crystal_beam_start", src)

	beam = new(get_turf(target))
	beam.target = target

	addtimer(CALLBACK(src, .proc/stop_beaming), 10 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/stop_beaming()
	beaming = FALSE
	update_icon()
	flick("crystal_beam_stop", src)
	if(beam && !QDELETED(beam))
		qdel(beam)
	addtimer(CALLBACK(src, .proc/get_the_fuck_up), 3 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/get_the_fuck_up()
	dropped = FALSE
	update_icon()
	flick("crystal_fly_up", src)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/do_dash()
	if(dropped)
		return

	ranged_cooldown = world.time + 60 SECONDS //Just in case
	add_atom_colour("#DE9E41", TEMPORARY_COLOUR_PRIORITY)

	while(get_dist(src, target) > 6)
		var/turf/next_turf = get_step(get_turf(src), get_dir(src, target))
		Move(next_turf)
		var/chronofield = make_field(/datum/proximity_monitor/advanced/timestop/amber, list("current_range" = 1, "host" = src, "immune" = list(src), "check_anti_magic" = FALSE, "check_holy" = FALSE))
		QDEL_IN(chronofield, AMBER_TIMESTOP_DURATION)
		SLEEP_CHECK_DEATH(1)

	ranged_cooldown = world.time + 2 SECONDS
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)

/obj/projectile/crystal_shards
	name = "crystal shards"
	icon_state = "crystal_spray"
	damage = 10
	damage_type = BRUTE
	speed = 2

/obj/projectile/crystal_shards/slow
	speed = 4

/obj/projectile/crystal_shards/on_hit(atom/target)
	if(istype(target, /mob/living/simple_animal/hostile/megafauna/jungle/time_crystal) || istype(target, /mob/living/simple_animal/hostile/jungle/crystal_turret))
		return PROJECTILE_PIERCE_PHASE
	. = ..()

/obj/projectile/amber_crystal
	name = "amber crystal"
	icon_state = "crystal1"
	damage = 30
	damage_type = BRUTE
	speed = 2

/obj/projectile/amber_crystal/Initialize()
	. = ..()

/obj/projectile/amber_crystal/on_hit(atom/target)
	if(istype(target, /mob/living/simple_animal/hostile/megafauna/jungle/time_crystal) || istype(target, /mob/living/simple_animal/hostile/jungle/crystal_turret))
		return PROJECTILE_PIERCE_PHASE
	. = ..()

/obj/projectile/amber_crystal/second
	icon_state = "crystal2"

/obj/projectile/amber_crystal/third
	icon_state = "crystal3"

/obj/projectile/chronosphere
	name = "chronosphere"
	icon_state = "chrono"
	damage = 0
	nodamage = TRUE
	speed = 6 //You can outrun it
	range = 24
	homing = TRUE

/obj/projectile/chronosphere/on_range()
	new /obj/effect/temp_visual/chronoexplosion(get_turf(src))
	new /obj/effect/timestop/amber(get_turf(src), AMBER_TIMESTOP_RANGE, AMBER_TIMESTOP_DURATION, list(firer))
	. = ..()


/obj/projectile/chronosphere/on_hit(atom/target)
	if(istype(target, /mob/living/simple_animal/hostile/megafauna/jungle/time_crystal) || istype(target, /mob/living/simple_animal/hostile/jungle/crystal_turret))
		return PROJECTILE_PIERCE_PHASE

	new /obj/effect/timestop/amber(get_turf(target), AMBER_TIMESTOP_RANGE, AMBER_TIMESTOP_DURATION, list(firer))
	. = ..()

/obj/projectile/crystal
	name = "crystal shard"
	icon = 'icons/mob/jungle/amber_crystal.dmi'
	icon_state = "tiny"
	damage = 10
	damage_type = BRUTE
	var/pressure_decreased = FALSE

/obj/projectile/crystal/Initialize()
	icon_state = "[initial(icon_state)][rand(1,8)]"
	update_icon()
	. = ..()

/obj/projectile/crystal/on_hit(atom/target)
	if(istype(target, /mob/living/simple_animal/hostile/megafauna/jungle/time_crystal) || istype(target, /mob/living/simple_animal/hostile/jungle/crystal_turret))
		return PROJECTILE_PIERCE_PHASE
	. = ..()

/obj/projectile/crystal/prehit_pierce(atom/target)
	. = ..()
	if(. == PROJECTILE_PIERCE_PHASE)
		return

	if(!lavaland_equipment_pressure_check(get_turf(target)) && !pressure_decreased)
		name = "weakened [name]"
		damage = damage * 0.25
		pressure_decreased = TRUE

/obj/effect/timestop/amber
	invisibility = 101
	sound_on_del = FALSE

/obj/effect/timestop/amber/timestop()
	target = get_turf(src)
	chronofield = make_field(/datum/proximity_monitor/advanced/timestop/amber, list("current_range" = freezerange, "host" = src, "immune" = immune, "check_anti_magic" = check_anti_magic, "check_holy" = check_holy))
	QDEL_IN(src, duration)

/datum/proximity_monitor/advanced/timestop/amber
	var/list/immune_types = list(/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal,
								 /obj/projectile/crystal_shards,
								 /obj/projectile/amber_crystal,
								 /obj/projectile/chronosphere,
								 /mob/living/simple_animal/hostile/jungle/crystal_turret,
								 /obj/effect/temp_visual/crystal_killbeam)

/datum/proximity_monitor/advanced/timestop/amber/freeze_atom(atom/movable/A)
	if(isprojectile(A))
		var/obj/projectile/proj = A
		if(proj.firer in immune)
			return FALSE
	for(var/immune_type in immune_types)
		if(istype(A, immune_type))
			return
	. = ..()

/datum/proximity_monitor/advanced/timestop/amber/into_the_negative_zone(atom/A)
	A.add_atom_colour("#DE9E41", TEMPORARY_COLOUR_PRIORITY)

/datum/proximity_monitor/advanced/timestop/amber/escape_the_negative_zone(atom/A)
	A.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)

/mob/living/simple_animal/hostile/jungle/crystal_turret
	name = "floating crystal"
	desc = "A floating chunk of amber. That's odd."
	icon = 'icons/mob/jungle/amber_crystal.dmi'
	icon_state = "crystal_first"
	icon_living = "crystal_first"
	mob_biotypes = MOB_MINERAL | MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_ICON
	ranged = 1
	ranged_cooldown_time = 1 SECONDS
	projectiletype = /obj/projectile/amber_crystal
	projectilesound = 'sound/effects/ethereal_revive_fail.ogg'
	speak_emote = list("vibrates")
	maxHealth = 600
	health = 600
	vision_range = 9
	aggro_vision_range = 9
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	del_on_death = TRUE

/mob/living/simple_animal/hostile/jungle/crystal_turret/Move() //Does not move by itself
	return

/mob/living/simple_animal/hostile/jungle/crystal_turret/AttackingTarget(atom/attacked_target)
	Shoot(attacked_target)

/mob/living/simple_animal/hostile/jungle/crystal_turret/second
	icon_state = "crystal_second"
	icon_living = "crystal_second"
	rapid = 3
	projectiletype = /obj/projectile/crystal_shards

/mob/living/simple_animal/hostile/jungle/crystal_turret/third
	icon_state = "crystal_third"
	icon_living = "crystal_third"
	ranged_cooldown_time = 3 SECONDS
	projectiletype = /obj/projectile/chronosphere

/obj/effect/temp_visual/crystal_killbeam
	name = "energy beam"
	icon_state = "crystal_ray"
	icon = 'icons/mob/jungle/amber_crystal_big.dmi'
	duration = 10 SECONDS
	randomdir = FALSE
	var/mob/living/target

/obj/effect/temp_visual/crystal_killbeam/Initialize()
	. = ..()
	START_PROCESSING(SSfastprocess, src)

/obj/effect/temp_visual/crystal_killbeam/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	. = ..()

/obj/effect/temp_visual/crystal_killbeam/process()
	if(!target)
		return

	if(get_turf(src) == get_turf(target))
		target.adjustFireLoss(10)
		target.adjust_fire_stacks(0.2)
		target.IgniteMob()
		playsound(target, 'sound/weapons/sear.ogg', 50, TRUE)
		to_chat(target, span_userdanger("[src] burns you!"))
	else
		Move(get_step(get_turf(src), get_dir(src, target)))

/obj/item/crusher_trophy/crystal_shard
	name = "crystal shard"
	desc = "A bright orange amber shard. Suitable as a trophy for a kinetic crusher."
	icon_state = "crystal_shard"
	denied_type = /obj/item/crusher_trophy/crystal_shard
	bonus_value = 4

/obj/item/crusher_trophy/crystal_shard/effect_desc()
	return "mark detonation to stun creatures and make them more vunerable for a bit"

/obj/item/crusher_trophy/crystal_shard/on_mark_detonation(mob/living/target, mob/living/user)
	if(ishostile(target))
		var/mob/living/simple_animal/hostile/H = target
		H.Stun(bonus_value)
		H.damage_coeff = list(BRUTE = 1.2, BURN = 1.2, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
		sleep(bonus_value * 5)
		H.damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)

/obj/item/clothing/gloves/crystal
	name = "crystal gauntlets"
	desc = "Odd-shaped crystals that look like they would fit your hands"
	icon_state = "crystal_gauntlets"
	inhand_icon_state = "crystal_gauntlets"
	strip_delay = 40
	equip_delay_other = 20
	cold_protection = HANDS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	heat_protection = HANDS
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	armor = list(MELEE = 15, BULLET = 25, LASER = 15, ENERGY = 15, BOMB = 100, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)

/obj/item/clothing/gloves/crystal/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_GLOVES)
		RegisterSignal(user, COMSIG_HUMAN_EARLY_UNARMED_ATTACK, .proc/shootie)
	else
		UnregisterSignal(user, COMSIG_HUMAN_EARLY_UNARMED_ATTACK)

/obj/item/clothing/gloves/crystal/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_HUMAN_EARLY_UNARMED_ATTACK)

/obj/item/clothing/gloves/crystal/proc/shootie(mob/living/carbon/human/H, atom/A, proximity)
	SIGNAL_HANDLER

	var/obj/projectile/proj = new /obj/projectile/crystal(get_turf(H))
	proj.preparePixelProjectile(get_turf(A), get_turf(H))
	proj.firer = H
	proj.original = A
	H.changeNext_move(CLICK_CD_RAPID)

	proj.fire()

/obj/effect/spawner/lootdrop/time_crystal
	name = "time crystal loot spawner"
	loot = list(/obj/item/clothing/gloves/crystal = 2, /obj/item/crystal_fruit = 1)

/obj/item/crystal_fruit //One-use full heal and buff for 30 seconds. When you're truely fucked.
	name = "crystal fruit"
	desc = "Legends say that eating this fruit will give you \"awesome power\". It's not specified what these are."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "crystal_fruit"

/obj/item/crystal_fruit/attack_self(mob/user)
	if(!iscarbon(user))
		return

	var/mob/living/carbon/eater = user
	if(eater.is_mouth_covered())
		to_chat(eater, span_warning("You can't eat [src] with your mouth covered!")) //Minor inconvinience just because I am a dickhead

	eater.revive(full_heal = TRUE, admin_revive = TRUE)
	eater.apply_status_effect(STATUS_EFFECT_CRYSTAL_HEART)
	playsound(eater, 'sound/magic/staff_healing.ogg', 20, TRUE)
	to_chat(eater, span_notice("You feel great!"))
	qdel(src)

/obj/effect/temp_visual/chronoexplosion
	icon = 'icons/effects/96x96.dmi'
	icon_state = "sphere_explosion"
	pixel_x = -32
	pixel_y = -32
	duration = 3

/obj/item/amber_core
	name = "amber core"
	desc = "Strange crystal made of very dense amber found in one of Time Crystals."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "amber_core"
	w_class = WEIGHT_CLASS_TINY
	force = 0
	throwforce = 0

#undef AMBER_TIMESTOP_RANGE
#undef AMBER_TIMESTOP_DURATION
