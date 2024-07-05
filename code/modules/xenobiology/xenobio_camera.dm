/obj/machinery/computer/camera_advanced/xenobio
	name = "Slime management console"
	desc = "A computer used for remotely handling slimes."
	networks = list(CAMERANET_NETWORK_SS13)
	circuit = /obj/item/circuitboard/computer/xenobiology

	///The recycler connected to the camera console
	var/obj/machinery/monkey_recycler/connected_recycler
	///The slimes stored inside the console
	var/list/stored_slimes
	///The single slime potion stored inside the console
	var/obj/item/slimepotion/slime/current_potion
	///The maximum amount of slimes that fit in the machine
	var/max_slimes = 5
	///The amount of monkey cubes inside the machine
	var/monkeys = 0

	icon_screen = "slime_comp"
	icon_keyboard = "rd_key"

	light_color = LIGHT_COLOR_PINK
