
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
	required_reagents = list(/datum/reagent/blood = 1)

/datum/chemical_reaction/slime/grey_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/stack/biomass(get_turf(holder.my_atom), 3) //You can insert these into the biomass recycler and get 3 monkey cubes
	. = ..()

/datum/chemical_reaction/slime/grey_plasma
	required_container = /obj/item/slime_extract/grey
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/grey_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/mob/living/simple_animal/slime/color/grey/slime = new(get_turf(holder.my_atom))
	slime.visible_message(span_danger("[holder.my_atom] begins to grow as it is injected with plasma and turns into a small grey slime!"))
	. = ..()

// ************************************************
// ******************* TIER TWO *******************
// ************************************************

// Orange Extract

/datum/chemical_reaction/slime/orange_blood
	required_container = /obj/item/slime_extract/orange
	required_reagents = list(/datum/reagent/blood = 3)
	results = list(/datum/reagent/phosphorus = 1, /datum/reagent/potassium = 1, /datum/reagent/consumable/sugar = 1, /datum/reagent/consumable/capsaicin = 2)

/datum/chemical_reaction/slime/orange_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/orange

/datum/chemical_reaction/slime/orange_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/atom/cycle_loc = holder.my_atom
	while(!isturf(cycle_loc) && !ishuman(cycle_loc))
		cycle_loc = cycle_loc.loc

	if(!ishuman(cycle_loc))
		cycle_loc.visible_message(span_warning("[holder.my_atom] starts to expand, but fails to find something to latch onto and deflates!"))
		deletes_extract = FALSE
		return ..()

	var/mob/living/carbon/human/owner = cycle_loc
	owner.apply_status_effect(/datum/status_effect/slime/orange)
	return ..()


// Purple Extract

/datum/chemical_reaction/slime/purple_blood
	required_container = /obj/item/slime_extract/purple
	required_reagents = list(/datum/reagent/blood = 1)
	results = list(/datum/reagent/medicine/regen_jelly = 5)

/datum/chemical_reaction/slime/purple_plasma
	required_container = /obj/item/slime_extract/purple
	required_reagents = list(/datum/reagent/toxin/plasma = 1)

/datum/chemical_reaction/slime/purple_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slime_potion/slime_steroid(get_turf(holder.my_atom))
	return ..()

// Blue Extract

/datum/chemical_reaction/slime/blue_plasma
	required_container = /obj/item/slime_extract/blue
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	results = list(/datum/reagent/consumable/frostoil = 10)

/datum/chemical_reaction/slime/blue_blood
	required_container = /obj/item/slime_extract/blue
	required_reagents = list(/datum/reagent/blood = 1)

/datum/chemical_reaction/slime/blue_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/slime_potion/slime_stabilizer(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/blue_water
	required_container = /obj/item/slime_extract/blue
	required_reagents = list(/datum/reagent/water = 1)

/datum/chemical_reaction/slime/blue_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/grenade/frost_core(get_turf(holder.my_atom))
	return ..()

// Metal Extract

/datum/chemical_reaction/slime/metal_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/metal

/datum/chemical_reaction/slime/metal_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/location = get_turf(holder.my_atom)
	new /obj/item/stack/sheet/plasteel(location, 5)
	new /obj/item/stack/sheet/iron(location, 15)
	return ..()

/datum/chemical_reaction/slime/metal_water
	required_reagents = list(/datum/reagent/water = 1)
	required_container = /obj/item/slime_extract/metal

/datum/chemical_reaction/slime/metal_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/location = get_turf(holder.my_atom)
	new /obj/item/stack/sheet/rglass(location, 5)
	new /obj/item/stack/sheet/glass(location, 15)
	return ..()

// ************************************************
// ****************** TIER THREE ******************
// ************************************************

// Yellow Extract

/datum/chemical_reaction/slime/yellow_blood
	required_reagents = list(/datum/reagent/blood = 1)
	required_container = /obj/item/slime_extract/yellow
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_SLIME | REACTION_TAG_DANGEROUS
	deletes_extract = FALSE

/datum/chemical_reaction/slime/yellow_blood/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	empulse(get_turf(holder.my_atom), 3, 7)
	return ..()

/datum/chemical_reaction/slime/yellow_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/yellow

/datum/chemical_reaction/slime/yellow_plasma/on_reaction(datum/reagents/holder, created_volume)
	new /obj/item/stock_parts/cell/emproof/slime(get_turf(holder.my_atom))
	return ..()

/datum/chemical_reaction/slime/yellow_water
	required_reagents = list(/datum/reagent/water = 1)
	required_container = /obj/item/slime_extract/yellow

/datum/chemical_reaction/slime/yellow_water/on_reaction(datum/reagents/holder, created_volume)
	var/turf/location = get_turf(holder.my_atom)
	location.visible_message(span_danger("[holder.my_atom] explodes into an electrical field!"))
	playsound(get_turf(src), 'sound/weapons/zapbang.ogg', 50, TRUE)
	for(var/mob/living/victim in view(4, location))
		victim.Beam(location, "lightning[rand(1, 12)]", time = 8)
		victim.electrocute_act(25, src)
		to_chat(victim, span_userdanger("You feel a sharp electrical pulse!"))
	return ..()

// Dark Purple

/datum/chemical_reaction/slime/dark_purple_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/dark_purple

/datum/chemical_reaction/slime/dark_purple_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	new /obj/item/stack/sheet/mineral/plasma(get_turf(holder.my_atom), 5)
	return ..()

/datum/chemical_reaction/slime/dark_purple_water
	required_reagents = list(/datum/reagent/water = 1)
	required_container = /obj/item/slime_extract/dark_purple
	deletes_extract = FALSE

/datum/chemical_reaction/slime/dark_purple_water/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/dark_purple/extract = holder.my_atom
	if(!istype(extract))
		return
	extract.plasma_drain()
	return ..()

// Dark Blue

/datum/chemical_reaction/slime/dark_blue_plasma
	required_reagents = list(/datum/reagent/toxin/plasma = 1)
	required_container = /obj/item/slime_extract/dark_blue

/datum/chemical_reaction/slime/dark_blue_plasma/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/obj/item/slime_extract/dark_blue/extract = holder.my_atom
	if(!istype(extract))
		return
	extract.stasis_ready = TRUE
	return ..()

/datum/chemical_reaction/slime/dark_blue_blood
	required_reagents = list(/datum/reagent/blood = 1)
	required_container = /obj/item/slime_extract/dark_blue

/datum/chemical_reaction/slime/dark_blue_blood/on_reaction(datum/reagents/holder, created_volume)
	new /obj/item/reagent_containers/hypospray/medipen/slimepen/dark_blue(get_turf(holder.my_atom))
	return ..()
