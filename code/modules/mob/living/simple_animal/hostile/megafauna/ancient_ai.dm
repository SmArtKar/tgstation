/**
*
* Ancient AI
*
* Even though we're fighting against an arena itself and not against some mob, I still make it a megafauna because why the fuck not.
* So yeah, this is the main controller of ancient AI arena. This boss can be found in deep jungle caves in a special arena.
*
* Ancient AI has a few different moves:
* 1. A few turrets activate and shoot rockets.
* 2. Some turfs become electrified, damaging and stunning everybody who walks ontop of them.
* 3. Giant manipulators activate and perform a few swings, damaging everything they collide with
* 4. Giant manipulators activate and try to grab the player and throw him afterwards
* 5. Laser Flower turrets activate, flooding the arena with slow laser bullethell. This attack is performed rarely and only on low HP.
* 6. A bunch of hostile drones are spawned, targeting player. This attack is only performed on low HP.
*
* To kill the AI you need to break it's servers which can be done by either brute force(very slow) or by dodging rockets and making them hit the servers.
* After servers are broken, you can finish the AI by destroying it's core whose shields were deactivated.
*
* After killing the AI you get some Experimental Components(required to craft some cool shit) and a badass exoskeleton armor that gives you HUDs and allows you to perform a few sick tricks.
* When killed with crusher, it will also drop it's core that will allow you to shoot 3 heat-seeking missiles on right click(these are harmless for humans)
* It also has "common" loot that drops per everybody in the group that killed it. It consists of an experimental drone pet that serves as a combat companion and a mob bait.
*
* Intended difficulty: OH GOD OH FUCK
*
**/

#define FLOOR_SHOCK_LENGTH 10 SECONDS
#define DRONE_RESPAWN_COOLDOWN 10 SECONDS
#define LASER_FLOWER_LENGTH 2 SECONDS
#define LASER_FLOWER_BULLETHELL_LENGTH 6 SECONDS

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
	stat_attack = HARD_CRIT
	ranged = TRUE
	ranged_message = null
	ranged_ignores_vision = TRUE

	loot = list(/obj/item/malf_upgrade)
	crusher_loot = list(/obj/item/malf_upgrade)
	common_loot = list(/obj/item/personal_drone_shell, /obj/item/bait_beacon, /obj/item/experimental_components, /obj/item/mod/control/pre_equipped/exotic)
	common_crusher_loot = list(/obj/item/personal_drone_shell, /obj/item/bait_beacon, /obj/item/experimental_components, /obj/item/mod/control/pre_equipped/exotic, /obj/item/crusher_trophy/ai_core)
	spawns_minions = TRUE

	var/rocket_type = /obj/projectile/bullet/a84mm/ancient/at
	var/shield_toggled = TRUE
	var/list/server_list = list()
	var/servers = 0
	var/initial_servers = 0
	var/bullethell = FALSE
	var/floorshock = FALSE
	var/list/drones = list()

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

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/activate_turrets()
	var/list/working_turrets = list()

	for(var/obj/machinery/porta_turret/ancient_ai/turret in range(12, src))
		if(turret.master_ai != src)
			turret.master_ai = src

		if(turret.machine_stat & BROKEN)
			continue

		if(!(target in view(6, turret)))
			continue

		working_turrets.Add(turret)

	for(var/i = 1 to 4)
		var/obj/machinery/porta_turret/ancient_ai/turret = pick_n_take(working_turrets)
		turret.showShoot(target)
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

	for(var/obj/machinery/rogue_drone_spawner/spawner in range(12, src))
		if(prob(50))
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
		if(prob(75))
			turret.toggle_with_warning(TRUE)

	addtimer(CALLBACK(src, .proc/deactivate_flowers), LASER_FLOWER_BULLETHELL_LENGTH)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/server_broken()
	servers -= 1
	playsound(src, 'sound/voice/ed209_20sec.ogg', 100, FALSE)

	shield_toggled = FALSE
	status_flags &= ~GODMODE
	update_appearance()

	if(servers > 0)
		addtimer(CALLBACK(src, .proc/activate_shield), 5 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/proc/activate_shield()
	shield_toggled = TRUE
	status_flags |= GODMODE
	update_appearance()

/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/OpenFire()
	if(servers > 0)
		anger_modifier = clamp((initial_servers / servers) + (shield_toggled ? 0 : 1), 0, 6)
	else
		anger_modifier = 6
	ranged_cooldown = world.time + ((6 - anger_modifier / 2) SECONDS) / (shield_toggled ? 1 : 2)

	if(get_dist(src, target) <= 2 && !floorshock)
		activate_floor_shock()
		return

	if(anger_modifier == 6)
		rocket_type = /obj/projectile/bullet/a84mm/ancient/heavy
	else if(anger_modifier > 4)
		rocket_type = /obj/projectile/bullet/a84mm/ancient
	else if(anger_modifier > 1)
		rocket_type = /obj/projectile/bullet/a84mm/he/ancient
	else
		rocket_type = /obj/projectile/bullet/a84mm/ancient/at

	if(prob(anger_modifier * 10) && !bullethell)
		if(prob(anger_modifier * 5))
			laser_flower_bullethell()
			return
		laser_flower()

	if(prob(anger_modifier * 5 + 10))
		spawn_drones()
	else if(prob(anger_modifier * 5 + 20))
		INVOKE_ASYNC(src, .proc/violent_smash)

	if(prob(25))
		activate_floor_shock()
	else
		activate_turrets()






/obj/machinery/rogue_drone_spawner
	name = "drone pedestal"
	desc = "Some sort of platform with a drone shell ontop of it. It's all dusted and dirty."
	icon = 'icons/obj/jungle/ancient_ai.dmi'
	icon_state = "drone_spawner"

	max_integrity = 200
	armor = list(MELEE = 75, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 75, BIO = 0, FIRE = 100, ACID = 100)
	density = TRUE
	anchored = TRUE

	var/has_drone = TRUE
	var/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/master_ai

/obj/machinery/rogue_drone_spawner/proc/spawn_drone()
	if(!has_drone || LAZYLEN(master_ai.drones) >= 6)
		return

	icon_state = "[initial(icon_state)]_empty"
	update_icon()
	flick("[initial(icon_state)]_activate", src)
	has_drone = FALSE
	var/mob/living/simple_animal/hostile/jungle/rogue_drone/drone = new(get_turf(src))
	drone.master_ai = master_ai
	drone.GiveTarget(master_ai.target)
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
	armor = list(MELEE = 75, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 75, BIO = 0, FIRE = 100, ACID = 100)
	density = TRUE
	anchored = TRUE

	var/active = FALSE
	var/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/master_ai

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

	var/mutable_appearance/arm_1 = mutable_appearance(icon, "arm_1")
	var/matrix/arm_1_matrix = matrix()
	arm_1_matrix.Turn(angle_1 - 45)
	arm_1.transform = arm_1_matrix
	add_overlay(arm_1)


	var/mutable_appearance/arm_2 = mutable_appearance(icon, "arm_2")
	var/matrix/arm_2_matrix = matrix()
	arm_2_matrix.Turn(angle_2 - 45)
	arm_2_matrix.Translate(cos(angle_1) * round(sqrt(25 ** 2 / 2)) * 2 + 1, -sin(angle_1) * round(sqrt(25 ** 2 / 2)) * 2 + 1)
	arm_2.transform = arm_2_matrix
	add_overlay(arm_2)


	var/mutable_appearance/arm_3 = mutable_appearance(icon, "arm_3")
	var/matrix/arm_3_matrix = matrix()
	arm_3_matrix.Turn(angle_3 - 45)
	arm_3_matrix.Translate(cos(angle_1) * round(sqrt(25 ** 2 / 2)) * 2 + 1, -sin(angle_1) * round(sqrt(25 ** 2 / 2)) * 2 + 1)
	arm_3_matrix.Translate(cos(angle_2) * round(sqrt(25 ** 2 / 2)) * 2 + 1, -sin(angle_2) * round(sqrt(25 ** 2 / 2)) * 2 + 1)
	arm_3.transform = arm_3_matrix
	add_overlay(arm_3)

	. = ..()

/obj/machinery/giant_arm_holder/proc/violent_smash()
	var/speed = 5
	while(angle_1 < default_angle + 90)
		angle_1 = min(angle_1 + speed, default_angle + 90)
		angle_2 = min(angle_1 + round(speed / 2), default_angle + 90)
		angle_3 = min(angle_1 + round(speed / 2), default_angle + 90)
		speed *= 2
		check_damage()
		sleep(1)
		update_icon()

	playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)

	while(angle_2 < default_angle + 90)
		angle_2 = min(angle_2 + speed, default_angle + 90)
		angle_3 = min(angle_3 + speed, default_angle + 90)
		check_damage()
		sleep(1)
		update_icon()

	speed = 2
	while(angle_1 > default_angle - 90)
		angle_1 = max(angle_1 - speed, default_angle - 90)
		angle_2 = max(angle_1 - round(speed / 2), default_angle - 90)
		angle_3 = max(angle_1 - round(speed / 2), default_angle - 90)
		speed *= 2
		check_damage()
		sleep(1)
		update_icon()

	playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)

	while(angle_2 > default_angle - 90)
		angle_2 = max(angle_2 - speed, default_angle - 90)
		angle_3 = max(angle_3 - speed, default_angle - 90)
		check_damage()
		sleep(1)
		update_icon()

	while(angle_1 < default_angle)
		angle_1 = min(angle_1 + 3, default_angle)
		angle_2 = min(angle_2 + 3, default_angle)
		angle_3 = min(angle_3 + 3, default_angle)
		sleep(1)
		update_icon()


/obj/machinery/giant_arm_holder/proc/check_damage()
	var/first_joint_x = round((cos(angle_1) * round(sqrt(25 ** 2 / 2)) * 2 + 1) / 32) + 1
	var/first_joint_y = round((sin(angle_1) * round(sqrt(25 ** 2 / 2)) * 2 + 1) / 32)
	var/second_joint_x = round(((cos(angle_1) * round(sqrt(25 ** 2 / 2)) * 2 + 1) + (cos(angle_2) * round(sqrt(25 ** 2 / 2)) * 2 + 1)) / 32) + 1
	var/second_joint_y = round(((sin(angle_1) * round(sqrt(25 ** 2 / 2)) * 2 + 1) + (sin(angle_2) * round(sqrt(25 ** 2 / 2)) * 2 + 1)) / 32)

	var/turf/first_joint = locate(first_joint_x + x, y - first_joint_y, z)
	var/turf/second_joint = locate(second_joint_x + x, y - second_joint_y, z)
	var/list/already_thrown = list()

	for(var/mob/living/target in first_joint)
		if(target in already_thrown)
			continue
		already_thrown.Add(target)
		to_chat(target, span_userdanger("You're hit by a giant manipulator!"))
		target.adjustBruteLoss(20)
		target.throw_at(get_edge_target_turf(target, get_dir(src, target)), 6, 3)

	for(var/mob/living/target in second_joint)
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

	max_integrity = 200
	armor = list(MELEE = 50, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 50, BIO = 0, FIRE = 100, ACID = 100)

	var/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/master_ai

/obj/machinery/ancient_server/attackby(obj/item/C, mob/user, params)
	. = ..()
	if(master_ai)
		master_ai.GiveTarget(user)

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
	desc = "A potato with a lot of wires. Suitable as a trophy for a kinetic crusher."
	icon_state = "ai_core"
	denied_type = list(/obj/item/crusher_trophy/ai_core, /obj/item/crusher_trophy/leaper_eye)
	var/rocket_cooldown = 0

/obj/item/crusher_trophy/ai_core/effect_desc()
	return "ranged right click attacks to shoot out 3 heat-seeking missiles. This ability has a 10 seconds cooldown."

/obj/item/crusher_trophy/ai_core/proc/shoot_rockets(mob/living/user, atom/target)
	for(var/i = 1 to 3)
		var/turf/startloc = get_turf(user)
		var/obj/projectile/P = new /obj/projectile/bullet/a84mm/ancient/at/seeking(startloc)
		P.preparePixelProjectile(target, startloc)
		P.firer = user
		P.original = target
		P.fire(target)
		P.homing_target = target
		sleep(3)

/obj/item/crusher_trophy/ai_core/on_right_click(atom/target, mob/living/user)
	if(rocket_cooldown > world.time)
		to_chat(user, "<span class='warning'>[src] hasn't fully recovered from the previous blast! Wait [round((rocket_cooldown - world.time) / 10)] more seconds!</span>")
		return

	if(isclosedturf(target) || isclosedturf(get_turf(target)))
		return

	rocket_cooldown = world.time + 10 SECONDS
	INVOKE_ASYNC(src, .proc/shoot_rockets, user, target)

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

	active = !active
	if(!active)
		deactivate()
		return

	log_combat(user, null, "lured mobs in the area", src)

	icon_state = "batterer"
	playsound(user, 'sound/effects/stealthoff.ogg', 50, TRUE, TRUE)

	for(var/mob/living/simple_animal/hostile/M in urange(10, src))
		M.GiveTarget(src)

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

#undef FLOOR_SHOCK_LENGTH
#undef DRONE_RESPAWN_COOLDOWN
#undef LASER_FLOWER_LENGTH
#undef LASER_FLOWER_BULLETHELL_LENGTH

#undef PROTON_ACTIVE_ARMOR
#undef PROTON_INACTIVE_ARMOR
#undef PROTON_ARMOR_DIFFERENCE

#undef PROTON_JUMP_COOLDOWN
#undef PROTON_JUMP_RANGE
#undef PROTON_JUMP_SPEED
#undef PROTON_DASH_RANGE
#undef PROTON_DASH_TICK_PRESS
#undef PROTON_DASH_COOLDOWN
#undef PROTON_HOOK_COOLDOWN

#undef PROTON_JUMP_COST
#undef PROTON_DASH_COST
#undef PROTON_HOOK_COST
