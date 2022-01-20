#define AMBER_TIMESTOP_RANGE 2
#define AMBER_TIMESTOP_DURATION 3 SECONDS
#define CRYSTAL_TURRET_HEALING -20

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
	speak_emote = list("vibrates")
	mob_biotypes = MOB_MINERAL | MOB_BEAST | MOB_EPIC
	speed = 14
	ranged = TRUE
	ranged_cooldown_time = 20
	aggro_vision_range = 18
	former_target_vision_range = 18

	achievement_type = /datum/award/achievement/boss/time_crystal_kill
	crusher_achievement_type = /datum/award/achievement/boss/time_crystal_crusher
	score_achievement_type = /datum/award/score/time_crystal_score

	loot = list(/obj/item/amber_core)
	common_loot = list(/obj/effect/spawner/random/boss/time_crystal)
	common_crusher_loot = list(/obj/effect/spawner/random/boss/time_crystal, /obj/item/crusher_trophy/crystal_shard)

	wander = FALSE
	gps_name = "Vibrating Signal"
	del_on_death = FALSE
	light_color = LIGHT_COLOR_ORANGE

	var/has_orbiting = TRUE
	var/dropped = FALSE
	var/beaming = FALSE

	var/list/killer_beams = list()
	var/list/crystal_turrets = list()

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_MOVE_FLYING, INNATE_TRAIT)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/Move()
	if(dropped)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/death(gibbed, list/force_grant)
	for(var/obj/effect/temp_visual/energy_killbeam/crystal/beam in killer_beams)
		killer_beams -= beam
		if(beam && !QDELETED(beam))
			qdel(beam)
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

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/shoot_projectile(turf/marker, set_angle, proj_type = /obj/projectile/colossus/crystal_shards, homing = FALSE, turf/startloc = get_turf(src))
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/obj/projectile/proj = new proj_type(startloc)
	proj.preparePixelProjectile(marker, startloc)
	proj.firer = src

	if(target)
		proj.original = target
		if(proj.homing)
			proj.homing_target = target

	if(proj_type == /obj/projectile/chronosphere)
		var/obj/projectile/chronosphere/chronosphere = proj
		chronosphere.master_crystal = src

	proj.fire(set_angle)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/spiral_shoot(negative = pick(TRUE, FALSE), counter_start = 8)
	if(check_proj_immunity(target)) //Oh boi
		do_dash()
		chronospheres()
		return
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
		shoot_projectile(start_turf, counter * 22.5, proj_type = /obj/projectile/colossus/crystal_shards/slow)
		SLEEP_CHECK_DEATH(1, src)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/AttackingTarget(atom/attacked_target) //It just point-blanks you in melee
	OpenFire()

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/chronospheres()
	var/obj/effect/temp_visual/decoy/decoy = new /obj/effect/temp_visual/decoy(loc, src)
	animate(decoy, alpha = 0, transform = matrix() * 2, time = 6)
	SLEEP_CHECK_DEATH(6, src)
	var/turf/start_turf = get_step(src, pick(GLOB.alldirs))
	playsound(get_turf(src), 'sound/effects/ethereal_revive.ogg', 100) //Fits pretty well I guess?
	for(var/i in 1 to 5)
		shoot_projectile(start_turf, i * 72, proj_type = /obj/projectile/chronosphere, homing = TRUE)
		SLEEP_CHECK_DEATH(3, src)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/OpenFire()
	anger_modifier =  (1 -(health / maxHealth)) * 100
	ranged_cooldown = world.time + 2 SECONDS

	if(beaming || dropped)
		return

	if(get_dist(src, target) > 7)
		do_dash()
		return

	if(prob(min(30 + anger_modifier / 3, 50)) && get_dist(src, target) > 2)
		chronospheres()
	else
		spawn_turrets()

	if(prob(max(0, 25 - anger_modifier * 3)))
		drop_n_beam()
		return

	if(prob(clamp(60  - anger_modifier * 0.75, 15, 80)))
		spiral_shoot()
	else
		do_dash()

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/spawn_turrets()
	if(!has_orbiting)
		return

	has_orbiting = FALSE
	update_icon()

	var/list/possible_turfs = list()
	var/list/view_turfs = view(6, src)
	for(var/turf/open/possible_turret in range(6, src))
		if(!possible_turret.is_blocked_turf_ignore_climbable() && (possible_turret in view_turfs))
			possible_turfs.Add(possible_turret)

	var/mob/living/simple_animal/hostile/jungle/crystal_turret/turret = new(pick_n_take(possible_turfs))
	turret.GiveTarget(turret)
	turret.master_crystal = src
	crystal_turrets += turret

	turret = new /mob/living/simple_animal/hostile/jungle/crystal_turret/second(pick_n_take(possible_turfs))
	turret.GiveTarget(turret)
	turret.master_crystal = src
	crystal_turrets += turret

	turret = new /mob/living/simple_animal/hostile/jungle/crystal_turret/third(pick_n_take(possible_turfs))
	turret.GiveTarget(turret)
	turret.master_crystal = src
	crystal_turrets += turret

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/drop_n_beam()
	if(has_orbiting)
		spawn_turrets()

	dropped = TRUE
	ranged_cooldown = world.time + 15 SECONDS //We don't want other attacks while beaming
	update_icon()
	flick("crystal_drop", src)
	SLEEP_CHECK_DEATH(3, src)
	flick("crystal_beam_telegraph", src)
	addtimer(CALLBACK(src, .proc/start_beaming), 3 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/start_beaming()
	beaming = TRUE
	update_icon()
	flick("crystal_beam_start", src)

	for(var/mob/living/targeting in former_targets)
		var/obj/effect/temp_visual/energy_killbeam/crystal/beam = new(get_turf(targeting), targeting)
		killer_beams += beam

	addtimer(CALLBACK(src, .proc/stop_beaming), 10 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/stop_beaming()
	beaming = FALSE
	update_icon()
	flick("crystal_beam_stop", src)
	for(var/obj/effect/temp_visual/energy_killbeam/crystal/beam in killer_beams)
		killer_beams -= beam
		if(beam && !QDELETED(beam))
			qdel(beam)
	addtimer(CALLBACK(src, .proc/get_back_up), 3 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/get_back_up()
	dropped = FALSE
	update_icon()
	flick("crystal_fly_up", src)

/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/proc/do_dash()
	if(dropped)
		return

	ranged_cooldown = world.time + 60 SECONDS //Just in case
	add_atom_colour("#DE9E41", TEMPORARY_COLOUR_PRIORITY)

	while(get_dist(src, target) > 1)
		var/turf/next_turf = get_step(get_turf(src), get_dir(src, target))
		new /obj/effect/timestop/time_crystal(get_turf(src), 1, AMBER_TIMESTOP_DURATION, list(src))
		Move(next_turf)
		SLEEP_CHECK_DEATH(1, src)

	ranged_cooldown = world.time + 2 SECONDS
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)

/obj/projectile/colossus/crystal_shards
	name = "crystal shards"
	icon_state = "crystal_spray"
	damage = 10
	damage_type = BRUTE
	speed = 2

/obj/projectile/colossus/crystal_shards/slow
	speed = 4

/obj/projectile/colossus/crystal_shards/on_hit(atom/target)
	if(istype(target, /mob/living/simple_animal/hostile/megafauna/jungle/time_crystal) || istype(target, /mob/living/simple_animal/hostile/jungle/crystal_turret))
		return BULLET_ACT_FORCE_PIERCE
	. = ..()

/obj/projectile/colossus/amber_crystal
	name = "amber crystal"
	icon_state = "crystal1"
	damage = 30
	damage_type = BRUTE
	speed = 2

/obj/projectile/colossus/amber_crystal/Initialize()
	. = ..()

/obj/projectile/colossus/amber_crystal/on_hit(atom/target)
	if(istype(target, /mob/living/simple_animal/hostile/megafauna/jungle/time_crystal) || istype(target, /mob/living/simple_animal/hostile/jungle/crystal_turret))
		return BULLET_ACT_FORCE_PIERCE
	. = ..()

/obj/projectile/colossus/amber_crystal/second
	icon_state = "crystal2"

/obj/projectile/colossus/amber_crystal/third
	icon_state = "crystal3"

/obj/projectile/chronosphere
	name = "chronosphere"
	icon_state = "chrono"
	damage = 0
	nodamage = TRUE
	speed = 6 //You can outrun it
	range = 24
	homing = TRUE
	var/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/master_crystal

/obj/projectile/chronosphere/on_range()
	new /obj/effect/temp_visual/chronoexplosion(get_turf(src))
	new /obj/effect/timestop/time_crystal(get_turf(src), AMBER_TIMESTOP_RANGE, AMBER_TIMESTOP_DURATION, (master_crystal.crystal_turrets + master_crystal))
	. = ..()


/obj/projectile/chronosphere/on_hit(atom/target)
	if(istype(target, /mob/living/simple_animal/hostile/megafauna/jungle/time_crystal) || istype(target, /mob/living/simple_animal/hostile/jungle/crystal_turret))
		return BULLET_ACT_FORCE_PIERCE

	new /obj/effect/timestop/time_crystal(get_turf(target), AMBER_TIMESTOP_RANGE, AMBER_TIMESTOP_DURATION, (master_crystal.crystal_turrets + master_crystal))
	. = ..()

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
	projectiletype = /obj/projectile/colossus/amber_crystal
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
	var/mob/living/simple_animal/hostile/megafauna/jungle/time_crystal/master_crystal

/mob/living/simple_animal/hostile/jungle/crystal_turret/Life(delta_time, times_fired)
	. = ..()
	if(DT_PROB(30, delta_time))
		master_crystal.adjustHealth(CRYSTAL_TURRET_HEALING)
		new /obj/effect/temp_visual/heal(get_turf(master_crystal), "#DE9E41")

/mob/living/simple_animal/hostile/jungle/crystal_turret/Move() //Does not move by itself
	return

/mob/living/simple_animal/hostile/jungle/crystal_turret/AttackingTarget(atom/attacked_target)
	Shoot(attacked_target)

/mob/living/simple_animal/hostile/jungle/crystal_turret/death(gibbed)
	master_crystal.crystal_turrets -= src
	. = ..()

/mob/living/simple_animal/hostile/jungle/crystal_turret/second
	icon_state = "crystal_second"
	icon_living = "crystal_second"
	rapid = 3
	projectiletype = /obj/projectile/colossus/crystal_shards

/mob/living/simple_animal/hostile/jungle/crystal_turret/third
	icon_state = "crystal_third"
	icon_living = "crystal_third"
	ranged_cooldown_time = 4 SECONDS
	projectiletype = /obj/projectile/chronosphere

/mob/living/simple_animal/hostile/jungle/crystal_turret/third/Shoot(atom/targeted_atom)
	var/atom/target_from = GET_TARGETS_FROM(src)
	if(QDELETED(targeted_atom) || targeted_atom == target_from.loc || targeted_atom == target_from )
		return
	var/turf/startloc = get_turf(target_from)
	face_atom(targeted_atom)
	var/obj/projectile/chronosphere/chronosphere = new(startloc)
	playsound(src, projectilesound, 100, TRUE)
	chronosphere.starting = startloc
	chronosphere.firer = src
	chronosphere.fired_from = src
	chronosphere.yo = targeted_atom.y - startloc.y
	chronosphere.xo = targeted_atom.x - startloc.x
	chronosphere.master_crystal = master_crystal
	chronosphere.original = targeted_atom
	chronosphere.preparePixelProjectile(targeted_atom, src)
	chronosphere.fire()
	return chronosphere

/obj/item/crusher_trophy/crystal_shard
	name = "crystal shard"
	desc = "A bright orange amber shard. Suitable as a trophy for a kinetic crusher."
	icon_state = "crystal_shard"
	denied_type = list(/obj/item/crusher_trophy/crystal_shard, /obj/item/crusher_trophy/axe_head)
	bonus_value = 5

/obj/item/crusher_trophy/crystal_shard/effect_desc()
	return "mark detonation to stun creatures and make them more vunerable for a bit"

/obj/item/crusher_trophy/crystal_shard/on_mark_detonation(mob/living/target, mob/living/user)
	INVOKE_ASYNC(src, .proc/weaken_mob, target, user)

/obj/item/crusher_trophy/crystal_shard/proc/weaken_mob(mob/living/target, mob/living/user)
	if(isanimal(target))
		var/mob/living/simple_animal/H = target
		H.Stun(bonus_value)
		var/damage_coeffs = H.damage_coeff
		sleep(bonus_value * 6)
		H.damage_coeff = damage_coeffs

#define DEFENSIVE_STANCE_COOLDOWN 20 SECONDS
#define SHIELD_MOVE_COOLDOWN 4
#define MAX_STANCE_DURATION 50

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
	armor = list(MELEE = 15, BULLET = 25, LASER = 15, ENERGY = 15, BOMB = 100, BIO = 0, FIRE = 100, ACID = 100)
	slowdown = 0
	var/stance_duration = 0
	var/stance_cooldown = 0
	var/active = FALSE
	var/mutable_appearance/shield_effect

/obj/item/clothing/gloves/crystal/equipped(mob/living/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_GLOVES)
		RegisterSignal(user, COMSIG_MOB_ALTCLICKON, .proc/use_shield)
	else
		UnregisterSignal(user, COMSIG_MOB_ALTCLICKON)
		if(active)
			drop_shield(user)

/obj/item/clothing/gloves/crystal/process(delta_time)
	stance_duration += delta_time
	if(stance_duration > MAX_STANCE_DURATION && isliving(loc))
		var/mob/living/user = loc
		drop_shield(user)

/obj/item/clothing/gloves/crystal/dropped(mob/living/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_ALTCLICKON)
	if(active)
		drop_shield(user)

/obj/item/clothing/gloves/crystal/proc/use_shield(mob/living/source, atom/target)
	SIGNAL_HANDLER
	if(stance_cooldown > world.time)
		to_chat(source, span_warning("[src] haven't recovered from previous use yet! Wait [DisplayTimeText(stance_cooldown - world.time)] to use them again!"))
		return

	if(active)
		drop_shield(source)
	else
		activate_shield(source)

/obj/item/clothing/gloves/crystal/proc/activate_shield(mob/living/user)
	playsound(get_turf(user), 'sound/effects/ethereal_crystalization.ogg', 50)
	active = TRUE
	shield_effect = mutable_appearance('icons/effects/effects.dmi', "crystal_shield")
	shield_effect.pixel_x = user.pixel_x
	shield_effect.pixel_y = user.pixel_y
	user.overlays += shield_effect
	ADD_TRAIT(user, TRAIT_NOGUNS, TIME_CRYSTAL_TRAIT)
	user.next_move_modifier *= SHIELD_MOVE_COOLDOWN
	stance_duration = 0
	START_PROCESSING(SSobj, src)

	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		human_user.physiology.brute_mod *= 0.1
		human_user.physiology.burn_mod *= 0.1
		human_user.physiology.tox_mod *= 0.1
		human_user.physiology.oxy_mod *= 0.1
		human_user.physiology.clone_mod *= 0.1
		human_user.physiology.stamina_mod *= 0.1

	user.add_movespeed_modifier(/datum/movespeed_modifier/crystal_shield)

/obj/item/clothing/gloves/crystal/proc/drop_shield(mob/living/user)
	playsound(get_turf(user), 'sound/effects/ethereal_revive_fail.ogg', 100)
	active = FALSE
	user.overlays -= shield_effect
	QDEL_NULL(shield_effect)
	REMOVE_TRAIT(user, TRAIT_NOGUNS, TIME_CRYSTAL_TRAIT)
	user.next_move_modifier /= SHIELD_MOVE_COOLDOWN
	STOP_PROCESSING(SSobj, src)
	stance_cooldown = world.time + DEFENSIVE_STANCE_COOLDOWN
	stance_duration = 0

	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		human_user.physiology.brute_mod *= 10
		human_user.physiology.burn_mod *= 10
		human_user.physiology.tox_mod *= 10
		human_user.physiology.oxy_mod *= 10
		human_user.physiology.clone_mod *= 10
		human_user.physiology.stamina_mod *= 10

	user.remove_movespeed_modifier(/datum/movespeed_modifier/crystal_shield)

#undef DEFENSIVE_STANCE_COOLDOWN
#undef SHIELD_MOVE_COOLDOWN

/obj/effect/spawner/random/boss/time_crystal
	name = "time crystal loot spawner"
	loot = list(/obj/item/clothing/gloves/crystal = 1, /obj/item/crystal_fruit = 1, /obj/item/amber_hourglass = 1)

/obj/item/crystal_fruit
	name = "crystal fruit"
	desc = "A strange fruit made out of amber crystals. Legends say these increase"
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "crystal_fruit"

/obj/item/crystal_fruit/attack_self(mob/user)
	if(!iscarbon(user))
		return

	var/mob/living/carbon/eater = user

	eater.apply_status_effect(STATUS_EFFECT_CRYSTAL_HEART)
	playsound(eater, 'sound/magic/staff_healing.ogg', 20, TRUE)
	to_chat(eater, span_notice("You feel much tougher!"))
	qdel(src)

/obj/effect/temp_visual/chronoexplosion
	icon = 'icons/effects/96x96.dmi'
	icon_state = "sphere_explosion"
	pixel_x = -32
	pixel_y = -32
	duration = 3

/obj/item/amber_core
	name = "amber core"
	desc = "Strange core made of very dense amber that can be found in Time Crystals."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "amber_core"
	w_class = WEIGHT_CLASS_TINY
	force = 0
	throwforce = 0

/obj/effect/timestop/time_crystal
	alpha = 0
	chronofield_type = /datum/proximity_monitor/advanced/timestop/time_crystal

/datum/proximity_monitor/advanced/timestop/time_crystal/into_the_negative_zone(atom/A)
	A.add_atom_colour("#DE9E41", TEMPORARY_COLOUR_PRIORITY)

/obj/item/amber_hourglass
	name = "amber hourglass"
	desc = "Strange hourglass made out of amber. What could these do?"
	icon = 'icons/obj/hourglass.dmi'
	icon_state = "hourglass_idle"
	var/activated
	var/mob/living/carbon/owner
	var/turf/original_turf

	var/clone_loss
	var/tox_loss
	var/oxy_loss
	var/brain_loss
	var/list/datum/saved_bodypart/saved_bodyparts

/obj/item/amber_hourglass/attack_self(mob/user)
	. = ..()
	if(!iscarbon(user) || (owner && user != owner) || (!activated && HAS_TRAIT(user, TRAIT_AMBER_REWIND)))
		to_chat(user, span_warning("Strange force prevents you from flipping the [src]!"))
		return

	to_chat(user, span_notice("You flip the [src]."))
	flick("hourglass_flip", src)
	if(!activated)
		owner = user
		add_filter("amber_hourglass_outline", 9, list("type" = "outline", "color" = "#DE9E41", "size" = 1))
		original_turf = get_turf(owner)

		clone_loss = owner.getCloneLoss()
		tox_loss = owner.getToxLoss()
		oxy_loss = owner.getOxyLoss()
		brain_loss = owner.getOrganLoss(ORGAN_SLOT_BRAIN)
		saved_bodyparts = owner.save_bodyparts()

		activated = TRUE
		ADD_TRAIT(owner, TRAIT_AMBER_REWIND, TIME_CRYSTAL_TRAIT)
	else
		rewind()

/obj/item/amber_hourglass/equipped(mob/user, slot, initial)
	. = ..()
	if(user == owner)
		RegisterSignal(owner, COMSIG_MOB_STATCHANGE, .proc/on_statchange)

/obj/item/amber_hourglass/dropped(mob/user)
	. = ..()
	var/atom/recurs_loc = loc
	while(!ismob(loc) && !isturf(loc))
		recurs_loc = recurs_loc.loc

	if(recurs_loc != owner)
		UnregisterSignal(owner, COMSIG_MOB_STATCHANGE)

/obj/item/amber_hourglass/proc/on_statchange(mob/living/carbon/user, new_stat)
	SIGNAL_HANDLER
	if(new_stat > CONSCIOUS && new_stat < DEAD && activated)
		rewind()

/obj/item/amber_hourglass/proc/rewind()

	var/mob/living/simple_animal/hostile/megafauna/jungle/attacker
	for(var/mob/living/simple_animal/hostile/megafauna/jungle/mega in GLOB.megafauna)
		if(mega.target == owner || ((owner in mega.former_targets) && get_dist(owner, mega) <= mega.aggro_vision_range))
			attacker = mega
			break

	if(!attacker)
		return

	to_chat(owner, span_notice("You remember a time not so long ago..."))
	sleep(3)
	playsound(get_turf(owner), 'sound/effects/ethereal_revive_fail.ogg', 100)
	var/area/destination_area = original_turf.loc
	if(destination_area.area_flags & NOTELEPORT)
		to_chat(owner, span_warning("For some reason, your head aches and fills with mental fog when you try to think of where you were... It feels like you're now going against some dull, unstoppable universal force."))
	else
		owner.forceMove(original_turf)
		owner.setCloneLoss(clone_loss)
		owner.setToxLoss(tox_loss)
		owner.setOxyLoss(oxy_loss)
		owner.setOrganLoss(ORGAN_SLOT_BRAIN, brain_loss)
		owner.apply_saved_bodyparts(saved_bodyparts)
	to_chat(owner, span_warning("[src] shatters as it fulfils it's purpose!"))
	REMOVE_TRAIT(owner, TRAIT_AMBER_REWIND, TIME_CRYSTAL_TRAIT)
	qdel(src)

/obj/effect/temp_visual/energy_killbeam/crystal
	duration = 11 SECONDS

#undef AMBER_TIMESTOP_RANGE
#undef AMBER_TIMESTOP_DURATION
#undef CRYSTAL_TURRET_HEALING
