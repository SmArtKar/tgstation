#define MOOK_ATTACK_NEUTRAL 0
#define MOOK_ATTACK_WARMUP 1
#define MOOK_ATTACK_ACTIVE 2
#define MOOK_ATTACK_RECOVERY 3
#define ATTACK_INTERMISSION_TIME 5

//Fragile but highly aggressive wanderers that pose a large threat in numbers. //No longer fragile :)
//They'll attempt to leap at their target from afar using their hatchets.
/mob/living/simple_animal/hostile/jungle/mook
	name = "wanderer"
	desc = "This unhealthy looking primitive is wielding a rudimentary hatchet, swinging it with wild abandon. One isn't much of a threat, but in numbers they can quickly overwhelm a superior opponent."
	icon = 'icons/mob/jungle/mook.dmi'
	icon_state = "mook"
	icon_living = "mook"
	icon_dead = "mook_dead"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	maxHealth = 270
	health = 270
	butcher_results = list(/obj/item/food/meat/slab/synthmeat = 2, /obj/item/stack/sheet/mechanical_alloy = 1)
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -8
	base_pixel_y = -8
	melee_damage_lower = 30
	melee_damage_upper = 30
	ranged = TRUE
	ranged_cooldown_time = 10
	pass_flags_self = LETPASSTHROW
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	attack_sound = 'sound/weapons/rapierhit.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	deathsound = 'sound/voice/mook_death.ogg'
	aggro_vision_range = 15 //A little more aggressive once in combat to balance out their really low HP
	var/attack_state = MOOK_ATTACK_NEUTRAL
	var/struck_target_leap = FALSE

	footstep_type = FOOTSTEP_MOB_BAREFOOT
	crusher_drop_mod = 10
	crusher_loot = /obj/item/crusher_trophy/axe_head

/mob/living/simple_animal/hostile/jungle/mook/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /mob/living/simple_animal/hostile/jungle/mook))
		var/mob/living/simple_animal/hostile/jungle/mook/mook_moover = mover
		if(mook_moover.attack_state == MOOK_ATTACK_ACTIVE && mook_moover.throwing)
			return TRUE

/mob/living/simple_animal/hostile/jungle/mook/death()
	desc = "A deceased primitive. Upon closer inspection, it was suffering from severe cellular degeneration and its garments are machine made..."//Can you guess the twist
	return ..()

/mob/living/simple_animal/hostile/jungle/mook/AttackingTarget()
	if(isliving(target))
		if(ranged_cooldown <= world.time && attack_state == MOOK_ATTACK_NEUTRAL)
			var/mob/living/L = target
			if(L.incapacitated())
				WarmupAttack(forced_slash_combo = TRUE)
				return
			WarmupAttack()
		return
	return ..()

/mob/living/simple_animal/hostile/jungle/mook/Goto()
	if(attack_state != MOOK_ATTACK_NEUTRAL)
		return
	return ..()

/mob/living/simple_animal/hostile/jungle/mook/Move()
	if(attack_state == MOOK_ATTACK_WARMUP || attack_state == MOOK_ATTACK_RECOVERY)
		return
	return ..()

/mob/living/simple_animal/hostile/jungle/mook/proc/WarmupAttack(forced_slash_combo = FALSE)
	if(attack_state == MOOK_ATTACK_NEUTRAL && target)
		attack_state = MOOK_ATTACK_WARMUP
		walk(src,0)
		update_icons()
		if(prob(50) && get_dist(src,target) <= 3 || forced_slash_combo)
			addtimer(CALLBACK(src, .proc/SlashCombo), ATTACK_INTERMISSION_TIME)
			return
		addtimer(CALLBACK(src, .proc/LeapAttack), ATTACK_INTERMISSION_TIME + rand(0,3))
		return
	attack_state = MOOK_ATTACK_RECOVERY
	ResetNeutral()

/mob/living/simple_animal/hostile/jungle/mook/proc/SlashCombo()
	if(attack_state == MOOK_ATTACK_WARMUP && !stat)
		attack_state = MOOK_ATTACK_ACTIVE
		update_icons()
		SlashAttack()
		addtimer(CALLBACK(src, .proc/SlashAttack), 3)
		addtimer(CALLBACK(src, .proc/SlashAttack), 6)
		addtimer(CALLBACK(src, .proc/AttackRecovery), 9)

/mob/living/simple_animal/hostile/jungle/mook/proc/SlashAttack()
	if(target && !stat && attack_state == MOOK_ATTACK_ACTIVE)
		melee_damage_lower = 15
		melee_damage_upper = 15
		var/mob_direction = get_dir(src,target)
		var/atom/target_from = GET_TARGETS_FROM(src)
		if(get_dist(src,target) > 1)
			step(src,mob_direction)
		if(isturf(target_from.loc) && target.Adjacent(target_from) && isliving(target))
			var/mob/living/L = target
			L.attack_animal(src)
			return
		var/swing_turf = get_step(src,mob_direction)
		new /obj/effect/temp_visual/kinetic_blast(swing_turf)
		playsound(src, 'sound/weapons/slashmiss.ogg', 50, TRUE)

/mob/living/simple_animal/hostile/jungle/mook/proc/LeapAttack()
	if(target && !stat && attack_state == MOOK_ATTACK_WARMUP)
		attack_state = MOOK_ATTACK_ACTIVE
		set_density(FALSE)
		melee_damage_lower = 30
		melee_damage_upper = 30
		update_icons()
		new /obj/effect/temp_visual/mook_dust(get_turf(src))
		playsound(src, 'sound/weapons/thudswoosh.ogg', 25, TRUE)
		playsound(src, 'sound/voice/mook_leap_yell.ogg', 100, TRUE)
		var/target_turf = get_turf(target)
		throw_at(target_turf, 7, 1, src, FALSE, callback = CALLBACK(src, .proc/AttackRecovery))
		return
	attack_state = MOOK_ATTACK_RECOVERY
	ResetNeutral()

/mob/living/simple_animal/hostile/jungle/mook/proc/AttackRecovery()
	if(attack_state == MOOK_ATTACK_ACTIVE && !stat)
		attack_state = MOOK_ATTACK_RECOVERY
		set_density(TRUE)
		face_atom(target)
		if(!struck_target_leap)
			update_icons()
		struck_target_leap = FALSE
		if(prob(40))
			attack_state = MOOK_ATTACK_NEUTRAL
			if(target)
				if(isliving(target))
					var/mob/living/L = target
					if(L.incapacitated() && L.stat != DEAD)
						addtimer(CALLBACK(src, .proc/WarmupAttack, TRUE), ATTACK_INTERMISSION_TIME)
						return
			addtimer(CALLBACK(src, .proc/WarmupAttack), ATTACK_INTERMISSION_TIME)
			return
		addtimer(CALLBACK(src, .proc/ResetNeutral), ATTACK_INTERMISSION_TIME)

/mob/living/simple_animal/hostile/jungle/mook/proc/ResetNeutral()
	if(attack_state == MOOK_ATTACK_RECOVERY)
		attack_state = MOOK_ATTACK_NEUTRAL
		ranged_cooldown = world.time + ranged_cooldown_time
		update_icons()
		if(target && !stat)
			update_icons()
			Goto(target, move_to_delay, minimum_distance)

/mob/living/simple_animal/hostile/jungle/mook/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(isliving(hit_atom) && attack_state == MOOK_ATTACK_ACTIVE)
		var/mob/living/L = hit_atom
		if(CanAttack(L))
			L.attack_animal(src)
			struck_target_leap = TRUE
			set_density(TRUE)
			update_icons()
	var/mook_under_us = FALSE
	for(var/A in get_turf(src))
		if(struck_target_leap && mook_under_us)
			break
		if(A == src)
			continue
		if(isliving(A))
			var/mob/living/ML = A
			if(!struck_target_leap && CanAttack(ML))//Check if some joker is attempting to use rest to evade us
				struck_target_leap = TRUE
				ML.attack_animal(src)
				set_density(TRUE)
				struck_target_leap = TRUE
				update_icons()
				continue
			if(istype(ML, /mob/living/simple_animal/hostile/jungle/mook) && !mook_under_us)//If we land on the same tile as another mook, spread out so we don't stack our sprite on the same tile
				var/mob/living/simple_animal/hostile/jungle/mook/M = ML
				if(!M.stat)
					mook_under_us = TRUE
					var/anydir = pick(GLOB.cardinals)
					Move(get_step(src, anydir), anydir)
					continue

/mob/living/simple_animal/hostile/jungle/mook/handle_automated_action()
	if(attack_state)
		return
	return ..()

/mob/living/simple_animal/hostile/jungle/mook/OpenFire()
	if(isliving(target))
		var/mob/living/L = target
		if(L.incapacitated())
			return
	WarmupAttack()

/mob/living/simple_animal/hostile/jungle/mook/update_icons()
	. = ..()
	if(!stat)
		switch(attack_state)
			if(MOOK_ATTACK_NEUTRAL)
				icon_state = "mook"
			if(MOOK_ATTACK_WARMUP)
				icon_state = "mook_warmup"
			if(MOOK_ATTACK_ACTIVE)
				if(!density)
					icon_state = "mook_leap"
					return
				if(struck_target_leap)
					icon_state = "mook_strike"
					return
				icon_state = "mook_slash_combo"
			if(MOOK_ATTACK_RECOVERY)
				icon_state = "mook"

/obj/effect/temp_visual/mook_dust
	name = "dust"
	desc = "It's just a dust cloud!"
	icon = 'icons/mob/jungle/mook.dmi'
	icon_state = "mook_leap_cloud"
	layer = BELOW_MOB_LAYER
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -16
	base_pixel_y = -16
	duration = 10

/obj/item/crusher_trophy/axe_head //Allows you to hit super fast if you manage to constantly detonate marks, but heavily impacts damage.
	name = "axe head"
	desc = "A shiny metal axe head. Suitable as a trophy for a kinetic crusher."
	icon_state = "axe_head"
	denied_type = /obj/item/crusher_trophy/axe_head

/obj/item/crusher_trophy/axe_head/effect_desc()
	return "mark detonation to lower attack cooldown. Heavily impacts damage while also reducing recharge time."

/obj/item/crusher_trophy/axe_head/on_mark_detonation(mob/living/target, mob/living/user)
	user.changeNext_move(CLICK_CD_RANGE)

/obj/item/crusher_trophy/axe_head/add_to(obj/item/kinetic_crusher/crusher, mob/living/user)
	. = ..()
	if(.)
		crusher.AddComponent(/datum/component/two_handed, force_wielded=10) //Breaks when used with wendigo's horn, but this shouldn't happen normally.
		crusher.charge_time -= 5
		crusher.detonation_damage -= 25
		crusher.backstab_bonus -= 15

/obj/item/crusher_trophy/axe_head/remove_from(obj/item/kinetic_crusher/crusher, mob/living/user)
	. = ..()
	if(.)
		crusher.AddComponent(/datum/component/two_handed, force_wielded=20)
		crusher.charge_time += 5
		crusher.detonation_damage += 25
		crusher.backstab_bonus += 15

/obj/item/stack/sheet/mechanical_alloy
	name = "mechanical alloy"
	icon = 'icons/obj/mining.dmi'
	desc = "Odd, non-newtonian dark-yellow metal that has been harvested from wanderer corpses."
	singular_name = "mechanical alloy"
	icon_state = "sheet-mechanicalloy"
	max_amount = 12
	novariants = FALSE
	item_flags = NOBLUDGEON
	w_class = WEIGHT_CLASS_NORMAL
	merge_type = /obj/item/stack/sheet/mechanical_alloy

#define RESONANCE_COOLDOWN 3 SECONDS
#define RESONANCE_RANGE 5

/obj/item/clothing/suit/hooded/alloy_armor
	name = "mechanical alloy armor"
	desc = "A suit made out of mechanicall alloy plates sewed together with bat sinew."
	icon_state = "mechanical_alloy"
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/mining_scanner, /obj/item/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator, /obj/item/pickaxe, /obj/item/spear)
	armor = list(MELEE = 50, BULLET = 20, LASER = 10, ENERGY = 10, BOMB = 50, BIO = 60, RAD = 50, FIRE = 100, ACID = 100)
	hoodtype = /obj/item/clothing/head/hooded/alloy_armor
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	resistance_flags = FIRE_PROOF | ACID_PROOF
	transparent_protection = HIDEGLOVES|HIDESUITSTORAGE|HIDEJUMPSUIT|HIDESHOES

/obj/item/clothing/head/hooded/alloy_armor
	name = "mechanical alloy helmet"
	desc = "A helmet made out of mechanical alloy and bat sinew."
	icon_state = "mechanical_alloy"
	armor = list(MELEE = 50, BULLET = 20, LASER = 10, ENERGY = 10, BOMB = 50, BIO = 60, RAD = 50, FIRE = 100, ACID = 100)
	clothing_flags = SNUG_FIT
	resistance_flags = FIRE_PROOF | ACID_PROOF
	actions_types = list(/datum/action/item_action/alloy_resonance)
	var/resonance_cooldown = 0

/obj/item/clothing/head/hooded/alloy_armor/proc/resonate(mob/user)
	if(resonance_cooldown > world.time)
		to_chat(span_warning("[src] is not ready to resonate yet! Wait [round((resonance_cooldown - world.time) / 10)] more seconds before activating resonance once again!"))
		return

	if(!lavaland_equipment_pressure_check(get_turf(user)))
		to_chat(span_warning("Pressure here is too high for [src] to resonate with enough power!"))
		return

	resonance_cooldown = world.time + RESONANCE_COOLDOWN
	user.visible_message(span_warning("[user]'s [src] starts resonating and emitting a high-pitched sound!"))
	playsound(get_turf(user), 'sound/effects/clockcult_gateway_disrupted.ogg', 100, TRUE)
	for(var/obj/projectile/proj in range(RESONANCE_RANGE, get_turf(user)))
		proj.set_angle(Get_Angle(user, proj))

#undef RESONANCE_RANGE
#undef RESONANCE_COOLDOWN
#undef MOOK_ATTACK_NEUTRAL
#undef MOOK_ATTACK_WARMUP
#undef MOOK_ATTACK_ACTIVE
#undef MOOK_ATTACK_RECOVERY
#undef ATTACK_INTERMISSION_TIME
