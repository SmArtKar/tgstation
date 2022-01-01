#define WEB_DISTANCE 5

/mob/living/simple_animal/hostile/jungle/cave_spider
	name = "cave spider"
	desc = "A big, yet not huge, furred spider. It has a surprisingly big web weaver."
	icon = 'icons/mob/jungle/jungle_monsters.dmi'
	icon_state = "cave_spider"
	icon_living = "cave_spider"
	icon_dead = "cave_spider_dead"
	mob_biotypes = MOB_ORGANIC | MOB_BUG
	speak_emote = list("chitters")
	emote_hear = list("chitters")
	speed = 2
	see_in_dark = 4
	butcher_results = list(/obj/item/food/meat/slab/spider = 1, /obj/item/food/spiderleg = 8)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	initial_language_holder = /datum/language_holder/spider
	maxHealth = 100
	health = 100
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0.25, CLONE = 1.2, STAMINA = 0, OXY = 1)
	unsuitable_cold_damage = 10
	unsuitable_heat_damage = 10
	melee_damage_lower = 15
	melee_damage_upper = 15
	faction = list("jungle", "spiders")
	pass_flags = PASSTABLE
	move_to_delay = 2
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	footstep_type = FOOTSTEP_MOB_CLAW
	obj_damage = 20
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	ranged = TRUE
	projectiletype = /obj/projectile/cave_spider_web
	crusher_drop_mod = 10 //They spawn in packs
	crusher_loot = /obj/item/crusher_trophy/spider_webweaver
	move_resist = MOVE_RESIST_DEFAULT
	move_force = MOVE_FORCE_DEFAULT
	pull_force = PULL_FORCE_DEFAULT
	var/jump_mod = 1
	var/tameable = TRUE

/mob/living/simple_animal/hostile/jungle/cave_spider/Initialize()
	. = ..()
	if(tameable)
		AddComponent(/datum/component/tameable, food_types = list(/obj/item/food/grown/jungle_flora/bagelshroom), tame_chance = 15, bonus_tame_chance = 5, after_tame = CALLBACK(src, .proc/tamed))

/mob/living/simple_animal/hostile/jungle/cave_spider/proc/tamed(mob/living/tamer)
	can_buckle = TRUE
	buckle_lying = 0
	AddElement(/datum/element/ridable, /datum/component/riding/creature/cave_spider_mount/common)
	AddElement(/datum/element/pet_bonus, "chitters happily!")
	faction = list("neutral", "spiders")
	can_have_ai = FALSE
	toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/jungle/cave_spider/OpenFire(atom/targeting)
	if(get_dist(src, targeting) > WEB_DISTANCE)
		return

	if(prob((100 - health / maxHealth) * jump_mod))
		throw_at(targeting, WEB_DISTANCE, 2, src, FALSE, TRUE)
		visible_message("<span class='danger'>[src] jumps at [targeting]!</span>")
		return

	. = ..()

/obj/projectile/cave_spider_web
	name = "spider web"
	invisibility = 101
	nodamage = TRUE
	range = WEB_DISTANCE

/obj/projectile/cave_spider_web/fire(set_angle)
	. = ..()

	firer.Beam(src, icon_state = "web", maxdistance = WEB_DISTANCE, beam_type=/obj/effect/ebeam/web)

/obj/projectile/cave_spider_web/on_hit(atom/movable/targeted, blocked, pierce_hit)
	. = ..()
	if (. == BULLET_ACT_HIT)
		var/datum/beam/web = firer.Beam(targeted, icon_state = "web", maxdistance = WEB_DISTANCE, beam_type=/obj/effect/ebeam/web)
		if(isliving(targeted))
			var/mob/living/L = targeted
			L.safe_throw_at(firer, WEB_DISTANCE, 2, firer, FALSE, TRUE, gentle = TRUE)
		QDEL_IN(web, 3 SECONDS)

/obj/effect/ebeam/web
	name = "spider web"
	mouse_opacity = MOUSE_OPACITY_ICON
	desc = "Thick spider web."

/obj/effect/ebeam/web/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = .proc/on_entered,
	)
	AddElement(/datum/element/connect_loc, src, loc_connections)

/obj/effect/ebeam/web/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(isliving(AM))
		var/mob/living/L = AM
		if(!isspider(L))
			L.Stun(3)
			to_chat(L, "<span class='alert'>You get stuck in [src] for a moment.</span>")

/obj/effect/ebeam/web/attackby(obj/item/O, mob/living/user, params)
	. = ..()
	if(!O.force)
		return
	to_chat(user, "<span class='warning'>You use [O] to tear [src] down</span>")
	qdel(src)
	qdel(owner)

/obj/effect/ebeam/web/attack_hand(mob/user, list/modifiers)
	.= ..()
	if(!HAS_TRAIT(user,TRAIT_WEB_WEAVER))
		return
	user.visible_message("<span class='notice'>[user] begins weaving [src] into cloth.</span>", "<span class='notice'>You begin weaving [src] into cloth.</span>")
	if(!do_after(user, 2 SECONDS))
		return
	var/obj/item/stack/sheet/cloth/woven_cloth = new /obj/item/stack/sheet/cloth
	user.put_in_hands(woven_cloth)
	qdel(src)
	qdel(owner)

/obj/effect/ebeam/web/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return exposed_temperature > 300

/obj/effect/ebeam/web/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	playsound(loc, 'sound/items/welder.ogg', 100, TRUE)
	qdel(src)
	qdel(owner)

/obj/effect/spawner/jungle/cave_spider_nest
	name = "cave spider nest spawner"
	icon = 'icons/effects/effects.dmi'
	icon_state = "stickyweb1"

/obj/effect/spawner/jungle/cave_spider_nest/Initialize()
	. = ..()
	new /mob/living/simple_animal/hostile/jungle/cave_spider(get_turf(src))
	for(var/turf/open/T in range(1, src))

		if(prob(15) && T != src)
			new /mob/living/simple_animal/hostile/jungle/cave_spider(T)

	for(var/turf/open/T in range(3, src))
		if(sqrt((T.x - x) ** 2 + (T.y - y) ** 2) > 3) //I want it to be a CIRCLE
			continue

		var/probability = 30
		for(var/turf/possible_turf in range(1, T))
			if(locate(/obj/structure/spider/stickyweb) in possible_turf || isclosedturf(possible_turf))
				probability += 15

		if(prob(probability) && !istype(T, /turf/open/water/jungle))
			new /obj/structure/spider/stickyweb/cave(T)

	return INITIALIZE_HINT_QDEL

/obj/structure/spider/stickyweb/cave/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	return

/obj/item/crusher_trophy/spider_webweaver //A bit weaker than normal cave spider attack
	name = "cave spider's web weaver"
	desc = "A ripped off web weaver. Suitable as a trophy for a kinetic crusher."
	icon_state = "spider_webweaver"
	denied_type = list(/obj/item/crusher_trophy/spider_webweaver, /obj/item/crusher_trophy/blaster_tubes)
	var/web_shot = FALSE

/obj/item/crusher_trophy/spider_webweaver/effect_desc()
	return "mark detonation to turn next shot into a ball of web that will stun enemies and pull them at you upon hit."

/obj/item/crusher_trophy/spider_webweaver/on_projectile_fire(obj/projectile/destabilizer/marker, mob/living/user)
	if(web_shot)
		marker.name = "webbed [marker.name]"
		marker.icon_state = "webball"
		RegisterSignal(marker, COMSIG_PROJECTILE_ON_HIT, .proc/projectile_hit)
		web_shot = FALSE

/obj/item/crusher_trophy/spider_webweaver/on_mark_detonation(mob/living/target, mob/living/user)
	web_shot = TRUE
	addtimer(CALLBACK(src, .proc/reset_web_shot), 300, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/crusher_trophy/spider_webweaver/proc/reset_web_shot()
	web_shot = FALSE

/obj/item/crusher_trophy/spider_webweaver/proc/projectile_hit(atom/fired_from, atom/movable/firer, atom/target, Angle)
	SIGNAL_HANDLER
	if(isliving(target))
		var/mob/living/L = target
		L.safe_throw_at(firer, WEB_DISTANCE, 1, firer, FALSE, TRUE, gentle = TRUE)
		var/datum/beam/web = firer.Beam(target, icon_state = "web")
		QDEL_IN(web, 3 SECONDS)

#undef WEB_DISTANCE
