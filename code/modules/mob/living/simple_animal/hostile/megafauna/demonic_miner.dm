#define BLOOD_JAUNT_LENGTH 1 SECONDS

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner
	name = "demonic miner"
	desc = "A body of some poor dead miner, posessed by an ancient demon."
	health = 3500
	maxHealth = 3500
	icon_state = "demonic_miner"
	icon_living = "demonic_miner"
	icon = 'icons/mob/jungle/jungle_monsters.dmi'

	attack_sound = 'sound/weapons/slash.ogg'
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID|MOB_EPIC
	light_color = COLOR_RED_LIGHT
	movement_type = GROUND
	speak_emote = list("roars")

	armour_penetration = 60
	melee_damage_lower = 20
	melee_damage_upper = 20
	obj_damage = 0 //So he doesn't break the walls on his arena as they are very important to dodge the beam and sprial attacks
	ranged = TRUE
	vision_range = 18
	aggro_vision_range = 21
	former_target_vision_range = 21
	rapid_melee = 3
	melee_queue_distance = 2
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"

	speed = 4
	move_to_delay = 4
	wander = FALSE
	gps_name = "Posessed Signal"

	achievement_type = /datum/award/achievement/boss/demonic_miner_kill
	crusher_achievement_type = /datum/award/achievement/boss/demonic_miner_crusher
	score_achievement_type = /datum/award/score/jungle_demonic_miner_score

	common_loot = list(/obj/item/demon_stone, /obj/effect/spawner/random/boss/demonic_miner)
	common_crusher_loot = list(/obj/item/demon_stone, /obj/effect/spawner/random/boss/demonic_miner, /obj/item/crusher_trophy/demon_horn) //Let's reward everybody who killed this guy, he's hard and loot is only usable for fauna killing.
	loot = list(/obj/effect/decal/remains/human)

	del_on_death = TRUE
	blood_volume = BLOOD_VOLUME_NORMAL
	deathmessage = "falls to the ground as demon that possesses it dies."
	deathsound = "bodyfall"
	footstep_type = FOOTSTEP_MOB_HEAVY
	alpha = 175 //as long as it's not awake
	var/demon_form = FALSE
	var/noaction = TRUE
	var/imps = 0

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/Initialize()
	. = ..()
	status_flags |= GODMODE
	pixel_y = -1
	add_filter("demonic_miner_outline", 9, list("type" = "outline", "color" = rgb(209, 4, 4, 100), "size" = 1))

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/update_icon(updates)
	if(demon_form)
		icon_state = "demonic_miner_phase2"
		icon_living = "demonic_miner_phase2"
	else
		icon_state = "demonic_miner_phase2"
		icon_living = "demonic_miner_phase2"
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/death()
	. = ..()
	if(.)
		if(demon_form)
			new /obj/effect/temp_visual/dir_setting/miner_death/demonic/demon_form(loc, dir)
		else
			new /obj/effect/temp_visual/dir_setting/miner_death/demonic(loc, dir)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/imp_death()
	imps -= 1
	if(imps <= 0)
		noaction = FALSE
		status_flags &= ~GODMODE
		visible_message(span_danger("[src] exists stasis as it's last servant was killed!"), span_userdanger("You exit stasis as your last servant was killed!"))
		alpha = 255

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/ex_act(severity, target)
	adjustBruteLoss(-30 * severity)
	visible_message(span_danger("[src] absorbs the explosion!"), span_userdanger("You absorb the explosion!"))

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/jaunt_at(atom/victim)
	var/turf/target_turf = get_turf(victim)

	flick("[icon_state]_jaunt", src)
	noaction = TRUE
	status_flags |= GODMODE
	set_density(FALSE)
	playsound(target_turf, 'sound/magic/ethereal_enter.ogg', 50, TRUE, -1)
	SLEEP_CHECK_DEATH(9, src)
	invisibility = INVISIBILITY_MAXIMUM
	alpha = 0 //To hide HUDs
	addtimer(CALLBACK(src, .proc/end_jaunt, target_turf), BLOOD_JAUNT_LENGTH)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/end_jaunt(turf/target_turf)
	forceMove(target_turf)
	playsound(target_turf, 'sound/magic/ethereal_exit.ogg', 50, TRUE, -1)
	invisibility = initial(invisibility)
	alpha = 255
	flick("[icon_state]_jaunt_out", src)
	SLEEP_CHECK_DEATH(9, src)
	noaction = FALSE
	status_flags &= ~GODMODE
	set_density(TRUE)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(. && health <= maxHealth * 0.5 && !demon_form)
		become_demon()

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/become_demon()
	demon_form = TRUE
	noaction = TRUE
	status_flags |= GODMODE
	spin(30, 2)
	SLEEP_CHECK_DEATH(30, src)
	playsound(src, 'sound/effects/explosion3.ogg', 100, TRUE)
	playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	armour_penetration = 100
	melee_damage_lower = 30
	melee_damage_upper = 30
	speed = 2
	move_to_delay = 2
	update_icon()
	status_flags &= ~GODMODE
	noaction = FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/channel_ray(starting_angle = 0, ending_angle = 360, angle_step = 5, fixed_time = 0)
	var/current_angle = starting_angle
	var/cur_time = 0
	if(starting_angle > ending_angle)
		angle_step *= -1

	var/turf/cur_turf = get_turf(src)
	var/turf/target_turf = get_turf_in_angle(current_angle, cur_turf, 15)

	var/obj/effect/temp_beam_target/temp_target = new(get_turf(target_turf))
	var/obj/effect/abstract/demon_beam_splash/splash = new(cur_turf)
	var/beam
	var/list/already_hit = list()

	noaction = TRUE

	while((ending_angle > starting_angle && current_angle < ending_angle) || (ending_angle < starting_angle && current_angle > ending_angle))
		for(var/turf/check_turf in get_line(cur_turf, target_turf))
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
		target_turf = get_turf_in_angle(current_angle, cur_turf, 15)
		setDir(angle2dir(current_angle))
		SLEEP_CHECK_DEATH(1, src)

	noaction = FALSE
	qdel(beam)
	qdel(temp_target)
	qdel(splash)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/blast_line(atom/targeting = null)
	if(!targeting)
		targeting = target
	var/target_turf = get_turf(targeting)
	var/end_turf = get_ranged_target_turf_direct(src, target_turf, 40, 0)
	var/turf_line = get_line(get_turf(src), end_turf) - get_turf(src)
	for(var/turf/targeting_turf in turf_line)
		if(isclosedturf(targeting_turf))
			return

		if(demon_form)
			new /obj/effect/temp_visual/demonic_blast_warning/quick(targeting_turf)
			continue

		new /obj/effect/temp_visual/demonic_blast_warning(targeting_turf)
		SLEEP_CHECK_DEATH(1, src)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/blast_line_directions(list/dirs = pick(GLOB.cardinals, GLOB.diagonals))
	for(var/blast_dir in dirs)
		var/turf/target_turf = get_turf(src)
		while(!isclosedturf(target_turf))
			target_turf = get_step(target_turf, blast_dir)
			if(demon_form)
				new /obj/effect/temp_visual/demonic_blast_warning/quick(target_turf)
			else
				new /obj/effect/temp_visual/demonic_blast_warning(target_turf)

		SLEEP_CHECK_DEATH(1, src)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/triple_blast_line()
	blast_line(target)
	SLEEP_CHECK_DEATH(3, src)
	blast_line(target)
	SLEEP_CHECK_DEATH(3, src)
	blast_line(target)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/proc/blast_circle(atom/targeting = null, attack_range = 2)
	if(!targeting)
		targeting = target
	var/turf/target_turf = get_turf(targeting)
	var/cur_range = 0
	for(var/turf/targeting_turf in range(attack_range, target_turf))
		if(sqrt((targeting_turf.x - target_turf.x) ** 2 + (targeting_turf.y - target_turf.y) ** 2) > cur_range)
			cur_range = sqrt((targeting_turf.x - target_turf.x) ** 2 + (targeting_turf.y - target_turf.y) ** 2)
			SLEEP_CHECK_DEATH(demon_form ? 0 : 2, src)

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
	var/obj/effect/temp_visual/decoy/decoy = new /obj/effect/temp_visual/decoy(loc, src)
	animate(decoy, alpha = 0, color = "#FF0000", transform = matrix() * 2, time = 6)
	SLEEP_CHECK_DEATH(6, src)
	if(check_proj_immunity(target)) //Don't try to cheese this fella
		for(var/i = 1 to 3)
			blast_circle(target)
			SLEEP_CHECK_DEATH(3, src)
		channel_ray(get_angle(src, target) - 45, get_angle(src, target) + 45)
		return
	var/turf/start_turf = get_step(src, pick(GLOB.alldirs))
	var/counter = counter_start
	for(var/i in 1 to 16)
		if(negative)
			counter--
		else
			counter++
		if(counter > 16)
			counter = 1
		if(counter < 1)
			counter = 16
		shoot_projectile(start_turf, counter * 22.5)
		shoot_projectile(start_turf, ((counter + 4) % 16) * 22.5)
		shoot_projectile(start_turf, ((counter + 8) % 16) * 22.5)
		shoot_projectile(start_turf, ((counter + 12) % 16) * 22.5)
		SLEEP_CHECK_DEATH(1, src)

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/Move()
	if(noaction)
		return

	if(ranged_cooldown < world.time) //Because of some shitcode fuckery
		INVOKE_ASYNC(src, .proc/OpenFire)

	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/AttackingTarget()
	if(noaction)
		return

	if(ranged_cooldown < world.time) //Because of some shitcode fuckery
		INVOKE_ASYNC(src, .proc/OpenFire)

	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/OpenFire()
	if(noaction)
		return

	anger_modifier = 1 - (clamp(((maxHealth - health) / 100),0,20) * 0.01)
	ranged_cooldown = world.time + (5 * anger_modifier SECONDS)

	if(prob(25) && LAZYLEN(former_targets) > 1)
		target = pick(former_targets - target)
		new /mob/living/simple_animal/hostile/imp/jungle(get_turf(src)) //Leaves a small "present" behind when changes targets
		jaunt_at(target)
		ranged_cooldown = world.time += BLOOD_JAUNT_LENGTH
		SLEEP_CHECK_DEATH(BLOOD_JAUNT_LENGTH, src)

	if(get_dist(src, target) > 12) //Punush them for running away, you can't get away from the demon
		jaunt_at(target)
		ranged_cooldown = world.time + BLOOD_JAUNT_LENGTH + ((demon_form ? 1 : 3) * anger_modifier SECONDS)
		SLEEP_CHECK_DEATH(BLOOD_JAUNT_LENGTH + ((demon_form ? 0 : 1) * anger_modifier SECONDS), src)
		if(prob(35))
			ranged_cooldown = ranged_cooldown + 3 SECONDS
			SLEEP_CHECK_DEATH((demon_form ? 0 : 1) * anger_modifier SECONDS, src)
			spiral_shoot()
		blast_line_directions()
		return

	var/picked_attack = rand(1, 8)
	switch(picked_attack)
		if(1)
			jaunt_at(target)
			ranged_cooldown = world.time + BLOOD_JAUNT_LENGTH + ((demon_form ? 3 : 5) * anger_modifier SECONDS)
			SLEEP_CHECK_DEATH(BLOOD_JAUNT_LENGTH + ((demon_form ? 0 : 2) * anger_modifier SECONDS), src)
			spiral_shoot()
		if(2)
			channel_ray(get_angle(src, target) - 45, get_angle(src, target) + 45)
			ranged_cooldown = world.time + ((demon_form ? 3 : 6) * anger_modifier SECONDS)
		if(3)
			if(demon_form)
				shoot_projectile(get_turf(target), proj_type = /obj/projectile/bloody_orb)
			triple_blast_line()
		if(4)
			blast_circle(target)
			spiral_shoot()
		if(5)
			if(demon_form)
				blast_line(target)
			shoot_projectile(get_turf(target), proj_type = /obj/projectile/bloody_orb)
		if(6)
			blast_circle(target)
			SLEEP_CHECK_DEATH(demon_form ? 2 : 4, src)
			blast_circle(target, (demon_form ? 2 : 1))
			if(demon_form)
				SLEEP_CHECK_DEATH(2, src)
				blast_circle(target)
			ranged_cooldown = world.time + (demon_form ? 2 : 4) * anger_modifier SECONDS
		if(7)
			if(demon_form)
				blast_line_directions(GLOB.alldirs)
				SLEEP_CHECK_DEATH(4, src)
				spiral_shoot()
				return
			blast_line_directions()
		if(8)
			if(demon_form) //Oh boy
				for(var/i = 1 to 3)
					shoot_projectile(null, (i * 120 + rand(60)) % 360, proj_type = /obj/projectile/bloody_orb)
				spiral_shoot()
				return

			for(var/i = 1 to 3)
				blast_circle(target)
				SLEEP_CHECK_DEATH(3, src)

/obj/effect/ebeam/demonic
	name = "demonic beam"
	light_range = 1
	light_power = 0.5
	light_color = COLOR_RED_LIGHT

/obj/effect/temp_visual/demonic_blast_warning
	name = "demonic blast warning"
	icon_state = "demonic_blast_warning"
	duration = 6
	light_range = 1
	light_power = 0.5
	light_color = COLOR_RED_LIGHT
	var/blast_type = /obj/effect/temp_visual/demonic_blast

/obj/effect/temp_visual/demonic_blast_warning/Destroy()
	new blast_type(get_turf(src))
	. = ..()

/obj/effect/temp_visual/demonic_blast_warning/quick
	icon_state = "demonic_blast_warning_quick"
	duration = 4

/obj/effect/temp_visual/demonic_blast_warning/quick/friendly_fire
	blast_type = /obj/effect/temp_visual/demonic_blast/friendly_fire

/obj/effect/temp_visual/demonic_blast
	name = "demonic blast"
	icon_state = "demonic_blast"
	duration = 5
	light_range = 2
	light_power = 0.5
	light_color = COLOR_RED_LIGHT
	var/friendly_fire = FALSE
	var/default_blast = TRUE

/obj/effect/temp_visual/demonic_blast/Initialize()
	. = ..()
	if(default_blast)
		var/turf/my_turf = get_turf(src)
		if(!locate(/mob/living) in my_turf)
			return

		playsound(src, 'sound/magic/mm_hit.ogg', 100, TRUE)
		for(var/mob/living/target in my_turf)
			if(friendly_fire && (istype(target, /mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner)) || faction_check(target.faction, list("jungle", "boss")))
				continue
			target.adjustFireLoss(20)
			to_chat(target, span_userdanger("You're hit by a demonic blast!"))


/obj/effect/temp_visual/demonic_blast/friendly_fire
	friendly_fire = TRUE

/obj/effect/temp_visual/demonic_blast/demonslayer
	default_blast = FALSE

/obj/effect/temp_visual/demonic_blast/demonslayer/Initialize(mapload, mob/caster)
	. = ..()
	var/turf/my_turf = get_turf(src)
	if(!locate(/mob/living) in my_turf)
		return

	playsound(src, 'sound/magic/mm_hit.ogg', 100, TRUE)
	for(var/mob/living/target in my_turf)
		if(target == caster || caster.faction_check_mob(target))
			continue
		if(isanimal(target))
			target.adjustFireLoss(40)
		else
			target.adjustFireLoss(15)
		to_chat(target, span_userdanger("You're hit by a demonic blast!"))

/obj/effect/temp_visual/dir_setting/miner_death/demonic
	icon = 'icons/mob/jungle/jungle_monsters.dmi'
	icon_state = "demonic_miner"

/obj/effect/temp_visual/dir_setting/miner_death/demonic/demon_form
	icon_state = "demonic_miner_phase2"

/obj/effect/abstract/demon_beam_splash
	icon = 'icons/effects/64x64.dmi'
	icon_state = "beam_splash_red"
	layer = RIPPLE_LAYER
	pixel_x = -16
	pixel_y = -16

/obj/effect/abstract/demon_beam_splash/Initialize(mapload)
	. = ..()
	flick("beam_splash_red_starter", src)

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
	return BULLET_ACT_FORCE_PIERCE

/obj/projectile/bloody_orb/proc/start_rays()
	speed = INFINITY //Don't move
	for(var/beam in beams)
		qdel(beam)

	playsound(get_turf(src), 'sound/magic/magic_missile.ogg', 100, TRUE)

	var/list/already_hit = list()

	for(var/beam_target in beam_targets)
		Beam(beam_target, icon_state = "blood_beam_thin", beam_type = /obj/effect/ebeam/demonic, time = 10)
		QDEL_IN(beam_target, 10)

		var/target_turf = get_turf(beam_target)
		var/end_turf = get_ranged_target_turf_direct(src, target_turf, 40, 0)
		var/turf_line = get_line(get_turf(src), end_turf)
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

	QDEL_IN(src, 5)

/obj/projectile/bloody_orb/on_hit(atom/target, blocked, pierce_hit)
	start_rays()

/obj/projectile/bloody_orb/proc/cast_rays()
	addtimer(CALLBACK(src, .proc/start_rays), 3 SECONDS)
	var/turf/cur_turf = get_turf(src)
	for(var/i = 1 to 5)
		var/angle = rand(1, 359)
		var/turf/target_turf = get_turf_in_angle(angle, cur_turf, 15)
		var/obj/effect/temp_beam_target/temp_target = new(get_turf(target_turf))

		for(var/turf/check_turf in get_line(cur_turf, target_turf))
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

/obj/projectile/demonic_energy/nohuman
	damage = 30
	speed = 1

/obj/projectile/demonic_energy/nohuman/on_hit(atom/target, blocked, pierce_hit)
	if(firer == target)
		set_angle(rand(0, 360))
		return BULLET_ACT_FORCE_PIERCE
	if(isliving(firer) && isliving(target))
		var/mob/living/living_firer = firer
		if(living_firer.faction_check_mob(target))
			set_angle(rand(0, 360))
			return BULLET_ACT_FORCE_PIERCE
	if(!isanimal(target))
		damage = 3 //Deals miniscule amounts of damage to humans and silicons
		armour_penetration = 15
	. = ..()

/mob/living/simple_animal/hostile/imp/jungle
	maxHealth = 40
	health = 40
	weather_immunities = list(TRAIT_LAVA_IMMUNE)
	faction = list("hell", "jungle", "boss")

/mob/living/simple_animal/hostile/imp/jungle/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_CRUSHER_VUNERABLE, INNATE_TRAIT)

/mob/living/simple_animal/hostile/imp/jungle/demonic_miner
	wander = FALSE
	var/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner/king
	var/beam

/mob/living/simple_animal/hostile/imp/jungle/demonic_miner/Initialize(mapload)
	. = ..()
	king = locate(/mob/living/simple_animal/hostile/megafauna/jungle/demonic_miner) in range(4, src)
	king.imps += 1
	beam = Beam(king, icon_state = "blood_beam_thin", beam_type = /obj/effect/ebeam/demonic)

/mob/living/simple_animal/hostile/imp/jungle/demonic_miner/Destroy()
	king.imp_death()
	qdel(beam)
	. = ..()

/obj/item/demon_stone
	name = "demonic stone"
	desc = "A pretty big red gem that contains remains of an ancient demon. If you put it close enough to your ears you are able to hear odd wishpers..."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "demon_stone"
	w_class = WEIGHT_CLASS_SMALL
	var/used = FALSE

/obj/item/demon_stone/attack_self(mob/living/user)
	if(!ishuman(user))
		return

	if(used)
		to_chat(user, span_warning("[src] is already drained!"))
		return

	if(tgui_alert(user, "Are you sure to break [src]? Doing so will allow you to harvest souls of your fallen enemies, but they will haunt you forever...", "Demonic Stone", list("Yes", "No")) != "Yes")
		return

	user.emote("scream")
	user.apply_status_effect(STATUS_EFFECT_DEMONSTONE)
	user.visible_message(span_danger("[user] grips [src] in their hand and thousands demonic voices flood your mind!"), span_userdanger("Thousads voices and demonic visions flood your mind as you grip [src] in your hand!"))
	playsound(user, 'sound/effects/glassbr3.ogg', 100)
	playsound(user, 'sound/magic/teleport_app.ogg', 50)
	icon_state = "demon_stone_drained"
	update_icon()
	used = TRUE

#undef BLOOD_JAUNT_LENGTH

/obj/effect/spawner/random/boss/demonic_miner
	name = "demonic miner loot spawner"
	loot = list(/obj/item/gun/magic/staff/blood_claymore = 1, /obj/item/book/granter/spell/throwing_knives = 1, /mob/living/simple_animal/pet/dog/corgi/narsie/hellhound = 1)

#define MAXIMUM_BLOOD 50
#define TELEPORT_BLOOD 5
#define BLOOD_REGEN 1

/obj/item/gun/magic/staff/blood_claymore
	name = "bloodied claymore"
	desc = "An ancient claymore."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	fire_sound = 'sound/magic/wand_teleport.ogg'
	ammo_type = /obj/item/ammo_casing/magic/blood_wave
	icon_state = "bloody_claymore1"
	inhand_icon_state = "bloody_claymore1"
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")
	sharpness = SHARP_EDGED
	hitsound = 'sound/weapons/rapierhit.ogg'

	force = 20
	armour_penetration = 50
	block_chance = 25
	max_charges = 3
	recharge_rate = 10 //Forces you to go in close combat
	school = SCHOOL_FORBIDDEN
	var/blood = 0

/obj/effect/temp_visual/dir_setting/firing_effect/cult
	icon = 'icons/effects/cult/effects.dmi'
	icon_state = "bloodsparkles"
	duration = 3

/obj/item/ammo_casing/magic/blood_wave
	firing_effect_type = /obj/effect/temp_visual/dir_setting/firing_effect/cult
	projectile_type = /obj/projectile/magic/blood_wave

/obj/projectile/magic/blood_wave
	name = "blood wave"
	icon_state = "blood_wave"
	damage = 25
	damage_type = BURN
	nodamage = FALSE

/obj/projectile/magic/blood_wave/on_hit(atom/target, blocked = FALSE)
	if(isliving(target))
		var/mob/living/victim = target
		victim.apply_status_effect(STATUS_EFFECT_DEMON_MARK, fired_from)
	if(!isanimal(target))
		damage = 10
	. = ..()

/obj/item/gun/magic/staff/blood_claymore/update_icon(updates)
	icon_state = "bloody_claymore[clamp(round(blood / MAXIMUM_BLOOD * 3) + (charges > 0 ? 1 : 0), 0, 3)]"
	inhand_icon_state = icon_state
	. = ..()

/obj/item/gun/magic/staff/blood_claymore/afterattack(atom/target, mob/living/user, proximity, params)
	if(LAZYACCESS(params2list(params), RIGHT_CLICK))
		teleport(target, user)
		return

	. = ..()
	if(!proximity || !isliving(target))
		return

	var/mob/living/victim = target
	if(victim.has_status_effect(STATUS_EFFECT_DEMON_MARK) && victim.stat != DEAD && victim.remove_status_effect(STATUS_EFFECT_DEMON_MARK)) // Hitting mobs allows to recharge faster.
		blood = clamp(blood + BLOOD_REGEN, 0, MAXIMUM_BLOOD)
		victim.Beam(user, icon_state="blood_mid_light", time = 0.5 SECONDS)
		playsound(get_turf(victim), 'sound/magic/exit_blood.ogg', 50, TRUE)
		charges += 2
		for(var/i = 1 to 2)
			recharge_newshot()
		update_icon()
		user.changeNext_move(CLICK_CD_RAPID)

/obj/item/gun/magic/staff/blood_claymore/recharge_newshot()
	. = ..()
	update_icon()

/obj/item/gun/magic/staff/blood_claymore/process_fire(atom/target, mob/living/user, message, params, zone_override, bonus_spread)
	. = ..()
	update_icon()

/obj/item/gun/magic/staff/blood_claymore/Initialize()
	. = ..()
	AddComponent(/datum/component/butchering, 15, 125, 0, hitsound)
	AddElement(/datum/element/lifesteal, 8)
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/gun/magic/staff/blood_claymore/attack_self(mob/user)
	if(blood < MAXIMUM_BLOOD)
		to_chat(user, span_warning("[src] does not have enough blood stored inside to use it's true potential!"))
		return

	var/turf/cur_turf = get_turf(user)

	playsound(cur_turf, 'sound/magic/exit_blood.ogg', 100, TRUE)
	playsound(cur_turf, 'sound/magic/mutate.ogg', 100, TRUE)
	user.visible_message(span_danger("[user] lets out a horrible screech as [user.p_they()] begin swinging [src] in circles!"))

	ADD_TRAIT(user, TRAIT_IMMOBILIZED, type)

	var/current_angle = 0
	var/turf/target_turf = get_turf_in_angle(current_angle, cur_turf, 15)

	var/obj/effect/abstract/demon_beam_splash/splash = new(cur_turf)
	var/list/already_hit = list()

	for(var/i = 1 to 72)
		for(var/turf/check_turf in get_line(cur_turf, target_turf))
			if(isclosedturf(check_turf))
				target_turf = check_turf
				break

			for(var/mob/living/victim in check_turf.contents)
				if(victim != user && !faction_check(victim.faction, user.faction) && !(victim in already_hit) && isanimal(victim))
					victim.Paralyze(20)
					victim.adjustBruteLoss(500) //Only hits animals but much stronger than demonic miner's one because duh mobs have huge health pools and it is our ultimate attack that requires 50 hits
					playsound(victim, 'sound/machines/clockcult/ark_damage.ogg', 50, TRUE)
					to_chat(victim, span_userdanger("You're hit by a demonic ray!"))
					already_hit.Add(victim)

		user.Beam(target_turf, icon_state = "bsa_beam_red", beam_type = /obj/effect/ebeam/demonic, time = 0.5)
		var/matrix/splash_matrix = matrix()
		splash_matrix.Turn(current_angle)
		splash_matrix.Translate(cos(current_angle + 90) * 16, -sin(current_angle + 90) * 16)
		splash.transform = splash_matrix

		current_angle += 5
		target_turf = get_turf_in_angle(current_angle, cur_turf, 5)
		user.setDir(angle2dir(current_angle))
		sleep(0.5)

	qdel(splash)

	REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, type)
	blood = 0
	update_icon()

/obj/item/gun/magic/staff/blood_claymore/proc/teleport(atom/target, mob/living/user)
	if(blood < TELEPORT_BLOOD)
		to_chat(user, span_warning("[src] does not have enough blood stored inside to use it's blood jaunt!"))
		return

	var/turf/user_loc = get_turf(user)
	var/turf/destination

	var/counter = 0
	for(var/turf/destination_holder in get_line(user_loc, get_turf(target)))
		if(destination_holder.is_blocked_turf(exclude_mobs = TRUE) || counter > 8)
			break

		destination = destination_holder
		counter += 1

	if(!destination || destination == user_loc)
		return

	playsound(user_loc, "sparks", 50, TRUE)

	new /obj/effect/temp_visual/guardian/phase/out(get_turf(user))
	if(do_teleport(user, destination, channel = TELEPORT_CHANNEL_CULT))
		new /obj/effect/temp_visual/guardian/phase(destination)
		user_loc.Beam(destination, "bsa_beam_red", time = 4)
		playsound(destination, 'sound/effects/phasein.ogg', 25, TRUE)
		playsound(destination, "sparks", 50, TRUE)

	blood -= TELEPORT_BLOOD

	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

#undef MAXIMUM_BLOOD
#undef TELEPORT_BLOOD
#undef BLOOD_REGEN

/obj/projectile/magic/throwing_knife //Really good, you can use it as your main weapon
	name = "demonic throwing knife"
	icon_state = "throwing_knife"
	damage = 5
	damage_type = BRUTE
	nodamage = FALSE
	armour_penetration = 0
	flag = MELEE
	hitsound = 'sound/weapons/rapierhit.ogg'

/obj/projectile/magic/throwing_knife/on_hit(target, blocked = FALSE)
	if(isanimal(target))
		damage *= 7 //350 damage per full barrage
	. = ..()
	if(!.)
		return
	if(isanimal(target) && !blocked && isliving(firer))
		var/mob/living/victim = target
		if(victim.stat == DEAD)
			return
		victim = firer
		victim.heal_ordered_damage(3.5, list(BRUTE, BURN, TOX, OXY)) //Pretty good, 35 healed damage per barrage if all knives hit

/obj/effect/proc_holder/spell/targeted/infinite_guns/throwing_knives
	name = "Summon Knives"
	desc = "Summon a barrage of demonic throwing knives."
	action_icon_state = "throwing_knives"
	action_background_icon_state = "bg_demon"
	clothes_req = FALSE
	summon_path = /obj/item/gun/ballistic/rifle/enchanted/throwing_knife
	charge_max = 20 SECONDS

/obj/item/ammo_casing/magic/throwing_knife
	projectile_type = /obj/projectile/magic/throwing_knife
	firing_effect_type = /obj/effect/temp_visual/dir_setting/firing_effect/cult

/obj/item/gun/ballistic/rifle/enchanted/throwing_knife
	name = "demonic throwing knife"
	desc = "A very sharp throwing knife. It's abnormaly cold."
	fire_sound = 'sound/weapons/guillotine.ogg' //Hilarious, but it actually fits
	pin = /obj/item/firing_pin/magic
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "throwing_knife"
	inhand_icon_state = "edagger"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	slot_flags = null
	can_bayonet = FALSE
	item_flags = DROPDEL | ABSTRACT
	flags_1 = NONE
	trigger_guard = TRIGGER_GUARD_ALLOW_ALL
	show_bolt_icon = FALSE
	guns_left = 10
	hitsound = 'sound/weapons/rapierhit.ogg'
	force = 10
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")
	sharpness = SHARP_EDGED

	mag_type = /obj/item/ammo_box/magazine/internal/throwing_knife

/obj/item/gun/ballistic/rifle/enchanted/throwing_knife/Initialize()
	. = ..()
	AddComponent(/datum/component/butchering, 15, 125, 0, hitsound)
	AddElement(/datum/element/lifesteal, 5)

/obj/item/gun/ballistic/rifle/enchanted/throwing_knife/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	. = ..()
	if(!.)
		return
	user.changeNext_move(CLICK_CD_RAPID)

/obj/item/gun/ballistic/rifle/enchanted/throwing_knife/discard_gun(mob/living/user)
	qdel(src)

/obj/item/book/granter/spell/throwing_knives
	spell = /obj/effect/proc_holder/spell/targeted/infinite_guns/throwing_knives
	spellname = "knife summoning"
	icon_state ="bookknives"
	desc = "Summon a barrage of demonic throwing knives."
	remarks = list("Nal'fh ra B'hr'auh!", "Don't let demons posess you...", "Target their heads, not their feet...", "I saw that move in my favorite cartoon from Space Japan!", "Don't forget to charge cells in these knives or they won't have that cool glow...")

/obj/item/book/granter/spell/throwing_knives/recoil(mob/user)
	..()
	for(var/i = 1 to rand(2, 5))
		playsound(user, 'sound/weapons/guillotine.ogg', 100)
		var/obj/projectile/magic/throwing_knife/knife = new(get_turf(user))
		knife.original = user
		knife.def_zone = BODY_ZONE_CHEST
		knife.spread = 0
		knife.preparePixelProjectile(user, get_turf(user))
		knife.fire()
		sleep(1)

/mob/living/simple_animal/pet/dog/corgi/narsie/hellhound
	name = "hellhound"
	desc = "A pitch-black hound with glowing red eyes that came straight from hell."
	ai_controller = /datum/ai_controller/dog/agressive/hellhound

	health = 300
	maxHealth = 300
	melee_damage_lower = 15
	melee_damage_upper = 25

	atmos_requirements = list("min_oxy" = 3, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	weather_immunities = list(TRAIT_ACID_IMMUNE, TRAIT_LAVA_IMMUNE)
	minbodytemp = 0
	maxbodytemp = 450

/mob/living/simple_animal/pet/dog/corgi/narsie/hellhound/try_feast()
	for(var/mob/living/simple_animal/victim in range(1, src))
		var/devourable = (victim != src && !istype(victim, /mob/living/simple_animal/pet/dog/corgi/narsie)) && (istype(victim, /mob/living/simple_animal/pet) || victim.stat == DEAD) && !istype(victim, /mob/living/simple_animal/hostile/megafauna) && (victim.mob_biotypes & MOB_ORGANIC) && !victim.ckey

		if(devourable) //He gibs either pets or non-megafauna clientless organic monsters
			visible_message(span_warning("[src] devours [victim]!"), \
			"<span class='cult big bold'>DELICIOUS SOULS</span>")
			playsound(src, 'sound/magic/demon_attack1.ogg', 75, TRUE)
			narsie_act()
			victim.gib()

/mob/living/simple_animal/pet/dog/corgi/narsie/hellhound/narsie_act()
	adjustBruteLoss(-200)

/mob/living/simple_animal/pet/dog/corgi/narsie/hellhound/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/projectile/kinetic))
		return TRUE
	else if(istype(mover, /obj/projectile/destabilizer))
		return TRUE
	else if(istype(mover, /obj/projectile/magic/blood_wave))
		return TRUE
	else if(istype(mover, /obj/projectile/magic/throwing_knife))
		return TRUE

/obj/effect/temp_visual/dir_setting/hellhound_recall
	name = "hellhound_recall"
	icon_state = "narsian_out"
	duration = 8.4

/obj/effect/temp_visual/dir_setting/hellhound_recall/out
	icon_state = "narsian_in"

/obj/effect/proc_holder/spell/targeted/hellhound_recall
	name = "Hellhound Recall"
	desc = "Recall or summon your demonic hound."
	charge_max = 3 SECONDS
	clothes_req = FALSE
	invocation = ""
	invocation_type = INVOCATION_WHISPER
	school = SCHOOL_FORBIDDEN
	range = -1
	include_user = TRUE
	selection_type = "range"
	action_icon_state = "hellhound_recall"
	action_background_icon_state = "bg_demon"
	sound = 'sound/magic/ethereal_enter.ogg'
	var/mob/living/simple_animal/pet/dog/corgi/narsie/hellhound/hound

/obj/effect/proc_holder/spell/targeted/hellhound_recall/Initialize(mapload, new_hound)
	. = ..()
	hound = new_hound

/obj/effect/proc_holder/spell/targeted/hellhound_recall/cast(list/targets, mob/user = usr)
	if(hound.loc != user)
		new /obj/effect/temp_visual/dir_setting/hellhound_recall(get_turf(hound), hound.dir)
		hound.toggle_ai(AI_OFF)
		hound.forceMove(user)
		return

	var/list/possible_spawns = list(get_turf(user))
	for(var/direction in GLOB.alldirs)
		var/turf/turf_to_add = get_step(get_turf(user), direction)
		if(!turf_to_add || turf_to_add.is_blocked_turf())
			continue
		possible_spawns += turf_to_add

	var/turf/picked_turf = pick(possible_spawns)
	new /obj/effect/temp_visual/dir_setting/hellhound_recall/out(get_turf(picked_turf), hound.dir)
	sleep(8.4)
	hound.toggle_ai(AI_ON)
	hound.forceMove(picked_turf)
