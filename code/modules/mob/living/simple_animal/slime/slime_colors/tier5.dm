/datum/slime_color/cerulean
	color = "cerulean"
	coretype = /obj/item/slime_extract/cerulean
	mutations = null
	slime_tags = DISCHARGER_WEAKENED

/datum/slime_color/sepia
	color = "sepia"
	coretype = /obj/item/slime_extract/sepia
	mutations = null

/datum/slime_color/pyrite
	color = "pyrite"
	coretype = /obj/item/slime_extract/pyrite
	mutations = null

/datum/slime_color/bluespace
	color = "bluespace"
	coretype = /obj/item/slime_extract/bluespace
	mutations = null

/datum/slime_color/bluespace/New(slime)
	. = ..()
	RegisterSignal(src.slime, COMSIG_SLIME_TAKE_STEP, .proc/teleport)

/datum/slime_color/bluespace/remove()
	UnregisterSignal(slime, COMSIG_SLIME_TAKE_STEP)

/datum/slime_color/bluespace/proc/teleport(datum/source, atom/step_target)
	if(!prob(BLUESPACE_SLIME_TELEPORT_CHANCE))
		return

	var/turf/slime_turf = get_turf(slime)
	if(HAS_TRAIT(slime_turf, TRAIT_NO_SLIME_TELEPORTATION))
		return

	var/turf/possible_tele_turf = slime_turf
	var/iter = 1
	for(var/turf/tele_turf in get_line(slime_turf, get_turf(step_target)))
		if(iter > BLUESPACE_SLIME_TELEPORT_DISTANCE)
			break

		tele_turf = get_step(tele_turf, get_dir(slime, step_target))
		if(is_safe_turf(tele_turf, no_teleport = TRUE) && !tele_turf.is_blocked_turf_ignore_climbable(exclude_mobs = TRUE) && !HAS_TRAIT(tele_turf, TRAIT_NO_SLIME_TELEPORTATION))
			possible_tele_turf = tele_turf

		iter += 1

	slime_turf.Beam(possible_tele_turf, "bluespace_phase", time = 12)
	do_teleport(slime, possible_tele_turf, channel = TELEPORT_CHANNEL_BLUESPACE)
	return COLOR_SLIME_NO_STEP
