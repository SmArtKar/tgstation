//Science modules for MODsuits

///Reagent Scanner - Lets the user scan reagents.
/obj/item/mod/module/reagent_scanner
	name = "MOD reagent scanner module"
	desc = "A module based off research-oriented Nanotrasen HUDs, this is capable of scanning the contents of \
		containers and projecting the information in an easy-to-read format on the wearer's display. \
		It cannot detect flavors, so that's up to you."
	icon_state = "scanner"
	module_type = MODULE_TOGGLE
	complexity = 1
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.2
	incompatible_modules = list(/obj/item/mod/module/reagent_scanner)
	cooldown_time = 0.5 SECONDS

/obj/item/mod/module/reagent_scanner/on_activation()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(mod.wearer, TRAIT_REAGENT_SCANNER, MOD_TRAIT)

/obj/item/mod/module/reagent_scanner/on_deactivation(display_message = TRUE)
	. = ..()
	if(!.)
		return
	REMOVE_TRAIT(mod.wearer, TRAIT_REAGENT_SCANNER, MOD_TRAIT)

/obj/item/mod/module/reagent_scanner/advanced
	name = "MOD advanced reagent scanner module"
	complexity = 0
	removable = FALSE
	var/explosion_detection_dist = 21

/obj/item/mod/module/reagent_scanner/advanced/on_activation()
	. = ..()
	if(!.)
		return
	mod.wearer.research_scanner++
	RegisterSignal(SSdcs, COMSIG_GLOB_EXPLOSION, .proc/sense_explosion)

/obj/item/mod/module/reagent_scanner/advanced/on_deactivation(display_message = TRUE)
	. = ..()
	if(!.)
		return
	mod.wearer.research_scanner--
	RegisterSignal(SSdcs, COMSIG_GLOB_EXPLOSION)

/obj/item/mod/module/reagent_scanner/advanced/proc/sense_explosion(datum/source, turf/epicenter,
	devastation_range, heavy_impact_range, light_impact_range, took, orig_dev_range, orig_heavy_range, orig_light_range)
	SIGNAL_HANDLER
	var/turf/wearer_turf = get_turf(mod.wearer)
	if(wearer_turf.z != epicenter.z)
		return
	if(get_dist(epicenter, wearer_turf) > explosion_detection_dist)
		return
	to_chat(mod.wearer, span_notice("Explosion detected! Epicenter: [devastation_range], Outer: [heavy_impact_range], Shock: [light_impact_range]"))

///Anti-Gravity - Makes the user weightless.
/obj/item/mod/module/anomaly_locked/antigrav
	name = "MOD anti-gravity module"
	desc = "A module that uses a gravitational core to make the user completely weightless."
	icon_state = "antigrav"
	module_type = MODULE_TOGGLE
	complexity = 3
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.7
	incompatible_modules = list(/obj/item/mod/module/anomaly_locked, /obj/item/mod/module/atrocinator)
	cooldown_time = 0.5 SECONDS
	accepted_anomalies = list(/obj/item/assembly/signaler/anomaly/grav)

/obj/item/mod/module/anomaly_locked/antigrav/on_activation()
	. = ..()
	if(!.)
		return
	if(mod.wearer.has_gravity())
		new /obj/effect/temp_visual/mook_dust(get_turf(src))
	mod.wearer.AddElement(/datum/element/forced_gravity, 0)
	mod.wearer.update_gravity(mod.wearer.has_gravity())
	playsound(src, 'sound/effects/gravhit.ogg', 50)

/obj/item/mod/module/anomaly_locked/antigrav/on_deactivation(display_message = TRUE)
	. = ..()
	if(!.)
		return
	mod.wearer.RemoveElement(/datum/element/forced_gravity, 0)
	mod.wearer.update_gravity(mod.wearer.has_gravity())
	if(mod.wearer.has_gravity())
		new /obj/effect/temp_visual/mook_dust(get_turf(src))
	playsound(src, 'sound/effects/gravhit.ogg', 50)

/obj/item/mod/module/anomaly_locked/antigrav/prebuilt
	prebuilt = TRUE

///Teleporter - Lets the user teleport to a nearby location.
/obj/item/mod/module/anomaly_locked/teleporter
	name = "MOD teleporter module"
	desc = "A module that uses a bluespace core to let the user transport their particles elsewhere."
	icon_state = "teleporter"
	module_type = MODULE_ACTIVE
	complexity = 3
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	cooldown_time = 5 SECONDS
	accepted_anomalies = list(/obj/item/assembly/signaler/anomaly/bluespace)
	/// Time it takes to teleport
	var/teleport_time = 3 SECONDS

/obj/item/mod/module/anomaly_locked/teleporter/on_select_use(atom/target)
	. = ..()
	if(!.)
		return
	var/turf/open/target_turf = get_turf(target)
	if(!istype(target_turf) || target_turf.is_blocked_turf_ignore_climbable() || !(target_turf in view(mod.wearer)))
		balloon_alert(mod.wearer, "invalid target!")
		return
	balloon_alert(mod.wearer, "teleporting...")
	var/matrix/pre_matrix = matrix()
	pre_matrix.Scale(4, 0.25)
	var/matrix/post_matrix = matrix()
	post_matrix.Scale(0.25, 4)
	animate(mod.wearer, teleport_time, color = COLOR_CYAN, transform = pre_matrix.Multiply(mod.wearer.transform), easing = EASE_OUT)
	if(!do_after(mod.wearer, teleport_time, target = mod))
		balloon_alert(mod.wearer, "interrupted!")
		animate(mod.wearer, teleport_time*0.1, color = null, transform = post_matrix.Multiply(mod.wearer.transform), easing = EASE_IN)
		return
	animate(mod.wearer, teleport_time*0.1, color = null, transform = post_matrix.Multiply(mod.wearer.transform), easing = EASE_IN)
	if(!do_teleport(mod.wearer, target_turf, asoundin = 'sound/effects/phasein.ogg'))
		return
	drain_power(use_power_cost)

/obj/item/mod/module/anomaly_locked/teleporter/prebuilt
	prebuilt = TRUE

/obj/item/mod/module/repeller_field //This is supposed to be an upgrade for xenobio suit
	name = "MOD repeller field generator module"
	desc = "A complex module designed by \"Xynergy Solutions\", repeller field generator creates a field that protects the user from slimes."
	icon_state = "repeller_field"
	module_type = MODULE_TOGGLE
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/repeller_field)
	cooldown_time = 0.5 SECONDS
	var/mutable_appearance/worn_underlay

/obj/item/mod/module/repeller_field/on_activation()
	. = ..()
	if(!.)
		return

	ADD_TRAIT(mod.wearer, TRAIT_NO_SLIME_FEED, MOD_TRAIT)
	playsound(src, 'sound/effects/bamf.ogg', 50)

	worn_underlay = mutable_appearance('icons/mob/clothing/mod.dmi', "repeller_field")
	worn_underlay.pixel_x = mod.wearer.pixel_x
	worn_underlay.pixel_y = mod.wearer.pixel_y
	mod.wearer.underlays += worn_underlay

/obj/item/mod/module/repeller_field/on_deactivation(display_message = TRUE)
	. = ..()
	if(!.)
		return

	REMOVE_TRAIT(mod.wearer, TRAIT_NO_SLIME_FEED, MOD_TRAIT)
	playsound(src, 'sound/effects/bamf.ogg', 50)

	if(mod.wearer)
		mod.wearer.underlays -= worn_underlay
		QDEL_NULL(worn_underlay)

/obj/item/mod/module/vacuum_pack
	name = "MOD vacuum xenofauna storage module"
	desc = "A minified version of Xynergy's xenofauna vacuum storage backpack that's able to be stuffed into a MODsuit."
	icon_state = "vacuum"
	module_type = MODULE_TOGGLE
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN * 0.2
	incompatible_modules = list(/obj/item/mod/module/vacuum_pack)
	cooldown_time = 0.5 SECONDS
	var/obj/item/vacuum_pack/integrated/pack

/obj/item/mod/module/vacuum_pack/Initialize(mapload)
	. = ..()
	pack = new(src)

/obj/item/mod/module/vacuum_pack/on_activation()
	. = ..()
	if(!.)
		return

	pack.toggle_nozzle(mod.wearer)

/obj/item/mod/module/vacuum_pack/on_deactivation(display_message = TRUE)
	. = ..()
	if(!.)
		return

	pack.remove_nozzle()

/obj/item/mod/module/slime_bracers
	name = "MOD bracer overcharger module"
	desc = "A bracer-mounted module that overcharges them, causing slimes to get violently repulsed on contact. Quite effective in case of a slime outbreak, especially in combination with a repeller field."
	icon_state = "slime_bracers"
	module_type = MODULE_TOGGLE
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/slime_bracers)
	cooldown_time = 0.5 SECONDS
	overlay_state_active = "module_slime_bracers"

/obj/item/mod/module/slime_bracers/on_activation()
	. = ..()
	if(!.)
		return

	RegisterSignal(mod.wearer, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, .proc/launch_slime)

/obj/item/mod/module/slime_bracers/on_deactivation(display_message = TRUE)
	. = ..()
	if(!.)
		return

	UnregisterSignal(mod.wearer, COMSIG_HUMAN_MELEE_UNARMED_ATTACK)

/obj/item/mod/module/slime_bracers/proc/launch_slime(mob/living/carbon/human/wearer, atom/target, proximity)
	if(!isslime(target))
		return

	var/mob/living/simple_animal/slime/slime = target
	slime.visible_message(span_warning("[slime] is violently launched into the air as soon as it comes in contact with [mod.wearer]'s overcharged bracers!"))
	var/throwtarget = get_edge_target_turf(wearer, get_dir(wearer, slime))
	slime.throw_at(throwtarget, 3, 2, wearer)
	slime.Stun(50)
	playsound(src, 'sound/effects/contractorbatonhit.ogg', 75)
	drain_power(DEFAULT_CHARGE_DRAIN * 2)

/obj/item/mod/module/emote_holoscreen
	name = "MOD emote holoscreen module"
	desc = "A holographic projector mounted into your helmet that allows you to show slimeys on it."
	icon_state = "emote_holoscreen"
	module_type = MODULE_TOGGLE
	complexity = 0
	use_power_cost = DEFAULT_CHARGE_DRAIN * 0.1
	incompatible_modules = list(/obj/item/mod/module/emote_holoscreen)
	cooldown_time = 0.5 SECONDS
	overlay_state_active = "emote_uwu"

/obj/item/mod/module/emote_holoscreen/on_activation()
	. = ..()
	if(!.)
		return

	var/list/emotions = list(
		"emote_pout" = image(icon = 'icons/hud/radial.dmi', icon_state = "emote_pout"),
		"emote_sad" = image(icon = 'icons/hud/radial.dmi', icon_state = "emote_sad"),
		"emote_angry" = image(icon = 'icons/hud/radial.dmi', icon_state = "emote_angry"),
		"emote_mischevous" = image(icon = 'icons/hud/radial.dmi', icon_state = "emote_mischevous"),
		"emote_uwu" = image(icon = 'icons/hud/radial.dmi', icon_state = "emote_uwu"),
		"emote_owo" = image(icon = 'icons/hud/radial.dmi', icon_state = "emote_owo"),
		)

	overlay_state_active = show_radial_menu(mod.wearer, mod, emotions, require_near = TRUE)
	mod.helmet.update_icon()
	mod.wearer.update_icon()
