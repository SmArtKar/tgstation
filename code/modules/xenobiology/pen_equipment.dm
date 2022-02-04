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

/obj/item/wallframe/space_heater
	name = "\improper space heater frame"
	desc = "A space heater detached from a wall."
	icon_state = "apc"

	icon_state = "space_heater"
	pixel_shift = 29
	result_path = /obj/machinery/space_heater/wall_mount
