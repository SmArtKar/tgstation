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
	var/extract_color = COLOR_WHITE
	var/list/activate_reagents = list() ///Reagents required for activation

/obj/item/slime_extract/examine(mob/user)
	. = ..()
	if(uses > 1)
		. += "It has [uses] uses remaining."

/obj/item/slime_extract/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/slimepotion/enhancer))
		if(uses >= 5)
			to_chat(user, span_warning("You cannot enhance this extract further!"))
			return ..()
		if(istype(O, /obj/item/slimepotion/enhancer/max))
			to_chat(user, span_notice("You dump the maximizer on the slime extract. It can now be used a total of 5 times!"))
			uses = 5
		else
			to_chat(user, span_notice("You apply the enhancer to the slime extract. It may now be reused one more time."))
			uses++
		qdel(O)
	..()

/obj/item/slime_extract/Initialize(mapload)
	. = ..()
	create_reagents(100, INJECTABLE | DRAWABLE)

/obj/item/slime_extract/on_grind()
	. = ..()
	if(uses)
		grind_results[/datum/reagent/toxin/slimejelly] = 20

/**
* Effect when activated by a Luminescent.
*
* This proc is called whenever a Luminescent consumes a slime extract. Each one is separated into major and minor effects depending on the extract. Cooldown is measured in deciseconds.
*
* * arg1 - The mob absorbing the slime extract.
* * arg2 - The valid species for the absorbtion. Should always be a Luminescent unless something very major has changed.
* * arg3 - Whether or not the activation is major or minor. Major activations have large, complex effects, minor are simple.
*/

/obj/item/slime_extract/proc/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	to_chat(user, span_warning("Nothing happened... This slime extract cannot be activated this way."))
	return FALSE

// ************************************************
// ******************* TIER ONE *******************
// ************************************************

// Grey Extract

/obj/item/slime_extract/grey
	name = "grey slime extract"
	icon_state = "grey"
	activate_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5)
	extract_color = COLOR_GRAY
	tier = 1

/obj/item/slime_extract/grey/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/obj/item/stack/biomass/cube = new(user.drop_location())
			user.put_in_active_hand(cube)
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			to_chat(user, span_notice("You spit out a cube of biomass."))
			return 120

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_notice("Your [name] starts pulsing..."))
			if(do_after(user, 40, target = user))
				var/mob/living/simple_animal/slime/S = new(get_turf(user), /datum/slime_color/grey)
				playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
				to_chat(user, span_notice("You spit out [S]."))
				return 350
			else
				return 0

// ************************************************
// ******************* TIER TWO *******************
// ************************************************

// Orange Extract

/obj/item/slime_extract/orange
	name = "orange slime extract"
	icon_state = "orange"
	activate_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5, /datum/reagent/water = 5)
	extract_color = COLOR_ORANGE
	tier = 2

/obj/item/slime_extract/orange/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_notice("You activate [src]. You start feeling hot!"))
			user.reagents.add_reagent(/datum/reagent/consumable/capsaicin, 10)
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			user.reagents.add_reagent(/datum/reagent/phosphorus, 5)			  //
			user.reagents.add_reagent(/datum/reagent/potassium, 5)			  // = smoke, along with any reagents inside mr. slime
			user.reagents.add_reagent(/datum/reagent/consumable/sugar, 5)     //
			to_chat(user, span_warning("You activate [src], and a cloud of smoke bursts out of your skin!"))
			return 450

// Blue Extract

/obj/item/slime_extract/blue
	name = "blue slime extract"
	icon_state = "blue"
	activate_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5, /datum/reagent/water = 5)
	extract_color = COLOR_BLUE
	tier = 2

/obj/item/slime_extract/blue/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_notice("You activate [src]. Your genome feels more stable!"))
			user.adjustCloneLoss(-15)
			user.reagents.add_reagent(/datum/reagent/medicine/mutadone, 10)
			user.reagents.add_reagent(/datum/reagent/medicine/potass_iodide, 10)
			return 250

		if(SLIME_ACTIVATE_MAJOR)
			user.reagents.create_foam(/datum/effect_system/foam_spread,20)
			user.visible_message(span_danger("Foam spews out from [user]'s skin!"), span_warning("You activate [src], and foam bursts out of your skin!"))
			return 600

// Purple Extract

/obj/item/slime_extract/purple
	name = "purple slime extract"
	icon_state = "purple"
	activate_reagents = list(/datum/reagent/blood = 5, /datum/reagent/toxin/plasma = 5)
	extract_color = COLOR_PURPLE
	tier = 2

/obj/item/slime_extract/purple/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			user.adjust_nutrition(50)
			user.blood_volume += 50
			to_chat(user, span_notice("You activate [src], and your body is refilled with fresh slime jelly!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_notice("You activate [src], and it releases regenerative chemicals!"))
			user.reagents.add_reagent(/datum/reagent/medicine/regen_jelly,10)
			return 600

// Metal Extract

/obj/item/slime_extract/metal
	name = "metal slime extract"
	icon_state = "metal"
	activate_reagents = list(/datum/reagent/toxin/plasma = 5, /datum/reagent/water = 5)
	extract_color = COLOR_DARK
	tier = 2

/obj/item/slime_extract/metal/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/obj/item/stack/sheet/iron/O = new(null, 10)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			var/obj/item/stack/sheet/plasteel/O = new(null, 10)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 200

// ************************************************
// ****************** TIER THREE ******************
// ************************************************

// Dark Purple Extract

/obj/item/slime_extract/darkpurple
	name = "dark purple slime extract"
	icon_state = "dark_purple"
	activate_reagents = list(/datum/reagent/toxin/plasma)
	tier = 3

/obj/item/slime_extract/darkpurple/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/obj/item/stack/sheet/mineral/plasma/O = new(null, 1)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			var/turf/open/T = get_turf(user)
			if(istype(T))
				T.atmos_spawn_air("plasma=20")
			to_chat(user, span_warning("You activate [src], and a cloud of plasma bursts out of your skin!"))
			return 900

// Dark Blue Extract

/obj/item/slime_extract/darkblue
	name = "dark blue slime extract"
	icon_state = "dark_blue"
	activate_reagents = list(/datum/reagent/toxin/plasma,/datum/reagent/water)
	tier = 3

/obj/item/slime_extract/darkblue/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_notice("You activate [src]. You start feeling colder!"))
			user.extinguish_mob()
			user.adjust_fire_stacks(-20)
			user.reagents.add_reagent(/datum/reagent/consumable/frostoil,4)
			user.reagents.add_reagent(/datum/reagent/medicine/cryoxadone,5)
			return 100

		if(SLIME_ACTIVATE_MAJOR)
			var/turf/open/T = get_turf(user)
			if(istype(T))
				T.atmos_spawn_air("nitrogen=40;TEMP=2.7")
			to_chat(user, span_warning("You activate [src], and icy air bursts out of your skin!"))
			return 900

// Silver Extract

/obj/item/slime_extract/silver
	name = "silver slime extract"
	icon_state = "silver"
	activate_reagents = list(/datum/reagent/toxin/plasma,/datum/reagent/water)
	tier = 3

/obj/item/slime_extract/silver/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/food_type = get_random_food()
			var/obj/item/food_item = new food_type
			if(!user.put_in_active_hand(food_item))
				food_item.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [food_item]!"), span_notice("You spit out [food_item]!"))
			return 200

		if(SLIME_ACTIVATE_MAJOR)
			var/drink_type = get_random_drink()
			var/obj/O = new drink_type
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 200

// Yellow Extract

/obj/item/slime_extract/yellow
	name = "yellow slime extract"
	icon_state = "yellow"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)
	tier = 3

/obj/item/slime_extract/yellow/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			if(species.glow_intensity != LUMINESCENT_DEFAULT_GLOW)
				to_chat(user, span_warning("Your glow is already enhanced!"))
				return
			species.update_glow(user, 7)
			addtimer(CALLBACK(species, /datum/species/jelly/luminescent.proc/update_glow, user, LUMINESCENT_DEFAULT_GLOW), 600)
			to_chat(user, span_notice("You start glowing brighter."))

		if(SLIME_ACTIVATE_MAJOR)
			user.visible_message(span_warning("[user]'s skin starts flashing intermittently..."), span_warning("Your skin starts flashing intermittently..."))
			if(do_after(user, 25, target = user))
				empulse(user, 1, 2)
				user.visible_message(span_warning("[user]'s skin flashes!"), span_warning("Your skin flashes as you emit an electromagnetic pulse!"))
				return 600

// ************************************************
// ****************** TIER FOUR *******************
// ************************************************

// Red Extract

/obj/item/slime_extract/red
	name = "red slime extract"
	icon_state = "red"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)
	tier = 4

/obj/item/slime_extract/red/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_notice("You activate [src]. You start feeling fast!"))
			user.reagents.add_reagent(/datum/reagent/medicine/ephedrine,5)
			return 450

		if(SLIME_ACTIVATE_MAJOR)
			user.visible_message(span_warning("[user]'s skin flashes red for a moment..."), span_warning("Your skin flashes red as you emit rage-inducing pheromones..."))
			for(var/mob/living/simple_animal/slime/slime in viewers(get_turf(user), null))
				slime.rabid = TRUE
				slime.visible_message(span_danger("The [slime] is driven into a frenzy!"))
			return 600

// Green Extract

/obj/item/slime_extract/green
	name = "green slime extract"
	icon_state = "green"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/uranium/radium)
	tier = 4

/obj/item/slime_extract/green/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_warning("You feel yourself reverting to human form..."))
			if(do_after(user, 120, target = user))
				to_chat(user, span_warning("You feel human again!"))
				user.set_species(/datum/species/human)
				return
			to_chat(user, span_notice("You stop the transformation."))

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_warning("You feel yourself radically changing your slime type..."))
			if(do_after(user, 120, target = user))
				to_chat(user, span_warning("You feel different!"))
				user.set_species(pick(/datum/species/jelly/slime, /datum/species/jelly/stargazer))
				return
			to_chat(user, span_notice("You stop the transformation."))

// Pink Extract

/obj/item/slime_extract/pink
	name = "pink slime extract"
	icon_state = "pink"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)
	tier = 4

/obj/item/slime_extract/pink/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			if(user.gender != MALE && user.gender != FEMALE)
				to_chat(user, span_warning("You can't swap your gender!"))
				return

			if(user.gender == MALE)
				user.gender = FEMALE
				user.visible_message(span_boldnotice("[user] suddenly looks more feminine!"), span_boldwarning("You suddenly feel more feminine!"))
			else
				user.gender = MALE
				user.visible_message(span_boldnotice("[user] suddenly looks more masculine!"), span_boldwarning("You suddenly feel more masculine!"))
			return 100

		if(SLIME_ACTIVATE_MAJOR)
			user.visible_message(span_warning("[user]'s skin starts flashing hypnotically..."), span_notice("Your skin starts forming odd patterns, pacifying creatures around you."))
			for(var/mob/living/carbon/C in viewers(user, null))
				if(C != user)
					C.reagents.add_reagent(/datum/reagent/pax,2)
			return 600

// Gold Extract

/obj/item/slime_extract/gold
	name = "gold slime extract"
	icon_state = "gold"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)
	tier = 4

/obj/item/slime_extract/gold/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			user.visible_message(span_warning("[user] starts shaking!"),span_notice("Your [name] starts pulsing gently..."))
			if(do_after(user, 40, target = user))
				var/mob/living/spawned_mob = create_random_mob(user.drop_location(), FRIENDLY_SPAWN)
				spawned_mob.faction |= "neutral"
				playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
				user.visible_message(span_warning("[user] spits out [spawned_mob]!"), span_notice("You spit out [spawned_mob]!"))
				return 300

		if(SLIME_ACTIVATE_MAJOR)
			user.visible_message(span_warning("[user] starts shaking violently!"),span_warning("Your [name] starts pulsing violently..."))
			if(do_after(user, 50, target = user))
				var/mob/living/spawned_mob = create_random_mob(user.drop_location(), HOSTILE_SPAWN)
				if(!user.combat_mode)
					spawned_mob.faction |= "neutral"
				else
					spawned_mob.faction |= "slime"
				playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
				user.visible_message(span_warning("[user] spits out [spawned_mob]!"), span_warning("You spit out [spawned_mob]!"))
				return 600


// ************************************************
// ****************** TIER FIVE *******************
// ************************************************

// Cerulean Extract

/obj/item/slime_extract/cerulean
	name = "cerulean slime extract"
	icon_state = "cerulean"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)
	tier = 5

/obj/item/slime_extract/cerulean/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			user.reagents.add_reagent(/datum/reagent/medicine/salbutamol,15)
			to_chat(user, span_notice("You feel like you don't need to breathe!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			var/turf/open/T = get_turf(user)
			if(istype(T))
				T.atmos_spawn_air("o2=11;n2=41;TEMP=293.15")
				to_chat(user, span_warning("You activate [src], and fresh air bursts out of your skin!"))
				return 600

// Sepia Extract

/obj/item/slime_extract/sepia
	name = "sepia slime extract"
	icon_state = "sepia"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,/datum/reagent/water)
	tier = 5

/obj/item/slime_extract/sepia/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/obj/item/camera/O = new(null, 1)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_warning("You feel time slow down..."))
			if(do_after(user, 30, target = user))
				new /obj/effect/timestop(get_turf(user), 2, 50, list(user))
				return 900

// Pyrite Extract

/obj/item/slime_extract/pyrite
	name = "pyrite slime extract"
	icon_state = "pyrite"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)
	tier = 5

/obj/item/slime_extract/pyrite/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/chosen = pick(difflist(subtypesof(/obj/item/toy/crayon),typesof(/obj/item/toy/crayon/spraycan)))
			var/obj/item/O = new chosen(null)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			var/blacklisted_cans = list(/obj/item/toy/crayon/spraycan/borg, /obj/item/toy/crayon/spraycan/infinite)
			var/chosen = pick(subtypesof(/obj/item/toy/crayon/spraycan) - blacklisted_cans)
			var/obj/item/O = new chosen(null)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 250

// Bluespace Extract

/obj/item/slime_extract/bluespace
	name = "bluespace slime extract"
	icon_state = "bluespace"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)
	tier = 5
	var/teleport_ready = FALSE
	var/teleport_x = 0
	var/teleport_y = 0
	var/teleport_z = 0

/obj/item/slime_extract/bluespace/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_warning("You feel your body vibrating..."))
			if(do_after(user, 25, target = get_turf(user)))
				to_chat(user, span_warning("You teleport!"))
				do_teleport(user, get_turf(user), 6, asoundin = 'sound/weapons/emitter2.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)
				return 300

		if(SLIME_ACTIVATE_MAJOR)
			if(!teleport_ready)
				to_chat(user, span_notice("You feel yourself anchoring to this spot..."))
				var/turf/T = get_turf(user)
				teleport_x = T.x
				teleport_y = T.y
				teleport_z = T.z
				teleport_ready = TRUE
			else
				playsound(user, 'sound//magic/lightning_chargeup.ogg', 75, TRUE)
				if(!do_after(user, 40, target = get_turf(user)))
					return 250
				teleport_ready = FALSE
				if(teleport_x && teleport_y && teleport_z)
					var/turf/T = locate(teleport_x, teleport_y, teleport_z)
					to_chat(user, span_notice("You snap back to your anchor point!"))
					do_teleport(user, T,  asoundin = 'sound/weapons/emitter2.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)
					return 450


// ************************************************
// ******************* TIER SIX *******************
// ************************************************

// Oil Extract

/obj/item/slime_extract/oil
	name = "oil slime extract"
	icon_state = "oil"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma)
	tier = 6

/obj/item/slime_extract/oil/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_warning("You vomit slippery oil."))
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			new /obj/effect/decal/cleanable/oil/slippery(get_turf(user))
			return 450

		if(SLIME_ACTIVATE_MAJOR)
			user.visible_message(span_warning("[user]'s skin starts pulsing and glowing ominously..."), span_userdanger("You feel unstable..."))
			if(do_after(user, 60, target = user))
				to_chat(user, span_userdanger("You explode!"))
				explosion(user, devastation_range = 1, heavy_impact_range = 3, light_impact_range = 6, explosion_cause = src)
				user.gib()
				return
			to_chat(user, span_notice("You stop feeding [src], and the feeling passes."))

// Black Extract

/obj/item/slime_extract/black
	name = "black slime extract"
	icon_state = "black"
	activate_reagents = list(/datum/reagent/toxin/plasma)
	tier = 6

/obj/item/slime_extract/black/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			to_chat(user, span_userdanger("You feel something <i>wrong</i> inside you..."))
			user.ForceContractDisease(new /datum/disease/transformation/slime(), FALSE, TRUE)
			return 100

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_warning("You feel your own light turning dark..."))
			if(do_after(user, 120, target = user))
				to_chat(user, span_warning("You feel a longing for darkness."))
				user.set_species(pick(/datum/species/shadow))
				return
			to_chat(user, span_notice("You stop feeding [src]."))

// Adamantine Extract

/obj/item/slime_extract/adamantine
	name = "adamantine slime extract"
	icon_state = "adamantine"
	activate_reagents = list(/datum/reagent/toxin/plasma)
	tier = 6

/obj/item/slime_extract/adamantine/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			if(species.armor > 0)
				to_chat(user, span_warning("Your skin is already hardened!"))
				return
			to_chat(user, span_notice("You feel your skin harden and become more resistant."))
			species.armor += 25
			addtimer(CALLBACK(src, .proc/reset_armor, species), 1200)
			return 450

		if(SLIME_ACTIVATE_MAJOR)
			to_chat(user, span_warning("You feel your body rapidly crystallizing..."))
			if(do_after(user, 120, target = user))
				to_chat(user, span_warning("You feel solid."))
				user.set_species(pick(/datum/species/golem/adamantine))
				return
			to_chat(user, span_notice("You stop feeding [src], and your body returns to its slimelike state."))

/obj/item/slime_extract/adamantine/proc/reset_armor(datum/species/jelly/luminescent/species)
	if(istype(species))
		species.armor -= 25

// Light Pink Extrat

/obj/item/slime_extract/lightpink
	name = "light pink slime extract"
	icon_state = "light_pink"
	activate_reagents = list(/datum/reagent/toxin/plasma)
	tier = 6

/obj/item/slime_extract/lightpink/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			var/obj/item/slimepotion/slime/renaming/O = new(null, 1)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150

		if(SLIME_ACTIVATE_MAJOR)
			var/obj/item/slimepotion/slime/sentience/O = new(null, 1)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 450


// ************************************************
// ****************** TIER SEVEN ******************
// ************************************************

// Rainbow Extract

/obj/item/slime_extract/rainbow
	name = "rainbow slime extract"
	icon_state = "rainbow"
	activate_reagents = list(/datum/reagent/blood,/datum/reagent/toxin/plasma,"lesser plasma",/datum/reagent/toxin/slimejelly,"holy water and uranium") //Curse this snowflake reagent list.
	tier = 7

/obj/item/slime_extract/rainbow/activate(mob/living/carbon/human/user, datum/species/jelly/luminescent/species, activation_type)
	switch(activation_type)
		if(SLIME_ACTIVATE_MINOR)
			user.dna.features["mcolor"] = "#[pick("7F", "FF")][pick("7F", "FF")][pick("7F", "FF")]"
			user.dna.update_uf_block(DNA_MUTANT_COLOR_BLOCK)
			user.updateappearance(mutcolor_update=1)
			species.update_glow(user)
			to_chat(user, span_notice("You feel different..."))
			return 100

		if(SLIME_ACTIVATE_MAJOR)
			var/chosen = pick(subtypesof(/obj/item/slime_extract))
			var/obj/item/O = new chosen(null)
			if(!user.put_in_active_hand(O))
				O.forceMove(user.drop_location())
			playsound(user, 'sound/effects/splat.ogg', 50, TRUE)
			user.visible_message(span_warning("[user] spits out [O]!"), span_notice("You spit out [O]!"))
			return 150
