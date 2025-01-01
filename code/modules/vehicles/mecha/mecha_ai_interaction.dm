/obj/vehicle/sealed/mecha/attack_ai(mob/living/silicon/ai/user)
	// Get diagnostic information
	examine(user)
	// Allows the Malf to scan a mech's status and loadout, helping it to decide if it is a worthy chariot.
	if (user.can_dominate_mechs)
		for (var/obj/item/mecha_equipment/tracker/tracker in flat_equipment)
			to_chat(user, span_danger("Warning: Tracking Beacon detected. Enter at your own risk. Beacon Data:"))
			to_chat(user, "[tracker.get_mecha_info()]")
			break
		// Nothing like a big, red link to make the player feel powerful!
		to_chat(user, "<a href='byond://?src=[REF(user)];ai_take_control=[REF(src)]'>[span_userdanger("ASSUME DIRECT CONTROL?")]</a><br>")
		return


	if (driver_amount())
		to_chat(user, span_warning("This exosuit has a pilot and cannot be controlled."))
		return

	var/can_control_mech = FALSE
	for (var/obj/item/mecha_equipment/tracker/ai_control/ai_tracker in flat_equipment)
		can_control_mech = TRUE
		to_chat(user, "[span_notice("[icon2html(src, user)] Status of [name]:")]")
		to_chat(user, "[ai_tracker.get_mecha_info()]")
		break

	if (!can_control_mech)
		to_chat(user, span_warning("You cannot control exosuits without AI control beacons installed."))
		return

	to_chat(user, "<a href='byond://?src=[REF(user)];ai_take_control=[REF(src)]'>[span_boldnotice("Take control of exosuit?")]</a><br>")

/obj/vehicle/sealed/mecha/transfer_ai(interaction, mob/user, mob/living/silicon/ai/new_pilot, obj/item/aicard/card)
	. = ..()
	if (!.)
		return

	if (interaction == AI_MECH_HACK)
		if (LAZYLEN(occupants))
			if (!new_pilot.can_dominate_mechs)
				to_chat(new_pilot, span_userdanger("[src] is already occupied!"))
				return

			to_chat(new_pilot, span_warning("Occupants detected! Forced ejection initiated!"))
			to_chat(occupants, span_danger("You have been forcibly ejected!"))
			for(var/mob/living/ejectee as anything in occupants)
				mob_exit(ejectee, silent = TRUE, randomstep = TRUE, forced = TRUE)

		new_pilot.linked_core = new /obj/structure/ai_core/deactivated(new_pilot.loc)
		new_pilot.linked_core.remote_ai = new_pilot
		ai_enter_mech(new_pilot)
		return


	if (interaction == AI_TRANS_FROM_CARD) //Using an AI card to upload to a mech.
		new_pilot = card.AI
		if(!new_pilot)
			to_chat(user, span_warning("There is no AI currently installed on this device."))
			return

		if(new_pilot.deployed_shell) //Recall AI if shelled so it can be checked for a client
			new_pilot.disconnect_shell()

		if(new_pilot.stat || !new_pilot.client)
			to_chat(user, span_warning("[new_pilot.name] is currently unresponsive, and cannot be uploaded."))
			return

		if((LAZYLEN(occupants) >= max_occupants) || dna_lock) //Normal AIs cannot steal mechs!
			to_chat(user, span_warning("Access denied. [name] is [LAZYLEN(occupants) >= max_occupants ? "currently fully occupied" : "secured with a DNA lock"]."))
			return

		new_pilot.control_disabled = FALSE
		new_pilot.radio_enabled = TRUE
		to_chat(user, "[span_boldnotice("Transfer successful")]: [new_pilot.name] ([rand(1000,9999)].exe) installed and executed successfully. Local copy has been removed.")
		card.AI = null
		ai_enter_mech(new_pilot)
		return

	if(!(mecha_flags & PANEL_OPEN)) //Mech must be in maint mode to allow carding.
		balloon_alert(user, "panel closed!")
		return

	var/list/ai_pilots = list()
	for(var/mob/living/silicon/ai/ai_pilot in occupants)
		ai_pilots += ai_pilot

	if(!length(ai_pilots)) //Mech does not have an AI for a pilot
		balloon_alert(user, "no AIs!")
		return

	var/mob/living/silicon/ai/ai_pilot = ai_pilots[1]
	if(length(ai_pilots) > 1) //Input box for multiple AIs, but if there's only one we'll default to them.
		ai_pilot = tgui_input_list(user, "Which AI do you wish to card?", "AI Selection", sort_list(ai_pilots))

	if(isnull(ai_pilot))
		return

	if(!(ai_pilot in occupants) || !user.Adjacent(src))
		return //User sat on the selection window and things changed.

	ai_pilot.ai_restore_power() //So the AI initially has power.
	ai_pilot.control_disabled = TRUE
	ai_pilot.radio_enabled = FALSE
	ai_pilot.disconnect_shell()
	remove_occupant(ai_pilot)
	mecha_flags  &= ~SILICON_PILOT
	ai_pilot.forceMove(card)
	card.AI = ai_pilot
	ai_pilot.controlled_equipment = null
	ai_pilot.remote_control = null
	to_chat(ai_pilot, span_notice("You have been downloaded to a mobile storage device. Wireless connection offline."))
	to_chat(user, "[span_boldnotice("Transfer successful")]: [ai_pilot.name] ([rand(1000,9999)].exe) removed from [name] and stored within local memory.")

///Hack and From Card interactions share some code, so leave that here for both to use.
/obj/vehicle/sealed/mecha/proc/ai_enter_mech(mob/living/silicon/ai/new_pilot)
	new_pilot.ai_restore_power()
	mecha_flags |= SILICON_PILOT
	moved_inside(new_pilot)
	new_pilot.eyeobj?.forceMove(src)
	new_pilot.eyeobj?.RegisterSignal(src, COMSIG_MOVABLE_MOVED, TYPE_PROC_REF(/mob/eye/camera/ai, update_visibility))
	new_pilot.controlled_equipment = src
	new_pilot.remote_control = src
	add_occupant(new_pilot)
	to_chat(new_pilot, new_pilot.can_dominate_mechs ? span_greenannounce("Takeover of [name] complete! You are now loaded onto the onboard computer. Do not attempt to leave the station sector!") :\
		span_notice("You have been uploaded to a mech's onboard computer."))
	to_chat(new_pilot, span_boldnotice("Use Middle-Mouse or the action button in your HUD to toggle equipment safety. Clicks with safety enabled will pass AI commands."))
