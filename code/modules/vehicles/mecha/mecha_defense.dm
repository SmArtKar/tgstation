/// Returns a damage multiplier for damage coming from a particular direction
/obj/vehicle/sealed/mecha/proc/get_dir_damage_multiplier(damage_dir)
	// Front or 45* off takes (usually) reduced damage
	if (damage_dir & dir)
		return facing_modifiers[MECHA_FRONT_ARMOUR]
	// Direct backstabs
	if (damage_dir == REVERSE_DIR(dir))
		return facing_modifiers[MECHA_BACK_ARMOUR]
	// Everything else
	return facing_modifiers[MECHA_SIDE_ARMOUR]

/obj/vehicle/sealed/mecha/rust_heretic_act()
	take_damage(500, BRUTE, MELEE, armour_penetration = 100)

/obj/vehicle/sealed/mecha/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	. = ..()
	if(. <= 0 || atom_integrity < 0)
		return

	update_diag_health()
	if (prob(damage_amount * 5))
		spark_system?.start()
	if(damage_taken >= 5)
		to_chat(occupants, "[icon2html(src, occupants)][span_userdanger("Taking damage!")]")
	log_message("Took [damage_taken] points of damage. Damage type: [damage_type]", LOG_MECHA)

/obj/vehicle/sealed/mecha/run_atom_armor(damage_amount, damage_type, damage_flag = 0, attack_dir, armour_penetration)
	return ..() * get_dir_damage_multiplier(attack_dir)

/obj/vehicle/sealed/mecha/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	user.changeNext_move(CLICK_CD_MELEE) // Ugh. Ideally we shouldn't be setting cooldowns outside of click code.
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	playsound(loc, 'sound/items/weapons/tap.ogg', 40, TRUE, -1)
	var/attack_verb = "hit"
	var/obj/item/bodypart/arm = user.get_active_hand()
	if (arm && LAZYLEN(arm.unarmed_attack_verbs))
		attack_verb = pick(arm.unarmed_attack_verbs)
	user.visible_message(span_danger("[user] [attack_verb]s [src]. Nothing happens."), span_warning("You [attack_verb] [src]. Nothing happens."), vision_distance = COMBAT_MESSAGE_RANGE)
	log_message("Attack by hand/paw (no damage). Attacker - [user].", LOG_MECHA, color="red")

/obj/vehicle/sealed/mecha/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/vehicle/sealed/mecha/attack_alien(mob/living/user, list/modifiers)
	log_message("Attack by alien. Attacker - [user].", LOG_MECHA, color = "red")
	playsound(loc, 'sound/items/weapons/slash.ogg', 100, TRUE)
	attack_generic(user, rand(user.melee_damage_lower, user.melee_damage_upper), BRUTE, MELEE, 0)

/obj/vehicle/sealed/mecha/hulk_damage()
	return 15

/obj/vehicle/sealed/mecha/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(.)
		log_message("Attack by hulk. Attacker - [user].", LOG_MECHA, color = "red")
		log_combat(user, src, "punched", "hulk powers")

/obj/vehicle/sealed/mecha/hitby(atom/movable/thrown_thing, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	log_message("Hit by [thrown_thing].", LOG_MECHA, color = "red")
	return ..()

/obj/vehicle/sealed/mecha/attack_tk()
	return

/obj/vehicle/sealed/mecha/blob_act(obj/structure/blob/blob)
	log_message("Attack by blob. Attacker - [blob].", LOG_MECHA, color = "red")
	take_damage(30, BRUTE, MELEE, FALSE, armour_penetration = 50)

/obj/vehicle/sealed/mecha/ex_act(severity, target)
	log_message("Affected by explosion of severity: [severity].", LOG_MECHA, color="red")
	return ..()

/obj/vehicle/sealed/mecha/contents_explosion(severity, target)
	if (mecha_flags & IS_ENCLOSED)
		severity--

	switch(severity)
		if(EXPLODE_DEVASTATE)
			if(flat_equipment)
				SSexplosions.high_mov_atom += flat_equipment
			if(occupants)
				SSexplosions.high_mov_atom += occupants
		if(EXPLODE_HEAVY)
			if(flat_equipment)
				SSexplosions.med_mov_atom += flat_equipment
			if(occupants)
				SSexplosions.med_mov_atom += occupants
		if(EXPLODE_LIGHT)
			if(flat_equipment)
				SSexplosions.low_mov_atom += flat_equipment
			if(occupants)
				SSexplosions.low_mov_atom += occupants

/obj/vehicle/sealed/mecha/attack_animal(mob/living/simple_animal/user, list/modifiers)
	log_message("Attack by simple animal. Attacker - [user].", LOG_MECHA, color="red")
	if(!user.melee_damage_upper && !user.obj_damage)
		user.emote("custom", message = "[user.friendly_verb_continuous] [src].")
		return FALSE

	var/play_soundeffect = 1
	if(user.environment_smash)
		play_soundeffect = 0
		playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
	var/animal_damage = rand(user.melee_damage_lower, user.melee_damage_upper)
	if(user.obj_damage)
		animal_damage = user.obj_damage
	animal_damage = min(animal_damage, 20 * user.environment_smash)
	log_combat(user, src, "attacked")
	attack_generic(user, animal_damage, user.melee_damage_type, MELEE, play_soundeffect)

/obj/vehicle/sealed/mecha/bullet_act(obj/projectile/hitting_projectile, def_zone, piercing_hit, blocked = 0) //wrapper
	// Allows bullets to hit the pilot of open-canopy mechs
	if(!(mecha_flags & IS_ENCLOSED)\
		&& LAZYLEN(occupants)\
		&& prob(MECHA_OPEN_CABIN_DRIVER_HIT_CHANCE)\
		&& !(mecha_flags & SILICON_PILOT)\
		&& (def_zone == BODY_ZONE_HEAD || def_zone == BODY_ZONE_CHEST)\
	)
		var/mob/living/hitmob = pick(occupants)
		return hitmob.projectile_hit(hitting_projectile, def_zone, piercing_hit) // If the cabin is open, the occupant can be hit

	. = ..()
	log_message("Hit by projectile. Type: [hitting_projectile]([hitting_projectile.damage_type]).", LOG_MECHA, color="red")
	// Or if its a piercing hit and we failed to block the projectile
	if (. != BULLET_ACT_BLOCK && blocked < 100 && piercing_hit && PROB(MECHA_DRIVER_PIERCE_HIT_CHANCE))
		var/mob/living/hitmob = pick(occupants)
		var/hit_result = hitmob.projectile_hit(hitting_projectile, def_zone, piercing_hit)
		// Don't transfer FORCE_PIERCE over if it didn't FORCE_PIERCE us
		if (hit_result != BULLET_ACT_FORCE_PIERCE)
			return hit_result

/obj/vehicle/sealed/mecha/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return

	log_message("Hit by an EMP", LOG_MECHA, color="red")
	if(get_charge())
		use_energy(MECHA_EMP_CHARGE_DRAIN * cell.charge / severity)
		take_damage(30 / severity, BURN, ENERGY)

	if (!equipment_disabled)
		for (var/mob/occupant as anything in occupants)
			balloon_alert(occupant, "equipment disabled!")
			SEND_SOUND(occupant, sound('sound/items/weapons/jammed.ogg', volume = 75)) // Audio feedback cuz this's important

	equipment_disabled = TRUE
	set_mouse_pointer()
	equipment_reactivation_timer = addtimer(CALLBACK(src, PROC_REF(restore_equipment)), MECHA_EMP_EQUIPMENT_REBOOT_TIME, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)

/obj/vehicle/sealed/mecha/narsie_act()
	emp_act(EMP_HEAVY)

/obj/vehicle/sealed/mecha/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if (user.combat_mode)
		return NONE

	if (istype(tool, /obj/item/mmi))
		install_mmi(user, tool)
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/mecha_ammo))
		ammo_resupply(user, tool)
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/rcd_upgrade))
		upgrade_rcd(user, tool)
		return ITEM_INTERACT_SUCCESS

	if(tool.GetID())
		if(!allowed(user))
			if(mecha_flags & ID_LOCK_ON)
				balloon_alert(user, "access denied!")
			else
				balloon_alert(user, "unable to set id lock!")
			return ITEM_INTERACT_BLOCKING

		mecha_flags ^= ID_LOCK_ON
		balloon_alert(user, "[mecha_flags & ID_LOCK_ON ? "enabled" : "disabled"] id lock!")
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/mecha_parts))
		var/obj/item/mecha_parts = tool
		part.try_attach_part(user, src, modifiers[RIGHT_CLICK])
		return ITEM_INTERACT_SUCCESS

	if(is_wire_tool(tool) && (mecha_flags & PANEL_OPEN))
		wires.interact(user)
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/stock_parts) && try_insert_part(tool, user))
		return ITEM_INTERACT_SUCCESS

/obj/vehicle/sealed/mecha/attacked_by(obj/item/attacking_item, mob/living/user)
	if(!attacking_item.force)
		return

	var/total_force = (attacking_item.force * attacking_item.demolition_mod)
	var/damage = take_damage(total_force, attacking_item.damtype, MELEE, TRUE, get_dir(src, user), attacking_item.armour_penetration)

	// Sanity in case one is null for some reason
	var/picked_index = rand(max(length(attacking_item.attack_verb_simple), length(attacking_item.attack_verb_continuous)))

	var/message_verb_continuous = "attacks"
	var/message_verb_simple = "attack"
	// Sanity in case one is... longer than the other?
	if (picked_index && length(attacking_item.attack_verb_continuous) >= picked_index)
		message_verb_continuous = attacking_item.attack_verb_continuous[picked_index]
	if (picked_index && length(attacking_item.attack_verb_simple) >= picked_index)
		message_verb_simple = attacking_item.attack_verb_simple[picked_index]

	if(attacking_item.demolition_mod > 1 && prob(damage * 5))
		message_verb_simple = "pulverise"
		message_verb_continuous = "pulverises"

	if(attacking_item.demolition_mod < 1)
		message_verb_simple = "ineffectively " + message_verb_simple
		message_verb_continuous = "ineffectively " + message_verb_continuous

	user.visible_message(span_danger("[user] [message_verb_continuous] [src] with [attacking_item][damage ? "." : ", [no_damage_feedback]!"]"), \
		span_danger("You [message_verb_simple] [src] with [attacking_item][damage ? "." : ", [no_damage_feedback]!"]"), null, COMBAT_MESSAGE_RANGE)
	log_combat(user, src, "attacked", attacking_item)
	log_message("Attacked by [user]. Item - [attacking_item], Damage - [damage]", LOG_MECHA)

/obj/vehicle/sealed/mecha/screwdriver_act(mob/living/user, obj/item/tool)
	..()
	. = TRUE
	if(LAZYLEN(occupants))
		balloon_alert(user, "panel blocked")
		return

	mecha_flags ^= PANEL_OPEN
	balloon_alert(user, (mecha_flags & PANEL_OPEN) ? "panel open" : "panel closed")
	tool.play_tool_sound(src)

/obj/vehicle/sealed/mecha/crowbar_act(mob/living/user, obj/item/tool)
	..()
	. = TRUE
	if(istype(tool, /obj/item/crowbar/mechremoval))
		var/obj/item/crowbar/mechremoval/remover = tool
		remover.empty_mech(src, user)
		return

	if(!(mecha_flags & PANEL_OPEN))
		balloon_alert(user, "open the panel first!")
		return

	if(dna_lock)
		var/datum/dna/user_dna = user.has_dna()
		if(user_dna?.unique_enzymes != dna_lock)
			balloon_alert(user, "access denied!")
			return

	if((mecha_flags & ID_LOCK_ON) && !allowed(user))
		balloon_alert(user, "access denied!")
		return

	var/list/stock_parts = list()
	if(cell)
		stock_parts[cell.name] = cell.appearance
	if(scanner)
		stock_parts[scanner.name] = scanner.appearance
	if(capacitor)
		stock_parts[capacitor.name] = capacitor.appearance
	if(servo)
		stock_parts[servo.name] = servo.appearance

	if(!length(stock_parts))
		balloon_alert(user, "no parts!")

	var/obj/item/stock_parts/part_to_remove = show_radial_menu(user, src, stock_parts, require_near = TRUE)
	if(!(locate(part_to_remove) in contents))
		return

	user.put_in_hands(part_to_remove)
	CheckParts()
	update_diag_cell()
	tool.play_tool_sound(src)

/obj/vehicle/sealed/mecha/welder_act(mob/living/user, obj/item/tool)
	..()
	. = TRUE

	if(DOING_INTERACTION(user, src))
		balloon_alert(user, "already repairing!")
		return

	if(atom_integrity >= max_integrity)
		balloon_alert(user, "not damaged!")
		return

	if(!tool.tool_start_check(user, amount = 1, heat_required = HIGH_TEMPERATURE_REQUIRED))
		return

	user.balloon_alert_to_viewers("started repairing")
	audible_message(deaf_message = span_hear("You hear welding."))
	var/did_repairs = FALSE
	while(atom_integrity < max_integrity)
		if(!tool.use_tool(src, user, 2.5 SECONDS, volume = 50))
			break

		did_repairs = TRUE
		atom_integrity = min(max_integrity, atom_integrity + 10)

	if(!did_repairs)
		balloon_alert(user, "repairs interrupted!")
		return

	balloon_alert(user, "[(atom_integrity >= max_integrity) ? "fully" : "partially"] repaired!")
	update_diag_health()

/// Try to insert a stock part into the mech
/obj/vehicle/sealed/mecha/proc/try_insert_part(obj/item/stock_parts/weapon, mob/living/user)
	if (!(mecha_flags & PANEL_OPEN))
		balloon_alert(user, "open the panel first!")
		return TRUE

	if (istype(weapon, /obj/item/stock_parts/power_store/battery))
		if (cell)
			balloon_alert(user, "already installed!")
			return TRUE
		if (!user.transferItemToLoc(weapon, src, silent = FALSE))
			return TRUE
		cell = weapon
		balloon_alert(user, "installed power cell")
		update_diag_cell()
		playsound(src, 'sound/items/tools/screwdriver2.ogg', 50, FALSE)
		log_message("Power cell installed", LOG_MECHA)
		return TRUE

	if (istype(weapon, /obj/item/stock_parts/scanning_module))
		if (scanner)
			balloon_alert(user, "already installed!")
			return TRUE
		if (!user.transferItemToLoc(weapon, src, silent = FALSE))
			return TRUE
		scanner = weapon
		balloon_alert(user, "installed scanning module")
		playsound(src, 'sound/items/tools/screwdriver2.ogg', 50, FALSE)
		log_message("[weapon] installed", LOG_MECHA)
		return TRUE

	if (istype(weapon, /obj/item/stock_parts/capacitor))
		if (capacitor)
			balloon_alert(user, "already installed!")
			return TRUE
		if (!user.transferItemToLoc(weapon, src, silent = FALSE))
			return TRUE
		capacitor = weapon
		balloon_alert(user, "installed capacitor")
		playsound(src, 'sound/items/tools/ratchet.ogg', 50, FALSE)
		log_message("[weapon] installed", LOG_MECHA)
		return TRUE

	if (istype(weapon, /obj/item/stock_parts/servo))
		if (!servo)
			balloon_alert(user, "already installed!")
			return TRUE
		if (!user.transferItemToLoc(weapon, src, silent = FALSE))
			return TRUE
		servo = weapon
		balloon_alert(user, "installed servo")
		playsound(src, 'sound/items/tools/ratchet.ogg', 50, FALSE)
		log_message("[weapon] installed", LOG_MECHA)
		return TRUE
	return FALSE

/// Special light eater handling
/obj/vehicle/sealed/mecha/proc/on_light_eater(obj/vehicle/sealed/source, datum/light_eater)
	SIGNAL_HANDLER
	if (mecha_flags & HAS_LIGHTS)
		visible_message(span_danger("[src]'s lights burn out!"))
		mecha_flags &= ~HAS_LIGHTS
	set_light_on(FALSE)
	for (var/occupant in occupants)
		remove_action_type_from_mob(/datum/action/vehicle/sealed/mecha/mech_toggle_lights, occupant)
	return COMPONENT_BLOCK_LIGHT_EATER

/obj/vehicle/sealed/mecha/on_saboteur(datum/source, disrupt_duration)
	. = ..()
	if ((mecha_flags & HAS_LIGHTS) && light_on)
		set_light_on(FALSE)
		return TRUE

/////////////////////////////////////
////////  Atmospheric stuff  ////////
/////////////////////////////////////

/obj/vehicle/sealed/mecha/remove_air(amount)
	if ((mecha_flags & IS_ENCLOSED) && cabin_sealed)
		return cabin_air.remove(amount)
	return ..()

/obj/vehicle/sealed/mecha/return_air()
	if ((mecha_flags & IS_ENCLOSED) && cabin_sealed)
		return cabin_air
	return ..()

/obj/vehicle/sealed/mecha/return_analyzable_air()
	return cabin_air

/obj/vehicle/sealed/mecha/proc/return_pressure()
	var/datum/gas_mixture/air = return_air()
	return air?.return_pressure()

/obj/vehicle/sealed/mecha/return_temperature()
	var/datum/gas_mixture/air = return_air()
	return air?.return_temperature()

/obj/vehicle/sealed/mecha/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return exposed_temperature > max_temperature

/obj/vehicle/sealed/mecha/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	log_message("Exposed to dangerous temperature.", LOG_MECHA, color="red")
	take_damage(5, BURN, 0, 1)

/obj/vehicle/sealed/mecha/fire_act() //Check if we should ignite the pilot of an open-canopy mech
	. = ..()
	if (mecha_flags & IS_ENCLOSED || mecha_flags & SILICON_PILOT)
		return
	for (var/mob/living/cookedalive as anything in occupants)
		if (cookedalive.fire_stacks < 5)
			cookedalive.adjust_fire_stacks(1)
			cookedalive.ignite_mob()

/// Upgrades any attached RCD equipment, unless the disk has anti-distruption upgrade. That doesn't fly with us.
/obj/vehicle/sealed/mecha/proc/upgrade_rcd(obj/item/rcd_upgrade/rcd_upgrade, mob/user)
	if (rcd_upgrade.upgrade & RCD_UPGRADE_ANTI_INTERRUPT)
		balloon_alert(user, "invalid upgrade!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, FALSE)
		return

	for (var/obj/item/mecha_equipment/rcd/rcd_equip in flat_equipment)
		if (rcd_equip.internal_rcd.install_upgrade(rcd_upgrade, user))
			return

/*


/obj/vehicle/sealed/mecha/proc/full_repair(charge_cell)
	atom_integrity = max_integrity
	if(cell && charge_cell)
		cell.charge = cell.maxcharge
		diag_hud_set_mechcell()
	if(internal_damage & MECHA_INT_FIRE)
		clear_internal_damage(MECHA_INT_FIRE)
	if(internal_damage & MECHA_INT_TEMP_CONTROL)
		clear_internal_damage(MECHA_INT_TEMP_CONTROL)
	if(internal_damage & MECHA_INT_SHORT_CIRCUIT)
		clear_internal_damage(MECHA_INT_SHORT_CIRCUIT)
	if(internal_damage & MECHA_CABIN_AIR_BREACH)
		clear_internal_damage(MECHA_CABIN_AIR_BREACH)
	if(internal_damage & MECHA_INT_CONTROL_LOST)
		clear_internal_damage(MECHA_INT_CONTROL_LOST)
	diag_hud_set_mechhealth()

/obj/vehicle/sealed/mecha/proc/ammo_resupply(obj/item/mecha_ammo/A, mob/user,fail_chat_override = FALSE)
	if(!A.rounds)
		if(!fail_chat_override)
			balloon_alert(user, "the box is empty!")
		return FALSE
	var/ammo_needed
	var/found_gun
	for(var/obj/item/mecha_equipment/weapon/ballistic/gun in flat_equipment)
		ammo_needed = 0

		if(gun.ammo_type != A.ammo_type)
			continue
		found_gun = TRUE
		if(A.direct_load)
			ammo_needed = initial(gun.projectiles) - gun.projectiles
		else
			ammo_needed = gun.projectiles_cache_max - gun.projectiles_cache

		if(!ammo_needed)
			continue
		if(ammo_needed < A.rounds)
			if(A.direct_load)
				gun.projectiles = gun.projectiles + ammo_needed
			else
				gun.projectiles_cache = gun.projectiles_cache + ammo_needed
			playsound(get_turf(user),A.load_audio,50,TRUE)
			to_chat(user, span_notice("You add [ammo_needed] [A.ammo_type][ammo_needed > 1?"s":""] to the [gun.name]"))
			A.rounds = A.rounds - ammo_needed
			if(A.custom_materials)	//Change material content of the ammo box according to the amount of ammo deposited into the weapon
				/// list of materials contained in the ammo box after we put it through the equation so we can stick this list into set_custom_materials()
				var/list/new_material_content = list()
				for(var/datum/material/current_material in A.custom_materials)
					if(istype(current_material, /datum/material/iron))	//we can flatten an empty ammo box into a sheet of iron (2000 units) so we have to make sure the box always has this amount at minimum
						new_material_content[current_material] = (A.custom_materials[current_material] - SHEET_MATERIAL_AMOUNT) * (A.rounds / initial(A.rounds)) + SHEET_MATERIAL_AMOUNT
					else
						new_material_content[current_material] = A.custom_materials[current_material] * (A.rounds / initial(A.rounds))
				A.set_custom_materials(new_material_content)
			A.update_name()
			return TRUE

		if(A.direct_load)
			gun.projectiles = gun.projectiles + A.rounds
		else
			gun.projectiles_cache = gun.projectiles_cache + A.rounds
		playsound(get_turf(user),A.load_audio,50,TRUE)
		to_chat(user, span_notice("You add [A.rounds] [A.ammo_type][A.rounds > 1?"s":""] to the [gun.name]"))
		if(A.qdel_on_empty)
			qdel(A)
			return TRUE
		A.rounds = 0
		A.set_custom_materials(list(/datum/material/iron=SHEET_MATERIAL_AMOUNT))
		A.update_appearance()
		return TRUE
	if(!fail_chat_override)
		if(found_gun)
			balloon_alert(user, "ammo storage is full!")
		else
			balloon_alert(user, "can't use this ammo!")
	return FALSE

///tries to deal internal damaget depending on the damage amount
/obj/vehicle/sealed/mecha/proc/try_deal_internal_damage(damage)
	if(damage < internal_damage_threshold)
		return
	if(!prob(internal_damage_probability))
		return
	var/internal_damage_to_deal = possible_int_damage
	internal_damage_to_deal &= ~internal_damage
	if(internal_damage_to_deal)
		set_internal_damage(pick(bitfield_to_list(internal_damage_to_deal)))

/// tries to repair any internal damage and plays fluff for it
/obj/vehicle/sealed/mecha/proc/try_repair_int_damage(mob/user, flag_to_heal)
	balloon_alert(user, get_int_repair_fluff_start(flag_to_heal))
	log_message("[key_name(user)] starting internal damage repair for flag [flag_to_heal]", LOG_MECHA)
	if(!do_after(user, 10 SECONDS, src))
		balloon_alert(user, get_int_repair_fluff_fail(flag_to_heal))
		log_message("Internal damage repair for flag [flag_to_heal] failed.", LOG_MECHA, color="red")
		return
	clear_internal_damage(flag_to_heal)
	balloon_alert(user, get_int_repair_fluff_end(flag_to_heal))
	log_message("Finished internal damage repair for flag [flag_to_heal]", LOG_MECHA)

///gets the starting balloon alert flufftext
/obj/vehicle/sealed/mecha/proc/get_int_repair_fluff_start(flag)
	switch(flag)
		if(MECHA_INT_FIRE)
			return "activating internal fire supression..."
		if(MECHA_INT_TEMP_CONTROL)
			return "resetting temperature module..."
		if(MECHA_CABIN_AIR_BREACH)
			return "activating cabin breach sealant..."
		if(MECHA_INT_CONTROL_LOST)
			return "recalibrating coordination system..."
		if(MECHA_INT_SHORT_CIRCUIT)
			return "flushing internal capacitor..."

///gets the successful finish balloon alert flufftext
/obj/vehicle/sealed/mecha/proc/get_int_repair_fluff_end(flag)
	switch(flag)
		if(MECHA_INT_FIRE)
			return "internal fire supressed"
		if(MECHA_INT_TEMP_CONTROL)
			return "temperature chip reactivated"
		if(MECHA_CABIN_AIR_BREACH)
			return "cabin breach sealed"
		if(MECHA_INT_CONTROL_LOST)
			return "coordination re-established"
		if(MECHA_INT_SHORT_CIRCUIT)
			return "internal capacitor reset"

///gets the on-fail balloon alert flufftext
/obj/vehicle/sealed/mecha/proc/get_int_repair_fluff_fail(flag)
	switch(flag)
		if(MECHA_INT_FIRE)
			return "fire supression canceled"
		if(MECHA_INT_TEMP_CONTROL)
			return "reset aborted"
		if(MECHA_CABIN_AIR_BREACH)
			return "sealant deactivated"
		if(MECHA_INT_CONTROL_LOST)
			return "recalibration failed"
		if(MECHA_INT_SHORT_CIRCUIT)
			return "capacitor flush failure"

/obj/vehicle/sealed/mecha/proc/set_internal_damage(int_dam_flag)
	internal_damage |= int_dam_flag
	log_message("Internal damage of type [int_dam_flag].", LOG_MECHA)
	SEND_SOUND(occupants, sound('sound/machines/warning-buzzer.ogg',wait=0))
	diag_hud_set_mechstat()

/obj/vehicle/sealed/mecha/proc/clear_internal_damage(int_dam_flag)
	if(internal_damage & int_dam_flag)
		switch(int_dam_flag)
			if(MECHA_INT_TEMP_CONTROL)
				to_chat(occupants, "[icon2html(src, occupants)][span_boldnotice("Life support system reactivated.")]")
			if(MECHA_INT_FIRE)
				to_chat(occupants, "[icon2html(src, occupants)][span_boldnotice("Internal fire extinguished.")]")
			if(MECHA_CABIN_AIR_BREACH)
				to_chat(occupants, "[icon2html(src, occupants)][span_boldnotice("Cabin breach has been sealed.")]")
			if(MECHA_INT_CONTROL_LOST)
				to_chat(occupants, "[icon2html(src, occupants)][span_boldnotice("Control module reactivated.")]")
			if(MECHA_INT_SHORT_CIRCUIT)
				to_chat(occupants, "[icon2html(src, occupants)][span_boldnotice("Internal capacitor has been reset successfully.")]")
	internal_damage &= ~int_dam_flag
	diag_hud_set_mechstat()


/// tries to damage mech equipment depending on damage and where is being targeted
/obj/vehicle/sealed/mecha/proc/try_damage_component(damage, def_zone)
	if(damage < component_damage_threshold)
		return
	var/obj/item/mecha_equipment/gear
	switch(def_zone)
		if(BODY_ZONE_L_ARM)
			gear = equip_by_category[MECHA_L_ARM]
		if(BODY_ZONE_R_ARM)
			gear = equip_by_category[MECHA_R_ARM]
	if(!gear)
		return
	var/component_health = gear.get_integrity()
	// always leave at least 1 health
	var/damage_to_deal = min(component_health - 1, damage)
	if(damage_to_deal <= 0)
		return

	gear.take_damage(damage_to_deal)
	if(gear.get_integrity() <= 1)
		to_chat(occupants, "[icon2html(src, occupants)][span_danger("[gear] is critically damaged!")]")
		playsound(src, gear.destroy_sound, 50)
*/
