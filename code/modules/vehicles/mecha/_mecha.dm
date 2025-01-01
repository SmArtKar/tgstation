/***************** WELCOME TO MECHA.DM, ENJOY YOUR STAY *****************/

/**
 * Mechs are now (finally) vehicles, this means you can make them multicrew
 * They can also grant select ability buttons based on occupant bitflags
 *
 * Movement is handled through vehicle_move() which is called by relaymove
 * Clicking is done by way of signals registering to the entering mob
 * NOTE: MMIS are NOT mobs but instead contain a brain that is, so you need special checks
 * AI also has special checks becaus it gets in and out of the mech differently
 * Always call remove_occupant(mob) when leaving the mech so the mob is removed properly
 *
 * For multi-crew, you need to set how the occupants receive ability bitflags corresponding to their status on the vehicle(i.e: driver, gunner etc)
 * Abilities can then be set to only apply for certain bitflags and are assigned as such automatically
 *
 * Clicks are wither translated into mech_melee_attack (see mech_melee_attack.dm)
 * Or are used to call action() on equipped gear
 * Cooldown for gear is on the mech because exploits
 * Cooldown for melee is on mech_melee_attack also because exploits
 */

/obj/vehicle/sealed/mecha
	name = "exosuit"
	desc = "Exosuit"
	icon = 'icons/mob/rideables/mecha.dmi'

	resistance_flags = FIRE_PROOF | ACID_PROOF
	max_integrity = 300
	armor_type = /datum/armor/sealed_mecha

	movedelay = 1 SECONDS
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_EXTREMELY_STRONG
	/// Significantly heavier than humans
	inertia_force_weight = 5
	generic_canpass = FALSE

	light_system = OVERLAY_LIGHT_DIRECTIONAL
	light_on = FALSE
	light_range = 6

	hud_possible = list(DIAG_STAT_HUD, DIAG_BATT_HUD, DIAG_MECH_HUD, DIAG_TRACK_HUD, DIAG_CAMERA_HUD)
	mouse_pointer = 'icons/effects/mouse_pointers/mecha_mouse.dmi'

	// ----- Generic mech info -----
	/// Single flag for the type of this mech, determines what kind of equipment can be attached to it
	var/mech_type = NONE
	/// Typepath for the wreckage it spawns when destroyed
	var/wreck_type = null
	/// Mech capability flags
	var/mecha_flags = CAN_STRAFE | IS_ENCLOSED | HAS_LIGHTS | MMI_COMPATIBLE | CAN_MOVE_DIAGONALLY
	/// Maximum cabin (or outside air, for open cabin mechs) temperature before mech starts taking damage
	var/max_temperature = 25000
	/// DNA ensymes of mech's owner
	var/dna_lock = null
	/// A list of all granted accesses
	var/list/accesses = list()
	/// If the mech should require ALL or only ONE of the listed accesses
	var/one_access = TRUE
	/// Time it takes to leave the mech
	var/exit_delay = 2 SECONDS
	/// Time you get knocked out for when the mech gets destroyed
	var/blowout_pilot_knockout = 2 SECONDS
	/// Separate icon_state for when the mech does not have a human pilot but is controlled by an AI or a COMP unit
	var/silicon_icon_state
	/// If we're currently in strafing movement mode
	var/strafing = FALSE
	/// Currently ejecting, and unable to do things
	var/currently_ejecting = FALSE
	/// What wires datum we use
	var/wires_type = /datum/wires/mecha
	/// Does this mech accept non-posibrain MMIs as fully capable pilots?
	/// If FALSE, both MMIs and posibrains will go in as COMP units
	var/mmi_full_control = FALSE

	// ----- Equipment-related -----
	/// Currently installed equipment
	var/list/equip_by_category = list(
		MECHA_ARM_LEFT_SLOT = null,
		MECHA_ARM_RIGHT_SLOT = null,
		MECHA_UTILITY_SLOT = list(),
	)
	/// Flat list of equipment for ease of iteration
	var/list/flat_equipment = list()
	/// Total equipment complexity limit of the mech
	var/maximum_complexity = 0
	/// Is our equipment currently disabled (from EMP and alike)
	var/equipment_disabled = FALSE
	/// Timer for equipment reactivation
	var/equipment_reactivation_timer
	/// Mech's installed battery
	var/obj/item/stock_parts/power_store/battery/cell
	/// Capacitor installed into the mech, determines how much heat the mech can sustain
	var/obj/item/stock_parts/capacitor/capacitor
	/// Servo installed into the mech, slightly reduces amount of heat generated during overloading by melee and movement
	var/obj/item/stock_parts/servo/servo
	/// Scanning module installed into the mech, slightly increases heat dissipation
	var/obj/item/stock_parts/scanning_module/scanner

	// ----- Combat-related -----
	/// Melee attack verbs
	var/list/attack_verbs = list("hit", "pommel", "smash")
	/// Force with which the mech punches stuff
	force = 5
	/// Damage multiplier against structures and machinery, so that we break structures but don't oneshot mobs
	demolition_mod = 3
	/// Armor penetration of our punches
	var/armour_penetration = 0
	/// Cooldown between melee attacks
	var/melee_cooldown = CLICK_CD_SNAIL
	/// Whenever weapon safety is enabled. Can be toggled with middle click
	var/safety_enabled = FALSE
	/// Sound that plays when safety is toggled
	var/safety_sound = 'sound/machines/beep/beep.ogg'
	///Modifiers for directional damage reduction
	var/list/facing_modifiers = list(
		MECHA_FRONT_ARMOUR = 0.75,
		MECHA_SIDE_ARMOUR = 1,
		MECHA_BACK_ARMOUR = 1.25,
		)

	// ----- Power and heat -----
	// For these, keep in mind that mechs use megacells!
	/// How much energy the mech will consume each time it moves. this is the current active energy consumed
	var/step_energy_drain = 0.005 * STANDARD_BATTERY_VALUE
	///How much energy we drain each time we melee someone
	var/melee_energy_drain = 0.015 * STANDARD_BATTERY_CHARGE
	///Power we use to have the lights on
	var/light_power_drain = 0.0001 * STANDARD_BATTERY_RATE
	/// How many times can this mech overheat before blowing up in a fabulous fashion during next time they overheat?
	/// Mech will blow up after overheating while having this amount of malfunctions.
	var/max_malfunctions = 3
	/// List of all currently active malfunctions
	var/list/active_malfunctions = list()
	/// How much heat this mech can hold before it overheats
	var/maximum_heat = 200
	/// Mech's current heat
	var/current_heat = 0
	/// Is this mech currently overclocking?
	/// Overclocking increases movement and melee speed, but makes movement produce heat and increases all other heat generation
	/// Mech also doesn't automatically dump heat when overclocking, but additional heat will be converted into cabin temperature and damage!
	var/overclock_active = FALSE
	/// Speed multiplier for movement when overclocked
	var/overclock_speed_mult = 1.25
	/// Melee cooldown multiplier when overclocked
	var/overclock_melee_mult = 0.75
	/// How much additional heat can the mech sustain before blowing up?
	var/overclock_maximum_temp_mult = 2
	/// Whether the mech has an option to enable safe overclocking
	var/overclock_safety_available = FALSE
	/// Safely overclocked mechs will dump heat upon reaching the safe limit
	var/overclock_safety = FALSE
	/// How much heat is produced for every melee attack, double that when overclocking (but reduced by better servos!)
	var/melee_heat_production = 5
	/// How much heat is produced for every step while overclocking
	var/step_heat_production = 2
	/// Percentage of mech's health dealt as damage when it overheats
	/// If current health is below that amount, the mech will detonate instead!
	var/overheat_damage_percentage = 10
	/// Last tick when we increased our temperature
	var/last_heat_tick = 0
	/// Delay before the mech starts losing heat
	var/cooling_cooldown = 1 SECONDS
	/// How much heat is lost per second, this is in JOULES
	var/cooling_efficiency = 5 * MECHA_INTERNAL_HEAT_CAPACITY

	// ----- Effects-related -----
	/// Type of footsteps we play when moving. Can be null to prevent footsteps from playing
	var/step_sound = FOOTSTEP_OBJ_MECHA
	/// Sound played when the mech turns
	var/turn_sound = 'sound/vehicles/mecha/mechturn.ogg'
	/// Sound for melee attacks
	var/melee_sound = SFX_PUNCH
	/// Sound that plays when the mech destroys a wall
	var/destroy_wall_sound = 'sound/effects/meteorimpact.ogg'
	/// Mech's cached spark system
	var/datum/effect_system/spark_spread/spark_system
	/// Radius of heavy explosion upon our destruction
	var/heavy_ex_range = -1
	/// Radius of light explosion upon our destruction
	var/light_ex_range = 0
	/// Radius of flames upon our destruction
	var/flame_ex_range = 1

	// ----- Atmos-related -----
	/// Whether the cabin exchanges gases with the environment
	var/cabin_sealed = FALSE
	/// Internal air mix datum
	var/datum/gas_mixture/cabin_air
	/// Volume of the cabin
	var/cabin_volume = TANK_STANDARD_VOLUME * 3

	// ----- UI-related -----
	/// Theme of the mech TGUI
	var/ui_theme = "ntos"
	/// Module selected by default when mech UI is opened
	var/ui_selected_module_index
	/// ref to screen object that displays in the middle of the UI
	var/atom/movable/screen/map_view/ui_view

/datum/armor/sealed_mecha
	melee = 20
	bullet = 10
	bomb = 10
	fire = 100
	acid = 100

/obj/vehicle/sealed/mecha/Initialize(mapload, built_manually)
	. = ..()
	START_PROCESSING(SSobj, src)
	SSpoints_of_interest.make_point_of_interest(src)
	log_message("[src] created.", LOG_MECHA)

	ui_view = new()
	ui_view.generate_view("mech_view_[REF(src)]")
	RegisterSignal(src, COMSIG_LIGHT_EATER_ACT, PROC_REF(on_light_eater))

	spark_system = new()
	spark_system.set_up(2, 0, src)
	spark_system.attach(src)

	cabin_air = new(cabin_volume)
	if(!built_manually)
		populate_parts()
	update_access()
	set_wires(new wires_type(src))
	GLOB.mechas_list += src //global mech list

	prepare_huds()
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.huds)
		diag_hud.add_atom_to_hud(src)
	update_diag_health()
	update_diag_cell()
	update_diag_stat()
	update_appearance()

	AddElement(/datum/element/atmos_sensitive, mapload)
	become_hearing_sensitive(trait_source = ROUNDSTART_TRAIT)
	AddElement(/datum/element/falling_hazard, damage = 80, wound_bonus = 10, hardhat_safety = FALSE, crushes = TRUE)
	AddElement(/datum/element/hostile_machine)
	if (step_sound)
		AddElement(/datum/element/footstep, FOOTSTEP_OBJ_MECHA, 1, -4, sound_vary = TRUE, simplesteps = TRUE)

	if (mecha_flags & IS_ENCLOSED)
		add_traits(list(TRAIT_ASHSTORM_IMMUNE, TRAIT_SNOWSTORM_IMMUNE), ROUNDSTART_TRAIT)

	if (ispath(equip_by_category[MECHA_ARM_LEFT_SLOT]))
		var/equip_path = equip_by_category[MECHA_ARM_LEFT_SLOT]
		var/obj/item/mecha_equipment/left_arm = new equip_path(loc)
		left_arm.attach(src, MECHA_ARM_LEFT_SLOT)

	if (ispath(equip_by_category[MECHA_ARM_RIGHT_SLOT]))
		var/equip_path = equip_by_category[MECHA_ARM_RIGHT_SLOT]
		var/obj/item/mecha_equipment/right_arm = new equip_path(loc)
		right_arm.attach(src, MECHA_ARM_RIGHT_SLOT)

	for (var/utility_thing in equip_by_category[MECHA_UTILITY_SLOT])
		if (!ispath(utility_thing))
			continue
		var/obj/item/mecha_equipment/equip = new utility_thing(loc)
		equip.attach(src, MECHA_UTILITY_SLOT)

/obj/vehicle/sealed/mecha/Destroy()
	for (var/mob/to_eject in (contents|occupants))
		mob_exit(to_eject, silent = TRUE, forced = TRUE)

	for (var/obj/item/mecha_equipment/equip as anything in flat_equipment)
		equip.detach()
		qdel(equip)

	equip_by_category.Cut()
	flat_equipment.Cut()
	// Sign themselves up for our deletion
	active_malfunctions.Cut()
	STOP_PROCESSING(SSobj, src)

	QDEL_NULL(cell)
	QDEL_NULL(capacitor)
	QDEL_NULL(servo)
	QDEL_NULL(scanner)
	QDEL_NULL(cabin_air)
	QDEL_NULL(spark_system)
	QDEL_NULL(ui_view)
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.huds)
		diag_hud.remove_atom_from_hud(src)
	GLOB.mechas_list -= src
	return ..()

/// Add parts on mech spawning. Skipped in manual construction.
/obj/vehicle/sealed/mecha/proc/populate_parts()
	cell = new /obj/item/stock_parts/power_store/battery/high(src)
	capacitor = new /obj/item/stock_parts/capacitor(src)
	servo = new /obj/item/stock_parts/servo(src)
	scanner = new /obj/item/stock_parts/scanning_module(src)

/obj/vehicle/sealed/mecha/CheckParts(list/parts_list)
	. = ..()
	cell = locate(/obj/item/stock_parts/power_store/battery) in contents
	capacitor = locate(/obj/item/stock_parts/capacitor) in contents
	servo = locate(/obj/item/stock_parts/servo) in contents
	scanner = locate(/obj/item/stock_parts/scanning_module) in contents
	update_diag_cell()

/obj/vehicle/sealed/mecha/atom_destruction()
	spark_system?.start()
	loc.assume_air(cabin_air)

	var/mob/living/silicon/ai/unlucky_ai
	var/turf/cur_turf = get_turf(src)
	for(var/mob/living/occupant as anything in occupants)
		if(!isAI(occupant))
			mob_exit(occupant, forced = TRUE)
			if(!isbrain(occupant))
				occupant.SetSleeping(blowout_pilot_knockout)
			occupant.throw_at(get_edge_target_turf(cur_turf, pick(GLOB.alldirs)), 1, 1)
			continue

		var/mob/living/silicon/ai/ai = occupant
		if(ai.linked_core || ai.can_shunt) // We probably shouldnt gib AIs with a core or shunting abilities
			mob_exit(ai, silent = TRUE, forced = TRUE) // So we dont ghost the AI
			continue

		unlucky_ai = occupant
		ai.investigate_log("has been gibbed by having their mech destroyed.", INVESTIGATE_DEATHS)
		ai.gib(DROP_ALL_REMAINS) // No wreck, no AI to recover

	if (heavy_ex_range >= 0 || light_ex_range >= 0 || flame_ex_range >= 0)
		explosion(loc, heavy_impact_range = heavy_ex_range, light_impact_range = light_ex_range, flame_range = flame_ex_range)

	if (!wreck_type)
		return ..()

	var/obj/structure/mecha_wreckage/wreckage = new wreck_type(loc, unlucky_ai)
	for(var/obj/item/mecha_equipment/equip in flat_equipment)
		if(!equip.detachable || prob(MECHA_EQUIPMENT_DESTRUCTION_PROB))
			equip.detach()
			qdel(equip)
			continue

		equip.detach(wreckage)
		wreckage.crowbar_salvage += equip

	if(cell)
		wreckage.crowbar_salvage += cell
		cell.forceMove(wreckage)
		cell.use(rand(0, cell.charge), TRUE)
		cell = null

	return ..()

/obj/vehicle/sealed/mecha/update_icon_state()
	icon_state = get_occupant_icon_state()
	return ..()

/obj/vehicle/sealed/mecha/proc/get_occupant_icon_state()
	if((mecha_flags & SILICON_PILOT) && silicon_icon_state)
		return silicon_icon_state

	if(LAZYLEN(occupants))
		return base_icon_state

	return "[base_icon_state]-open"

/// Can be used to split control between multiple mobs
/obj/vehicle/sealed/mecha/auto_assign_occupant_flags(mob/rider)
	// COMP-units (MMIs and posibrains) get control based on whenever we currently have a pilot or not
	if (isbrain(rider))
		var/mob/living/brain/brain = rider
		var/obj/item/mmi/container = brain.container
		add_control_flags(brain, VEHICLE_CONTROL_SETTINGS)
		if (driver_amount())
			return
		add_control_flags(brain, VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_MELEE)
		if (mmi_full_control && !istype(container, /obj/item/mmi/posibrain))
			add_control_flags(brain, VEHICLE_CONTROL_EQUIPMENT)
		return

	if (driver_amount() < max_drivers)
		add_control_flags(rider, FULL_MECHA_CONTROL)

/obj/vehicle/sealed/mecha/proc/set_mouse_pointer()
	if(safety_enabled)
		mouse_pointer = ""
	else if(equipment_disabled)
		mouse_pointer = 'icons/effects/mouse_pointers/mecha_mouse-disable.dmi'
	else
		mouse_pointer = 'icons/effects/mouse_pointers/mecha_mouse.dmi'

	for(var/mob/mob_occupant as anything in occupants)
		mob_occupant.update_mouse_pointer()

/obj/vehicle/sealed/mecha/get_cell()
	return cell

/// Toggles weapons safety
/obj/vehicle/sealed/mecha/proc/set_safety(mob/user)
	safety_enabled = !safety_enabled
	if(safety_sound)
		SEND_SOUND(user, sound(safety_sound, volume = 25))
	balloon_alert(user, "equipment [safety_enabled ? "stowed" : "ready"]")
	set_mouse_pointer()
	SEND_SIGNAL(src, COMSIG_MECHA_SAFETIES_TOGGLE, user, safety_enabled)

/obj/vehicle/sealed/mecha/proc/restore_equipment()
	equipment_disabled = FALSE
	deltimer(equipment_reactivation_timer)
	for(var/mob/occupant as anything in occupants)
		SEND_SOUND(occupant, sound('sound/machines/high_tech_confirm.ogg', volume = 50))
		balloon_alert(occupant, "equipment rebooted!")
	set_mouse_pointer()

/obj/vehicle/sealed/mecha/generate_integrity_message()
	switch(atom_integrity / max_integrity)
		if(0.85 to INFINITY)
			return "It's fully intact."
		if(0.65 to 0.85)
			return "It's slightly damaged."
		if(0.45 to 0.65)
			return "It's badly damaged."
		if(0.25 to 0.45)
			return span_warning("It's heavily damaged.")
		else
			return span_warning("It's falling apart!")

/// Apply required accesses according to settings
/obj/vehicle/sealed/mecha/proc/update_access()
	req_access = one_access ? list() : accesses
	req_one_access = one_access ? accesses : list()

/// Electrocute user from power cell
/obj/vehicle/sealed/mecha/proc/shock(mob/living/user)
	if(!istype(user) || !get_charge())
		return FALSE
	do_sparks(5, TRUE, src)
	return electrocute_mob(user, cell, src, 0.7, TRUE)

/obj/vehicle/sealed/mecha/examine(mob/user)
	. = ..()
	if(LAZYLEN(flat_equipment))
		. += span_notice("It's equipped with:")
		for (var/obj/item/mecha_equipment/equipment as anything in flat_equipment)
			if (!HAS_TRAIT(equipment, TRAIT_HIDDEN_MECH_EQUIPMENT))
				. += span_notice("[icon2html(equipment, user)] \A [equipment].")

	if (mecha_flags & PANEL_OPEN)
		. += span_notice("The panel is open. You could use a <b>crowbar</b> to eject parts or lock the panel back with a <b>screwdriver</b>.")
		if (!capacitor)
			. += span_warning("It's missing a capacitor.")
		else if (capacitor.rating > 1)
			. += span_notice("[capacitor] is increasing maximum heat capacity by [(capacitor.rating - 1) * 10]%.")
		if (!servo)
			. += span_warning("It's missing a servo.")
		else if (servo.rating > 1)
			. += span_notice("[servo] is reducing overclock heat generation by [(servo.rating - 1) * 10]%")
		if (!scanner)
			. += span_warning("It's missing a scanning module.")
		else if (scanner.rating > 1)
			. += span_notice("[scanner] is increasing maximum structural complexity by [scanner.rating - 1] units.")
	else
		. += span_notice("You could unlock the maintenance cover with a <b>screwdriver</b>.")

	if (mecha_flags & IS_ENCLOSED)
		return

	if (mecha_flags & SILICON_PILOT)
		. += span_notice("[src] appears to be piloting itself.")
		return

	for (var/occupant in occupants)
		. += span_notice("You can see [occupant] inside.")

/obj/vehicle/sealed/mecha/proc/has_charge(amount)
	return get_charge() >= amount

/obj/vehicle/sealed/mecha/proc/get_charge()
	return cell?.charge

/obj/vehicle/sealed/mecha/proc/use_energy(amount)
	var/output = cell.use(amount)
	if (output)
		update_diag_cell()
	return output

/obj/vehicle/sealed/mecha/proc/give_power(amount)
	return cell?.give(amount)

/obj/vehicle/sealed/mecha/proc/get_maximum_heat()
	return maximum_heat * (1 + max(capacitor?.rating, 0) * 0.1)

/// Displays a special speech bubble when someone inside the mecha speaks
/obj/vehicle/sealed/mecha/proc/display_speech_bubble(datum/source, list/speech_args)
	SIGNAL_HANDLER
	var/list/speech_bubble_recipients = list()
	for (var/mob/listener in get_hearers_in_view(7, src))
		if (listener.client)
			speech_bubble_recipients += listener.client

	var/image/mech_speech = image('icons/mob/effects/talk.dmi', src, "machine[say_test(speech_args[SPEECH_MESSAGE])]", MOB_LAYER+1)
	mech_speech.pixel_x += (get_cached_width(src) - ICON_SIZE_X) / 2
	mech_speech.pixel_y += get_cached_height(src) - ICON_SIZE_Y
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(flick_overlay_global), mech_speech, speech_bubble_recipients, 3 SECONDS)

/// Toggles lights on/off
/obj/vehicle/sealed/mecha/proc/toggle_lights(mob/user, new_state = FALSE)
	if (!(mecha_flags & HAS_LIGHTS))
		if (user)
			balloon_alert(user, "no lights!")
		return

	if (mecha_flags & DESTROYED_LIGHTS)
		if (user)
			balloon_alert(user, "lights unresponsive!")
		return

	if (!light_on && new_state && get_charge() < power_to_energy(light_power_drain, scheduler = SSobj))
		if (user)
			balloon_alert(user, "no power!")
		return

	set_light_on(!light_on)
	playsound(src,'sound/machines/clockcult/brass_skewer.ogg', 40, TRUE)
	log_message("Toggled lights [light_on ? "on": "off"].", LOG_MECHA)

	for (var/mob/occupant as anything in occupants)
		balloon_alert(occupant, "lights [light_on ? "on": "off"]")
		var/datum/action/action = LAZYACCESSASSOC(occupant_actions, occupant, /datum/action/vehicle/sealed/mecha/toggle_lights)
		action?.build_all_button_icons()

/// Toggles strafing on and off
/obj/vehicle/sealed/mecha/proc/toggle_strafe(mob/user)
	if (!(mecha_flags & CAN_STRAFE))
		balloon_alert(user, "cannot strafe!")
		return

	strafing = !strafing
	for (var/mob/occupant as anything in occupants)
		balloon_alert(occupant, "strafing [strafing ? "on" : "off"]")
		occupant.playsound_local(src, 'sound/machines/terminal/terminal_eject.ogg', 50, TRUE)
		var/datum/action/action = LAZYACCESSASSOC(occupant_actions, occupant, /datum/action/vehicle/sealed/mecha/toggle_strafe)
		action?.build_all_button_icons()

	log_message("Toggled strafing mode [strafing ? "on" : "off"].", LOG_MECHA)

/// Seals or unseals the cabin, either filling it with external air or dumping the air outside
/obj/vehicle/sealed/mecha/proc/set_cabin_seal(mob/user, seal_state)
	if (!(mecha_flags & IS_ENCLOSED))
		balloon_alert(user, "cabin can't be sealed!")
		return

	if (TIMER_COOLDOWN_RUNNING(src, COOLDOWN_MECHA_CABIN_SEAL))
		balloon_alert(user, "on cooldown!")
		return

	TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_CABIN_SEAL, 1 SECONDS)
	cabin_sealed = seal_state

	var/datum/gas_mixture/environment_air = loc?.return_air()
	if (!isnull(environment_air))
		if (cabin_sealed)
			// Fill cabin with air
			environment_air.pump_gas_to(cabin_air, environment_air.return_pressure())
		else
			// Dump cabin air
			var/datum/gas_mixture/removed_gases = cabin_air.remove_ratio(1)
			if (loc)
				loc.assume_air(removed_gases)
			else
				qdel(removed_gases)

	log_message("Cabin [cabin_sealed ? "sealed" : "unsealed"].", LOG_MECHA)
	if (cabin_sealed)
		playsound(src, 'sound/items/internals/internals_on.ogg', 50, TRUE)
	else
		playsound(src, 'sound/items/internals/internals_off.ogg', 50, TRUE)

	for (var/mob/occupant as anything in occupants)
		balloon_alert(occupant, "cabin [cabin_sealed ? "sealed" : "unsealed"]")
		var/datum/action/action = LAZYACCESSASSOC(occupant_actions, occupant, /datum/action/vehicle/sealed/mecha/toggle_cabin_seal)
		action?.build_all_button_icons()
	/*

	var/obj/item/mecha_equipment/air_tank/tank = locate(/obj/item/mecha_equipment/air_tank) in equip_by_category[MECHA_UTILITY]
	for(var/mob/occupant as anything in occupants)
		var/datum/action/action = locate(/datum/action/vehicle/sealed/mecha/mech_toggle_cabin_seal) in occupant.actions
		if(!isnull(tank) && cabin_sealed && tank.auto_pressurize_on_seal)
			if(!tank.active)
				tank.set_active(TRUE)
			else
				action.button_icon_state = "mech_cabin_pressurized"
				action.build_all_button_icons()
	*/

/obj/vehicle/sealed/mecha/generate_actions()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/eject)
	if (mecha_flags & IS_ENCLOSED)
		initialize_controller_action_type(/datum/action/vehicle/sealed/mecha/toggle_cabin_seal, VEHICLE_CONTROL_SETTINGS)
	if (mecha_flags & HAS_LIGHTS)
		initialize_controller_action_type(/datum/action/vehicle/sealed/mecha/toggle_lights, VEHICLE_CONTROL_SETTINGS)
	initialize_controller_action_type(/datum/action/vehicle/sealed/mecha/toggle_safeties, VEHICLE_CONTROL_SETTINGS)
	initialize_controller_action_type(/datum/action/vehicle/sealed/mecha/view_stats, VEHICLE_CONTROL_SETTINGS)
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/toggle_overclock, VEHICLE_CONTROL_SETTINGS)
	initialize_controller_action_type(/datum/action/vehicle/sealed/mecha/toggle_strafe, VEHICLE_CONTROL_DRIVE)

/*

///Locate an internal tack in the utility modules
/obj/vehicle/sealed/mecha/proc/get_internal_tank()
	var/obj/item/mecha_equipment/air_tank/module = locate(/obj/item/mecha_equipment/air_tank) in equip_by_category[MECHA_UTILITY]
	return module?.internal_tank

/obj/vehicle/sealed/mecha/proc/process_overclock_effects(seconds_per_tick)
	if(!overclock_mode && overclock_temp > 0)
		overclock_temp -= seconds_per_tick
		return
	var/temp_gain = seconds_per_tick * (1 + 1 / movedelay)
	overclock_temp = min(overclock_temp + temp_gain, overclock_temp_danger * 2)
	if(overclock_temp < overclock_temp_danger)
		return
	if(overclock_temp >= overclock_temp_danger && overclock_safety)
		toggle_overclock(FALSE)
		return
	var/damage_chance = 100 * ((overclock_temp - overclock_temp_danger) / (overclock_temp_danger * 2))
	if(SPT_PROB(damage_chance, seconds_per_tick))
		do_sparks(5, TRUE, src)
		try_deal_internal_damage(damage_chance)
		take_damage(seconds_per_tick, BURN, 0, 0)

/obj/vehicle/sealed/mecha/proc/process_internal_damage_effects(seconds_per_tick)
	if(internal_damage & MECHA_INT_FIRE)
		if(!(internal_damage & MECHA_INT_TEMP_CONTROL) && SPT_PROB(2.5, seconds_per_tick))
			clear_internal_damage(MECHA_INT_FIRE)
		if(cabin_air && cabin_sealed && cabin_air.return_volume()>0)
			if(cabin_air.return_pressure() > (PUMP_DEFAULT_PRESSURE * 30) && !(internal_damage & MECHA_CABIN_AIR_BREACH))
				set_internal_damage(MECHA_CABIN_AIR_BREACH)
			cabin_air.temperature = min(6000+T0C, cabin_air.temperature+rand(5,7.5)*seconds_per_tick)

	if(internal_damage & MECHA_CABIN_AIR_BREACH && cabin_air && cabin_sealed) //remove some air from cabin_air
		var/datum/gas_mixture/leaked_gas = cabin_air.remove_ratio(SPT_PROB_RATE(0.05, seconds_per_tick))
		if(loc)
			loc.assume_air(leaked_gas)
		else
			qdel(leaked_gas)

	if(internal_damage & MECHA_INT_SHORT_CIRCUIT && get_charge())
		spark_system.start()
		var/damage_energy_consumption = 0.005 * STANDARD_CELL_CHARGE * seconds_per_tick
		use_energy(damage_energy_consumption)
		cell.maxcharge -= min(damage_energy_consumption, cell.maxcharge)

/obj/vehicle/sealed/mecha/proc/process_occupants(seconds_per_tick)
	for(var/mob/living/occupant as anything in occupants)
		if(!(mecha_flags & IS_ENCLOSED) && occupant?.incapacitated) //no sides mean it's easy to just sorta fall out if you're incapacitated.
			mob_exit(occupant, randomstep = TRUE) //bye bye
			continue
		if(cell && cell.maxcharge)
			var/cellcharge = cell.charge/cell.maxcharge
			switch(cellcharge)
				if(0.75 to INFINITY)
					occupant.clear_alert(ALERT_CHARGE)
				if(0.5 to 0.75)
					occupant.throw_alert(ALERT_CHARGE, /atom/movable/screen/alert/lowcell/mech, 1)
				if(0.25 to 0.5)
					occupant.throw_alert(ALERT_CHARGE, /atom/movable/screen/alert/lowcell/mech, 2)
				if(0.01 to 0.25)
					occupant.throw_alert(ALERT_CHARGE, /atom/movable/screen/alert/lowcell/mech, 3)
				else
					occupant.throw_alert(ALERT_CHARGE, /atom/movable/screen/alert/emptycell/mech)
		else
			occupant.throw_alert(ALERT_CHARGE, /atom/movable/screen/alert/nocell)
		var/integrity = atom_integrity/max_integrity*100
		switch(integrity)
			if(30 to 45)
				occupant.throw_alert(ALERT_MECH_DAMAGE, /atom/movable/screen/alert/low_mech_integrity, 1)
			if(15 to 35)
				occupant.throw_alert(ALERT_MECH_DAMAGE, /atom/movable/screen/alert/low_mech_integrity, 2)
			if(-INFINITY to 15)
				occupant.throw_alert(ALERT_MECH_DAMAGE, /atom/movable/screen/alert/low_mech_integrity, 3)
			else
				occupant.clear_alert(ALERT_MECH_DAMAGE)
		var/atom/checking = occupant.loc
		// recursive check to handle all cases regarding very nested occupants,
		// such as brainmob inside brainitem inside MMI inside mecha
		while(!isnull(checking))
			if(isturf(checking))
				// hit a turf before hitting the mecha, seems like they have been moved out
				occupant.clear_alert(ALERT_CHARGE)
				occupant.clear_alert(ALERT_MECH_DAMAGE)
				occupant = null
				break
			else if (checking == src)
				break  // all good
			checking = checking.loc
	//Diagnostic HUD updates
	diag_hud_set_mechhealth()
	diag_hud_set_mechcell()
	diag_hud_set_mechstat()

/// Toggle mech overclock with a button or by hacking
/obj/vehicle/sealed/mecha/proc/toggle_overclock(forced_state = null)
	if(!isnull(forced_state))
		if(overclock_mode == forced_state)
			return
		overclock_mode = forced_state
	else
		overclock_mode = !overclock_mode
	log_message("Toggled overclocking.", LOG_MECHA)

	for(var/mob/occupant as anything in occupants)
		var/datum/action/act = locate(/datum/action/vehicle/sealed/mecha/mech_overclock) in occupant.actions
		if(!act)
			continue
		act.button_icon_state = "mech_overload_[overclock_mode ? "on" : "off"]"
		balloon_alert(occupant, "overclock [overclock_mode ? "on":"off"]")
		act.build_all_button_icons()

	if(overclock_mode)
		movedelay = movedelay / overclock_coeff
		visible_message(span_notice("[src] starts heating up, making humming sounds."))
	else
		movedelay = initial(movedelay)
		visible_message(span_notice("[src] cools down and the humming stops."))
	update_energy_drain()

*/
