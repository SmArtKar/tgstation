
/datum/chemical_reaction/slime
	reaction_flags = REACTION_INSTANT
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_SLIME
	required_other = TRUE

	var/deletes_extract = TRUE

/datum/chemical_reaction/slime/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	use_slime_core(holder)

/datum/chemical_reaction/slime/proc/use_slime_core(datum/reagents/holder)
	SSblackbox.record_feedback("tally", "slime_cores_used", 1, "type")
	if(deletes_extract)
		delete_extract(holder)

/datum/chemical_reaction/slime/proc/delete_extract(datum/reagents/holder)
	var/obj/item/slime_extract/M = holder.my_atom
	if(M.uses <= 0 && !results.len) //if the slime doesn't output chemicals
		qdel(M)

// ************************************************
// ******************* TIER ONE *******************
// ************************************************

// Grey Extract

/datum/chemical_reaction/slime/grey_blood
	required_container = /obj/item/slime_extract/grey
	required_reagents = list(/datum/reagent/blood = 5)

/datum/chemical_reaction/slime/grey_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	for(var/i in 1 to 3)
		new /obj/item/stack/biomass(get_turf(holder.my_atom)) //You can insert these into the biomass recycler and get 3 monkey cubes
	. = ..()

/datum/chemical_reaction/slime/grey_plasma
	required_container = /obj/item/slime_extract/grey
	required_reagents = list(/datum/reagent/toxin/plasma = 5)

/datum/chemical_reaction/slime/grey_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/mob/living/simple_animal/slime/slime = new(get_turf(holder.my_atom), /datum/slime_color/grey)
	slime.visible_message(span_danger("[holder.my_atom] begins to grow as it is injected with plasma and turns into a small grey slime!"))
	. = ..()

// ************************************************
// ******************* TIER TWO *******************
// ************************************************

// Orange Extract

/datum/chemical_reaction/slime/orange_blood
	required_container = /obj/item/slime_extract/orange
	required_reagents = list(/datum/reagent/blood = 1)
	results = list(/datum/reagent/phosphorus = 1, /datum/reagent/potassium = 1, /datum/reagent/consumable/sugar = 1, /datum/reagent/consumable/capsaicin = 2)

/datum/chemical_reaction/slime/orange_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/orange
	deletes_extract = FALSE

/datum/chemical_reaction/slime/orange_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/T = get_turf(holder.my_atom)
	T.visible_message(span_danger("[holder.my_atom] begins to bubble and vibrate!"))
	addtimer(CALLBACK(src, .proc/slime_burn, holder), 50)
	var/obj/item/slime_extract/M = holder.my_atom
	deltimer(M.qdel_timer)
	. = ..()
	M.qdel_timer = addtimer(CALLBACK(src, .proc/delete_extract, holder), 55, TIMER_STOPPABLE)

/datum/chemical_reaction/slime/orange_plasma/proc/slime_burn(datum/reagents/holder)
	if(holder?.my_atom)
		var/turf/open/T = get_turf(holder.my_atom)
		if(istype(T))
			T.atmos_spawn_air("plasma=50;TEMP=1000")

// Purple Extract

/datum/chemical_reaction/slime/purple_blood
	required_reagents = list(/datum/reagent/blood = 1)
	results = list(/datum/reagent/medicine/regen_jelly = 5)
	required_container = /obj/item/slime_extract/purple

/datum/chemical_reaction/slime/purple_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/purple

/datum/chemical_reaction/slime/purple_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slimepotion/slime/steroid(get_turf(holder.my_atom))
	return ..()

// Blue Extract

/datum/chemical_reaction/slime/blue_plasma
	results = list(/datum/reagent/consumable/frostoil = 10)
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/blue

/datum/chemical_reaction/slime/blue_blood
	required_reagents = list(/datum/reagent/blood = 1)
	required_container = /obj/item/slime_extract/blue

/datum/chemical_reaction/slime/blue_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slimepotion/slime/stabilizer(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/blue_water
	required_reagents = list(/datum/reagent/water = 5)
	required_container = /obj/item/slime_extract/blue

/datum/chemical_reaction/slime/blue_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	holder.create_foam(/datum/effect_system/foam_spread, 80, span_danger("[src] spews out foam!"))

// Metal Extract

/datum/chemical_reaction/slime/metal_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/metal

/datum/chemical_reaction/slime/metal_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/stack/sheet/plasteel(get_turf(holder.my_atom), 5)
	new /obj/item/stack/sheet/iron(get_turf(holder.my_atom), 15)
	return ..()

/datum/chemical_reaction/slime/metal_water
	required_reagents = list(/datum/reagent/water = 1)
	required_container = /obj/item/slime_extract/metal

/datum/chemical_reaction/slime/metal_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/stack/sheet/rglass(get_turf(holder.my_atom), 15)
	new /obj/item/stack/sheet/glass(get_turf(holder.my_atom), 15)
	..()

// ************************************************
// ****************** TIER THREE ******************
// ************************************************
