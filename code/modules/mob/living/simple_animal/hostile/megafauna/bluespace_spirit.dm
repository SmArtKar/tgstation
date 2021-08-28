/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit
	name = "bluespace spirit"
	desc = "A blue glowing spirit that came from deep layers of bluespace."
	health = 2000
	maxHealth = 2000
	icon_state = "demonic_miner"
	icon_living = "demonic_miner"
	icon = 'icons/mob/jungle/demonic_miner.dmi'

	attack_sound = 'sound/effects/curseattack.ogg'
	mob_biotypes = MOB_SPIRIT|MOB_EPIC
	light_color = COLOR_MODERATE_BLUE
	movement_type = FLYING
	speak_emote = list("wails")

	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_vis_effect = ATTACK_EFFECT_SLASH
	melee_damage_lower = 10
	melee_damage_upper = 10
	ranged = TRUE
	vision_range = 12
	aggro_vision_range = 21

	wander = FALSE
	speed = 2
	move_to_delay = 2
	retreat_distance = 3
	minimum_distance = 3
	gps_name = "Quantum Signal"

	var/list/copies = list()
	var/charging = FALSE
	var/chasming = FALSE
	var/mimicking = FALSE
	var/enraged = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/OpenFire(atom/A)
	ranged_cooldown = world.time + 3 SECONDS

	if(mimicking)
		shotgun()
		return

	if(enraged) //You really want to try and hit the real one or you're gonna be fucked
		charge()
		if(prob(85))
			shotgun(list(-10.5, -7, -3.5, 0, 3.5, 7, 10.5))
		else
			spiral_shoot_reverse(counter_length = 16)
		ranged_cooldown = world.time + 0.5 SECONDS
		return

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/shoot_projectile(turf/marker, set_angle, proj_type = /obj/projectile/bluespace_blast)
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/turf/startloc = get_turf(src)
	var/obj/projectile/P = new proj_type(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = src
	if(target)
		P.original = target
	P.fire(set_angle)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/shoot_projectile_reverse(turf/startloc, set_angle, proj_type = /obj/projectile/bluespace_blast, turf/marker = get_turf(src))
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/obj/projectile/P = new proj_type(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = src
	if(target)
		P.original = target
	P.fire(set_angle)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/spiral_shoot_reverse(negative = pick(TRUE, FALSE), counter_start = 8, counter_max = 16, counter_length = 40)
	var/counter = counter_start
	for(var/i in 1 to counter_length)
		if(negative)
			counter--
		else
			counter++
		if(counter > counter_max)
			counter = 1
		if(counter < 1)
			counter = counter_max
		var/turf/target_turf

		for(var/turf/check_turf in getline(get_turf(src), get_turf_in_angle(counter * (360 / counter_max), get_turf(src), 15)))
			if(isclosedturf(check_turf) || check_turf.is_blocked_turf(exclude_mobs = TRUE))
				break
			target_turf = check_turf

		if(target_turf)
			shoot_projectile_reverse(target_turf)
		SLEEP_CHECK_DEATH(1)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/Move()
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc, src)
		if(chasming)
			var/turf/turf = get_turf(src)
			var/reset_turf = turf.type
			if(reset_turf != /turf/open/chasm/bluespace)
				turf.ChangeTurf(/turf/open/chasm/bluespace, flags = CHANGETURF_INHERIT_AIR)
				addtimer(CALLBACK(turf, /turf.proc/ChangeTurf, reset_turf, null, CHANGETURF_INHERIT_AIR), 5 SECONDS, TIMER_OVERRIDE|TIMER_UNIQUE)
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/projectile/bluespace_blast) || istype(mover, /mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit) || charging)
		return TRUE

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/bullet_act(obj/projectile/P)
	if(istype(P, /obj/projectile/bluespace_blast))
		return BULLET_ACT_FORCE_PIERCE
	return ..()

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/triple_bouncer(start_angle = 0)
	var/turf/start_turf = get_step(src, pick(GLOB.alldirs))
	for(var/i = 1 to 3)
		shoot_projectile(start_turf, (i * 120 + start_angle) % 360,  proj_type = /obj/projectile/bluespace_blast/bouncer)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/more_bouncers()
	triple_bouncer()
	SLEEP_CHECK_DEATH(8)
	triple_bouncer(180)
	SLEEP_CHECK_DEATH(8)
	triple_bouncer()

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/charge(atom/chargeat = target, delay = 3, chargepast = 2, chasm_charge = TRUE)
	if(!chargeat)
		return
	var/chargeturf = get_turf(chargeat)
	if(!chargeturf)
		return
	var/dir = get_dir(src, chargeturf)
	var/turf/T = get_ranged_target_turf(chargeturf, dir, chargepast)
	if(!T)
		return
	charging = TRUE
	if(chasm_charge)
		chasming = TRUE
	pass_flags |= PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSTABLE | PASSMOB | PASSDOORS
	walk(src, 0)
	setDir(dir)
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, color = COLOR_BLUE, transform = matrix() * 2, time = 3)
	SLEEP_CHECK_DEATH(delay)
	var/movespeed = 1
	walk_towards(src, T, movespeed)
	SLEEP_CHECK_DEATH(get_dist(src, T) * movespeed)
	pass_flags &= ~(PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSTABLE | PASSMOB | PASSDOORS)
	walk(src, 0)
	if(chasm_charge)
		chasming = FALSE
	charging = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/angle_charge(charge_angle, charge_length = 7)
	var/turf/target_turf = get_turf_in_angle(charge_angle, get_turf(src), charge_length)
	var/turf/charge_turf
	for(var/turf/check_turf in getline(get_turf(src), target_turf))
		if(isclosedturf(check_turf) || check_turf.is_blocked_turf(exclude_mobs = TRUE))
			break
		charge_turf = check_turf
	charge(charge_turf)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/triple_charge()
	var/chosen_modifier = pick(-1, 1)
	var/target_angle = Get_Angle(src, target) + rand(0, 10) * chosen_modifier
	angle_charge(target_angle)
	target_angle = (target_angle + rand(110, 150) * chosen_modifier) % 360
	angle_charge(target_angle)
	target_angle = (target_angle + rand(110, 150) * chosen_modifier) % 360
	angle_charge(target_angle)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/bluespace_collapse(collapse_amount = rand(4, 6))
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, color = COLOR_BLUE, transform = matrix() * 2, time = 3)
	var/list/turfs = list()
	for(var/turf/open/possible_turf in orange(7, get_turf(target)))
		if(possible_turf.is_blocked_turf())
			continue
		turfs.Add(possible_turf)

	for(var/i = 1 to collapse_amount)
		var/turf/collapse_turf = pick_n_take(turfs)
		var/collapse_angle = (target && get_dist(collapse_turf, target) < 4 ? Get_Angle(collapse_turf, target) : rand(0, 360))
		var/turf/target_turf = get_turf_in_angle(collapse_angle, collapse_turf, 15)
		for(var/turf/check_turf in getline(collapse_turf, target_turf))
			if(isclosedturf(check_turf))
				target_turf = check_turf
				break
		new /obj/effect/temp_visual/bluespace_collapse(collapse_turf, target_turf)
		for(var/turf/open/turf_to_remove in orange(2, collapse_turf))
			if(sqrt((turf_to_remove.x - collapse_turf.x) ** 2 + (turf_to_remove.y - collapse_turf.y) ** 2) > 2 || !(turf_to_remove in turfs))
				continue
			turfs.Remove(turf_to_remove)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/shotgun(shot_angles = list(3.5, 0, -3.5))
	var/turf/target_turf = get_turf(target)
	var/angle_to_target = Get_Angle(src, target_turf)
	for(var/i in shot_angles)
		shoot_projectile(target_turf, angle_to_target + i, proj_type = /obj/projectile/bluespace_blast/slow)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/clone_rush(directions = pick(GLOB.cardinals, GLOB.diagonals))
	charge(target, chasm_charge = FALSE)
	var/turf/start_turf = get_step(get_turf(src), get_dir(get_step(get_turf(src), pick_n_take(directions)), get_turf(src))) //Try figuring what this is :)))) Jokes aside, this shitty line of code gets a turf in an INVERSE direction from what it picks
	new /obj/effect/temp_visual/sparks_bluespace(start_turf)
	retreat_distance = 2
	minimum_distance = 2
	mimicking = TRUE
	for(var/clone_dir in directions)
		var/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination/clone = new(get_step(start_turf, clone_dir), src)
		clone.ranged_cooldown = world.time + rand(20, 30)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(amount <= 0)
		return ..()

	if(!LAZYLEN(copies))
		return ..()

	real_was_hit()
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/fake_was_hit() //You're gonna have a baaaaad time
	retreat_distance = 3
	minimum_distance = 3
	mimicking = FALSE
	enraged = TRUE
	speed = 0
	move_to_delay = 0 //Speedy
	addtimer(CALLBACK(src, .proc/stop_rage), 20 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/stop_rage()
	enraged = FALSE
	speed = 3
	move_to_delay = 3

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/real_was_hit()
	retreat_distance = 3
	minimum_distance = 3
	mimicking = FALSE

	for(var/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination/fake in copies)
		fake.visible_message(span_danger("[fake] starts spinning and explodes in a shower of sparks!"))
		INVOKE_ASYNC(fake, /mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination.proc/fake_hit, TRUE)

/obj/projectile/bluespace_blast
	name = "bluespace blast"
	icon_state = "gaussblue"
	damage = 10
	armour_penetration = 30
	damage_type = BRUTE
	flag = MAGIC
	speed = 1

	ricochets_max = 2
	ricochet_chance = 80
	ricochet_decay_chance = 0.9
	ricochet_decay_damage = 0.9
	ricochet_auto_aim_angle = 10
	ricochet_auto_aim_range = 2
	ricochet_incidence_leeway = 0

/obj/projectile/bluespace_blast/slow
	speed = 2

/obj/projectile/bluespace_blast/check_ricochet_flag(atom/A)
	return TRUE

/obj/projectile/bluespace_blast/on_ricochet(atom/A)
	if(!ricochet_auto_aim_angle || !ricochet_auto_aim_range)
		return

	var/mob/living/unlucky_sob
	var/best_angle = ricochet_auto_aim_angle
	if(firer && HAS_TRAIT(firer, TRAIT_NICE_SHOT))
		best_angle += NICE_SHOT_RICOCHET_BONUS
	for(var/mob/living/L in range(ricochet_auto_aim_range, src.loc))
		if(L.stat == DEAD || !isInSight(src, L))
			continue
		if(isliving(firer))
			var/mob/living/living_firer = firer
			if(faction_check(living_firer.faction, L.faction))
				continue
		var/our_angle = abs(closer_angle_difference(Angle, Get_Angle(src.loc, L.loc)))
		if(our_angle < best_angle)
			best_angle = our_angle
			unlucky_sob = L

	if(unlucky_sob)
		set_angle(Get_Angle(src, unlucky_sob.loc))

/obj/projectile/bluespace_blast/bouncer
	name = "bluespace bouncer"
	icon_state = "bluespace_bouncer"
	damage = 65
	armour_penetration = 100
	speed = 2

	ricochets_max = 30 //Fun time!
	ricochet_chance = 600
	ricochet_decay_chance = 0.99
	ricochet_decay_damage = 1
	ricochet_auto_aim_angle = 35
	ricochet_auto_aim_range = 15

/obj/projectile/bluespace_bouncer/Initialize()
	. = ..()
	SpinAnimation()

/obj/effect/temp_visual/bluespace_collapse
	icon_state = "bluespace_collapse"
	layer = BELOW_MOB_LAYER
	duration = 7
	var/turf/target_turf

/obj/effect/temp_visual/bluespace_collapse/Initialize(mapload, new_target_turf)
	. = ..()
	target_turf = new_target_turf
	Beam(target_turf, icon_state = "bluespace_beam_prepare", time = 7)

/obj/effect/temp_visual/bluespace_collapse/Destroy()
	playsound(get_turf(src), 'sound/magic/lightningbolt.ogg', 50, TRUE)
	Beam(target_turf, icon_state = "bluespace_beam", time = 6)
	for(var/turf/check_turf in getline(get_turf(src), target_turf))
		for(var/mob/living/victim in check_turf.contents)
			if(!faction_check(victim.faction, list("jungle", "boss")))
				victim.Paralyze(1) //Make em drop
				victim.adjustBruteLoss(30)
				to_chat(victim, span_userdanger("You're hit by a bluespace collapse beam!"))
				if(ishuman(victim))
					var/mob/living/carbon/human/human_victim = victim
					human_victim.electrocution_animation(1 SECONDS)

	. = ..()

/turf/open/chasm/bluespace
	icon = 'icons/turf/floors/bluechasms.dmi'
	initial_gas_mix = JUNGLE_DEFAULT_ATMOS
	planetary_atmos = TRUE
	baseturfs = /turf/open/chasm/bluespace
	layer = 1.98
	light_range = 1.9
	light_power = 0.65
	light_color = COLOR_MODERATE_BLUE
	smoothing_groups = list(SMOOTH_GROUP_TURF_CHASM)

/turf/open/chasm/bluespace/Initialize()
	. = ..()
	AddComponent(/datum/component/chasm/bluespace) //We lead to a random open turf in 14 tile radius, but not closer than 6 tiles to initial location

/// Hallucination mob

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination
	health = 1
	maxHealth = 1
	retreat_distance = 2
	minimum_distance = 2
	mimicking = TRUE

	var/suicide_active = FALSE
	var/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/summoner

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination/Initialize(mapload, new_summoner)
	. = ..()
	summoner = new_summoner
	summoner.copies.Add(src)
	GiveTarget(summoner.target)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination/Life(delta_time = SSMOBS_DT, times_fired)
	. = ..()
	med_hud_set_health()

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination/med_hud_set_health()
	if(summoner)
		var/image/holder = hud_list[HEALTH_HUD]
		holder.icon_state = "hud[RoundHealth(summoner)]"

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(amount <= 0)
		return ..()

	if(suicide_active)
		return

	summoner.fake_was_hit()

	for(var/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination/fake in summoner.copies)
		fake.visible_message(span_danger("[fake] starts spinning and explodes in a shower of sparks!"))
		INVOKE_ASYNC(fake, .proc/fake_hit)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination/proc/fake_hit(fast = FALSE)
	suicide_active = TRUE
	sleep(rand(0, 4))
	if(!fast)
		spin(16, 2)
		animate(src, pixel_y = pixel_y + 16, time = 16, easing = ELASTIC_EASING)
		sleep(16)
	else
		spin(8, 1)
		animate(src, pixel_y = pixel_y + 16, time = 8, easing = ELASTIC_EASING)
		sleep(8)
	playsound(src, "sparks", 75, TRUE)
	new /obj/effect/temp_visual/sparks_bluespace(get_turf(src))
	for(var/turf/open/possible_turf in orange(3, src))
		if(prob(40))
			new /obj/effect/temp_visual/sparks_bluespace(possible_turf)
	flick("jaunt_start", src)
	sleep(round(13 * 0.7))
	playsound(get_turf(src), 'sound/effects/explosion3.ogg', 75, TRUE)
	summoner.copies.Remove(src)
	qdel(src)

/obj/effect/temp_visual/sparks_bluespace
	icon_state = "sparks_bluespace"
	duration = 6
