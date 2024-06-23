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

	/// How many pixels this projectile moves per decisecond
	/// This value is inverse from old guncode, which divided delta_time by this value instead of multiplying it
	var/speed = 1.25


