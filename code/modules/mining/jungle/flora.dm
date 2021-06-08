/obj/structure/flora/aquatic

/obj/structure/flora/aquatic/rock
	name = "rock"
	desc = "A volcanic rock. Pioneers used to ride these babies for miles."
	icon = 'icons/obj/flora/waterflora.dmi'
	icon_state = "bigwaterrock"
	resistance_flags = FIRE_PROOF
	density = TRUE
	var/obj/item/stack/mineResult = /obj/item/stack/ore/glass/basalt
	var/mineAmount = 20

/obj/structure/flora/aquatic/rock/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)][rand(1,3)]"

/obj/structure/flora/aquatic/rock/attackby(obj/item/W, mob/user, params)
	if(!mineResult || W.tool_behaviour != TOOL_MINING)
		return ..()
	if(flags_1 & NODECONSTRUCT_1)
		return ..()
	to_chat(user, "<span class='notice'>You start mining...</span>")
	if(W.use_tool(src, user, 40, volume=50))
		to_chat(user, "<span class='notice'>You finish mining the rock.</span>")
		if(mineResult && mineAmount)
			new mineResult(loc, mineAmount)
		SSblackbox.record_feedback("tally", "pick_used_mining", 1, W.type)
		qdel(src)

/obj/structure/flora/aquatic/rock/pile
	name = "pile of rocks"
	desc = "A pile of rocks."
	icon_state = "waterrock"

/obj/structure/flora/aquatic/rock/pile/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)][rand(1,2)]"
