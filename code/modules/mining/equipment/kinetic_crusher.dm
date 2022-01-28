#define CRUSHER_TROPHY_LIMIT 6

/*********************Mining Hammer****************/
/obj/item/kinetic_crusher
	icon = 'icons/obj/mining.dmi'
	icon_state = "crusher"
	inhand_icon_state = "crusher0"
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	name = "proto-kinetic crusher"
	desc = "An early design of the proto-kinetic accelerator, it is little more than a combination of various mining tools cobbled together, forming a high-tech club. \
	While it is an effective mining tool, it did little to aid any but the most skilled and/or suicidal miners against local fauna."
	force = 0 //You can't hit stuff unless wielded
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	throwforce = 5
	throw_speed = 4
	armour_penetration = 10
	custom_materials = list(/datum/material/iron=1150, /datum/material/glass=2075)
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("smashes", "crushes", "cleaves", "chops", "pulps")
	attack_verb_simple = list("smash", "crush", "cleave", "chop", "pulp")
	sharpness = SHARP_EDGED
	actions_types = list(/datum/action/item_action/toggle_light)
	obj_flags = UNIQUE_RENAME
	light_system = MOVABLE_LIGHT
	light_range = 5
	light_on = FALSE
	var/list/trophies = list()
	var/charged = TRUE
	var/charge_time = 15
	var/detonation_damage = 50
	var/backstab_bonus = 30
	var/strong_miner_bonus = 20
	var/wielded = FALSE // track wielded status on item
	var/trophy_capacity = CRUSHER_TROPHY_LIMIT

/obj/item/kinetic_crusher/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, .proc/on_wield)
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, .proc/on_unwield)

/obj/item/kinetic_crusher/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 60, 110) //technically it's huge and bulky, but this provides an incentive to use it
	AddComponent(/datum/component/two_handed, force_unwielded=0, force_wielded=20)

/obj/item/kinetic_crusher/Destroy()
	QDEL_LIST(trophies)
	return ..()

/// triggered on wield of two handed item
/obj/item/kinetic_crusher/proc/on_wield(obj/item/source, mob/user)
	SIGNAL_HANDLER
	wielded = TRUE

/// triggered on unwield of two handed item
/obj/item/kinetic_crusher/proc/on_unwield(obj/item/source, mob/user)
	SIGNAL_HANDLER
	wielded = FALSE

/obj/item/kinetic_crusher/examine(mob/living/user)
	. = ..()
	. += span_notice("Mark a large creature with the destabilizing force, then hit them in melee to do <b>[force + detonation_damage]</b> damage.")
	. += span_notice("Does <b>[force + detonation_damage + backstab_bonus]</b> damage if the target is backstabbed, instead of <b>[force + detonation_damage]</b>.")
	for(var/t in trophies)
		var/obj/item/crusher_trophy/T = t
		. += span_notice("It has \a [icon2html(T, user)] [T] attached, which causes [T.effect_desc()].")

/obj/item/kinetic_crusher/attackby(obj/item/I, mob/living/user)
	if(I.tool_behaviour == TOOL_CROWBAR)
		if(LAZYLEN(trophies))
			to_chat(user, span_notice("You remove [src]'s trophies."))
			I.play_tool_sound(src)
			for(var/t in trophies)
				var/obj/item/crusher_trophy/T = t
				T.remove_from(src, user)
		else
			to_chat(user, span_warning("There are no trophies on [src]."))
	else if(istype(I, /obj/item/crusher_trophy))
		var/obj/item/crusher_trophy/T = I
		T.add_to(src, user)
	else
		return ..()

/obj/item/kinetic_crusher/attack(mob/living/target, mob/living/carbon/user)
	if(!wielded)
		to_chat(user, span_warning("[src] is too heavy to use with one hand! You fumble and drop everything."))
		user.drop_all_held_items()
		return
	var/datum/status_effect/crusher_damage/C = target.has_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
	if(!C)
		C = target.apply_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
	var/target_health = target.health
	..()
	for(var/t in trophies)
		if(!QDELETED(target))
			var/obj/item/crusher_trophy/T = t
			T.on_melee_hit(target, user)
	if(!QDELETED(C) && !QDELETED(target))
		C.total_damage += target_health - target.health //we did some damage, but let's not assume how much we did

/obj/item/kinetic_crusher/afterattack(atom/target, mob/living/user, proximity_flag, clickparams)
	. = ..()
	var/modifiers = params2list(clickparams)
	if(!wielded)
		return

	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		for(var/t in trophies)
			if(!QDELETED(target))
				var/obj/item/crusher_trophy/T = t
				T.on_right_click(target, user)
		return

	if(!proximity_flag && charged)//Mark a target, or mine a tile.
		var/turf/proj_turf = user.loc
		if(!isturf(proj_turf))
			return
		var/obj/projectile/destabilizer/D = new /obj/projectile/destabilizer(proj_turf)
		for(var/t in trophies)
			var/obj/item/crusher_trophy/T = t
			T.on_projectile_fire(D, user)
		D.preparePixelProjectile(target, user, modifiers)
		D.firer = user
		D.hammer_synced = src
		playsound(user, 'sound/weapons/plasma_cutter.ogg', 100, TRUE)
		D.fire()
		charged = FALSE
		update_appearance()
		addtimer(CALLBACK(src, .proc/Recharge), charge_time)
		return
	if(proximity_flag && isliving(target))
		var/mob/living/L = target
		var/datum/status_effect/crusher_mark/CM = L.has_status_effect(STATUS_EFFECT_CRUSHERMARK)
		if(!CM || CM.hammer_synced != src || !L.remove_status_effect(STATUS_EFFECT_CRUSHERMARK))
			return
		var/datum/status_effect/crusher_damage/C = L.has_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
		if(!C)
			C = L.apply_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
		var/target_health = L.health
		for(var/t in trophies)
			var/obj/item/crusher_trophy/T = t
			T.on_mark_detonation(target, user)
		var/misc_bonus = 0
		if(HAS_TRAIT(user, TRAIT_STRONG_MINER))
			misc_bonus += strong_miner_bonus
		if(!QDELETED(L))
			if(!QDELETED(C))
				C.total_damage += target_health - L.health //we did some damage, but let's not assume how much we did
			new /obj/effect/temp_visual/kinetic_blast(get_turf(L))
			var/backstab_dir = get_dir(user, L)
			var/def_check = L.getarmor(type = BOMB)
			if((user.dir & backstab_dir) && (L.dir & backstab_dir))
				if(!QDELETED(C))
					C.total_damage += detonation_damage + backstab_bonus + misc_bonus //cheat a little and add the total before killing it, so certain mobs don't have much lower chances of giving an item
				L.apply_damage(detonation_damage + backstab_bonus + misc_bonus, BRUTE, blocked = def_check)
				playsound(user, 'sound/weapons/kenetic_accel.ogg', 100, TRUE) //Seriously who spelled it wrong
			else
				if(!QDELETED(C))
					C.total_damage += detonation_damage + misc_bonus
				L.apply_damage(detonation_damage + misc_bonus, BRUTE, blocked = def_check)

/obj/item/kinetic_crusher/proc/Recharge()
	if(!charged)
		charged = TRUE
		update_appearance()
		playsound(src.loc, 'sound/weapons/kenetic_reload.ogg', 60, TRUE)

/obj/item/kinetic_crusher/ui_action_click(mob/user, actiontype)
	set_light_on(!light_on)
	playsound(user, 'sound/weapons/empty.ogg', 100, TRUE)
	update_appearance()


/obj/item/kinetic_crusher/update_icon_state()
	inhand_icon_state = "crusher[wielded]" // this is not icon_state and not supported by 2hcomponent
	return ..()

/obj/item/kinetic_crusher/update_overlays()
	. = ..()
	if(!charged)
		. += "[icon_state]_uncharged"
	if(light_on)
		. += "[icon_state]_lit"

//destablizing force
/obj/projectile/destabilizer
	name = "destabilizing force"
	icon_state = "pulse1"
	nodamage = TRUE
	damage = 0 //We're just here to mark people. This is still a melee weapon.
	damage_type = BRUTE
	flag = BOMB
	range = 6
	log_override = TRUE
	var/obj/item/kinetic_crusher/hammer_synced

/obj/projectile/destabilizer/Destroy()
	hammer_synced = null
	return ..()

/obj/projectile/destabilizer/on_hit(atom/target, blocked = FALSE)
	if(isliving(target))
		var/mob/living/L = target
		var/had_effect = (L.has_status_effect(STATUS_EFFECT_CRUSHERMARK)) //used as a boolean
		var/datum/status_effect/crusher_mark/CM = L.apply_status_effect(STATUS_EFFECT_CRUSHERMARK, hammer_synced)
		if(hammer_synced)
			for(var/t in hammer_synced.trophies)
				var/obj/item/crusher_trophy/T = t
				T.on_mark_application(target, CM, had_effect)
	var/target_turf = get_turf(target)
	if(ismineralturf(target_turf))
		var/turf/closed/mineral/M = target_turf
		new /obj/effect/temp_visual/kinetic_blast(M)
		M.gets_drilled(firer)
	..()

//trophies
/obj/item/crusher_trophy
	name = "tail spike"
	desc = "A strange spike with no usage."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "tail_spike"
	var/bonus_value = 10 //if it has a bonus effect, this is how much that effect is
	var/denied_type = /obj/item/crusher_trophy

/obj/item/crusher_trophy/examine(mob/living/user)
	. = ..()
	. += span_notice("Causes [effect_desc()] when attached to a kinetic crusher.")

/obj/item/crusher_trophy/proc/effect_desc()
	return "errors"

/obj/item/crusher_trophy/attackby(obj/item/A, mob/living/user)
	if(istype(A, /obj/item/kinetic_crusher))
		add_to(A, user)
	else
		..()

/obj/item/crusher_trophy/proc/add_to(obj/item/kinetic_crusher/H, mob/living/user)
	if(LAZYLEN(H.trophies) >= H.trophy_capacity)
		to_chat(user, span_warning("You can't seem to attach [src] to [H]. Maybe remove a few trophies?"))
		return FALSE

	if(ispath(denied_type, /obj/item/crusher_trophy))
		for(var/t in H.trophies)
			var/obj/item/crusher_trophy/T = t
			if(istype(T, denied_type) || istype(src, T.denied_type))
				to_chat(user, span_warning("[icon2html(src, user)] [src] seems to conflict with [icon2html(T, user)] [T], maybe you should choose one of them?"))
				return FALSE

	else if(islist(denied_type))
		for(var/t in H.trophies)
			var/obj/item/crusher_trophy/T = t
			if(istype(src, T.denied_type))
				to_chat(user, span_warning("[icon2html(src, user)] [src] seems to conflict with [icon2html(T, user)] [T], maybe you should choose one of them?"))
				return FALSE
			for(var/denied_path in denied_type)
				if(istype(T, denied_path))
					to_chat(user, span_warning("[icon2html(src, user)] [src] seems to conflict with [icon2html(T, user)] [T], maybe you should choose one of them?"))
					return FALSE

	if(!user.transferItemToLoc(src, H))
		return
	H.trophies += src
	to_chat(user, span_notice("You attach [src] to [H]."))
	return TRUE

/obj/item/crusher_trophy/proc/remove_from(obj/item/kinetic_crusher/H, mob/living/user)
	forceMove(get_turf(H))
	H.trophies -= src
	return TRUE

/obj/item/crusher_trophy/proc/on_melee_hit(mob/living/target, mob/living/user) //the target and the user
/obj/item/crusher_trophy/proc/on_right_click(mob/living/target, mob/living/user) //the target and the user
/obj/item/crusher_trophy/proc/on_projectile_fire(obj/projectile/destabilizer/marker, mob/living/user) //the projectile fired and the user
/obj/item/crusher_trophy/proc/on_mark_application(mob/living/target, datum/status_effect/crusher_mark/mark, had_mark) //the target, the mark applied, and if the target had a mark before
/obj/item/crusher_trophy/proc/on_mark_detonation(mob/living/target, mob/living/user) //the target and the user

//goliath
/obj/item/crusher_trophy/goliath_tentacle
	name = "goliath tentacle"
	desc = "A sliced-off goliath tentacle. Suitable as a trophy for a kinetic crusher."
	icon_state = "goliath_tentacle"
	denied_type = /obj/item/crusher_trophy/goliath_tentacle
	bonus_value = 2
	var/missing_health_ratio = 0.1
	var/missing_health_desc = 10

/obj/item/crusher_trophy/goliath_tentacle/effect_desc()
	return "mark detonation to do <b>[bonus_value]</b> more damage for every <b>[missing_health_desc]</b> health you are missing"

/obj/item/crusher_trophy/goliath_tentacle/on_mark_detonation(mob/living/target, mob/living/user)
	var/missing_health = user.maxHealth - user.health
	missing_health *= missing_health_ratio //bonus is active at all times, even if you're above 90 health
	missing_health *= bonus_value //multiply the remaining amount by bonus_value
	if(missing_health > 0)
		target.adjustBruteLoss(missing_health) //and do that much damage

//watcher
/obj/item/crusher_trophy/watcher_wing
	name = "watcher wing"
	desc = "A wing ripped from a watcher. Suitable as a trophy for a kinetic crusher."
	icon_state = "watcher_wing"
	denied_type = /obj/item/crusher_trophy/watcher_wing
	bonus_value = 5

/obj/item/crusher_trophy/watcher_wing/effect_desc()
	return "mark detonation to prevent certain creatures from using certain attacks for <b>[bonus_value*0.1]</b> second\s"

/obj/item/crusher_trophy/watcher_wing/on_mark_detonation(mob/living/target, mob/living/user)
	if(ishostile(target))
		var/mob/living/simple_animal/hostile/H = target
		if(H.ranged) //briefly delay ranged attacks
			if(H.ranged_cooldown >= world.time)
				H.ranged_cooldown += bonus_value
			else
				H.ranged_cooldown = bonus_value + world.time

//magmawing watcher
/obj/item/crusher_trophy/blaster_tubes/magma_wing
	name = "magmawing watcher wing"
	desc = "A still-searing wing from a magmawing watcher. Suitable as a trophy for a kinetic crusher."
	icon_state = "magma_wing"
	gender = NEUTER
	bonus_value = 5

/obj/item/crusher_trophy/blaster_tubes/magma_wing/effect_desc()
	return "mark detonation to make the next destabilizer shot deal <b>[bonus_value]</b> damage"

/obj/item/crusher_trophy/blaster_tubes/magma_wing/on_projectile_fire(obj/projectile/destabilizer/marker, mob/living/user)
	if(deadly_shot)
		marker.name = "heated [marker.name]"
		marker.icon_state = "lava"
		marker.damage = bonus_value
		marker.nodamage = FALSE
		deadly_shot = FALSE

//icewing watcher
/obj/item/crusher_trophy/watcher_wing/ice_wing
	name = "icewing watcher wing"
	desc = "A carefully preserved frozen wing from an icewing watcher. Suitable as a trophy for a kinetic crusher."
	icon_state = "ice_wing"
	bonus_value = 8

//legion
/obj/item/crusher_trophy/legion_skull
	name = "legion skull"
	desc = "A dead and lifeless legion skull. Suitable as a trophy for a kinetic crusher."
	icon_state = "legion_skull"
	denied_type = /obj/item/crusher_trophy/legion_skull
	bonus_value = 3

/obj/item/crusher_trophy/legion_skull/effect_desc()
	return "a kinetic crusher to recharge <b>[bonus_value*0.1]</b> second\s faster"

/obj/item/crusher_trophy/legion_skull/add_to(obj/item/kinetic_crusher/H, mob/living/user)
	. = ..()
	if(.)
		H.charge_time -= bonus_value

/obj/item/crusher_trophy/legion_skull/remove_from(obj/item/kinetic_crusher/H, mob/living/user)
	. = ..()
	if(.)
		H.charge_time += bonus_value

//blood-drunk hunter
/obj/item/crusher_trophy/miner_eye
	name = "eye of a blood-drunk hunter"
	desc = "Its pupil is collapsed and turned to mush. Suitable as a trophy for a kinetic crusher."
	icon_state = "hunter_eye"
	denied_type = /obj/item/crusher_trophy/miner_eye

/obj/item/crusher_trophy/miner_eye/effect_desc()
	return "mark detonation to grant stun immunity and <b>90%</b> damage reduction for <b>1</b> second"

/obj/item/crusher_trophy/miner_eye/on_mark_detonation(mob/living/target, mob/living/user)
	user.apply_status_effect(STATUS_EFFECT_BLOODDRUNK)

//ash drake
/obj/item/crusher_trophy/tail_spike
	desc = "A spike taken from an ash drake's tail. Suitable as a trophy for a kinetic crusher."
	denied_type = /obj/item/crusher_trophy/tail_spike
	bonus_value = 5

/obj/item/crusher_trophy/tail_spike/effect_desc()
	return "mark detonation to do <b>[bonus_value]</b> damage to nearby creatures and push them back"

/obj/item/crusher_trophy/tail_spike/on_mark_detonation(mob/living/target, mob/living/user)
	for(var/mob/living/L in oview(2, user))
		if(L.stat == DEAD)
			continue
		playsound(L, 'sound/magic/fireball.ogg', 20, TRUE)
		new /obj/effect/temp_visual/fire(L.loc)
		addtimer(CALLBACK(src, .proc/pushback, L, user), 1) //no free backstabs, we push AFTER module stuff is done
		L.adjustFireLoss(bonus_value, forced = TRUE)

/obj/item/crusher_trophy/tail_spike/proc/pushback(mob/living/target, mob/living/user)
	if(!QDELETED(target) && !QDELETED(user) && (!target.anchored || ismegafauna(target))) //megafauna will always be pushed
		step(target, get_dir(user, target))

//bubblegum
/obj/item/crusher_trophy/demon_claws
	name = "demon claws"
	desc = "A set of blood-drenched claws from a massive demon's hand. Suitable as a trophy for a kinetic crusher."
	icon_state = "demon_claws"
	gender = PLURAL
	denied_type = /obj/item/crusher_trophy/demon_claws
	bonus_value = 10
	var/static/list/damage_heal_order = list(BRUTE, BURN, OXY)

/obj/item/crusher_trophy/demon_claws/effect_desc()
	return "melee hits to do <b>[bonus_value * 0.2]</b> more damage and heal you for <b>[bonus_value * 0.1]</b>, with <b>5X</b> effect on mark detonation"

/obj/item/crusher_trophy/demon_claws/add_to(obj/item/kinetic_crusher/H, mob/living/user)
	. = ..()
	if(.)
		H.force += bonus_value * 0.2
		H.detonation_damage += bonus_value * 0.8
		AddComponent(/datum/component/two_handed, force_wielded=(20 + bonus_value * 0.2))

/obj/item/crusher_trophy/demon_claws/remove_from(obj/item/kinetic_crusher/H, mob/living/user)
	. = ..()
	if(.)
		H.force -= bonus_value * 0.2
		H.detonation_damage -= bonus_value * 0.8
		AddComponent(/datum/component/two_handed, force_wielded=20)

/obj/item/crusher_trophy/demon_claws/on_melee_hit(mob/living/target, mob/living/user)
	user.heal_ordered_damage(bonus_value * 0.1, damage_heal_order)

/obj/item/crusher_trophy/demon_claws/on_mark_detonation(mob/living/target, mob/living/user)
	user.heal_ordered_damage(bonus_value * 0.4, damage_heal_order)

//colossus
/obj/item/crusher_trophy/blaster_tubes
	name = "blaster tubes"
	desc = "The blaster tubes from a colossus's arm. Suitable as a trophy for a kinetic crusher."
	icon_state = "blaster_tubes"
	gender = PLURAL
	denied_type = /obj/item/crusher_trophy/blaster_tubes
	bonus_value = 15
	var/deadly_shot = FALSE

/obj/item/crusher_trophy/blaster_tubes/effect_desc()
	return "mark detonation to make the next destabilizer shot deal <b>[bonus_value]</b> damage but move slower"

/obj/item/crusher_trophy/blaster_tubes/on_projectile_fire(obj/projectile/destabilizer/marker, mob/living/user)
	if(deadly_shot)
		marker.name = "deadly [marker.name]"
		marker.icon_state = "chronobolt"
		marker.damage = bonus_value
		marker.nodamage = FALSE
		marker.speed = 2
		deadly_shot = FALSE

/obj/item/crusher_trophy/blaster_tubes/on_mark_detonation(mob/living/target, mob/living/user)
	deadly_shot = TRUE
	addtimer(CALLBACK(src, .proc/reset_deadly_shot), 300, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/crusher_trophy/blaster_tubes/proc/reset_deadly_shot()
	deadly_shot = FALSE

//hierophant
/obj/item/crusher_trophy/vortex_talisman
	name = "vortex talisman"
	desc = "A glowing trinket that was originally the Hierophant's beacon. Suitable as a trophy for a kinetic crusher."
	icon_state = "vortex_talisman"
	denied_type = /obj/item/crusher_trophy/vortex_talisman

/obj/item/crusher_trophy/vortex_talisman/effect_desc()
	return "mark detonation to create a barrier you can pass"

/obj/item/crusher_trophy/vortex_talisman/on_mark_detonation(mob/living/target, mob/living/user)
	var/turf/T = get_turf(user)
	new /obj/effect/temp_visual/hierophant/wall/crusher(T, user) //a wall only you can pass!
	var/turf/otherT = get_step(T, turn(user.dir, 90))
	if(otherT)
		new /obj/effect/temp_visual/hierophant/wall/crusher(otherT, user)
	otherT = get_step(T, turn(user.dir, -90))
	if(otherT)
		new /obj/effect/temp_visual/hierophant/wall/crusher(otherT, user)

/obj/effect/temp_visual/hierophant/wall/crusher
	duration = 75

// Cave Bat and Albino Cave Bat

/obj/item/crusher_trophy/bat_wing //Basically an alternative version of demon claws that requires you to detonate your mark first and doesn't give x5 effect on mark detonation, but you get more healing and also regenerate your blood.
	name = "cave bat wing"
	desc = "A wing of a cave bat. Suitable as a trophy for a kinetic crusher."
	icon_state = "bat_wing"
	denied_type = /obj/item/crusher_trophy/bat_wing

/obj/item/crusher_trophy/bat_wing/effect_desc()
	return "mark detonation to apply a bloody mark to the target. For each hit you land at the marked creature will regenerate some of your health and blood"

/obj/item/crusher_trophy/bat_wing/on_mark_detonation(mob/living/target, mob/living/user)
	target.apply_status_effect(STATUS_EFFECT_BLOODYMARK)

/obj/item/crusher_trophy/bat_wing/on_melee_hit(mob/living/target, mob/living/user)
	if(target.has_status_effect(STATUS_EFFECT_BLOODYMARK))
		user.heal_ordered_damage(3, list(BRUTE, BURN, OXY))
		if(iscarbon(user))
			var/mob/living/carbon/carbie = user
			carbie.blood_volume += carbie.blood_volume >= BLOOD_VOLUME_NORMAL ? 0 : 10

/obj/effect/temp_visual/bat_wing_detonation
	icon = 'icons/effects/effects.dmi'
	icon_state = "bat_wing_detonation"
	duration = 4

/obj/item/crusher_trophy/white_bat_wing // A nice but not too OP DPS and healing trophy. Does not work with axe head because we need at least SOME balance
	name = "albino cave bat wing"
	desc = "A pure white bat wing. Suitable as a trophy for a kinetic crusher."
	icon_state = "white_bat_wing"
	denied_type = list(/obj/item/crusher_trophy/white_bat_wing, /obj/item/crusher_trophy/axe_head)
	var/charges = 0

/obj/item/crusher_trophy/white_bat_wing/effect_desc()
	return "each melee hit to add a blood charge. When three charges are collected, the next target you hit will recieve massive damage and you will steal some of their health. Current charges [charges] / 3"

/obj/item/crusher_trophy/white_bat_wing/on_melee_hit(mob/living/target, mob/living/user)
	charges += 1

	if(charges >= 4)
		charges = 0
		new /obj/effect/temp_visual/bat_wing_detonation(get_turf(target))
		if(isanimal(target))
			target.adjustBruteLoss(75)

		user.heal_ordered_damage(10, list(BRUTE, BURN, OXY))
		if(iscarbon(user))
			var/mob/living/carbon/carbie = user
			carbie.blood_volume += carbie.blood_volume >= BLOOD_VOLUME_NORMAL ? 0 : 15

//Cave Spider and Red Cave Spider

/obj/item/crusher_trophy/red_spider_webweaver
	name = "red cave spider's web weaver"
	desc = "A bloody red web weaver. Suitable as a trophy for a kinetic crusher."
	icon_state = "red_spider_webweaver"
	denied_type = list(/obj/item/crusher_trophy/red_spider_webweaver, /obj/item/crusher_trophy/blaster_tubes)
	var/web_shot = FALSE

/obj/item/crusher_trophy/red_spider_webweaver/effect_desc()
	return "mark detonation to turn next shot into a ball of web that will stun enemies and pull them at you upon hit"

/obj/item/crusher_trophy/red_spider_webweaver/on_projectile_fire(obj/projectile/destabilizer/marker, mob/living/user)
	if(web_shot)
		marker.name = "webbed [marker.name]"
		marker.icon_state = "webball"
		RegisterSignal(marker, COMSIG_PROJECTILE_ON_HIT, .proc/projectile_hit)
		web_shot = FALSE

/obj/item/crusher_trophy/red_spider_webweaver/on_mark_detonation(mob/living/target, mob/living/user)
	web_shot = TRUE
	addtimer(CALLBACK(src, .proc/reset_web_shot), 300, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/crusher_trophy/red_spider_webweaver/proc/reset_web_shot()
	web_shot = FALSE

/obj/item/crusher_trophy/red_spider_webweaver/proc/projectile_hit(atom/fired_from, atom/movable/firer, atom/target, Angle)
	SIGNAL_HANDLER
	if(isliving(target))
		var/mob/living/L = target
		L.safe_throw_at(firer, 5, 1, firer, FALSE, TRUE, gentle = TRUE)
		var/datum/beam/web = firer.Beam(target, icon_state = "web")
		QDEL_IN(web, 3 SECONDS)

/obj/item/crusher_trophy/spider_webweaver //Useful with ranged builds
	name = "cave spider's web weaver"
	desc = "A ripped off web weaver. Suitable as a trophy for a kinetic crusher."
	icon_state = "spider_webweaver"
	denied_type = /obj/item/crusher_trophy/spider_webweaver

/obj/item/crusher_trophy/spider_webweaver/effect_desc()
	return "mark detonation to throw you away from your enemy a few tiles"

/obj/item/crusher_trophy/spider_webweaver/on_mark_detonation(mob/living/target, mob/living/user)
	var/turf/target_turf = get_edge_target_turf(user, get_dir(target, user))
	user.throw_at(target_turf, 2, 2, user, FALSE, TRUE, gentle = TRUE)

//Leaper

/obj/item/crusher_trophy/leaper_eye
	name = "leaper eye"
	desc = "A blood-red eye of a leaper. Suitable as a trophy for a kinetic crusher."
	icon_state = "leaper_eye"
	denied_type = list(/obj/item/crusher_trophy/ai_core, /obj/item/crusher_trophy/leaper_eye)
	var/jump_cooldown = 0

/obj/item/crusher_trophy/leaper_eye/effect_desc()
	return "ranged right click attacks to make you jump onto your target instead"

/obj/item/crusher_trophy/leaper_eye/on_right_click(atom/target, mob/living/user)
	if(jump_cooldown > world.time)
		to_chat(user, "<span class='warning'>[src] hasn't fully recovered from the previous jump! Wait [round((jump_cooldown - world.time) / 10)] more seconds!</span>")
		return

	if(isclosedturf(target) || isclosedturf(get_turf(target)))
		return

	jump_cooldown = world.time + 3 SECONDS
	new /obj/effect/temp_visual/leaper_crush_small(get_turf(target))
	addtimer(CALLBACK(src, .proc/jump, target, user), 0.5 SECONDS)

/obj/item/crusher_trophy/leaper_eye/proc/jump(atom/target, mob/living/user)
	var/old_density = user.density
	user.density = FALSE
	user.throw_at(target, get_dist(user, target), 3, user, FALSE, callback = CALLBACK(src, .proc/crush, target, user, old_density), gentle = TRUE)

/obj/item/crusher_trophy/leaper_eye/proc/crush(atom/target, mob/living/user, old_density) //More suitable for quick escapes/sudden attacks/gimmick builds
	playsound(user, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	user.density = old_density
	var/new_turf = get_turf(user)
	for(var/mob/living/victim in new_turf)
		if(victim == user)
			continue

		if(isanimal(victim))
			victim.adjustBruteLoss(35)
			victim.Paralyze(1 SECONDS)
		else
			victim.adjustBruteLoss(15)

		if(!QDELETED(victim)) // Some mobs are deleted on death
			var/throw_dir = get_dir(user, victim)
			if(victim.loc == loc)
				throw_dir = pick(GLOB.alldirs)
			var/throwtarget = get_edge_target_turf(user, throw_dir)
			victim.throw_at(throwtarget, 5, 1)
			visible_message("<span class='warning'>[victim] is thrown clear of [user]!</span>")

	jump_cooldown = world.time + 7 SECONDS

//Mega Arachnid

/obj/item/crusher_trophy/acid_sack //Blood-drunk eye analogue. Works slightly different
	name = "acid sack"
	desc = "A still pulsing sack full of acidic blood. Suitable as a trophy for a kinetic crusher."
	icon_state = "acid_sack"
	denied_type = list(/obj/item/crusher_trophy/acid_sack)

/obj/item/crusher_trophy/acid_sack/effect_desc()
	return "mark detonation to gain temporal stun and slowdown immunity. Each normal hit with crusher while it's active makes the effect last slightly longer"

/obj/item/crusher_trophy/acid_sack/on_mark_detonation(mob/living/target, mob/living/user)
	user.apply_status_effect(STATUS_EFFECT_ACID_SACK)

/obj/item/crusher_trophy/acid_sack/on_melee_hit(mob/living/target, mob/living/user)
	var/datum/status_effect/acid_sack/C = user.has_status_effect(STATUS_EFFECT_ACID_SACK)
	if(C)
		C.duration += 0.5 SECONDS //Not enough time to infinitely stack it.

//Mook

/obj/item/crusher_trophy/axe_head //Allows you to hit super fast if you manage to constantly detonate marks, but heavily impacts damage.
	name = "axe head"
	desc = "A shiny metal axe head. Suitable as a trophy for a kinetic crusher."
	icon_state = "axe_head"
	denied_type = list(/obj/item/crusher_trophy/axe_head, /obj/item/crusher_trophy/crystal_shard)

/obj/item/crusher_trophy/axe_head/effect_desc()
	return "mark detonation to lower attack cooldown. Heavily impacts damage while also reducing recharge time"

/obj/item/crusher_trophy/axe_head/on_mark_detonation(mob/living/target, mob/living/user)
	user.changeNext_move(CLICK_CD_RAPID)
	if(istype(loc, /obj/item/kinetic_crusher))
		var/obj/item/kinetic_crusher/kinetic_crusher = loc
		kinetic_crusher.Recharge()

/obj/item/crusher_trophy/axe_head/add_to(obj/item/kinetic_crusher/crusher, mob/living/user)
	. = ..()
	if(.)
		var/datum/component/two_handed/wielded = crusher.GetComponent(/datum/component/two_handed)
		crusher.AddComponent(/datum/component/two_handed, force_wielded = wielded.force_wielded * 0.25) //Breaks when used with wendigo's horn, but this shouldn't happen normally.
		crusher.charge_time -= 10
		crusher.detonation_damage -= 35
		crusher.backstab_bonus -= 20

/obj/item/crusher_trophy/axe_head/remove_from(obj/item/kinetic_crusher/crusher, mob/living/user)
	. = ..()
	if(.)
		var/datum/component/two_handed/wielded = crusher.GetComponent(/datum/component/two_handed)
		crusher.AddComponent(/datum/component/two_handed, force_wielded = wielded.force_wielded * 4)
		crusher.charge_time += 10
		crusher.detonation_damage += 40
		crusher.backstab_bonus += 20

//Seedling

/obj/item/crusher_trophy/tail_spike/seedling_petal
	name = "seedling petal"
	desc = "A petal from a seedling. Suitable as a trophy for a kinetic crusher."
	icon_state = "seedling_petal"
	denied_type = /obj/item/crusher_trophy/tail_spike/seedling_petal

/obj/item/crusher_trophy/tail_spike/seedling_petal/on_mark_detonation(mob/living/target, mob/living/user)
	for(var/mob/living/L in oview(2, user))
		if(L.stat == DEAD)
			continue
		playsound(L, 'sound/weapons/sear.ogg', 20, TRUE)
		new /obj/effect/temp_visual/seedling_sparks(L.loc)
		addtimer(CALLBACK(src, .proc/pushback, L, user), 1)
		L.adjustFireLoss(bonus_value, forced = TRUE)

//Snakeman and Alpha Snakeman

/obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs //Haha balls jokes
	name = "adrenaline sacs"
	desc = "Sliced-off adrenaline sacs. Suitable as a trophy for a kinetic crusher."
	icon_state = "adrenaline_sacs"
	denied_type = /obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs

/obj/item/crusher_trophy/goliath_tentacle/adrenaline_sacs/alpha
	name = "purple adrenaline sacs"
	desc = "Purple adrenaline sacs sliced off from an alpha snakeman. Suitable as a trophy for a kinetic crusher."
	icon_state = "purple_adrenaline_sacs"
	bonus_value = 4

//Spider Queen

/obj/item/crusher_trophy/spider_leg
	name = "queen spider leg"
	desc = "A leg ripped off from a spider queen. Suitable as a trophy for a kinetic crusher."
	icon_state = "spider_leg"
	denied_type = /obj/item/crusher_trophy/spider_leg

/obj/item/crusher_trophy/spider_leg/effect_desc()
	return "mark detonation to create a shockwave, throwing your enemies away from you"

/obj/item/crusher_trophy/spider_leg/on_mark_detonation(mob/living/target, mob/living/user)
	INVOKE_ASYNC(src, .proc/create_shockwave, target, user)

/obj/item/crusher_trophy/spider_leg/proc/create_shockwave(mob/living/target, mob/living/user)
	var/list/hit_things = list()
	var/turf/user_turf = get_turf(user)
	for(var/i in 1 to 3)
		user_turf = get_step(user_turf, get_dir(user, target))
		if(!user_turf || user_turf.is_blocked_turf(TRUE))
			return
		new /obj/effect/temp_visual/small_smoke/halfsecond(user_turf)
		for(var/mob/living/victim in user_turf.contents)
			if(user_turf != user && !(victim in hit_things) && !faction_check(victim.faction, user.faction))
				var/throwtarget = get_edge_target_turf(user_turf, get_dir(user, victim))
				victim.throw_at(throwtarget, 3, 1, user)
				victim.adjustBruteLoss(10)
				hit_things += victim
		sleep(1)

//Ancient AI

/obj/item/crusher_trophy/ai_core
	name = "AI core"
	desc = "A potato with a lot of wires in it. Suitable as a trophy for a kinetic crusher."
	icon_state = "ai_core"
	denied_type = list(/obj/item/crusher_trophy/ai_core, /obj/item/crusher_trophy/leaper_eye)
	var/drone_cooldown = 0
	var/drone_destroy_time = 0
	var/mob/living/simple_animal/hostile/crusher_drone/drone

/obj/item/crusher_trophy/ai_core/effect_desc()
	return "ranged right click attacks to create a flying drone that attack your enemies with long-ranged destabilizing force"

/obj/item/crusher_trophy/ai_core/on_right_click(atom/target, mob/living/user)
	if(drone && !QDELETED(drone))
		if(drone_destroy_time > world.time)
			to_chat(user, span_notice("Drone successfully destroyed."))
			drone.death()
			return

		to_chat(user, span_warning("Your previous drone is still alive! Use the trophy again to destroy it."))
		drone_destroy_time = world.time + 3 SECONDS
		return

	if(drone_cooldown > world.time)
		to_chat(user, span_warning("Wait [round((drone_cooldown - world.time) / 10)] more seconds before trying to create another drone!"))
		return

	if(isclosedturf(get_turf(target)))
		return

	drone_cooldown = world.time + 30 SECONDS

	drone = new(get_turf(user))
	drone.faction = list("neutral", "[REF(user)]")
	drone.GiveTarget(target)
	drone.crusher = loc

/mob/living/simple_animal/hostile/crusher_drone
	name = "V.0.R.T.X. drone"
	desc = "An outdated version of an automated defence drone that were made to help protect colonies from local fauna. This one is linked to a kinetic crusher and shares it's tropheys."
	icon = 'icons/mob/jungle/jungle_monsters.dmi'
	icon_state = "crusher_drone"
	icon_living = "crusher_drone"
	mob_biotypes = MOB_ROBOTIC
	combat_mode = FALSE
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_plas" = 0, "max_plas" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	faction = list("neutral")
	maxHealth = 200
	health = 200
	obj_damage = 0
	melee_damage_lower = 0
	melee_damage_upper = 0
	del_on_death = TRUE

	speed = 4
	retreat_distance = 3
	minimum_distance = 5

	deathmessage = "slowly floats down to the ground as it shuts down."
	deathsound = 'sound/voice/borg_deathsound.ogg'
	ranged = 1
	ranged_cooldown_time = 2 SECONDS
	var/obj/item/kinetic_crusher/crusher

/mob/living/simple_animal/hostile/crusher_drone/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/projectile/kinetic))
		return TRUE
	else if(istype(mover, /obj/projectile/destabilizer))
		return TRUE

/mob/living/simple_animal/hostile/crusher_drone/AttackingTarget(atom/attacked_target)
	Shoot(attacked_target)

/mob/living/simple_animal/hostile/crusher_drone/Shoot(mob/targeted)
	if(!targeted)
		return

	setDir(get_dir(src, targeted))

	var/obj/projectile/destabilizer/proj = new /obj/projectile/destabilizer/vortex_drone(get_turf(src))
	for(var/obj/item/crusher_trophy/trophy in crusher.trophies)
		trophy.on_projectile_fire(proj, src)
	proj.preparePixelProjectile(get_turf(targeted), get_turf(src))
	proj.firer = src
	proj.hammer_synced = crusher
	playsound(src, 'sound/weapons/plasma_cutter.ogg', 100, TRUE)
	proj.fire()

/obj/projectile/destabilizer/vortex_drone
	range = 12

/mob/living/carbon/human/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/projectile/destabilizer/vortex_drone))
		return TRUE

//Bluespace Spirit

#define MAX_PARTICLE_CONNECTIONS 3
#define MAX_PARTICLES 7

/obj/item/crusher_trophy/bluespace_rift
	name = "bluespace rift"
	desc = "A rift in space and time, created by an unknown anomaly. Suitable as a trophy for a kinetic crusher."
	icon_state = "bluespace_rift"
	denied_type = list(/obj/item/crusher_trophy/bluespace_rift)
	bonus_value = 15
	var/list/bluespace_particles = list()

/obj/item/crusher_trophy/bluespace_rift/effect_desc()
	return "mark detonations to create bluespace particles that will connect together using beams. Whenever an enemy passes through the beam, they get damaged for <b>[bonus_value]</b>"

/obj/item/crusher_trophy/bluespace_rift/on_mark_detonation(mob/living/target, mob/living/user)
	playsound(get_turf(target), 'sound/magic/lightningbolt.ogg', 25, TRUE)
	if(locate(/obj/effect/bluespace_particle) in get_turf(target))
		return
	var/obj/effect/bluespace_particle/particle = new(get_turf(target), user)
	if(LAZYLEN(bluespace_particles) >= MAX_PARTICLES)
		qdel(pick_n_take(bluespace_particles))
	bluespace_particles += particle
	QDEL_IN(particle, 30 SECONDS)

/obj/effect/bluespace_particle
	name = "bluespace particle"
	desc = "A small tear in bluespace."
	icon = 'icons/effects/effects.dmi'
	icon_state = "bluespace_particle"
	var/list/particle_beams = list()

/obj/effect/bluespace_particle/Initialize(mapload, mob/living/author)
	. = ..()

	var/connection_count = 0
	for(var/obj/effect/bluespace_particle/particle in orange(6, get_turf(src)))
		if(!istype(particle) || particle == src)
			continue
		var/datum/beam/particle_beam = Beam(particle, icon_state = "bluespace_beam", beam_type = /obj/effect/ebeam/bluespace_blast)
		particle.particle_beams[particle_beam] = src
		particle_beams[particle_beam] = particle
		connection_count += 1
		if(connection_count >= MAX_PARTICLE_CONNECTIONS)
			break

/obj/effect/bluespace_particle/Destroy(force)
	for(var/particle_beam in particle_beams)
		var/obj/effect/bluespace_particle/connected_to = particle_beams[particle_beam]
		connected_to.particle_beams -= particle_beam
		qdel(particle_beam)
	. = ..()

#undef MAX_PARTICLE_CONNECTIONS
#undef MAX_PARTICLES

/obj/effect/ebeam/bluespace_blast
	name = "bluespace blast"
	mouse_opacity = MOUSE_OPACITY_ICON

/obj/effect/ebeam/bluespace_blast/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = .proc/on_entered,
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/ebeam/bluespace_blast/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(isliving(AM))
		var/mob/living/L = AM
		if("jungle" in L.faction && !("neutral" in L.faction))
			L.adjustFireLoss(10)

//Demonic Miner

/mob/living/simple_animal/hostile/jungle/hellborn_shadow
	name = "hellborn shadow"
	desc = "A transparent, dark red spirit from the depths of hell, coming for your soul."
	response_help_continuous = "thinks better of touching"
	response_help_simple = "think better of touching"
	response_disarm_continuous = "flails at"
	response_disarm_simple = "flail at"
	response_harm_continuous = "punches"
	response_harm_simple = "punch"
	icon = 'icons/mob/jungle/jungle_monsters.dmi'
	icon_state = "spirit"
	icon_living = "spirit"
	speed = 4
	move_to_delay = 4
	combat_mode = TRUE
	attack_sound = 'sound/magic/demon_attack1.ogg'
	attack_vis_effect = ATTACK_EFFECT_CLAW
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = INFINITY
	faction = list("jungle", "boss", "hell")
	weather_immunities = list(TRAIT_ACID_IMMUNE, TRAIT_LAVA_IMMUNE)
	attack_verb_continuous = "flails at"
	attack_verb_simple = "flail at"
	maxHealth = 40
	health = 40
	healable = 0
	obj_damage = 10
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	melee_damage_lower = 5
	melee_damage_upper = 5
	vision_range = 2
	aggro_vision_range = 4
	see_in_dark = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	del_on_death = TRUE
	deathmessage = "screams in agony as it sublimates into a cloud of sulfurous smoke."
	deathsound = 'sound/magic/demon_dies.ogg'
	var/obj/item/crusher_trophy/demon_horn/horn

/mob/living/simple_animal/hostile/jungle/hellborn_shadow/Initialize(mapload, creator)
	. = ..()
	horn = creator
	horn.spirits.Add(src)
	ADD_TRAIT(src, TRAIT_CRUSHER_VUNERABLE, INNATE_TRAIT)

/mob/living/simple_animal/hostile/jungle/hellborn_shadow/death(gibbed)
	horn.spirits.Remove(src)
	. = ..()

/obj/item/crusher_trophy/demon_horn //Glory kills!
	name = "demon horn"
	desc = "A big red curved horn. Suitable as a trophy for a kinetic crusher."
	icon_state = "demon_horn"
	denied_type = /obj/item/crusher_trophy/demon_horn
	var/buffing = FALSE
	var/stop_buff_timer
	var/list/spirits = list()

/obj/item/crusher_trophy/demon_horn/effect_desc()
	return "kills with mark detonation to give you a temporary boost in speed and armor as well as light healing. While fighting megafauna, small low-health spirits will appear around the user"

/obj/item/crusher_trophy/demon_horn/on_mark_detonation(mob/living/target, mob/living/user)
	INVOKE_ASYNC(src, .proc/glory_kill_check, target, user)

/obj/item/crusher_trophy/demon_horn/proc/glory_kill_check(mob/living/target, mob/living/user)
	sleep(1) //Just enough time for target to process their health. Doesn't work without sleep cuz crusher code.

	if(QDELETED(user) || user.stat == DEAD || !ishuman(user))
		return

	var/mob/living/carbon/human/human_user = user
	human_user.heal_ordered_damage(15, list(BRUTE, BURN, TOX, OXY))

	if(!buffing)
		human_user.add_movespeed_modifier(/datum/movespeed_modifier/glory_kill)
		human_user.physiology.damage_resistance += 50
		human_user.physiology.stun_mod *= 0.25
		human_user.physiology.bleed_mod *= 0.25
		buffing = TRUE

	if(stop_buff_timer)
		deltimer(stop_buff_timer)
	stop_buff_timer = addtimer(CALLBACK(src, .proc/stop_buff, human_user), 5 SECONDS, TIMER_STOPPABLE)

/obj/item/crusher_trophy/demon_horn/proc/stop_buff(mob/living/carbon/human/user)
	user.remove_movespeed_modifier(/datum/movespeed_modifier/glory_kill)
	user.physiology.damage_resistance -= 50
	user.physiology.stun_mod /= 0.25
	user.physiology.bleed_mod /= 0.25
	buffing = FALSE

/obj/item/crusher_trophy/demon_horn/add_to(obj/item/kinetic_crusher/H, mob/living/user)
	. = ..()
	if(.)
		START_PROCESSING(SSfastprocess, src)

/obj/item/crusher_trophy/demon_horn/remove_from(obj/item/kinetic_crusher/H, mob/living/user)
	. = ..()
	if(.)
		STOP_PROCESSING(SSfastprocess, src)

/obj/item/crusher_trophy/demon_horn/process(delta_time)
	var/mob/living/carbon/human/user
	var/atom/loc_iter = loc
	while(!user)
		if(isturf(loc_iter) || isarea(loc_iter))
			return

		if(ishuman(loc_iter))
			user = loc_iter
			break

		loc_iter = loc_iter.loc

	var/mob/living/simple_animal/hostile/megafauna/jungle/attacker
	for(var/mob/living/simple_animal/hostile/megafauna/jungle/mega in GLOB.megafauna)
		if(mega.spawns_minions)
			continue

		if(mega.target == user)
			attacker = mega
			break

	if(!attacker)
		return

	var/list/possible_turfs = list()
	for(var/turf/open/possible_spawn in view(7, user))
		if(!possible_spawn.is_blocked_turf())
			possible_turfs.Add(possible_spawn)

	if(LAZYLEN(spirits) < 5 && DT_PROB(25, delta_time))
		var/turf/spirit_spawn = pick_n_take(possible_turfs)
		new /mob/living/simple_animal/hostile/jungle/hellborn_shadow(spirit_spawn, src)
		new /obj/effect/temp_visual/guardian/phase(spirit_spawn)

	for(var/mob/living/simple_animal/hostile/jungle/hellborn_shadow/shadow as anything in spirits)
		if(get_dist(shadow, user) > 9)
			new /obj/effect/temp_visual/guardian/phase/out(get_turf(shadow))
			spirits.Remove(shadow)
			qdel(shadow)

//Vine Kraken

/obj/item/crusher_trophy/vine_tentacle
	name = "vine tentacle"
	desc = "A long, thorny vine, moving as it's alive. Suitable as a trophy for a kinetic crusher."
	icon_state = "vine_tentacle"
	denied_type = list(/obj/item/crusher_trophy/vine_tentacle, /obj/item/crusher_trophy/axe_head)
	bonus_value = 5

/obj/item/crusher_trophy/vine_tentacle/effect_desc()
	return "mark detonation to spawn a ring of vines around you that will heal you for one third of incoming damage"

/obj/item/crusher_trophy/vine_tentacle/on_mark_detonation(mob/living/target, mob/living/user)
	user.apply_status_effect(STATUS_EFFECT_VINE_RING)

//Time Crystal

/obj/item/crusher_trophy/crystal_shard
	name = "crystal shard"
	desc = "A bright orange amber shard. Suitable as a trophy for a kinetic crusher."
	icon_state = "crystal_shard"
	denied_type = list(/obj/item/crusher_trophy/crystal_shard, /obj/item/crusher_trophy/axe_head)
	bonus_value = 5

/obj/item/crusher_trophy/crystal_shard/effect_desc()
	return "mark detonation to stun creatures and make them more vunerable for a bit"

/obj/item/crusher_trophy/crystal_shard/on_mark_detonation(mob/living/target, mob/living/user)
	INVOKE_ASYNC(src, .proc/weaken_mob, target, user)

/obj/item/crusher_trophy/crystal_shard/proc/weaken_mob(mob/living/target, mob/living/user)
	if(isanimal(target))
		var/mob/living/simple_animal/H = target
		H.Stun(bonus_value)
		H.apply_status_effect(STATUS_EFFECT_CRYSTAL_WEAKNESS) //We're using status effect system to prevent their damage_coeffs from breaking

//Mud Worm

/obj/item/crusher_trophy/blaster_tubes/giant_tooth
	name = "giant tooth"
	desc = "A giant tooth ripped out of a mud worm's mouth. Suitable as a trophy for a kinetic crusher."
	icon_state = "giant_tooth"
	bonus_value = 10
	denied_type = list(/obj/item/crusher_trophy/red_spider_webweaver, /obj/item/crusher_trophy/blaster_tubes)

/obj/item/crusher_trophy/blaster_tubes/giant_tooth/effect_desc()
	return "mark detonation to make the next destabilizer shot deal <b>[bonus_value]</b> damage"

/obj/item/crusher_trophy/blaster_tubes/giant_tooth/on_projectile_fire(obj/projectile/destabilizer/marker, mob/living/user)
	if(deadly_shot)
		marker.name = "giant tooth"
		marker.icon_state = "tooth_spin"
		marker.damage = bonus_value
		marker.nodamage = FALSE
		deadly_shot = FALSE

#undef CRUSHER_TROPHY_LIMIT
