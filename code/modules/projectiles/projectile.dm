/obj/projectile
	name = "projectile"
	icon = 'icons/obj/weapons/guns/projectiles.dmi'
	icon_state = "bullet"
	density = FALSE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	movement_type = FLYING
	wound_bonus = CANT_WOUND
	generic_canpass = FALSE
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	layer = MOB_LAYER
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	animate_movement = NO_STEPS //Use SLIDE_STEPS in conjunction with legacy

	// Firing data
	/// Zone that the projectile was originally aimed at
	var/def_zone
	/// Who fired the projectile
	var/atom/movable/firer
	/// Item/spell/etc that the projectile was shot from
	var/datum/fired_from
	/// Projectile's starting turf
	var/turf/origin_turf
	/// Target at which the projectile was shot
	var/atom/intended_target
	/// Starting positon offsets
	var/origin_x = 16
	var/origin_y = 16
	/// Target position offsets
	var/target_x = 16
	var/target_y = 16
	/// Movement vector for the projectile. Handles trig and current position tracking
	var/datum/point/vector/trajectory
	/// If TRUE, we can hit our firer
	var/ignore_source_check = FALSE

	/// How many pixels this projectile moves per decisecond
	/// This value is inverse from old guncode, which divided delta_time by this value instead of multiplying it
	var/speed = 1.25
	/// Multiplier for distance passed every pixel. Compensates for speed
	/// Increasing this past 1 risks projectiles passing through tiles if fired at an angle
	var/pixel_move_multiplier = 1
	/// Maximum distance that this projectile can travel, in tiles
	var/range = 50
	/// Minimum layer below which objects cannot be automatically hit
	var/hit_threshhold = PROJECTILE_HIT_THRESHOLD_LAYER
	/// Can this projectile hit floor tiles. Defaults to false, else you cannot shoot into the air
	var/can_hit_floors = FALSE
	///If TRUE, hit mobs, even if they are lying on the floor and are not our target within MAX_RANGE_HIT_PRONE_TARGETS tiles
	var/hit_prone_targets = FALSE
	///if TRUE, ignores the range of MAX_RANGE_HIT_PRONE_TARGETS tiles of hit_prone_targets
	var/ignore_range_hit_prone_targets = FALSE

	/// Setting this to TRUE would prevent the projectile from rotating towards the movement vector
	var/nondirectional_sprite = FALSE
	/// If set to TRUE, firing this projectile won't generate a log
	var/disable_firing_log = FALSE
	/// If set to TRUE, no information about this projectile will be logged
	var/disable_logging = FALSE

	// Damage data
	var/damage = 10
	var/damage_type = BRUTE
	/// Defines what armor to use when it hits things.
	var/armor_flag = BULLET
	/// This projectile's armor penetration value.
	/// Positive values use (armor - pen) / (100 - pen) formula, while negative values act as multipliers for existing armor
	var/armour_penetration = 0
	/// Extra stamina damage applied on projectile hit (in addition to the main damage)
	var/stamina = 0

	// Status effects applied on hit
	var/stun = 0 SECONDS
	var/knockdown = 0 SECONDS
	var/paralyze = 0 SECONDS
	var/immobilize = 0 SECONDS
	var/unconscious = 0 SECONDS
	/// Seconds of blurry eyes applied on projectile hit
	var/eyeblur = 0 SECONDS
	/// Drowsiness applied on projectile hit
	var/drowsy = 0 SECONDS
	/// Jittering applied on projectile hit
	var/jitter = 0 SECONDS
	/// Stuttering applied on projectile hit
	var/stutter = 0 SECONDS
	/// Slurring applied on projectile hit
	var/slurring = 0 SECONDS

	// Internal variables
	/// Targets that we have already hit and shouldn't affect again
	var/list/impacted = list()
	/// Keeps track of how many seconds are "in the buffer" after a lag spike if capped by global_pixel_speed
	var/overrun = 0
	/// How many tiles we still have to travel
	var/remaining_range
	/// Signals to initialize on every tile
	var/static/list/projectile_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_ATTACK_HAND = PROC_REF(attempt_parry),
	)
	// Tracked "final" pixel_x and pixel_y for animations to prevent jittering in case of lag spikes
	var/pixel_x_goal = 0
	var/pixel_y_goal = 0
	/// When set to TRUE, next forceMove won't reset our trajectory
	var/prevent_trajectory_reset = FALSE

/obj/projectile/Initialize(mapload)
	. = ..()
	remaining_range = range
	AddElement(/datum/element/connect_loc, projectile_connections)
	pixel_x_goal = pixel_x
	pixel_y_goal = pixel_y

/obj/projectile/Destroy(force)
	if (trajectory)
		QDEL_NULL(trajectory)

	return ..()

/*
 * =================================
 *     Projectile movement code
 * =================================
*/

/// Calls pixel_move a certain amount of times to move the projectile, after which the movement is animated
/// Accounts for lag spikes via delta_time and overrun variable
/obj/projectile/process()
	if (!loc || !trajectory)
		return PROCESS_KILL

	var/delta_time = DELTA_WORLD_TIME(SSprojectiles) + overrun
	var/required_moves = delta_time * speed
	overrun = 0
	if (required_moves > SSprojectiles.global_max_tick_moves)
		overrun = (SSprojectiles.global_max_tick_moves - required_moves) / speed

	required_moves = round(required_moves / (SSprojectiles.global_pixel_speed * pixel_move_multiplier))

	for (var/i in 1 to required_moves)
		pixel_move(pixel_move_multiplier)

		if (QDELETED(src))
			return

	animate_move(required_moves * pixel_move_multiplier)

/obj/projectile/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return TRUE // Bullets don't drift in space

/// Moves projectile by SSprojectiles.global_pixel_speed * pixel_move_multiplier pixels, usually 2, after which is calls after_move
/obj/projectile/proc/pixel_move(trajectory_multiplier = 1)
	trajectory.increment(trajectory_multiplier)

	var/turf/T = trajectory.return_turf()
	if(!istype(T))
		qdel(src)
		return

	if (T == loc)
		after_move()
		return

	if (T.z == loc.z)
		step_towards(src, T)
		after_move()
		return

	prevent_trajectory_reset = TRUE
	forceMove(T)
	pixel_x = trajectory.return_px()
	pixel_y = trajectory.return_py()
	pixel_x_goal = pixel_x
	pixel_y_goal = pixel_y
	after_move(SSprojectiles.global_pixel_speed * pixel_move_multiplier / 32)

/// Animates a single step
/obj/projectile/animate_move(move_multiplier = 1)
	pixel_x = trajectory.return_px() - trajectory.mpx * move_multiplier - (pixel_x_goal - pixel_x)
	pixel_y = trajectory.return_py() - trajectory.mpy * move_multiplier - (pixel_y_goal - pixel_y)
	pixel_x_goal = trajectory.return_px()
	pixel_y_goal = trajectory.return_py()
	animate(src, pixel_x = pixel_x_goal, pixel_y = pixel_y_goal, time = 1, flags = ANIMATION_END_NOW)

/// Handles all range-specific logic and additional logic during movement
/obj/projectile/proc/after_move(distance_passed)
	if (QDELETED(src))
		return

	remaining_range -= distance_passed
	SEND_SIGNAL(src, COMSIG_PROJECTILE_AFTER_MOVE, distance_passed)

	if(remaining_range <= 0 && loc)
		max_range()

/// Called when the projectile reaches its maximum range
/obj/projectile/proc/max_range()
	SEND_SIGNAL(src, COMSIG_PROJECTILE_MAX_RANGE)
	qdel(src)

/obj/projectile/proc/set_pixel_speed(new_speed)
	if(!trajectory)
		return FALSE
	trajectory.set_speed(new_speed)
	return TRUE

/obj/projectile/CanPassThrough(atom/blocker, movement_dir, blocker_opinion)
	return impacted[blocker.weak_reference] || ..()

/obj/projectile/forceMove(atom/destination)
	if (!isloc(destination) || !isloc(loc) || !z)
		return ..()

	. = ..()
	if (QDELETED(src))
		return

	if (trajectory &&! trajectory_ignore_forcemove && isturf(destination))
		trajectory.initialize_location(destination.x, destination.y, destination.z, 0, 0)

/*
 * =================================
 *     Projectile impact code
 * =================================
*/

/obj/projectile/Bump(atom/bumped_atom)
	SEND_SIGNAL(src, COMSIG_MOVABLE_BUMP, bumped_atom)
	if(can_hit_target(bumped_atom, TRUE, TRUE))
		hit_target(bumped_atom)
		return

	// We bumped into an object but failed to hit it (we impacted it already, its invalid, its unhittable, its our firer)
	// In that case, try to hit at least *something* on that turf
	scan_turf(get_turf(bumped_atom))

/// Projectile crossed: When something enters a projectile's tile, make sure the projectile hits it if it should be hitting it.
/obj/projectile/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(can_hit_target(AM))
		hit_target(AM)

/obj/projectile/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	scan_turf(loc)

/// Checks if passed target can be hit
/// ignore_loc will make us ignore target's current position and ignore_density ignores object density and layers
/obj/projectile/proc/can_hit_target(atom/target, ignore_loc = FALSE, ignore_density = FALSE, override_priority = FALSE)
	if(QDELETED(target) || impacted[target.weak_reference])
		return FALSE

	var/direct_target = (target == intended_target) || override_priority

	if(!ignore_loc && loc != target.loc && !(can_hit_floors && direct_target && target != loc))
		return FALSE

	// if pass_flags match, pass through entirely - unless its our intended target
	if((target.pass_flags_self & pass_flags) && !direct_target)
		return FALSE

	if(HAS_TRAIT(target, TRAIT_UNHITTABLE_BY_PROJECTILES))
		return FALSE

	if(!ignore_source_check && firer)
		var/mob/M = firer
		if (target == firer || firer.loc || (target in firer.buckled_mobs) || (istype(M) && (M.buckled == target)))
			return FALSE

	if (ignore_density || target.density)
		return TRUE

	if (!isliving(target))
		if (isturf(target))
			return can_hit_floors || direct_target

		if (target.layer < hit_threshhold)
			return FALSE
		return direct_target

	var/mob/living/victim = target
	if(direct_target)
		return TRUE

	// Projectiles pass through dead, floored, cuffed or immobilized people without collision unless they're the target.
	if(living_target.stat == DEAD)
		return FALSE

	if(HAS_TRAIT(living_target, TRAIT_IMMOBILIZED) && HAS_TRAIT(living_target, TRAIT_FLOORED) && HAS_TRAIT(living_target, TRAIT_HANDS_BLOCKED))
		return FALSE

	if (!hit_prone_targets)
		return living_target.body_position != LYING_DOWN

	if (range - remaining_range <= MAX_RANGE_HIT_PRONE_TARGETS)
		return TRUE

	if (ignore_range_hit_prone_targets)
		return TRUE
	return FALSE

/// Scan a specific turf for potential targets
/obj/projectile/proc/scan_turf(turf/target_turf)
	var/atom/target = find_target(target_turf)
	if (target)
		hit_target(target)

/// Tries to locate the most fitting target on the passed turf
/// Priority as follows: Intended target -> mobs (random) -> objects (random) -> turf
/obj/projectile/proc/find_target(turf/target_turf)

