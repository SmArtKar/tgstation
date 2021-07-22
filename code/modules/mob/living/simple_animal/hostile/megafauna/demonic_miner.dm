/**
 * Demonic Miner
 *
 * Basically jungle demonic frost miner. Second endgame boss as alternative to ancient AI
 *
 * This fucker has like what, 8-10 patterns and attack moves, I am not going to list all of them
 * Just know that he can: Use a giant laser beam, spawn lines/circles of hiero-like blasts under you, jaunt, shoot projectiles in spirals and shoot spheres that create warning lasers and then shoot real ones.
 *
 * This one literraly ate my soul out, go kill him as brutally as you can ~SmArtKar
 *
 * Intended Difficulty: OH FUCK OH GOD
 *
 */

#define BLOOD_JAUNT_LENGTH 2 SECONDS

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner
	name = "demonic miner"
	desc = "A body of some poor dead miner, posessed by an ancient demon."
	health = 3000
	maxHealth = 3000
	icon_state = "demonic_miner"
	icon_living = "demonic_miner"
	icon = 'icons/mob/jungle/demonic_miner.dmi'

	attack_sound = 'sound/weapons/slash.ogg'
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID|MOB_EPIC
	light_color = COLOR_RED_LIGHT
	movement_type = GROUND
	speak_emote = list("roars")

	armour_penetration = 60
	melee_damage_lower = 20
	melee_damage_upper = 20
	ranged = TRUE
	vision_range = 18
	rapid_melee = 1
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"

	speed = 5
	move_to_delay = 20
	wander = FALSE
	gps_name = "Posessed Signal"

	pixel_y = -1

	crusher_loot = list(/obj/effect/decal/remains)
	loot = list(/obj/effect/decal/remains)
	del_on_death = TRUE
	blood_volume = BLOOD_VOLUME_NORMAL
	deathmessage = "falls to the ground as demon that possesses it dies."
	deathsound = "bodyfall"
	footstep_type = FOOTSTEP_MOB_HEAVY
	var/demon_form = FALSE
	var/noaction = FALSE
	var/nodamage = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/Initialize()
	. = ..()
	pixel_y = -1

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/update_icon(updates)
	if(demon_form)
		icon_state = "demon_form"
		icon_living = "demon_form"
	else
		icon_state = "demonic_miner"
		icon_living = "demonic_miner"
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/death()
	. = ..()
	if(.)
		if(demon_form)
			new /obj/effect/temp_visual/dir_setting/miner_death/demonic/demon_form(loc, dir)
		else
			new /obj/effect/temp_visual/dir_setting/miner_death/demonic(loc, dir)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/ex_act(severity, target)
	adjustBruteLoss(-30 * severity)
	visible_message(span_danger("[src] absorbs the explosion!"), span_userdanger("You absorb the explosion!"))

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/jaunt_at(atom/victim)
	var/turf/target_turf = get_turf(victim)

	flick("jaunt_[demon_form ? "demon_" : ""]start", src)
	noaction = TRUE
	nodamage = TRUE
	set_density(FALSE)
	playsound(target_turf, 'sound/magic/ethereal_enter.ogg', 50, TRUE, -1)
	SLEEP_CHECK_DEATH(9)
	invisibility = INVISIBILITY_MAXIMUM
	addtimer(CALLBACK(src, .proc/end_jaunt, target_turf), BLOOD_JAUNT_LENGTH)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/end_jaunt(turf/target_turf)
	forceMove(target_turf)
	playsound(target_turf, 'sound/magic/ethereal_exit.ogg', 50, TRUE, -1)
	invisibility = initial(invisibility)
	flick("jaunt_[demon_form ? "demon_" : ""]end", src)
	SLEEP_CHECK_DEATH(9)
	noaction = FALSE
	nodamage = FALSE
	set_density(TRUE)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(nodamage)
		return FALSE
	. = ..()
	if(. && health <= maxHealth * 0.5 && !demon_form)
		become_demon()

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/become_demon()
	demon_form = TRUE
	noaction = TRUE
	nodamage = TRUE
	spin(30, 2)
	SLEEP_CHECK_DEATH(30)
	playsound(src, 'sound/effects/explosion3.ogg', 100, TRUE)
	playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	armour_penetration = 100
	melee_damage_lower = 30
	melee_damage_upper = 30
	update_icon()
	nodamage = FALSE
	noaction = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/channel_ray(starting_angle = 0, ending_angle = 360, angle_step = 5, fixed_time = 0)
	var/current_angle = starting_angle
	var/cur_time = 0
	if(starting_angle > ending_angle)
		angle_step *= -1

	var/turf/cur_turf = get_turf(src)
	var/turf/target_turf = get_turf_in_angle(current_angle, cur_turf, 40)

	var/obj/effect/temp_beam_target/temp_target = new(get_turf(target_turf))
	var/obj/effect/abstract/demon_beam_splash/splash = new(cur_turf)
	var/beam
	var/list/already_hit = list()

	noaction = TRUE

	while((ending_angle > starting_angle && current_angle < ending_angle) || (ending_angle < starting_angle && current_angle > ending_angle))
		for(var/turf/check_turf in getline(cur_turf, target_turf))
			if(isclosedturf(check_turf))
				target_turf = check_turf
				break

			for(var/mob/living/victim in check_turf.contents)
				if(victim != src && !faction_check(victim.faction, faction) && !(victim in already_hit))
					victim.Paralyze(20)
					victim.adjustBruteLoss(30)
					playsound(victim, 'sound/machines/clockcult/ark_damage.ogg', 50, TRUE)
					to_chat(victim, span_userdanger("You're hit by a demonic ray!"))
					already_hit.Add(victim)

		temp_target.forceMove(target_turf)
		beam = Beam(temp_target, icon_state = "bsa_beam_red", beam_type = /obj/effect/ebeam/demonic, time = 1)
		var/matrix/splash_matrix = matrix()
		splash_matrix.Turn(current_angle)
		splash_matrix.Translate(cos(current_angle + 90) * 16, -sin(current_angle + 90) * 16)
		splash.transform = splash_matrix

		current_angle += angle_step
		cur_time += 1
		target_turf = get_turf_in_angle(current_angle, cur_turf, 40)
		setDir(angle2dir(current_angle))
		SLEEP_CHECK_DEATH(1)

	noaction = FALSE
	qdel(beam)
	qdel(temp_target)
	qdel(splash)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/blast_line(atom/targeting = null)
	if(!targeting)
		targeting = target
	var/target_turf = get_turf(targeting)
	var/end_turf = get_ranged_target_turf_direct(src, target_turf, 40, 0)
	var/turf_line = getline(get_turf(src), end_turf) - get_turf(src)
	for(var/turf/targeting_turf in turf_line)
		if(isclosedturf(targeting_turf))
			return

		if(demon_form)
			new /obj/effect/temp_visual/demonic_blast_warning/quick(targeting_turf)
			continue

		new /obj/effect/temp_visual/demonic_blast_warning(targeting_turf)
		SLEEP_CHECK_DEATH(1)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/blast_line_directions(list/dirs = pick(GLOB.cardinals, GLOB.diagonals))
	for(var/blast_dir in dirs)
		var/turf/target_turf = get_turf(src)
		while(!isclosedturf(target_turf))
			target_turf = get_step(target_turf, blast_dir)
			if(demon_form)
				new /obj/effect/temp_visual/demonic_blast_warning/quick(target_turf)
			else
				new /obj/effect/temp_visual/demonic_blast_warning(target_turf)

		SLEEP_CHECK_DEATH(1)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/triple_blast_line()
	blast_line(target)
	SLEEP_CHECK_DEATH(3)
	blast_line(target)
	SLEEP_CHECK_DEATH(3)
	blast_line(target)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/blast_circle(atom/targeting = null, attack_range = 2)
	if(!targeting)
		targeting = target
	var/turf/target_turf = get_turf(targeting)
	var/cur_range = 0
	for(var/turf/targeting_turf in range(attack_range, target_turf))
		if(sqrt((targeting_turf.x - target_turf.x) ** 2 + (targeting_turf.y - target_turf.y) ** 2) > cur_range)
			cur_range = sqrt((targeting_turf.x - target_turf.x) ** 2 + (targeting_turf.y - target_turf.y) ** 2)
			SLEEP_CHECK_DEATH(demon_form ? 0 : 2)

		if(cur_range > attack_range)
			continue

		new /obj/effect/temp_visual/demonic_blast_warning(targeting_turf)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/shoot_projectile(turf/marker, set_angle, proj_type = /obj/projectile/demonic_energy)
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/turf/startloc = get_turf(src)
	var/obj/projectile/P = new proj_type(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = src
	if(target)
		P.original = target
	P.fire(set_angle)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/spiral_shoot(negative = pick(TRUE, FALSE), counter_start = 8)
	var/turf/start_turf = get_step(src, pick(GLOB.alldirs))
	var/counter = counter_start
	for(var/i in 1 to 80)
		if(negative)
			counter--
		else
			counter++
		if(counter > 16)
			counter = 1
		if(counter < 1)
			counter = 16
		shoot_projectile(start_turf, counter * 22.5)
		SLEEP_CHECK_DEATH(1)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/Move()
	if(noaction)
		return

	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/AttackingTarget()
	if(noaction)
		return

	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/OpenFire()
	if(noaction)
		return

	anger_modifier = clamp(((maxHealth - health) / 100),0,20)
	ranged_cooldown = world.time + ((demon_form ? 3 : 5) SECONDS)

	var/picked_attack = rand(1, 6)
	switch(picked_attack)
		if(1)
			jaunt_at(target)
			ranged_cooldown = world.time + BLOOD_JAUNT_LENGTH + ((demon_form ? 3 : 5) SECONDS)
			SLEEP_CHECK_DEATH(BLOOD_JAUNT_LENGTH + 2 SECONDS)
			spiral_shoot()
		if(2)
			channel_ray(Get_Angle(src, target) - 45, Get_Angle(src, target) + 45)
			ranged_cooldown = world.time + 7 SECONDS
		if(3)
			triple_blast_line()
		if(4)
			blast_circle(target)
		if(5)
			if(demon_form)
				blast_line(target)
			shoot_projectile(get_turf(target), proj_type = /obj/projectile/bloody_orb)
		if(6)
			blast_circle(target)
			SLEEP_CHECK_DEATH(demon_form ? 2 : 4)
			blast_circle(target, (demon_form ? 2 : 1))
			if(demon_form)
				SLEEP_CHECK_DEATH(2)
				blast_circle(target)
			ranged_cooldown = world.time + 4 SECONDS
		if(7)
			if(demon_form)
				blast_line_directions(GLOB.alldirs)
				SLEEP_CHECK_DEATH(4)
				spiral_shoot()
				return
			blast_line_directions()

/obj/effect/ebeam/demonic
	name = "demonic beam"
	light_range = 1
	light_power = 0.5
	light_color = COLOR_RED_LIGHT

/obj/effect/temp_visual/demonic_blast_warning
	name = "demonic blast warning"
	icon_state = "demonic_blast_warning"
	duration = 4
	light_range = 1
	light_power = 0.5
	light_color = COLOR_RED_LIGHT

/obj/effect/temp_visual/demonic_blast_warning/Destroy()
	new /obj/effect/temp_visual/demonic_blast(get_turf(src))
	. = ..()

/obj/effect/temp_visual/demonic_blast_warning/quick
	icon_state = "demonic_blast_warning_quick"
	duration = 2

/obj/effect/temp_visual/demonic_blast
	name = "demonic blast"
	icon_state = "demonic_blast"
	duration = 5
	light_range = 2
	light_power = 0.5
	light_color = COLOR_RED_LIGHT

/obj/effect/temp_visual/demonic_blast/Initialize()
	. = ..()
	var/turf/my_turf = get_turf(src)
	if(!locate(/mob/living) in my_turf)
		return

	playsound(src, 'sound/magic/mm_hit.ogg', 100, TRUE)
	for(var/mob/living/target in my_turf)
		if(istype(target, /mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner))
			continue
		target.adjustFireLoss(20)
		to_chat(target, span_userdanger("You're hit by a demonic blast!"))

/obj/effect/temp_visual/dir_setting/miner_death/demonic
	icon = 'icons/mob/jungle/demonic_miner.dmi'
	icon_state = "demonic_miner_death"

/obj/effect/temp_visual/dir_setting/miner_death/demonic/demon_form
	icon_state = "demon_form_death"

/obj/effect/abstract/demon_beam_splash
	icon = 'icons/mob/jungle/demonic_miner_big.dmi'
	icon_state = "beam_splash_red_nodir"
	layer = RIPPLE_LAYER
	pixel_x = -16
	pixel_y = -16

/obj/effect/temp_beam_target
	name = "temporary beam target"
	invisibility = INVISIBILITY_MAXIMUM

/obj/projectile/bloody_orb
	name = "bloody orb"
	icon_state = "blood_orb"
	damage = 0
	nodamage = TRUE
	speed = 16

	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSMOB | PASSFLAPS
	var/list/beam_targets = list()
	var/list/beams = list()

/obj/projectile/bloody_orb/fire(angle, atom/direct_target)
	. = ..()
	cast_rays()

/obj/projectile/bloody_orb/on_hit(atom/target, blocked, pierce_hit)
	start_rays()

/obj/projectile/bloody_orb/proc/start_rays()
	speed = INFINITY //Don't move
	for(var/beam in beams)
		qdel(beam)

	playsound(get_turf(src), 'sound/magic/magic_missile.ogg', 100, TRUE)

	var/list/already_hit = list()

	for(var/beam_target in beam_targets)
		Beam(beam_target, icon_state = "blood_beam_thin", beam_type = /obj/effect/ebeam/demonic, time = 10)

		var/target_turf = get_turf(beam_target)
		var/end_turf = get_ranged_target_turf_direct(src, target_turf, 40, 0)
		var/turf_line = getline(get_turf(src), end_turf)
		for(var/turf/targeting_turf in turf_line)
			if(isclosedturf(targeting_turf))
				break

			for(var/mob/living/victim in targeting_turf)
				if(istype(victim, /mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner) || (victim in already_hit))
					continue
				already_hit.Add(victim)
				victim.adjustBruteLoss(30)
				playsound(victim, 'sound/machines/clockcult/ark_damage.ogg', 50, TRUE)
				to_chat(victim, span_userdanger("You're hit by a demonic beam!"))

	for(var/beam_target in beam_targets)
		qdel(beam_target)

	QDEL_IN(src, 5)

/obj/projectile/bloody_orb/proc/cast_rays()
	addtimer(CALLBACK(src, .proc/start_rays), 5 SECONDS)
	var/turf/cur_turf = get_turf(src)
	for(var/i = 1 to 5)
		var/angle = rand(1, 359)
		var/turf/target_turf = get_turf_in_angle(angle, cur_turf, 40)
		var/obj/effect/temp_beam_target/temp_target = new(get_turf(target_turf))

		for(var/turf/check_turf in getline(cur_turf, target_turf))
			if(isclosedturf(check_turf))
				target_turf = check_turf
				break

		temp_target.forceMove(target_turf)
		var/beam = Beam(temp_target, icon_state = "blood_beam_thin_prepare", beam_type = /obj/effect/ebeam/demonic)
		beam_targets.Add(temp_target)
		beams.Add(beam)

/obj/projectile/demonic_energy
	name = "demonic blast"
	icon_state = "demonic_energy"
	damage = 15
	armour_penetration = 100
	speed = 2
	damage_type = BURN

#undef BLOOD_JAUNT_LENGTH
