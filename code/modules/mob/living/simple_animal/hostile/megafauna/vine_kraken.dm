#define VINE_DELETE_CHANCE 15
#define VINE_MIN_DELETE 4
#define VINE_MAX 6
#define THROW_MOVE_COOLDOWN 1 SECONDS
#define POWER_THROW_MOVE_COOLDOWN 0.5 SECONDS
#define STAFF_VINE_COOLDOWN 5 SECONDS

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken
	name = "vine kraken"
	desc = "A terrifying moster made out entirely of jungle vines."
	health = 3000
	maxHealth = 3000
	icon_state = "vine_kraken"
	icon_living = "vine_kraken"
	icon_dead = "vine_kraken_dead"
	icon = 'icons/mob/jungle/vine_kraken.dmi'

	attack_sound = 'sound/creatures/venus_trap_hit.ogg'
	mob_biotypes = MOB_ORGANIC|MOB_PLANT|MOB_EPIC
	light_color = LIGHT_COLOR_YELLOW
	movement_type = GROUND
	speak_emote = list("chitters")
	faction = list("jungle", "boss", "vines", "plants")

	melee_damage_lower = 25
	melee_damage_upper = 25
	ranged = TRUE
	vision_range = 16
	aggro_vision_range = 16
	former_target_vision_range = 16
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stabs"
	obj_damage = 200
	pixel_x = -8
	base_pixel_x = -8
	pixel_y = -8
	base_pixel_y = -8

	achievement_type = /datum/award/achievement/boss/vine_kraken_kill
	crusher_achievement_type = /datum/award/achievement/boss/vine_kraken_crusher
	score_achievement_type = /datum/award/score/vine_kraken_score

	wander = FALSE
	speed = 3
	move_to_delay = 3
	gps_name = "Solar Signal"

	loot = list(/obj/item/organ/heart/jungle, /obj/item/green_rose)
	common_loot = list(/obj/item/gun/magic/staff/vine)
	common_crusher_loot = list(/obj/item/gun/magic/staff/vine, /obj/item/crusher_trophy/vine_tentacle)

	var/list/vines = list()
	var/list/vine_targets = list()
	var/already_moving = FALSE
	var/move_cooldown
	var/immobile = FALSE
	var/throw_spree = 0
	var/second_stage = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/Life(delta_time, times_fired)
	. = ..()
	if(health < maxHealth * 0.5 && !second_stage)
		second_stage = TRUE
		damage_coeff = list(BRUTE = 0.7, BURN = 0.25, TOX = 0.5, CLONE = 1, STAMINA = 0, OXY = 1)
		initial_damage_coeff = list(BRUTE = 0.7, BURN = 0.25, TOX = 0.5, CLONE = 1, STAMINA = 0, OXY = 1)

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/Destroy()
	for(var/vine in vines)
		qdel(vine)
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/OpenFire()
	anger_modifier = clamp(((maxHealth - health) / 80), 0, 20)
	ranged_cooldown = world.time + 4 SECONDS

	if(check_proj_immunity(target)) //Become enraged if we get attacked by someone immune to projectiles
		if(!throw_spree)
			throwing_spree()
		vine_attack()
		ranged_cooldown = world.time + 2 SECONDS
		return

	if(prob(45 + anger_modifier) && !throw_spree)
		throwing_spree()
		ranged_cooldown = ranged_cooldown + 2 SECONDS

	if(health < maxHealth * 0.5)
		for(var/mob/living/possible_target in former_targets)
			if(get_dist(src, possible_target) < 4 && prob(80))
				INVOKE_ASYNC(src, .proc/spiral_shoot, 0)
				break
		if(prob(65))
			throwing_spree()
			SLEEP_CHECK_DEATH(5, src)
		var/radius_active = FALSE
		if(prob(25))
			triple_radius()
			radius_active = TRUE

		if(prob(35))
			vine_attack()
			if(prob(anger_modifier + 15) && !radius_active)
				INVOKE_ASYNC(src, .proc/attack_in_radius)
				SLEEP_CHECK_DEATH(2 SECONDS, src)
				throwing_spree()
				ranged_cooldown = world.time + 12 SECONDS
			else
				solar_barrage()
		else
			ranged_cooldown = ranged_cooldown + 2 SECONDS
			vine_attack()
			SLEEP_CHECK_DEATH(6, src)
			vine_attack()
			SLEEP_CHECK_DEATH(6, src)
			throwing_spree()
	else
		var/attack_type = rand(1, 5)
		switch(attack_type)
			if(1 to 3)
				if(!throw_spree)
					throwing_spree()
					return

				if(prob(50 + anger_modifier))
					solar_barrage()
				else
					attack_in_radius()
			if(4)
				attack_in_radius()
				SLEEP_CHECK_DEATH(1.5 SECONDS, src)
				vine_attack()
			if(5)
				INVOKE_ASYNC(src, .proc/spiral_shoot)

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/Goto(target, delay, minimum_distance)
	if(!already_moving && world.time > move_cooldown && !immobile)
		if(throw_spree)
			throw_spree -= 1
			move_cooldown = world.time + POWER_THROW_MOVE_COOLDOWN
			already_moving = TRUE
			shoot_projectile(get_turf(target), mark_target = FALSE, proj_type = /obj/projectile/vine_tentacle/throwing)
			return
		move_cooldown = world.time + THROW_MOVE_COOLDOWN
		var/should_shoot = TRUE

		if((LAZYLEN(vines) > VINE_MIN_DELETE && prob(VINE_DELETE_CHANCE)) || LAZYLEN(vines) > VINE_MAX)
			var/to_delete = pick(vines)
			var/vine_to_delete = vines[to_delete]
			vines.Remove(to_delete)
			qdel(vine_to_delete)
			vine_targets.Remove(to_delete)

		var/view_objects = view(15, get_turf(src))
		for(var/atom/vine_target in vine_targets)
			if(!vine_target || QDELETED(vine_target) || !(vine_target in view_objects))
				var/vine_to_delete = vines[vine_target]
				vines.Remove(vine_target)
				qdel(vine_to_delete)
				vine_targets.Remove(vine_target)

		var/target_angle = get_angle(src, target)
		if(target_angle < 0)
			target_angle += 360
		for(var/atom/vine_target in vine_targets)
			var/vine_angle = get_angle(src, vine_target)
			if(vine_angle < 0)
				vine_angle += 360
			if(abs(vine_angle - target_angle) < 15)
				should_shoot = FALSE
				break

		if(!should_shoot)
			process_vine_move(target, FALSE)
			return
		shoot_projectile(get_turf(target), mark_target = FALSE)

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)

	if((LAZYLEN(vines) > VINE_MIN_DELETE && prob(VINE_DELETE_CHANCE)) || LAZYLEN(vines) > VINE_MAX)
		var/to_delete = pick(vines)
		var/vine_to_delete = vines[to_delete]
		vines.Remove(to_delete)
		qdel(vine_to_delete)
		vine_targets.Remove(to_delete)

	already_moving = FALSE

	var/view_objects = view(15, get_turf(src))
	for(var/atom/vine_target in vine_targets)
		if(!vine_target || QDELETED(vine_target) || !(vine_target in view_objects))
			var/vine_to_delete = vines[vine_target]
			vines.Remove(vine_target)
			qdel(vine_to_delete)
			vine_targets.Remove(vine_target)

	if(!isliving(hit_atom))
		visible_message(span_danger("[src] slams into [hit_atom]!"), span_warning("You slam into [hit_atom]!"))
		if(isobj(hit_atom))
			var/obj/slammed = hit_atom
			slammed.take_damage(obj_damage, BRUTE, MELEE)
			if(ismovable(hit_atom))
				var/atom/movable/dunked = hit_atom
				if(!dunked.anchored)
					var/turf/throw_target = get_ranged_target_turf(dunked, get_dir(src, hit_atom), 40)
					dunked.throw_at(throw_target, 40, 4)
		if(istype(hit_atom, /turf/closed/mineral))
			var/turf/closed/mineral/rock = hit_atom
			rock.gets_drilled(src)
		if(throw_spree)
			SLEEP_CHECK_DEATH(5, src)
			Goto(target, move_to_delay, 1)
		return

	var/mob/living/victim = hit_atom
	victim.visible_message(span_danger("[src] slams into [victim]!"), span_userdanger("[src] slams into you, sending you flying!"))
	to_chat(src, span_warning("You slam into [victim]!"))
	var/turf/throw_target = get_ranged_target_turf(victim, get_dir(src, hit_atom), 40)
	victim.throw_at(throw_target, 40, 3) //YEEEEEEET
	if(throw_spree)
		SLEEP_CHECK_DEATH(5, src)
		Goto(target, move_to_delay, 1)

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/shoot_projectile(turf/marker, set_angle, proj_type = /obj/projectile/vine_tentacle, mark_target = TRUE, turf/startloc = get_turf(src))
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/obj/projectile/P = new proj_type(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = src
	if(target && mark_target)
		P.original = target
	P.fire(set_angle)
	return P

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/process_vine_move(atom/targeting, throw_type = FALSE)
	if(throw_type)
		throw_at(get_turf(targeting), 40, 1, spin = FALSE, diagonals_first = TRUE)
		return

	walk_to(src, get_turf(targeting), get_dist(get_turf(target), get_turf(targeting)), move_to_delay)

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/solar_barrage()
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, transform = matrix() * 1.5, time = 4)
	SLEEP_CHECK_DEATH(4, src)
	qdel(D)
	var/static/list/barrage_shot_angles = list(12.5, 7.5, 2.5, -2.5, -7.5, -12.5)
	var/target_angle = get_angle(src, target)
	var/turf/target_turf = get_turf(target)
	for(var/i in barrage_shot_angles)
		shoot_projectile(target_turf, target_angle + i, proj_type = /obj/projectile/solar)

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/spiral_shoot(delay = 1, counter_start = 8, blasts_per_circle = 16, negative = pick(TRUE, FALSE), proj_type = /obj/projectile/solar_particle)
	immobile = TRUE
	walk_to(src, 0)
	var/turf/start_turf = get_step(src, pick(GLOB.alldirs))
	var/counter = counter_start
	var/prev_health = health
	for(var/i in 1 to 32)
		if(negative)
			counter--
		else
			counter++
		if(counter > blasts_per_circle)
			counter = 1
		if(counter < 1)
			counter = blasts_per_circle
		shoot_projectile(start_turf, counter * (360 / blasts_per_circle), proj_type = proj_type)
		SLEEP_CHECK_DEATH(delay, src)

		if(health != prev_health)
			immobile = FALSE
			throwing_spree()
			solar_barrage()
			return
	immobile = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/vine_attack()
	immobile = TRUE
	walk_to(src, 0)
	for(var/i = 1 to 3)
		var/turf/start_turf = get_step(get_turf(src), pick(GLOB.alldirs))
		shoot_projectile(start_turf, get_angle(src, target) + rand(-15, 15), proj_type = /obj/projectile/vine_spawner)
		SLEEP_CHECK_DEATH(1 SECONDS, src)
	immobile = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/attack_in_radius(negative = FALSE, immobilize = TRUE)
	if(immobilize)
		immobile = TRUE
		walk_to(src, 0)
	for(var/turf/target_turf in orange(7, get_turf(src)))
		if(isclosedturf(target_turf))
			continue
		if(sqrt((target_turf.x - x) ** 2 + (target_turf.y - y) ** 2) > 7)
			continue
		if((target_turf.x % 2 == target_turf.y % 2) != negative)
			new /obj/effect/temp_visual/target/vine_tentacle(target_turf, src)
	if(immobilize)
		immobile = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/triple_radius()
	immobile = TRUE
	walk_to(src, 0)
	attack_in_radius(FALSE, FALSE)
	SLEEP_CHECK_DEATH(20, src)
	attack_in_radius(TRUE, FALSE)
	SLEEP_CHECK_DEATH(20, src)
	attack_in_radius(FALSE, FALSE)
	immobile = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/death(gibbed, list/force_grant)
	for(var/atom/vine_target in vine_targets)
		qdel(vines[vine_target])
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/throwing_spree()
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, transform = matrix() * 1.5, time = 4)
	SLEEP_CHECK_DEATH(4, src)
	qdel(D)
	throw_spree = rand(2, 4)

/obj/effect/temp_visual/target/vine_tentacle
	duration = 10
	var/mob/living/creator

/obj/effect/temp_visual/target/vine_tentacle/Initialize(mapload, list/flame_hit, mob/new_creator)
	. = ..()
	creator = new_creator

/obj/effect/temp_visual/target/vine_tentacle/fall(list/flame_hit)
	var/turf/T = get_turf(src)
	if(ismineralturf(T))
		return
	sleep(duration)
	new /obj/effect/temp_visual/goliath_tentacle/vine_kraken/nostun(get_turf(src), creator)
	qdel(src)

/obj/projectile/vine_tentacle
	name = "vine tentacle"
	icon_state = "tentacle_jungle"
	nodamage = TRUE
	range = 40
	pass_flags = PASSTABLE | PASSMOB
	speed = 0
	var/tentacle
	var/throwing_proj = FALSE
	var/staff = FALSE

/obj/projectile/vine_tentacle/staff
	nodamage = FALSE
	damage = 10
	damage_type = BRUTE
	flag = MELEE
	staff = TRUE

/obj/projectile/vine_tentacle/staff/throwing
	throwing_proj = TRUE

/obj/item/ammo_casing/magic/vine
	projectile_type = /obj/projectile/vine_tentacle/staff

/obj/item/ammo_casing/magic/vine/throwing
	projectile_type = /obj/projectile/vine_tentacle/staff/throwing

/obj/projectile/vine_tentacle/fire(setAngle)
	if(firer)
		tentacle = firer.Beam(src, icon_state = "vine_jungle[throwing_proj ? "_blooming" : ""]", beam_type = /obj/effect/ebeam/vine)
	..()

/obj/projectile/vine_tentacle/on_hit(atom/target, blocked = FALSE)
	qdel(tentacle)
	var/vine = firer.Beam(target, icon_state = "vine_jungle[throwing_proj ? "_blooming" : ""]", beam_type = /obj/effect/ebeam/vine)
	if(istype(firer, /mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken))
		var/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/kraken = firer
		kraken.vines[target] = vine
		kraken.vine_targets.Add(target)
		kraken.process_vine_move(target, throwing_proj)
		QDEL_IN(vine, 20 SECONDS)
	if(staff)
		QDEL_IN(vine, 2 SECONDS)
		if(isliving(target))
			var/mob/living/victim = target
			if(!isanimal(victim))
				victim.Stun(0.5)
				damage = 5
			else
				victim.Stun(1)
		if(throwing_proj && firer)
			firer.throw_at(get_turf(target), get_dist(firer, get_turf(target)) - 1, 1, spin = FALSE, diagonals_first = FALSE)
	. = ..()

/obj/projectile/vine_tentacle/throwing
	throwing_proj = TRUE

/obj/effect/temp_visual/goliath_tentacle/vine_kraken
	name = "tropical vine"
	icon = 'icons/mob/jungle/jungle_monsters.dmi'
	icon_state = "vine_tentacle_spawn"
	base_icon_state = "vine"
	stun_length = 4 SECONDS //Still enough to get your face destroyed

/obj/effect/temp_visual/goliath_tentacle/vine_kraken/nostun
	stun_length = 0
	lower_damage = 25
	upper_damage = 30

/obj/projectile/solar
	name = "solar blast"
	icon_state = "solar"
	damage = 15
	damage_type = BURN
	hitsound = 'sound/weapons/sear.ogg'
	speed = 2
	flag = ENERGY

/obj/projectile/solar/Initialize()
	. = ..()
	SpinAnimation()

/obj/projectile/solar_particle
	name = "solar particle"
	icon_state = "solar_2"
	damage = 20
	damage_type = BURN
	flag = ENERGY
	hitsound = 'sound/weapons/sear.ogg'
	speed = 2
	homing = TRUE
	var/counter = 0

/obj/projectile/solar_particle/process_homing() //I guess I'll just use homing proc for modifying speed?
	counter += 30
	set_pixel_speed((sin(counter) + 1) * SSprojectiles.global_pixel_speed * 0.2) //Cool wave-like movement

/obj/projectile/vine_spawner
	nodamage = TRUE
	range = 40
	pass_flags = PASSTABLE | PASSMOB
	nodamage = TRUE
	invisibility = INVISIBILITY_MAXIMUM
	speed = 4
	suppressed = TRUE

/obj/projectile/vine_spawner/on_hit(atom/target, blocked, pierce_hit)
	qdel(src)

/obj/projectile/vine_spawner/pixel_move(trajectory_multiplier, hitscanning = FALSE)
	. = ..()
	if(!loc)
		return

	if(locate(/obj/effect/temp_visual/goliath_tentacle/vine_kraken) in get_turf(src))
		return

	new /obj/effect/temp_visual/goliath_tentacle/vine_kraken(get_turf(src), firer)

/obj/item/gun/magic/staff/vine
	name = "staff of vines"
	desc = "A staff entangled in vines. This ancient artifact is able to throw vines. Right click to throw a blooming vine that will pull you along with it"
	fire_sound = 'sound/creatures/venus_trap_hit.ogg'
	ammo_type = /obj/item/ammo_casing/magic/vine
	icon_state = "vine_staff"
	icon = 'icons/obj/lavaland/artefacts.dmi'
	inhand_icon_state = "vine_staff"
	school = SCHOOL_EVOCATION
	max_charges = 10
	recharge_rate = 1
	var/vine_cooldown
	var/blooming_casing

/obj/item/gun/magic/staff/vine/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, 0.3 SECONDS)
	blooming_casing = new /obj/item/ammo_casing/magic/vine/throwing(src)

/obj/item/gun/magic/staff/vine/afterattack_secondary(atom/target, mob/living/user, flag, params)
	if(world.time < vine_cooldown)
		to_chat(user, span_warning("[src] hasn't yet recovered from previous blooming vine!"))
		return
	vine_cooldown = world.time + STAFF_VINE_COOLDOWN
	var/old_casing = chambered
	chambered = blooming_casing
	afterattack(target, user, flag, params)
	chambered = old_casing

/obj/item/organ/heart/jungle //Gives player great mobility at cost of rendering normal healing useless. Only hardcore, only seedling cores.
	name = "heart of the jungle"
	desc = "A green, thorny heart with a large rose blooming out of it. Legends say that this heart will allow you to move around using vines, but at what cost?.."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "heart-vine-on"
	base_icon_state = "heart-vine-off"
	status = ORGAN_ORGANIC
	organ_flags = ORGAN_FROZEN|ORGAN_UNREMOVABLE
	var/obj/item/organ/cyberimp/arm/vine_tentacle/tentacle
	var/list/vines = list()
	var/list/vine_targets = list()

/obj/item/organ/heart/jungle/Insert(mob/living/carbon/target, special = 0)
	. = ..()
	if(!istype(target))
		return

	ADD_TRAIT(target, TRAIT_VINE_IMMUNE, ORGAN_TRAIT)
	ADD_TRAIT(target, TRAIT_MOVE_FLOATING, ORGAN_TRAIT)
	ADD_TRAIT(target, TRAIT_NO_FLOATING_ANIM, ORGAN_TRAIT)
	target.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/equipment_speedmod)
	target.add_movespeed_modifier(/datum/movespeed_modifier/jungle_heart)

	RegisterSignal(target, COMSIG_MOVABLE_MOVED, .proc/on_move)

	tentacle = new(get_turf(src))
	tentacle.zone = pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	tentacle.SetSlotFromZone()
	tentacle.Insert(target)

/obj/item/organ/heart/jungle/Remove(mob/living/carbon/target, special = 0)
	. = ..()
	if(!istype(target))
		return

	REMOVE_TRAIT(target, TRAIT_VINE_IMMUNE, ORGAN_TRAIT)
	REMOVE_TRAIT(target, TRAIT_MOVE_FLOATING, ORGAN_TRAIT)
	REMOVE_TRAIT(target, TRAIT_NO_FLOATING_ANIM, ORGAN_TRAIT)
	target.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/equipment_speedmod)
	target.remove_movespeed_modifier(/datum/movespeed_modifier/jungle_heart)

	UnregisterSignal(target, COMSIG_MOVABLE_MOVED)

	tentacle.Remove(target)

/obj/item/organ/heart/jungle/on_life(delta_time, times_fired)
	for(var/datum/reagent/reagent in owner.reagents.reagent_list)
		if(!istype(reagent, /datum/reagent/medicine))
			continue
		owner.reagents.remove_reagent(reagent.type, reagent.metabolization_rate * delta_time / owner.metabolism_efficiency * 9) //Basically renders chems useless so you have to rely solely on seedling cores
	. = ..()

/obj/item/organ/heart/jungle/proc/on_move(atom/movable/movable, atom/old_loc)
	var/should_shoot = TRUE

	if((LAZYLEN(vines) > VINE_MIN_DELETE && prob(VINE_DELETE_CHANCE)) || LAZYLEN(vines) > VINE_MAX)
		var/to_delete = pick(vines)
		var/vine_to_delete = vines[to_delete]
		vines.Remove(to_delete)
		qdel(vine_to_delete)
		vine_targets.Remove(to_delete)

	var/view_objects = view(15, get_turf(owner))
	for(var/atom/vine_target in vine_targets)
		if(!vine_target || QDELETED(vine_target) || !(vine_target in view_objects) || get_dist(owner, vine_target) > 10)
			var/vine_to_delete = vines[vine_target]
			vines.Remove(vine_target)
			qdel(vine_to_delete)
			vine_targets.Remove(vine_target)

	var/target_angle = get_angle(old_loc, get_turf(movable))
	if(target_angle < 0)
		target_angle += 360

	for(var/atom/vine_target in vines)
		var/vine_angle = get_angle(get_turf(movable), vine_target)
		if(vine_angle < 0)
			vine_angle += 360
		if(abs(vine_angle - target_angle) < 15)
			should_shoot = FALSE
			break

	if(should_shoot)
		var/turf/start_turf = get_step(get_turf(owner), pick(GLOB.alldirs))
		shoot_projectile(start_turf, set_angle = target_angle + rand(-7, 7))

/obj/item/organ/heart/jungle/proc/shoot_projectile(turf/marker, set_angle)
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/obj/projectile/heart_vine_tentacle/P = new(get_turf(owner))
	P.preparePixelProjectile(marker, get_turf(owner))
	P.firer = owner
	P.heart_origin = src
	P.fire(set_angle)
	return P

/obj/projectile/heart_vine_tentacle
	name = "vine tentacle"
	icon_state = "tentacle_jungle"
	nodamage = TRUE
	range = 11
	pass_flags = PASSTABLE | PASSMOB
	speed = 0
	var/tentacle
	var/blooming = FALSE
	var/obj/item/organ/heart/jungle/heart_origin

/obj/projectile/heart_vine_tentacle/fire(setAngle)
	if(firer)
		blooming = prob(33)
		tentacle = firer.Beam(src, icon_state = "vine_jungle[blooming ? "_blooming" : ""]", beam_type = /obj/effect/ebeam/vine)
	..()

/obj/projectile/heart_vine_tentacle/on_hit(atom/target, blocked = FALSE)
	qdel(tentacle)
	tentacle = firer.Beam(target, icon_state = "vine_jungle[blooming ? "_blooming" : ""]", beam_type = /obj/effect/ebeam/vine)
	heart_origin.vines[target] = tentacle
	heart_origin.vine_targets += target
	. = ..()

/obj/item/organ/cyberimp/arm/vine_tentacle
	name = "vine tentacle"
	desc = "You aren't supposed to see this."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "vine_tentacle"
	status = ORGAN_ORGANIC
	organ_flags = ORGAN_FROZEN|ORGAN_UNREMOVABLE
	items_to_create = list(/obj/item/vine_tentacle)
	extend_sound = 'sound/effects/splat.ogg'
	retract_sound = 'sound/effects/splat.ogg'

/obj/item/organ/cyberimp/arm/vine_tentacle/Retract()
	var/obj/item/vine_tentacle/tentacle = active_item
	if(!tentacle)
		return
	tentacle.wash(CLEAN_TYPE_BLOOD)
	return ..()

/obj/item/organ/cyberimp/arm/vine_tentacle/Remove(mob/living/carbon/target, special = 0)
	. = ..()
	qdel(src)

/obj/item/vine_tentacle
	name = "vine tentacle"
	desc = "A long, thorny vine, moving as it's alive. It has a few flowers blooming on it here and there."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "vine_tentacle"

	force = 15
	w_class = WEIGHT_CLASS_HUGE
	reach = 3
	attack_verb_continuous = list("flogs", "whips", "lashes")
	attack_verb_simple = list("flog", "whip", "lash")
	hitsound = 'sound/weapons/whip.ogg'

/obj/item/crusher_trophy/vine_tentacle
	name = "vine tentacle"
	desc = "A long, thorny vine, moving as it's alive. Suitable as a trophy for a kinetic crusher."
	icon_state = "vine_tentacle"
	denied_type = list(/obj/item/crusher_trophy/vine_tentacle, /obj/item/crusher_trophy/axe_head)
	bonus_value = 5

/obj/item/crusher_trophy/vine_tentacle/effect_desc()
	return "mark detonation to spawn a ring of vines around you that will heal you for half of incoming damage"

/obj/item/crusher_trophy/vine_tentacle/on_mark_detonation(mob/living/target, mob/living/user)
	user.apply_status_effect(STATUS_EFFECT_VINE_RING)

/obj/item/green_rose
	name = "green rose"
	desc = "A strange rose of odd green color. Weird."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "green_rose"
	w_class = WEIGHT_CLASS_TINY
	force = 0
	throwforce = 0

#undef VINE_DELETE_CHANCE
#undef VINE_MIN_DELETE
#undef VINE_MAX
#undef THROW_MOVE_COOLDOWN
#undef POWER_THROW_MOVE_COOLDOWN
#undef STAFF_VINE_COOLDOWN
