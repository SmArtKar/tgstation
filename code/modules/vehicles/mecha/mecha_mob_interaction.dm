
/obj/vehicle/sealed/mecha/mob_try_enter(mob/living/new_pilot)
	if(!ishuman(new_pilot)) // no silicons or drones in mechas.
		return

	// No lavalizards or monkeys in mechs
	if(HAS_TRAIT(new_pilot, TRAIT_PRIMITIVE) && !ISADVANCEDTOOLUSER(new_pilot))
		to_chat(new_pilot, span_warning("The knowledge to use this device eludes you!"))
		return

	log_message("[new_pilot] tried to move into [src].", LOG_MECHA)

	if(dna_lock && new_pilot.has_dna()?.unique_enzymes != dna_lock)
		to_chat(new_pilot, span_warning("Access denied. [name] is secured with a DNA lock."))
		log_message("Permission denied (DNA LOCK).", LOG_MECHA)
		return

	if((mecha_flags & ACCESS_LOCK_ON) && !allowed(new_pilot))
		to_chat(new_pilot, span_warning("Access denied. Insufficient operation keycodes."))
		log_message("Permission denied (No keycode).", LOG_MECHA)
		return

	. = ..()
	if(.)
		moved_inside(new_pilot)

/obj/vehicle/sealed/mecha/enter_checks(mob/living/new_pilot)
	if(new_pilot.incapacitated)
		return FALSE

	if(atom_integrity <= 0) // somehow?
		to_chat(new_pilot, span_warning("[src] has been destroyed!"))
		return FALSE

	if(new_pilot.buckled)
		to_chat(new_pilot, span_warning("You can't enter the exosuit while buckled to [new_pilot.buckled]."))
		return FALSE

	if(new_pilot.has_buckled_mobs())
		to_chat(new_pilot, span_warning("You can't enter the exosuit with other creatures attached to you!"))
		return FALSE
	return ..()

/obj/vehicle/sealed/mecha/add_occupant(mob/driver, control_flags)
	RegisterSignal(driver, COMSIG_MOB_CLICKON, PROC_REF(on_mouseclick))
	RegisterSignal(driver, COMSIG_MOB_SAY, PROC_REF(display_speech_bubble))
	RegisterSignal(driver, COMSIG_MOVABLE_KEYBIND_FACE_DIR, PROC_REF(on_turn))
	RegisterSignal(driver, COMSIG_MOB_ALTCLICKON, PROC_REF(on_click_alt))
	. = ..()
	update_appearance()

/obj/vehicle/sealed/mecha/remove_occupant(mob/driver)
	UnregisterSignal(driver, list(
		COMSIG_MOB_CLICKON,
		COMSIG_MOB_SAY,
		COMSIG_MOVABLE_KEYBIND_FACE_DIR,
		COMSIG_MOB_ALTCLICKON,
	))
	driver.update_mouse_pointer()
	/* SMARTKAR TODO
	driver.clear_alert(ALERT_CHARGE)
	driver.clear_alert(ALERT_MECH_DAMAGE)
	if(driver.client)
		driver.client.view_size.resetToDefault()
		zoom_mode = FALSE
	*/
	. = ..()
	update_appearance()

/obj/vehicle/sealed/mecha/after_add_occupant(mob/living/new_occupant)
	. = ..()
	// Update COMP unit flags when someone enters in case we need to revoke their driver's license
	for (var/mob/living/brain/comp_unit in occupants)
		if (comp_unit == new_occupant)
			continue
		remove_control_flags(comp_unit, ALL)
		auto_assign_occupant_flags(comp_unit)

/obj/vehicle/sealed/mecha/after_remove_occupant(mob/living/former_occupant)
	. = ..()
	// Update COMP unit flags when someone exits in case they need to be given driver persmissions
	for (var/mob/living/brain/comp_unit in occupants)
		remove_control_flags(comp_unit, ALL)
		auto_assign_occupant_flags(comp_unit)

/// Proc called whenever a new pilot enters a mech
/obj/vehicle/sealed/mecha/proc/moved_inside(mob/living/new_pilot)
	mecha_flags &= ~PANEL_OPEN // Close panel if open
	add_fingerprint(new_pilot)
	log_message("[new_pilot] moved in as pilot.", LOG_MECHA)
	setDir(SOUTH)
	playsound(src, 'sound/machines/windowdoor.ogg', 50, TRUE)
	set_mouse_pointer()
	SEND_SOUND(new_pilot, sound('sound/vehicles/mecha/nominal.ogg', volume = 50))

/obj/vehicle/sealed/mecha/mob_exit(mob/living/user, silent = FALSE, randomstep = FALSE, forced = FALSE)
	var/turf/cur_turf = get_turf(src)
	setDir(SOUTH)
	SStgui.close_user_uis(user, src)
	if (isbrain(user))
		var/mob/living/brain/brain = user
		var/obj/item/mmi/mmi = brain.container
		mmi.forceMove(cur_turf)
		// Restore our occupant limit after removing a COMP unit
		if (!mmi_full_control || istype(new_pilot, /obj/item/mmi/posibrain))
			max_occupants -= 1
		log_message("[mmi] moved out.", LOG_MECHA)
		if(mmi.brainmob)
			brain.forceMove(mmi)
			brain.reset_perspective()
			remove_occupant(brain)
		mmi.set_mecha(null)
		mmi.update_appearance()
		return ..()

	if (!isAI(user))
		user.forceMove(cur_turf)
		log_message("[user] moved out.", LOG_MECHA)
		return ..()

	var/mob/living/silicon/ai/sillycone = user
	sillycone.eyeobj?.UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	sillycone.eyeobj?.forceMove(cur_turf) //kick the eye out as well
	sillycone.controlled_equipment = null
	sillycone.remote_control = null
	mecha_flags &= ~SILICON_PILOT
	// Something went awry with the mech, and AI has fully shunted into us
	if (forced && !sillycone.linked_core)
		if (!sillycone.can_shunt || !LAZYLEN(sillycone.hacked_apcs))
			sillycone.investigate_log("has been gibbed by being forced out of their mech.", INVESTIGATE_DEATHS)
			sillycone.gib(DROP_ALL_REMAINS)
			return ..()
		var/obj/machinery/power/apc/emergency_shunt_apc = pick(sillycone.hacked_apcs)
		emergency_shunt_apc.malfoccupy(sillycone) // Get shunted into a random APC (you don't get to choose which)
		return ..()

	if(!forced && !silent)
		to_chat(sillycone, span_notice("Returning to core..."))

	sillycone.forceMove(get_turf(sillycone.linked_core))
	QDEL_NULL(sillycone.linked_core)
	if (forced)
		to_chat(sillycone, span_danger("ZZUZULU.ERR--ERRR-NEUROLOG-- PERCEP--- DIST-B**@"))
		for(var/count in 1 to 5)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(do_sparks), rand(10, 20), FALSE, sillycone), count SECONDS)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(empulse), get_turf(sillycone), 10,  20), 10 SECONDS)
	return ..()

/obj/vehicle/sealed/mecha/container_resist_act(mob/living/user)
	if(isAI(user))
		var/mob/living/silicon/ai/ai_pilot = user
		if(!ai_pilot.linked_core)
			to_chat(ai_pilot, span_userdanger("Inactive core destroyed. Unable to return."))
			if(!ai_pilot.can_shunt || !LAZYLEN(ai_pilot.hacked_apcs))
				to_chat(ai_pilot, span_warning("[ai_pilot.can_shunt ? "No hacked APCs available." : "No shunting capabilities."]"))
				return

			var/confirm = tgui_alert(ai_pilot, "Shunt to a random APC? You won't have anywhere else to go!", "Confirm Emergency Shunt", list("Yes", "No"))
			if(confirm == "Yes")
				/// Mechs with open cockpits can have the pilot shot by projectiles, or EMPs may destroy the AI inside
				/// Alternatively, destroying the mech will shunt the AI if they can shunt, or a deadeye wizard can hit
				/// them with a teleportation bolt
				if (ai_pilot.stat == DEAD || ai_pilot.loc != src)
					return
				mob_exit(ai_pilot, forced = TRUE)
			return

	to_chat(user, span_notice("You begin the ejection procedure. Equipment is disabled during this process. Hold still to finish ejecting."))
	currently_ejecting = TRUE
	if(!do_after(user, exit_delay, target = src))
		to_chat(user, span_notice("You stop exiting the mech. Weapons are enabled again."))
		currently_ejecting = FALSE
		return

	if(cabin_sealed)
		set_cabin_seal(user, FALSE)
	mob_exit(user, silent = TRUE)

/// Installs an MMI or posibrain into our mechs
/obj/vehicle/sealed/mecha/proc/install_mmi(obj/item/mmi/new_pilot, mob/user)
	if (!(mecha_flags & MMI_COMPATIBLE))
		to_chat(user, span_warning("[name] is not compatible with MMIs!"))
		return FALSE

	if (!new_pilot.brain_check(user))
		return FALSE

	if (locate(/mob/living/brain) in occupants)
		to_chat(user, span_warning("[name] already has a COMP unit installed!"))
		return FALSE

	var/mob/living/brain/brain_mob = new_pilot.brainmob
	if(dna_lock && (!brain_mob.stored_dna || brain_mob.stored_dna.unique_enzymes != dna_lock || user.has_dna()?.unique_enzymes != dna_lock))
		to_chat(user, span_warning("Access denied. [name] is secured with a DNA lock."))
		return FALSE

	user.visible_message(span_notice("[user] starts to insert [new_pilot] into [name]."), span_notice("You start inserting [new_pilot] into [name]."))

	if(!do_after(user, 4 SECONDS, target = src))
		return FALSE

	if (locate(/mob/living/brain) in occupants)
		to_chat(user, span_warning("[name] already has a COMP unit installed!"))
		return FALSE

	return mmi_moved_inside(new_pilot, user)

/obj/vehicle/sealed/mecha/proc/mmi_moved_inside(obj/item/mmi/new_pilot, mob/user)
	if(!new_pilot.brain_check(user))
		return FALSE

	if(!user.transferItemToLoc(new_pilot, src))
		to_chat(user, span_warning("[new_pilot] is stuck to your hand, you cannot put it in [src]!"))
		return FALSE

	var/mob/living/brain/brain_mob = new_pilot.brainmob
	new_pilot.set_mecha(src)
	add_occupant(brain_mob) // Note this forcemoves the brain into the mech to allow relaymove
	mecha_flags &= ~PANEL_OPEN // Close panel if open
	brain_mob.reset_perspective(src)
	brain_mob.remote_control = src
	brain_mob.update_mouse_pointer()
	if (!mmi_full_control || istype(new_pilot, /obj/item/mmi/posibrain))
		max_occupants += 1 // Cursed, but required as MMIs count for occupants
	setDir(SOUTH)
	log_message("[new_pilot] moved in as pilot.", LOG_MECHA)
	user.log_message("has put the MMI/posibrain of [key_name(brain_mob)] into [src]", LOG_GAME)
	brain_mob.log_message("was put into [src] by [key_name(user)]", LOG_GAME, log_globally = FALSE)
	return TRUE

/// Returns a list of non-COMP unit drivers
/obj/vehicle/sealed/mecha/proc/noncomp_driver_amount()
	. = 0
	for (var/mob/living/pilot as anything in return_drivers())
		if (!isbrain(pilot))
			. += 1
			continue

		var/mob/living/brain/brain = pilot
		if (mmi_full_control && !istype(brain.container, /obj/item/mmi/posibrain))
			. += 1
