/datum/action/cooldown/mob_cooldown/create_spider_cocoons
	name = "Summon Spiderlings"
	desc = "Spawn three spider cocoons that will hatch into spiderlings."
	icon_icon = 'icons/mob/actions/actions_jungle.dmi'
	button_icon_state = "summon_spiders"
	cooldown_time = 1.5 SECONDS

	/// How many cocoons do we spawn
	var/cocoon_amount = 3

/datum/action/cooldown/mob_cooldown/create_spider_cocoons/New(Target, cocoon_amount)
	. = ..()

	if(cocoon_amount)
		src.cocoon_amount = cocoon_amount

/datum/action/cooldown/mob_cooldown/create_spider_cocoons/Activate(atom/target_atom)
	StartCooldown()

	for(var/i = 1 to 3)
		create_cocoon()

/datum/action/cooldown/mob_cooldown/create_spider_cocoons/proc/create_cocoon()
	var/list/possible_turfs = list()
	for(var/turf/fitting_turf in range(3, owner))
		if(isopenturf(fitting_turf) && !fitting_turf.is_blocked_turf() && !(locate(/obj/structure/spider/queen_egg) in fitting_turf))
			possible_turfs[fitting_turf] = 3 - get_dist(owner, fitting_turf)

	var/obj/structure/spider/queen_egg/egg = new(pick_weight(possible_turfs), owner)

	if(istype(owner, /mob/living/simple_animal/hostile/megafauna/jungle/spider_queen))
		var/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/mommy = owner
		mommy.cocoons.Add(egg)
		egg.mommy = mommy

/obj/structure/spider/queen_egg
	name = "black cocoon"
	desc = "A pitch black spider cocoon. What could be inside?.."
	icon_state = "cocoon_black"
	var/birth_timer
	var/spider_type = /mob/living/simple_animal/hostile/jungle/cave_spider/baby
	var/creator
	var/mob/living/simple_animal/hostile/megafauna/jungle/spider_queen/mommy

/obj/structure/spider/queen_egg/Initialize(mapload)
	. = ..()
	birth_timer = addtimer(CALLBACK(src, .proc/give_birth), rand(50, 100), TIMER_UNIQUE | TIMER_STOPPABLE)

/obj/structure/spider/queen_egg/Destroy()
	if(birth_timer)
		deltimer(birth_timer)
	if(mommy)
		mommy.cocoons -= src
	. = ..()

/obj/structure/spider/queen_egg/proc/give_birth()
	var/mob/living/simple_animal/hostile/jungle/cave_spider/baby/spidey = new spider_type(get_turf(src))
	new /obj/effect/decal/cleanable/insectguts(get_turf(src))
	visible_message(span_warning("[src] bursts, revealing [spidey]!"))
	playsound(get_turf(src), 'sound/misc/splort.ogg', 100, TRUE)
	if(mommy)
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
	for(var/mob/living/carbon/human/try_for_owner in spiral_range(8, get_turf(src)))
		if(try_for_owner.client)
			new_owner = try_for_owner
			break
	spidey.set_owner(new_owner)
	qdel(src)
