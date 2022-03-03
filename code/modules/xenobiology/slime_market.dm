/obj/machinery/slime_market_pad
	name = "intergalactic market pad"
	desc = "A tall device with a hole for inserting slime extracts. IMPs are widely used for trading small items on large distances all over the galaxy."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "market_pad"
	base_icon_state = "market_pad"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 2000
	circuit = /obj/item/circuitboard/machine/slime_market_pad
	var/obj/machinery/computer/slime_market/console

/obj/machinery/slime_market_pad/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, I))
		user.visible_message(span_notice("\The [user] [panel_open ? "opens" : "closes"] the hatch on \the [src]."), span_notice("You [panel_open ? "open" : "close"] the hatch on \the [src]."))
		update_appearance()
		return TRUE

	if(default_unfasten_wrench(user, I))
		return TRUE

	if(default_deconstruction_crowbar(I))
		return TRUE

	. = ..()

/obj/machinery/slime_market_pad/examine(mob/user)
	. = ..()
	if(!panel_open)
		. += span_notice("The panel is <i>screwed</i> in.")

/obj/machinery/slime_market_pad/update_overlays()
	. = ..()
	if(panel_open)
		. += "market_pad-panel"

/obj/machinery/slime_market_pad/Initialize(mapload)
	. = ..()
	link_console()

/obj/machinery/slime_market_pad/proc/link_console()
	if(console)
		return

	for(var/direction in GLOB.cardinals)
		console = locate(/obj/machinery/computer/slime_market, get_step(src, direction))
		if(console)
			console.link_market_pad()
			break

/obj/machinery/slime_market_pad/attackby(obj/item/I, mob/living/user, params)
	if(!console)
		to_chat(user, span_warning("[src] does not have a console linked to it!"))
		return

	var/obj/item/card/id/card = user.get_idcard(TRUE)
	if(!card)
		to_chat(user, span_warning("Unable to locate an ID card!"))
		return

	if(istype(I, /obj/item/slime_extract))
		flick("[base_icon_state]_vend", src)
		sell_extract(I, card)
		return

	else if(istype(I, /obj/item/storage/bag/bio))
		if(tgui_alert(user, "Are you sure you want to sell all extracts from [I]?", "<3?", list("Yes", "No")) != "Yes")
			return

		flick("[base_icon_state]_vend", src)
		for(var/obj/item/slime_extract/extract in I)
			sell_extract(extract, card)
		return
	. = ..()

/obj/machinery/slime_market_pad/proc/sell_extract(obj/item/slime_extract/extract, obj/item/card/id/card)
	card.xenobio_points += SSresearch.slime_core_prices[extract.type]
	SSresearch.slime_core_prices[extract.type] = round(rand(SLIME_SELL_MODIFIER_MIN * 100, SLIME_SELL_MODIFIER_MAX * 100) / 100 * SSresearch.slime_core_prices[extract.type])
	for(var/core_type in SSresearch.slime_core_prices)
		if(core_type == extract.type)
			continue
		SSresearch.slime_core_prices[core_type] = round(rand(SLIME_SELL_OTHER_MODIFIER_MIN * 100, SLIME_SELL_OTHER_MODIFIER_MAX * 100) / 100 * SSresearch.slime_core_prices[core_type])
	qdel(extract)

/obj/machinery/slime_bounty_pad
	name = "intergalactic bounty pad"
	desc = "A tall device with a hole for inserting slime extracts. IMPs are widely used for trading small items on large distances all over the galaxy."
	icon = 'icons/obj/xenobiology/machinery.dmi'
	icon_state = "bounty_pad"
	density = TRUE
	anchored = TRUE
	pass_flags_self = PASSTABLE | LETPASSTHROW
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 2000
	pixel_y = 3
	circuit = /obj/item/circuitboard/machine/slime_bounty_pad
	var/obj/machinery/computer/slime_market/console
	var/max_contract_tier = 2

/obj/machinery/slime_bounty_pad/examine(mob/user)
	. = ..()
	if(!panel_open)
		. += span_notice("The panel is <i>screwed</i> in.")
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: This IBP can process contracts up to [max_contract_tier] level.")

/obj/machinery/slime_bounty_pad/update_overlays()
	. = ..()
	if(panel_open)
		. += "bounty_pad-panel"

/obj/machinery/slime_bounty_pad/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, I))
		user.visible_message(span_notice("\The [user] [panel_open ? "opens" : "closes"] the hatch on \the [src]."), span_notice("You [panel_open ? "open" : "close"] the hatch on \the [src]."))
		update_appearance()
		return TRUE

	if(default_unfasten_wrench(user, I))
		return TRUE

	if(default_deconstruction_crowbar(I))
		return TRUE

	. = ..()

/obj/machinery/slime_bounty_pad/Initialize(mapload)
	. = ..()
	link_console()

/obj/machinery/slime_bounty_pad/RefreshParts()
	max_contract_tier = 0
	for(var/obj/item/stock_parts/capacitor/capacitor in component_parts)
		max_contract_tier += capacitor.rating

/obj/machinery/slime_bounty_pad/proc/link_console()
	if(console)
		return

	for(var/direction in GLOB.cardinals)
		console = locate(/obj/machinery/computer/slime_market, get_step(src, direction))
		if(console)
			console.link_market_pad()
			break
