#define HOVERFAB_REPAIR_INTACT 0
#define HOVERFAB_REPAIR_COIL 1
#define HOVERFAB_REPAIR_PLASTEEL 2
#define HOVERFAB_REPAIR_WELDING 3

#define HOVERFAB_STATE_INACTIVE 0
#define HOVERFAB_STATE_ACTIVATED 1
#define HOVERFAB_STATE_OPEN 2
#define HOVERFAB_STATE_PROCESSING 3

/// Hoverfabricator: A small side-quest for maintenance dwellers (assistants or bored engineers) to do.
/// You need to repair it with cable coils, plasteel and a welder and then win 3 rounds of Simon Says in order to unlock it
/// Give it some planks, cable coil, a capacitor and a couple of lightbulbs to get a fancy fast hoverboard that can knock people down
/obj/machinery/hoverfab
	name = "abandoned fabricator"
	desc = "A long-discarded H0V-E5 type autofabricator. Such models of fabricators was mostly used to print personal \
	entertainment items, such as toys and gadgets, before being discontinued in 2549 due to faulty extrusion mechanisms. \
	This particular fabricator seems to have a hololock installed in order to prevent unauthorized access."
	icon = 'icons/obj/machines/hoverfab.dmi'
	icon_state = "hoverfab_locked"
	base_icon_state = "hoverfab"
	density = TRUE
	pixel_x = -8
	base_pixel_x = -8
	// Doesn't have a circuit to prevent repair cheese
	/// What is this fabricator's current repair state
	var/repair_state = HOVERFAB_REPAIR_INTACT
	/// What is our hoverfab's activation state
	var/current_state = HOVERFAB_STATE_INACTIVE
	/// Emissive overlay, stored so we can flick it for animations
	var/mutable_appearance/emissive_overlay

/obj/machinery/hoverfab/broken
	repair_state = HOVERFAB_REPAIR_COIL

/obj/machinery/hoverfab/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/machinery/hoverfab/Destroy(force)
	emissive_overlay = null
	return ..()

/obj/machinery/hoverfab/examine(mob/user)
	. = ..()
	switch (repair_state)
		if (HOVERFAB_REPAIR_COIL)
			. += span_notice("Torn wiring is poking out from underneath its unresponsive LEDs. Some <b>cable coil</b> should do the trick.")
		if (HOVERFAB_REPAIR_PLASTEEL)
			. += span_notice("Its top panel is cracked and doesn't seem to budge. Maybe you could repair it with some <b>plasteel</b>...")
		if (HOVERFAB_REPAIR_WELDING)
			. += span_notice("Its casing is in a pretty rough shape and has some severe dents in it, jamming the lid. You could probably straighten it out after <b>heating the metal up</b>.")

/obj/machinery/hoverfab/update_icon_state()
	. = ..()
	if (repair_state)
		icon_state = "[base_icon_state]_busted_[repair_state]"
		return

	switch (current_state)
		if (HOVERFAB_STATE_INACTIVE)
			icon_state = "[base_icon_state]_locked"
		if (HOVERFAB_STATE_ACTIVATED)
			icon_state = "[base_icon_state]_active"
		if (HOVERFAB_STATE_OPEN)
			icon_state = "[base_icon_state]_open"
		if (HOVERFAB_STATE_PROCESSING)
			icon_state = "[base_icon_state]_processing"

/obj/machinery/hoverfab/update_overlays()
	. = ..()
	if (repair_state || current_state == HOVERFAB_STATE_INACTIVE)
		return
	emissive_overlay = emissive_appearance(icon, "[icon_state]_e", src)
	. += emissive_overlay

/obj/machinery/hoverfab/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if (!repair_state)
		return

	var/item_type
	var/balloon_message
	var/amount
	switch (repair_state)
		if (HOVERFAB_REPAIR_COIL)
			item_type = /obj/item/stack/cable_coil
			balloon_message = "wiring is torn!"
			amount = 5
		if (HOVERFAB_REPAIR_PLASTEEL)
			item_type = /obj/item/stack/sheet/plasteel
			balloon_message = "top panel is cracked!"
			amount = 3
		if (HOVERFAB_REPAIR_WELDING)
			item_type = TOOL_WELDER
			balloon_message = "casing is dented!"
			amount = 10

	if (ispath(item_type) ? !istype(tool, item_type) : tool.tool_behaviour != item_type)
		balloon_alert(user, balloon_message)
		return ITEM_INTERACT_BLOCKING

	if(!tool.use_tool(src, user, 5 SECONDS, amount = amount, volume = 50))
		balloon_alert(user, "interrupted!")
		return ITEM_INTERACT_BLOCKING

	if (repair_state == HOVERFAB_REPAIR_WELDING)
		repair_state = HOVERFAB_REPAIR_INTACT
	else
		repair_state += 1

	update_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/machinery/hoverfab/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if (repair_state)
		return

	if (current_state == HOVERFAB_STATE_INACTIVE)
		current_state = HOVERFAB_STATE_ACTIVATED
		update_appearance()
		flick("[base_icon_state]_started", src)
		if (emissive_overlay)
			flick("[base_icon_state]_started_e", emissive_overlay)
		playsound(src, 'sound/machines/compiler/compiler-stage2.ogg', 50)
		return

#undef HOVERFAB_REPAIR_INTACT
#undef HOVERFAB_REPAIR_COIL
#undef HOVERFAB_REPAIR_PLASTEEL
#undef HOVERFAB_REPAIR_WELDING

#undef HOVERFAB_STATE_INACTIVE
#undef HOVERFAB_STATE_ACTIVATED
#undef HOVERFAB_STATE_OPEN
#undef HOVERFAB_STATE_PROCESSING
