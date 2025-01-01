
/// Processing temperature, air regulation, alert updates, lights power use.
/obj/vehicle/sealed/mecha/process(seconds_per_tick)
	if(cabin_sealed)
		process_cabin_air(seconds_per_tick)

	if(LAZYLEN(occupants))
		process_occupants(seconds_per_tick)

	process_temperature(seconds_per_tick)
	process_constant_power_usage(seconds_per_tick)

/// Heats or cools cabin air
/obj/vehicle/sealed/mecha/proc/process_cabin_air(seconds_per_tick)
	if(!cabin_air?.return_volume())
		return

	// Cooling systems do not function when overclocking, or overheating, as they're all busy keeping the mech in check
	if (cabin_air.temperature > T20C && (overclock_active || current_heat > maximum_heat))
		return

	var/heat_capacity = cabin_air.heat_capacity()
	var/required_energy = abs(T20C - cabin_air.temperature) * heat_capacity
	required_energy = min(required_energy, 1000)
	if(required_energy < 1)
		return

	var/delta_temperature = required_energy / heat_capacity
	if(!delta_temperature)
		return

	if(cabin_air.temperature < T20C)
		cabin_air.temperature += delta_temperature
	else
		cabin_air.temperature -= delta_temperature

/obj/vehicle/sealed/mecha/proc/process_temperature(seconds_per_tick)
	// When overheating, some heat may start bleeding into the cabin
	if (current_heat > maximum_heat && cabin_air?.return_volume())
		// Assuming that heat is temperature above 20C, and mech can sanely sustain up to maximum_heat + 20C
		cabin_air.temperature = min(current_heat - 20, cabin_air.temperature + (current_heat - maximum_heat) * MECHA_CABIN_HEAT_DUMP_COEFFICIENT / cabin_air.heat_capacity())

	if (cabin_air.return_temperature() > max_temperature)
		take_damage(round(cabin_air.return_temperature() / max_temperature, 0.1) * seconds_per_tick, BURN, null, FALSE)

	if (world.time >= last_heat_tick + cooling_cooldown)
		gain_heat(-cooling_efficiency, direct = TRUE)

/obj/vehicle/sealed/mecha/proc/process_constant_power_usage(seconds_per_tick)
	if(!light_on || use_energy(light_power_drain * seconds_per_tick))
		return

	set_light_on(FALSE)
	playsound(src, 'sound/effects/light_flicker.ogg', 50, FALSE)
	log_message("Toggled lights off due to the lack of power.", LOG_MECHA)

#define MECHA_HEAT_COLOR_THRESHOLD 50
#define MECHA_HEAT_SMOKE_THRESHOLD 70
#define MECHA_HEAT_SMOKE_HIGH_THRESHOLD 80
#define MECHA_HEAT_OUTLINE_THRESHOLD 90
#define MECHA_HEAT_BLUR_THRESHOLD 95

/// Adds heat to our mech
/// direct prevents heat multipliers, such as overclocking, from affecting how much heat we gain
/// prevent_overheat will ensure that the mech won't dump the heat even when not overclocking
/obj/vehicle/sealed/mecha/proc/gain_heat(added_heat, direct = FALSE, prevent_overheat = FALSE)
	var/heat_mult = list()

	if (SEND_SIGNAL(src, COMSIG_MECHA_GAINED_HEAT, added_heat, direct, prevent_overheat, heat_mult) & COMPONENT_CANCEL_MECH_HEAT_GAIN)
		return

	for (var/multiplier in heat_mult)
		added_heat *= multiplier

	var/old_heat = current_heat
	current_heat += added_heat

	if (added_heat <= 0)
		update_heat_effects(old_heat)
		return

	last_heat_tick = world.time

	if (current_heat > maximum_heat && !prevent_overheat && (!overclock_active || overclock_safety))
		overheat()
		return

	if (current_heat > maximum_heat * overclock_maximum_temp_mult * (1 + max(capacitor?.rating - 1, 0) * 0.1))
		start_blowing_up()
		return

	update_heat_effects(old_heat)

/// Handles all heat-related visuals, UI and SFX
/obj/vehicle/sealed/mecha/proc/update_heat_effects(old_heat)
	var/current_percentage = current_heat / maximum_heat
	var/old_percentage = old_heat / maximum_heat
	if (old_percentage >= MECHA_HEAT_COLOR_THRESHOLD && current_percentage < MECHA_HEAT_COLOR_THRESHOLD)
		remove_filter("mecha_heat_color")

	if (current_percentage >= MECHA_HEAT_COLOR_THRESHOLD)
		var/color_factor = 1 - 0.5 * (current_percentage / MECHA_HEAT_COLOR_THRESHOLD)
		add_filter("mecha_heat_color", 1, color_matrix_filter(list(1, 0, 0, 0, 0.5 + color_factor * 0.5, 0, 0, 0, color_factor)))

	// mmm spaghet
	if (old_percentage >= MECHA_HEAT_SMOKE_HIGH_THRESHOLD)
		if (current_percentage < MECHA_HEAT_SMOKE_HIGH_THRESHOLD)
			remove_shared_particles(/particles/smoke/mech)
		if (current_percentage >= MECHA_HEAT_SMOKE_THRESHOLD)
			add_shared_particles(/particles/smoke/mech/minor)
	else if (old_percentage >= MECHA_HEAT_SMOKE_THRESHOLD)
		if (current_percentage >= MECHA_HEAT_SMOKE_HIGH_THRESHOLD)
			remove_shared_particles(/particles/smoke/mech/minor)
			add_shared_particles(/particles/smoke/mech)
		else if (current_percentage < MECHA_HEAT_SMOKE_THRESHOLD)
			remove_shared_particles(/particles/smoke/mech/minor)
	else if (current_percentage >= MECHA_HEAT_SMOKE_THRESHOLD)
		add_shared_particles(/particles/smoke/mech/minor)

	if (old_percentage >= MECHA_HEAT_OUTLINE_THRESHOLD && current_percentage < MECHA_HEAT_OUTLINE_THRESHOLD)
		remove_filter("mecha_heat_outline")

	if (current_percentage > MECHA_HEAT_OUTLINE_THRESHOLD)
		add_filter("mecha_heat_outline", 1, outline_filter(color = "#ffc44dc4", size = 1))

	if (old_percentage >= MECHA_HEAT_BLUR_THRESHOLD && current_percentage < MECHA_HEAT_BLUR_THRESHOLD)
		remove_filter("mecha_heat_blur")

	if (current_percentage > MECHA_HEAT_BLUR_THRESHOLD)
		add_filter("mecha_heat_blur", 1, gauss_blur_filter(0.5))

/// Deals some damage, applies a malfunction and dumps heat
/obj/vehicle/sealed/mecha/proc/overheat()
	var/old_heat = current_heat
	current_heat -= maximum_heat
	playsound(src, 'sound/effects/gas_release.ogg', 70, TRUE)
	playsound(src, 'sound/effects/bamf.ogg', 100, TRUE)
	update_heat_effects(old_heat)

	// Creates a burst of smoke and sparks when overheating
	var/obj/smoke_particles = new /obj/effect/abstract/particle_holder(src, /particles/smoke/mech/overheat)
	addtimer(CALLBACK(smoke_particles.particles, TYPE_PROC_REF(/particles/smoke/mech/overheat, disable_spawning)), 1)
	QDEL_IN(smoke_particles, 2.6 SECONDS)

	var/obj/spark_particles = new /obj/effect/abstract/particle_holder(src, /particles/embers/spark/mech)
	addtimer(CALLBACK(spark_particles.particles, TYPE_PROC_REF(/particles/embers/spark/mech, disable_spawning)), 1)
	QDEL_IN(spark_particles, 2.7 SECONDS)

	var/damage_dealt = max_integrity / 100 * overheat_damage_percentage
	if (atom_integrity < damage_dealt) // Not enough health, go kaboom
		start_blowing_up()
		return

	take_damage(damage_dealt, BRUTE, sound_effect = FALSE)
	if (current_heat > maximum_heat)
		// Don't stack SFX or VFX
		addtimer(CALLBACK(src, PROC_REF(overheat)), 0.5 SECONDS)

/// Blows the mech up alongside all of its drivers due to overheating
/obj/vehicle/sealed/mecha/proc/start_blowing_up()
	animate(src, color = COLOR_RED, time = 0.25 SECONDS, loop = 3)
	animate(color = COLOR_SOFT_RED, time = 0.25 SECONDS)
	playsound(src, SFX_SM_DELAM, 50, FALSE) // Fits surprisingly well, huh
	ADD_TRAIT(src, TRAIT_MECHA_ACTIONS_DISABLED, MECHA_OVERHEAT_TRAIT)
	ADD_TRAIT(src, TRAIT_MECHA_MOVEMENT_DISABLED, MECHA_OVERHEAT_TRAIT)
	// Do this here in case we get destroyed before the timer runs out
	heavy_ex_range += 1
	light_ex_range += 1
	flame_ex_range += 1
	// Don't leave anything behind
	wreck_type = null
	addtimer(CALLBACK(src, PROC_REF(blow_up)), 1.5 SECONDS) // Usually not enough time to climb out of the mech

/obj/vehicle/sealed/mecha/proc/blow_up()
	if (prob(get_charge() * 10 / STANDARD_BATTERY_VALUE))
		tesla_zap(source = src, zap_range = 3, power = get_charge(), cutoff = 1e3)
	take_damage(atom_integrity, BRUTE, sound_effect = FALSE)

/particles/smoke/mech
	position = generator(GEN_CIRCLE, list(), 8, NORMAL_RAND)

/particles/smoke/mech/minor
	spawning = 1
	icon_state = list("chill_1" = 2, "chill_2" = 2, "chill_3" = 1)

/particles/smoke/mech/overheat
	spawning = 50
	velocity = generator(GEN_VECTOR, list(-0.5, 0.4, 0), list(0.5, 0.5, 0), LINEAR_RAND)

/particles/smoke/mech/overheat/proc/disable_spawning()
	spawning = 0

/particles/embers/spark/mech
	count = 15
	spawning = 15

/particles/embers/spark/mech/proc/disable_spawning()
	spawning = 0

#undef MECHA_HEAT_COLOR_THRESHOLD
#undef MECHA_HEAT_SMOKE_THRESHOLD
#undef MECHA_HEAT_SMOKE_HIGH_THRESHOLD
#undef MECHA_HEAT_BLUR_THRESHOLD
#undef MECHA_HEAT_OUTLINE_THRESHOLD
