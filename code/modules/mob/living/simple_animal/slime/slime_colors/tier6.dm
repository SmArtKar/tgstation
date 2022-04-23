/datum/slime_color/oil
	color = "oil"
	coretype = /obj/item/slime_extract/oil
	mutations = null
	environmental_req = "Subject's vacuole is extremely weak and will destabilize under pressures lower than 608 kPa, empowering subject's attacks and making the subject potentially explode on death."

/datum/slime_color/oil/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_LIVING_DEATH, .proc/boom)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/boom_attack)
	ADD_TRAIT(slime, TRAIT_BOMBIMMUNE, ROUNDSTART_TRAIT)

/datum/slime_color/oil/remove()
	UnregisterSignal(slime, list(COMSIG_LIVING_DEATH, COMSIG_SLIME_ATTACK_TARGET))
	REMOVE_TRAIT(slime, TRAIT_BOMBIMMUNE, ROUNDSTART_TRAIT)

/datum/slime_color/oil/Life(delta_time, times_fired)
	. = ..()
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(SLIME_SHOULD_MISBEHAVE(slime, delta_time))
		explosion(get_turf(slime), devastation_range = -1, heavy_impact_range = -1, light_impact_range = rand(0, 1), flame_range = rand(1, 2), flash_range = rand(1, 2))

	if(our_mix.return_pressure() > OIL_SLIME_REQUIRED_PRESSURE)
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * get_passive_damage_modifier())

/datum/slime_color/oil/proc/boom(mob/living/simple_animal/slime/dead_body)
	SIGNAL_HANDLER

	for(var/obj/machinery/xenobio_device/vacuole_stabilizer/stabilizer in range(3, get_turf(dead_body)))
		if(stabilizer.on)
			return

	if(!prob(OIL_SLIME_EXPLOSION_CHANCE))
		return

	dead_body.visible_message(span_danger("[dead_body]'s unstable vacuole collapses, causing the oily slime biomass around it to explode!"))
	explosion(get_turf(dead_body), devastation_range = -1, heavy_impact_range = 0, light_impact_range = 1, flame_range = 2, flash_range = 1)

/datum/slime_color/oil/proc/boom_attack(datum/source, atom/attack_target)
	SIGNAL_HANDLER

	if(fitting_environment || !prob(OIL_SLIME_EXPLOSIVE_ATTACK_CHANCE))
		return

	playsound(get_turf(attack_target), 'sound/effects/explosion2.ogg', 200, TRUE)
	new /obj/effect/temp_visual/explosion(get_turf(attack_target))
	for(var/atom/movable/throwback in range(1, get_turf(attack_target)))
		if(throwback == slime || throwback.anchored)
			continue
		var/turf/throw_target = get_edge_target_turf(throwback, get_dir(attack_target, throwback))
		throwback.throw_at(throw_target, 2, 2, slime)
	if(ismovable(attack_target))
		var/atom/movable/victim = attack_target
		var/turf/throw_victim = get_edge_target_turf(victim, get_dir(slime, victim))
		victim.throw_at(throw_victim, 20, 3, slime)

/datum/slime_color/black
	color = "black"
	coretype = /obj/item/slime_extract/black
	mutations = null
	slime_tags = SLIME_DISCHARGER_WEAKENED
	var/list/required_turfs

/datum/slime_color/black/New(slime)
	. = ..()
	if(!required_turfs)
		required_turfs = typecacheof(list(
			/turf/open/misc/asteroid,
			/turf/open/misc/ashplanet,
			/turf/open/misc/dirt,
			/turf/open/floor/fakebasalt,
		))

/datum/slime_color/black/Life(delta_time, times_fired)
	. = ..()

	if(SLIME_SHOULD_MISBEHAVE(slime, delta_time) && DT_PROB(BLACK_SLIME_CHANGE_TURF_CHANCE, delta_time))
		convert_turf()

	var/turf/our_turf = get_turf(slime)
	if(is_type_in_typecache(our_turf, required_turfs))
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * get_passive_damage_modifier())

	if(DT_PROB(BLACK_SLIME_CHANGE_TURF_CHANCE, delta_time))
		convert_turf()

/datum/slime_color/black/proc/convert_turf()

	var/list/convertable_turfs = list()
	for(var/turf/possible_target in circle_range_turfs(get_turf(slime), BLACK_SLIME_TURF_CHANGE_RANGE))
		if(istype(possible_target, /turf/open/misc/slime) || istype(possible_target, /turf/closed/wall/slime))
			continue

		if(isfloorturf(possible_target) || istype(possible_target, /turf/open/misc) || ismineralturf(possible_target))
			convertable_turfs[possible_target] = BLACK_SLIME_TURF_CHANGE_RANGE + 3 - get_dist(slime, possible_target) //Floors have a bit higher chance to be converted
		else if(iswallturf(possible_target))
			var/turf/closed/wall/target_wall = possible_target
			if(!prob(min(100, target_wall.hardness * 2)))
				continue
			convertable_turfs[possible_target] = BLACK_SLIME_TURF_CHANGE_RANGE + 1 - get_dist(slime, possible_target)

	var/turf/target_turf = pick_weight(convertable_turfs)
	if(isclosedturf(target_turf))
		target_turf.ChangeTurf(/turf/closed/wall/slime, flags = CHANGETURF_INHERIT_AIR)
	else if(locate(/obj/structure/window) in target_turf)
		for(var/obj/structure/window/window in target_turf)
			window.deconstruct(FALSE)
		target_turf.ChangeTurf(/turf/closed/wall/slime, flags = CHANGETURF_INHERIT_AIR)
	else
		target_turf.ChangeTurf(/turf/open/misc/slime, flags = CHANGETURF_INHERIT_AIR)

	var/obj/structure/grille/grille = locate() in target_turf
	if(grille)
		grille.deconstruct(FALSE)

/datum/slime_color/adamantine
	color = "adamantine"
	coretype = /obj/item/slime_extract/adamantine
	icon_file = 'icons/mob/big_slimes.dmi'
	pixel_x = -16
	pixel_y = -16
	mutations = null

/datum/slime_color/light_pink
	color = "light pink"
	icon_color = "light_pink"
	coretype = /obj/item/slime_extract/lightpink
	mutations = null
	slime_tags = SLIME_DISCHARGER_WEAKENED
