#define WEB_DISTANCE 5

/mob/living/simple_animal/hostile/jungle/cave_spider
	name = "cave spider"
	desc = "A big, yet not huge, furred spider. It has a surprisingly big web weaver."
	icon_state = "cave_spider"
	icon_living = "cave_spider"
	icon_dead = "cave_spider_dead"
	mob_biotypes = MOB_ORGANIC | MOB_BUG
	speak_emote = list("chitters")
	emote_hear = list("chitters")
	speed = 0
	turns_per_move = 2
	see_in_dark = 4
	butcher_results = list(/obj/item/food/meat/slab/spider = 1, /obj/item/food/spiderleg = 8)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	initial_language_holder = /datum/language_holder/spider
	maxHealth = 150
	health = 150
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0.25, CLONE = 1.2, STAMINA = 0, OXY = 1)
	unsuitable_cold_damage = 10
	unsuitable_heat_damage = 10
	melee_damage_lower = 20
	melee_damage_upper = 20
	combat_mode = TRUE
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

/mob/living/simple_animal/hostile/jungle/cave_spider/OpenFire(atom/targeting)
	if(get_dist(src, targeting) > WEB_DISTANCE)
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
			L.Paralyze(2 SECONDS)
			targeted.throw_at(firer, WEB_DISTANCE, 2, firer, FALSE, TRUE)
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

	for(var/turf/open/T in range(2, src))
		if(prob(60) && !istype(T, /turf/open/water/jungle))
			new /obj/structure/spider/stickyweb(T)

	return INITIALIZE_HINT_QDEL

#undef WEB_DISTANCE
