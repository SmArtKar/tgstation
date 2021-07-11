#define VORE_PROBABLILITY 40
#define EGG_LENGTH 5 SECONDS

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen
	name = "cave spider queen"
	desc = "A giant cave spider. It looks hungry."
	health = 2500
	maxHealth = 2500

	icon = 'icons/mob/jungle/spider_queen.dmi'
	icon_state = "spider_queen"
	icon_living = "spider_queen"
	icon_dead = "spider_queen_dead"

	faction = list("boss", "jungle", "spiders")
	speak_emote = list("chitters")
	combat_mode = TRUE

	mob_biotypes = MOB_ORGANIC | MOB_BEAST | MOB_EPIC | MOB_BUG
	speed = 4
	move_to_delay = 4
	footstep_type = FOOTSTEP_MOB_CLAW

	melee_damage_lower = 25
	melee_damage_upper = 25
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'

	ranged = TRUE
	ranged_cooldown_time = 30
	aggro_vision_range = 18

	loot = list()
	crusher_loot = list()

	wander = TRUE
	gps_name = "Webbed Signal"
	del_on_death = FALSE
	pixel_x = -3
	var/list/vored = list()
	var/charging = FALSE
	var/list/babies = list()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/Initialize()
	. = ..()
	update_appearance()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_glow")

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/AttackingTarget()
	if(charging)
		return

	if(target && istype(target.loc, /obj/structure/spider/cocoon))
		GiveTarget(null)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/OpenFire()
	if(charging)
		return

	if(target && istype(target.loc, /obj/structure/spider/cocoon))
		GiveTarget(null)
		return

	ranged_cooldown = world.time + 30
	anger_modifier = clamp(((maxHealth - health)/60), 0, 20)

	if(get_dist(src, target) > aggro_vision_range / 2 || prob(anger_modifier + 25))
		charge()
		return

	if(prob(50 - anger_modifier) && LAZYLEN(babies) < 8)
		triple_birth()
		return

	if(prob(40))
		triple_charge()
		if(prob(40 + anger_modifier))
			shockwave()
			ranged_cooldown = world.time + 60
		return

	shotgun()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/CanAttack(atom/the_target)
	if(istype(the_target.loc, /obj/structure/spider/cocoon))
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/devour(mob/living/cocoon_target)
	ADD_TRAIT(cocoon_target, TRAIT_HUSK, BURN) //Let's make em husked from "burns" so they can be unhusked with synthflesh.

	if(!is_station_level(z) || client)
		adjustBruteLoss(-cocoon_target.maxHealth/2)

	if(prob(VORE_PROBABLILITY))
		visible_message(span_danger("[src] devours [cocoon_target]!"), span_userdanger("You feast on [cocoon_target], restoring your health!"))
		cocoon_target.forceMove(src)
		vored.Add(cocoon_target)
		return

	var/obj/structure/spider/cocoon/queen/cocoon = new(cocoon_target.loc)
	cocoon_target.forceMove(cocoon)
	cocoon.icon_state = pick("cocoon_large1","cocoon_large2","cocoon_large3")
	visible_message(span_danger("[src] wraps [cocoon_target] into cocoon!"), span_userdanger("You suck [cocoon_target] dry and wrap them in a cocoon, restoring your health!"))

/obj/structure/spider/cocoon/queen/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	return

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/death(gibbed)
	. = ..()
	if(!gibbed)
		for(var/mob/vore_target in vored)
			vore_target.forceMove(get_turf(src)) //Empties contents of it's stomach upon death

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/Bump(atom/A) //Shamelessly stolen from Bubblegum
	if(charging)
		if(isturf(A) || isobj(A) && A.density)
			if(isobj(A))
				SSexplosions.med_mov_atom += A
			else
				SSexplosions.medturf += A
		DestroySurroundings()
		if(isliving(A))
			var/mob/living/victim = A
			victim.visible_message(span_danger("[src] slams into [victim]!"), span_userdanger("[src] tramples you into the ground!"))
			forceMove(get_turf(victim))
			victim.apply_damage(30, BRUTE, wound_bonus = CANT_WOUND)
			playsound(get_turf(victim), 'sound/effects/meteorimpact.ogg', 100, TRUE)
			shake_camera(victim, 4, 3)
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/proc/charge(chargepast = 2, delay = 3) //If you try to run from me I will groundpound your ass
	var/turf/chargeturf = get_turf(target)
	var/dir = get_dir(src, chargeturf)
	var/turf/target_turf = get_ranged_target_turf(chargeturf, dir, chargepast)

	if(!target_turf)
		return

	charging = TRUE
	DestroySurroundings()
	walk(src, 0)
	setDir(dir)
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, color = "#FF0000", transform = matrix()*2, time = 3)
	SLEEP_CHECK_DEATH(delay)
	var/movespeed = 0.5
	walk_towards(src, target_turf, movespeed)
	SLEEP_CHECK_DEATH(get_dist(src, target_turf) * movespeed)
	walk(src, 0)
	charging = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/proc/shoot_projectile(turf/marker, set_angle)
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/turf/startloc = get_turf(src)
	var/obj/projectile/P = new /obj/projectile/web_ball(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = src
	if(target)
		P.original = target
	P.fire(set_angle)

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(charging)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/AttackingTarget()
	if(charging)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/Goto(target, delay, minimum_distance)
	if(charging)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/MoveToTarget(list/possible_targets)
	if(charging)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/Move()
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc, src)
		DestroySurroundings()
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/proc/triple_charge()
	charge(delay = 6)
	charge(delay = 4)
	charge(delay = 2)
	ranged_cooldown = world.time + 15

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/proc/triple_birth()
	for(var/i = 1 to 3)
		create_baby_cocoon()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/proc/create_baby_cocoon()
	var/list/possible_turfs = list()
	for(var/turf/fitting_turf in range(3, src))
		if(isopenturf(fitting_turf) && !fitting_turf.is_blocked_turf())
			possible_turfs[fitting_turf] = get_dist(src, fitting_turf)

	var/obj/structure/spider/queen_egg/egg = new(pickweight(possible_turfs))
	egg.mommy = src

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/proc/shotgun(set_angle)
	ranged_cooldown = world.time + 20
	var/turf/target_turf = get_turf(target)
	var/angle_to_target = Get_Angle(src, target_turf)
	if(isnum(set_angle))
		angle_to_target = set_angle
	var/static/list/shotgun_shot_angles = list(12.5, 7.5, 2.5, -2.5, -7.5, -12.5)
	for(var/i in shotgun_shot_angles)
		shoot_projectile(target_turf, angle_to_target + i)

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/proc/shockwave(range = 3, iteration_duration = 5)
	visible_message("<span class='boldwarning'>[src] smashes the ground around them!</span>")
	playsound(src, 'sound/weapons/sonic_jackhammer.ogg', 200, 1) //I mean, why not?
	SLEEP_CHECK_DEATH(10)
	var/list/hit_things = list()
	for(var/i in 1 to range)
		for(var/turf/T in (view(i, src) - view(i - 1, src)))
			if(!T)
				return
			new /obj/effect/temp_visual/small_smoke/halfsecond(T)
			for(var/mob/living/L in T.contents)
				if(L != src && !(L in hit_things) && !faction_check(L.faction, faction))
					var/throwtarget = get_edge_target_turf(T, get_dir(T, L))
					L.safe_throw_at(throwtarget, 5, 1, src)
					L.Stun(10)
					L.apply_damage_type(20, BRUTE)
					hit_things += L
		sleep(iteration_duration)

/mob/living/simple_animal/hostile/jungle/cave_spider/baby
	name = "baby cave spider"
	desc = "A pitch-black cave spider baby with glowing purple eyes and turquoise stripe on it's back. "
	icon_state = "cave_spider_dark"
	icon_living = "cave_spider_dark"
	icon_dead = "cave_spider_dark_dead"
	maxHealth = 50
	health = 50
	melee_damage_lower = 10
	melee_damage_upper = 10
	crusher_drop_mod = 0
	jump_mod = 0.5
	ranged_cooldown_time = 4 SECONDS
	var/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/mommy

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/Initialize()
	. = ..()
	update_appearance()

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_glow")

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/death(gibbed)
	mommy.babies.Remove(src)
	. = ..()

/obj/structure/spider/queen_egg
	name = "black cocoon"
	desc = "A pitch black spider cocoon. What could be inside?.."
	icon_state = "cocoon_black"
	var/birth_timer
	var/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/mommy

/obj/structure/spider/queen_egg/Initialize(mapload)
	. = ..()
	birth_timer = addtimer(CALLBACK(src, .proc/give_birth), EGG_LENGTH, TIMER_UNIQUE | TIMER_STOPPABLE)

/obj/structure/spider/queen_egg/Destroy()
	if(birth_timer)
		deltimer(birth_timer)
	. = ..()

/obj/structure/spider/queen_egg/proc/give_birth()
	var/mob/living/simple_animal/hostile/jungle/cave_spider/baby/spidey = new(get_turf(src))
	new /obj/effect/decal/cleanable/insectguts(get_turf(src))
	visible_message(span_warning("[src] bursts, revealing a [spidey]!"))
	mommy.babies.Add(spidey)
	spidey.mommy = mommy
	qdel(src)

/obj/structure/spider/queen_egg/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	return

/obj/projectile/web_ball
	name = "ball of web"
	nodamage = TRUE
	speed = 4

/obj/projectile/web_ball/fire(set_angle)
	. = ..()

	firer.Beam(src, icon_state = "web", beam_type=/obj/effect/ebeam/web)

/obj/projectile/web_ball/on_hit(atom/movable/targeted, blocked, pierce_hit)
	. = ..()
	if (. == BULLET_ACT_HIT)
		var/datum/beam/web = firer.Beam(targeted, icon_state = "web", beam_type=/obj/effect/ebeam/web)
		if(isliving(targeted))
			var/mob/living/L = targeted
			L.throw_at(firer, get_dist(L, firer), 2, firer, FALSE, TRUE)
			L.Paralyze(1 SECONDS)
		QDEL_IN(web, 3 SECONDS)


#undef VORE_PROBABLILITY
#undef EGG_LENGTH
