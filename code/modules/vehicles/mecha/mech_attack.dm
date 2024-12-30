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
	return 100 //this is an arbitrary "damage" number since the actual damage is rng dismantle

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
	return take_damage(mecha_attacker.force * mecha_attacker.demolition_mod, mecha_attacker.damtype, MELEE, FALSE, get_dir(src, mecha_attacker), armour_penetration)

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
	return take_damage(mecha_attacker.force * mecha_attacker.demolition_mod, mecha_attacker.damtype, MELEE, FALSE, get_dir(src, mecha_attacker), armour_penetration)

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
	mecha_attacker.visible_message(span_danger("[mecha_attacker] [attack_verb]s [src]!"), vision_distance = COMBAT_MESSAGE_RANGE, ignored_mobs = user)
	if (user)
		to_chat(user, span_danger("You [attack_verb] [src]!"))
	..()
	// No demolition mod as this also applies in mech to mech combat
	return take_damage(mecha_attacker.force, mecha_attacker.damtype, MELEE, FALSE, get_dir(src, mecha_attacker), armour_penetration)

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

	mecha_attacker.do_attack_animation(src)
	playsound(src, mecha_attacker.melee_sound, 50, TRUE)
	var/attack_verb = pick(mecha_attacker.attack_verbs)
	mecha_attacker.visible_message(span_danger("[mecha_attacker] [attack_verb]s [src]!"), vision_distance = COMBAT_MESSAGE_RANGE, ignored_mobs = user)
	if (user)
		to_chat(user, span_danger("You [attack_verb] [src]!"))

	// Snowflake toxin damage into reagents
	if (mecha_attacker.damtype == TOX)
		var/bio_armor = (100 - run_armor_check(def_zone attack_flag = BIO)) / 100
		if(reagents.get_reagent_amount(/datum/reagent/cryptobiolin) < mecha_attacker.force * 2)
			reagents.add_reagent(/datum/reagent/cryptobiolin, mecha_attacker.force / 2 * bio_armor)
		if((reagents.get_reagent_amount(/datum/reagent/toxin) + mecha_attacker.force) < mecha_attacker.force * 2)
			reagents.add_reagent(/datum/reagent/toxin, mecha_attacker.force / 2.5 * bio_armor)
/*
	if(mecha_attacker.damtype == BRUTE)
		step_away(src, mecha_attacker, 15)
	switch(mecha_attacker.damtype)
		if(BRUTE)
			if(mecha_attacker.force > 35) // durand and other heavy mechas
				mecha_attacker.melee_attack_effect(src, heavy = TRUE)
			else if(mecha_attacker.force > 20 && !IsKnockdown()) // lightweight mechas like gygax
				mecha_attacker.melee_attack_effect(src, heavy = FALSE)
			playsound(src, mecha_attacker.brute_attack_sound, 50, TRUE)
		if(FIRE)
			playsound(src, mecha_attacker.burn_attack_sound, 50, TRUE)
		if(TOX)
			playsound(src, mecha_attacker.tox_attack_sound, 50, TRUE)
			var/bio_armor = (100 - run_armor_check(attack_flag = BIO, silent = TRUE)) / 100
			if((reagents.get_reagent_amount(/datum/reagent/cryptobiolin) + mecha_attacker.force) < mecha_attacker.force * 2)
				reagents.add_reagent(/datum/reagent/cryptobiolin, mecha_attacker.force / 2 * bio_armor)
			if((reagents.get_reagent_amount(/datum/reagent/toxin) + mecha_attacker.force) < mecha_attacker.force * 2)
				reagents.add_reagent(/datum/reagent/toxin, mecha_attacker.force / 2.5 * bio_armor)
		else
			return

	var/damage = rand(mecha_attacker.force * 0.5, mecha_attacker.force)
	if (mecha_attacker.damtype == BRUTE || mecha_attacker.damtype == FIRE)
		var/def_zone = get_random_valid_zone(user.zone_selected, even_weights = TRUE)
		var/zone_readable = parse_zone_with_bodypart(def_zone)
		apply_damage(damage, mecha_attacker.damtype, def_zone, run_armor_check(
			def_zone = def_zone,
			attack_flag = MELEE,
			absorb_text = span_notice("Your armor has protected your [zone_readable]!"),
			soften_text = span_warning("Your armor has softened a hit to your [zone_readable]!")
		))

	visible_message(span_danger("[mecha_attacker.name] [mecha_attacker.attack_verbs[1]] [src]!"), \
		span_userdanger("[mecha_attacker.name] [mecha_attacker.attack_verbs[2]] you!"), span_hear("You hear a sickening sound of flesh [mecha_attacker.attack_verbs[3]] flesh!"), COMBAT_MESSAGE_RANGE, list(mecha_attacker))
	to_chat(mecha_attacker, span_danger("You [mecha_attacker.attack_verbs[1]] [src]!"))
	..()
	return damage
*/
