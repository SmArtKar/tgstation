/// Global assoc list of hud element type -> singleton instance
GLOBAL_LIST_INIT(hud_elements, init_hud_elements())

/proc/init_hud_elements()
	var/list/result = list()
	for (var/datum/hud_element/element as anything in subtypesof(/datum/hud_element))
		if (element::abstract_type == element)
			continue
		result[element] = new element()
	return result

/**
 * HUD element *singleton* datum, used to dynamically assemble mob huds through datums instead of relying on manual element creation
 * Each datum should fully handle a single HUD element, either for a specific mob type if its a mob-dedicated subtype (fetched through subtypesof)
 * or be type-agnostic if its not (fetched through type lists)
 */
/datum/hud_element
	/// Typepath for the screen atom to be created
	var/atom/movable/screen/element_type = /atom/movable/screen
	/// screen_loc assigned to the created object, null defaults to said object's own screen_loc
	var/screen_loc = null
	/// What HUD modes is the element visible in
	var/hud_type = HUD_ELEM_BASIC
	/// Abstract parent type for this element to be ignored when creating singletons
	var/abstract_type = /datum/hud_element

/**
 * Create a hud element for a specific HUD and mob
 * * hud - hud we're linking the element to
 * * owner - mob that owns the hud, could technically be null
 */
/datum/hud_element/proc/create_element(datum/hud/hud, mob/owner)
	var/atom/movable/screen/element = new element_type(null, hud)
	element.hud_type = hud_type
	if (screen_loc)
		element.screen_loc = screen_loc
	hud.ui_elements[element] = src
	return element

/// Inventory datum, has additional logic/vars for inventory slots and toggling

/datum/hud_element/inventory
	element_type = /atom/movable/screen/inventory
	abstract_type = /datum/hud_element/inventory
	/// Name of the slot
	var/name = "error"
	/// Item slot attached to this element
	var/slot_id
	/// Icon state for the slot
	var/icon_state
	/// Icon state for the slot when its occupied by an item
	var/icon_full
	/// Does this element get hidden when the inventory is collapsed?
	var/toggleable = FALSE

/datum/hud_element/inventory/create_element(datum/hud/hud, mob/owner)
	var/atom/movable/screen/inventory/element = ..()
	element.name = name
	element.slot_id = slot_id
	element.icon_state = icon_state
	element.icon_full = icon_full
	if (slot_id)
		hud.inv_slots[TOBITSHIFT(slot_id) + 1] = element
	element.update_appearance()
	return element
