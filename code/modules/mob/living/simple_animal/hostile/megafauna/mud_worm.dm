/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm
	name = "mud worm"
	desc = "A huge multi-segmented worm with a lot of rocks and mud stuck to it, forming some sort of armor."
	icon_state = "head"
	icon_living = "head"
	base_icon_state = "head"
	icon = 'icons/mob/jungle/mud_worm.dmi'
	maxHealth = 300
	health = 300
	melee_damage_lower = 20
	melee_damage_upper = 20
	move_resist = MOVE_FORCE_OVERPOWERING+1
	movement_type = GROUND

	ranged = TRUE
	ranged_cooldown_time = 40

	del_on_death = TRUE
	faction = list("boss", "jungle")

	var/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/back
	var/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/front
	var/list/all_fragments = list()
	var/has_armor = TRUE
	var/prev_loc
	var/charging = FALSE
	var/list/already_hit = list()
	var/acid_trail

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/update_icon(updates)
	if(has_armor)
		icon_state = "[base_icon_state]_plate"
	else
		icon_state = base_icon_state
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/Initialize(mapload, spawn_more = TRUE, len = 6)
	. = ..()
	if(len < 3)
		stack_trace("Mud Worm Megafauna created with invalid len ([len]). Reverting to 3. Ping SmArtKar on discord and blame his ass.")
		len = 3

	prev_loc = loc
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, .proc/update_worm)
	update_icon()

	if(!spawn_more)
		true_spawn = FALSE
		ADD_TRAIT(src, TRAIT_NEVER_POI, MEGAFAUNA_TRAIT)
		return

	var/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/prev = src
	var/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/current

	for(var/i in 1 to len)
		current = new type(drop_location(),FALSE)
		current.icon_state = "body"
		current.icon_living = "body"
		current.base_icon_state = "body"
		current.toggle_ai(AI_OFF)
		current.front = prev
		current.update_icon()
		prev.back = current
		prev = current
	prev.icon_state = "end"
	prev.icon_living = "end"
	prev.base_icon_state = "end"
	prev.update_icon()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/has_gravity(turf/T) //nograv breaks us
	return TRUE

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/can_be_pulled()
	return FALSE

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/get_length()
	. += 1
	if(back)
		. += back.get_length()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/update_worm()
	SIGNAL_HANDLER

	if(back && back.loc != prev_loc)
		back.Move(prev_loc)
	else if(front)
		setDir(front.dir)

	if(front && loc != front.prev_loc)
		forceMove(front.prev_loc)
	prev_loc = loc
	if(base_icon_state == "head" && back)
		setDir(back.dir)

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/GiveTarget(new_target)
	. = ..()
	if(front)
		front.GiveTarget(new_target)

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/adjustBruteLoss(amount, updating_health, forced)
	if(back && !has_armor && base_icon_state == "head")
		back.adjustBruteLoss(amount, updating_health, forced)
	else
		return ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/adjustFireLoss(amount, updating_health, forced)
	if(back && !has_armor && base_icon_state == "head")
		back.adjustFireLoss(amount, updating_health, forced)
	else
		return ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/death(gibbed, list/force_grant)
	if(has_armor)
		adjustBruteLoss(-maxHealth, forced = TRUE)
		has_armor = FALSE
		update_icon()
		return
	if(base_icon_state == "body")
		front.back = back
		back.front = front
	else if(front && base_icon_state == "end")
		if(front.base_icon_state != "head")
			front.icon_state = "end"
			front.icon_living = "end"
			front.base_icon_state = "end"
		front.back = null

	if(back)
		back.update_worm()

	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/contract_next_chain_into_single_tile()
	if(back)
		back.forceMove(loc)
		back.contract_next_chain_into_single_tile()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/AttackingTarget()
	if(charging)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/OpenFire()
	if(charging)
		return

	ranged_cooldown = world.time + 40
	anger_modifier = clamp((1 - round(get_length() / 10)) * 30, 0, 20)

	if(get_dist(src, target) >= aggro_vision_range || prob(anger_modifier + 35))
		charge()
		return

	if(prob(25 + anger_modifier))
		shoot_projectile(get_turf(target))
		return

	if(prob(40))
		toothanfall()
		if(get_length() > 3)
			return

	start_trail()


/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/Bump(atom/A) //Shamelessly stolen from Bubblegum
	if(charging)
		if(isturf(A) || isobj(A) && A.density)
			if(isobj(A))
				SSexplosions.med_mov_atom += A
			else
				SSexplosions.medturf += A
		DestroySurroundings()
		if(isliving(A) && !(A in already_hit))
			var/mob/living/victim = A
			already_hit.Add(victim)
			victim.visible_message(span_danger("[src] slams into [victim]!"), span_userdanger("[src] slams into you!"))
			victim.apply_damage(30, BRUTE, wound_bonus = CANT_WOUND)
			victim.safe_throw_at(charging, 6, 1, src)
			playsound(get_turf(victim), 'sound/effects/meteorimpact.ogg', 100, TRUE)
			shake_camera(victim, 4, 3)
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(charging)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/Goto(target, delay, minimum_distance)
	if(charging)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/MoveToTarget(list/possible_targets)
	if(charging)
		return
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/Move()
	if(charging)
		DestroySurroundings()
	. = ..()

	if(front)
		return

	var/able_to_move = FALSE
	for(var/direction in GLOB.cardinals)
		var/turf/stepped = get_step(get_turf(src), direction)
		if(!(locate(type) in stepped) && !((isclosedturf(stepped) || stepped.is_blocked_turf()) && !ismineralturf(stepped)))
			able_to_move = TRUE
			break

	if(!able_to_move)
		contract_next_chain_into_single_tile()

	if(acid_trail)
		puff()


/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/charge(chargepast = 5, delay = 3) //Stolen from spider queen where it was stolen from bubblegum
	var/turf/chargeturf = get_turf(target)
	var/dir = get_dir(src, chargeturf)
	var/turf/target_turf = get_ranged_target_turf(chargeturf, dir, chargepast)

	if(!target_turf)
		return

	already_hit = list()
	charging = target_turf
	DestroySurroundings()
	walk(src, 0)
	setDir(dir)
	SLEEP_CHECK_DEATH(delay)
	var/movespeed = 0.5
	walk_towards(src, target_turf, movespeed)
	SLEEP_CHECK_DEATH(get_dist(src, target_turf) * movespeed)
	walk(src, 0)
	charging = FALSE
	already_hit = list()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/shoot_projectile(turf/marker, set_angle, proj_type = /obj/projectile/acid_ball)
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/turf/startloc = get_turf(src)
	var/obj/projectile/P = new proj_type(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = src
	if(target)
		P.original = target
	P.fire(set_angle)

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/projectile/acid_ball))
		return TRUE

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/toothanfall() //Get it?
	if(!target)
		return
	target.visible_message(span_boldwarning("[src] raises it's head, spewing it's own giant teeth into the sky!"))
	var/turf/targetturf = get_turf(target)
	var/list/turfs_for_pick = list()
	for(var/turf/open/turf as anything in RANGE_TURFS(9, targetturf))
		turfs_for_pick.Add(turf)

	for(var/i = 1 to round(LAZYLEN(turfs_for_pick) / 9))
		new /obj/effect/temp_visual/target/tooth(pick_n_take(turfs_for_pick))
		SLEEP_CHECK_DEATH(1)

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/puff()
	if(!acid_trail)
		return
	create_reagents(5)
	reagents.add_reagent(/datum/reagent/toxin/acid, 5)
	var/datum/effect_system/smoke_spread/chem/s = new
	s.set_up(reagents, 0, get_turf(src))
	s.start()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/start_trail()
	acid_trail = TRUE
	addtimer(CALLBACK(src, .proc/stop_trail), 3 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/stop_trail()
	acid_trail = FALSE

/obj/projectile/acid_ball
	name = "sphere of acid"
	icon_state = "acid_ball"
	damage = 0
	nodamage = TRUE
	speed = 2

/obj/projectile/acid_ball/on_hit(atom/target, blocked, pierce_hit)
	create_reagents(30)
	reagents.add_reagent(/datum/reagent/toxin/acid, 30)
	var/datum/effect_system/smoke_spread/chem/s = new
	s.set_up(reagents, 3, target)
	s.start()
	. = ..()

/// Stolen from drake code

/obj/effect/temp_visual/fireball/giant_tooth //Does brute damage instead of burn and does not set on fire
	name = "giant tooth"
	desc = "Get out of the way!"
	icon = 'icons/obj/guns/projectiles.dmi'
	icon_state = "tooth"
	duration = 8

/obj/effect/temp_visual/target/tooth
	duration = 8

/obj/effect/temp_visual/target/tooth/fall(list/flame_hit)
	var/turf/T = get_turf(src)
	if(ismineralturf(T))
		return
	playsound(T, 'sound/effects/break_stone.ogg', 60, TRUE)
	new /obj/effect/temp_visual/fireball/giant_tooth(T)
	sleep(duration)
	playsound(T, 'sound/effects/ethereal_revive_fail.ogg', 60, TRUE)
	for(var/mob/living/L in T.contents)
		if(ismegafauna(L))
			continue

		if(islist(flame_hit) && !flame_hit[L])
			L.adjustBruteLoss(40)
			to_chat(L, span_userdanger("You're hit by a falling giant tooth!"))
			flame_hit[L] = TRUE
		else
			L.adjustBruteLoss(10)
