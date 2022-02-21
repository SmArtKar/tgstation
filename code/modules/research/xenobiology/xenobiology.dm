////Slime-derived potions///



///Definitions for slime products that don't have anywhere else to go (Floor tiles, blueprints).

/obj/item/stack/tile/bluespace
	name = "bluespace floor tile"
	singular_name = "floor tile"
	desc = "Through a series of micro-teleports these tiles let people move at incredible speeds."
	icon_state = "tile_bluespace"
	inhand_icon_state = "tile-bluespace"
	w_class = WEIGHT_CLASS_NORMAL
	force = 6
	mats_per_unit = list(/datum/material/iron=500)
	throwforce = 10
	throw_speed = 3
	throw_range = 7
	flags_1 = CONDUCT_1
	max_amount = 60
	turf_type = /turf/open/floor/bluespace
	merge_type = /obj/item/stack/tile/bluespace

/obj/item/stack/tile/sepia
	name = "sepia floor tile"
	singular_name = "floor tile"
	desc = "Time seems to flow very slowly around these tiles."
	icon_state = "tile_sepia"
	inhand_icon_state = "tile-sepia"
	w_class = WEIGHT_CLASS_NORMAL
	force = 6
	mats_per_unit = list(/datum/material/iron=500)
	throwforce = 10
	throw_speed = 0.1
	throw_range = 28
	flags_1 = CONDUCT_1
	max_amount = 60
	turf_type = /turf/open/floor/sepia
	merge_type = /obj/item/stack/tile/sepia

/obj/item/areaeditor/blueprints/slime
	name = "cerulean prints"
	desc = "A one use yet of blueprints made of jelly like organic material. Extends the reach of the management console."
	color = "#2956B2"

/obj/item/areaeditor/blueprints/slime/edit_area()
	..()
	var/area/A = get_area(src)
	for(var/turf/T in A)
		T.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
		T.add_atom_colour("#2956B2", FIXED_COLOUR_PRIORITY)
	A.area_flags |= XENOBIOLOGY_COMPATIBLE
	qdel(src)
