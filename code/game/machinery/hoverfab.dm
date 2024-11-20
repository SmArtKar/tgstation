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
/// How much delay is deducted for every won round/reset
#define HOVERFAB_DELAY_REDUCTION 0.15 SECONDS
/// Minimum delay between colors
#define HOVERFAB_MINIMUM_DELAY 0.2 SECONDS
/// How long it takes for a hoverfab to produce an item
#define HOVERFAB_PRODUCTION_TIME 10 SECONDS
/// How many boards can a fabricator produce before rebooting, with game getting harder every reboot
#define HOVERFAB_MAX_BOARDS 3
/// How many rounds you have to fail for the thing to blow up
#define HOVERFAB_FAILURES_TO_KABOOM 10

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
	/// How many times has this fabricator rebooted?
	var/reboots = 0
	/// How many boards has this fabricator produced so far?
	var/produced_items = 0
	/// Is there an active game going on?
	var/active_game = FALSE
	/// Emissive overlay, stored so we can flick it for animations
	var/mutable_appearance/emissive_overlay
	/// Processing sound loop. This is basically a fancy microwave from player's perspective anyways.
	var/datum/looping_sound/microwave/soundloop
	/// What sort of items we're producing
	var/created_type = /obj/item/melee/skateboard/hoverboard/jetboard
	/// List of all dummies who failed the game (and how many times)
	var/list/losers = list()
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

/obj/machinery/hoverfab/debug/Initialize(mapload)
	. = ..()
	new /obj/item/stack/sheet/mineral/wood/fifty(src)
	new /obj/item/stack/cable_coil/thirty(src)
	new /obj/item/light/bulb(src)
	new /obj/item/light/bulb(src)
	new /obj/item/stock_parts/capacitor(src)

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
		addtimer(CALLBACK(soundloop, TYPE_PROC_REF(/datum/looping_sound, start)), 2.3 SECONDS)
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
	for (var/i in 1 to (HOVERFAB_BASE_ROUNDS + won_rounds + reboots * 2))
		var/picked_color = pick(all_colors)
		color_sequence += picked_color
		var/flick_time = max(HOVERFAB_BASE_DELAY - HOVERFAB_DELAY_REDUCTION * (won_rounds + reboots), HOVERFAB_MINIMUM_DELAY)
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
			if (!losers[user])
				losers[user] = 0
			losers[user] += 1
			won_rounds = 0
			update_appearance()
			active_game = FALSE
			if (losers[user] >= HOVERFAB_FAILURES_TO_KABOOM)
				explosion(src, 0, rand(0, 1), rand(2, 3), 4, 5)
			return

		playsound(src, length(color_sequence) == 1 ? 'sound/machines/compiler/compiler-stage1.ogg' : 'sound/machines/lever/lever_start.ogg', 50)
		color_sequence.Cut(1, 2)

	active_game = FALSE
	won_rounds += 1
	// Some mercy
	losers[user] -= 0.25
	update_appearance()

/obj/machinery/hoverfab/proc/finish_processing()
	for (var/atom/something as anything in contents)
		for (var/req_type in required_items)
			if (istype(something, req_type))
				qdel(something)
				break
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
	new created_type(drop_location())
	produced_items += 1
	if (produced_items < HOVERFAB_MAX_BOARDS)
		return
	current_state = HOVERFAB_STATE_ACTIVATED
	won_rounds = 0
	reboots += 1
	update_appearance()
	flick("[base_icon_state]_closing", src)
	if (emissive_overlay)
		flick("[base_icon_state]_closing_e", emissive_overlay)
	playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50)

// Jetboards, besides being rad as fuck, can be used to "tackle" people by ramming into them at full speed with throw intent on.
// In addition to that, normal crashes also act as rams and simply knock the victim down while dealing some hefty stamina to you
/obj/item/melee/skateboard/hoverboard/jetboard
	name = "jetboard"
	desc = "A sleek jetboard using hardlight jets to push itself off the ground. You can feel its internals trembling under your fingers."
	icon_state = "jetboard_held"
	inhand_icon_state = "hoverboard_nt"
	throwforce = 16
	attack_verb_continuous = list("bashes", "crashes", "grinds", "skates")
	attack_verb_simple = list("bash", "crash", "grind", "skate")
	board_item_type = /obj/vehicle/ridden/scooter/skateboard/hoverboard/jetboard

/obj/item/melee/skateboard/hoverboard/jetboard/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_e", src)

/obj/vehicle/ridden/scooter/skateboard/hoverboard/jetboard
	name = "jetboard"
	desc = "A sleek jetboard using hardlight jets to push itself off the ground. You can feel its internals trembling under your feet."
	board_item_type = /obj/item/melee/skateboard/hoverboard/jetboard
	instability = 2
	icon_state = "jetboard"
	spark_type = /datum/effect_system/spark_spread/holographic

/obj/vehicle/ridden/scooter/skateboard/hoverboard/jetboard/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_e", src)

/obj/vehicle/ridden/scooter/skateboard/hoverboard/jetboard/make_ridable()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/scooter/skateboard/hover/jetboard)

/obj/vehicle/ridden/scooter/skateboard/hoverboard/jetboard/crash(mob/living/rider, atom/bumped_thing)
	if (!iscarbon(rider) || rider.getStaminaLoss() > (iscarbon(bumped_thing) ? 75 : 93) || grinding)
		return ..()

	var/mob/living/carbon/user = rider
	next_crash = world.time + (iscarbon(bumped_thing) ? 1 : 1 SECONDS)

	if (!iscarbon(bumped_thing))
		playsound(src, 'sound/effects/bang.ogg', 30, TRUE)
		user.adjustStaminaLoss(7)
		step(src, REVERSE_DIR(dir))
		SpinAnimation(0.4 SECONDS, 1) //Sick flips my dude
		user.SpinAnimation(0.4 SECONDS, 1)
		user.spin(0.4 SECONDS, 1)
		return

	var/mob/living/carbon/victim = bumped_thing
	if (!user.throw_mode)
		playsound(src, 'sound/items/weapons/shove.ogg', 50, TRUE)
		if(victim.check_block(user, 0, user.name, attack_type = UNARMED_ATTACK))
			victim.visible_message(span_danger("[user] crashes into [victim] but [victim.p_they()] manage to block it!"), span_userdanger("[user] crashes into you but you manage to block [user.p_them()]!"))
			victim.throw_at(get_edge_target_turf(victim, dir), 2, 1, spin = FALSE, gentle = TRUE)
		else
			victim.Knockdown(0.1 SECONDS)
			victim.adjustStaminaLoss(10)
			victim.visible_message(span_danger("[user] crashes into [victim], knocking [victim.p_them()] to the ground!"), span_userdanger("[user] crashes into you, knocking you to the ground!"))
		user.adjustStaminaLoss(25)
		user.adjust_eye_blur(2 SECONDS)
		user.SpinAnimation(0.5 SECONDS, 1)
		throw_at(get_edge_target_turf(src, REVERSE_DIR(dir)), 3, 1, spin = TRUE) // YEET
		return

	user.toggle_throw_mode()
	// Really its just oversimplified tackling because jesus christ that thing is needlessly complicated
	if(victim.check_block(user, 0, user.name, attack_type = LEAP_ATTACK))
		victim.visible_message(span_danger("[user]'s [src] tackle is blocked by [victim], softening the effect!"), span_userdanger("You block [user]'s attempt to tackle you with [src], softening the effect!"), ignored_mobs = user)
		to_chat(user, span_userdanger("[victim] blocks your tackle attempt, softening the effect!"))
		neutral_effect(user, victim)
		return

	// Having more stamloss than the tackler screws you over a bit and vise versa
	var/defense_mod = (user.getStaminaLoss() - victim.getStaminaLoss()) / 50
	if(HAS_TRAIT(victim, TRAIT_GRABWEAKNESS))
		defense_mod -= 2
	if(HAS_TRAIT(victim, TRAIT_GIANT))
		defense_mod += 2

	// Going into floats a bit due to stamloss providing minor difference
	var/tackle_roll = rand(-15, 20) / 5 - defense_mod
	// High risk, small reward
	if (grinding)
		tackle_roll += rand(-2, 1)

	if (tackle_roll > -1 && tackle_roll < 1)
		neutral_effect(user, victim)
		return

	if (tackle_roll >= 1)
		playsound(src, 'sound/items/weapons/shove.ogg', 50, TRUE)
		victim.Knockdown(tackle_roll * 1 SECONDS)
		victim.adjust_staggered_up_to(tackle_roll * 2 SECONDS, 10 SECONDS)
		user.adjustStaminaLoss(30 / tackle_roll)
		user.SpinAnimation(0.5 SECONDS, 1)
		sparks.start()
		throw_at(get_edge_target_turf(src, dir), 2, 1, spin = TRUE) // Over the bodied target!
		victim.visible_message(span_danger("[user] crashes into [victim], knocking [victim.p_them()] to the ground!"), span_userdanger("[user] crashes into you, knocking you to the ground!"))
		return

	// Fuck around and find out, really
	instability *= tackle_roll * -2
	. = ..()
	instability /= tackle_roll * -2

/obj/vehicle/ridden/scooter/skateboard/hoverboard/jetboard/proc/neutral_effect(mob/living/carbon/user, mob/living/carbon/victim)
	playsound(src, 'sound/items/weapons/shove.ogg', 50, TRUE)
	// Some stamina to the user, some stagger and a bit less stamina to the victim
	victim.adjustStaminaLoss(10)
	victim.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
	user.adjustStaminaLoss(20)
	user.spin(0.4 SECONDS, 1)
	user.SpinAnimation(0.4 SECONDS, 1)
	victim.throw_at(get_edge_target_turf(victim, dir), 2, 1, spin = FALSE, gentle = TRUE) // push the victim back
	throw_at(get_edge_target_turf(src, REVERSE_DIR(dir)), 2, 1, spin = TRUE) // and YEET ourselves
	victim.visible_message(span_danger("[user] crashes into [victim], knocking them both back!"), span_userdanger("[user] crashes into you, knocking both of you back!"))

/obj/effect/temp_visual/decoy/jetboard_fade/Initialize(mapload, atom/mimiced_atom)
	. = ..()
	color = "#BD69E0"
	alpha = 200
	animate(src, alpha = 0, time = 1 SECONDS)

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
#undef HOVERFAB_MINIMUM_DELAY
#undef HOVERFAB_PRODUCTION_TIME
#undef HOVERFAB_MAX_BOARDS
#undef HOVERFAB_FAILURES_TO_KABOOM
