
/obj/vehicle/sealed/mecha/mob_try_enter(mob/living/new_pilot)
	if(!ishuman(new_pilot)) // no silicons or drones in mechas.
		return

	// No lavalizards or monkeys in mechs
	if(HAS_TRAIT(new_pilot, TRAIT_PRIMITIVE) && !ISADVANCEDTOOLUSER(new_pilot))
		to_chat(new_pilot, span_warning("The knowledge to use this device eludes you!"))
		return

	log_message("[new_pilot] tried to move into [src].", LOG_MECHA)

	if(dna_lock && new_pilot.has_dna())
		var/mob/living/carbon/entering_carbon = new_pilot
		if(entering_carbon.dna.unique_enzymes != dna_lock)
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
	. = ..()
	update_appearance()

/// Proc called whenever a new pilot enters a mech
/obj/vehicle/sealed/mecha/proc/moved_inside(mob/living/new_pilot)
	mecha_flags &= ~PANEL_OPEN //Close panel if open
	add_fingerprint(new_pilot)
	log_message("[new_pilot] moved in as pilot.", LOG_MECHA)
	setDir(SOUTH)
	playsound(src, 'sound/machines/windowdoor.ogg', 50, TRUE)
	set_mouse_pointer()
	SEND_SOUND(new_pilot, sound('sound/vehicles/mecha/nominal.ogg', volume = 50))

/*

///proc called when a new mmi mob tries to enter this mech
/obj/vehicle/sealed/mecha/proc/mmi_move_inside(obj/item/mmi/brain_obj, mob/user)
	if(!(mecha_flags & MMI_COMPATIBLE))
		to_chat(user, span_warning("This mecha is not compatible with MMIs!"))
		return FALSE
	if(!brain_obj.brain_check(user))
		return FALSE
	var/mob/living/brain/brain_mob = brain_obj.brainmob
	if(LAZYLEN(occupants) >= max_occupants)
		to_chat(user, span_warning("It's full!"))
		return FALSE
	if(dna_lock && (!brain_mob.stored_dna || (dna_lock != brain_mob.stored_dna.unique_enzymes)))
		to_chat(user, span_warning("Access denied. [name] is secured with a DNA lock."))
		return FALSE

	visible_message(span_notice("[user] starts to insert an MMI into [name]."))

	if(!do_after(user, 4 SECONDS, target = src))
		to_chat(user, span_notice("You stop inserting the MMI."))
		return FALSE
	if(LAZYLEN(occupants) < max_occupants)
		return mmi_moved_inside(brain_obj, user)
	to_chat(user, span_warning("Maximum occupants exceeded!"))
	return FALSE

///proc called when a new mmi mob enters this mech
/obj/vehicle/sealed/mecha/proc/mmi_moved_inside(obj/item/mmi/brain_obj, mob/user)
	if(!(Adjacent(brain_obj) && Adjacent(user)))
		return FALSE
	if(!brain_obj.brain_check(user))
		return FALSE

	var/mob/living/brain/brain_mob = brain_obj.brainmob
	if(!user.transferItemToLoc(brain_obj, src))
		to_chat(user, span_warning("[brain_obj] is stuck to your hand, you cannot put it in [src]!"))
		return FALSE

	brain_obj.set_mecha(src)
	add_occupant(brain_mob)//Note this forcemoves the brain into the mech to allow relaymove
	mecha_flags &= ~PANEL_OPEN //Close panel if open
	mecha_flags |= SILICON_PILOT
	brain_mob.reset_perspective(src)
	brain_mob.remote_control = src
	brain_mob.update_mouse_pointer()
	setDir(SOUTH)
	log_message("[brain_obj] moved in as pilot.", LOG_MECHA)
	if(!internal_damage)
		SEND_SOUND(brain_obj, sound('sound/vehicles/mecha/nominal.ogg',volume=50))
	user.log_message("has put the MMI/posibrain of [key_name(brain_mob)] into [src]", LOG_GAME)
	brain_mob.log_message("was put into [src] by [key_name(user)]", LOG_GAME, log_globally = FALSE)
	return TRUE

/obj/vehicle/sealed/mecha/mob_exit(mob/M, silent = FALSE, randomstep = FALSE, forced = FALSE)
	var/atom/movable/mob_container
	var/turf/newloc = get_turf(src)
	if(ishuman(M))
		mob_container = M
	else if(isbrain(M))
		var/mob/living/brain/brain = M
		mob_container = brain.container
	else if(isAI(M))
		var/mob/living/silicon/ai/AI = M
		mob_container = AI
		//stop listening to this signal, as the static update is now handled by the eyeobj's setLoc
		AI.eyeobj?.UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
		AI.eyeobj?.forceMove(newloc) //kick the eye out as well
		AI.controlled_equipment = null
		AI.remote_control = null
		if(forced)
			if(!AI.linked_core) //if the victim AI has no core
				if (!AI.can_shunt || !length(AI.hacked_apcs))
					AI.investigate_log("has been gibbed by being forced out of their mech.", INVESTIGATE_DEATHS)
					/// If an AI with no core (and no shunting abilities) gets forced out of their mech
					/// (in a way that isn't handled by the normal handling of their mech being destroyed)
					/// we gib 'em here, too.
					AI.gib(DROP_ALL_REMAINS)
					AI = null
					mecha_flags &= ~SILICON_PILOT
					return ..()
				else
					var/obj/machinery/power/apc/emergency_shunt_apc = pick(AI.hacked_apcs)
					emergency_shunt_apc.malfoccupy(AI) //get shunted into a random APC (you don't get to choose which)
					AI = null
					mecha_flags &= ~SILICON_PILOT
					return ..()
		if(!forced && !silent)
			to_chat(AI, span_notice("Returning to core..."))
		mecha_flags &= ~SILICON_PILOT
		newloc = get_turf(AI.linked_core)
		qdel(AI.linked_core)
		AI.forceMove(newloc)
		if(forced)
			to_chat(AI, span_danger("ZZUZULU.ERR--ERRR-NEUROLOG-- PERCEP--- DIST-B**@"))
			for(var/count in 1 to 5)
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(do_sparks), rand(10, 20), FALSE, AI), count SECONDS)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(empulse), get_turf(AI), /*heavy_range = */10, /*light_range = */20), 10 SECONDS)
		return ..()
	else if(isliving(M))
		mob_container = M
	else
		return ..()
	var/mob/living/ejector = M
	mob_container.forceMove(newloc)//ejecting mob container
	log_message("[mob_container] moved out.", LOG_MECHA)
	SStgui.close_user_uis(M, src)
	if(istype(mob_container, /obj/item/mmi))
		var/obj/item/mmi/mmi = mob_container
		if(mmi.brainmob)
			ejector.forceMove(mmi)
			ejector.reset_perspective()
			remove_occupant(ejector)
		mmi.set_mecha(null)
		mmi.update_appearance()
	setDir(SOUTH)
	return ..()

/obj/vehicle/sealed/mecha/container_resist_act(mob/living/user)
	if(isAI(user))
		var/mob/living/silicon/ai/AI = user
		if(!AI.linked_core)
			to_chat(AI, span_userdanger("Inactive core destroyed. Unable to return."))
			if(!AI.can_shunt || !AI.hacked_apcs.len)
				to_chat(AI, span_warning("[AI.can_shunt ? "No hacked APCs available." : "No shunting capabilities."]"))
				return
			var/confirm = tgui_alert(AI, "Shunt to a random APC? You won't have anywhere else to go!", "Confirm Emergency Shunt", list("Yes", "No"))
			if(confirm == "Yes")
				/// Mechs with open cockpits can have the pilot shot by projectiles, or EMPs may destroy the AI inside
				/// Alternatively, destroying the mech will shunt the AI if they can shunt, or a deadeye wizard can hit
				/// them with a teleportation bolt
				if (AI.stat == DEAD || AI.loc != src)
					return
				mob_exit(AI, forced = TRUE)
			return
	to_chat(user, span_notice("You begin the ejection procedure. Equipment is disabled during this process. Hold still to finish ejecting."))
	is_currently_ejecting = TRUE
	if(do_after(user, has_gravity() ? exit_delay : 0 , target = src))
		to_chat(user, span_notice("You exit the mech."))
		if(cabin_sealed)
			set_cabin_seal(user, FALSE)
		mob_exit(user, silent = TRUE)
	else
		to_chat(user, span_notice("You stop exiting the mech. Weapons are enabled again."))
	is_currently_ejecting = FALSE

/obj/vehicle/sealed/mecha/remove_occupant(mob/driver)
	driver.clear_alert(ALERT_CHARGE)
	driver.clear_alert(ALERT_MECH_DAMAGE)
	if(driver.client)
		driver.client.view_size.resetToDefault()
		zoom_mode = FALSE
*/
