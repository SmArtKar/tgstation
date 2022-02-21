/obj/machinery/computer/slime_market
	name = "slime market console"
	desc = "Used to sell slime cores and manage intergalactic slime bounties."
	icon_screen = "slime_market"
	icon_keyboard = "rd_key"
	light_color = LIGHT_COLOR_LAVENDER
	circuit = /obj/item/circuitboard/computer/slime_market
	var/obj/machinery/slime_market_pad/market_pad

/obj/machinery/computer/slime_market/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	link_market_pad()

/obj/machinery/computer/slime_market/proc/link_market_pad()
	if(market_pad)
		return

	for(var/direction in GLOB.cardinals)
		market_pad = locate(/obj/machinery/slime_market_pad, get_step(src, direction))
		if(market_pad)
			market_pad.link_console()
			break

	return market_pad

/obj/machinery/computer/slime_market/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/xenobio_market),
	)

/obj/machinery/computer/slime_market/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "XenobioMarket", name)
		ui.open()

/obj/machinery/computer/slime_market/ui_act(action, params)
	. = ..()
	if(.)
		return

	//switch(action)
	//	return

/obj/machinery/computer/slime_market/ui_data()
	var/data = list()
	var/list/prices = list()
	var/list/price_row = list()
	var/iter = 1
	for(var/core_type in (subtypesof(/obj/item/slime_extract) - /obj/item/slime_extract/rainbow))
		if(iter % 4 == 1)
			prices.Add(list(list("key" = LAZYLEN(prices), "prices" = price_row.Copy())))
			price_row = list()

		if(core_type == /obj/item/slime_extract/grey)
			price_row.Add(list(list("key" = iter % 4)))
			iter += 1

		var/obj/item/slime_extract/core = core_type
		var/list/core_data = list("icon" = "[initial(core.icon_state)]-dead",
								  "price" = SSresearch.slime_core_prices[core_type],
								  "key" = iter % 4,
								  )
		price_row.Add(list(core_data))
		iter += 1

		if(core_type == /obj/item/slime_extract/grey)
			core = /obj/item/slime_extract/rainbow
			var/list/rainbow_core_data = list("icon" = "[initial(core.icon_state)]-dead",
									"price" = SSresearch.slime_core_prices[/obj/item/slime_extract/rainbow],
									"key" = iter % 4,
									)
			price_row.Add(list(rainbow_core_data))
			iter += 1
			price_row.Add(list(list("key" = iter % 4)))
			iter += 1

	if(LAZYLEN(price_row))
		prices.Add(list(list("key" = LAZYLEN(prices), "prices" = price_row.Copy())))

	data["prices"] = prices



	return data
