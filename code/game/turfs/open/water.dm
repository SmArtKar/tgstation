/turf/open/water
	gender = PLURAL
	name = "water"
	desc = "Shallow water."
	icon = 'icons/turf/floors.dmi'
	icon_state = "riverwater_motion"
	baseturfs = /turf/open/chasm/lavaland
	initial_gas_mix = OPENTURF_LOW_PRESSURE
	planetary_atmos = TRUE
	slowdown = 1
	bullet_sizzle = TRUE
	bullet_bounce_sound = null //needs a splashing sound one day.

	footstep = FOOTSTEP_WATER
	barefootstep = FOOTSTEP_WATER
	clawfootstep = FOOTSTEP_WATER
	heavyfootstep = FOOTSTEP_WATER

/turf/open/water/jungle //Actually working water that wets stuff
	baseturfs = /turf/open/floor/plating/dirt/jungle
	initial_gas_mix = JUNGLE_DEFAULT_ATMOS
	slowdown = 4 //We're swimming, not walking
	layer = 1.98 //We need other turfs to be above it

	var/flora_list = list(/obj/structure/flora/aquatic/rock = 1, /obj/structure/flora/aquatic/rock/pile = 1, /obj/structure/flora/aquatic/seaweed = 8)
	var/flora_prob = 8

/turf/open/water/jungle/corrupted
	name = "corrupted water"
	desc = "Is that... blood?!"
	icon_state = "riverwater_motion_corrupted"

/turf/open/water/jungle/ex_act(severity, target)
	contents_explosion(severity, target)

/turf/open/water/jungle/MakeSlippery(wet_setting, min_wet_time, wet_time_to_add, max_wet_time, permanent)
	return

/turf/open/water/jungle/Melt()
	to_be_destroyed = FALSE
	return src

/turf/open/water/jungle/acid_act(acidpwr, acid_volume)
	return FALSE

/turf/open/water/jungle/MakeDry(wet_setting = TURF_WET_WATER)
	return

/turf/open/water/jungle/Entered(atom/movable/AM)
	if(wet_stuff(AM))
		START_PROCESSING(SSobj, src)
	. = ..()

/turf/open/water/jungle/Exited(atom/movable/Obj, atom/newloc)
	. = ..()
	if(isliving(Obj))
		var/mob/living/L = Obj
		if(L.on_fire)
			L.update_fire()

/turf/open/water/jungle/Initialize()
	. = ..()
	for(var/obj/structure/flora/plant in src) //We don't want any rocks or grass randomly growing in water
		if(istype(plant, /obj/structure/flora/aquatic))
			continue
		qdel(plant)

	if(prob(flora_prob))
		var/area/A = loc

		if(!(A.area_flags & FLORA_ALLOWED))
			return

		var/flora_type = pick_weight(flora_list)
		new flora_type(src)

/turf/open/water/jungle/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if(wet_stuff(AM))
		START_PROCESSING(SSobj, src)

/turf/open/water/jungle/process(delta_time)
	if(!wet_stuff(null, delta_time))
		STOP_PROCESSING(SSobj, src)

/turf/open/water/jungle/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	switch(the_rcd.mode)
		if(RCD_FLOORWALL)
			return list("mode" = RCD_FLOORWALL, "delay" = 0, "cost" = 3)
	return FALSE

/turf/open/water/jungle/singularity_act()
	return

/turf/open/water/jungle/singularity_pull(S, current_size)
	return

/turf/open/water/jungle/attackby(obj/item/C, mob/user, params)
	..()
	if(istype(C, /obj/item/stack/rods))
		var/obj/item/stack/rods/R = C
		var/obj/structure/lattice/H = locate(/obj/structure/lattice, src)
		if(H)
			to_chat(user, "<span class='warning'>There is already a lattice here!</span>")
			return
		if(R.use(1))
			to_chat(user, "<span class='notice'>You construct a lattice.</span>")
			playsound(src, 'sound/weapons/genhit.ogg', 50, TRUE)
			new /obj/structure/lattice(locate(x, y, z))
		else
			to_chat(user, "<span class='warning'>You need one rod to build a lattice.</span>")
		return

/turf/open/water/jungle/proc/is_safe()
	var/static/list/safeties_typecache = typecacheof(list(/obj/structure/lattice/catwalk, /obj/structure/stone_tile, /obj/structure/lattice))
	var/list/found_safeties = typecache_filter_list(contents, safeties_typecache)
	for(var/obj/structure/stone_tile/S in found_safeties)
		if(S.fallen)
			LAZYREMOVE(found_safeties, S)
	return LAZYLEN(found_safeties)

/turf/open/water/jungle/proc/wet_stuff(AM, delta_time = 1)
	. = 0

	if(is_safe())
		return FALSE

	var/thing_to_check = src
	if (AM)
		thing_to_check = list(AM)

	for(var/thing in thing_to_check)
		if(isobj(thing))
			. = 1
			var/obj/O = thing
			if(O.resistance_flags & (ON_FIRE))
				O.extinguish()

			if(istype(O, /obj/structure/closet))
				var/obj/structure/closet/C = O
				for(var/I in C.contents)
					wet_stuff(I)

		else if (isliving(thing))
			. = 1
			var/mob/living/L = thing

			var/buckle_check = L.buckled
			if(isobj(buckle_check))
				var/obj/O = buckle_check
				if(istype(O, /obj/vehicle/ridden/lavaboat)) //Any kind of boat
					continue

			if(L.movement_type & FLYING)
				continue

			L.adjust_fire_stacks(-10 * delta_time)

			if(L.mob_size <= MOB_SIZE_SMALL || L.body_position == LYING_DOWN) //Lying/small mobs drown in water
				if(L.losebreath < 5)
					L.losebreath = min(5, L.losebreath + 1)

			for(var/obj/item/I in L)
				wet_stuff(I)

/turf/open/water/jungle/underground
	flora_list = list(/obj/structure/flora/aquatic/rock = 2, /obj/structure/flora/aquatic/rock/pile = 4)
