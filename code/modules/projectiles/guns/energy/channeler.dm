/obj/item/gun/energy/anomacore_channeler
	name = "anomacore channeler"
	desc = "A ."
	icon_state = "taiyo"
	inhand_icon_state = "taiyo"
	worn_icon_state = null
	automatic_charge_overlays = FALSE
	ammo_type = list(/obj/item/ammo_casing/energy/anomacore)
	/// Anomaly core currently inserted into the gun
	var/obj/item/assembly/signaler/anomaly/installed_core = null
	/// Chargeup delay for the anomabeam attack
	var/beam_chargeup_delay = 1.5 SECONDS

/obj/item/gun/energy/anomacore_channeler/update_overlays()
	. = ..()
	if (installed_core)
		. += mutable_appearance(icon, "[icon_state]_[installed_core.channeler_color]")
		. += emissive_appearance(icon, "[icon_state]_[installed_core.channeler_color]", src, alpha = 200)

/obj/item/gun/energy/anomacore_channeler/separate_worn_overlays(mutable_appearance/standing, mutable_appearance/draw_target, isinhands, icon_file)
	. = ..()
	if (!isinhands || !installed_core)
		return
	. += mutable_appearance(icon_file, "[icon_state]_[installed_core.channeler_color]")
	. += emissive_appearance(icon_file, "[inhand_icon_state]_[installed_core.channeler_color]", src, alpha = 200)

/obj/item/gun/energy/anomacore_channeler/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if (!istype(tool, /obj/item/assembly/signaler/anomaly))
		return NONE

	if (installed_core)
		to_chat(user, span_warning("[src] already has \a [installed_core] installed!"))
		return ITEM_INTERACT_BLOCKING

	if (!user.transferItemToLoc(tool, src))
		to_chat(user, span_warning("You fail to install [tool] into [src]!"))
		return ITEM_INTERACT_BLOCKING

	installed_core = tool
	to_chat(user, span_notice("You install [installed_core] into [src]."))
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	update_appearance()
	user.update_held_items()
	return ITEM_INTERACT_SUCCESS

/obj/item/gun/energy/anomacore_channeler/try_fire_gun(atom/target, mob/living/user, params)
	// Right click fires anomacore pellets, left click channels a beam
	if(LAZYACCESS(params2list(params), RIGHT_CLICK))
		return ..()

	user.balloon_alert_to_viewers("charging an anomabeam!")
	if (!do_after(user, beam_chargeup_delay, src, extra_checks = CALLBACK(src, PROC_REF(check_beam_fire), user)))
		return

/obj/item/gun/energy/anomacore_channeler/proc/check_beam_fire(mob/living/user)
	return can_trigger_gun(user) && can_shoot()
