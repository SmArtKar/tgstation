/datum/slime_color/oil
	color = "oil"
	coretype = /obj/item/slime_extract/oil
	mutations = null
	environmental_req = "Subject's vacuole is extremely weak and will destabilize under pressures lower than 608 kPa, empowering subject's attacks and making the subject potentially explode on death."

/datum/slime_color/oil/New(mob/living/simple_animal/slime/slime)
	. = ..()
	RegisterSignal(slime, COMSIG_LIVING_DEATH, .proc/boom)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_ATOM, .proc/boom_attack)

/datum/slime_color/oil/remove()
	UnregisterSignal(slime, list(COMSIG_LIVING_DEATH, COMSIG_SLIME_ATTACK_ATOM))

/datum/slime_color/oil/Life(delta_time, times_fired)
	. = ..()
	var/datum/gas_mixture/our_mix = slime.loc.return_air()
	if(our_mix.return_pressure() > OIL_SLIME_REQUIRED_PRESSURE)
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time)

/datum/slime_color/oil/proc/boom(mob/living/simple_animal/slime/dead_body)
	SIGNAL_HANDLER

	for(var/obj/machinery/xenobio_device/vacuole_stabilizer/stabilizer in range(3, get_turf(dead_body)))
		if(stabilizer.on)
			return

	if(!prob(OIL_SLIME_EXPLOSION_CHANCE))
		return

	dead_body.visible_message(span_danger("[dead_body]'s unstable vacuole collapses, causing the oily slime biomass around it to explode!"))
	explosion(get_turf(dead_body), devastation_range = -1, heavy_impact_range = 1, light_impact_range = 2, flame_range = 2, flash_range = 1)

/datum/slime_color/oil/proc/boom_attack(datum/source, atom/attack_target)
	SIGNAL_HANDLER

	if(fitting_environment || !prob(OIL_SLIME_EXPLOSIVE_ATTACK_CHANCE))
		return

	playsound(get_turf(attack_target), 'sound/effects/explosion2.ogg', 200, TRUE)
	new /obj/effect/temp_visual/explosion(get_turf(attack_target))
	EX_ACT(attack_target, EXPLODE_LIGHT)
	for(var/atom/movable/throwback in range(1, get_turf(attack_target)))
		if(throwback == slime)
			continue
		var/atom/throw_target = get_edge_target_turf(throwback, get_dir(attack_target, attack_target))
		throwback.throw_at(throw_target, 2, 2, slime)

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

	var/turf/our_turf = get_turf(slime)
	if(is_type_in_typecache(our_turf, required_turfs))
		fitting_environment = TRUE
		return

	fitting_environment = FALSE

/datum/slime_color/adamantine
	color = "adamantine"
	coretype = /obj/item/slime_extract/adamantine
	mutations = null

/datum/slime_color/light_pink
	color = "light pink"
	icon_color = "light_pink"
	coretype = /obj/item/slime_extract/lightpink
	mutations = null
	slime_tags = SLIME_DISCHARGER_WEAKENED
