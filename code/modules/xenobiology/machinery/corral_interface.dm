/obj/item/slime_corral_interface
	name = "corral management interface"
	desc = "A specialized tablet fitted with a multitude of xenobiological scanners, intended to keep track of living organisms in a small area."
	icon = 'icons/obj/science/xenobiology.dmi'
	icon_state = "corral_interface_item"

	/// Emissive overlay for the screen
	var/mutable_appearance/screen_emissive
	/// ID for mappers. Allows to set up pens roundstart using corral helpers
	var/mapping_id

/obj/item/slime_corral_interface/Initialize(mapload)
	. = ..()
	desc += " It has [span_boldnotice("pylon attachment points")] and [span_boldnotice("small bolts for securing it to the floor")]."
	update_appearance()

/obj/item/slime_corral_interface/update_overlays()
	. = ..()
	if (isnull(screen_emissive))
		screen_emissive = emissive_appearance(icon, "corral_interface_item_emissive", src)
	. += screen_emissive

/obj/item/slime_corral_interface/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if (!istype(interacting_with, /obj/machinery/corral_generator))
		return NONE

	var/obj/machinery/corral_generator/generator = interacting_with
	forceMove(generator)
	balloon_alert(user, "interface attached")
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	generator.attached_interface = src
	generator.interface_direction = get_dir(generator, user)
	generator.corner_status[get_dir(generator, user)] = FALSE
	generator.update_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/item/slime_corral_interface/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CorralInterface", name)
		ui.open()
