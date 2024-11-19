#define HOVERFAB_REPAIR_INTACT 0
#define HOVERFAB_REPAIR_COIL 1
#define HOVERFAB_REPAIR_PLASTEEL 2
#define HOVERFAB_REPAIR_WELDING 3

#define HOVERFAB_STATE_INACTIVE 0
#define HOVERFAB_STATE_ACTIVATED 1
#define HOVERFAB_STATE_OPEN 2
#define HOVERFAB_STATE_PROCESSING 3

/// How many answers in a row you need to give. Increased by the number of subsequently won rounds.
#define HOVERFAB_BASE_ROUNDS 4
/// Delay between each color
#define HOVERFAB_BASE_DELAY 0.8 SECONDS
/// How much delay is deducted for every won round
#define HOVERFAB_DELAY_REDUCTION 0.15 SECONDS
/// How long it takes for a hoverfab to produce an item
#define HOVERFAB_PRODUCTION_TIME 10 SECONDS

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
	/// How many rounds of Simon Says have been won so far?
	var/won_rounds = 0
	/// Is there an active game going on?
	var/active_game = FALSE
	/// Emissive overlay, stored so we can flick it for animations
	var/mutable_appearance/emissive_overlay
	/// Processing sound loop. This is basically a fancy microwave from player's perspective anyways.
	var/datum/looping_sound/microwave/soundloop
	/// What sort of items we're producing
	var/created_type
	/// Items required to produce a hoverboard
	var/static/list/required_items = list(
		/obj/item/stack/sheet/mineral/wood = 5,
		/obj/item/stack/cable_coil = MAXCOIL,
		/obj/item/light/bulb = 2,
		/obj/item/stock_parts/capacitor = 1,
	)

/obj/machinery/hoverfab/broken
	repair_state = HOVERFAB_REPAIR_COIL

/obj/machinery/hoverfab/debug
	current_state = HOVERFAB_STATE_ACTIVATED
	won_rounds = 3

/obj/machinery/hoverfab/Initialize(mapload)
	. = ..()
	soundloop = new(src, FALSE)
	update_appearance()

/obj/machinery/hoverfab/Destroy(force)
	emissive_overlay = null
	QDEL_NULL(soundloop)
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

	if (current_state != HOVERFAB_STATE_OPEN)
		return

	var/list/missing_items = get_missing_items()
	if (!length(missing_items))
		return

	. += span_notice("[src] needs the following items before it can initiate the printing process:")

	for (var/atom/missed_item as anything in missing_items)
		. += span_notice("[missed_item::name]: [required_items[missed_item] - missing_items[missed_item]]/[required_items[missed_item]]")

/obj/machinery/hoverfab/proc/get_missing_items()
	var/list/missing_items = required_items.Copy()
	for (var/atom/something as anything in contents)
		var/found_type = null
		for (var/req_type in missing_items)
			if (istype(something, req_type))
				found_type = req_type
				break

		if (!found_type)
			continue

		if (isstack(something))
			var/obj/item/stack/stack_something = something
			missing_items[found_type] -= stack_something.amount
		else
			missing_items[found_type] -= 1

		if (missing_items[found_type] <= 0)
			missing_items -= found_type
	return missing_items

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

	if (current_state == HOVERFAB_STATE_PROCESSING)
		return

	if (current_state == HOVERFAB_STATE_ACTIVATED)
		for (var/i in 1 to won_rounds)
			var/mutable_appearance/bar_app = mutable_appearance(icon, "[base_icon_state]_bar", offset_spokesman = src)
			var/mutable_appearance/bar_emm = emissive_appearance(icon, "[base_icon_state]_bar_e", src)
			bar_app.pixel_y += (i - 1) * 3
			bar_emm.pixel_y += (i - 1) * 3
			. += bar_app
			. += bar_emm
		return

	if (locate(/obj/item/stack/sheet/mineral/wood) in contents)
		. += mutable_appearance(icon, "[base_icon_state]_contents_planks", offset_spokesman = src)
	if (locate(/obj/item/stack/cable_coil) in contents)
		. += mutable_appearance(icon, "[base_icon_state]_contents_cable", offset_spokesman = src)
	if (locate(/obj/item/light/bulb) in contents)
		. += mutable_appearance(icon, "[base_icon_state]_contents_lightbulbs", offset_spokesman = src)
	if (locate(/obj/item/stock_parts/capacitor) in contents)
		. += mutable_appearance(icon, "[base_icon_state]_contents_capacitor", offset_spokesman = src)

/obj/machinery/hoverfab/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if (!repair_state)
		var/list/missing_items = get_missing_items()
		var/found_type = null
		for (var/req_type in missing_items)
			if (istype(tool, req_type))
				found_type = req_type
				break

		if (!found_type)
			return

		if (!isstack(tool))
			if(!user.temporarilyRemoveItemFromInventory(tool))
				return ITEM_INTERACT_BLOCKING
			balloon_alert(user, "item inserted")
			tool.forceMove(src)
			update_appearance()
			return ITEM_INTERACT_SUCCESS

		var/obj/item/stack/tool_stack = tool
		if (tool_stack.amount > missing_items[found_type])
			tool_stack = tool_stack.split_stack(amount = missing_items[found_type])
		else
			if(!user.temporarilyRemoveItemFromInventory(tool_stack))
				return ITEM_INTERACT_BLOCKING
		balloon_alert(user, "item inserted")
		tool_stack.forceMove(src)
		update_appearance()
		return ITEM_INTERACT_SUCCESS

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
		balloon_alert(user, balloon_message, starting_x = 8)
		return ITEM_INTERACT_BLOCKING

	if(!tool.use_tool(src, user, 5 SECONDS, amount = amount, volume = 50))
		balloon_alert(user, "interrupted!", starting_x = 8)
		return ITEM_INTERACT_BLOCKING

	if (repair_state == HOVERFAB_REPAIR_WELDING)
		repair_state = HOVERFAB_REPAIR_INTACT
	else
		repair_state += 1

	update_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/machinery/hoverfab/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if (repair_state || current_state == HOVERFAB_STATE_PROCESSING)
		return

	if (current_state == HOVERFAB_STATE_INACTIVE)
		current_state = HOVERFAB_STATE_ACTIVATED
		update_appearance()
		flick("[base_icon_state]_started", src)
		if (emissive_overlay)
			flick("[base_icon_state]_started_e", emissive_overlay)
		playsound(src, 'sound/machines/compiler/compiler-stage2.ogg', 50)
		return

	if (current_state == HOVERFAB_STATE_OPEN)
		if (length(get_missing_items()))
			return
		current_state = HOVERFAB_STATE_PROCESSING
		update_appearance()
		flick("[base_icon_state]_closing", src)
		if (emissive_overlay)
			flick("[base_icon_state]_closing_e", emissive_overlay)
		playsound(src, 'sound/machines/compiler/compiler-stage1.ogg', 50)
		addtimer(CALLBACK(soundloop, TYPE_PROC_REF(/datum/soundloop, start)), 2.5 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(finish_processing)), HOVERFAB_PRODUCTION_TIME)
		return

	if (active_game)
		playsound(src, 'sound/machines/uplink/uplinkerror.ogg', 50)
		return

	if (won_rounds >= 3)
		current_state = HOVERFAB_STATE_OPEN
		update_appearance()
		flick("[base_icon_state]_opening", src)
		if (emissive_overlay)
			flick("[base_icon_state]_opening_e", emissive_overlay)
		playsound(src, 'sound/machines/scanner/scanner.ogg', 50, TRUE)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), src, 'sound/machines/gateway/gateway_calibrated.ogg', 30, -3), 2.4 SECONDS)
		return

	INVOKE_ASYNC(src, PROC_REF(play_round), user)

/obj/machinery/hoverfab/proc/finish_processing()
	soundloop.stop()
	current_state = HOVERFAB_STATE_OPEN
	update_appearance()
	flick("[base_icon_state]_opening", src)
	if (emissive_overlay)
		flick("[base_icon_state]_opening_e", emissive_overlay)
	playsound(src, 'sound/machines/scanner/scanner.ogg', 50, TRUE)
	addtimer(CALLBACK(src, PROC_REF(create_board)), 2.4 SECONDS)

/obj/machinery/hoverfab/proc/create_board()
	playsound(src, 'sound/machines/compiler/compiler-stage2.ogg', 50)

/obj/machinery/hoverfab/proc/play_round(mob/living/user)
	// Our color define names are *really* bad
	var/static/list/all_colors = list(
		"Red" = COLOR_RED,
		"Orange" = COLOR_MOSTLY_PURE_ORANGE,
		"Yellow" = COLOR_TANGERINE_YELLOW,
		"Green" = COLOR_LIME,
		"Cyan" = COLOR_CYAN,
		"Blue" = COLOR_BLUE,
		"Purple" = COLOR_VIOLET,
	)

	var/static/list/color_picks = list(
		"Red" = image(icon = 'icons/hud/radial.dmi', icon_state = "red"),
		"Orange" = image(icon = 'icons/hud/radial.dmi', icon_state = "orange"),
		"Yellow" = image(icon = 'icons/hud/radial.dmi', icon_state = "yellow"),
		"Green" = image(icon = 'icons/hud/radial.dmi', icon_state = "green"),
		"Cyan" = image(icon = 'icons/hud/radial.dmi', icon_state = "cyan"),
		"Blue" = image(icon = 'icons/hud/radial.dmi', icon_state = "blue"),
		"Purple" = image(icon = 'icons/hud/radial.dmi', icon_state = "amethyst"),
	)

	active_game = TRUE
	var/list/color_sequence = list()
	for (var/i in 1 to (HOVERFAB_BASE_ROUNDS + won_rounds))
		var/picked_color = pick(all_colors)
		color_sequence += picked_color
		var/flick_time = HOVERFAB_BASE_DELAY - HOVERFAB_DELAY_REDUCTION * won_rounds
		var/mutable_appearance/lock_overlay = mutable_appearance(icon, "[base_icon_state]_lock", offset_spokesman = src)
		lock_overlay.color = all_colors[picked_color]
		flick_overlay_view(lock_overlay, flick_time)
		flick_overlay_view(emissive_appearance(icon, "[base_icon_state]_lock_e", src), flick_time)
		// For colorblind folks out there *unless you're also colorblind in-game*
		if (!HAS_TRAIT(user, TRAIT_COLORBLIND))
			balloon_alert(user, lowertext(picked_color), starting_x = 8, starting_y = 4)
		sleep(flick_time + 0.4 SECONDS)

	if (!user.CanReach(src))
		active_game = FALSE
		return

	while (length(color_sequence))
		var/color_pick = show_radial_menu(user, src, color_picks, require_near = TRUE, tooltips = TRUE, entry_animation = FALSE, offset_x = 8, offset_y = -4)
		// Yeowch, go get your eyes fixed. Or get a friend to solve it for you.
		if (HAS_TRAIT(user, TRAIT_COLORBLIND) && prob(15))
			color_pick = pick(all_colors)

		if (color_pick != color_sequence[1])
			playsound(src, 'sound/machines/uplink/uplinkerror.ogg', 50)
			balloon_alert(user, "wrong answer!", starting_x = 8)
			won_rounds = 0
			update_appearance()
			active_game = FALSE
			return

		playsound(src, length(color_sequence) == 1 ? 'sound/machines/compiler/compiler-stage1.ogg' : 'sound/machines/lever/lever_start.ogg', 50)
		color_sequence.Cut(1, 2)

	active_game = FALSE
	won_rounds += 1
	update_appearance()

#undef HOVERFAB_REPAIR_INTACT
#undef HOVERFAB_REPAIR_COIL
#undef HOVERFAB_REPAIR_PLASTEEL
#undef HOVERFAB_REPAIR_WELDING

#undef HOVERFAB_STATE_INACTIVE
#undef HOVERFAB_STATE_ACTIVATED
#undef HOVERFAB_STATE_OPEN
#undef HOVERFAB_STATE_PROCESSING

#undef HOVERFAB_BASE_ROUNDS
#undef HOVERFAB_BASE_DELAY
#undef HOVERFAB_DELAY_REDUCTION
#undef HOVERFAB_PRODUCTION_TIME

/obj/item/melee/skateboard/hoverboard/jetboard
	name = "jetboard"
	desc = "A sleek jetboard using hardlight jets to push itself off the ground. You can feel its internals trembling under your fingers."
	icon_state = "jetboard_held"
	inhand_icon_state = "hoverboard_nt"
	throwforce = 16
	attack_verb_continuous = list("bashes", "crashes", "grinds", "skates")
	attack_verb_simple = list("bash", "crash", "grind", "skate")
	board_item_type = /obj/vehicle/ridden/scooter/skateboard/hoverboard/jetboard

/obj/vehicle/ridden/scooter/skateboard/hoverboard/jetboard
	name = "jetboard"
	desc = "A sleek jetboard using hardlight jets to push itself off the ground. You can feel its internals trembling under your feet."
	board_item_type = /obj/item/melee/skateboard/hoverboard/jetboard
	instability = 1.66 // ~10 stam damage per impact
	icon_state = "jetboard"
	spark_type = /datum/effect_system/spark_spread/holographic

// Jetboards, besides being
/obj/vehicle/ridden/scooter/skateboard/hoverboard/jetboard/crash(atom/bumped_thing)

/*

/obj/vehicle/ridden/scooter/skateboard/proc/crash(atom/bumped_thing)
	next_crash = world.time + 10
	rider.adjustStaminaLoss(instability*6)
	playsound(src, 'sound/effects/bang.ogg', 40, TRUE)

	if(iscarbon(rider) && rider.getStaminaLoss() < 100 && !grinding && !iscarbon(bumped_thing))
		var/backdir = REVERSE_DIR(dir)
		step(src, backdir)
		rider.spin(4, 1)
		return

	var/atom/throw_target = get_edge_target_turf(rider, pick(GLOB.cardinals))
	unbuckle_mob(rider)

	if((istype(bumped_thing, /obj/machinery/disposal/bin)))
		rider.Paralyze(8 SECONDS)
		rider.forceMove(bumped_thing)
		forceMove(bumped_thing)
		visible_message(span_danger("[src] crashes into [bumped_thing], and gets dumped straight into it!"))
		return

	rider.throw_at(throw_target, 3, 2)
	var/head_slot = rider.get_item_by_slot(ITEM_SLOT_HEAD)
	if(!head_slot || !(istype(head_slot,/obj/item/clothing/head/helmet) || istype(head_slot,/obj/item/clothing/head/utility/hardhat)))
		rider.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5)
		rider.updatehealth()

	visible_message(span_danger("[src] crashes into [bumped_thing], sending [rider] flying!"))
	rider.Paralyze(8 SECONDS)
	if(!iscarbon(bumped_thing))
		return
	var/mob/living/carbon/victim = bumped_thing
	var/grinding_mulitipler = 1
	if(grinding)
		grinding_mulitipler = 2
	victim.Knockdown(4 * grinding_mulitipler SECONDS)
*/
