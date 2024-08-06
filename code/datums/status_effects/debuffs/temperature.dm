/datum/status_effect/fake_temperature
	id = "fake_temperature"
	status_type = STATUS_EFFECT_MULTIPLE
	var/temperature_override

/datum/status_effect/fake_temperature/on_creation(mob/living/new_owner, temperature_override = null)
	. = ..()
	src.temperature_override = temperature_override

/datum/status_effect/fake_temperature/on_apply()
	RegisterSignal(owner, COMSIG_CARBON_UPDATING_TEMPERATURE_HUD, PROC_REF(on_hud_update))
	return TRUE

/datum/status_effect/fake_temperature/on_remove()
	UnregisterSignal(owner, COMSIG_CARBON_UPDATING_TEMPERATURE_HUD)

/datum/status_effect/fake_temperature/proc/on_hud_update(datum/source, old_bodytemp, bodytemp, bodytemp_overrides)
	SIGNAL_HANDLER

	if (!isnull(temperature_override))
		bodytemp_overrides += temperature_override
