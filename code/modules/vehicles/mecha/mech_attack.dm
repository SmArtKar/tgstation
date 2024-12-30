

/// Called when a driver clicks somewhere. Handles everything like equipment, punches, etc.
/obj/vehicle/sealed/mecha/proc/on_mouseclick(mob/living/user, atom/target, list/modifiers)
	SIGNAL_HANDLER

	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		set_safety(user)
		return COMSIG_MOB_CANCEL_CLICKON

	if(safety_enabled)
		return

	// For AIs: If safeties are off, use mech functions. If safeties are on, use AI functions.
	if(isAI(user))
		. = COMSIG_MOB_CANCEL_CLICKON

	// Allows things to be examined.
	if(modifiers[SHIFT_CLICK])
		return

	// Inventory still should work
	if (!isturf(target) || !isturf(target.loc))
		return

	if (currently_ejecting || (mecha_flags & MECH_ACTIONS_DISABLED))
		return

	if (blocking_state)
		balloon_alert(user, "not while [blocking_state]!")
		return

	if(user.incapacitated)
		return

	if(!get_charge())
		return

	var/dir_to_target = get_dir(src, target)
	// Mechs can still make a hole in your face in melee unless you're directly behind them
	if (!(mecha_flags & OMNIDIRECTIONAL_ATTACKS) && dir_to_target)
		if ((get_dist(src, target) > 1 && !(dir_to_target & dir)) || (dir_to_target & REVERSE_DIR(dir)))
			setDir(dir_to_target)
			if (!(mecha_flags & RAPID_TURNING))
				return

	var/obj/item/mecha_equipment/selected
	if(modifiers[RIGHT_CLICK])
		selected = equip_by_category[MECHA_ARM_LEFT_SLOT]
	else
		selected = equip_by_category[MECHA_ARM_RIGHT_SLOT]

	if (selected && (user in return_controllers_with_flag(VEHICLE_CONTROL_EQUIPMENT)))
		if(selected.can_use(user, target))
			if(HAS_TRAIT(user, TRAIT_PACIFISM) && selected.harmful)
				to_chat(user, span_warning("You don't want to harm other living beings!"))
				return

			var/signal_result = SEND_SIGNAL(src, COMSIG_MECHA_EQUIPMENT_CLICK, user, target)
			if(signal_result & COMPONENT_CANCEL_EQUIPMENT_CLICK)
				return

			if (signal_result & COMPONENT_RANDOMIZE_EQUIPMENT_CLICK)
				target = pick(oview(Adjacent(src, target) ? 1 : 3, src)) || target

			INVOKE_ASYNC(selected, TYPE_PROC_REF(/obj/item/mecha_equipment, action), user, target, modifiers)
			return

	if(!(user in return_controllers_with_flag(VEHICLE_CONTROL_MELEE)))
		balloon_alert(user, "no control!")
		return

	var/on_cooldown = TIMER_COOLDOWN_RUNNING(src, COOLDOWN_MECHA_MELEE_ATTACK)
	var/adjacent = Adjacent(target)
	var/signal_result = SEND_SIGNAL(src, COMSIG_MECHA_MELEE_CLICK, user, target, on_cooldown, adjacent)

	if(signal_result & COMPONENT_CANCEL_MELEE_CLICK)
		return

	if (signal_result & COMPONENT_RANDOMIZE_MELEE_CLICK)
		target = pick(oview(1, src)) || target

	if(on_cooldown || !adjacent)
		return

	if(!has_charge(melee_energy_drain))
		return

	use_energy(melee_energy_drain)

	SEND_SIGNAL(user, COMSIG_MOB_USED_CLICK_MECH_MELEE, src)
	if(target.mech_melee_attack(src, user))
		TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MELEE_ATTACK, melee_cooldown)

/// Alt clicking toggles strafing
/obj/vehicle/sealed/mecha/proc/on_click_alt(mob/user, atom/target, params)
	SIGNAL_HANDLER
	. = COMSIG_MOB_CANCEL_CLICKON // Cancel base_click_alt
	if(target != src)
		return

	if(!(user in occupants))
		return

	if(!(user in return_controllers_with_flag(VEHICLE_CONTROL_DRIVE)))
		balloon_alert(user, "cannot control!")
		return

	toggle_strafe()

/obj/vehicle/sealed/mecha/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect && !visual_effect_icon)
		switch (damtype)
			if (BURN)
				visual_effect_icon = ATTACK_EFFECT_MECHFIRE
			if(TOX)
				visual_effect_icon = ATTACK_EFFECT_MECHTOXIN
			else
				visual_effect_icon = ATTACK_EFFECT_SMASH
	..()

/atom/proc/mech_melee_attack(obj/vehicle/sealed/mecha/mecha_attacker, mob/living/user)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_MECH, mecha_attacker, user)
	if(!isnull(user))
		log_combat(user, src, "attacked", mecha_attacker, "(COMBAT MODE: [uppertext(user?.combat_mode)] (DAMTYPE: [uppertext(mecha_attacker.damtype)])")
	return

/turf/closed/wall/mech_melee_attack(obj/vehicle/sealed/mecha/mecha_attacker, mob/living/user)
	if(!user.combat_mode)
		return

	mecha_attacker.do_attack_animation(src)
	playsound(src, mecha_attacker.melee_sound, 50, TRUE)
	var/attack_verb = pick(mecha_attacker.attack_verbs)
	mecha_attacker.visible_message(span_danger("[mecha_attacker] [attack_verb]s [src]!"), vision_distance = COMBAT_MESSAGE_RANGE, ignored_mobs = mecha_attacker.return_drivers())
	// COMP units also get the message
	for (var/mob/living/driver as anything in mecha_attacker.return_drivers())
		to_chat(driver, span_danger("You [attack_verb] [src]!"))

	if(prob(hardness + mecha_attacker.force) && mecha_attacker.force > 20)
		dismantle_wall(TRUE)
		playsound(src, mecha_attacker.destroy_wall_sound, 100, TRUE)
	else
		add_dent(WALL_DENT_HIT)
	..()
	return TRUE

/obj/structure/mech_melee_attack(obj/vehicle/sealed/mecha/mecha_attacker, mob/living/user)
	if(!user.combat_mode)
		return

	mecha_attacker.do_attack_animation(src)
	playsound(src, mecha_attacker.melee_sound, 50, TRUE)
	var/attack_verb = pick(mecha_attacker.attack_verbs)
	mecha_attacker.visible_message(span_danger("[mecha_attacker] [attack_verb]s [src]!"), vision_distance = COMBAT_MESSAGE_RANGE, ignored_mobs = user)
	if (user)
		to_chat(user, span_danger("You [attack_verb] [src]!"))
	..()
	take_damage(mecha_attacker.force * mecha_attacker.demolition_mod, mecha_attacker.damtype, MELEE, FALSE, get_dir(src, mecha_attacker), mecha_attacker.armour_penetration)
	return TRUE

/obj/machinery/mech_melee_attack(obj/vehicle/sealed/mecha/mecha_attacker, mob/living/user)
	if(!user.combat_mode)
		return

	mecha_attacker.do_attack_animation(src)
	playsound(src, mecha_attacker.melee_sound, 50, TRUE)
	var/attack_verb = pick(mecha_attacker.attack_verbs)
	mecha_attacker.visible_message(span_danger("[mecha_attacker] [attack_verb]s [src]!"), vision_distance = COMBAT_MESSAGE_RANGE, ignored_mobs = user)
	if (user)
		to_chat(user, span_danger("You [attack_verb] [src]!"))
	..()
	take_damage(mecha_attacker.force * mecha_attacker.demolition_mod, mecha_attacker.damtype, MELEE, FALSE, get_dir(src, mecha_attacker), mecha_attacker.armour_penetration)
	return TRUE

/obj/structure/window/mech_melee_attack(obj/vehicle/sealed/mecha/mecha_attacker, mob/living/user)
	if(!can_be_reached())
		return
	return ..()

/obj/machinery/mech_melee_attack(obj/vehicle/sealed/mecha/mecha_attacker, mob/living/user)
	if(!user.combat_mode)
		return

	mecha_attacker.do_attack_animation(src)
	playsound(src, mecha_attacker.melee_sound, 50, TRUE)
	var/attack_verb = pick(mecha_attacker.attack_verbs)
	mecha_attacker.visible_message(span_danger("[mecha_attacker] [attack_verb]s [src]!"),  vision_distance = COMBAT_MESSAGE_RANGE, ignored_mobs = user)
	if (user)
		to_chat(user, span_danger("You [attack_verb] [src]!"))
	..()
	// No demolition mod as this also applies in mech to mech combat
	take_damage(mecha_attacker.force, mecha_attacker.damtype, MELEE, FALSE, get_dir(src, mecha_attacker), mecha_attacker.armour_penetration)
	return TRUE

/mob/living/mech_melee_attack(obj/vehicle/sealed/mecha/mecha_attacker, mob/living/user)
	if(istype(user) && !user.combat_mode)
		log_combat(user, src, "pushed", mecha_attacker)
		if (!step_away(src, mecha_attacker))
			return
		visible_message(span_warning("[mecha_attacker] pushes [src] out of the way."),\
			span_warning("[mecha_attacker] pushes you out of the way!"),\
			span_hear("You hear aggressive shuffling!"),\
			vision_distance = COMBAT_MESSAGE_RANGE,\
			ignored_mobs = user)
		if (user)
			to_chat(user, span_danger("You push [src] out of your way."))
		return

	if(!isnull(user) && HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("You don't want to harm other living beings!"))
		return

	. = ..()
	mecha_attacker.do_attack_animation(src)
	playsound(src, mecha_attacker.melee_sound, 50, TRUE)
	var/attack_verb = pick(mecha_attacker.attack_verbs)
	mecha_attacker.visible_message(span_danger("[mecha_attacker] [attack_verb]s [src]!"), vision_distance = COMBAT_MESSAGE_RANGE, ignored_mobs = user)
	if (user)
		to_chat(user, span_danger("You [attack_verb] [src]!"))

	// Snowflake toxin damage into reagents
	if (mecha_attacker.damtype == TOX)
		var/bio_armor = (100 - run_armor_check(def_zone = get_random_valid_zone(user?.zone_selected, even_weights = TRUE), attack_flag = BIO, armour_penetration = mecha_attacker.armour_penetration)) / 100
		if(reagents.get_reagent_amount(/datum/reagent/cryptobiolin) < mecha_attacker.force)
			reagents.add_reagent(/datum/reagent/cryptobiolin, mecha_attacker.force / 2 * bio_armor)
		if(reagents.get_reagent_amount(/datum/reagent/toxin) < mecha_attacker.force)
			reagents.add_reagent(/datum/reagent/toxin, mecha_attacker.force / 2 * bio_armor)
		return TRUE

	var/def_zone = get_random_valid_zone(user?.zone_selected, even_weights = TRUE)
	var/zone_readable = parse_zone_with_bodypart(def_zone)
	var/damage_dealt = apply_damage(mecha_attacker.force, mecha_attacker.damtype, def_zone, run_armor_check(
		def_zone = def_zone,
		attack_flag = MELEE,
		absorb_text = span_notice("Your armor has protected your [zone_readable]!"),
		soften_text = span_warning("Your armor has softened a hit to your [zone_readable]!"),
		armour_penetration = mecha_attacker.armour_penetration,
	))
	mecha_attacker.melee_attack_effect(src, damage_dealt, user)
	return TRUE

/obj/vehicle/sealed/mecha/proc/melee_attack_effect(mob/living/victim, damage_dealt, mob/living/user)
	if (damage_dealt >= MECHA_MELEE_THROW_DAMAGE)
		throw_at(get_edge_target_turf(victim, get_dir(src, victim)), 2, 1, user)
	else if (damage_dealt >= MECHA_MELEE_PUSH_DAMAGE)
		step_away(victim, src, 15)

	if(damage_dealt > MECHA_MELEE_KNOCKOUT_DAMAGE)
		victim.Unconscious(2 SECONDS)
	// Don't chain knockdown
	if (damage_dealt > MECHA_MELEE_KNOCKDOWN_DAMAGE && !victim.IsKnockdown())
		victim.Knockdown(4 SECONDS)
