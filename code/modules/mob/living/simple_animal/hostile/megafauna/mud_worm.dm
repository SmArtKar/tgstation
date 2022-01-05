/**
 * Mud Worm
 *
 * A multi-segment worm with thick armor plates you need to destroy first before kiling the segment.
 * It has 200 HP * 2 health bars * 7 segments = 2800 HP. It becomes angrier and harder with each segment.
 *
 * Attack patterns:
 * 1. Worm charges into player. In case player is hit, worm drags them until charge is ended
 * 2. Worm starts creating an acid trail that disappears after a while. Walking over the trail damages you and your gear.
 * 3. Worm spews an acid ball, creating a cloud of well, sulphuric acid.
 * 4. Worm spews it's teeth, making them fall at the player from above similar to ash drake's fireball attack. This attack also activates acid trail when worm is on low HP.
 *
 *
 * Intended Difficulty: Hard
 *
 */

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm
	name = "mud worm"
	desc = "A huge multi-segmented worm with a lot of rocks and mud stuck to it, forming some sort of armor."
	icon_state = "head"
	icon_living = "head"
	base_icon_state = "head"
	icon = 'icons/mob/jungle/mud_worm.dmi'
	maxHealth = 250
	health = 250
	melee_damage_lower = 30
	melee_damage_upper = 30
	move_resist = MOVE_FORCE_OVERPOWERING+1
	movement_type = GROUND

	ranged = TRUE
	ranged_cooldown_time = 40

	del_on_death = TRUE
	loot = list(/obj/item/worm_tongue)
	common_loot = list(/obj/item/armor_scales)
	common_crusher_loot = list(/obj/item/armor_scales, /obj/item/crusher_trophy/blaster_tubes/giant_tooth)
	rare_loot = list(/obj/effect/spawner/random/mud_worm)
	rarity = 2

	gps_name = "Crushing Signal"
	light_range = 1
	light_power = 2
	light_color = LIGHT_COLOR_BROWN

	var/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/back
	var/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/front
	var/list/all_fragments = list()
	var/has_armor = TRUE
	var/prev_loc
	var/charging = FALSE
	var/list/already_hit = list()
	var/acid_trail = FALSE
	var/obj/effect/decal/cleanable/blood/xtracks/thick/prev_trail

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/update_icon(updates)
	if(has_armor)
		icon_state = "[base_icon_state]_plate"
	else
		icon_state = base_icon_state
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/Initialize(mapload, spawn_more = TRUE, len = 6)
	if(!spawn_more)
		true_spawn = FALSE
		ADD_TRAIT(src, TRAIT_NEVER_POI, MEGAFAUNA_TRAIT)

	. = ..()

	if(len < 3)
		stack_trace("Mud Worm Megafauna created with invalid len ([len]). Reverting to 3. Ping SmArtKar on discord and blame his ass.")
		len = 3

	prev_loc = loc
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, .proc/update_worm)
	update_icon()

	if(!spawn_more)
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

	if(front)
		loot = list()
		crusher_loot = list()

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
		for(var/mob/living/targeting in former_targets)
			charge(targeting)
		return

	if(prob(25 + anger_modifier))
		shoot_projectile(get_turf(target))

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
		if(!stepped)
			continue

		if(!(locate(type) in stepped) && !((isclosedturf(stepped) || stepped.is_blocked_turf()) && !ismineralturf(stepped)))
			able_to_move = TRUE
			break

	if(!able_to_move)
		contract_next_chain_into_single_tile()

	if(acid_trail)
		puff()


/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/charge(atom/targeting, chargepast = 5, delay = 6) //Stolen from spider queen where it was stolen from bubblegum
	var/turf/chargeturf = get_turf(targeting)
	var/dir = get_dir(src, chargeturf)
	var/turf/target_turf = get_ranged_target_turf(chargeturf, dir, chargepast)

	if(!target_turf)
		return

	already_hit = list()
	charging = target_turf
	DestroySurroundings()
	walk(src, 0)
	setDir(dir)
	INVOKE_ASYNC(src, .proc/anim_decoy, delay, delay / get_length())
	SLEEP_CHECK_DEATH(delay)
	var/movespeed = 0.5
	walk_towards(src, target_turf, movespeed)
	SLEEP_CHECK_DEATH(get_dist(src, target_turf) * movespeed)
	walk(src, 0)
	charging = FALSE
	already_hit = list()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/anim_decoy(delay = 6, sleep_delay)
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc, src)
	animate(D, alpha = 0, color = "#FF0000", transform = matrix()*2, time = delay)
	if(back)
		SLEEP_CHECK_DEATH(sleep_delay)
		back.anim_decoy(delay, sleep_delay)

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

	var/obj/effect/decal/cleanable/blood/gibs/decal = new /obj/effect/decal/cleanable/blood/xtracks/thick(drop_location())
	decal.setDir(dir)

	var/rev_dir
	if(dir == NORTH)
		rev_dir = SOUTH
	else if(dir == SOUTH)
		rev_dir = NORTH
	else if(dir == EAST)
		rev_dir = WEST
	else if(dir == WEST)
		rev_dir = EAST

	if(!prev_trail || !istype(prev_trail) || prev_trail.dir == dir || prev_trail.dir == rev_dir)
		prev_trail = decal
		return

	prev_trail.setDir(combine_dirs(rev_dir, prev_trail.dir))
	prev_trail = decal

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/acid_act(acidpwr, acid_volume) //Immune to acid
	return

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/start_trail()
	acid_trail = TRUE
	addtimer(CALLBACK(src, .proc/stop_trail), 3 SECONDS)

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/proc/stop_trail()
	acid_trail = FALSE
	prev_trail = null

/obj/projectile/acid_ball
	name = "sphere of acid"
	icon_state = "acid_ball"
	damage = 0
	nodamage = TRUE
	speed = 2

/obj/projectile/acid_ball/on_hit(atom/target, blocked, pierce_hit)
	create_reagents(15)
	reagents.add_reagent(/datum/reagent/toxin/acid, 15)
	var/datum/effect_system/smoke_spread/chem/s = new
	s.set_up(reagents, 2, target, silent = TRUE)
	s.start()
	. = ..()

/// Stolen from drake code

/obj/effect/temp_visual/fireball/giant_tooth //Does brute damage instead of burn and does not set on fire
	name = "giant tooth"
	desc = "Get out of the way!"
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "giant_tooth"
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

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/lesser
	name = "lesser mud worm"
	desc = "A smaller and calmer version mud worm."
	maxHealth = 25
	health = 25
	faction = list("neutral")

	obj_damage = 80
	melee_damage_upper = 30
	melee_damage_lower = 30
	mouse_opacity = MOUSE_OPACITY_ICON
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)

	loot = list()
	crusher_loot = list()
	attack_action_types = list()
	var/player_cooldown = 0

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/lesser/Initialize(mapload, spawn_more = TRUE, len = 3)
	toggle_ai(AI_OFF)
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/lesser/grant_achievement(medaltype,scoretype)
	return

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/lesser/OpenFire()
	if(charging)
		return

	if(ranged_cooldown >= world.time)
		to_chat(src, span_warning("You need to wait [(ranged_cooldown - world.time) / 10] seconds before spewing acid again!"))
		return

	ranged_cooldown = world.time + 120
	shoot_projectile(get_turf(target))

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/lesser/AltClickOn(atom/movable/A)
	if(!istype(A))
		return

	if(player_cooldown >= world.time)
		to_chat(src, span_warning("You need to wait [(player_cooldown - world.time) / 10] seconds before charging again!"))
		return

	player_cooldown = world.time + 200
	GiveTarget(A)
	charge()

/mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/lesser/Destroy()
	if(back)
		qdel(back)
	. = ..()

/obj/effect/proc_holder/spell/targeted/shapeshift/mud_worm
	name = "Worm Form"
	desc = "Take on the shape a lesser mud worm."
	invocation = "CHOOOOOOOMP!!"
	convert_damage = FALSE

	shapeshift_type = /mob/living/simple_animal/hostile/megafauna/jungle/mud_worm/lesser

/obj/item/worm_tongue
	name = "squishy tongue"
	desc = "A giant tongue of some dead mud worm. You're not eating this, right? Riiiight?"
	icon = 'icons/obj/surgery.dmi'
	icon_state = "roro core"

/obj/item/worm_tongue/attack_self(mob/living/carbon/human/user)
	if(!istype(user))
		return

	to_chat(user, span_danger("Power courses through you! You can now shift your form at will."))
	if(user.mind)
		var/obj/effect/proc_holder/spell/targeted/shapeshift/mud_worm/worm = new
		user.mind.AddSpell(worm)

	playsound(user.loc, 'sound/items/eatfood.ogg', 50, TRUE)
	qdel(src)

/obj/item/crusher_trophy/blaster_tubes/giant_tooth
	name = "giant tooth"
	desc = "A giant tooth ripped out of a mud worm's mouth. Suitable as a trophy for a kinetic crusher."
	icon_state = "giant_tooth"
	bonus_value = 10
	denied_type = list(/obj/item/crusher_trophy/spider_webweaver, /obj/item/crusher_trophy/blaster_tubes)

/obj/item/crusher_trophy/blaster_tubes/giant_tooth/effect_desc()
	return "mark detonation to make the next destabilizer shot deal <b>[bonus_value]</b> damage"

/obj/item/crusher_trophy/blaster_tubes/giant_tooth/on_projectile_fire(obj/projectile/destabilizer/marker, mob/living/user)
	if(deadly_shot)
		marker.name = "giant tooth"
		marker.icon_state = "tooth_spin"
		marker.damage = bonus_value
		marker.nodamage = FALSE
		deadly_shot = FALSE

/obj/item/armor_scales
	name = "armor scales"
	desc = "Hardened dirt, mud and rocks in form of natural armor scales."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "armor_scales"
	w_class = WEIGHT_CLASS_TINY
	force = 0
	throwforce = 0

/obj/effect/spawner/random/mud_worm
	name = "mud worm loot spawner"
	loot = list(/obj/item/dual_sword = 1, /obj/item/book/granter/spell/powerdash = 1)

/obj/item/book/granter/spell/powerdash
	spell = /obj/effect/proc_holder/spell/targeted/powerdash
	spellname = "power dash"
	icon_state ="bookdash"
	desc = "Release your inner energy and use it to move around."
	remarks = list("Okay, so I need to place my feet like this and...", "Ugh, is this stance really required?", "Why am I supposed to drink Space Cola before I use this spell?", "Faster, faster, FASTER!")

/obj/item/book/granter/spell/powerdash/recoil(mob/user)
	..()
	var/turf/T = get_edge_target_turf(user, pick(GLOB.alldirs))
	user.throw_at(T, 10, 4, TRUE, TRUE)

/obj/effect/proc_holder/spell/targeted/powerdash
	name = "Power Dash"
	desc = "Makes you dash forward as everybody around you gets thrown backwards. Gives you a speed boost for a while afterwards."
	charge_max = 10 SECONDS
	clothes_req = FALSE
	invocation = "UNLIMITED SPEED!"
	invocation_type = INVOCATION_SHOUT
	school = SCHOOL_EVOCATION
	max_targets = 0
	range = 3
	include_user = TRUE
	selection_type = "view"
	action_icon_state = "repulse"
	sound = 'sound/effects/clockcult_gateway_disrupted.ogg'

/obj/effect/proc_holder/spell/targeted/powerdash/cast(list/targets, mob/user = usr)
	if(!isliving(user))
		return FALSE

	var/atom/target = get_edge_target_turf(user, user.dir)
	var/atom/antitarget = get_edge_target_turf(user, get_dir(target, user))

	var/list/victims = list()
	for(var/mob/living/victim in targets)
		if(get_dir(user, victim) != user.dir && victim != user)
			victims.Add(victim)

	if (user.throw_at(target, 5, 2, spin = FALSE, diagonals_first = TRUE))
		new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(user))
		for(var/mob/living/victim in victims)
			victim.throw_at(antitarget, 3, 1, spin = TRUE, diagonals_first = TRUE)
			new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(victim))
		user.add_movespeed_modifier(/datum/movespeed_modifier/power_dash)
		addtimer(CALLBACK(user, /mob.proc/remove_movespeed_modifier, /datum/movespeed_modifier/power_dash), 5 SECONDS)
		return TRUE
	else
		to_chat(user, span_warning("Something prevents you from dashing forward!"))
		return FALSE


#define PARRY_ACTIVE_TIME 12
#define PARRY_STAGGER_TIME 12

/obj/item/dual_sword //A neat yet hard to use sword. Deals 40 damage to animals and 10 to humans, attacks everything in front of player and allows you to parry for PARRY_ACTIVE_TIME, altrough failed parries stagger you for PARRY_STAGGER_TIME making you unable to act
	name = "double-bladed sword"
	desc = "No, it's not an energy sword. Yeah, sad, I know."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "dual_blade0"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 5
	throwforce = 5
	throw_speed = 1
	throw_range = 1
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_NORMAL
	hitsound = 'sound/weapons/bladeslice.ogg'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_BACK
	armour_penetration = 15
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")
	block_chance = 15
	wound_bonus = -30
	var/swiping = FALSE
	var/parrying = FALSE

/obj/item/dual_sword/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded = 5, force_wielded = 10)
	AddComponent(/datum/component/butchering, 50, 100)

/obj/item/dual_sword/attack(mob/living/M, mob/living/user, params)
	var/pre_force = force
	if(isanimal(M))
		force *= 3
	. = ..()
	force = pre_force

/obj/item/dual_sword/pre_attack(atom/A, mob/living/user, params)
	if(swiping || get_turf(A) == get_turf(user))
		return ..()

	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		parry(user)
		return TRUE

	var/turf/user_turf = get_turf(user)
	var/dir_to_target = get_dir(user_turf, get_turf(A))
	swiping = TRUE
	var/static/list/slash_angles = list(0, 45, -45)
	for(var/i in slash_angles)
		var/turf/T = get_step(user_turf, turn(dir_to_target, i))
		for(var/mob/living/simple_animal/V in T) //Perfect against swarming enemies
			if(user.Adjacent(V))
				melee_attack_chain(user, V)

	swiping = FALSE
	return TRUE

/obj/item/dual_sword/hit_reaction(mob/living/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(!parrying)
		return ..()
	playsound(owner, 'sound/effects/bang.ogg', 50)
	var/modifier = 1
	if(isanimal(hitby))
		modifier = 3

	final_block_chance += 20 * modifier
	if(attack_type == THROWN_PROJECTILE_ATTACK)
		final_block_chance += 30
	else if(attack_type == LEAP_ATTACK)
		final_block_chance = 100
	else if(attack_type == PROJECTILE_ATTACK)
		final_block_chance = 0 //Don't bring a sword to a gunfight

	. = ..()
	if(. && isliving(hitby))
		attack(hitby, owner)
	parrying = FALSE

/obj/item/dual_sword/proc/parry(mob/living/user)
	to_chat(user, span_notice("You prepare to parry!"))
	user.changeNext_move(PARRY_ACTIVE_TIME)
	addtimer(CALLBACK(src, .proc/check_parry_stagger, user), PARRY_ACTIVE_TIME)

/obj/item/dual_sword/proc/check_parry_stagger(mob/living/user)
	if(!parrying)
		return
	to_chat(user, span_warning("You fail to parry, staggering yourself!"))
	user.changeNext_move(PARRY_STAGGER_TIME)

/obj/effect/decal/cleanable/blood/xtracks/thick
	icon_state = "xtracks-thick"

/obj/effect/decal/cleanable/blood/xtracks/thick/on_entered(datum/source, atom/movable/arrived) //Get your ass burned off
	. = ..()
	if(!isliving(arrived))
		return

	var/mob/living/victim = arrived
	victim.acid_act(10, 5)

/obj/effect/decal/cleanable/blood/xtracks/thick/get_timer()
	drytime = world.time + 15 SECONDS

/obj/effect/decal/cleanable/blood/xtracks/thick/dry()
	qdel(src)

#undef PARRY_ACTIVE_TIME
#undef PARRY_STAGGER_TIME
