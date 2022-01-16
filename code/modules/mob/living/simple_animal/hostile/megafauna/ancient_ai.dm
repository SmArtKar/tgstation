#define FLOOR_SHOCK_LENGTH 10 SECONDS
#define DRONE_RESPAWN_COOLDOWN 10 SECONDS
#define LASER_FLOWER_LENGTH 2 SECONDS
#define LASER_FLOWER_BULLETHELL_LENGTH 6 SECONDS
#define SERVER_ARMOR_PER_MINER 10

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai
	name = "ancient AI"
	desc = "An ancient Nanotrasen AI that was hacked and reprogrammed to kill everything in sight."
	health = 1000
	maxHealth = 1000

	icon = 'icons/obj/jungle/64x96.dmi'
	icon_state = "ai_complex_offline"
	icon_living = "ai_complex_offline"
	icon_dead = "ai_complex_broken"

	mob_biotypes = MOB_ROBOTIC | MOB_EPIC

	friendly_verb_continuous = "crackles at"
	friendly_verb_simple = "crackles at"
	speak_emote = list("beeps")

	melee_damage_lower = 0
	melee_damage_upper = 0

	gps_name = "Scrambled Signal"
	deathmessage = "lets out a horrible screeching sound as it's monitors turn off forever... "
	deathsound = 'sound/voice/ed209_20sec.ogg'

	faction = list("jungle", "boss", "silicon")

	robust_searching = TRUE
	vision_range = 13
	aggro_vision_range = 13
	former_target_vision_range = 16
	stat_attack = HARD_CRIT
	ranged = TRUE
	ranged_message = null
	ranged_ignores_vision = TRUE

	achievement_type = /datum/award/achievement/boss/ancient_ai_kill
	crusher_achievement_type = /datum/award/achievement/boss/ancient_ai_crusher
	score_achievement_type = /datum/award/score/ancient_ai_score

	loot = list(/obj/item/malf_upgrade)
	common_loot = list(/obj/effect/spawner/random/boss/ancient_ai, /obj/item/experimental_components, /obj/effect/spawner/random/boss/ancient_ai/valuable)
	common_crusher_loot = list(/obj/effect/spawner/random/boss/ancient_ai, /obj/item/experimental_components, /obj/effect/spawner/random/boss/ancient_ai/valuable, /obj/item/crusher_trophy/ai_core)
	spawns_minions = TRUE

	var/rocket_type = /obj/projectile/bullet/a84mm/ancient/at
	var/shield_toggled = TRUE
	var/list/server_list = list()
	var/servers = 0
	var/initial_servers = 0
	var/bullethell = FALSE
	var/floorshock = FALSE
	var/list/drones = list()

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/update_armor()
	var/enemies = 0
	for(var/mob/living/possible_enemy in range(aggro_vision_range, get_turf(src)))
		if((ishuman(possible_enemy) || possible_enemy.mind) && (possible_enemy in former_targets))
			enemies += 1

	enemies -= 1 //So we don't gain armor from a single guy

	if(enemies <= 1)
		return

	damage_coeff = initial(damage_coeff)
	for(var/coeff in damage_coeff)
		damage_coeff[coeff] = clamp(damage_coeff[coeff] - 0.15 * enemies, 0.2, 1)

	for(var/obj/machinery/ancient_server/server in server_list)
		server.armor = initial(server.armor)
		server.armor[MELEE] = min(server.armor[MELEE] + SERVER_ARMOR_PER_MINER, 80)
		server.armor[BOMB] = min(server.armor[BOMB] + SERVER_ARMOR_PER_MINER, 95)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/SpinAnimation(speed = 10, loops = -1, clockwise = 1, segments = 3, parallel = TRUE) //No spins from rocket hits
	return

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/Initialize()
	. = ..()
	update_appearance()
	status_flags |= GODMODE

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/Move()
	return

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/GiveTarget(new_target)
	. = ..()
	if(new_target)
		if(icon_state == "ai_complex_offline")
			icon_state = "ai_complex_online"
			update_icon()
			playsound(src, 'sound/ai/default/aimalf.ogg', 50, TRUE)
			activate_servers()
		flick("ai_complex_syndicate", src)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/update_overlays()
	. = ..()
	if(shield_toggled)
		. += "ai_shield"

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/activate_turrets(turret_target = target, turret_amount = 4)
	var/list/working_turrets = list()

	for(var/obj/machinery/porta_turret/ancient_ai/turret in range(12, src))
		if(turret.master_ai != src)
			turret.master_ai = src

		if((turret.machine_stat & BROKEN) || turret.being_used)
			continue

		if(!(target in view(6, turret)))
			continue

		working_turrets.Add(turret)

	for(var/i = 1 to turret_amount)
		var/obj/machinery/porta_turret/ancient_ai/turret = pick_n_take(working_turrets)
		if(turret)
			turret.showShoot(turret_target)
			sleep(5)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/activate_floor_shock()
	if(floorshock)
		return

	for(var/turf/open/floor/engine/ecute/floor in range(12, src))
		if(prob(50))
			floor.turn_on(TRUE)
			addtimer(CALLBACK(floor, /turf/open/floor/engine/ecute.proc/turn_on, FALSE), FLOOR_SHOCK_LENGTH)

	floorshock = TRUE
	addtimer(CALLBACK(src, .proc/deactivate_floor_shock), FLOOR_SHOCK_LENGTH)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/deactivate_floor_shock()
	floorshock = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/spawn_drones()
	var/list/drone_spawners = list()
	for(var/obj/machinery/rogue_drone_spawner/spawner in range(12, src))
		drone_spawners += spawner

	for(var/i = 1 to max(3 + LAZYLEN(former_targets) * 3 - LAZYLEN(drones), rand(3, 2 + LAZYLEN(former_targets) * 3)))
		var/obj/machinery/rogue_drone_spawner/spawner = pick_n_take(drone_spawners)
		spawner.spawn_drone()

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/violent_smash()

	for(var/obj/machinery/giant_arm_holder/arm in range(12, src))
		if(prob(70))
			INVOKE_ASYNC(arm, /obj/machinery/giant_arm_holder/.proc/violent_smash)
			continue
		arm.violent_smash()
		sleep(3)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/activate_servers()
	for(var/obj/machinery/ancient_server/server in range(12, src))
		if(!(server in server_list))
			server_list.Add(server)
			servers += 1
			initial_servers += 1

		if(server.icon_state == "ai_server_inactive_dusted")
			server.icon_state = "ai_server_active_dusted"
			server.update_icon()
		server.master_ai = src

	for(var/obj/machinery/rogue_drone_spawner/drone_spawner in range(12, src))
		drone_spawner.master_ai = src

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/laser_flower()
	bullethell = TRUE
	for(var/obj/machinery/laser_flower/turret in range(12, src))
		if(prob(50))
			turret.toggle_with_warning(TRUE)

	addtimer(CALLBACK(src, .proc/deactivate_flowers), LASER_FLOWER_LENGTH)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/deactivate_flowers()
	bullethell = FALSE
	for(var/obj/machinery/laser_flower/turret in range(12, src))
		turret.toggle(FALSE)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/laser_flower_bullethell()
	bullethell = TRUE
	for(var/obj/machinery/laser_flower/turret in range(12, src))
		turret.toggle_with_warning(TRUE)

	addtimer(CALLBACK(src, .proc/deactivate_flowers), LASER_FLOWER_BULLETHELL_LENGTH)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/server_broken()
	servers -= 1
	playsound(src, 'sound/voice/ed209_20sec.ogg', 100, FALSE)

	shield_toggled = FALSE
	status_flags &= ~GODMODE
	update_appearance()

	if(servers > 0)
		addtimer(CALLBACK(src, .proc/activate_shield), 7.5 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/activate_shield()
	shield_toggled = TRUE
	status_flags |= GODMODE
	update_appearance()

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/OpenFire()
	if(servers > 0)
		anger_modifier = clamp((initial_servers / servers) - (shield_toggled ? 1 : 0), 0, 6)
	else
		anger_modifier = 6
	ranged_cooldown = world.time + ((4.5 - anger_modifier / 3) SECONDS) / (shield_toggled ? 1 : 2)

	for(var/mob/living/possible_target in former_targets)
		if(get_dist(src, possible_target) <= 2 && !floorshock)
			activate_floor_shock()
			break

	if(anger_modifier == 6)
		rocket_type = /obj/projectile/bullet/a84mm/ancient/heavy
	else if(anger_modifier > 3)
		rocket_type = /obj/projectile/bullet/a84mm/ancient
	else if(anger_modifier > 0)
		rocket_type = /obj/projectile/bullet/a84mm/he/ancient
	else
		rocket_type = /obj/projectile/bullet/a84mm/ancient/at

	if(prob(anger_modifier * 10) && !bullethell)
		if(prob(anger_modifier * 5))
			laser_flower_bullethell()
			return
		laser_flower()

	if(prob(anger_modifier * 5 + 20) && LAZYLEN(drones) < 3 + LAZYLEN(former_targets) * 3)
		spawn_drones()
	else if(prob(anger_modifier * 5 + 20))
		INVOKE_ASYNC(src, .proc/violent_smash)

	sleep(2)

	if(prob(25))
		activate_floor_shock()
		if(!!bullethell)
			laser_flower()
	else
		activate_turrets()
		if(LAZYLEN(former_targets) > 1)
			for(var/mob/living/possible_target in (former_targets - target))
				activate_turrets(possible_target, rand(2, 4))

/obj/machinery/rogue_drone_spawner
	name = "drone pedestal"
	desc = "Some sort of platform with a drone shell ontop of it. It's all dusted and dirty."
	icon = 'icons/obj/jungle/ancient_ai.dmi'
	icon_state = "drone_spawner"

	max_integrity = 200
	armor = list(MELEE = 75, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 65, BIO = 100, FIRE = 100, ACID = 100)
	density = TRUE
	anchored = TRUE

	var/has_drone = TRUE
	var/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/master_ai

/obj/machinery/rogue_drone_spawner/ex_act(severity, target)
	return

/obj/machinery/rogue_drone_spawner/proc/spawn_drone()
	if(!has_drone || LAZYLEN(master_ai.drones) >= 3 + LAZYLEN(master_ai.former_targets) * 3)
		return

	icon_state = "[initial(icon_state)]_empty"
	update_icon()
	flick("[initial(icon_state)]_activate", src)
	has_drone = FALSE
	var/mob/living/simple_animal/hostile/jungle/rogue_drone/drone = new(get_turf(src))
	drone.master_ai = master_ai
	drone.GiveTarget(pick(master_ai.former_targets))
	addtimer(CALLBACK(src, .proc/recreate_drone), DRONE_RESPAWN_COOLDOWN)

/obj/machinery/rogue_drone_spawner/proc/recreate_drone()
	if(has_drone)
		return

	has_drone = TRUE
	icon_state = initial(icon_state)
	update_icon()

/obj/machinery/laser_flower
	name = "laser flower turret"
	desc = "A monstrous combination of 8 laser turrets, designed to constantly shoot laser bolts, flooding the entire area with them."
	icon = 'icons/obj/jungle/ancient_ai.dmi'
	icon_state = "laser_flower"

	max_integrity = 200
	armor = list(MELEE = 75, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 65, BIO = 100, FIRE = 100, ACID = 100)
	density = TRUE
	anchored = TRUE

	var/active = FALSE
	var/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/master_ai

/obj/machinery/laser_flower/ex_act(severity, target)
	return

/obj/machinery/laser_flower/update_icon()
	if(machine_stat & BROKEN)
		icon_state = "[initial(icon_state)]_broken"
	else
		icon_state = "[initial(icon_state)][active ? "_active" : ""]"
	. = ..()

/obj/machinery/laser_flower/proc/toggle_with_warning(activate = TRUE)
	new /obj/effect/temp_visual/turret_telegraph(get_turf(src))
	addtimer(CALLBACK(src, .proc/toggle, activate), 10)

/obj/machinery/laser_flower/proc/toggle(activate = TRUE)
	if(active == activate)
		return

	active = activate
	update_icon()

	if(active)
		START_PROCESSING(SSprocessing, src)
	else
		STOP_PROCESSING(SSprocessing, src)

/obj/machinery/laser_flower/process()
	if(!active)
		STOP_PROCESSING(SSprocessing, src)
		return

	for(var/direction in GLOB.alldirs)
		var/turf/target = get_step(src, direction)
		shoot_projectile(target)

/obj/machinery/laser_flower/proc/shoot_projectile(target)
	var/turf/startloc = get_turf(src)
	var/obj/projectile/P = new /obj/projectile/beam/laser/kinetic(startloc)
	P.preparePixelProjectile(target, startloc)
	P.firer = src
	if(master_ai && master_ai.target)
		P.original = master_ai.target
	P.fire(target)

/obj/projectile/beam/laser/kinetic
	name = "kinetic laser"
	icon_state = "emitter"
	wound_bonus = -100
	damage_type = BRUTE
	flag = BULLET	//I want armor to work against it at least a tiny bit
	damage = 20
	speed = 2
	eyeblur = 0

/obj/machinery/giant_arm_holder
	name = "giant manipulator mount"
	desc = "A huge giant arm mounted on a wall."
	icon = 'icons/obj/jungle/64x64.dmi'
	icon_state = "arm_holder"
	resistance_flags = INDESTRUCTIBLE
	density = TRUE
	anchored = TRUE

	pixel_y = -32
	base_pixel_y = -32

	var/default_angle = 45
	var/angle_1 = 45
	var/angle_2 = 45
	var/angle_3 = 45

/obj/machinery/giant_arm_holder/Initialize()
	. = ..()
	angle_1 = default_angle
	angle_2 = default_angle
	angle_3 = default_angle
	update_appearance()

/obj/machinery/giant_arm_holder/update_icon()
	cut_overlays()

	var/mutable_appearance/arm_1 = mutable_appearance('icons/obj/jungle/96x96.dmi', "arm_1")
	var/matrix/arm_1_matrix = matrix()
	arm_1_matrix.Turn(angle_1 - 45)
	arm_1_matrix.Translate(-16, -16)
	arm_1.transform = arm_1_matrix
	add_overlay(arm_1)


	var/mutable_appearance/arm_2 = mutable_appearance('icons/obj/jungle/96x96.dmi', "arm_2")
	var/matrix/arm_2_matrix = matrix()
	arm_2_matrix.Turn(angle_2 - 45)
	arm_2_matrix.Translate(round(cos(angle_1) * round(sqrt(42 ** 2 / 2)) * 2 + 1) - 16, round(-sin(angle_1) * round(sqrt(42 ** 2 / 2)) * 2) - 16)
	arm_2.transform = arm_2_matrix
	add_overlay(arm_2)


	var/mutable_appearance/arm_3 = mutable_appearance('icons/obj/jungle/96x96.dmi', "arm_3")
	var/matrix/arm_3_matrix = matrix()
	arm_3_matrix.Turn(angle_3 - 45)
	arm_3_matrix.Translate(round(cos(angle_1) * round(sqrt(42 ** 2 / 2)) * 2 + 1) - 16, round(-sin(angle_1) * round(sqrt(42 ** 2 / 2)) * 2) - 16)
	arm_3_matrix.Translate(round(cos(angle_2) * round(sqrt(42 ** 2 / 2)) * 2 + 1), round(-sin(angle_2) * round(sqrt(42 ** 2 / 2)) * 2))
	arm_3.transform = arm_3_matrix
	add_overlay(arm_3)

	. = ..()

/obj/machinery/giant_arm_holder/proc/violent_smash()
	var/speed = 5
	while(angle_1 < default_angle + 90)
		angle_1 = min(angle_1 + speed, default_angle + 90)
		angle_2 = min(angle_2 + round(speed / 2), default_angle + 90)
		angle_3 = min(angle_3 + round(speed / 2), default_angle + 90)
		speed = min(15, speed * 2)
		check_damage()
		update_icon()
		sleep(1)

	playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)

	while(angle_2 < default_angle + 90)
		angle_2 = min(angle_2 + speed, default_angle + 90)
		angle_3 = min(angle_3 + speed, default_angle + 90)
		check_damage()
		update_icon()
		sleep(1)

	speed = 2
	while(angle_1 > default_angle - 90)
		angle_1 = max(angle_1 - speed, default_angle - 90)
		angle_2 = max(angle_2 - round(speed / 2), default_angle - 90)
		angle_3 = max(angle_3 - round(speed / 2), default_angle - 90)
		speed = min(15, speed * 2)
		check_damage()
		update_icon()
		sleep(1)

	playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)

	while(angle_2 > default_angle - 90)
		angle_2 = max(angle_2 - speed, default_angle - 90)
		angle_3 = max(angle_3 - speed, default_angle - 90)
		check_damage()
		update_icon()
		sleep(1)

	while(angle_1 < default_angle)
		angle_1 = min(angle_1 + 3, default_angle)
		angle_2 = min(angle_2 + 3, default_angle)
		angle_3 = min(angle_3 + 3, default_angle)
		update_icon()
		sleep(1)


/obj/machinery/giant_arm_holder/proc/check_damage()
	var/first_joint_x = (cos(angle_1) * round(sqrt(42 ** 2 / 2)) * 2 + 1) / 32
	var/first_joint_y = (sin(angle_1) * round(sqrt(42 ** 2 / 2)) * 2) / 32
	var/second_joint_x = (cos(angle_2) * round(sqrt(42 ** 2 / 2)) * 2 + 1) / 32 + first_joint_x
	var/second_joint_y = (sin(angle_2) * round(sqrt(42 ** 2 / 2)) * 2) / 32 + first_joint_y

	if(first_joint_x - round(first_joint_x) > 0.35)
		first_joint_x = round(first_joint_x) + 1
	else
		first_joint_x = round(first_joint_x)

	if(first_joint_y - round(first_joint_y) > 0.35)
		first_joint_y = round(first_joint_y) + 1
	else
		first_joint_y = round(first_joint_y)

	if(second_joint_x - round(second_joint_x) > 0.35)
		second_joint_x = round(second_joint_x) + 1
	else
		second_joint_x = round(second_joint_x)

	if(second_joint_y - round(second_joint_y) > 0.35)
		second_joint_y = round(second_joint_y) + 1
	else
		second_joint_y = round(second_joint_y)

	var/turf/first_joint = locate(first_joint_x + x, y - first_joint_y, z)
	var/turf/second_joint = locate(second_joint_x + x, y - second_joint_y, z)
	var/list/already_thrown = list()

	for(var/turf/target_turf in (get_line(get_turf(src), first_joint) + get_line(first_joint, second_joint)))
		for(var/mob/living/target in target_turf)
			if(target in already_thrown)
				continue
			already_thrown.Add(target)
			to_chat(target, span_userdanger("You're hit by a giant manipulator!"))
			target.adjustBruteLoss(20)
			target.throw_at(get_edge_target_turf(target, get_dir(src, target)), 6, 3)

/obj/machinery/giant_arm_holder/dir_1
	default_angle = 225

/obj/machinery/giant_arm_holder/dir_4
	default_angle = -45

/obj/machinery/giant_arm_holder/dir_8
	default_angle = 135

/obj/machinery/ancient_server
	name = "ancient server"
	desc = "An ancient NT server hacked by the Syndicate. It's all dirty and dusted."
	icon = 'icons/obj/jungle/32x64.dmi'
	icon_state = "ai_server_inactive_dusted"
	density = TRUE
	anchored = TRUE

	max_integrity = 300
	armor = list(MELEE = 50, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 65, BIO = 0, FIRE = 100, ACID = 100)

	var/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/master_ai

/obj/machinery/ancient_server/attackby(obj/item/C, mob/user, params)
	. = ..()
	if(master_ai)
		master_ai.GiveTarget(user)

/obj/machinery/ancient_server/bullet_act(obj/projectile/Proj)
	if(master_ai && Proj.firer)
		master_ai.GiveTarget(Proj.firer)
	. = ..()

/obj/machinery/ancient_server/ex_act(severity, target)
	return

/obj/machinery/ancient_server/Destroy()
	master_ai.server_list.Remove(src)
	master_ai.server_broken()
	new /obj/structure/fluff/broken_ancient_server(get_turf(src))
	. = ..()

/obj/structure/fluff/broken_ancient_server
	name = "ancient server"
	desc = "An ancient NT server hacked by the Syndicate. It's broken and unrecoverable."
	icon = 'icons/obj/jungle/32x64.dmi'
	icon_state = "ai_server_broken_dusted"
	density = TRUE
	anchored = TRUE
	deconstructible = FALSE
	resistance_flags = INDESTRUCTIBLE


/obj/item/crusher_trophy/ai_core
	name = "AI core"
	desc = "A potato with a lot of wires in it. Suitable as a trophy for a kinetic crusher."
	icon_state = "ai_core"
	denied_type = list(/obj/item/crusher_trophy/ai_core, /obj/item/crusher_trophy/leaper_eye)
	var/drone_cooldown = 0

/obj/item/crusher_trophy/ai_core/effect_desc()
	return "ranged right click attacks to create a flying drone that attack your enemies with long-ranged destabilizing force"


/obj/item/crusher_trophy/ai_core/on_right_click(atom/target, mob/living/user)
	if(drone_cooldown > world.time)
		to_chat(user, span_warning("Wait [round((drone_cooldown - world.time) / 10)] more seconds before trying to create another drone!"))
		return

	if(isclosedturf(target) || isclosedturf(get_turf(target)))
		return

	drone_cooldown = world.time + 30 SECONDS

	var/mob/living/simple_animal/hostile/crusher_drone/drone = new(get_turf(user))
	drone.faction = list("[REF(user)]")
	drone.GiveTarget(target)
	drone.crusher = loc
	addtimer(CALLBACK(drone, /mob/living.proc/death), 25 SECONDS)

/mob/living/simple_animal/hostile/crusher_drone
	name = "V.0.R.T.X. drone"
	desc = "An outdated version of an automated defence drone that were made to help protect colonies from local fauna. This one is linked to a kinetic crusher and shares it's tropheys."
	icon = 'icons/mob/jungle/jungle_monsters.dmi'
	icon_state = "crusher_drone"
	icon_living = "crusher_drone"
	mob_biotypes = MOB_ROBOTIC
	combat_mode = FALSE
	stop_automated_movement = TRUE
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_plas" = 0, "max_plas" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	faction = list("neutral")
	maxHealth = 200
	health = 200
	obj_damage = 0
	melee_damage_lower = 0
	melee_damage_upper = 0
	del_on_death = TRUE
	deathmessage = "slowly floats down to the ground as it shuts down."
	deathsound = 'sound/voice/borg_deathsound.ogg'
	ranged = 1
	ranged_cooldown_time = 2 SECONDS
	var/obj/item/kinetic_crusher/crusher

/mob/living/simple_animal/hostile/crusher_drone/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/projectile/kinetic))
		return TRUE
	else if(istype(mover, /obj/projectile/destabilizer))
		return TRUE

/mob/living/simple_animal/hostile/crusher_drone/Move()
	return

/mob/living/simple_animal/hostile/crusher_drone/AttackingTarget(atom/attacked_target)
	Shoot(attacked_target)

/mob/living/simple_animal/hostile/crusher_drone/Shoot(mob/targeted)
	if(!targeted)
		return

	setDir(get_dir(src, targeted))

	var/obj/projectile/destabilizer/proj = new /obj/projectile/destabilizer/long_range(get_turf(src))
	for(var/obj/item/crusher_trophy/trophy in crusher.trophies)
		trophy.on_projectile_fire(proj, src)
	proj.preparePixelProjectile(get_turf(targeted), get_turf(src))
	proj.firer = src
	proj.hammer_synced = crusher
	playsound(src, 'sound/weapons/plasma_cutter.ogg', 100, TRUE)
	proj.fire()

/obj/projectile/destabilizer/long_range
	range = 9

/**
 *
 * Personal drone
 * When you throw experimental drone shell on the floor it activates and spawns a personal combat drone. It's pretty tanky, has neat damage, and in case it dies it can be repaired using a welder and some iron.
 *
 */

/obj/item/personal_drone_shell
	name = "experimental drone shell"
	desc = "An advanced drone shell with visible reinforcements and unusual toolset. A small sticker note on it says \"Throw on floor to activate\"."
	icon = 'icons/mob/drone.dmi'
	icon_state = "drone_repair_green_hat"

/obj/item/personal_drone_shell/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!..()) //not caught
		var/mob/living/simple_animal/hostile/jungle/rogue_drone/pet_drone/pet = new(get_turf(src))
		var/mob/thrown_by = thrownby?.resolve()
		if(thrown_by)
			pet.activate(thrown_by)
		qdel(src)

/// Bait Beacon

/obj/item/bait_beacon
	name = "bait beacon"
	desc = "A strange device with twin antennas that's designed to lure monsters to it."
	icon = 'icons/obj/device.dmi'
	icon_state = "battererburnt"
	throwforce = 5
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	flags_1 = CONDUCT_1
	obj_flags = CAN_BE_HIT
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	var/active = FALSE

/obj/item/bait_beacon/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_MOB_HATED, ROUNDSTART_TRAIT)

/obj/item/bait_beacon/attack_self(mob/living/carbon/user, flag = 0, emp = 0)
	if(!user)
		return

	active = FALSE
	deactivate()

/obj/item/bait_beacon/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(.)
		return .

	active = TRUE

	icon_state = "batterer"
	playsound(src, 'sound/effects/stealthoff.ogg', 50, TRUE, TRUE)

	for(var/mob/living/simple_animal/hostile/M in urange(10, src))
		M.GiveTarget(src)

	addtimer(CALLBACK(src, .proc/deactivate), 5 SECONDS)

/obj/item/bait_beacon/proc/deactivate()
	icon_state = "battererburnt"
	for(var/mob/living/simple_animal/hostile/M in urange(10, src))
		if(M.target == src)
			M.GiveTarget(null) // And as soon as it's disabled they lose interest in it

/obj/item/bait_beacon/attack_animal(mob/living/simple_animal/user, list/modifiers)
	if(active) //Disables it
		deactivate()
	. = ..()

/obj/item/experimental_components
	name = "experimental components"
	desc = "A bunch of dark-blue circuitry glued together for some reason. And they call that high tech?"
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "experimental_components"
	w_class = WEIGHT_CLASS_TINY
	force = 0
	throwforce = 0

/obj/structure/window/reinforced/survival_pod/indestructible
	resistance_flags = INDESTRUCTIBLE

/obj/item/organ/cyberimp/chest/thrusters/wingpack
	name = "implantable wingpack"
	desc = "A prototype wingpack which can be used anywhere if there's enough air. Sadly, due to high production cost and poor performance in high pressure this model has never made it to mass production."
	icon_state = "wingpack"
	base_icon_state = "wingpack"
	actions_types = list(/datum/action/item_action/organ_action/toggle/wingpack, /datum/action/item_action/organ_action/wingpack_rockets, /datum/action/item_action/organ_action/wingpack_ascend, /datum/action/item_action/organ_action/wingpack_choose_beacon)
	var/mutable_appearance/wingpack_overlay
	var/mutable_appearance/wingpack_underlay
	var/rocket_cooldown = 0
	var/ascend_cooldown = 0
	var/obj/structure/extraction_point/beacon

/obj/item/organ/cyberimp/chest/thrusters/wingpack/Insert(mob/living/carbon/thruster_owner, special = 0)
	. = ..()
	update_owner_overlays(thruster_owner)

/obj/item/organ/cyberimp/chest/thrusters/wingpack/Remove(mob/living/carbon/thruster_owner, special = 0)
	. = ..()
	thruster_owner.overlays -= wingpack_overlay
	thruster_owner.underlays -= wingpack_underlay
	qdel(wingpack_overlay)
	qdel(wingpack_underlay)

/obj/item/organ/cyberimp/chest/thrusters/wingpack/toggle(silent = FALSE)
	if(!on)
		if((organ_flags & ORGAN_FAILING))
			if(!silent)
				to_chat(owner, span_warning("Your wingpack seems to be broken!"))
			return FALSE
		if(allow_thrust(0.01))
			on = TRUE
			RegisterSignal(owner, COMSIG_MOVABLE_MOVED, .proc/move_react)
			RegisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE, .proc/pre_move_react)
			RegisterSignal(owner, COMSIG_MOVABLE_SPACEMOVE, .proc/spacemove_react)
			ADD_TRAIT(owner, TRAIT_MOVE_FLOATING, ANCIENT_AI_TRAIT)
			if(!silent)
				to_chat(owner, span_notice("You turn your wingpack on."))
			update_owner_overlays(overlay_modifier = "-on")
	else
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
		UnregisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE)
		UnregisterSignal(owner, COMSIG_MOVABLE_SPACEMOVE)
		REMOVE_TRAIT(owner, TRAIT_MOVE_FLOATING, ANCIENT_AI_TRAIT)
		if(!silent)
			to_chat(owner, span_notice("You turn your wingpack off."))
		on = FALSE
		update_owner_overlays()
	update_appearance()

/obj/item/organ/cyberimp/chest/thrusters/wingpack/proc/update_owner_overlays(mob/living/carbon/thruster_owner = owner, overlay_modifier = "")
	if(wingpack_overlay || wingpack_underlay)
		thruster_owner.overlays -= wingpack_overlay
		thruster_owner.underlays -= wingpack_underlay
		qdel(wingpack_overlay)
		qdel(wingpack_underlay)

	wingpack_underlay = mutable_appearance('icons/effects/effects.dmi', "wingpack-underlay[overlay_modifier]")
	wingpack_overlay = mutable_appearance('icons/effects/effects.dmi', "wingpack-overlay[overlay_modifier]")

	thruster_owner.overlays += wingpack_overlay
	thruster_owner.underlays += wingpack_underlay

/obj/item/organ/cyberimp/chest/thrusters/wingpack/proc/rocket_strike()
	playsound(get_turf(owner), 'sound/machines/terminal_on.ogg', 50, TRUE)
	playsound(get_turf(owner), 'sound/mecha/mechmove03.ogg', 50, TRUE)
	var/strike_successfull = FALSE
	var/strikes_left = 3
	for(var/mob/living/simple_animal/hostile/possible_target in view(9, owner))
		if(owner.faction_check_mob(possible_target) || possible_target.stat == DEAD)
			continue

		strikes_left -= 1

		podspawn(list(
			"target" = get_turf(possible_target),
			"style" = STYLE_MISSILE,
			"effectMissile" = TRUE,
			"explosionSize" = list(0,1,1,2),
			delays = list(POD_TRANSIT = 0, POD_FALLING = 2, POD_OPENING = 0, POD_LEAVING = 0)
		))
		strike_successfull = TRUE
		playsound(get_turf(owner), 'sound/weapons/gun/general/rocket_launch.ogg', 50, TRUE)
		if(!strikes_left)
			break
		sleep(3)

	if(strike_successfull)
		to_chat(owner, span_notice("Overlord Smartstrike activated. Targets acquired. Launching rockets."))
		rocket_cooldown = world.time + 15 SECONDS
	else
		to_chat(owner, span_notice("Overlord Smartstrike activated. Failed to acquire targets. Aborting launch."))
		rocket_cooldown = world.time + 5 SECONDS

/obj/item/organ/cyberimp/chest/thrusters/wingpack/proc/ascend() //escape all nasty situations with ease using your wingpack
	ascend_cooldown = world.time + 10 MINUTES
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, ANCIENT_AI_TRAIT)
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, ANCIENT_AI_TRAIT)
	if(owner.buckled)
		owner.buckled.unbuckle_mob(owner, TRUE)
	update_owner_overlays(overlay_modifier = "-ascend")
	var/prev_pixel_z = owner.pixel_z

	playsound(get_turf(owner), 'sound/vehicles/rocketlaunch.ogg', 100, TRUE)
	animate(owner, pixel_z = prev_pixel_z + 96, time = 40, easing = ELASTIC_EASING)
	owner.spin(40, 4)
	sleep(40)

	animate(owner, pixel_z = 512, time = 15)
	owner.spin(15, 1)
	sleep(15)

	var/list/flooring_near_beacon = list()
	for(var/turf/open/floor in orange(1, beacon))
		flooring_near_beacon += floor
	owner.forceMove(pick(flooring_near_beacon))

	animate(owner, pixel_z = prev_pixel_z + 96, time = 15)
	owner.spin(15, 1)
	sleep(15)

	animate(src, pixel_z = prev_pixel_z, time = 20, flags = ANIMATION_END_NOW)
	owner.spin(40, 4)
	sleep(40)

	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, ANCIENT_AI_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, ANCIENT_AI_TRAIT)
	update_owner_overlays(overlay_modifier = "-on")

/datum/action/item_action/organ_action/toggle/wingpack
	background_icon_state = "bg_tech_blue"

	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_IMMOBILE|AB_CHECK_LYING

/datum/action/item_action/organ_action/toggle/wingpack/Trigger()
	if(istype(target, /obj/item/organ/cyberimp/chest/thrusters/wingpack))
		var/obj/item/organ/cyberimp/chest/thrusters/wingpack/wingpack = target
		if(!do_after(owner, 2 SECONDS, owner, timed_action_flags = IGNORE_HELD_ITEM))
			to_chat(owner, span_warning("You have to stand still to toggle your wingpack!"))
			return

		playsound(get_turf(owner), 'sound/mecha/mechmove03.ogg', 50, TRUE)
		wingpack.toggle()

/datum/action/item_action/organ_action/wingpack_rockets
	name = "Activate Overlord Smartstrike"
	desc = "Activate your wingpack's built-in rocket launchers, raining hellfire from the sky."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	background_icon_state = "bg_tech_blue"

	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_IMMOBILE|AB_CHECK_LYING

/datum/action/item_action/organ_action/wingpack_rockets/Trigger()
	if(istype(target, /obj/item/organ/cyberimp/chest/thrusters/wingpack))
		var/obj/item/organ/cyberimp/chest/thrusters/wingpack/wingpack = target
		if(wingpack.rocket_cooldown > world.time)
			to_chat(owner, span_warning("Your wingpack hasn't yet recovered from previous Overlord Smartstrike. Wait [DisplayTimeText(wingpack.rocket_cooldown - world.time)] before using it again!"))
			return

		if(!wingpack.on)
			to_chat(owner, span_warning("Your wingpack has to be on to use Overlord Smartstrike!"))
			return

		wingpack.rocket_strike()

/datum/action/item_action/organ_action/wingpack_ascend
	name = "Begin Ascend"
	desc = "Overload your thrusters to ascend into the air and escape any nasty situation."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "wingpack_ascend"
	background_icon_state = "bg_tech_blue"

	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_IMMOBILE|AB_CHECK_LYING

/datum/action/item_action/organ_action/wingpack_ascend/Trigger()
	if(istype(target, /obj/item/organ/cyberimp/chest/thrusters/wingpack))
		var/obj/item/organ/cyberimp/chest/thrusters/wingpack/wingpack = target
		if(wingpack.ascend_cooldown > world.time)
			to_chat(owner, span_warning("Your wingpack hasn't yet recovered from previous thruster overload. Wait [DisplayTimeText(wingpack.ascend_cooldown - world.time)] before using it again!"))
			return

		if(!wingpack.on)
			to_chat(owner, span_warning("Your wingpack has to be on to begin ascension!"))
			return

		if(!wingpack.beacon)
			to_chat(owner, span_warning("You don't have a beacon selected!"))
			return

		wingpack.ascend()

/datum/action/item_action/organ_action/wingpack_choose_beacon
	name = "Select Extraction Point"
	desc = "Select an extraction point to which your wingpack will deliver you when you overload it."
	icon_icon = 'icons/obj/fulton.dmi'
	button_icon_state = "extraction_point"
	background_icon_state = "bg_tech_blue"

/datum/action/item_action/organ_action/wingpack_choose_beacon/Trigger()
	if(istype(target, /obj/item/organ/cyberimp/chest/thrusters/wingpack))
		var/obj/item/organ/cyberimp/chest/thrusters/wingpack/wingpack = target
		var/list/possible_beacons = list()
		for(var/obj/structure/extraction_point/extraction_point as anything in GLOB.total_extraction_beacons)
			possible_beacons += extraction_point

		if(!length(possible_beacons))
			to_chat(owner, span_warning("There are no extraction beacons availible!"))
			return
		else
			var/chosen_beacon = tgui_input_list(owner, "Beacon to connect to", "Implantable Wingpack", sort_names(possible_beacons))
			if(isnull(chosen_beacon))
				return
			wingpack.beacon = chosen_beacon
			to_chat(owner, span_notice("You link your wingpack to the beacon system."))

/obj/effect/spawner/random/boss/ancient_ai
	name = "ancient AI loot spawner"
	loot = list(/obj/item/personal_drone_shell = 1, /obj/item/bait_beacon = 1)

/obj/effect/spawner/random/boss/ancient_ai/valuable
	name = "ancient AI valuable loot spawner"
	loot = list(/obj/item/organ/cyberimp/chest/thrusters/wingpack = 1, /obj/item/mod/control/pre_equipped/exotic = 1)

#undef FLOOR_SHOCK_LENGTH
#undef DRONE_RESPAWN_COOLDOWN
#undef LASER_FLOWER_LENGTH
#undef LASER_FLOWER_BULLETHELL_LENGTH
#undef SERVER_ARMOR_PER_MINER
