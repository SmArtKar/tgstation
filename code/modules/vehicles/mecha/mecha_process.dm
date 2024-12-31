/// Adds heat to our mech
/// direct prevents heat multipliers, such as overclocking, from affecting how much heat we gain
/// prevent_overheat will ensure that the mech won't dump heat even outside of overclocking
/obj/vehicle/sealed/mecha/proc/gain_heat(added_heat, direct = FALSE, prevent_overheat = FALSE)
	var/heat_mult = list()
	if (SEND_SIGNAL(src, COMSIG_MECHA_GAINED_HEAT, added_heat, direct, prevent_overheat, heat_mult) & COMPONENT_CANCEL_MECH_HEAT_GAIN)
		return

	for (var/multiplier in heat_mult)
		added_heat *= multiplier

	if (overclock_active && !direct)
		added_heat *= overclock_heat_mult

	current_heat += added_heat
	if (current_heat > maximum_heat && !prevent_overheat && (!overclock_active || overclock_safety))
		overheat()
		return

	if (current_heat > maximum_heat * overclock_maximum_temp_mult)
		blow_up()
		return

	update_heat_visuals()

