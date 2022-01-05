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

	wander = FALSE
	speed = 3
	move_to_delay = 3
	retreat_distance = 3
	minimum_distance = 3
	gps_name = "Quantum Signal"

	common_loot = list(/obj/item/guardiancreator/tech/spacetime, /obj/item/bluespace_megacrystal) //Let's reward everybody who killed this fella
	common_crusher_loot = list(/obj/item/guardiancreator/tech/spacetime, /obj/item/bluespace_megacrystal, /obj/item/crusher_trophy/bluespace_rift)

	var/list/copies = list()
	var/charging = FALSE
	var/chasming = FALSE
	var/mimicking = FALSE
	var/enraged = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/OpenFire(atom/A)
	anger_modifier =  (1 -(health / maxHealth)) * 100
	ranged_cooldown = world.time + (3 * (1.5 - anger_modifier) + 0.5) SECONDS

	if(mimicking)
		shotgun()
		return

	if(enraged) //You really want to try and hit the real one or you're gonna be fucked
		charge()
		SLEEP_CHECK_DEATH(5)
		if(prob(85))
			if(prob(35))
				more_bouncers()

			for(var/i = 1 to 3)
				shotgun()
				SLEEP_CHECK_DEATH(5)
		else
			spiral_shoot_reverse(counter_length = 16)
		ranged_cooldown = world.time + 0.5 SECONDS
		return


	if(health / maxHealth < 0.5)
		if(prob(25 + anger_modifier / 3))
			triple_bouncer()
		else
			if(prob(10 + anger_modifier / 4))
				shoot_projectile_reverse()

	if(prob(45))
		if(prob(30))
			triple_charge()
		else
			charge()
			if(health / maxHealth < 0.5)
				SLEEP_CHECK_DEATH(5)
				shotgun()
	else
		if(prob(25))
			if(health / maxHealth < 0.5)
				more_bouncers()
			else
				triple_bouncer()
			SLEEP_CHECK_DEATH(15)
			clone_rush()
			return

		if(prob(40))
			for(var/i = 1 to 3)
				shotgun()
				SLEEP_CHECK_DEATH(3)
		else
			bluespace_collapse()
			if(health / maxHealth < 0.5)
				triple_bouncer()

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

		for(var/turf/check_turf in get_line(get_turf(src), get_turf_in_angle(counter * (360 / counter_max), get_turf(src), 15)))
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
	SLEEP_CHECK_DEATH(3)
	qdel(D)
	var/list/turfs = list()
	for(var/turf/open/possible_turf in orange(7, get_turf(target)))
		if(possible_turf.is_blocked_turf())
			continue
		turfs.Add(possible_turf)

	for(var/i = 1 to collapse_amount)
		var/turf/collapse_turf = pick_n_take(turfs)
		var/collapse_angle = (target && get_dist(collapse_turf, target) < 4 ? get_angle(collapse_turf, target) : rand(0, 360))
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

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/proc/shotgun(shot_angles = list(5, 0, -5))
	var/turf/target_turf = get_turf(target)
	var/angle_to_target = get_angle(src, target_turf)
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
	damage = 7
	damage_type = BRUTE
	speed = 1

	ricochets_max = 2
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
	armour_penetration = 100
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
	sleep(round(13 * 0.7))
	playsound(get_turf(src), 'sound/effects/explosion3.ogg', 75, TRUE)
	summoner.copies.Remove(src)
	qdel(src)

/mob/living/simple_animal/hostile/megafauna/jungle/bluespace_spirit/death(gibbed)
	if(prob(10))
		new /obj/item/gilded_card(get_turf(src))
	. = ..()

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
	theme = "magic"
	mob_name = "Experimental Holoparasite"
	use_message = "<span class='holoparasite'>You start to power on the injector...</span>"
	used_message = "<span class='holoparasite'>The injector has already been used.</span>"
	failure_message = "<span class='holoparasite bold'>...ERROR. BOOT SEQUENCE ABORTED. AI FAILED TO INTIALIZE. PLEASE CONTACT SUPPORT OR TRY AGAIN LATER.</span>"
	ling_failure = "<span class='holoparasite bold'>The holoparasites recoil in horror. They want nothing to do with a creature like you.</span>"
	possible_guardians = list("Spacetime")
	allowling = FALSE

/obj/item/guardiancreator/tech/spacetime/AltClick(mob/user)
	to_chat("<span class='holoparasite'>You override the holoparasite AI, making the injector spew out a solid chunk of nanites. Use it in-hand to gain special abilities.</span>")
	used = TRUE
	var/obj/item/organ/cyberimp/arm/spacetime_manipulator/manip = new(get_turf(src))
	user.put_in_hands(manip)

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

/obj/item/organ/cyberimp/arm/spacetime_manipulator/attack_self(mob/user, modifiers)
	. = ..()
	to_chat(user, span_userdanger("The mass goes up your arm and goes inside it!"))
	playsound(user, 'sound/magic/demon_consume.ogg', 50, TRUE)
	var/index = user.get_held_index_of_item(src)
	zone = (index == LEFT_HANDS ? BODY_ZONE_L_ARM : BODY_ZONE_R_ARM)
	SetSlotFromZone()
	user.temporarilyRemoveItemFromInventory(src, TRUE)
	Insert(user)

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
	playsound(user, 'sound/weapons/sonic_jackhammer.ogg', 200, 1)
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

/obj/item/gilded_card
	name = "gilded card"
	desc = "A strange guilded blue card with illegible text on it."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "gilded_card"

/obj/item/gilded_card/attack_self(mob/living/user)
	if(!iscarbon(user))
		to_chat(user, span_notice("A dark presence stops you from playing the card."))
		return
	forceMove(user)
	to_chat(user, span_danger("You play the card and suddenly realise that you've made a fatal mistake."))
	resurrect(user)

/obj/item/gilded_card/proc/resurrect(mob/living/carbon/user)
	var/turf/target = find_safe_turf()
	user.forceMove(target)
	user.revive(full_heal = TRUE, admin_revive = TRUE)
	INVOKE_ASYNC(user, /mob/living/carbon.proc/set_species, /datum/species/shadow)
	to_chat(user, span_notice("You blink and find yourself in [get_area_name(target)]... feeling a bit darker."))
	playsound(target, 'sound/effects/curse2.ogg', 80, TRUE)
	qdel(src)
