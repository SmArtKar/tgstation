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
	var/def_zone = BODY_ZONE_CHEST
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
	/// Target position offsets (click target)
	var/target_x = 16
	var/target_y = 16
	/// If TRUE, we can hit our firer
	var/ignore_source_check = FALSE
	/// If this projectile has been fired yet. Ensures that dead-in-the-water projectiles aren't kept alive due to piercing shenanigans
	var/fired = FALSE
	/// Mobs from these factions will be ignored by the projectile
	var/list/ignored_factions

	/// How many pixels this projectile moves per decisecond
	/// This value is inverse from old guncode, which divided delta_time by this value instead of multiplying it
	var/speed = 1.25
	/// Maximum distance that this projectile can travel, in tiles
	var/range = 50
	/// Minimum layer below which objects cannot be automatically hit
	var/hit_threshhold = PROJECTILE_HIT_THRESHOLD_LAYER
	/// Can this projectile hit floor tiles. Defaults to false, else you cannot shoot into the air
	var/can_hit_floors = FALSE
	/// If TRUE, hit mobs, even if they are lying on the floor and are not our target within MAX_RANGE_HIT_PRONE_TARGETS tiles
	var/hit_prone_targets = FALSE
	/// If TRUE, ignores the range of MAX_RANGE_HIT_PRONE_TARGETS tiles of hit_prone_targets
	var/ignore_range_hit_prone_targets = FALSE
	/// Random projectile spread, in degrees
	var/spread = 0
	/// If this projectile can be reflected
	var/reflectable = FALSE

	/// Setting this to TRUE would prevent the projectile from rotating towards the movement vector
	var/nondirectional_sprite = FALSE
	/// If set to TRUE, firing this projectile won't generate a log
	var/disable_firing_log = FALSE
	/// If set to TRUE, no information about this projectile will be logged
	var/disable_logging = FALSE

	// VFX and sounds
	/// Sound that is played upon impacting an object
	var/hitsound = 'sound/weapons/pierce.ogg'
	/// Sound that is played upon impacting a turf
	var/hitsound_turf = null
	/// Type of hit effect spawned upon impact
	var/impact_effect_type
	/// Suppression status
	/// SUPPRESSED_NONE doesn't do anything, SUPPRESSED_QUIET lowers the volume, SUPPRESSED_VERY removes the hit message
	var/suppressed = SUPPRESSED_NONE

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
	/// For what kind of brute wounds we're rolling for, if we're doing such a thing. Lasers obviously don't care since they do burn instead.
	var/sharpness = NONE
	/// The higher the number, the greater the bonus to dismembering. 0 will not dismember at all.
	var/dismemberment = 0
	/// If TRUE, this projectile deals its damage to the chest if it dismembers a limb.
	var/catastropic_dismemberment = FALSE

	//Homing data
	/// Whenever this projectile should home on its target
	var/homing = FALSE
	/// Target to home onto
	var/atom/homing_target
	/// Maximum angle which projectile can turn per tick
	var/homing_turn_speed = 10
	/// Minimal innacuracy for homing, for a more natural offset
	var/homing_inaccuracy_min = 0
	/// Maximal innacuracy for homing
	var/homing_inaccuracy_max = 0

	// Hitscan data
	/// If this projectile is hitscan. Speed will be ignored and hits will be registered instantly upon firing
	/// Should not be enabled with homing. Should not work with homing. Will produce funny results with homing.
	var/hitscan = FALSE
	/// VFX for hitscans
	var/tracer_type
	var/muzzle_type
	var/impact_type

	// Hitscan VFX info
	var/tracer_icon
	var/tracer_icon_state
	var/hitscan_light_intensity = 1.5
	var/hitscan_light_range = 0.75
	var/hitscan_light_color_override
	var/muzzle_flash_intensity = 3
	var/muzzle_flash_range = 1.5
	var/muzzle_flash_color_override
	var/impact_light_intensity = 3
	var/impact_light_range = 2
	var/impact_light_color_override
	var/tracer_duration = 3
	var/animate_tracers = TRUE

	// Piercing data
	/// If FALSE, allow us to hit something directly targeted/clicked/whatnot even if we're able to phase through it
	var/phasing_ignore_direct_target = FALSE
	/// Bitflag for things the projectile should just phase through entirely - No hitting unless direct target and [phasing_ignore_direct_target] is FALSE. Uses pass_flags flags.
	var/projectile_phasing = NONE
	/// Bitflag for things the projectile should hit, but pierce through without deleting itself. Defers to projectile_phasing. Uses pass_flags flags.
	var/projectile_piercing = NONE

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
	/// If this projectile has already been parried
	var/parried = FALSE
	/// Signals to initialize on every tile
	var/static/list/projectile_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_ATTACK_HAND = PROC_REF(attempt_parry),
	)

	/// Current fire angle, in case factors need recalculation
	/// Since its BYOND, north is 0 instead of 90
	var/angle = 0
	/// Factors for x and y movement to cut down on trig calculations
	var/x_factor = 0
	var/y_factor = 1
	/// Stored offsets for homing inaccuracy for visuals
	var/homing_offset_x = 0
	var/homing_offset_y = 0
	/// When set to true, PHASING will be removed the next time Moved is called
	/// Used to phase through object upon piercing them
	var/pierce_phase = FALSE
	/// Turf we were on before last move_distance
	var/turf/last_turf
	/// pixel_x before last move_distance call
	var/old_x = 0
	/// pixel_y before last move_distance call
	var/old_y = 0

	///If we have a shrapnel_type defined, these embedding stats will be passed to the spawned shrapnel type, which will roll for embedding on the target
	var/embed_type
	///Saves embedding data
	var/datum/embed_data/embed_data

/obj/projectile/Initialize(mapload)
	. = ..()
	remaining_range = range
	if(get_embed())
		AddElement(/datum/element/embed)
	AddElement(/datum/element/connect_loc, projectile_connections)
	RegisterSignal(src, COMSIG_ATOM_ATTACK_HAND, PROC_REF(attempt_parry))

/obj/projectile/Destroy(force)
	. = ..()
	UnregisterSignal(src, COMSIG_ATOM_ATTACK_HAND)

/*
 * =================================
 *     Projectile movement code
 * =================================
*/

/obj/projectile/process()
	if (!loc || !isturf(loc) || !fired)
		fired = FALSE
		return PROCESS_KILL

	// Overrun compensates for lag spikes large enough for more than 10 tiles of movement to get piled up
	var/delta_time = DELTA_WORLD_TIME(SSprojectiles) + overrun
	overrun = 0
	var/required_moves = delta_time * speed
	if (required_moves > MAX_TILES_PER_TICK)
		overrun = (MAX_TILES_PER_TICK - required_moves) / speed

	move_distance(required_moves)

/// Moves projectile a certain amount of tiles
/obj/projectile/proc/move_distance(distance)
	var/limit_distance = min(distance, remaining_range)
	remaining_range -= limit_distance
	last_turf = get_turf(src)
	var/x_pos = pixel_x
	var/y_pos = pixel_y
	old_x = pixel_x
	old_y = pixel_y

	while (limit_distance > 0)
		// Last move impacted something and deleted us
		if (QDELETED(src))
			return

		// How much movement has to be spent to move to a next tile in X/Y axis
		var/x_tile_move = (x_factor > 0 ? 32 - x_pos : x_pos) / abs(x_factor)
		var/y_tile_move = (y_factor > 0 ? 32 - y_pos : y_pos) / abs(y_factor)

		var/dist_moved = min(x_tile_move, y_tile_move)

		if (dist_moved > limit_distance)
			dist_moved = limit_distance

		limit_distance -= dist_moved
		x_pos = (x_pos + dist_moved * x_factor) % 32
		y_pos = (y_pos + dist_moved * y_factor) % 32

		var/turf/T = null
		if (x_tile_move == y_tile_move) //Perfectly diagonal
			T = locate(loc.x + SIGN(x_factor), loc.y + SIGN(y_factor), loc.z)
		else if (x_tile_move < y_tile_move) // Move on X axis first
			T = locate(loc.x + SIGN(x_factor), loc.y, loc.z)
		else
			T = locate(loc.x, loc.y + SIGN(y_factor), loc.z)

		if (!istype(T))
			qdel(src)
			return

		if (homing)
			process_homing(homing_turn_speed * dist_moved / distance)

		if (T.z == loc.z)
			step_towards(src, T)
			after_move()
			continue

		forceMove(T)
		after_move()

	if (QDELETED(src))
		return

	if (remaining_range <= 0)
		max_range()
		return

	var/current_x = pixel_x
	var/current_y = pixel_y
	pixel_x += (last_turf.x - loc.x) * 32 + old_x
	pixel_y += (last_turf.y - loc.y) * 32 + old_y
	animate(src, pixel_x = current_x, pixel_y = current_y, time = 1, flags = ANIMATION_END_NOW)
	return

/obj/projectile/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return TRUE // Bullets don't drift in space

/// Called when the projectile reaches its maximum range
/obj/projectile/proc/max_range()
	SEND_SIGNAL(src, COMSIG_PROJECTILE_MAX_RANGE)
	if (hitscan)
		generate_tracer(origin_turf, get_turf(src), origin_x, origin_y, pixel_x, pixel_y)
	qdel(src)

/obj/projectile/CanPassThrough(atom/blocker, movement_dir, blocker_opinion)
	return (blocker.weak_reference in impacted) || ..()

/// Handles additional logic during movement
/obj/projectile/proc/after_move(distance_passed)
	if (QDELETED(src))
		return

	SEND_SIGNAL(src, COMSIG_PROJECTILE_AFTER_MOVE, distance_passed)

/obj/projectile/proc/process_homing(max_angle)
	if (!homing_target)
		return

	var/datum/point/PT = RETURN_PRECISE_POINT(homing_target)
	PT.x = clamp(PT.x + homing_offset_x, 1, world.maxx)
	PT.y = clamp(PT.y + homing_offset_y, 1, world.maxy)
	var/angle_diff = closer_angle_difference(angle, angle_between_points(RETURN_PRECISE_POINT(src), PT))
	set_angle(angle + clamp(angle_diff, -max_angle, max_angle))

/*
 * =================================
 *     Projectile impact code
 * =================================
*/

/obj/projectile/Bump(atom/bumped_atom)
	SEND_SIGNAL(src, COMSIG_MOVABLE_BUMP, bumped_atom)
	if(can_hit_target(bumped_atom, TRUE, TRUE))
		process_impact(bumped_atom)
		return

	// We bumped into an object but failed to hit it (we impacted it already, its invalid, its unhittable, its our firer)
	// In that case, try to hit at least *something* on that turf
	scan_turf(get_turf(bumped_atom))

/// Projectile crossed: When something enters a projectile's tile, make sure the projectile hits it if it should be hitting it.
/obj/projectile/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(can_hit_target(AM))
		process_impact(AM)

/obj/projectile/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(pierce_phase)
		pierce_phase = FALSE
		movement_type &= ~PHASING

	scan_turf(loc)

/// Checks if passed target can be hit
/// ignore_loc will make us ignore target's current position and ignore_density ignores object density and layers
/// override_priority will make anything passed count as the intended target
/obj/projectile/proc/can_hit_target(atom/target, ignore_loc = FALSE, ignore_density = FALSE, override_priority = FALSE)
	if(QDELETED(target) || (target.weak_reference in impacted))
		return FALSE

	var/direct_target = (target == intended_target) || override_priority

	if(!ignore_loc && loc != target.loc && !(can_hit_floors && direct_target && target != loc))
		return FALSE

	// if pass_flags match, pass through entirely - unless its our intended target
	if((target.pass_flags_self & pass_flags) && !direct_target)
		return FALSE

	if(HAS_TRAIT(target, TRAIT_UNHITTABLE_BY_PROJECTILES))
		return FALSE

	if(!ignore_source_check && ismob(firer))
		var/mob/M = firer
		if (target == firer || firer.loc || (target in firer.buckled_mobs) || (istype(M) && (M.buckled == target)))
			return FALSE

	if(ignored_factions?.len && !direct_target && ismob(target))
		var/mob/target_mob = target
		if(faction_check(target_mob.faction, ignored_factions))
			return FALSE

	if (ignore_density || target.density)
		return TRUE

	if (!isliving(target))
		if (isturf(target))
			return can_hit_floors && direct_target

		if (target.layer < hit_threshhold)
			return FALSE
		return direct_target

	var/mob/living/victim = target
	if(direct_target)
		return TRUE

	// Projectiles pass through dead, floored, cuffed or immobilized people without collision unless they're the target.
	if(victim.stat == DEAD)
		return FALSE

	if(HAS_TRAIT(victim, TRAIT_IMMOBILIZED) && HAS_TRAIT(victim, TRAIT_FLOORED) && HAS_TRAIT(victim, TRAIT_HANDS_BLOCKED))
		return FALSE

	if (!hit_prone_targets)
		return victim.body_position != LYING_DOWN

	if (range - remaining_range <= MAX_RANGE_HIT_PRONE_TARGETS)
		return TRUE

	if (ignore_range_hit_prone_targets)
		return TRUE
	return FALSE

/// Scan a specific turf for potential targets
/obj/projectile/proc/scan_turf(turf/target_turf)
	var/atom/target = find_target(target_turf)
	if (target)
		process_impact(target)

/// Tries to locate the most fitting target on the passed turf
/// Priority as follows: Intended target -> mobs (random) -> objects (random) -> turf
/obj/projectile/proc/find_target(turf/target_turf)
	if(can_hit_target(intended_target, TRUE, FALSE))
		return intended_target

	var/list/atom/potential_targets = list()
	for (var/mob/living/victim in target_turf)
		if (can_hit_target(victim, TRUE, FALSE))
			potential_targets += victim

	if (length(potential_targets))
		return pick(potential_targets)

	for (var/atom/dense in target_turf)
		if (can_hit_target(dense, TRUE, FALSE))
			potential_targets += dense

	if (length(potential_targets))
		return pick(potential_targets)

	if (can_hit_target(target_turf, TRUE, FALSE))
		return target_turf

	return null

/// Call signals for ricochets and similar comps, randomise zone, call actual damage proc.
/// Unlike the latter should only be called on actual impacts
/obj/projectile/proc/process_impact(atom/target)
	if (SEND_SIGNAL(src, COMSIG_PROJECTILE_SELF_IMPACT, target) & PROJECTILE_INTERRUPT_IMPACT)
		return

	if(!HAS_TRAIT(src, TRAIT_ALWAYS_HIT_ZONE))
		def_zone = ran_zone(def_zone, max(100 - 7 * (range - remaining_range), 5))

	var/turf/target_turf = get_turf(target)
	// This loop exists in case our target is pierced through, in which case we need to locate another one on the same tile.
	while (target && !(target.weak_reference in impacted))
		impacted += WEAKREF(target)

		// Some objects like vehicles can redirect bullets to their drivers, so we fetch a possible replacement from them
		// By default this should return src on most atoms
		var/to_hit = target.get_bullet_target(src)
		var/hit_result = process_hit(to_hit)
		// Check if we pierced through the target and in that case, assign a new one
		// qdel check is there in case one of our subtypes tries something funky
		if (hit_result != PROJECTILE_PROCESS_HIT_PIERCE || QDELETED(src))
			break

		target = find_target(target_turf)

/// Actual hit code
/// Should not be called directly, or else weird stuff like stuck floating projectiles or multihits may happen
/obj/projectile/proc/process_hit(atom/target)
	if (QDELETED(src) || !istype(target))
		return PROJECTILE_PROCESS_HIT_FAILURE

	var/pierce_mode = prehit_pierce(target)
	if(pierce_mode == PROJECTILE_DELETE_WITHOUT_HITTING)
		if (hitscan)
			generate_tracer(origin_turf, get_turf(src), origin_x, origin_y, pixel_x, pixel_y)
		qdel(src)
		return PROJECTILE_PROCESS_HIT_FAILURE

	if(pierce_mode == PROJECTILE_PIERCE_PHASE)
		if(!(movement_type & PHASING))
			pierce_phase = TRUE
			movement_type |= PHASING
		return PROJECTILE_PROCESS_HIT_PIERCE

	/// Pierce checks passed, check if the target is okay with being hit
	if (SEND_SIGNAL(target, COMSIG_PROJECTILE_PREHIT, args, src) & PROJECTILE_INTERRUPT_HIT)
		qdel(src)
		return PROJECTILE_PROCESS_HIT_FAILURE

	var/result = target.bullet_act(src, def_zone)

	if (result == BULLET_ACT_BLOCK)
		if (pierce_mode == PROJECTILE_PIERCE_NONE)
			if (hitscan)
				generate_tracer(origin_turf, get_turf(src), origin_x, origin_y, pixel_x, pixel_y)
			qdel(src)
		return PROJECTILE_PROCESS_HIT_BLOCKED

	if (QDELETED(target))
		return PROJECTILE_PROCESS_HIT_SUCCESS

	on_hit(target, pierce_mode == PROJECTILE_PIERCE_HIT)
	if (pierce_mode == PROJECTILE_PIERCE_NONE)
		if (hitscan)
			generate_tracer(origin_turf, get_turf(src), origin_x, origin_y, pixel_x, pixel_y)
		qdel(src)
		return PROJECTILE_PROCESS_HIT_SUCCESS

	if(!(movement_type & PHASING))
		pierce_phase = TRUE
		movement_type |= PHASING

	return PROJECTILE_PROCESS_HIT_PIERCE

/// Compares pass flags to pick a pierce mode
/// PROJECTILE_PIERCE_HIT means that object will be hit and we will go through, while PROJECTILE_PIERCE_PHASE means we ignore it entirely
/obj/projectile/proc/prehit_pierce(atom/target)
	if((projectile_phasing & target.pass_flags_self) && (phasing_ignore_direct_target || intended_target != target))
		return PROJECTILE_PIERCE_PHASE

	if(projectile_piercing & target.pass_flags_self)
		return PROJECTILE_PIERCE_HIT

	var/atom/movable/movable_target = target
	if(istype(movable_target) && movable_target.throwing)
		return (projectile_phasing & LETPASSTHROW) ? PROJECTILE_PIERCE_PHASE : ((projectile_piercing & LETPASSTHROW)? PROJECTILE_PIERCE_HIT : PROJECTILE_PIERCE_NONE)

	return PROJECTILE_PIERCE_NONE

/// Mostly for component code and special effects from child projectiles
/// All damage and effect code should be handled in hit atoms' bullet_act and not here
/obj/projectile/proc/on_hit(atom/target, blocked = 0, pierce_hit = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	var/hit_limb_zone
	if(isliving(target))
		var/mob/living/L = target
		hit_limb_zone = L.check_hit_limb_zone_name(def_zone)

	// Base projectile only sends comsigs
	if(fired_from)
		SEND_SIGNAL(fired_from, COMSIG_PROJECTILE_ON_HIT, firer, target, angle, hit_limb_zone, blocked)
	SEND_SIGNAL(src, COMSIG_PROJECTILE_SELF_ON_HIT, firer, target, angle, hit_limb_zone, blocked)

	// And does VFX and SFX
	var/hit_x = target.pixel_x
	var/hit_y = target.pixel_y
	if (target == intended_target)
		hit_x += target_x - 16
		hit_y += target_y - 16
	else
		hit_x += rand(-8, 8)
		hit_y += rand(-8, 8)

	if (impact_effect_type)
		new impact_effect_type(get_turf(target), hit_x, hit_y)

	if (isturf(target) && hitsound_turf)
		playsound(loc, hitsound_turf, impact_volume(), TRUE, -1)
		return

	if (hitsound)
		playsound(loc, hitsound, impact_volume(), TRUE, -1)

/// Creates a tracer made from a muzzle flash, a beam and an impact light between two points
/obj/projectile/proc/generate_tracer(turf/starting_point, turf/end_point, start_x, start_y, end_x, end_y)
	// Creates, lights up and animates the tracer beam
	if (tracer_type)
		var/datum/beam/tracer = starting_point.Beam(end_point, tracer_icon_state, tracer_icon, tracer_duration, beam_type = tracer_type, emissive = TRUE, \
		override_origin_pixel_x = start_x, override_origin_pixel_y = start_y, override_target_pixel_x = end_x, override_target_pixel_y = end_y, layer = layer)
		tracer.visuals.set_light(hitscan_light_range, hitscan_light_intensity, hitscan_light_color_override || color)
		tracer.visuals.alpha = 0
		tracer.visuals.color = color
		if (isnull(tracer_icon_state))
			tracer.visuals.icon_state = initial(tracer.visuals.icon_state)
		if (isnull(tracer_icon))
			tracer.visuals.icon = initial(tracer.visuals.icon)
		tracer.visuals.update_appearance()
		animate(tracer.visuals, alpha = alpha, time = tracer_duration * 0.1)
		animate(tracer.visuals, alpha = alpha, time = tracer_duration * 0.6)
		animate(tracer.visuals, alpha = 0, time = tracer_duration * 0.3)

	// Generates muzzle flash
	if (muzzle_type)
		var/atom/movable/muzzle = new muzzle_type(starting_point)
		var/matrix/muzzle_matrix = matrix()
		muzzle_matrix.Turn(angle)
		muzzle.transform = muzzle_matrix
		muzzle.pixel_x = start_x
		muzzle.pixel_y = start_y
		muzzle.set_light(muzzle_flash_range, muzzle_flash_intensity, muzzle_flash_color_override || color)
		muzzle.alpha = 0
		muzzle.color = color
		animate(muzzle, alpha = alpha, time = tracer_duration * 0.1)
		animate(muzzle, alpha = alpha, time = tracer_duration * 0.6)
		animate(muzzle, alpha = 0, time = tracer_duration * 0.3)
		QDEL_IN(muzzle, tracer_duration)

	// Generates impact VFX
	if (impact_type)
		var/atom/movable/impact = new impact_type(end_point)
		var/matrix/impact_matrix = matrix()
		impact_matrix.Turn(angle)
		impact.transform = impact_matrix
		impact.pixel_x = end_x
		impact.pixel_y = end_y
		impact.set_light(impact_light_range, impact_light_intensity, impact_light_color_override || color)
		impact.alpha = 0
		impact.color = color
		animate(impact, alpha = alpha, time = tracer_duration * 0.1)
		animate(impact, alpha = alpha, time = tracer_duration * 0.1)
		animate(impact, alpha = alpha, time = tracer_duration * 0.6)
		animate(impact, alpha = 0, time = tracer_duration * 0.3)
		QDEL_IN(impact, tracer_duration)

/*
 * =================================
 *     Projectile firing code
 * =================================
*/

/// Sets the projectile angle, rotates the sprite and adjusts movement factors to correct values
/obj/projectile/proc/set_angle(new_angle)
	if(!nondirectional_sprite)
		transform = transform.TurnTo(angle, new_angle)

	angle = new_angle
	// BYOND angles are weird, north is 0 instead of 90 so we swap trig around
	x_factor = sin(angle)
	y_factor = cos(angle)

/**
 * Aims the projectile at a target.
 *
 * Must be passed at least one of a target or a list of click parameters.
 * If only passed the click modifiers the source atom must be a mob with a client.
 * Optional to call - fire() can assign all important variables by itself, this is mostly for offsets/origin information
 *
 * Arguments:
 * - [target][/atom]: (Optional) The thing that the projectile will be aimed at.
 * - [source][/atom]: The initial location of the projectile or the thing firing it.
 * - [modifiers][/list]: (Optional) A list of click parameters to apply to this operation.
 * - deviation: (Optional) How the trajectory should deviate from the target in degrees.
 */
/obj/projectile/proc/aim_projectile(atom/target, atom/source, list/modifiers = null, deviation = 0)
	if(!(isnull(modifiers) || islist(modifiers)))
		stack_trace("WARNING: Projectile [type] fired with non-list modifiers, likely was passed click params.")
		modifiers = null

	var/turf/target_turf = get_turf(target)
	origin_turf = source ? get_turf(source) : get_turf(src)

	if(isnull(origin_turf))
		stack_trace("WARNING: Projectile [type] fired from nullspace.")
		qdel(src)
		return FALSE

	// Move ourselves to the starting turf and assign visual position
	forceMove(origin_turf)
	if (!isnull(source))
		pixel_x = source.pixel_x
		pixel_y = source.pixel_y
		origin_x = source.pixel_x
		origin_y = source.pixel_y

	// We've been fired from a client which provided us with detailed target coordinates from a click
	if(length(modifiers))
		var/list/calculated = calculate_projectile_angle_and_pixel_offsets(source, target_turf && target, modifiers)
		target_x = calculated[2]
		target_y = calculated[3]
		set_angle(calculated[1] + deviation)
		return TRUE

	// We probably have been fired by a clientless mob or a turret with only a target in mind
	if(target_turf)
		set_angle(get_angle(src, target_turf) + deviation)
		return TRUE

	// If neither are supplied, error
	stack_trace("WARNING: Projectile [type] fired without a target or mouse parameters to aim with.")
	qdel(src)
	return FALSE

/obj/projectile/proc/set_homing_target(atom/home_target)
	if(!home_target || (!isturf(home_target) && !isturf(home_target.loc)))
		return FALSE
	homing = TRUE
	homing_target = home_target
	homing_offset_x = rand(homing_inaccuracy_min, homing_inaccuracy_max)
	homing_offset_y = rand(homing_inaccuracy_min, homing_inaccuracy_max)
	if(prob(50))
		homing_offset_x = -homing_offset_x
	if(prob(50))
		homing_offset_y = -homing_offset_y

/obj/projectile/proc/fire(atom/direct_target, start_angle)
	LAZYINITLIST(impacted)

	if(fired_from)
		SEND_SIGNAL(fired_from, COMSIG_PROJECTILE_BEFORE_FIRE, src, intended_target)
	if(firer)
		SEND_SIGNAL(firer, COMSIG_PROJECTILE_FIRER_BEFORE_FIRE, src, fired_from, intended_target)

	if(firer && intended_target && !(disable_firing_log || disable_logging))
		//note: mecha projectile logging is handled in /obj/item/mecha_parts/mecha_equipment/weapon/action(). try to keep these messages roughly the sameish just for consistency's sake.
		log_combat(firer, intended_target, "fired at", src, "from [get_area_name(src, TRUE)]")

	intended_target = direct_target

	// Point blank shots are handled as instant hits.
	if (direct_target && get_dist(direct_target, get_turf(src)) <= 1)
		process_impact(direct_target)
		if(QDELETED(src))
			return

	// If we are inside of something, also impact it instantly
	if (!isturf(loc))
		process_impact(loc)
		if(QDELETED(src))
			return

	if(isnum(start_angle))
		set_angle(start_angle)
	if(spread)
		set_angle(angle + ((rand() - 0.5) * spread))

	origin_turf = get_turf(src)
	if(!nondirectional_sprite)
		transform = transform.Turn(angle)

	forceMove(origin_turf)
	fired = TRUE
	play_fov_effect(origin_turf, 6, "gunfire", dir = NORTH, angle = angle)
	SEND_SIGNAL(src, COMSIG_PROJECTILE_FIRE)

	if(hitscan)
		process_hitscan()
		return // Hitscans always should be qdeleted at some point in process_hitscan(), be it due to range or other reasons

	if(!(datum_flags & DF_ISPROCESSING))
		START_PROCESSING(SSprojectiles, src)

/// Runs projectile's hitscan chain. Should handle all movement, hits, VFX and deletion at the end because hitscans should not exist longer than their fire call.
/obj/projectile/proc/process_hitscan()
	move_distance(range)

	if (!QDELETED(src))
		qdel(src)

/**
 * Fire a projectile directed at another atom
 *
 * Arguments:
 * - projectile_type: Projectile type to create and fire
 * - target: Atom at which we're aiming
 * - sound: Sound that is played upon firing
 * - firer (Optional): Atom that is firing the projectile. If not supplied, will default to this atom. Affects logging and initial pixel offsets
 * - ignore_targets (Optional): List of atoms that will be marked as already have been impacted
 */

/atom/proc/fire_projectile(projectile_type, atom/target, sound, firer, list/ignore_targets = list())
	if (!isnull(sound))
		playsound(src, sound, vol = 100, vary = TRUE)

	var/turf/start_turf = get_turf(src)
	var/obj/projectile/bullet = new projectile_type(start_turf)

	for (var/atom/thing as anything in ignore_targets)
		bullet.impacted += WEAKREF(thing)

	bullet.firer = firer || src
	bullet.fired_from = src
	bullet.aim_projectile(target, firer || src)
	bullet.fire(target)

	return bullet

/**
 * Calculates the pixel offsets and angle that a projectile should be launched at.
 *
 * Arguments:
 * - [source][/atom]: The thing that the projectile is being shot from.
 * - [target][/atom]: (Optional) The thing that the projectile is being shot at.
 *   - If this is not provided the  source atom must be a mob with a client.
 * - [modifiers][/list]: A list of click parameters used to modify the shot angle.
 */
/proc/calculate_projectile_angle_and_pixel_offsets(atom/source, atom/target, modifiers)
	var/angle = 0
	var/target_x = LAZYACCESS(modifiers, ICON_X) ? text2num(LAZYACCESS(modifiers, ICON_X)) : world.icon_size / 2 // ICON_(X|Y) are measured from the bottom left corner of the icon.
	var/target_y = LAZYACCESS(modifiers, ICON_Y) ? text2num(LAZYACCESS(modifiers, ICON_Y)) : world.icon_size / 2 // This centers the target if modifiers aren't passed.

	if(target)
		var/turf/source_turf = get_turf(source)
		var/turf/target_turf = get_turf(target)
		var/dx = ((target_turf.x - source_turf.x) * world.icon_size) + (target.pixel_x - source.pixel_x) + (target_x - (world.icon_size / 2))
		var/dy = ((target_turf.y - source_turf.y) * world.icon_size) + (target.pixel_y - source.pixel_y) + (target_y - (world.icon_size / 2))
		angle = ATAN2(dy, dx)
		return list(angle, target_x, target_y)

	if(!ismob(source) || !LAZYACCESS(modifiers, SCREEN_LOC))
		CRASH("Can't make trajectory calculations without a target or click modifiers and a client.")

	var/mob/user = source
	if(!user.client)
		CRASH("Can't make trajectory calculations without a target or click modifiers and a client.")

	//Split screen-loc up into X+Pixel_X and Y+Pixel_Y
	var/list/screen_loc_params = splittext(LAZYACCESS(modifiers, SCREEN_LOC), ",")
	//Split X+Pixel_X up into list(X, Pixel_X)
	var/list/screen_loc_x = splittext(screen_loc_params[1],":")
	//Split Y+Pixel_Y up into list(Y, Pixel_Y)
	var/list/screen_loc_y = splittext(screen_loc_params[2],":")

	var/tx = (text2num(screen_loc_x[1]) - 1) * world.icon_size + text2num(screen_loc_x[2])
	var/ty = (text2num(screen_loc_y[1]) - 1) * world.icon_size + text2num(screen_loc_y[2])

	//Calculate the "resolution" of screen based on client's view and world's icon size. This will work if the user can view more tiles than average.
	var/list/screenview = view_to_pixels(user.client.view)

	var/ox = round(screenview[1] / 2) - user.client.pixel_x //"origin" x
	var/oy = round(screenview[2] / 2) - user.client.pixel_y //"origin" y
	angle = ATAN2(tx - oy, ty - ox)
	return list(angle, target_x, target_y)

/// Fetches current ricochet angle and a rough (middle of the tile border) impact X and Y to cut down on trig for latter
/// This is a bit messy but probably the best way to do it - we calculate angle between the last "pause" turf and hit object, then compare it to our angle and based on that we get the side we impacted
/obj/projectile/proc/ricochet_angle_and_pixels(atom/target)
	var/turf/cur_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)

	// Distance between target and our last position
	var/target_diff_x = (target_turf.x - last_turf.x) * world.icon_size + target.pixel_x
	var/target_diff_y = (target_turf.y - last_turf.y) * world.icon_size + target.pixel_y
	var/target_angle = ATAN2(target_diff_x, target_diff_y)

	// Whenever we flip the vertical or horizontal direction of the projectile.
	// Signs required for this flip every 90 degrees of target_angle
	var/vertical = (round(target_angle / 90) % 2 == 1) ? angle < target_angle : angle > target_angle

	// Return middle of the hit border if we're on a different tile, or middle of the entry border if we're on the same tile as the hit object
	// Could be done in a single operation but then it becomes barely ledgible
	if (cur_turf == target_turf)
		if (vertical)
			return list(ATAN2(x_factor, y_factor * -1), ((last_turf.x > target_turf.x) ? 0 : world.icon_size), world.icon_size / 2)
		return list(ATAN2(x_factor * -1, y_factor), world.icon_size / 2, ((last_turf.y > target_turf.y) ? 0 : world.icon_size))

	if (vertical)
		return list(ATAN2(x_factor, y_factor * -1), ((last_turf.x > target_turf.x) ? world.icon_size : 0), world.icon_size / 2)
	return list(ATAN2(x_factor * -1, y_factor), world.icon_size / 2, ((last_turf.y > target_turf.y) ? world.icon_size : 0))

/// Reflects the projectile off an object. Unlike ricochets, does not aim itself at nearby people nor does it deal damage to the reflector
/obj/projectile/proc/reflect(atom/reflector)
	var/ricochet_data = ricochet_angle_and_pixels(reflector)
	if (hitscan)
		generate_tracer(origin_turf, get_turf(src), origin_x, origin_y, pixel_x, pixel_y)
	origin_turf = get_turf(src)
	origin_x = pixel_x
	origin_y = pixel_y
	set_angle(ricochet_data[1])
	impacted.Cut()
	impacted += WEAKREF(reflector)
	ignore_source_check = TRUE

/*
 * =============================
 *     Misc projectile code
 * =============================
*/

/// Volume of impact sounds. Hardcapped to 5 if we are suppressed
/obj/projectile/proc/impact_volume()
	if (suppressed) // Cap to 5 if suppressed
		return 5
	if (!src.damage) // 50% volume of the hitsound if we do no damage
		return 50
	return clamp((src.damage) * 0.67, 30, 100) // Multiply projectile damage by 0.67, then clamp the value between 30 and 100

/// Signal proc for when a mob attempts to attack this projectile or the turf it's on with an empty hand.
/obj/projectile/proc/attempt_parry(datum/source, mob/user, list/modifiers)
	SIGNAL_HANDLER

	if(parried)
		return FALSE

	if(SEND_SIGNAL(user, COMSIG_LIVING_PROJECTILE_PARRYING, src) & ALLOW_PARRY)
		on_parry(user, modifiers)
		return TRUE

	return FALSE

/// Called when a mob with PARRY_TRAIT clicks on this projectile or the tile its on, reflecting the projectile within 7 degrees and increasing the bullet's stats.
/obj/projectile/proc/on_parry(mob/user, list/modifiers)
	if(SEND_SIGNAL(user, COMSIG_LIVING_PROJECTILE_PARRIED, src) & INTERCEPT_PARRY_EFFECTS)
		return

	parried = TRUE
	set_angle(dir2angle(user.dir) + rand(-3, 3))
	firer = user
	speed *= 1.2 // Go 20% faster when parried
	damage *= 1.15 // And do 15% more damage
	add_atom_colour(COLOR_RED_LIGHT, TEMPORARY_COLOUR_PRIORITY)

/obj/projectile/experience_pressure_difference()
	return

/obj/projectile/vv_edit_var(var_name, var_value)
	switch(var_name)
		if(NAMEOF(src, angle))
			set_angle(var_value)
			return TRUE
		else
			return ..()

/**
 * Is this projectile considered "hostile"?
 *
 * By default all projectiles which deal damage or impart crowd control effects (including stamina) are hostile
 *
 * This is NOT used for pacifist checks, that's handled by [/obj/item/ammo_casing/var/harmful]
 * This is used in places such as AI responses to determine if they're being threatened or not (among other places)
 */

/obj/projectile/proc/is_hostile_projectile()
	if(damage > 0 || stamina > 0)
		return TRUE

	if(paralyze + stun + immobilize + knockdown > 0 SECONDS)
		return TRUE

	return FALSE

/// Fetches embedding data
/obj/projectile/proc/get_embed()
	return embed_type ? (embed_data ||= get_embed_by_type(embed_type)) : null

/obj/projectile/proc/set_embed(datum/embed_data/embed)
	if(embed_data == embed)
		return
	// GLOB.embed_by_type stores shared "default" embedding values of datums
	// Dynamically generated embeds use the base class and thus are not present in there, and should be qdeleted upon being discarded
	if(!isnull(embed_data) && !GLOB.embed_by_type[embed_data.type])
		qdel(embed_data)
	embed_data = ispath(embed) ? get_embed_by_type(armor) : embed
