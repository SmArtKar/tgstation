#define VORE_PROBABLILITY 40
#define EGG_LENGTH 5 SECONDS
#define SPIDER_SILK_LIMIT 60
#define SPIDER_SILK_BUFF 10

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
	footstep_type = FOOTSTEP_MOB_CLAW

	melee_damage_lower = 35
	melee_damage_upper = 35
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'

	ranged = TRUE
	ranged_cooldown_time = 30
	aggro_vision_range = 18
	former_target_vision_range = 21
	light_range = 0

	achievement_type = /datum/award/achievement/boss/spider_queen_kill
	crusher_achievement_type = /datum/award/achievement/boss/spider_queen_crusher
	score_achievement_type = /datum/award/score/spider_queen_score

	loot = list(/obj/item/organ/eyes/night_vision/spider, /obj/item/spider_eye)
	common_loot = list(/obj/effect/spawner/random/boss/spider_queen)
	common_crusher_loot = list(/obj/effect/spawner/random/boss/spider_queen, /obj/item/crusher_trophy/spider_leg)
	spawns_minions = TRUE

	wander = TRUE
	gps_name = "Webbed Signal"
	deathmessage = "drops dead, it's legs curling upwards"
	del_on_death = FALSE
	pixel_x = -3
	var/list/vored = list()
	var/charging = FALSE
	var/list/babies = list()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/Initialize()
	. = ..()
	AddElement(/datum/element/knockback, 7, FALSE, TRUE)
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

	ranged_cooldown = world.time + 3 SECONDS
	anger_modifier = clamp(((maxHealth - health)/60), 0, 20)

	if(get_dist(src, target) > aggro_vision_range / 2 || prob(anger_modifier + 35))
		charge()
		if(prob(anger_modifier + 25))
			SLEEP_CHECK_DEATH(5, src)
			triple_birth()
		return

	if(prob(50 - anger_modifier) && LAZYLEN(babies) < 3)
		ranged_cooldown = ranged_cooldown - 1.5 SECONDS
		triple_birth()
		return

	if(prob(50))
		ranged_cooldown = ranged_cooldown + 2 SECONDS
		triple_charge()
		if(prob(40 + anger_modifier))
			SLEEP_CHECK_DEATH(5, src)
			shockwave()
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

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/proc/charge(chargepast = 2, delay = 6) //If you try to run from me I will groundpound your ass
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
	animate(D, alpha = 0, color = "#FF0000", transform = matrix()*2, time = delay)
	SLEEP_CHECK_DEATH(delay, src)
	qdel(D)
	var/movespeed = 0.6
	walk_towards(src, target_turf, movespeed)
	SLEEP_CHECK_DEATH(get_dist(src, target_turf) * movespeed, src)
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

	var/obj/structure/spider/queen_egg/egg = new(pick_weight(possible_turfs))
	egg.mommy = src

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/proc/shotgun(set_angle)
	ranged_cooldown = world.time + 20
	var/turf/target_turf = get_turf(target)
	var/angle_to_target = get_angle(src, target_turf)
	if(isnum(set_angle))
		angle_to_target = set_angle
	var/static/list/shotgun_shot_angles = list(12.5, 7.5, 2.5, -2.5, -7.5, -12.5)
	for(var/i in shotgun_shot_angles)
		shoot_projectile(target_turf, angle_to_target + i)

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/proc/shockwave(range = 3, iteration_duration = 2)
	visible_message("<span class='boldwarning'>[src] smashes the ground around them!</span>")
	playsound(src, 'sound/weapons/sonic_jackhammer.ogg', 200, 1)
	var/list/hit_things = list()
	for(var/i in 1 to range)
		for(var/turf/T in (view(i, src) - view(i - 1, src)))
			if(!T)
				return
			new /obj/effect/temp_visual/small_smoke/halfsecond(T)
			for(var/mob/living/L in T.contents)
				if(L != src && !(L in hit_things) && !faction_check(L.faction, faction))
					var/throwtarget = get_edge_target_turf(T, get_dir(T, L))
					L.throw_at(throwtarget, 6 / i, 1, src)
					L.Stun(4 / i)
					L.apply_damage_type(20 / i, BRUTE)
					hit_things += L
		SLEEP_CHECK_DEATH(iteration_duration, src)

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
	tameable = FALSE
	var/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/mommy

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/Initialize()
	. = ..()
	update_appearance()

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_glow")

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/death(gibbed)
	if(mommy)
		mommy.babies.Remove(src)
	. = ..()

/obj/structure/spider/queen_egg
	name = "black cocoon"
	desc = "A pitch black spider cocoon. What could be inside?.."
	icon_state = "cocoon_black"
	var/birth_timer
	var/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/mommy
	var/spider_type = /mob/living/simple_animal/hostile/jungle/cave_spider/baby

/obj/structure/spider/queen_egg/Initialize(mapload)
	. = ..()
	birth_timer = addtimer(CALLBACK(src, .proc/give_birth), EGG_LENGTH, TIMER_UNIQUE | TIMER_STOPPABLE)

/obj/structure/spider/queen_egg/Destroy()
	if(birth_timer)
		deltimer(birth_timer)
	. = ..()

/obj/structure/spider/queen_egg/proc/give_birth()
	var/mob/living/simple_animal/hostile/jungle/cave_spider/baby/spidey = new spider_type(get_turf(src))
	new /obj/effect/decal/cleanable/insectguts(get_turf(src))
	visible_message(span_warning("[src] bursts, revealing [spidey]!"))
	mommy.babies.Add(spidey)
	spidey.mommy = mommy
	qdel(src)

/obj/structure/spider/queen_egg/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	return

/obj/structure/spider/queen_egg/mount
	spider_type = /mob/living/simple_animal/hostile/jungle/cave_spider/baby/mount

/obj/structure/spider/queen_egg/mount/give_birth()
	var/mob/living/simple_animal/hostile/jungle/cave_spider/baby/mount/spidey = new spider_type(get_turf(src))
	new /obj/effect/decal/cleanable/insectguts(get_turf(src))
	visible_message(span_warning("[src] bursts, revealing [spidey]!"))
	var/mob/living/carbon/human/new_owner
	for(var/mob/living/carbon/human/try_for_owner in range(8, get_turf(src)))
		if(!ismonkey(try_for_owner))
			new_owner = try_for_owner
			break
	spidey.get_owner(new_owner)
	qdel(src)

/obj/projectile/web_ball
	name = "ball of web"
	icon_state = "webball"
	nodamage = TRUE
	range = 10
	speed = 4
	var/web_beam

/obj/projectile/web_ball/fire(set_angle)
	. = ..()

	web_beam = firer.Beam(src, icon_state = "web", beam_type=/obj/effect/ebeam/web)

/obj/projectile/web_ball/on_hit(atom/movable/targeted, blocked, pierce_hit)
	qdel(web_beam)
	. = ..()
	if (. == BULLET_ACT_HIT)
		var/datum/beam/web = firer.Beam(targeted, icon_state = "web", beam_type=/obj/effect/ebeam/web)
		if(isliving(targeted))
			var/mob/living/L = targeted
			L.throw_at(firer, get_dist(L, firer), 2, firer, FALSE, TRUE)
			L.Paralyze(1 SECONDS)
		QDEL_IN(web, 3 SECONDS)

/datum/status_effect/spider_damage_tracker
	id = "spider_damage_tracker"
	duration = -1
	alert_type = null
	var/damage = 0
	var/lasthealth

/datum/status_effect/spider_damage_tracker/tick()
	if((lasthealth - owner.health) > 0)
		damage += (lasthealth - owner.health)
	lasthealth = owner.health

/obj/item/organ/eyes/night_vision/spider
	name = "spider eyes"
	desc = "Eight eyes instead of two!"
	eye_icon_state = "spidereyes"
	icon_state = "eyeballs-spider"
	flash_protect = FLASH_PROTECTION_SENSITIVE
	overlay_ignore_lighting = TRUE
	var/active_icon = FALSE
	var/list/active_friends = list()
	var/list/former_friends = list()

/obj/item/organ/eyes/night_vision/spider/on_life(delta_time, times_fired)
	var/turf/owner_turf = get_turf(owner)
	var/lums = owner_turf.get_lumcount()
	if(lums > 0.75)
		if(active_icon)
			active_icon = FALSE
			eye_icon_state = initial(eye_icon_state)
			icon_state = initial(icon_state)
			owner.update_appearance()
			for(var/X in actions)
				var/datum/action/A = X
				A.UpdateButtonIcon()
	else
		if(!active_icon)
			active_icon = TRUE
			eye_icon_state = "[initial(eye_icon_state)]_active"
			icon_state = "[initial(icon_state)]_active"
			owner.update_appearance()
			for(var/X in actions)
				var/datum/action/A = X
				A.UpdateButtonIcon()

	for(var/mob/living/simple_animal/M in view(7, owner_turf)) //You also look like spider so they don't attack you as long as you don't attack them
		if(!(M in active_friends) && !(M in former_friends) && isspider(M))
			active_friends += M
			M.apply_status_effect(/datum/status_effect/spider_damage_tracker)
			M.faction |= owner.real_name

	for(var/mob/living/simple_animal/M in active_friends)
		if(!(M in view(7, get_turf(owner_turf))))
			M.faction -= owner.real_name
			M.remove_status_effect(/datum/status_effect/spider_damage_tracker)
			active_friends -= M
			continue

		var/datum/status_effect/spider_damage_tracker/C = M.has_status_effect(/datum/status_effect/spider_damage_tracker)
		if(istype(C) && C.damage > 0)
			M.faction -= owner.real_name
			M.remove_status_effect(/datum/status_effect/spider_damage_tracker)
			active_friends -= M
			former_friends += M

	. = ..()

/obj/item/organ/eyes/night_vision/spider/Insert(mob/living/carbon/eye_owner, special = FALSE)
	. = ..()
	ADD_TRAIT(eye_owner, TRAIT_THERMAL_VISION, ORGAN_TRAIT)

/obj/item/organ/eyes/night_vision/spider/Remove(mob/living/carbon/eye_owner, special = FALSE)
	REMOVE_TRAIT(eye_owner, TRAIT_THERMAL_VISION, ORGAN_TRAIT)
	for(var/mob/living/simple_animal/M in active_friends)
		M.faction -= eye_owner.real_name
		M.remove_status_effect(/datum/status_effect/spider_damage_tracker)
		active_friends -= M
		former_friends += M

	active_friends = list()
	former_friends = list()

	. = ..()

/obj/item/organ/eyes/night_vision/spider/attack(mob/M, mob/living/carbon/user, obj/target) //Surgery sucks
	if(M != user)
		return ..()

	user.visible_message(span_warning("[user] presses [src] against [user.p_their()] face and they suddenly start growing in!"), span_userdanger("You press [src] against your face and suddenly they grow in and replace your eyes!"))
	user.temporarilyRemoveItemFromInventory(src, TRUE)
	user.emote("scream")
	src.Insert(user)

/obj/item/stack/sheet/spidersilk
	name = "spider silk cloth"
	icon = 'icons/obj/mining.dmi'
	desc = "A very tough and resistant cloth made from spider silk."
	singular_name = "spider silk cloth"
	icon_state = "sheet-spidersilk"
	max_amount = 3
	novariants = FALSE
	item_flags = NOBLUDGEON
	w_class = WEIGHT_CLASS_SMALL
	merge_type = /obj/item/stack/sheet/spidersilk

/obj/item/stack/sheet/spidersilk/afterattack(atom/A, mob/living/user, proximity_flag, clickparams)
	if(!istype(A, /obj/item/clothing/suit) && !istype(A, /obj/item/clothing/head))
		return ..()


	var/obj/item/clothing/target = A
	if(((MELEE in target.armor) && target.armor[MELEE] >= SPIDER_SILK_LIMIT) || HAS_TRAIT(target, TRAIT_SPIDER_SILK_UPGRADED))
		to_chat(user, span_warning("[target] can't be upgraded further!"))
		return ..()


	if(!target.armor.melee)
		target.armor.melee = SPIDER_SILK_BUFF
	else
		target.armor.melee = min(SPIDER_SILK_LIMIT, target.armor.melee + SPIDER_SILK_BUFF)
	to_chat(user, span_notice("You successfully upgrade [target] with [src]"))
	ADD_TRAIT(target, TRAIT_SPIDER_SILK_UPGRADED, MEGAFAUNA_TRAIT)
	use(1)

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/mount
	name = "tamed baby cave spider"
	desc = "A pitch-black cave spider baby with glowing purple eyes and turquoise stripe on it's back. It seems completely friendly and non-hostile."
	maxHealth = 300 //Made it tough so it won't get instakilled by fauna
	health = 300
	melee_damage_lower = 0
	melee_damage_upper = 0
	ranged = FALSE
	faction = list("neutral", "jungle", "spiders")
	can_buckle = TRUE
	buckle_lying = 0
	move_force = MOVE_FORCE_NORMAL
	move_resist = MOVE_FORCE_NORMAL
	pull_force = MOVE_FORCE_NORMAL
	ai_controller = /datum/ai_controller/hostile_friend

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/mount/Initialize()
	. = ..()
	AddElement(/datum/element/ridable, /datum/component/riding/creature/cave_spider_mount)
	AddElement(/datum/element/pet_bonus, "chitters happily!")
	can_have_ai = FALSE
	toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/mount/proc/get_owner(mob/living/owner)
	faction.Add("[REF(owner)]")
	if(ai_controller)
		var/datum/ai_controller/hostile_friend/ai_current_controller = ai_controller
		ai_current_controller.befriend(owner)
		can_have_ai = FALSE
		toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/mount/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(!istype(I, /obj/item/food/grown/jungle_flora/bagelshroom) && !istype(I, /obj/item/food/cut_bagelshroom))
		return

	if(stat == DEAD)
		to_chat(user, span_warning("[src] is dead!"))

	user.visible_message(span_notice("[user] hand-feeds [I] to [src]."), span_notice("You hand-feed [src] to [user]."))
	new /obj/effect/temp_visual/heart(loc)
	if(prob(50))
		manual_emote("chitters happily!")
	qdel(I)
	adjustHealth(-75) //Heal it with bagelshrooms!

/obj/effect/spawner/random/boss/spider_queen
	name = "spider queen loot spawner"
	loot = list(/obj/item/stack/sheet/spidersilk = 1, /obj/structure/spider/queen_egg/mount = 1)

/obj/item/spider_eye
	name = "spider queen eye"
	desc = "A giant eye of a spider queen. It looks squishy..."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "spider_eye"
	inhand_icon_state = null
	worn_icon_state = null
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = null
	custom_materials = list()
	actions_types = list()
	light_system = MOVABLE_LIGHT_DIRECTIONAL
	light_range = 3
	light_color = "#993FD4"
	light_on = FALSE

/obj/item/spider_eye/attack_self(mob/user)
	playsound(user, 'sound/misc/splort.ogg', 40, TRUE)
	icon_state = initial(icon_state)
	set_light_on(TRUE)
	addtimer(CALLBACK(src, .proc/turnOff, user), 5 SECONDS)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/item/spider_eye/proc/turnOff(mob/user)
	playsound(user, 'sound/misc/splort.ogg', 40, TRUE)
	icon_state = "[initial(icon_state)]-on"
	set_light_on(FALSE)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/item/crusher_trophy/spider_leg
	name = "queen spider leg"
	desc = "A leg ripped off from a spider queen. Suitable as a trophy for a kinetic crusher."
	icon_state = "spider_leg"
	denied_type = /obj/item/crusher_trophy/spider_leg

/obj/item/crusher_trophy/spider_leg/effect_desc()
	return "mark detonation to create a shockwave, throwing your enemies away from you"

/obj/item/crusher_trophy/spider_leg/on_mark_detonation(mob/living/target, mob/living/user)
	INVOKE_ASYNC(src, .proc/create_shockwave, target, user)

/obj/item/crusher_trophy/spider_leg/proc/create_shockwave(mob/living/target, mob/living/user)
	var/list/hit_things = list()
	var/turf/T = get_turf(user)
	for(var/i in 1 to 3)
		T = get_step(T, get_dir(user, target))
		if(!T)
			return
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/L in T.contents)
			if(L != src && !(L in hit_things) && !faction_check(L.faction, user.faction))
				var/throwtarget = get_edge_target_turf(T, get_dir(T, L))
				L.throw_at(throwtarget, 5, 1, user)
				L.adjustBruteLoss(10)
				hit_things += L
		sleep(1)

#undef VORE_PROBABLILITY
#undef SPIDER_SILK_LIMIT
#undef SPIDER_SILK_BUFF
#undef EGG_LENGTH
