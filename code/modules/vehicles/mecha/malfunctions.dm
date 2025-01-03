/// Datums handling specific mech malfunctions, these should also handle their own cleanup as mechs use these to check if they should blow up when overheating
/datum/mech_malfunction
	var/name = "Skill Malfunction"
	/// Mecha we're attached to
	var/obj/vehicle/sealed/mecha/parent

/datum/mech_malfunction/New(obj/vehicle/sealed/mecha/new_mecha)
	. = ..()
	parent = new_mecha
	LAZYADD(parent.active_malfunctions, src)

/datum/mech_malfunction/Destroy(force)
	LAZYREMOVE(parent.active_malfunctions, src)
	parent = null
	return ..()

/// Fries and cuts random wires, preventing them from being mended until repaired with some cable coil
/datum/mech_malfunction/burnt_wiring
	name = "Burnt Wiring"
	/// Has wiring been repaired yet?
	var/wiring_repaired = FALSE

/datum/mech_malfunction/burnt_wiring/New(obj/vehicle/sealed/mecha/new_mecha)
	. = ..()
	RegisterSignal(new_mecha, COMSIG_ATOM_EXAMINE, PROC_REF(on_examined))
	RegisterSignal(new_mecha, COMSIG_MECHA_PANEL_STATE_CHANGED, PROC_REF(on_panel))
	RegisterSignal(new_mecha, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(on_interact))
	RegisterSignal(new_mecha.wires, COMSIG_MEND_WIRE, PROC_REF(on_wire_mend))
	var/list/wires = new_mecha.wires.wires.Copy()
	for (var/i = 1 to rand(3, 5))
		new_mecha.wires.cut(pick_n_take(wires))

/datum/mech_malfunction/burnt_wiring/Destroy(force)
	UnregisterSignal(parent, list(COMSIG_ATOM_EXAMINE, COMSIG_MECHA_PANEL_STATE_CHANGED, COMSIG_ATOM_ITEM_INTERACTION))
	UnregisterSignal(parent.wires, COMSIG_MEND_WIRE)
	return ..()

/datum/mech_malfunction/burnt_wiring/proc/on_examined(datum/source, mob/user, list/examine_text)
	SIGNAL_HANDLER
	if (!(parent.mecha_flags & PANEL_OPEN))
		return
	if (wiring_repaired)
		examine_text += span_warning("Its burnt wiring has been replaced, but still requires mending!")
		return
	examine_text += span_warning("Its wiring is completely scorched and requires replacement!")

/datum/mech_malfunction/burnt_wiring/proc/on_panel(datum/source, mob/user, obj/item/tool)
	SIGNAL_HANDLER
	if (wiring_repaired || !(parent.mecha_flags & PANEL_OPEN))
		return
	to_chat(user, span_warning("As you open [parent.name]'s panel, you are hit by [HAS_TRAIT(user, TRAIT_ANOSMIA) ? "" : "a horrid stench of burnt wiring and "]a cloud of black smoke!"))

/datum/mech_malfunction/burnt_wiring/proc/on_interact(datum/source, mob/living/user, obj/item/tool, list/modifiers)
	SIGNAL_HANDLER
	if (wiring_repaired || user.combat_mode || !(parent.mecha_flags & PANEL_OPEN) || !istype(tool, /obj/item/stack/cable_coil))
		return NONE

	var/obj/item/stack/cable_coil/cable = tool
	if (!cable.use(5))
		parent.balloon_alert(user, "not enough cable!")
		return ITEM_INTERACT_BLOCKING

	wiring_repaired = TRUE
	cable.play_tool_sound(parent)
	parent.balloon_alert(user, "wiring repaired")
	return ITEM_INTERACT_SUCCESS

/datum/mech_malfunction/burnt_wiring/proc/on_wire_mend(datum/wires/source, wire, mob/living/user)
	SIGNAL_HANDLER
	if (!wiring_repaired)
		to_chat(user, span_warning("[parent.name]'s wiring is completely scorched and requires replacement!"))
		return COMPONENT_CANCEL_WIRE_MEND

	if (length(source.cut_wires) > 2)
		return

	// If only cut wire besides this one is WIRE_OVERCLOCK, consider ourselves repaired
	if (length(source.cut_wires) == 1 || (WIRE_OVERCLOCK in source.cut_wires))
		qdel(src)
