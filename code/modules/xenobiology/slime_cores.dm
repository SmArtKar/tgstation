/// Slime Extracts ///

/obj/item/slime_extract
	name = "slime extract"
	desc = "Goo extracted from a slime. Legends claim these to have \"magical powers\"."
	icon = 'icons/obj/xenobiology/slime_extracts.dmi'
	icon_state = "grey"
	force = 0
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	throw_speed = 3
	throw_range = 6
	grind_results = list()
	var/uses = 1 ///uses before it goes inert
	var/tier = 1
	var/qdel_timer = null ///deletion timer, for delayed reactions
	var/list/react_reagents = list()
	var/activated = FALSE

/obj/item/slime_extract/proc/activate()

/obj/item/slime_extract/proc/use_up()
	if(activated)
		return
	name = "used [name]"
	desc += " This extract has been used up."

/obj/item/slime_extract/examine(mob/user)
	. = ..()
	if(uses > 1)
		. += "It has [uses] uses remaining."

/obj/item/slime_extract/Initialize(mapload)
	. = ..()
	create_reagents(100, INJECTABLE | DRAWABLE)

/obj/item/slime_extract/on_grind()
	. = ..()
	if(uses)
		grind_results[/datum/reagent/toxin/slimejelly] = 20

/obj/item/slime_extract/afterattack(atom/target, mob/living/user, proximity_flag)
	if(!proximity_flag || !target.is_open_container())
		return ..()

	var/datum/reagents/target_reagents = target.reagents
	if(target_reagents.trans_to(src, reagents.maximum_volume - reagents.total_volume))
		to_chat(user, span_notice("You dip [src] into [target]."))
		return

	if(!target_reagents.total_volume)
		to_chat(user, span_warning("[target] is empty!"))
	else
		to_chat(user, span_warning("[src] is full!"))

// ************************************************
// ******************* TIER ONE *******************
// ************************************************

// Grey Extract

/obj/item/slime_extract/grey
	name = "grey slime extract"
	icon_state = "grey"
	tier = 1
	react_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5)

// ************************************************
// ******************* TIER TWO *******************
// ************************************************

// Orange Extract

/obj/item/slime_extract/orange
	name = "orange slime extract"
	icon_state = "orange"
	tier = 2
	react_reagents = list(/datum/reagent/blood = 21, /datum/reagent/toxin/plasma = 5)

// Blue Extract

/obj/item/slime_extract/blue
	name = "blue slime extract"
	icon_state = "blue"
	tier = 2
	react_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5, /datum/reagent/water = 5)

// Purple Extract

/obj/item/slime_extract/purple
	name = "purple slime extract"
	icon_state = "purple"
	tier = 2
	react_reagents = list(/datum/reagent/blood = 10, /datum/reagent/toxin/plasma = 5)

// Metal Extract

/obj/item/slime_extract/metal
	name = "metal slime extract"
	icon_state = "metal"
	tier = 2
	react_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5)

// ************************************************
// ****************** TIER THREE ******************
// ************************************************

// Dark Purple Extract

/obj/item/slime_extract/dark_purple
	name = "dark purple slime extract"
	icon_state = "dark_purple"
	tier = 3
	react_reagents = list(/datum/reagent/water = 5, /datum/reagent/toxin/plasma = 5)
	var/drained_amount = 0

/obj/item/slime_extract/dark_purple/proc/plasma_drain()
	var/turf/our_turf = get_turf(src)
	our_turf.visible_message(span_notice("[src] starts to glow and hiss as it begins absorbing plasma in the air!"))
	START_PROCESSING(SSfastprocess, src)
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. It's draining plasma from the atmospehre and condensing it into solid plasma sheets."
	activated = TRUE
	update_icon()
	addtimer(CALLBACK(src, .proc/stop_draining), 15 SECONDS)

/obj/item/slime_extract/dark_purple/proc/stop_draining() //Converts 50% of the plasma in the air into sheets, 200 moles per sheet
	STOP_PROCESSING(SSfastprocess, src)
	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	if(uses <= 0)
		use_up()
	update_icon()
	if(drained_amount >= 200)
		new /obj/item/stack/sheet/mineral/plasma(get_turf(src), round(drained_amount / 200))

/obj/item/slime_extract/dark_purple/process()
	for(var/turf/drain_turf in range(1, get_turf(src))) //High efficiency draining!
		var/datum/gas_mixture/drain_mix = drain_turf.return_air()
		if(!drain_mix.gases[/datum/gas/plasma] || !drain_mix.gases[/datum/gas/plasma][MOLES])
			return

		drained_amount += drain_mix.gases[/datum/gas/plasma][MOLES]
		drain_mix.remove_specific(/datum/gas/plasma, drain_mix.gases[/datum/gas/plasma][MOLES])

// Dark Blue Extract

/obj/item/slime_extract/dark_blue
	name = "dark blue slime extract"
	icon_state = "dark_blue"
	tier = 3
	react_reagents = list(/datum/reagent/water = 5, /datum/reagent/toxin/plasma = 5)
	var/stasis_ready = FALSE

/obj/item/slime_extract/dark_blue/activate()
	activated = TRUE
	stasis_ready = TRUE
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. It can be smeared over somebody in critical condition or youself to cover them in stasis-inducing and pressure-proof slime for one minute."

/obj/item/slime_extract/dark_blue/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!ishuman(target) || !stasis_ready)
		return

	var/mob/living/carbon/human/victim = target
	if(victim != user && !victim.stat)
		return

	victim.visible_message(span_warning("[src] starts to inflate and envelops [victim] in a layer stasis-inducing slime!"), span_userdanger("[src] starts to inflate and envelops you in a layer stasis-inducing slime!"))
	victim.apply_status_effect(/datum/status_effect/slime/dark_blue)
	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	if(uses <= 0)
		qdel(src)

// Silver Extract

/obj/item/slime_extract/silver
	name = "silver slime extract"
	icon_state = "silver"
	tier = 3
	react_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5, /datum/reagent/water = 5)

// Yellow Extract

/obj/item/slime_extract/yellow
	name = "yellow slime extract"
	icon_state = "yellow"
	tier = 3
	react_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5, /datum/reagent/water = 5)

// ************************************************
// ****************** TIER FOUR *******************
// ************************************************

// Cerulean Extract

/obj/item/slime_extract/cerulean
	name = "cerulean slime extract"
	icon_state = "cerulean"
	tier = 4
	react_reagents = list(/datum/reagent/toxin/plasma = 5)

// Sepia Extract

/obj/item/slime_extract/sepia
	name = "sepia slime extract"
	icon_state = "sepia"
	tier = 4
	react_reagents = list(/datum/reagent/toxin/plasma = 5)

/obj/item/slime_extract/sepia/activate()
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. It will soon explode into a timestop field!"
	activated = TRUE
	addtimer(CALLBACK(src, .proc/slime_stop), 5 SECONDS)
	playsound(get_turf(src), 'sound/magic/mandswap.ogg', 100, TRUE)

/obj/item/slime_extract/sepia/proc/slime_stop()
	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE
	new /obj/effect/timestop/small_effect(get_turf(src), 1)
	if(uses > 0)
		icon_state = initial(icon_state)
		var/mob/lastheld = get_mob_by_key(fingerprintslast)
		if(lastheld && !lastheld.equip_to_slot_if_possible(src, ITEM_SLOT_HANDS, disable_warning = TRUE))
			forceMove(get_turf(lastheld))
	else
		use_up()

// Pyrite Extract

/obj/item/slime_extract/pyrite
	name = "pyrite slime extract"
	icon_state = "pyrite"
	tier = 4

// Bluespace Extract

/obj/item/slime_extract/bluespace
	name = "bluespace slime extract"
	icon_state = "bluespace"
	tier = 4
	react_reagents = list(/datum/reagent/toxin/plasma = 5)

// ************************************************
// ****************** TIER FIVE *******************
// ************************************************

// Red Extract

/obj/item/slime_extract/red
	name = "red slime extract"
	icon_state = "red"
	tier = 5
	react_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5, /datum/reagent/water = 5)

// Green Extract

/obj/item/slime_extract/green
	name = "green slime extract"
	icon_state = "green"
	tier = 5
	react_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5, /datum/reagent/uranium/radium = 5)

// Pink Extract

/obj/item/slime_extract/pink
	name = "pink slime extract"
	icon_state = "pink"
	tier = 5
	react_reagents = list(/datum/reagent/toxin/plasma = 5)

// Gold Extract

/obj/item/slime_extract/gold
	name = "gold slime extract"
	icon_state = "gold"
	tier = 5

// ************************************************
// ******************* TIER SIX *******************
// ************************************************

// Oil Extract

/obj/item/slime_extract/oil
	name = "oil slime extract"
	icon_state = "oil"
	tier = 6

// Black Extract

/obj/item/slime_extract/black
	name = "black slime extract"
	icon_state = "black"
	tier = 6
	react_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5)
	var/relimb_ready = FALSE
	var/list/limb_transform_types = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/l_arm/jelly/slime,
		BODY_ZONE_R_ARM = /obj/item/bodypart/r_arm/jelly/slime,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/jelly/slime,
		BODY_ZONE_L_LEG = /obj/item/bodypart/l_leg/jelly/slime,
		BODY_ZONE_R_LEG = /obj/item/bodypart/r_leg/jelly/slime,
	)

/obj/item/slime_extract/black/activate()
	relimb_ready = TRUE
	activated = TRUE
	icon_state = "[initial(icon_state)]_pulsating"
	name = "activated [initial(name)]"
	desc = "An activated [initial(name)]. It can be smeared over someone's missing limb to restore it or existing one to patch up its wounds."

/obj/item/slime_extract/black/afterattack(atom/target, mob/living/user, proximity_flag)
	. = ..()
	if(!ishuman(target) || !relimb_ready)
		return

	icon_state = initial(icon_state)
	name = initial(name)
	desc = initial(desc)
	activated = FALSE

	var/mob/living/carbon/human/victim = target
	var/obj/item/bodypart/target_part = victim.get_bodypart(user.zone_selected)
	if(target_part && target_part.bodytype & BODYTYPE_ORGANIC)
		target_part.heal_damage(50, 50) //Usually full heal
		for(var/datum/wound/wound as anything in target_part.wounds)
			wound.on_synthflesh(30)
			wound.on_xadone(70) //Not enough to heal critical wounds, but works for moderate and severe
		if(uses <= 0)
			qdel(src)
			return
		return

	var/limb_type = limb_transform_types[user.zone_selected]
	var/obj/item/bodypart/new_part = new limb_type()
	new_part.mutation_color = "#333333"
	new_part.attach_limb(victim, TRUE)
	victim.update_body_parts()
	playsound(get_turf(victim), 'sound/effects/splat.ogg', 100, TRUE)
	victim.visible_message(span_notice("[user] smears [src] all over [victim]'s missing [parse_zone(user.zone_selected)] and it reforms into a new slimy limb."))

	if(uses <= 0)
		qdel(src)

// Adamantine Extract

/obj/item/slime_extract/adamantine
	name = "adamantine slime extract"
	icon_state = "adamantine"
	tier = 6

// Light Pink Extrat

/obj/item/slime_extract/lightpink
	name = "light pink slime extract"
	icon_state = "light_pink"
	tier = 6


// ************************************************
// ****************** TIER SEVEN ******************
// ************************************************

// Rainbow Extract

/obj/item/slime_extract/special/rainbow
	name = "rainbow slime extract"
	icon_state = "rainbow"
	tier = 7

/obj/item/slime_extract/special/fiery
	name = "fiery slime extract"
	icon_state = "fiery"
	tier = 0 //No selling

/obj/item/slime_extract/special/biohazard
	name = "biohazard slime extract"
	icon_state = "biohazard"
	tier = 0
