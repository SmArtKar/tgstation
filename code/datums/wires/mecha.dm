/datum/wires/mecha
	holder_type = /obj/vehicle/sealed/mecha
	proper_name = "Mecha Control"

/datum/wires/mecha/New(atom/holder)
	wires = list(WIRE_LEFT_ARM, WIRE_RIGHT_ARM, WIRE_ZAP, WIRE_OVERCLOCK, WIRE_ACTUATORS, WIRE_TARGETING)
	var/obj/vehicle/sealed/mecha/mecha = holder
	if (mecha.mecha_flags & HAS_LIGHTS)
		wires += WIRE_LIGHT
		add_duds(1)
	else
		add_duds(2)
	RegisterSignal(mecha, COMSIG_MECHA_EQUIPMENT_CLICK, PROC_REF(equipment_click))
	RegisterSignal(mecha, COMSIG_MECHA_MELEE_CLICK, PROC_REF(melee_click))
	RegisterSignal(mecha, COMSIG_MECHA_TRY_MOVE, PROC_REF(try_move))
	..()

/datum/wires/mecha/Destroy()
	UnregisterSignal(holder, list(COMSIG_MECHA_EQUIPMENT_CLICK, COMSIG_MECHA_MELEE_CLICK, COMSIG_MECHA_TRY_MOVE))
	return ..()

/datum/wires/mecha/interactable(mob/user)
	if (!..())
		return FALSE
	var/obj/vehicle/sealed/mecha/mecha = holder
	return mecha.mecha_flags & PANEL_OPEN

/datum/wires/mecha/can_reveal_wires(mob/user)
	if (HAS_TRAIT(user, TRAIT_KNOW_ROBO_WIRES))
		return TRUE
	return ..()

/datum/wires/mecha/get_status()
	. = list()
	var/obj/vehicle/sealed/mecha/mecha = holder
	if (is_cut(WIRE_LEFT_ARM) == is_cut(WIRE_RIGHT_ARM))
		. += "Both green lights are [is_cut(WIRE_LEFT_ARM) ? "off" : "on"]."
	else
		var/left_light = is_cut(WIRE_LEFT_ARM) ? "blinking" : "off"
		var/right_light = is_cut(WIRE_RIGHT_ARM) ? "blinking" : "off"
		. += "The green light on the left is [left_light], and the one on the right is [right_light]."

	. += "The red light is [mecha.overclock_active ? "blinking" : "off"]."
	. += "The blue light is [mecha.canmove || is_cut(WIRE_ACTUATORS) ? "on" : "off"]."
	. += "The purple light is [is_cut(WIRE_TARGETING) ? "blinking": "on"]."

	if(mecha.mecha_flags & HAS_LIGHTS)
		. += "The yellow light is [mecha.light_on ? "on" : "off"]."

	. += "The heat gauge is [mecha.current_heat > mecha.maximum_heat ? "blinking rapidly!" : "[round(mecha.current_heat / mecha.maximum_heat * 100, 5)]% full."]"

/datum/wires/mecha/proc/equipment_click(obj/vehicle/sealed/mecha/mecha, mob/living/user, atom/target, obj/item/mecha_equipment/selected)
	SIGNAL_HANDLER

	if (is_cut(WIRE_LEFT_ARM) && mecha[MECHA_ARM_LEFT_SLOT] == selected)
		return COMPONENT_CANCEL_EQUIPMENT_CLICK
	if (is_cut(WIRE_RIGHT_ARM) && mecha[MECHA_ARM_RIGHT_SLOT] == selected)
		return COMPONENT_CANCEL_EQUIPMENT_CLICK
	if (is_cut(WIRE_TARGETING))
		return COMPONENT_RANDOMIZE_EQUIPMENT_CLICK

/datum/wires/mecha/proc/melee_click(obj/vehicle/sealed/mecha/mecha, mob/living/user, atom/target, on_cooldown, adjacent, list/modifiers)
	SIGNAL_HANDLER

	if (is_cut(WIRE_LEFT_ARM) && !LAZYACCESS(modifiers, RIGHT_CLICK))
		return COMPONENT_CANCEL_MELEE_CLICK
	if (is_cut(WIRE_RIGHT_ARM) && LAZYACCESS(modifiers, RIGHT_CLICK))
		return COMPONENT_CANCEL_MELEE_CLICK
	if (is_cut(WIRE_TARGETING))
		return COMPONENT_RANDOMIZE_MELEE_CLICK

/datum/wires/mecha/proc/try_move(obj/vehicle/sealed/mecha/mecha, direction)
	SIGNAL_HANDLER

	if (is_cut(WIRE_ACTUATORS))
		return COMPONENT_CANCEL_MECHA_MOVE

/datum/wires/mecha/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user
	var/obj/vehicle/sealed/mecha/mecha = holder
	if (!HAS_SILICON_ACCESS(user) && is_cut(WIRE_ZAP) && mecha.shock(usr))
		return FALSE

/datum/wires/mecha/on_pulse(wire, user)
	var/obj/vehicle/sealed/mecha/mecha = holder
	switch (wire)
		if (WIRE_LEFT_ARM)
			try_attack(user, null)
		if (WIRE_RIGHT_ARM)
			try_attack(user, list(RIGHT_CLICK))
		if (WIRE_ZAP)
			mecha.shock(user)
		if (WIRE_OVERCLOCK)
			mecha.toggle_overclock()
		if (WIRE_ACTUATORS)
			// Relatively safe since you cannot turn and it obeys mech's movement cooldowns
			mecha.vehicle_move(mecha.dir)
		if (WIRE_TARGETING)
			mecha.vehicle_move(pick(GLOB.cardinals - mecha.dir))
		if (WIRE_LIGHT)
			mecha.toggle_lights(null, !mecha.light_on)

/datum/wires/mecha/on_cut(wire, mend, source)
	var/obj/vehicle/sealed/mecha/mecha = holder
	switch(wire)
		if(WIRE_LIGHT)
			mecha.set_light_on(!mend)
		if (WIRE_ZAP)
			mecha.shock(source)
		if(WIRE_OVERCLOCK)
			if(!mend)
				mecha.toggle_overclock(FALSE)

// Makes a mech fist-shaped hole in your face if you pulse the wrong wire
/datum/wires/mecha/proc/try_attack(mob/living/target, list/modifiers)
	var/obj/vehicle/sealed/mecha/mecha = holder
	if(mecha.occupant_amount() && !is_cut(WIRE_TARGETING))
		return

	if (!mecha.Adjacent(target) || mecha.safety_enabled || HAS_TRAIT(mecha, TRAIT_MECHA_ACTIONS_DISABLED))
		return

	mecha.melee_attack(null, target, modifiers)
