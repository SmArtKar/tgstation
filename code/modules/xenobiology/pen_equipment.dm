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

	new /obj/item/slime_discharger(get_turf(src))
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

/obj/item/slime_discharger
	name = "slime discharger"
	desc = "Prevents all living beings from being electrocuted by those nasty yellow slimes."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "discharger-off"
	w_class = WEIGHT_CLASS_NORMAL
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'

/obj/item/slime_discharger/attack_self(mob/user, modifiers)
	. = ..()
	if(loc == user)
		if(!user.temporarilyRemoveItemFromInventory(src))
			to_chat(user, span_warning("[src] is stuck to your hands!"))
			return

	playsound(get_turf(src), 'sound/machines/click.ogg', 75, TRUE)
	to_chat(user, span_notice("You put [src] down and it attaches itself to [loc]."))
	new /obj/machinery/power/energy_accumulator/slime_discharger(get_turf(src))
	for(var/turf/discharge_turf in range(2, get_turf(src)))
		new /obj/effect/temp_visual/xenobio_blast/discharger(discharge_turf)
	qdel(src)

/obj/effect/temp_visual/xenobio_blast/discharger
	name = "discharger field"
	color = COLOR_YELLOW

#undef DISCHARGE_PROB
#undef DISCHARGE_EFFECT_PROB

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
