#define CORRAL_INTERFACE_NORTH_OFFSET 3

/obj/machinery/corral_generator
	name = "corral field generator"
	desc = "A bulky machine with corral field projectors on its side. Position two of these in a straight line and they'll create a corral field which prevents animals from passing through it."
	icon = 'icons/obj/science/xenobiology.dmi'
	icon_state = "corral_pylon"
	base_icon_state = "corral_pylon"

	density = TRUE
	anchored = TRUE
	circuit = /obj/item/circuitboard/machine/corral_generator
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 0.02

	light_range = 2.5
	light_power = 2
	light_color = LIGHT_COLOR_LIGHT_CYAN

	/// Maximum distance at which we'll be looking for other field generators
	var/max_range = 9
	/// In what directions we are going to look for fields
	/// Cannot use TEXT_{direction} because a constant expression is required
	var/list/corner_status = list("1" = TRUE, "2" = TRUE, "4" = TRUE, "8" = TRUE)
	/// All fields created by this generator
	var/list/fields = list()
	/// All linked corral generators
	var/list/other_generators = list()
	/// Overlays for active links
	var/list/active_overlays = list()
	var/list/active_emissives = list()
	/// Overlays for the attached corral interface
	var/mutable_appearance/interface_overlay
	var/mutable_appearance/interface_emissive
	/// How much damage we can sustain
	var/max_charge = CORRAL_GENERATOR_BASE_CHARGE
	/// Whats the current charge
	var/charge = CORRAL_GENERATOR_BASE_CHARGE
	/// Are we currently active?
	var/active = TRUE
	/// Have we taken damage recently and not currently recovering?
	var/damage_taken = FALSE
	/// Damage recovery timer
	var/recovery_timer

	/// Attached interface. Unarmed click will be passed to it in order to open the interface
	var/obj/item/slime_corral_interface/attached_interface
	/// What direction has the interface been attached from
	var/interface_direction = SOUTH

/obj/machinery/corral_generator/post_machine_initialize()
	. = ..()
	set_light(l_on = FALSE)
	if (active)
		locate_links()

/obj/machinery/corral_generator/Destroy(force)
	active = FALSE
	for (var/direction in GLOB.cardinals)
		cleanup(direction)
	. = ..()

/obj/machinery/corral_generator/Moved()
	. = ..()

	for (var/direction in GLOB.cardinals)
		cleanup(direction)

	if (active && anchored)
		locate_links()

/obj/machinery/corral_generator/emp_act(severity)
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_SELF)
		return

	adjust_charge(-rand(0.2, 0.4) * severity * max_charge)

/obj/machinery/corral_generator/proc/adjust_charge(amount)
	charge = clamp(charge + amount, 0, max_charge)

	if (amount < 0)
		damage_taken = TRUE
		recovery_timer = addtimer(CALLBACK(src, PROC_REF(reset_damage_taken)), CORRAL_GENERATOR_RECOVERY_TIMER, TIMER_UNIQUE|TIMER_OVERRIDE)

	if (charge == 0)
		deactivate()
		return

	if (active || charge < max_charge)
		return

	activate()

/obj/machinery/corral_generator/proc/reset_damage_taken()
	damage_taken = FALSE

/obj/machinery/corral_generator/proc/activate()
	active = TRUE
	if (anchored)
		locate_links()

/obj/machinery/corral_generator/proc/deactivate()
	active = FALSE
	charge = 0
	for (var/direction in GLOB.cardinals)
		cleanup(direction)
	do_sparks(2, FALSE, src)
	set_light(l_on = FALSE)

/obj/machinery/corral_generator/power_change()
	. = ..()
	if (!powered())
		deactivate()
		return

	if (charge == max_charge)
		activate()

/obj/machinery/corral_generator/process()
	if (charge == max_charge || (machine_stat & (NOPOWER|BROKEN)) || damage_taken)
		return

	adjust_charge(CORRAL_GENERATOR_RECOVERY * 2)
	use_energy(active_power_usage)

/obj/machinery/corral_generator/proc/locate_links()
	for (var/direction in GLOB.cardinals)
		if (!corner_status["[direction]"] || other_generators["[direction]"])
			continue

		var/turf/current_turf = loc
		var/list/field_turfs = list()
		for (var/step in 1 to max_range)
			current_turf = get_step(current_turf, direction)

			if (current_turf.density)
				break

			var/obj/machinery/corral_generator/other_generator
			var/found_blocker = FALSE
			for (var/obj/thing in current_turf)
				if (istype(thing, /obj/machinery/corral_generator))
					other_generator = thing
					continue

				// Do not cross the beams!
				// We still want to be able to slot additional generators between live beams
				if (istype(thing, /obj/structure/corral_fence) && thing.dir != direction && thing.dir != REVERSE_DIR(direction))
					found_blocker = TRUE
					break

			if (found_blocker)
				break

			if (!isnull(other_generator) && other_generator.corner_status["[REVERSE_DIR(direction)]"])
				setup_field(direction, field_turfs, other_generator)
				break

			field_turfs += current_turf

/obj/machinery/corral_generator/proc/setup_field(direction, list/field_turfs, obj/machinery/corral_generator/other_generator)
	if (other_generator.other_generators["[REVERSE_DIR(direction)]"])
		other_generator.cleanup(REVERSE_DIR(direction))

	var/list/new_fields = list()
	for (var/turf/field_turf in field_turfs)
		var/obj/structure/corral_fence/fence = new(field_turf)
		fence.generator1 = src
		fence.generator2 = other_generator
		fence.setDir(direction)
		new_fields += fence

	//fields["[direction]"] = new_fields //TODO: FIX BULLSHIT ERROR
 	other_generator.fields["[REVERSE_DIR(direction)]"] = new_fields
	other_generators["[direction]"] = other_generator
	other_generator.other_generators["[REVERSE_DIR(direction)]"] = src
	update_appearance()
	other_generator.update_appearance()
	set_light(l_on = TRUE)

/obj/machinery/corral_generator/proc/cleanup(direction)
	if (!other_generators["[direction]"])
		return

	var/obj/machinery/corral_generator/other_gen = other_generators["[direction]"]
	other_gen.other_generators -= "[REVERSE_DIR(direction)]"
	other_generators -= "[direction]"
	other_gen.fields -= "[REVERSE_DIR(direction)]"

	var/list/fields_dir = fields["[direction]"]
	fields -= "[direction]"
	playsound(fields_dir[ceil(fields_dir.len / 2)], SFX_SHATTER, 70, TRUE)
	QDEL_LIST(fields_dir)
	if (!other_generators.len)
		set_light(l_on = FALSE)
	update_appearance()
	other_gen.update_appearance()

/obj/machinery/corral_generator/proc/remove_direction_overlay(direction)
	if (!other_generators.len)
		set_light(l_on = FALSE)
	update_appearance()

/obj/machinery/corral_generator/update_icon_state()
	icon_state = "[base_icon_state][!corner_status["[NORTH]"] ? "_closed" : ""][!corner_status["[SOUTH]"] ? "_flat" : ""]"
	. = ..()

/obj/machinery/corral_generator/update_overlays()
	. = ..()
	if (!active_overlays.len)
		for (var/direction in GLOB.cardinals)
			var/mutable_appearance/mutable = mutable_appearance(icon, "corral_field_link", src, layer = BELOW_MOB_LAYER)
			var/mutable_appearance/emissive = emissive_appearance(icon, "corral_field_link", src, layer = BELOW_MOB_LAYER, alpha = 200)
			mutable.dir = direction
			emissive.dir = direction
			active_overlays["[direction]"] = mutable
			active_emissives["[direction]"] = emissive

		interface_overlay = mutable_appearance(icon, "corral_interface", src, layer = ABOVE_OBJ_LAYER)
		interface_emissive = emissive_appearance(icon, "corral_interface_emissive", src, layer = ABOVE_OBJ_LAYER)

	for (var/direction in other_generators)
		. += active_overlays[direction]
		. += active_emissives[direction]

	if (!isnull(attached_interface))
		interface_overlay.dir = interface_direction
		interface_emissive.dir = interface_direction
		interface_overlay.pixel_y = (interface_direction == NORTH) ? CORRAL_INTERFACE_NORTH_OFFSET : 0
		interface_emissive.pixel_y = (interface_direction == NORTH) ? CORRAL_INTERFACE_NORTH_OFFSET : 0
		. += interface_overlay
		. += interface_emissive

/obj/machinery/corral_generator/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if (!isnull(attached_interface))
		attached_interface.ui_interact(user)

/obj/structure/corral_fence
	name = "corral fence"
	desc = "A holographic fence designed to prevent slimes from leaving. Takes some effort to pass through."
	icon = 'icons/obj/science/xenobiology.dmi'
	icon_state = "corral_field"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	move_resist = INFINITY
	anchored = TRUE
	can_atmos_pass = ATMOS_PASS_NO
	can_astar_pass = CANASTARPASS_ALWAYS_PROC
	layer = BELOW_MOB_LAYER
	light_range = 1.5
	light_power = 0.7
	light_color = LIGHT_COLOR_LIGHT_CYAN
	pass_flags_self = null
	armor_type = /datum/armor/corral_fence
	/// Enable to let living beings pass through
	var/quick_disabled = FALSE
	/// Generator that has created us
	var/obj/machinery/corral_generator/generator1
	/// Other generator that we're linked to
	var/obj/machinery/corral_generator/generator2
	/// Emissive appearance for ourselves
	var/mutable_appearance/emissive
	/// List of people currently trying to enter us. Used to prevent snimation and message spam
	var/list/moving_into = list()

/datum/armor/corral_fence
	melee = 25
	bio = 75
	fire = 100
	acid = 100

/obj/structure/corral_fence/Initialize(mapload)
	. = ..()
	emissive = emissive_appearance(icon, icon_state, src, alpha = 200)
	update_appearance()
	RegisterSignal(loc, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
	START_PROCESSING(SSobj, src)

/obj/structure/corral_fence/Destroy(force)
	STOP_PROCESSING(SSobj, src)
	UnregisterSignal(loc, COMSIG_ATOM_ENTERED)
	. = ..()

/obj/structure/corral_fence/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)
	playsound(loc, 'sound/effects/empulse.ogg', 75, -2)
	flick("corral_field_glitch", src)
	flick("corral_field_glitch", emissive)
	generator1.adjust_charge(-damage_amount)
	generator2.adjust_charge(-damage_amount)

/obj/structure/corral_fence/process(seconds_per_tick)
	. = ..()
	var/charge_avg = (generator1.charge / generator1.max_charge + generator2.charge / generator2.max_charge) / 2
	if (prob(3 + 10 * (1 - charge_avg)))
		flick("corral_field_glitch", src)
		flick("corral_field_glitch", emissive)

/obj/structure/corral_fence/CanPass(atom/movable/mover, border_dir)
	// Human-exclusive passcode is in Bumped()
	if(isliving(mover) && !quick_disabled)
		return FALSE
	return ..()

/obj/structure/corral_fence/update_overlays()
	. = ..()
	. += emissive

// Only humans can pass through, and they usually don't use A*
/obj/structure/corral_fence/CanAStarPass(to_dir, datum/can_pass_info/pass_info)
	return FALSE

/obj/structure/corral_fence/Bumped(atom/movable/bumped_atom)
	. = ..()

	if (bumped_atom in moving_into)
		return

	flick("corral_field_glitch", src)
	flick("corral_field_glitch", emissive)

	if (!ishuman(bumped_atom))
		return

	var/mob/living/carbon/human/passerby = bumped_atom
	to_chat(passerby, span_notice("You attempt to force your way through [src]"))
	moving_into += passerby
	if (!do_after(passerby, CORRAL_FIELD_PASS_DELAY, passerby, timed_action_flags = IGNORE_HELD_ITEM | IGNORE_SLOWDOWNS))
		moving_into -= passerby
		return

	moving_into -= passerby
	quick_disabled = TRUE
	bumped_atom.Move(loc)
	quick_disabled = FALSE

/obj/structure/corral_fence/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if (arrived.invisibility)
		return

	flick("corral_field_glitch", src)
	flick("corral_field_glitch", emissive)

#undef CORRAL_INTERFACE_NORTH_OFFSET
