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
	desc = "Ancient Nanotrasen AI that was hacked and reprogrammed to kill everything in sight."
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

	loot = list(/obj/item/clothing/suit/space/hardsuit/exosuit, /obj/item/malf_upgrade, /obj/item/experimental_components)
	crusher_loot = list(/obj/item/clothing/suit/space/hardsuit/exosuit, /obj/item/malf_upgrade, /obj/item/experimental_components, /obj/item/crusher_trophy/ai_core)
	common_loot = list(/obj/item/personal_drone_shell, /obj/item/bait_beacon)

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
	anger_modifier = clamp((initial_servers / servers) + (shield_toggled ? 0 : 1), 0, 6)
	ranged_cooldown = world.time + ((5 + anger_modifier / 2) SECONDS) / (shield_toggled ? 1 : 2)

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

	if(prob(anger_modifier * 5) && !bullethell)
		if(prob(anger_modifier * 5))
			laser_flower_bullethell()
			return
		laser_flower()

	if(prob(anger_modifier * 5 + 10))
		spawn_drones()
	else if(prob(anger_modifier * 5 + 20))
		violent_smash()

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
	armor = list(MELEE = 50, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
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
	var/mob/living/simple_animal/hostile/rogue_drone/drone = new(get_turf(src))
	drone.master_ai = master_ai
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
	armor = list(MELEE = 50, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
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

	max_integrity = 400
	armor = list(MELEE = 50, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)

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
	denied_type = /obj/item/crusher_trophy/ai_core
	var/rocket_cooldown = 0

/obj/item/crusher_trophy/ai_core/effect_desc()
	return "ranged right click attacks to shoot out 3 heat-seeking missiles. This ability has a 10 seconds cooldown."

/obj/item/crusher_trophy/ai_core/on_right_click(atom/target, mob/living/user)
	if(rocket_cooldown > world.time)
		to_chat(user, "<span class='warning'>[src] hasn't fully recovered from the previous blast! Wait [round((rocket_cooldown - world.time) / 10)] more seconds!</span>")
		return

	if(isclosedturf(target) || isclosedturf(get_turf(target)))
		return

	rocket_cooldown = world.time + 10 SECONDS
	for(var/i = 1 to 3)
		var/turf/startloc = get_turf(user)
		var/obj/projectile/P = new /obj/projectile/bullet/a84mm/ancient/at/seeking(startloc)
		P.preparePixelProjectile(target, startloc)
		P.firer = user
		P.original = target
		P.fire(target)
		P.homing_target = target
		sleep(5)

/**
 *
 * P.R.O.T.O.N. Exosuit
 *
 * A cool cybernetic suit that gives you HUDs and allows to perorm some sick tricks for more movement
 * It's as good as H.E.C.K. in terms of armor
 * However, all those sick features and armor only work in low-pressure enviroment to prevent it's use onboard and require power from internal cell, so don't forget to bring some!
 *
 **/

#define PROTON_ACTIVE_ARMOR list(MELEE = 75, BULLET = 40, LASER = 10, ENERGY = 20, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
#define PROTON_INACTIVE_ARMOR list(MELEE = 20, BULLET = 20, LASER = 10, ENERGY = 10, BOMB = 0, BIO = 100, RAD = 50, FIRE = 100, ACID = 100)
#define PROTON_ARMOR_DIFFERENCE list(MELEE = 55, BULLET = 20, ENERGY = 10, BOBM = 50, RAD = 50)

#define PROTON_JUMP_COOLDOWN 5 SECONDS //A bit better than jump boots
#define PROTON_JUMP_RANGE 5
#define PROTON_JUMP_SPEED 3
#define PROTON_DASH_RANGE 2
#define PROTON_DASH_TICK_PRESS 3
#define PROTON_DASH_COOLDOWN 0.3 SECONDS
#define PROTON_HOOK_COOLDOWN 3 SECONDS

#define PROTON_JUMP_COST 1500
#define PROTON_DASH_COST 500
#define PROTON_HOOK_COST 2000

/obj/item/clothing/suit/space/hardsuit/exosuit
	name = "P.R.O.T.O.N. exosuit"
	desc = "A prototype exosuit with external actuators for additional agility. It's dusty, but still in pretty good condition. \n Dash can be used by double-tapping movement button(when active) and hook can be activated by pressing resist hotkey."
	icon_state = "hardsuit-exosuit"
	inhand_icon_state = "syndicate-black"
	slowdown = 0
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/exosuit
	armor = PROTON_INACTIVE_ARMOR
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | LAVA_PROOF | ACID_PROOF | FREEZE_PROOF
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/pickaxe, /obj/item/spear, /obj/item/organ/regenerative_core, /obj/item/kitchen/knife, /obj/item/kinetic_crusher, /obj/item/resonator, /obj/item/gun/energy/kinetic_accelerator)
	actions_types = list(/datum/action/item_action/toggle_spacesuit/exosuit, /datum/action/item_action/toggle_helmet/exosuit, /datum/action/item_action/exosuit_jump, /datum/action/item_action/exosuit_dash, /datum/action/item_action/exosuit_hook)

	var/active = TRUE
	var/dash_active = FALSE
	var/dash_timer = 0
	var/dash_dir = 0
	var/jump_cooldown = 0
	var/dash_cooldown = 0
	var/hook_cooldown = 0
	var/obj/item/gun/magic/exosuit_hook/hook

/obj/item/clothing/suit/space/hardsuit/exosuit/Initialize()
	. = ..()
	hook = new(src)
	hook.suit = src

/obj/item/clothing/suit/space/hardsuit/exosuit/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING)
		check_pressure()
		RegisterSignal(user, COMSIG_MOVABLE_MOVED, .proc/check_pressure)
		RegisterSignal(user, COMSIG_KB_LIVING_RESIST_DOWN, .proc/extend_hook)

/obj/item/clothing/suit/space/hardsuit/exosuit/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(user, COMSIG_KB_LIVING_RESIST_DOWN)

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/check_pressure()
	if(lavaland_equipment_pressure_check(get_turf(src)))
		activate()
	else
		deactivate()

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/activate()
	if(active)
		return
	active = TRUE

	for(var/armor_tag in PROTON_ARMOR_DIFFERENCE)
		armor[armor_tag] += PROTON_ARMOR_DIFFERENCE[armor_tag]
		helmet.armor[armor_tag] += PROTON_ARMOR_DIFFERENCE[armor_tag]

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/deactivate()
	if(!active)
		return
	active = FALSE

	for(var/armor_tag in PROTON_ARMOR_DIFFERENCE)
		armor[armor_tag] -= PROTON_ARMOR_DIFFERENCE[armor_tag]
		helmet.armor[armor_tag] -= PROTON_ARMOR_DIFFERENCE[armor_tag]
	activate_dash() //Deactivates dash

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/check_cell(mob/user, charge_required, no_discharge = FALSE)
	if(no_discharge)
		if(!cell || cell.charge < charge_required)
			to_chat(user, span_warning("[src]'s actuators are limp and lifeless, probably it's cell is missing or discharged!"))
			return
		return TRUE

	if(!cell || !cell.use(charge_required))
		to_chat(user, span_warning("[src]'s actuators are limp and lifeless, probably it's cell is missing or discharged!"))
		return
	var/obj/item/clothing/head/helmet/space/hardsuit/exosuit/my_helmet = helmet
	my_helmet.check_charge(user) //So HUDs deactivate when cell is fully depleted.
	return TRUE

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/activate_jump(mob/user)
	if(!check_cell(user, PROTON_JUMP_COST))
		return

	if(jump_cooldown > world.time)
		cell.give(PROTON_JUMP_COST) //Refunds cost if fails to activate. I want the power check first so it will prioritise powerless error message
		to_chat(user, span_warning("[src]'s internal jump boosters haven't yet fully cooled down! Wait [round((jump_cooldown - world.time) / 10)] more seconds!"))
		return

	if(!active)
		cell.give(PROTON_JUMP_COST)
		to_chat(user, span_warning("[src]'s actuators hiss, but fail to propperly activate in high-pressure enviroment!"))
		return

	var/atom/target = get_edge_target_turf(user, user.dir)

	if (user.throw_at(target, PROTON_JUMP_RANGE, PROTON_JUMP_SPEED, spin = FALSE, diagonals_first = TRUE, callback = CALLBACK(src, .proc/jump_end, user)))
		ADD_TRAIT(user, TRAIT_NO_FLOATING_ANIM, SUIT_TRAIT)
		ADD_TRAIT(user, TRAIT_STUNIMMUNE, SUIT_TRAIT)
		ADD_TRAIT(user, TRAIT_MOVE_FLYING, SUIT_TRAIT) //Unlike jump boots, P.R.O.T.O.N. actually makes you fly for a bit so you are not affected by lava and such shit
		playsound(user, 'sound/effects/stealthoff.ogg', 50, TRUE, TRUE)
		user.visible_message(span_warning("[user] dashes forward into the air!"))
		jump_cooldown = world.time + PROTON_JUMP_COOLDOWN
	else
		cell.give(PROTON_JUMP_COST)
		to_chat(user, span_warning("Something prevents you from jumping!"))

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/jump_end(mob/user)
	REMOVE_TRAIT(user, TRAIT_NO_FLOATING_ANIM, SUIT_TRAIT)
	REMOVE_TRAIT(user, TRAIT_MOVE_FLYING, SUIT_TRAIT)
	REMOVE_TRAIT(user, TRAIT_STUNIMMUNE, SUIT_TRAIT)

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/activate_dash(mob/user)
	dash_active = !dash_active

	if(!active)
		dash_active = FALSE

	if(dash_active)
		RegisterSignal(user, COMSIG_KB_MOVEMENT_NORTH_DOWN, .proc/dash_north)
		RegisterSignal(user, COMSIG_KB_MOVEMENT_SOUTH_DOWN, .proc/dash_south)
		RegisterSignal(user, COMSIG_KB_MOVEMENT_EAST_DOWN, .proc/dash_east)
		RegisterSignal(user, COMSIG_KB_MOVEMENT_WEST_DOWN, .proc/dash_west)
	else
		UnregisterSignal(user, list(COMSIG_KB_MOVEMENT_NORTH_DOWN, COMSIG_KB_MOVEMENT_SOUTH_DOWN, COMSIG_KB_MOVEMENT_WEST_DOWN, COMSIG_KB_MOVEMENT_EAST_DOWN))

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/dash_north(turf/new_loc)
	attempt_dash(NORTH)

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/dash_south(turf/new_loc)
	attempt_dash(SOUTH)

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/dash_east(turf/new_loc)
	attempt_dash(EAST)

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/dash_west(turf/new_loc)
	attempt_dash(WEST)

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/attempt_dash(direction = NORTH)
	if(!isliving(loc))
		return

	var/mob/living/user = loc

	if(user.incapacitated() || user.body_position == LYING_DOWN)
		return

	if(dash_cooldown > world.time)
		to_chat(user, span_warning("[src]'s actuators haven't yet fully cooled down! Wait [round((dash_cooldown - world.time) / 10)] more seconds!"))
		return

	if(dash_dir != direction)
		dash_dir = direction
		dash_timer = world.time
		return

	if(world.time - dash_timer <= PROTON_DASH_TICK_PRESS)
		if(!check_cell(user, PROTON_DASH_COST))
			return
		dash_timer = 0
		var/atom/target = get_edge_target_turf(user, direction)
		if(user.throw_at(target, PROTON_DASH_RANGE, 1, spin = FALSE, diagonals_first = TRUE))
			playsound(user, 'sound/effects/stealthoff.ogg', 50, TRUE, TRUE)
			dash_cooldown = world.time + PROTON_DASH_COOLDOWN
		else
			cell.give(PROTON_DASH_COST)
			to_chat(user, span_warning("Something prevents you from dashing!"))
	else
		dash_timer = world.time

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/extend_hook(mob/user)
	if(hook.loc != src)
		if(ismob(hook.loc))
			var/mob/hook_loc = hook.loc
			hook_loc.dropItemToGround(hook)
		hook.forceMove(src)
		return

	if(!check_cell(user, PROTON_HOOK_COST, TRUE) || !active)
		return

	if(hook_cooldown > world.time)
		cell.give(PROTON_DASH_COST)
		to_chat(user, span_warning("[src]'s hook launching system haven't yet fully cooled down! Wait [round((hook_cooldown - world.time) / 10)] more seconds!"))
		return

	hook.forceMove(get_turf(src))
	if(!user.put_in_hands(hook))
		hook.forceMove(src)
		return

/obj/item/clothing/suit/space/hardsuit/exosuit/proc/hook_used()
	hook_cooldown = PROTON_HOOK_COOLDOWN
	cell.use(PROTON_HOOK_COST)

/obj/item/clothing/head/helmet/space/hardsuit/exosuit
	name = "P.R.O.T.O.N. exosuit helmet"
	desc = "An advanced helmet with a complex HUD. It's dusty and one of the stripes is faded but other than that, it is in a good condition."
	icon_state = "hardsuit0-exosuit"
	hardsuit_type = "exosuit"
	armor = PROTON_INACTIVE_ARMOR
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | LAVA_PROOF | ACID_PROOF | FREEZE_PROOF
	actions_types = list(/datum/action/item_action/toggle_helmet_light/exosuit)

/obj/item/clothing/head/helmet/space/hardsuit/exosuit/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HEAD && suit.cell && suit.cell.charge > 0)
		var/datum/atom_hud/hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		hud.add_hud_to(user)
		ADD_TRAIT(user, TRAIT_MEDICAL_HUD, HELMET_TRAIT)

		hud = GLOB.huds[DATA_HUD_SECURITY_ADVANCED]
		hud.add_hud_to(user)
		ADD_TRAIT(user, TRAIT_SECURITY_HUD, HELMET_TRAIT)

		hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED]
		hud.add_hud_to(user)
		ADD_TRAIT(user, TRAIT_DIAGNOSTIC_HUD, HELMET_TRAIT)

/obj/item/clothing/head/helmet/space/hardsuit/exosuit/dropped(mob/user)
	. = ..()
	var/datum/atom_hud/hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	hud.remove_hud_from(user)
	REMOVE_TRAIT(user, TRAIT_MEDICAL_HUD, HELMET_TRAIT)

	hud = GLOB.huds[DATA_HUD_SECURITY_ADVANCED]
	hud.remove_hud_from(user)
	REMOVE_TRAIT(user, TRAIT_SECURITY_HUD, HELMET_TRAIT)

	hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED]
	hud.remove_hud_from(user)
	REMOVE_TRAIT(user, TRAIT_DIAGNOSTIC_HUD, HELMET_TRAIT)

/obj/item/clothing/head/helmet/space/hardsuit/exosuit/proc/check_charge(mob/user)
	if(!suit.cell || suit.cell.charge <= 0)
		var/datum/atom_hud/hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		hud.remove_hud_from(user)
		REMOVE_TRAIT(user, TRAIT_MEDICAL_HUD, HELMET_TRAIT)

		hud = GLOB.huds[DATA_HUD_SECURITY_ADVANCED]
		hud.remove_hud_from(user)
		REMOVE_TRAIT(user, TRAIT_SECURITY_HUD, HELMET_TRAIT)

		hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED]
		hud.remove_hud_from(user)
		REMOVE_TRAIT(user, TRAIT_DIAGNOSTIC_HUD, HELMET_TRAIT)
		return

	var/datum/atom_hud/hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	hud.add_hud_to(user)
	ADD_TRAIT(user, TRAIT_MEDICAL_HUD, HELMET_TRAIT)

	hud = GLOB.huds[DATA_HUD_SECURITY_ADVANCED]
	hud.add_hud_to(user)
	ADD_TRAIT(user, TRAIT_SECURITY_HUD, HELMET_TRAIT)

	hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED]
	hud.add_hud_to(user)
	ADD_TRAIT(user, TRAIT_DIAGNOSTIC_HUD, HELMET_TRAIT)

/obj/item/gun/magic/exosuit_hook
	name = "magnetic grappling hook"
	desc = "A powerful magnet on a chain that is designed to pull you towards your target."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "hook_exo"
	inhand_icon_state = null
	fire_sound = 'sound/weapons/batonextend.ogg'
	max_charges = 1
	recharge_rate = 1 //Cooldown is handled in suit itself
	slot_flags = null
	item_flags = NOBLUDGEON
	force = 0
	ammo_type = /obj/item/ammo_casing/magic/exosuit_hook
	var/obj/item/clothing/suit/space/hardsuit/exosuit/suit

/obj/item/gun/magic/exosuit_hook/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	. = ..()
	user.dropItemToGround(src)
	forceMove(suit)
	suit.hook_used()

/obj/item/gun/magic/exosuit_hook/dropped(mob/user)
	. = ..()
	forceMove(suit)

/obj/item/ammo_casing/magic/exosuit_hook
	name = "magnetic hook"
	desc = "A magnet on a chain."
	projectile_type = /obj/projectile/exosuit_hook
	caliber = CALIBER_HOOK
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "hook_exo"
	firing_effect_type = /obj/effect/temp_visual/dir_setting/firing_effect

/obj/item/ammo_casing/magic/exosuit_hook/ready_proj(atom/target, mob/living/user, quiet, zone_override = "")
	..()
	if(loc && istype(loc, /obj/item/gun/magic/exosuit_hook) && loaded_projectile && istype(loaded_projectile, /obj/projectile/exosuit_hook))
		var/obj/item/gun/magic/exosuit_hook/hook = loc
		var/obj/projectile/exosuit_hook/proj = loaded_projectile
		proj.suit = hook.suit

/obj/projectile/exosuit_hook
	name = "magnetic hook"
	icon_state = "hook_exo"
	icon = 'icons/obj/lavaland/artefacts.dmi'
	pass_flags = PASSTABLE
	damage = 5 //A bit of damage from the impact
	damage_type = BRUTE
	hitsound = 'sound/weapons/chainhit.ogg'
	var/chain
	var/obj/item/clothing/suit/space/hardsuit/exosuit/suit

/obj/projectile/exosuit_hook/fire(setAngle)
	if(firer)
		chain = firer.Beam(src, icon_state = "chain_thin")
	..()

/obj/projectile/exosuit_hook/on_hit(atom/target)
	. = ..()
	if(!firer)
		return

	if(firer.throw_at(target, get_dist(firer, target), 1, spin = FALSE, diagonals_first = TRUE, callback = CALLBACK(suit, /obj/item/clothing/suit/space/hardsuit/exosuit.proc/jump_end, firer)))
		ADD_TRAIT(firer, TRAIT_NO_FLOATING_ANIM, SUIT_TRAIT)
		ADD_TRAIT(firer, TRAIT_STUNIMMUNE, SUIT_TRAIT)
		ADD_TRAIT(firer, TRAIT_MOVE_FLYING, SUIT_TRAIT)
		playsound(firer, 'sound/effects/stealthoff.ogg', 50, TRUE, TRUE)
		firer.visible_message(span_warning("[firer] is pulled towards [target] by [src]!"))

/obj/projectile/exosuit_hook/Destroy()
	qdel(chain)
	return ..()

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
		var/mob/living/simple_animal/hostile/rogue_drone/pet_drone/pet = new(get_turf(src))
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
