/obj/item/xenobio_deployable
	var/deployable_type

/obj/item/xenobio_deployable/attack_self(mob/user, modifiers)
	. = ..()
	if(loc == user)
		if(!user.temporarilyRemoveItemFromInventory(src))
			to_chat(user, span_warning("[src] is stuck to your hands!"))
			return

	deploy(user, modifiers)

/obj/item/xenobio_deployable/proc/deploy(mob/user, modifiers)
	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	to_chat(user, span_notice("You put [src] down and it attaches itself to [loc]."))
	new deployable_type(get_turf(src))
	qdel(src)

#define DISCHARGE_PROB 30
#define DISCHARGE_EFFECT_PROB 65

/obj/machinery/power/energy_accumulator/slime_discharger
	name = "slime discharger"
	desc = "Prevents all living beings from being electrocuted by those nasty yellow slimes."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "discharger-off"
	base_icon_state = "discharger"
	anchored = TRUE
	density = TRUE
	wants_powernet = FALSE
	can_buckle = FALSE
	var/on = FALSE

/obj/machinery/power/energy_accumulator/slime_discharger/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads:<br>" + \
		  "Recently grounded <b>[display_joules(get_stored_joules())]</b>.<br>" + \
			"This energy would sustainably release <b>[display_power(get_power_output())]</b>.")

/obj/machinery/power/energy_accumulator/slime_discharger/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. != SUCCESSFUL_UNFASTEN)
		return

	new /obj/item/xenobio_deployable/slime_discharger(get_turf(src))
	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	to_chat(user, span_notice("You undo the bolts on [src], detaching it from the floor."))
	qdel(src)

/obj/machinery/power/energy_accumulator/slime_discharger/process()
	for(var/mob/living/simple_animal/slime/slime in range(2, src))
		if(slime.slime_color.slime_tags & DISCHARGER_WEAKENED)
			slime.adjust_nutrition(-1)

		if(slime.powerlevel > 2 && prob(DISCHARGE_PROB))
			slime.powerlevel = round(slime.powerlevel / 2)
			if(prob(DISCHARGE_EFFECT_PROB))
				Beam(slime, icon_state="lightning[rand(1,12)]", time = 5)

/obj/machinery/power/energy_accumulator/slime_discharger/update_icon_state()
	icon_state = "[base_icon_state][on ? "" : "-off"]"
	return ..()

/obj/machinery/power/energy_accumulator/slime_discharger/attackby(obj/item/W, mob/user, params)
	if(default_unfasten_wrench(user, W))
		return

	return ..()

/obj/machinery/power/energy_accumulator/slime_discharger/zap_act(power, zap_flags)
	if(on)
		flick("discharger-shock", src)
		stored_energy += joules_to_energy((power) * 400)
		return 0
	else
		. = ..()

/obj/item/xenobio_deployable/slime_discharger
	name = "slime discharger"
	desc = "Prevents all living beings from being electrocuted by those nasty yellow slimes."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "discharger-off"
	w_class = WEIGHT_CLASS_NORMAL
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	deployable_type = /obj/machinery/vacuole_stabilizer

/obj/item/xenobio_deployable/slime_discharger/deploy(mob/user, modifiers)
	for(var/turf/discharger_turf in range(2, get_turf(src)))
		new /obj/effect/temp_visual/xenobio_blast/discharger(discharger_turf)
	. = ..()

/obj/effect/temp_visual/xenobio_blast/discharger
	name = "discharger field"
	color = COLOR_YELLOW

#undef DISCHARGE_PROB
#undef DISCHARGE_EFFECT_PROB

/obj/machinery/vacuole_stabilizer
	name = "vacuole stabilizer"
	desc = "This device prevents silver slimes from imploding and splitting into blorbies."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "stabilizer-off"
	base_icon_state = "stabilizer"
	anchored = TRUE
	density = TRUE
	var/on = FALSE

/obj/machinery/vacuole_stabilizer/update_icon_state()
	icon_state = "[base_icon_state][on ? "" : "-off"]"
	return ..()

/obj/machinery/vacuole_stabilizer/attackby(obj/item/W, mob/user, params)
	if(default_unfasten_wrench(user, W))
		return

	return ..()

/obj/machinery/vacuole_stabilizer/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. != SUCCESSFUL_UNFASTEN)
		return

	new /obj/item/xenobio_deployable/vacuole_stabilizer(get_turf(src))
	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	to_chat(user, span_notice("You undo the bolts on [src], detaching it from the floor."))
	qdel(src)

/obj/item/xenobio_deployable/vacuole_stabilizer
	name = "vacuole stabilizer"
	desc = "This device prevents silver slimes from imploding and splitting into blorbies."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "stabilizer-off"
	w_class = WEIGHT_CLASS_NORMAL
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	deployable_type = /obj/machinery/vacuole_stabilizer

/obj/item/xenobio_deployable/vacuole_stabilizer/deploy(mob/user, modifiers)
	for(var/turf/stabilizer_turf in range(3, get_turf(src)))
		new /obj/effect/temp_visual/xenobio_blast/vacuole_stabilizer(stabilizer_turf)
	. = ..()

/obj/effect/temp_visual/xenobio_blast/vacuole_stabilizer
	name = "vacuole stabilizer field"
	color = COLOR_WHITE

/obj/item/wallframe/space_heater
	name = "\improper space heater frame"
	desc = "A space heater detached from a wall."
	icon_state = "space_heater"
	pixel_shift = 29
	result_path = /obj/machinery/space_heater/wall_mount

/obj/machinery/space_heater/wall_mount
	icon = 'icons/obj/xenobiology/machinery.dmi'
	anchored = TRUE
	density = FALSE
	use_power = TRUE
	use_cell = FALSE
	cell = null

/obj/machinery/space_heater/wall_mount/default_unfasten_wrench(mob/user, obj/item/wrench, time)
	. = ..()

	if(. != SUCCESSFUL_UNFASTEN)
		return

	new /obj/item/wallframe/space_heater(get_turf(src))
	qdel(src)

/obj/item/xenobio_deployable/bluespace_anchor
	name = "bluespace anchor"
	desc = "This device blocks low-power bluespace teleportation used by bluespace slimes, preventing them from escaping from their cells."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "bluespace_anchor-off"
	w_class = WEIGHT_CLASS_NORMAL
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	deployable_type = /obj/machinery/bluespace_anchor

/obj/effect/temp_visual/xenobio_blast/bluespace
	name = "bluespace stabilizer field"
	color = COLOR_CYAN

/obj/machinery/bluespace_anchor
	name = "bluespace anchor"
	desc = "This device blocks low-power bluespace teleportation used by bluespace slimes, preventing them from escaping from their cells."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "bluespace_anchor-off"
	base_icon_state = "bluespace_anchor"
	anchored = TRUE
	density = FALSE
	var/on = FALSE
	var/list/affected_turfs = list()
	var/list/visual_effects = list()

/obj/machinery/bluespace_anchor/Destroy()
	toggle(FALSE)
	. = ..()

/obj/machinery/bluespace_anchor/proc/toggle(new_state = TRUE)
	on = new_state
	update_icon()

	if(!on)
		for(var/turf/turf in affected_turfs)
			REMOVE_TRAIT(turf, TRAIT_NO_SLIME_TELEPORTATION, XENOBIO_DEPLOYABLE_TRAIT)

		for(var/atom/effect in visual_effects)
			qdel(effect)

		return

	var/list/turfs = detect_room(get_turf(src), list(/turf/open/space), 100)
	var/list/pen_turfs = list()
	for(var/turf/turf in turfs)
		var/is_pen = TRUE
		for(var/direction in GLOB.alldirs)
			if(!(get_step(turf, direction) in turfs))
				is_pen = FALSE
				break

		if(isclosedturf(turf))
			is_pen = FALSE

		if(is_pen)
			pen_turfs += turf

	if(!pen_turfs)
		break_off()
		return

	if(length(pen_turfs) > MAXIMUM_SLIME_PEN_SIZE)
		break_off()
		return

	for(var/turf/pen_turf in pen_turfs)
		new /obj/effect/temp_visual/xenobio_blast/bluespace(pen_turf)
		affected_turfs += pen_turf
		ADD_TRAIT(pen_turf, TRAIT_NO_SLIME_TELEPORTATION, XENOBIO_DEPLOYABLE_TRAIT)

	sleep(2)

	for(var/turf/pen_turf in pen_turfs)
		var/list/non_pen_dirs = list()
		for(var/direction in GLOB.alldirs)
			if(!(get_step(pen_turf, direction) in pen_turfs))
				non_pen_dirs += direction

		if(LAZYLEN(non_pen_dirs))
			var/list/cardinal_dirs = list()
			for(var/card in GLOB.cardinals)
				if(card in non_pen_dirs)
					cardinal_dirs += card


			var/list/diagonal_dirs = list()
			for(var/diag in GLOB.diagonals)
				if(diag in non_pen_dirs)
					diagonal_dirs += diag

			if(LAZYLEN(cardinal_dirs))
				switch(LAZYLEN(cardinal_dirs))
					if(1)
						var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
						visual_effects += edge
						edge.dir = cardinal_dirs[1]
						if(cardinal_dirs[1] in list(NORTH, SOUTH))
							diagonal_dirs -= EAST | cardinal_dirs[1]
							diagonal_dirs -= WEST | cardinal_dirs[1]
						else
							diagonal_dirs -= NORTH | cardinal_dirs[1]
							diagonal_dirs -= SOUTH | cardinal_dirs[1]
					if(2)
						if(turn(cardinal_dirs[1], 180) == cardinal_dirs[2])
							var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
							visual_effects += edge
							edge.dir = cardinal_dirs[1]

							edge = new(pen_turf)
							visual_effects += edge
							edge.dir = cardinal_dirs[2]

							diagonal_dirs = list()
						else
							var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
							visual_effects += edge
							edge.dir = cardinal_dirs[1] | cardinal_dirs[2]
							if(turn(cardinal_dirs[1] | cardinal_dirs[2], 180) in diagonal_dirs)
								diagonal_dirs = list(turn(cardinal_dirs[1] | cardinal_dirs[2], 180))
							else
								diagonal_dirs = list()
					if(3)
						if((NORTH in cardinal_dirs) && (SOUTH in cardinal_dirs))
							cardinal_dirs -= NORTH
							cardinal_dirs -= SOUTH
						else
							cardinal_dirs -= EAST
							cardinal_dirs -= WEST


						var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
						visual_effects += edge
						edge.icon_state = "bluespace_field_end"
						edge.dir = cardinal_dirs[1]
						edge.update_icon()
						diagonal_dirs = list()
					if(4)
						var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
						visual_effects += edge
						edge.icon_state = "bluespace_field"
						edge.update_icon()
						diagonal_dirs = list()

			if(LAZYLEN(diagonal_dirs))
				for(var/diag_dir in diagonal_dirs)
					var/obj/effect/bluespace_field_edge/edge = new(pen_turf)
					visual_effects += edge
					edge.dir = diag_dir
					edge.icon_state = "bluespace_field_corner"
					edge.update_icon()

/obj/effect/bluespace_field_edge
	icon_state = "bluespace_field_edge"

/obj/machinery/bluespace_anchor/proc/break_off()
	new /obj/item/xenobio_deployable/bluespace_anchor(get_turf(src))
	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	visible_message(span_warning("[src] fails to boot up and detaches itself from the floor."))
	qdel(src)

/obj/machinery/bluespace_anchor/update_icon_state()
	icon_state = "[base_icon_state][on ? "" : "-off"]"
	return ..()

/obj/machinery/bluespace_anchor/attackby(obj/item/W, mob/user, params)
	if(default_unfasten_wrench(user, W))
		return

	return ..()

/obj/machinery/bluespace_anchor/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. != SUCCESSFUL_UNFASTEN)
		return

	new /obj/item/xenobio_deployable/bluespace_anchor(get_turf(src))
	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	to_chat(user, span_notice("You undo the bolts on [src], detaching it from the floor."))
	qdel(src)
