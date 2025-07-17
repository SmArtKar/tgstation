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
	/// Alternate position for reduced HUD
	var/reduced_screen_loc = "EAST-1:28,SOUTH:5"

/datum/hud_element/human/combat_toggle/create_element(datum/hud/hud, mob/owner)
	var/atom/movable/screen/combattoggle/element = ..()
	element.reduced_screen_loc = reduced_screen_loc
	return element

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

/datum/hud_element/human/sleep
	element_type = /atom/movable/screen/sleep
	screen_loc = "EAST-1:28,SOUTH+1:41"

/datum/hud_element/human/resist
	element_type = /atom/movable/screen/resist
	screen_loc = "EAST-2:26,SOUTH+1:7"
	hud_type = HUD_ELEM_HOTKEY

/datum/hud_element/human/throw_catch
	element_type = /atom/movable/screen/throw_catch
	screen_loc = "EAST-1:28,SOUTH+1:24"
	hud_type = HUD_ELEM_HOTKEY

/datum/hud_element/human/rest
	element_type = /atom/movable/screen/rest
	screen_loc = "EAST-1:28,SOUTH+1:7"
	hud_type = HUD_ELEM_HOTKEY

/datum/hud_element/human/pull
	element_type = /atom/movable/screen/pull
	screen_loc = "EAST-2:26,SOUTH+1:24"
	hud_type = HUD_ELEM_HOTKEY

/datum/hud_element/human/zone_sel
	element_type = /atom/movable/screen/zone_sel
	screen_loc = "EAST-1:28,SOUTH:5"

/datum/hud_element/human/zone_sel/create_element(datum/hud/hud, mob/owner)
	var/atom/movable/screen/element = ..()
	element.update_appearance()
	return element

// Info elements
/datum/hud_element/human/spacesuit_cell
	element_type = /atom/movable/screen/spacesuit
	screen_loc = "EAST-1:28,CENTER-4:14"
	hud_type = HUD_ELEM_INFO

/datum/hud_element/human/healthbar
	element_type = /atom/movable/screen/healths
	screen_loc = "EAST-1:28,CENTER-1:19"
	hud_type = HUD_ELEM_INFO

/datum/hud_element/human/hunger
	element_type = /atom/movable/screen/hunger
	screen_loc = "EAST-1:2,CENTER:21"
	hud_type = HUD_ELEM_INFO

/datum/hud_element/human/healthdoll
	element_type = /atom/movable/screen/healthdoll/human
	screen_loc = "EAST-1:28,CENTER-2:17"
	hud_type = HUD_ELEM_INFO

/datum/hud_element/human/stamina
	element_type = /atom/movable/screen/stamina
	screen_loc = "EAST-1:28,CENTER-3:14"
	hud_type = HUD_ELEM_INFO

// Inventory elements

/datum/hud_element/human/inv_toggle
	element_type = /atom/movable/screen/inv_toggle
	screen_loc = "WEST:6,SOUTH:5"

/datum/hud_element/inventory/human
	abstract_type = /datum/hud_element/inventory/human

/datum/hud_element/inventory/human/uniform
	name = "uniform"
	icon_state = "uniform"
	icon_full = "template"
	screen_loc = "WEST:6,SOUTH+1:7"
	slot_id = ITEM_SLOT_ICLOTHING
	toggleable = TRUE

/datum/hud_element/inventory/human/suit
	name = "suit"
	icon_state = "suit"
	icon_full = "template"
	screen_loc = "WEST+1:8,SOUTH+1:7"
	slot_id = ITEM_SLOT_OCLOTHING
	toggleable = TRUE

/datum/hud_element/inventory/human/id
	name = "id"
	icon_state = "id"
	icon_full = "template_small"
	screen_loc = "CENTER-4:12,SOUTH:5"
	slot_id = ITEM_SLOT_ID
	toggleable = TRUE

/datum/hud_element/inventory/human/mask
	name = "mask"
	icon_state = "mask"
	icon_full = "template"
	screen_loc = "WEST+1:8,SOUTH+2:9"
	slot_id = ITEM_SLOT_MASK
	toggleable = TRUE

/datum/hud_element/inventory/human/neck
	name = "neck"
	icon_state = "neck"
	icon_full = "template"
	screen_loc = "WEST:6,SOUTH+2:9"
	slot_id = ITEM_SLOT_NECK
	toggleable = TRUE

/datum/hud_element/inventory/human/gloves
	name = "gloves"
	icon_state = "gloves"
	icon_full = "template"
	screen_loc = "WEST+2:10,SOUTH+1:7"
	slot_id = ITEM_SLOT_GLOVES
	toggleable = TRUE

/datum/hud_element/inventory/human/glasses
	name = "eyes"
	icon_state = "glasses"
	icon_full = "template"
	screen_loc = "WEST:6,SOUTH+3:11"
	slot_id = ITEM_SLOT_EYES
	toggleable = TRUE

/datum/hud_element/inventory/human/ears
	name = "ears"
	icon_state = "ears"
	icon_full = "template"
	screen_loc = "WEST+2:10,SOUTH+2:9"
	slot_id = ITEM_SLOT_EARS
	toggleable = TRUE

/datum/hud_element/inventory/human/head
	name = "head"
	icon_state = "head"
	icon_full = "template"
	screen_loc = "WEST+1:8,SOUTH+3:11"
	slot_id = ITEM_SLOT_HEAD
	toggleable = TRUE

/datum/hud_element/inventory/human/shoes
	name = "shoes"
	icon_state = "shoes"
	icon_full = "template"
	screen_loc = "WEST+1:8,SOUTH:5"
	slot_id = ITEM_SLOT_FEET
	toggleable = TRUE

/datum/hud_element/inventory/human/back
	name = "back"
	icon_state = "back"
	icon_full = "template_small"
	screen_loc = "CENTER-2:14,SOUTH:5"
	slot_id = ITEM_SLOT_BACK

/datum/hud_element/inventory/human/l_pocket
	name = "left pocket"
	icon_state = "pocket"
	icon_full = "template_small"
	screen_loc = "CENTER+1:18,SOUTH:5"
	slot_id = ITEM_SLOT_LPOCKET

/datum/hud_element/inventory/human/r_pocket
	name = "right pocket"
	icon_state = "pocket"
	icon_full = "template_small"
	screen_loc = "CENTER+2:20,SOUTH:5"
	slot_id = ITEM_SLOT_RPOCKET

/datum/hud_element/inventory/human/suit_storage
	name = "suit storage"
	icon_state = "suit_storage"
	icon_full = "template"
	screen_loc = "CENTER-5:10,SOUTH:5"
	slot_id = ITEM_SLOT_SUITSTORE

/datum/hud_element/inventory/human/belt
	name = "belt"
	icon_state = "belt"
	icon_full = "template_small"
	screen_loc = "CENTER-3:14,SOUTH:5"
	slot_id = ITEM_SLOT_BELT
