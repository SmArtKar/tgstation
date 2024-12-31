/// Sets the direction of the mecha and all of its occcupents, required for FOV.
/obj/vehicle/sealed/mecha/setDir(newdir)
	. = ..()
	for(var/mob/living/occupant as anything in occupants)
		occupant.setDir(newdir)

///Called when the driver turns with the movement lock key
/obj/vehicle/sealed/mecha/proc/on_turn(mob/living/driver, direction)
	SIGNAL_HANDLER
	return COMSIG_IGNORE_MOVEMENT_LOCK

/obj/vehicle/sealed/mecha/relaymove(mob/living/user, direction)
	. = TRUE
	if(!canmove || HAS_TRAIT(src, TRAIT_MECHA_MOVEMENT_DISABLED) || !(user in return_drivers()))
		return
	if (!vehicle_move(direction))
		return
	SEND_SIGNAL(user, COMSIG_MOB_DROVE_MECH, src)

/obj/vehicle/sealed/mecha/Bump(atom/obstacle)
	. = ..()
	if(.) //mech was thrown/door/whatever
		return

	// Whether or not we're on our mecha melee cooldown
	var/on_cooldown = TIMER_COOLDOWN_RUNNING(src, COOLDOWN_MECHA_MELEE_ATTACK)

	// Try smashing through whatever is blocking us if we can
	if((mecha_flags & BUMP_SMASH) && !on_cooldown)
		// Our pilot for this evening
		var/list/mobster = return_controllers_with_flag(VEHICLE_CONTROL_MELEE)
		if(obstacle.mech_melee_attack(src, mobster[1]))
			TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MELEE_ATTACK, melee_cooldown)

		// If obstacle got destroyed, or we can pass it now
		if(QDELETED(obstacle) || obstacle.CanPass(src, get_dir(obstacle, src) || dir))
			if (step(src, dir))
				return

	if (ismovable(obstacle))
		var/atom/movable/movable_obstacle = obstacle
		if(!movable_obstacle.anchored && movable_obstacle.move_resist <= move_force)
			if (step(obstacle, dir))
				step(src, dir)

/obj/vehicle/sealed/mecha/vehicle_move(direction)
	if(!COOLDOWN_FINISHED(src, cooldown_vehicle_move))
		return FALSE

	COOLDOWN_START(src, cooldown_vehicle_move, movedelay)
	if(!direction)
		return FALSE

	if(ismovable(loc)) // Mech is inside an object, tell it we moved
		var/atom/loc_atom = loc
		return loc_atom.relaymove(src, direction)

	if(!Process_Spacemove(direction))
		return FALSE

	var/list/missing_parts = list()
	if(isnull(cell))
		missing_parts += "power cell"

	if(isnull(capacitor))
		missing_parts += "capacitor"

	if(isnull(servo))
		missing_parts += "servo"

	if(length(missing_parts))
		if(TIMER_COOLDOWN_FINISHED(src, COOLDOWN_MECHA_MESSAGE))
			to_chat(occupants, "[icon2html(src, occupants)][span_warning("Missing [english_list(missing_parts)].")]")
			TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MESSAGE, 2 SECONDS)
		return FALSE

	if(!use_energy(step_energy_drain))
		if(TIMER_COOLDOWN_FINISHED(src, COOLDOWN_MECHA_MESSAGE))
			to_chat(occupants, "[icon2html(src, occupants)][span_warning("Insufficient power to move!")]")
			TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MESSAGE, 2 SECONDS)
		return FALSE

	var/signal_result = SEND_SIGNAL(src, COMSIG_MECHA_TRY_MOVE, direction)
	if (signal_result & COMPONENT_CANCEL_MECHA_MOVE)
		return
	if (signal_result & COMPONENT_RANDOMIZE_MECHA_MOVE)
		direction = pick(GLOB.cardinals)

	var/old_dir = dir
	if (ISDIAGONALDIR(direction) && !(mecha_flags & CAN_MOVE_DIAGONALLY))
		return TRUE

	var/keyheld = FALSE
	if(strafing)
		for(var/mob/driver as anything in return_drivers())
			if(driver.client?.keys_held["Alt"])
				keyheld = TRUE
				break

	if (dir != direction && (!strafing || keyheld))
		setDir(direction)
		if (turn_sound)
			playsound(src, turn_sound, 40, TRUE)
		// Mechs with rapid turns can turn and move in a single action
		if (keyheld || !(mecha_flags & RAPID_TURNING))
			return TRUE

	set_glide_size(DELAY_TO_GLIDE_SIZE(movedelay))
	. = try_step_multiz(direction)
	// If we're strafing, turn back to where we were facing
	if(strafing)
		setDir(old_dir)

// Do whatever you do to mobs to these fuckers too
/obj/vehicle/sealed/mecha/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	. = ..()
	if(.)
		return TRUE

	if(. || HAS_TRAIT(src, TRAIT_SPACEWALK))
		return TRUE

	if(movement_type & FLYING || HAS_TRAIT(src, TRAIT_FREE_FLOAT_MOVEMENT))
		return TRUE

	if (HAS_TRAIT(src, TRAIT_NOGRAV_ALWAYS_DRIFT))
		return FALSE

	var/atom/movable/backup = get_spacemove_backup(movement_dir, continuous_move)
	if(!backup)
		return FALSE

	if (drift_handler?.attempt_halt(movement_dir, continuous_move, backup))
		return FALSE

	if(continuous_move || !istype(backup) || !movement_dir || backup.anchored)
		return TRUE

	// last pushoff exists for one reason
	// to ensure pushing a mob doesn't just lead to it considering us as backup, and failing
	last_pushoff = world.time
	if(backup.newtonian_move(dir2angle(REVERSE_DIR(movement_dir)), instant = TRUE)) //You're pushing off something movable, so it moves
		// We set it down here so future calls to Process_Spacemove by the same pair in the same tick don't lead to fucky
		backup.last_pushoff = world.time
		to_chat(src, "[icon2html(src, occupants)][span_info("[src] pushes off of [backup] to propel itself.")]")

/*

///Collects ore when we move, if there is an orebox and it is functional
/obj/vehicle/sealed/mecha/proc/collect_ore()
	if(isnull(ore_box) || !HAS_TRAIT(src, TRAIT_OREBOX_FUNCTIONAL))
		return
	for(var/obj/item/stack/ore/ore in range(1, src))
		//we can reach it and it's in front of us? grab it!
		if(ore.Adjacent(src) && ((get_dir(src, ore) & dir) || ore.loc == loc))
			ore.forceMove(ore_box)
	for(var/obj/item/boulder/boulder in range(1, src))
		//As above, but for boulders
		if(boulder.Adjacent(src) && ((get_dir(src, boulder) & dir) || boulder.loc == loc))
			boulder.forceMove(ore_box)


//Following procs are camera static update related and are basically ripped off of code\modules\mob\living\silicon\silicon_movement.dm

//We only call a camera static update if we have successfully moved and have a camera installed
/obj/vehicle/sealed/mecha/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(chassis_camera)
		update_camera_location(old_loc)

/obj/vehicle/sealed/mecha/proc/update_camera_location(oldLoc)
	oldLoc = get_turf(oldLoc)
	if(!updating && oldLoc != get_turf(src))
		updating = TRUE
		do_camera_update(oldLoc)

///The static update delay on movement of the camera in a mech we use
#define MECH_CAMERA_BUFFER 0.5 SECONDS

/**
 * The actual update - also passes our unique update buffer. This makes our static update faster than stationary cameras,
 * helping us to avoid running out of the camera's FoV. An EMPd mecha with a lowered view_range on its camera can still
 * sometimes run out into static before updating, however.
*/
/obj/vehicle/sealed/mecha/proc/do_camera_update(oldLoc)
	if(oldLoc != get_turf(src))
		GLOB.cameranet.updatePortableCamera(chassis_camera, MECH_CAMERA_BUFFER)
	updating = FALSE
#undef MECH_CAMERA_BUFFER
*/
