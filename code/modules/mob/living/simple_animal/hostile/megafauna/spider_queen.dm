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
	move_to_delay = 4
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

	loot = list(/obj/structure/spider/queen_egg/mount, /obj/item/spider_eye)
	common_loot = list(/obj/effect/spawner/random/boss/spider_queen)
	common_crusher_loot = list(/obj/effect/spawner/random/boss/spider_queen, /obj/item/crusher_trophy/spider_leg)
	spawns_minions = TRUE

	wander = TRUE
	gps_name = "Webbed Signal"
	deathmessage = "drops dead, it's legs curling upwards"
	del_on_death = FALSE
	pixel_x = -3
	var/list/vored = list()
	var/list/babies = list()
	var/list/cocoons = list()

	var/datum/action/cooldown/mob_cooldown/charge/spider_queen/triple_charge/triple_charge
	var/datum/action/cooldown/mob_cooldown/charge/spider_queen/target_charge/target_charge
	var/datum/action/cooldown/mob_cooldown/shockwave/shockwave
	var/datum/action/cooldown/mob_cooldown/projectile_attack/rapid_fire/web_shot/web_shot
	var/datum/action/cooldown/mob_cooldown/projectile_attack/rapid_fire/web_shot/no_cd/web_shot_charge
	var/datum/action/cooldown/mob_cooldown/create_spider_cocoons/spawn_spiders

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/Initialize()
	. = ..()
	AddElement(/datum/element/knockback, 2, FALSE, TRUE)
	update_appearance()
	triple_charge = new()
	target_charge = new()
	shockwave = new()
	web_shot = new()
	web_shot_charge = new()
	spawn_spiders = new()
	triple_charge.Grant(src)
	target_charge.Grant(src)
	shockwave.Grant(src)
	web_shot.Grant(src)
	web_shot_charge.Grant(src)
	spawn_spiders.Grant(src)

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_glow")

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/AttackingTarget()
	if(target && istype(target.loc, /obj/structure/spider/cocoon))
		GiveTarget(null)
		return

	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/OpenFire()
	if(client)
		return

	var/anger_modifier = clamp(((maxHealth - health) / 60), 0, 20)

	for(var/former_target in former_targets)
		if(get_dist(src, former_target) <= 2 && prob(50 / max(get_dist(src, former_target), 1)))
			shockwave.Trigger(target = former_target)
			break

	if(LAZYLEN(babies) + LAZYLEN(cocoons) < 2 && prob(40))
		spawn_spiders.Trigger(target = target)

	var/enraged = prob((1 - health / maxHealth) * 200)

	if(enraged)
		if(prob(50 + anger_modifier))
			web_shot_charge.Trigger(target = target)
			sleep(5)
			triple_charge.Trigger(target = target)
		else
			triple_charge.Trigger(target = target)
		return

	if(prob(LAZYLEN(former_targets) * 30))
		if(LAZYLEN(former_targets) > 1)
			target = pick(former_targets - target)
		target_charge.Trigger(target = target)

	else if(prob(20 + anger_modifier))
		triple_charge.Trigger(target = target)
	else
		web_shot.Trigger(target = target)

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/CanAttack(atom/the_target)
	if(istype(the_target.loc, /obj/structure/spider/cocoon))
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/devour(mob/living/cocoon_target)
	ADD_TRAIT(cocoon_target, TRAIT_HUSK, BURN) //Let's make em husked from "burns" so they can be unhusked with synthflesh.

	if(!is_station_level(z) || client)
		adjustBruteLoss(-cocoon_target.maxHealth/2)

	if(prob(40))
		visible_message(span_danger("[src] devours [cocoon_target]!"), span_userdanger("You feast on [cocoon_target], restoring your health!"))
		cocoon_target.forceMove(src)
		vored.Add(cocoon_target)
		return

	var/obj/structure/spider/cocoon/queen/cocoon = new(cocoon_target.loc)
	cocoon_target.forceMove(cocoon)
	cocoon.icon_state = pick("cocoon_large1","cocoon_large2","cocoon_large3")
	visible_message(span_danger("[src] wraps [cocoon_target] up into a cocoon!"), span_userdanger("You suck [cocoon_target] dry and wrap them up into a cocoon, restoring your health!"))

/obj/structure/spider/cocoon/queen/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	return

/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/death(gibbed)
	. = ..()
	if(!gibbed)
		for(var/mob/vore_target in vored)
			vore_target.forceMove(get_turf(src)) //Empties contents of it's stomach upon death

/mob/living/simple_animal/hostile/jungle/cave_spider/baby
	name = "small cave spider"
	desc = "A small pitch-black cave spider with glowing purple eyes and turquoise stripe on it's back. "
	icon_state = "cave_spider_dark"
	icon_living = "cave_spider_dark"
	icon_dead = "cave_spider_dark_dead"
	maxHealth = 50
	health = 50
	melee_damage_lower = 10
	melee_damage_upper = 10
	crusher_drop_mod = 0
	tameable = FALSE
	projectiletype = /obj/projectile/web_ball_spiderling
	var/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/mommy

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/Initialize()
	. = ..()
	update_appearance()

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_glow")

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/death(gibbed)
	. = ..()
	mommy.babies -= src

/obj/projectile/web_ball
	name = "ball of web"
	icon_state = "webball"
	nodamage = TRUE
	damage = 0
	range = 10
	speed = 2
	var/web_beam

/obj/projectile/web_ball/fire(set_angle)
	. = ..()
	web_beam = firer.Beam(src, icon_state = "web", beam_type=/obj/effect/ebeam/web)

/obj/projectile/web_ball/on_hit(atom/movable/targeted, blocked, pierce_hit)
	qdel(web_beam)
	. = ..()
	if (. == BULLET_ACT_HIT)
		if(isliving(targeted))
			var/mob/living/victim = targeted
			var/datum/beam/web = firer.Beam(victim, icon_state = "web", beam_type=/obj/effect/ebeam/web)
			victim.throw_at(firer, get_dist(victim, firer), 2, firer, FALSE, TRUE, callback=CALLBACK(GLOBAL_PROC, .proc/qdel, web), gentle = TRUE)
			if(istype(firer, /mob/living/simple_animal/hostile/megafauna/jungle/spider_queen))
				var/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/queen = firer
				addtimer(CALLBACK(queen.triple_charge, /datum/action/cooldown/mob_cooldown/charge.proc/Activate, victim), 5)

/obj/projectile/web_ball_spiderling
	name = "ball of web"
	icon_state = "webball"
	nodamage = TRUE
	damage = 0
	range = 10
	speed = 2

/obj/projectile/web_ball_spiderling/on_hit(atom/movable/targeted, blocked, pierce_hit)
	. = ..()
	if (. == BULLET_ACT_HIT)
		if(isliving(targeted))
			var/mob/living/victim = targeted
			victim.apply_status_effect(/datum/status_effect/webbed)
