// Human-specific HUDs
/datum/hud_element/human
	abstract_type = /datum/hud_element/human

// Generic UI elements

/datum/hud_element/human/language_menu
	element_type = /atom/movable/screen/language_menu
	screen_loc = "EAST-3:7,SOUTH+1:24"

/datum/hud_element/human/navigate
	element_type = /atom/movable/screen/navigate
	screen_loc = "EAST-3:7,SOUTH+1:7"

/datum/hud_element/human/area_creator
	element_type = /atom/movable/screen/area_creator
	screen_loc = "EAST-3:24,SOUTH+1:24"

/datum/hud_element/human/combat_toggle
	element_type = /atom/movable/screen/combattoggle/flashy
	screen_loc = "EAST-3:24,SOUTH:5"
	hud_type = HUD_ELEM_INFO

/datum/hud_element/human/floor_changer
	element_type = /atom/movable/screen/floor_changer/vertical
	screen_loc = "EAST-4:22,SOUTH:5"

/datum/hud_element/human/move_intent
	element_type = /atom/movable/screen/move_intent
	screen_loc = "EAST-2:26,SOUTH:5"

/datum/hud_element/human/move_intent/create_element(datum/hud/hud, mob/owner)
	var/atom/movable/screen/element = ..()
	element.update_appearance()
	return element

/datum/hud_element/human/drop
	element_type = /atom/movable/screen/drop

/datum/hud_element/human/drop/create_element(datum/hud/hud, mob/owner)
	var/atom/movable/screen/element = ..()
	element.screen_loc = ui_swaphand_position(owner, LEFT_HANDS)
	return element

/datum/hud_element/human/swap_hand
	element_type = /atom/movable/screen/swap_hand

/datum/hud_element/human/swap_hand/create_element(datum/hud/hud, mob/owner)
	var/atom/movable/screen/element = ..()
	element.screen_loc = ui_swaphand_position(owner, RIGHT_HANDS)
	return element

/datum/hud_element/human/resist
	element_type = /atom/movable/screen/resist
	screen_loc = "EAST-2:26,SOUTH+1:7"

/datum/hud_element/human/throw_catch
	element_type = /atom/movable/screen/throw_catch
	screen_loc = "EAST-1:28,SOUTH+1:24"

/datum/hud_element/human/rest
	element_type = /atom/movable/screen/resist
	screen_loc = "EAST-1:28,SOUTH+1:7"

/datum/hud_element/human/sleep
	element_type = /atom/movable/screen/sleep
	screen_loc = "EAST-1:28,SOUTH+1:41"

/datum/hud_element/human/pull
	element_type = /atom/movable/screen/pull
	screen_loc = "EAST-2:26,SOUTH+1:24"

/datum/hud_element/human/zone_sel
	element_type = /atom/movable/screen/zone_sel

/datum/hud_element/human/zone_sel/create_element(datum/hud/hud, mob/owner)
	var/atom/movable/screen/element = ..()
	element.update_appearance()
	return element

// Inventory elements

/datum/hud_element/human/inv_toggle
	element_type = /atom/movable/screen/inv_toggle
	screen_loc = "WEST:6,SOUTH:5"
