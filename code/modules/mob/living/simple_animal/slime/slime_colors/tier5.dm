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

/datum/slime_color/bluespace/proc/teleport(atom/step_target)
	if(!prob(BLUESPACE_SLIME_TELEPORT_CHANCE))
		return

	var/turf/slime_turf = get_turf(slime)
	if(HAS_TRAIT(slime_turf, TRAIT_NO_SLIME_TELEPORTATION))
		return

	var/turf/tele_turf = get_step(get_step(get_turf(slime), get_dir(slime, step_target)), get_dir(slime, step_target))

	if(HAS_TRAIT(tele_turf, TRAIT_NO_SLIME_TELEPORTATION))
		return

	if(tele_turf.is_blocked_turf_ignore_climbable(exclude_mobs = TRUE))
		return

	tele_turf.Beam(get_turf(slime), "bluespace_phase", time = 12)
	do_teleport(slime, tele_turf, channel = TELEPORT_CHANNEL_BLUESPACE)
	return COLOR_SLIME_NO_STEP
