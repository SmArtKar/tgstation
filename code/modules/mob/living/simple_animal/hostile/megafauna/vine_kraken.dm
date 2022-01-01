#define VINE_DELETE_CHANCE 35
#define VINE_MIN_DELETE 4
#define VINE_MAX 6
#define THROW_MOVE_COOLDOWN 3 SECONDS
#define POWER_THROW_MOVE_COOLDOWN 0.5 SECONDS

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken
	name = "vine kraken"
	desc = "A terrifying moster made out entirely of jungle vines."
	health = 3000
	maxHealth = 3000
	icon_state = "vine_kraken"
	icon_living = "vine_kraken"
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
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stabs"
	obj_damage = 200
	pixel_x = -8
	base_pixel_x = -8
	pixel_y = -8
	base_pixel_y = -8

	wander = FALSE
	speed = 3
	move_to_delay = 3
	gps_name = "Solar Signal"


	var/list/vines = list()
	var/list/vine_targets = list()
	var/already_moving = FALSE
	var/move_cooldown
	var/immobile = FALSE
	var/throw_spree = 0

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

	if(prob(35 + anger_modifier) && !throw_spree)
		throwing_spree()
		ranged_cooldown = world.time + 2 SECONDS
		return

	if(health < maxHealth * 0.5)
		INVOKE_ASYNC(src, .proc/spiral_shoot)
		SLEEP_CHECK_DEATH(0.5 SECONDS)
		var/radius_active = FALSE
		if(prob(10 + anger_modifier))
			triple_radius()
			radius_active = TRUE

		if(prob(35))
			vine_attack()
			if(prob(anger_modifier + 15) && !radius_active)
				SLEEP_CHECK_DEATH(2 SECONDS)
				attack_in_radius()
		else
			solar_barrage()
			vine_attack()
			SLEEP_CHECK_DEATH(0.5 SECONDS)
			vine_attack()
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
				SLEEP_CHECK_DEATH(1.5 SECONDS)
				vine_attack()
			if(5)
				INVOKE_ASYNC(src, .proc/spiral_shoot)

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/Goto(target, delay, minimum_distance)
	if(target == src.target)
		approaching_target = TRUE
	else
		approaching_target = FALSE
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
			qdel(vines[LAZYLEN(vines)])

		var/view_objects = view(15, get_turf(src))
		for(var/atom/vine_target in vine_targets)
			if(!vine_target || QDELETED(vine_target) || !(vine_target in view_objects))
				qdel(vines[vine_target])
				vine_targets.Remove(vine_target)

		var/target_angle = get_angle(src, target)
		if(target_angle < 0)
			target_angle += 360
		for(var/atom/vine_target in vine_targets)
			var/vine_angle = get_angle(src, vine_target)
			if(vine_angle < 0)
				vine_angle += 360
			if(abs(vine_angle - target_angle) < 30)
				should_shoot = FALSE
				break

		if(!should_shoot)
			process_vine_move(target, FALSE)
			return
		shoot_projectile(get_turf(target), mark_target = FALSE)

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	if((LAZYLEN(vines) > VINE_MIN_DELETE && prob(VINE_DELETE_CHANCE)) || LAZYLEN(vines) > VINE_MAX)
		qdel(vines[LAZYLEN(vines)])

	already_moving = FALSE

	var/view_objects = view(15, get_turf(src))
	for(var/atom/vine_target in vine_targets)
		if(!vine_target || QDELETED(vine_target) || !(vine_target in view_objects))
			qdel(vines[vine_target])
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
		if(throw_spree)
			SLEEP_CHECK_DEATH(5)
			Goto(target, move_to_delay, 1)
		return

	var/mob/living/victim = hit_atom
	victim.visible_message(span_danger("[src] slams into [victim]!"), span_userdanger("[src] slams into you, sending you flying!"))
	to_chat(src, span_warning("You slam into [victim]!"))
	var/turf/throw_target = get_ranged_target_turf(victim, get_dir(src, hit_atom), 40)
	victim.throw_at(throw_target, 40, 3) //YEEEEEEET
	if(throw_spree)
		SLEEP_CHECK_DEATH(5)
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
	var/static/list/barrage_shot_angles = list(12.5, 7.5, 2.5, -2.5, -7.5, -12.5)
	var/target_angle = get_angle(src, target)
	var/turf/target_turf = get_turf(target)
	for(var/i in barrage_shot_angles)
		shoot_projectile(target_turf, target_angle + i, proj_type = /obj/projectile/solar)

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/spiral_shoot(counter_start = 8, blasts_per_circle = 16, negative = pick(TRUE, FALSE), proj_type = /obj/projectile/solar_particle)
	immobile = TRUE
	walk_to(src, 0)
	var/turf/start_turf = get_step(src, pick(GLOB.alldirs))
	var/counter = counter_start
	for(var/i in 1 to 32)
		if(negative)
			counter--
		else
			counter++
		if(counter > blasts_per_circle)
			counter = 1
		if(counter < 1)
			counter = blasts_per_circle
		shoot_projectile(start_turf, counter * (360 / blasts_per_circle), proj_type = /obj/projectile/solar_particle)
		SLEEP_CHECK_DEATH(1)
	immobile = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/vine_attack()
	immobile = TRUE
	walk_to(src, 0)
	for(var/i = 1 to 3)
		shoot_projectile(null, get_angle(src, target) + rand(-15, 15), proj_type = /obj/projectile/vine_spawner)
		SLEEP_CHECK_DEATH(1 SECONDS)
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
	SLEEP_CHECK_DEATH(20)
	attack_in_radius(TRUE, FALSE)
	SLEEP_CHECK_DEATH(20)
	attack_in_radius(FALSE, FALSE)
	immobile = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/proc/throwing_spree()
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

/obj/projectile/vine_tentacle/fire(setAngle)
	if(firer)
		tentacle = firer.Beam(src, icon_state = "vine_jungle", beam_type = /obj/effect/ebeam/vine)
	..()

/obj/projectile/vine_tentacle/on_hit(atom/target, blocked = FALSE)
	qdel(tentacle)
	var/vine = firer.Beam(target, icon_state = "vine_jungle[throwing_proj ? "_blooming" : ""]", beam_type = /obj/effect/ebeam/vine)
	if(istype(firer, /mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken))
		var/mob/living/simple_animal/hostile/megafauna/jungle/vine_kraken/kraken = firer
		kraken.vines[target] = vine
		kraken.vine_targets.Add(target)
		kraken.process_vine_move(target, throwing_proj)
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
	damage = 35
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

/obj/projectile/vine_spawner/on_hit(atom/target, blocked, pierce_hit)
	qdel(src)

/obj/projectile/vine_spawner/pixel_move(trajectory_multiplier, hitscanning = FALSE)
	. = ..()
	if(!loc)
		return

	if(locate(/obj/effect/temp_visual/goliath_tentacle/vine_kraken) in get_turf(src))
		return

	new /obj/effect/temp_visual/goliath_tentacle/vine_kraken(get_turf(src), firer)

#undef VINE_DELETE_CHANCE
#undef VINE_MIN_DELETE
#undef VINE_MAX
#undef THROW_MOVE_COOLDOWN
#undef POWER_THROW_MOVE_COOLDOWN
