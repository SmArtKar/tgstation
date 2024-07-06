#define CORRAL_INTERFACE_NORTH_OFFSET 3

/obj/item/slime_corral_interface
	name = "corral management interface"
	desc = "A specialized tablet fitted with a multitude of xenobiological scanners, intended to keep track of living organisms in a small area."
	icon = 'icons/obj/science/xenobiology.dmi'
	icon_state = "corral_interface_item"
	base_icon_state = "corral_interface_item"

	/// ID for mappers. Allows to set up pens roundstart using corral helpers
	var/mapping_id
	/// Pylon that we are currently attached to, if any
	var/obj/machinery/corral_generator/generator

/obj/item/slime_corral_interface/Initialize(mapload)
	. = ..()
	desc += " It has [span_boldnotice("pylon attachment points")] and [span_boldnotice("small bolts for securing it to the floor")]."
	update_appearance()

/obj/item/slime_corral_interface/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_emissive", src)

/obj/item/slime_corral_interface/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if (!istype(interacting_with, /obj/machinery/corral_generator))
		return NONE

	generator = interacting_with
	forceMove(generator)
	balloon_alert(user, "interface attached")
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	var/attach_dir = get_dir(generator, user)
	switch (attach_dir)
		if (SOUTHEAST)
			attach_dir = SOUTH
		if (SOUTHWEST)
			attach_dir = SOUTH
		if (NORTHWEST)
			attach_dir = WEST
		if (NORTHEAST)
			attach_dir = EAST
	generator.attached_interface = src
	generator.interface_direction = attach_dir
	generator.corner_status["[attach_dir]"] = FALSE
	setDir(attach_dir)
	generator.setDir(attach_dir)
	update_appearance()
	generator.update_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/item/slime_corral_interface/update_icon_state()
	if (isnull(generator))
		icon_state = base_icon_state
		return ..()

	icon_state = "corral_interface"
	pixel_x = 0
	pixel_w = 0
	pixel_y = (generator.interface_direction == NORTH ? CORRAL_INTERFACE_NORTH_OFFSET : 0)
	pixel_z = 0
	return ..()

/obj/item/slime_corral_interface/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CorralInterface", name)
		ui.open()

#undef CORRAL_INTERFACE_NORTH_OFFSET
