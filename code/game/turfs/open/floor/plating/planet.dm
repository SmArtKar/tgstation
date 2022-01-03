/turf/open/floor/plating/dirt
	gender = PLURAL
	name = "dirt"
	desc = "Upon closer examination, it's still dirt."
	icon = 'icons/turf/floors.dmi'
	icon_state = "dirt_basic"
	base_icon_state = "dirt"
	baseturfs = /turf/open/floor/plating/dirt //No longer becomes a chasm. Needed to prevent players from getting into ruins easily.
	initial_gas_mix = OPENTURF_LOW_PRESSURE
	planetary_atmos = TRUE
	attachment_holes = FALSE
	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SAND
	clawfootstep = FOOTSTEP_SAND
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	tiled_dirt = FALSE

	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_TURF_OPEN, SMOOTH_GROUP_FLOOR_DIRT)
	canSmoothWith = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_FLOOR_DIRT)
	var/smooth_icon = 'icons/turf/floors/dirt.dmi'

/turf/open/floor/plating/dirt/Initialize()
	. = ..()
	if(smoothing_flags)
		var/matrix/translation = new
		translation.Translate(-5, -5)
		transform = translation
		icon = smooth_icon

/turf/open/floor/plating/dirt/setup_broken_states()
	return list("dirt")

/turf/open/floor/plating/dirt/dark
	icon_state = "greenerdirt"
	base_icon_state = "greenerdirt"

/turf/open/floor/plating/dirt/try_replace_tile(obj/item/stack/tile/T, mob/user, params)
	return

/turf/open/floor/plating/dirt/jungle
	slowdown = 0.5
	initial_gas_mix = JUNGLE_DEFAULT_ATMOS

/turf/open/floor/plating/dirt/jungle/dark
	icon_state = "greenerdirt"
	base_icon_state = "dirt"
	smooth_icon = 'icons/turf/floors/dirt_greener.dmi'

/turf/open/floor/plating/dirt/jungle/wasteland //Like a more fun version of living in Arizona.
	name = "cracked earth"
	desc = "Looks a bit dry."
	icon = 'icons/turf/floors.dmi'
	icon_state = "wasteland"
	base_icon_state = "wasteland"
	slowdown = 1

	smoothing_flags = NONE
	smoothing_groups = null
	canSmoothWith = null
	layer = 1.99 //So other turfs go above it

	var/floor_variance = 15

/turf/open/floor/plating/dirt/jungle/wasteland/setup_broken_states()
	return list("[initial(icon_state)]0")

/turf/open/floor/plating/dirt/jungle/wasteland/Initialize(mapload)
	.=..()
	if(prob(floor_variance))
		icon_state = "[initial(icon_state)][rand(0,12)]"

/turf/open/floor/plating/dirt/jungle/corrupted
	name = "corrupted dirt"
	desc = "If you look closer, you actually realise that's it's a patch of spiky, moving biomass. Probably not a great idea to step on this."
	slowdown = 0.75

/turf/open/floor/plating/dirt/jungle/corrupted/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(prob(15) && isliving(arrived))
		var/mob/living/victim = arrived
		var/damage = 1
		if(HAS_TRAIT(victim, TRAIT_LIGHT_STEP))
			damage *= 0.75

		var/picked_def_zone = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
		var/obj/item/bodypart/bodypart = victim.get_bodypart(picked_def_zone)
		if(!istype(bodypart))
			victim.adjustBruteLoss(5 * damage)
			to_chat(victim, span_userdanger("[src] stabs you with it's small spikes!"))
			return

		if(bodypart.status == BODYPART_ROBOTIC)
			damage *= 0.75

		victim.apply_damage(5 * damage, BRUTE, bodypart)
		to_chat(victim, span_userdanger("[src] stabs your [bodypart] with it's small spikes!"))

/turf/open/floor/plating/grass/jungle
	name = "jungle grass"
	initial_gas_mix = JUNGLE_DEFAULT_ATMOS
	planetary_atmos = TRUE
	baseturfs = /turf/open/floor/plating/dirt
	desc = "Greener on the other side."
	icon_state = "junglegrass"
	base_icon_state = "junglegrass"
	smooth_icon = 'icons/turf/floors/junglegrass.dmi'
	smoothing_groups = list(SMOOTH_GROUP_TURF_OPEN, SMOOTH_GROUP_FLOOR_GRASS_JUNGLE)
	canSmoothWith = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_FLOOR_GRASS_JUNGLE)

	layer = 2.031

/turf/open/floor/plating/grass/jungle/green
	smooth_icon = 'icons/turf/floors/junglegrass_green.dmi'
	smoothing_groups = list(SMOOTH_GROUP_TURF_OPEN, SMOOTH_GROUP_FLOOR_GRASS)
	canSmoothWith = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_FLOOR_GRASS)
	layer = HIGH_TURF_LAYER


/turf/open/floor/plating/grass/jungle/corrupted
	name = "corrupted grass"
	desc = "If you look closer, you actually realise that's it's a patch of spiky, moving biomass. Probably not a great idea to step on this."
	slowdown = 0.75

	smoothing_groups = list(SMOOTH_GROUP_TURF_OPEN, SMOOTH_GROUP_FLOOR_GRASS_JUNGLE)
	canSmoothWith = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_FLOOR_GRASS_JUNGLE)
	layer = HIGH_TURF_LAYER

/turf/open/floor/plating/grass/jungle/corrupted/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(prob(15) && isliving(arrived))
		var/mob/living/victim = arrived
		var/damage = 1
		if(HAS_TRAIT(victim, TRAIT_LIGHT_STEP))
			damage *= 0.75

		var/picked_def_zone = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
		var/obj/item/bodypart/bodypart = victim.get_bodypart(picked_def_zone)
		if(!istype(bodypart))
			victim.adjustBruteLoss(5 * damage)
			to_chat(victim, span_userdanger("[src] stabs you with it's small spikes!"))
			return

		if(bodypart.status == BODYPART_ROBOTIC)
			damage *= 0.75

		victim.apply_damage(5 * damage, BRUTE, bodypart)
		to_chat(victim, span_userdanger("[src] stabs your [bodypart] with it's small spikes!"))
