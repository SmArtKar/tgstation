/obj/vehicle/sealed/mecha/generate_action_type()
	. = ..()
	if(istype(., /datum/action/vehicle/sealed/mecha))
		var/datum/action/vehicle/sealed/mecha/mecha_action = .
		mecha_action.set_chassis(src)

/datum/action/vehicle/sealed/mecha
	button_icon = 'icons/mob/actions/actions_mecha.dmi'
	var/obj/vehicle/sealed/mecha/chassis

/datum/action/vehicle/sealed/mecha/Destroy()
	chassis = null
	return ..()

///Sets the chassis var of our mecha action to the referenced mecha. Used during actions generation in generate_action_type() chain
/datum/action/vehicle/sealed/mecha/proc/set_chassis(passed_chassis)
	chassis = passed_chassis

/datum/action/vehicle/sealed/mecha/eject
	name = "Eject From Mech"
	button_icon_state = "mech_eject"

/datum/action/vehicle/sealed/mecha/eject/Trigger(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.container_resist_act(owner)

/datum/action/vehicle/sealed/mecha/toggle_cabin_seal
	name = "Toggle Cabin Airtight"
	button_icon_state = "mech_cabin_open"
	desc = "Airtight cabin preserves internal air and can be pressurized with a mounted air tank."

/datum/action/vehicle/sealed/mecha/toggle_cabin_seal/apply_button_icon(atom/movable/screen/movable/action_button/current_button, force)
	button_icon_state = "mech_cabin_[chassis.cabin_sealed ? "pressurized" : "open"]"
	return ..()

/datum/action/vehicle/sealed/mecha/toggle_cabin_seal/Trigger(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.set_cabin_seal(owner, !chassis.cabin_sealed)

/datum/action/vehicle/sealed/mecha/toggle_lights
	name = "Toggle Lights"
	button_icon_state = "mech_lights_off"

/datum/action/vehicle/sealed/mecha/toggle_lights/apply_button_icon(atom/movable/screen/movable/action_button/current_button, force)
	button_icon_state = "mech_lights_[chassis.light_on ? "on" : "off"]"
	return ..()

/datum/action/vehicle/sealed/mecha/toggle_lights/Trigger(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.toggle_lights(owner, !chassis.light_on)

/datum/action/vehicle/sealed/mecha/view_stats
	name = "View Stats"
	button_icon_state = "mech_view_stats"

/datum/action/vehicle/sealed/mecha/view_stats/Trigger(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.ui_interact(owner)

/datum/action/vehicle/sealed/mecha/toggle_safeties
	name = "Toggle Equipment Safeties"
	button_icon_state = "mech_safeties_off"

/datum/action/vehicle/sealed/mecha/toggle_safeties/set_chassis(passed_chassis)
	. = ..()
	RegisterSignal(chassis, COMSIG_MECHA_SAFETIES_TOGGLE, PROC_REF(update_action_icon))

/datum/action/vehicle/sealed/mecha/toggle_safeties/Trigger(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.set_safety(owner)

/datum/action/vehicle/sealed/mecha/toggle_safeties/apply_button_icon(atom/movable/screen/movable/action_button/current_button, force)
	button_icon_state = "mech_safeties_[chassis.safety_enabled ? "on" : "off"]"
	return ..()

/datum/action/vehicle/sealed/mecha/toggle_safeties/proc/update_action_icon()
	SIGNAL_HANDLER
	build_all_button_icons()

/datum/action/vehicle/sealed/mecha/toggle_strafe
	name = "Toggle Strafing"
	button_icon_state = "strafe_off"

/datum/action/vehicle/sealed/mecha/toggle_safeties/apply_button_icon(atom/movable/screen/movable/action_button/current_button, force)
	button_icon_state = "mech_strafe_[chassis.strafing ? "on" : "off"]"
	return ..()

/datum/action/vehicle/sealed/mecha/toggle_strafe/Trigger(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.toggle_strafe()

/datum/action/vehicle/sealed/mecha/toggle_overclock
	name = "Toggle overclocking"
	button_icon_state = "mech_overload_off"

/datum/action/vehicle/sealed/mecha/toggle_overclock/apply_button_icon(atom/movable/screen/movable/action_button/current_button, force)
	button_icon_state = "mech_overload_[chassis.overclock_active ? "on" : "off"]"
	return ..()

/datum/action/vehicle/sealed/mecha/toggle_overclock/Trigger(trigger_flags, forced_state = null)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.toggle_overclock(forced_state)

/*

///swap seats, for two person mecha
/datum/action/vehicle/sealed/mecha/swap_seat
	name = "Switch Seats"
	button_icon_state = "mech_seat_swap"

/datum/action/vehicle/sealed/mecha/swap_seat/Trigger(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return

	if(chassis.occupants.len == chassis.max_occupants)
		chassis.balloon_alert(owner, "other seat occupied!")
		return
	var/list/drivers = chassis.return_drivers()
	chassis.balloon_alert(owner, "moving to other seat...")
	chassis.currently_ejecting = TRUE
	if(!do_after(owner, chassis.has_gravity() ? chassis.exit_delay : 0 , target = chassis))
		chassis.balloon_alert(owner, "interrupted!")
		chassis.currently_ejecting = FALSE
		return
	chassis.currently_ejecting = FALSE
	if(owner in drivers)
		chassis.balloon_alert(owner, "controlling gunner seat")
		chassis.remove_control_flags(owner, VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS)
		chassis.add_control_flags(owner, VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT)
	else
		chassis.balloon_alert(owner, "controlling pilot seat")
		chassis.remove_control_flags(owner, VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT)
		chassis.add_control_flags(owner, VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS)
	chassis.update_icon_state()

*/
