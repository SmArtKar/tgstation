/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit
	name = "bluespace spirit"
	desc = "A blue glowing spirit that came from deep layers of bluespace."
	health = 2000
	maxHealth = 2000
	icon_state = "bluespace_spirit"
	icon_living = "bluespace_spirit"
	icon = 'icons/mob/jungle/jungle_monsters.dmi'

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
	former_target_vision_range = 21

	achievement_type = /datum/award/achievement/boss/bluespace_spirit_kill
	crusher_achievement_type = /datum/award/achievement/boss/bluespace_spirit_crusher
	score_achievement_type = /datum/award/score/bluespace_spirit_score

	wander = FALSE
	speed = 3
	move_to_delay = 3
	retreat_distance = 3
	minimum_distance = 3
	gps_name = "Quantum Signal"
	del_on_death = TRUE

	loot = list(/obj/item/space_cutter)
	common_loot = list(/obj/item/guardiancreator/tech/spacetime, /obj/item/bluespace_megacrystal) //Rewarding everybody who killed him because he becomes very difficult with multiple players
	common_crusher_loot = list(/obj/item/guardiancreator/tech/spacetime, /obj/item/bluespace_megacrystal, /obj/item/crusher_trophy/bluespace_rift)

	var/list/copies = list()
	var/charging = FALSE
	var/chasming = FALSE
	var/mimicking = FALSE
	var/enraged = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/Life(delta_time, times_fired)
	. = ..()
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target.stat == DEAD || (living_target.stat == SOFT_CRIT && !HAS_TRAIT(living_target, TRAIT_NOSOFTCRIT)) || (living_target.stat == HARD_CRIT && !HAS_TRAIT(living_target, TRAIT_NOHARDCRIT)))
			retreat_distance = 0
			minimum_distance = 0
		else
			retreat_distance = initial(retreat_distance)
			minimum_distance = initial(minimum_distance)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/OpenFire(atom/A)
	anger_modifier =  (1 -(health / maxHealth)) * 100
	ranged_cooldown = world.time + (4 * (1.5 - anger_modifier) + 0.5) SECONDS

	if(mimicking)
		shotgun()
		return

	if(prob(min(15 * (LAZYLEN(former_targets) - 1), 30)))
		GiveTarget(pick(former_targets))
		charge()
		SLEEP_CHECK_DEATH(5, src)

	if(enraged) //You really want to try and hit the real one or you're gonna be fucked
		charge()
		SLEEP_CHECK_DEATH(5, src)
		if(prob(65))
			spiral_shoot_reverse(counter_length = 16)
		else
			bluespace_collapse()

		ranged_cooldown = world.time + 3 SECONDS
		return


	if(health / maxHealth < 0.5)
		if(prob(30 + anger_modifier / 3))
			spiral_shoot_reverse()
			SLEEP_CHECK_DEATH(5, src)
		else
			if(prob(30))
				triple_bouncer()

	if(prob(30 + anger_modifier / 5))
		if(prob(60))
			chop_chop_chop()
		else
			charge()
			if(health / maxHealth < 0.5)
				SLEEP_CHECK_DEATH(5, src)
				bluespace_collapse()
	else if(health / maxHealth < 0.5)
		if(prob(25))
			if(health / maxHealth < 0.25)
				chop_chop_chop()
			else
				triple_bouncer()
			SLEEP_CHECK_DEATH(15, src)
			clone_rush()
			return
		else if(prob(35 + anger_modifier / 5))
			spiral_shoot_reverse()
	else
		if(prob(25))
			for(var/i = 1 to 3)
				shotgun()
				SLEEP_CHECK_DEATH(5, src)
		else
			if(prob(65))
				spiral_shoot_reverse()
			bluespace_collapse()

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
	if(!isnum(set_angle) && (!startloc || startloc == loc))
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

		for(var/turf/check_turf in get_line(get_turf(src), get_turf_in_angle(counter * (360 / counter_max), get_turf(src), 15)))
			if(isclosedturf(check_turf) || check_turf.is_blocked_turf(exclude_mobs = TRUE))
				break
			target_turf = check_turf

		if(target_turf)
			shoot_projectile_reverse(target_turf)
		SLEEP_CHECK_DEATH(1, src)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/Move()
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc, src)
		if(chasming)
			var/turf/turf = get_turf(src)
			var/reset_turf = turf.type
			if(reset_turf != /turf/open/chasm/bluespace)
				turf.ChangeTurf(/turf/open/chasm/bluespace, flags = CHANGETURF_INHERIT_AIR)
				addtimer(CALLBACK(turf, /turf.proc/ChangeTurf, reset_turf, null, CHANGETURF_INHERIT_AIR), 3 SECONDS, TIMER_OVERRIDE|TIMER_UNIQUE)
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
	SLEEP_CHECK_DEATH(8, src)
	triple_bouncer(180)
	SLEEP_CHECK_DEATH(8, src)
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
	SLEEP_CHECK_DEATH(delay, src)
	var/movespeed = 1
	walk_towards(src, T, movespeed)
	SLEEP_CHECK_DEATH(get_dist(src, T) * movespeed, src)
	pass_flags &= ~(PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSTABLE | PASSMOB | PASSDOORS)
	walk(src, 0)
	if(chasm_charge)
		chasming = FALSE
	charging = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/angle_charge(charge_angle, charge_length = 7)
	var/turf/target_turf = get_turf_in_angle(charge_angle, get_turf(src), charge_length)
	var/turf/charge_turf
	for(var/turf/check_turf in get_line(get_turf(src), target_turf))
		if(isclosedturf(check_turf) || check_turf.is_blocked_turf(exclude_mobs = TRUE))
			break
		charge_turf = check_turf
	charge(charge_turf)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/triple_charge()
	var/chosen_modifier = pick(-1, 1)
	var/target_angle = get_angle(src, target) + rand(0, 10) * chosen_modifier
	angle_charge(target_angle)
	target_angle = (target_angle + rand(110, 150) * chosen_modifier) % 360
	angle_charge(target_angle)
	target_angle = (target_angle + rand(110, 150) * chosen_modifier) % 360
	angle_charge(target_angle)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/bluespace_collapse(collapse_amount = rand(4, 6))
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, color = COLOR_BLUE, transform = matrix() * 2, time = 3)
	SLEEP_CHECK_DEATH(3, src)
	qdel(D)
	for(var/mob/living/collapse_target in former_targets)
		var/list/turfs = list()
		for(var/turf/open/possible_turf in orange(7, get_turf(collapse_target)))
			if(possible_turf.is_blocked_turf())
				continue
			turfs.Add(possible_turf)

		for(var/i = 1 to collapse_amount)
			var/turf/collapse_turf = pick_n_take(turfs)
			var/collapse_angle = (collapse_target && get_dist(collapse_turf, collapse_target) < 4 ? get_angle(collapse_turf, collapse_target) : rand(0, 360))
			var/turf/target_turf = get_turf_in_angle(collapse_angle, collapse_turf, 15)
			for(var/turf/check_turf in get_line(collapse_turf, target_turf))
				if(isclosedturf(check_turf))
					target_turf = check_turf
					break
			new /obj/effect/temp_visual/bluespace_collapse(collapse_turf, target_turf)
			for(var/turf/open/turf_to_remove in orange(2, collapse_turf))
				if(sqrt((turf_to_remove.x - collapse_turf.x) ** 2 + (turf_to_remove.y - collapse_turf.y) ** 2) > 2 || !(turf_to_remove in turfs))
					continue
				turfs.Remove(turf_to_remove)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/chop_chop_chop(beam_amount = rand(4, 6))

	ranged_cooldown = world.time + 3 SECONDS + beam_amount * 12

	var/list/beam_targets = list()
	var/list/full_beam_targets = list()

	for(var/i = 1 to beam_amount)
		for(var/mob/targeting in former_targets)
			var/list/possible_targets = list()
			for(var/turf/possible_target in range(9, get_turf(targeting)))
				if((possible_targets in full_beam_targets) || get_dist(possible_target, targeting) < 8)
					continue
				possible_targets += possible_target

			var/turf/first_target = pick(possible_targets)
			var/turf/second_target = locate(targeting.x - (first_target.x - targeting.x), targeting.y - (first_target.y - targeting.y), targeting.z)

			beam_targets[first_target] = second_target
			full_beam_targets += first_target
			full_beam_targets += second_target

		for(var/turf/first_target in beam_targets)
			var/turf/second_target = beam_targets[first_target]
			first_target.Beam(second_target, icon_state = "bluespace_beam_prepare", time = 8)

		SLEEP_CHECK_DEATH(6, src)
		playsound(get_turf(src), 'sound/magic/lightningbolt.ogg', 50, TRUE)

		for(var/turf/first_target in beam_targets)
			var/turf/second_target = beam_targets[first_target]
			first_target.Beam(second_target, icon_state = "bluespace_beam", time = 8)
			for(var/turf/check_turf in get_line(first_target, second_target))
				for(var/mob/living/victim in check_turf.contents)
					if(faction_check_mob(victim))
						continue
					victim.adjustBruteLoss(30)
					to_chat(victim, span_userdanger("You're hit by a bluespace collapse beam!"))
					if(ishuman(victim))
						var/mob/living/carbon/human/human_victim = victim
						human_victim.electrocution_animation(1 SECONDS)

		SLEEP_CHECK_DEATH(6, src)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/shotgun(shot_angles = list(5, 0, -5))
	var/turf/target_turf = get_turf(target)
	var/angle_to_target = get_angle(src, target_turf)
	for(var/i in shot_angles)
		shoot_projectile(target_turf, angle_to_target + i, proj_type = /obj/projectile/bluespace_blast/slow)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/clone_rush()
	charge(target, chasm_charge = FALSE)
	var/list/directions_orig = pick(GLOB.cardinals, GLOB.diagonals)
	var/list/directions = directions_orig.Copy()
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
	addtimer(CALLBACK(src, .proc/stop_rage), 15 SECONDS)

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

	Stun(3 SECONDS) //As a reward for player for hitting the real guy

/obj/projectile/bluespace_blast
	name = "bluespace blast"
	icon_state = "gaussblue"
	damage = 5
	damage_type = BRUTE
	speed = 1

	ricochets_max = 1
	ricochet_chance = 80
	ricochet_decay_chance = 0.9
	ricochet_decay_damage = 0.9
	ricochet_auto_aim_angle = 10
	ricochet_auto_aim_range = 2
	ricochet_incidence_leeway = 0

/obj/projectile/bluespace_blast/slow
	speed = 4

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
		if(L.stat == DEAD || !is_in_sight(src, L))
			continue
		if(isliving(firer))
			var/mob/living/living_firer = firer
			if(faction_check(living_firer.faction, L.faction))
				continue
		var/our_angle = abs(closer_angle_difference(Angle, get_angle(src.loc, L.loc)))
		if(our_angle < best_angle)
			best_angle = our_angle
			unlucky_sob = L

	if(unlucky_sob)
		set_angle(get_angle(src, unlucky_sob.loc))

/obj/projectile/bluespace_blast/bouncer
	name = "bluespace bouncer"
	icon_state = "bluespace_bouncer"
	damage = 45
	speed = 4

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
	var/damaging = TRUE

/obj/effect/temp_visual/bluespace_collapse/nodamage
	damaging = FALSE

/obj/effect/temp_visual/bluespace_collapse/Initialize(mapload, new_target_turf)
	. = ..()
	target_turf = new_target_turf
	if(damaging)
		Beam(target_turf, icon_state = "bluespace_beam_prepare", time = 7)

/obj/effect/temp_visual/bluespace_collapse/Destroy()
	playsound(get_turf(src), 'sound/magic/lightningbolt.ogg', 50, TRUE)
	if(!damaging)
		return ..()
	Beam(target_turf, icon_state = "bluespace_beam", time = 6)
	for(var/turf/check_turf in get_line(get_turf(src), target_turf))
		for(var/mob/living/victim in check_turf.contents)
			if(!faction_check(victim.faction, list("jungle", "boss")))
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
	normal_chasm = FALSE

/turf/open/chasm/bluespace/Initialize()
	. = ..()
	AddComponent(/datum/component/chasm/bluespace) //We lead to a random open turf in 11 tile radius, but not closer than 3 tiles to initial location

/// Hallucination mob

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/hallucination
	health = 1
	maxHealth = 1
	retreat_distance = 2
	minimum_distance = 2
	mimicking = TRUE
	alpha = 195

	loot = list()
	crusher_loot = list()

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
	Stun(10 SECONDS)
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
		if(prob(30))
			new /obj/effect/temp_visual/sparks_bluespace(possible_turf)
	flick("jaunt_start", src)
	sleep(9)
	playsound(get_turf(src), 'sound/effects/explosion3.ogg', 75, TRUE)
	summoner.copies.Remove(src)
	qdel(src)

/obj/effect/temp_visual/sparks_bluespace
	icon_state = "sparks_bluespace"
	duration = 6

#define MAX_PARTICLE_CONNECTIONS 4
#define MAX_PARTICLES 7

/obj/item/crusher_trophy/bluespace_rift
	name = "bluespace rift"
	desc = "A rift in space and time, created by an unknown anomaly. Suitable as a trophy for a kinetic crusher."
	icon_state = "bluespace_rift"
	denied_type = list(/obj/item/crusher_trophy/bluespace_rift)
	bonus_value = 15
	var/list/bluespace_particles = list()

/obj/item/crusher_trophy/bluespace_rift/effect_desc()
	return "mark detonations to create bluespace particles that will connect together using beams. Whenever an enemy passes through the beam, they get damaged for <b>[bonus_value]</b>"

/obj/item/crusher_trophy/bluespace_rift/on_mark_detonation(mob/living/target, mob/living/user)
	var/obj/effect/bluespace_particle/particle = new(get_turf(target), user)
	playsound(get_turf(target), 'sound/magic/lightningbolt.ogg', 25, TRUE)
	if(LAZYLEN(bluespace_particles) >= MAX_PARTICLES)
		qdel(pick_n_take(bluespace_particles))
	bluespace_particles += particle
	QDEL_IN(particle, 30 SECONDS)

/obj/effect/bluespace_particle
	name = "bluespace particle"
	desc = "A small tear in bluespace."
	icon = 'icons/effects/effects.dmi'
	icon_state = "bluespace_particle"
	var/list/particle_beams = list()

/obj/effect/bluespace_particle/Initialize(mapload, mob/living/author)
	. = ..()

	var/connection_count = 0
	for(var/obj/effect/bluespace_particle/particle in orange(6, get_turf(src)))
		if(!istype(particle) || particle == src)
			continue
		var/datum/beam/particle_beam = Beam(particle, icon_state = "bluespace_beam", beam_type = /obj/effect/ebeam/bluespace_blast)
		particle.particle_beams[particle_beam] = src
		particle_beams[particle_beam] = particle
		connection_count += 1
		if(connection_count >= MAX_PARTICLE_CONNECTIONS)
			break

/obj/effect/bluespace_particle/Destroy(force)
	for(var/particle_beam in particle_beams)
		var/obj/effect/bluespace_particle/connected_to = particle_beams[particle_beam]
		connected_to.particle_beams -= particle_beam
		qdel(particle_beam)
	. = ..()

#undef MAX_PARTICLE_CONNECTIONS
#undef MAX_PARTICLES

/obj/effect/ebeam/bluespace_blast
	name = "bluespace blast"
	mouse_opacity = MOUSE_OPACITY_ICON

/obj/effect/ebeam/bluespace_blast/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = .proc/on_entered,
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/ebeam/bluespace_blast/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(isliving(AM))
		var/mob/living/L = AM
		if("jungle" in L.faction && !("neutral" in L.faction))
			L.adjustFireLoss(30)

/obj/item/guardiancreator/tech/spacetime
	name = "experimental holoparasite injector"
	desc = "An experimental version of holoparasites that specialise on manipulating space and time via bluespace. It can also be used in override mode, giving the user manual control over the holoparasites. (Override mode is activated through alt-click)"
	mob_name = "Experimental Holoparasite"
	possible_guardians = list("Spacetime")
	allowling = FALSE

/obj/item/guardiancreator/tech/spacetime/AltClick(mob/user)
	if(used)
		return
	to_chat("<span class='holoparasite'>You override the holoparasite AI, making the injector spew out a solid chunk of nanites. Use it in-hand to gain special abilities.</span>")
	used = TRUE
	var/obj/item/organ/cyberimp/arm/spacetime_manipulator/manip = new(get_turf(src))
	user.put_in_hands(manip)

/obj/item/guardiancreator/tech/spacetime/spawn_guardian(mob/living/user, mob/dead/candidate)
	. = ..()
	if(.)
		user.apply_status_effect(STATUS_EFFECT_BLUESPACE_INSTABILITY)

/obj/item/organ/cyberimp/arm/spacetime_manipulator
	name = "blue shard"
	desc = "An eerie crystal shard surrounded by fluctuating bluespace."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "nanite_chunk"
	status = ORGAN_ORGANIC
	organ_flags = ORGAN_FROZEN|ORGAN_UNREMOVABLE
	items_to_create = list(/obj/item/cursed_katana/spacetime_manipulator)
	extend_sound = 'sound/magic/mandswap.ogg'
	retract_sound = 'sound/magic/mandswap.ogg'

/obj/item/organ/cyberimp/arm/spacetime_manipulator/attack_self(mob/living/user, modifiers)
	. = ..()
	to_chat(user, span_userdanger("The mass goes up your arm and goes inside it!"))
	playsound(user, 'sound/magic/demon_consume.ogg', 50, TRUE)
	var/index = user.get_held_index_of_item(src)
	zone = (index == LEFT_HANDS ? BODY_ZONE_L_ARM : BODY_ZONE_R_ARM)
	SetSlotFromZone()
	user.temporarilyRemoveItemFromInventory(src, TRUE)
	Insert(user)
	user.apply_status_effect(STATUS_EFFECT_BLUESPACE_INSTABILITY)

/obj/item/organ/cyberimp/arm/spacetime_manipulator/screwdriver_act(mob/living/user, obj/item/screwtool)
	return

/obj/item/organ/cyberimp/arm/spacetime_manipulator/Retract()
	var/obj/item/cursed_katana/spacetime_manipulator/manipulator = active_item
	if(!manipulator)
		return
	manipulator.wash(CLEAN_TYPE_BLOOD)
	return ..()

/obj/item/bluespace_megacrystal
	name = "bluespace megacrystal"
	desc = "A giant bluespace crystal that can be probably used for something... if only you could find where you should stick it."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "bluespace_megacrystal"
	w_class = WEIGHT_CLASS_TINY
	force = 0
	throwforce = 0

#define LEFT_SLASH "Left Slash"
#define RIGHT_SLASH "Right Slash"
#define COMBO_STEPS "steps"
#define COMBO_PROC "proc"
#define ATTACK_REPULSE "Repulse"
#define ATTACK_BLAST "Bluespace Blast"
#define ATTACK_RIFT "Space Rift"
#define ATTACK_COLLAPSE "Bluespace Collapse"
#define ATTACK_PARTICLE "Particle Blast"
#define ATTACK_CLOAK "Space Cloak"

/obj/item/cursed_katana/spacetime_manipulator
	name = "space-time manipulator"
	desc = "A cluster of space-time manipulating nanites that is coating your hand."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "bluespace_hand"
	lefthand_file = 'icons/mob/inhands/misc/touchspell_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/touchspell_righthand.dmi'
	force = 15
	block_chance = 0
	w_class = WEIGHT_CLASS_HUGE
	attack_verb_continuous = list("manipulates", "slams", "crushes", "rips", "tears", "time travels")
	attack_verb_simple = list("manipulate", "slam", "crush", "rip", "tear", "time travel")
	hitsound = 'sound/magic/repulse.ogg'
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | FREEZE_PROOF
	drinks_blood = FALSE
	combo_list = list(
		ATTACK_REPULSE = list(COMBO_STEPS = list(LEFT_SLASH, LEFT_SLASH, RIGHT_SLASH), COMBO_PROC = .proc/repulse),
		ATTACK_BLAST = list(COMBO_STEPS = list(RIGHT_SLASH, LEFT_SLASH, LEFT_SLASH), COMBO_PROC = .proc/blast),
		ATTACK_RIFT = list(COMBO_STEPS = list(LEFT_SLASH, RIGHT_SLASH, RIGHT_SLASH), COMBO_PROC = .proc/dash),
		ATTACK_COLLAPSE = list(COMBO_STEPS = list(LEFT_SLASH, RIGHT_SLASH, LEFT_SLASH, RIGHT_SLASH), COMBO_PROC = .proc/collapse),
		ATTACK_PARTICLE = list(COMBO_STEPS = list(RIGHT_SLASH, RIGHT_SLASH, LEFT_SLASH), COMBO_PROC = .proc/particle_blast),
		ATTACK_CLOAK = list(COMBO_STEPS = list(RIGHT_SLASH, LEFT_SLASH, RIGHT_SLASH, LEFT_SLASH), COMBO_PROC = .proc/cloak),
		)

/obj/item/cursed_katana/spacetime_manipulator/proc/blast(mob/living/target, mob/user)
	visible_message(span_warning("[user] creates a bluespace blast around [target]!</span>"))
	for(var/turf/target_turf in range(1, get_turf(target)))
		new /obj/effect/temp_visual/bluespace_blast_warning(target_turf, user)
		sleep(1)

/obj/item/cursed_katana/spacetime_manipulator/proc/repulse(mob/living/target, mob/user)
	visible_message(span_warning("[user] repulses everything around them!</span>"))
	playsound(user, 'sound/weapons/sonic_jackhammer.ogg', 100, 1)
	sleep(2)
	for(var/turf/target_turf in view(1, user))
		if(!target_turf)
			return
		new /obj/effect/temp_visual/small_smoke/halfsecond(target_turf)
		for(var/mob/living/victim in target_turf.contents)
			if(victim != user)
				var/throwtarget = get_edge_target_turf(target_turf, get_dir(user, victim))
				victim.throw_at(throwtarget, 4, 1, user)
				victim.Stun(5)
				victim.adjustBruteLoss(15)

/obj/item/cursed_katana/spacetime_manipulator/proc/collapse(mob/living/target, mob/user)
	visible_message(span_warning("[user] activates local bluespace collapse!</span>"))
	var/target_turf = get_turf(target)
	new /obj/effect/temp_visual/bluespace_collapse/nodamage(target_turf)
	sleep(7)
	new /obj/effect/temp_visual/chronoexplosion(target_turf)
	playsound(target_turf, 'sound/magic/lightningbolt.ogg', 50, TRUE)
	for(var/mob/living/victim in range(1, target_turf))
		if(victim == user)
			continue
		var/damage_mod = 1
		if(!isanimal(victim))
			damage_mod *= 0.75
		if(victim in target_turf)
			to_chat(victim, span_userdanger("Bluespace collapses around, crushing you!"))
			victim.adjustBruteLoss(40 * damage_mod)
		else
			to_chat(victim, span_userdanger("The tremors from the bluespace collapse landing sends you flying!"))
			var/fly_away_direction = get_dir(src, victim)
			victim.throw_at(get_edge_target_turf(victim, fly_away_direction), 4, 3)
			victim.adjustBruteLoss(20 * damage_mod)

/obj/item/cursed_katana/spacetime_manipulator/proc/shoot_projectile(turf/marker, set_angle, atom/target = null, mob/user = null, proj_type = /obj/projectile/bluespace_blast/particle)
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/turf/startloc = get_turf(src)
	var/obj/projectile/P = new proj_type(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = user
	if(target)
		P.original = target
	P.fire(set_angle)

/obj/item/cursed_katana/spacetime_manipulator/proc/shotgun(atom/target, mob/user, shot_angles = list(7, 0, -7))
	var/turf/target_turf = get_turf(target)
	var/angle_to_target = get_angle(get_turf(src), target_turf)
	for(var/i in shot_angles)
		shoot_projectile(target_turf, angle_to_target + i, target, user)

/obj/item/cursed_katana/spacetime_manipulator/proc/particle_blast(mob/living/target, mob/user)
	user.visible_message(span_warning("[user] activates their bluespace particle generator!"),
		span_notice("You activate your bluespace particle generator, aiming it towards [target]!"))

	for(var/i = 1 to 3)
		playsound(src, 'sound/magic/magic_missile.ogg', 100, TRUE)
		shotgun(target)
		sleep(3)

/obj/item/cursed_katana/spacetime_manipulator/cloak(mob/living/target, mob/user)
	user.alpha = 150
	user.invisibility = INVISIBILITY_OBSERVER
	user.sight |= SEE_SELF
	user.visible_message(span_warning("[user] vanishes into thin air!"),
		span_notice("You enter invisibility via phase-change."))
	playsound(src, 'sound/magic/staff_animation.ogg', 50, TRUE)
	if(ishostile(target))
		var/mob/living/simple_animal/hostile/hostile_target = target
		hostile_target.LoseTarget()
	addtimer(CALLBACK(src, .proc/uncloak, user), 5 SECONDS, TIMER_UNIQUE)

/obj/item/cursed_katana/spacetime_manipulator/uncloak(mob/user)
	user.alpha = 255
	user.invisibility = 0
	user.sight &= ~SEE_SELF
	user.visible_message(span_warning("[user] appears from thin air!"),
		span_notice("You stop the phase-change."))
	playsound(src, 'sound/magic/summonitems_generic.ogg', 50, TRUE)

/obj/projectile/bluespace_blast/particle
	name = "bluespace particle"
	icon_state = "bluespace_particle"
	damage = 5
	armour_penetration = 100

#undef LEFT_SLASH
#undef RIGHT_SLASH
#undef COMBO_STEPS
#undef COMBO_PROC
#undef ATTACK_REPULSE
#undef ATTACK_BLAST
#undef ATTACK_RIFT
#undef ATTACK_COLLAPSE
#undef ATTACK_PARTICLE
#undef ATTACK_CLOAK

#define CUT_COOLDOWN 30 SECONDS
#define SPIT_OUT_TIME 3 SECONDS
#define SPIT_OUT_STUN 7.5 SECONDS

/obj/effect/landmark/space_cutter
	name = "space cutter room"
	icon_state = "space_cutter"

/obj/effect/landmark/space_cutter/Initialize(mapload)
	. = ..()
	new /obj/structure/pocket_rift(get_turf(src), TRUE)

/obj/item/space_cutter
	name = "The Space Cutter"
	desc = "An experimental sword with a bluespace blade, capable of cutting space-time. Sadly it's not able to cut flesh at all."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "space_cutter"
	inhand_icon_state = "space_cutter"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 0
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 0
	throw_range = 5
	throw_speed = 2
	var/cut_cooldown = 0
	var/obj/structure/pocket_rift/rift

/obj/item/space_cutter/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!user.Adjacent(target))
		return

	if(cut_cooldown > world.time)
		to_chat(user, span_warning("[src] hasn't cooled down it's bluespace circuitry yet. Wait [DisplayTimeText(cut_cooldown - world.time)] before using it again!"))
		return

	if(!do_after(user, 5 SECONDS, target = get_turf(target)))
		return

	if(rift)
		qdel(rift)

	cut_cooldown = world.time + CUT_COOLDOWN
	user.visible_message(span_warning("[user] swings [src] in the air and forms a bluespace rift!"))
	rift = new(get_turf(target))
	playsound(get_turf(target), 'sound/magic/forcewall.ogg', 50, TRUE)

/obj/structure/pocket_rift
	name = "bluespace rift"
	desc = "An odd bluespace rift that leads somewhere unknown..."
	icon = 'icons/obj/carp_rift.dmi'
	icon_state = "carp_rift"
	anchored = TRUE
	density = TRUE

	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 100, BIO = 100, FIRE = 100, ACID = 100)
	resistance_flags = INDESTRUCTIBLE

	var/obj/structure/pocket_rift/connected_rift
	var/collapsing = FALSE
	var/source_portal = FALSE

/obj/structure/pocket_rift/Initialize(mapload, source_port = FALSE)
	. = ..()
	ADD_TRAIT(src, TRAIT_MOB_HATED, INNATE_TRAIT)
	source_portal = source_port
	var/obj/effect/landmark/space_cutter/landmark = locate(/obj/effect/landmark/space_cutter) in GLOB.landmarks_list
	if(get_turf(src) == get_turf(landmark))
		source_portal = TRUE
		return

	connected_rift = locate(/obj/structure/pocket_rift) in get_turf(landmark)
	if(!connected_rift)
		return

	connected_rift.connected_rift = src

/obj/structure/pocket_rift/Bumped(atom/movable/mover)
	. = ..()
	attempt_teleport(mover)

/obj/structure/pocket_rift/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	attempt_teleport(user)

/obj/structure/pocket_rift/proc/attempt_teleport(atom/mover)
	if(isanimal(mover) || !connected_rift)
		to_chat(mover, span_warning("An unknown presence stops you from entering [src]!"))
		return

	var/turf/target_turf = get_turf(connected_rift)
	if(do_teleport(mover, target_turf, null, channel = TELEPORT_CHANNEL_QUANTUM, asoundin = 'sound/effects/phasein.ogg', forced = TRUE))
		for(var/mob/living/simple_animal/hostile/possible_attacker in range(21, get_turf(src)))
			if(possible_attacker.target == mover)
				possible_attacker.GiveTarget(src)

	to_chat(mover, span_notice("You enter [src] and find yourself in [get_area_name(target_turf)]."))

/obj/structure/pocket_rift/attack_generic(mob/user, damage_amount, damage_type, damage_flag, sound_effect, armor_penetration)
	if(!collapsing && !source_portal)
		collapse(user)
		return
	return ..()

/obj/structure/pocket_rift/attack_paw(mob/user, list/modifiers)
	if(!collapsing && !source_portal)
		collapse(user)
		return
	return ..()

/obj/structure/pocket_rift/attackby(obj/item/I, mob/living/user, params)
	if(!collapsing && !source_portal)
		collapse(user)
		return
	return ..()

/obj/structure/pocket_rift/bullet_act(obj/projectile/proj)
	if(!collapsing && !source_portal)
		collapse(proj)
		return
	return ..()

/obj/structure/pocket_rift/proc/collapse(atom/attacker)
	collapsing = TRUE
	visible_message(span_danger("[src] starts collapsing and folding on itself as it is hit by [attacker]!"))
	playsound(src, 'sound/magic/repulse.ogg', 100)
	playsound(connected_rift, 'sound/magic/repulse.ogg', 100) //Gives a small audio hint that the portal is collapsing
	addtimer(CALLBACK(src, .proc/collapse_destroy), SPIT_OUT_TIME)

/obj/structure/pocket_rift/proc/collapse_destroy()
	visible_message(span_danger("[src] fully collapses!"))
	for(var/mob/living/victim in range(3, get_turf(connected_rift)))
		if(isanimal(victim))
			continue
		connected_rift.attempt_teleport(victim)
		victim.Knockdown(SPIT_OUT_STUN)
		victim.Paralyze(SPIT_OUT_STUN)
	connected_rift.connected_rift = null
	qdel(src)

#undef CUT_COOLDOWN
#undef SPIT_OUT_TIME
#undef SPIT_OUT_STUN
