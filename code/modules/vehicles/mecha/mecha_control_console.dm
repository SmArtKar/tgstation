/obj/machinery/computer/mecha
	name = "exosuit control console"
	desc = "Used to remotely locate or lockdown exosuits."
	icon_screen = "mecha"
	icon_keyboard = "tech_key"
	req_access = list(ACCESS_ROBOTICS)
	circuit = /obj/item/circuitboard/computer/mecha_control

/obj/machinery/computer/mecha/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ExosuitControlConsole", name)
		ui.open()

/obj/machinery/computer/mecha/ui_data(mob/user)
	var/list/data = list()

	var/list/trackerlist = list()
	for(var/obj/vehicle/sealed/mecha/mecha as anything in GLOB.mechas_list)
		for (var/obj/item/mecha_equipment/tracker/tracker in mecha.flat_equipment)
			trackerlist += tracker

	data["mechs"] = list()
	for (var/obj/item/mecha_equipment/tracker/tracker as anything in trackerlist)
		if(!tracker.chassis)
			continue
		var/obj/vehicle/sealed/mecha/mecha = tracker.chassis
		var/list/mech_data = list(
			name = mecha.name,
			integrity = round((mecha.get_integrity() / mecha.max_integrity) * 100),
			charge = mecha.cell ? round(mecha.cell.percent()) : null,
			airtank = (mecha.mecha_flags & IS_ENCLOSED) ? mecha.return_pressure() : null,
			pilot = mecha.return_drivers(),
			location = get_area_name(mecha, TRUE),
			emp_recharging = tracker.recharging,
			tracker_ref = REF(tracker)
		)
		/* SMARTKAR TODO
		if(istype(mecha, /obj/vehicle/sealed/mecha/ripley))
			var/obj/vehicle/sealed/mecha/ripley/workmech = mecha
			mech_data += list(
				cargo_space = round(workmech.cargo_hold.contents.len / workmech.cargo_hold.cargo_capacity * 100)
		)
		*/

		data["mechs"] += list(mech_data)

	return data

/obj/machinery/computer/mecha/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("send_message")
			var/obj/item/mecha_equipment/tracker/tracker = locate(params["tracker_ref"])
			if(!istype(tracker))
				return
			var/message = tgui_input_text(usr, "Input message", "Transmit message", max_length = MAX_MESSAGE_LEN)
			var/obj/vehicle/sealed/mecha/mecha = tracker.chassis
			if(trim(message) && mecha)
				to_chat(mecha.occupants, message)
				to_chat(usr, span_notice("Message sent."))
				return TRUE

		if("shock")
			var/obj/item/mecha_equipment/tracker/tracker = locate(params["tracker_ref"])
			if(!istype(tracker))
				return
			var/obj/vehicle/sealed/mecha/mecha = tracker.chassis
			if(!mecha)
				return
			mecha.emp_act(EMP_LIGHT)
			usr.log_message("has activated remote EMP on exosuit [mecha], located at [loc_name(mecha)], which is currently [LAZYLEN(mecha.occupants) ? "occupied by [mecha.occupants.Join(", ")]." : "without a pilot."]", LOG_ATTACK)
			usr.log_message("has activated remote EMP on exosuit [mecha], located at [loc_name(mecha)], which is currently [LAZYLEN(mecha.occupants) ? "occupied by [mecha.occupants.Join(", ")]." : "without a pilot."]", LOG_GAME, log_globally = FALSE)
			message_admins("[key_name_admin(usr)][ADMIN_FLW(usr)] has activated remote EMP on exosuit [mecha][ADMIN_JMP(mecha)], which is currently [LAZYLEN(mecha.occupants) ? "occupied by [mecha.occupants.Join(",")][ADMIN_FLW(mecha)]." : "without a pilot."]")
			return TRUE
