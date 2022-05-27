//Largely beneficial effects go here, even if they have drawbacks.

/datum/status_effect/his_grace
	id = "his_grace"
	duration = -1
	tick_interval = 4
	alert_type = /atom/movable/screen/alert/status_effect/his_grace
	var/bloodlust = 0

/atom/movable/screen/alert/status_effect/his_grace
	name = "His Grace"
	desc = "His Grace hungers, and you must feed Him."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/atom/movable/screen/alert/status_effect/his_grace/MouseEntered(location,control,params)
	desc = initial(desc)
	var/datum/status_effect/his_grace/HG = attached_effect
	desc += "<br><font size=3><b>Current Bloodthirst: [HG.bloodlust]</b></font>\
	<br>Becomes undroppable at <b>[HIS_GRACE_FAMISHED]</b>\
	<br>Will consume you at <b>[HIS_GRACE_CONSUME_OWNER]</b>"
	return ..()

/datum/status_effect/his_grace/on_apply()
	owner.log_message("gained His Grace's stun immunity", LOG_ATTACK)
	owner.add_stun_absorption("hisgrace", INFINITY, 3, null, "His Grace protects you from the stun!")
	return ..()

/datum/status_effect/his_grace/tick()
	bloodlust = 0
	var/graces = 0
	for(var/obj/item/his_grace/HG in owner.held_items)
		if(HG.bloodthirst > bloodlust)
			bloodlust = HG.bloodthirst
		if(HG.awakened)
			graces++
	if(!graces)
		owner.apply_status_effect(/datum/status_effect/his_wrath)
		qdel(src)
		return
	var/grace_heal = bloodlust * 0.05
	owner.adjustBruteLoss(-grace_heal)
	owner.adjustFireLoss(-grace_heal)
	owner.adjustToxLoss(-grace_heal, TRUE, TRUE)
	owner.adjustOxyLoss(-(grace_heal * 2))
	owner.adjustCloneLoss(-grace_heal)

/datum/status_effect/his_grace/on_remove()
	owner.log_message("lost His Grace's stun immunity", LOG_ATTACK)
	if(islist(owner.stun_absorption) && owner.stun_absorption["hisgrace"])
		owner.stun_absorption -= "hisgrace"


/datum/status_effect/wish_granters_gift //Fully revives after ten seconds.
	id = "wish_granters_gift"
	duration = 50
	alert_type = /atom/movable/screen/alert/status_effect/wish_granters_gift

/datum/status_effect/wish_granters_gift/on_apply()
	to_chat(owner, span_notice("Death is not your end! The Wish Granter's energy suffuses you, and you begin to rise..."))
	return ..()


/datum/status_effect/wish_granters_gift/on_remove()
	owner.revive(full_heal = TRUE, admin_revive = TRUE)
	owner.visible_message(span_warning("[owner] appears to wake from the dead, having healed all wounds!"), span_notice("You have regenerated."))


/atom/movable/screen/alert/status_effect/wish_granters_gift
	name = "Wish Granter's Immortality"
	desc = "You are being resurrected!"
	icon_state = "wish_granter"

/datum/status_effect/cult_master
	id = "The Cult Master"
	duration = -1
	alert_type = null
	on_remove_on_mob_delete = TRUE
	var/alive = TRUE

/datum/status_effect/cult_master/proc/deathrattle()
	if(!QDELETED(GLOB.cult_narsie))
		return //if Nar'Sie is alive, don't even worry about it
	var/area/A = get_area(owner)
	for(var/datum/mind/B as anything in get_antag_minds(/datum/antagonist/cult))
		if(isliving(B.current))
			var/mob/living/M = B.current
			SEND_SOUND(M, sound('sound/hallucinations/veryfar_noise.ogg'))
			to_chat(M, span_cultlarge("The Cult's Master, [owner], has fallen in \the [A]!"))

/datum/status_effect/cult_master/tick()
	if(owner.stat != DEAD && !alive)
		alive = TRUE
		return
	if(owner.stat == DEAD && alive)
		alive = FALSE
		deathrattle()

/datum/status_effect/cult_master/on_remove()
	deathrattle()
	. = ..()

/datum/status_effect/blooddrunk
	id = "blooddrunk"
	duration = 10
	tick_interval = 0
	alert_type = /atom/movable/screen/alert/status_effect/blooddrunk

/atom/movable/screen/alert/status_effect/blooddrunk
	name = "Blood-Drunk"
	desc = "You are drunk on blood! Your pulse thunders in your ears! Nothing can harm you!" //not true, and the item description mentions its actual effect
	icon_state = "blooddrunk"

/datum/status_effect/blooddrunk/on_apply()
	. = ..()
	if(.)
		ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, BLOODDRUNK_TRAIT)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.physiology.brute_mod *= 0.1
			H.physiology.burn_mod *= 0.1
			H.physiology.tox_mod *= 0.1
			H.physiology.oxy_mod *= 0.1
			H.physiology.clone_mod *= 0.1
			H.physiology.stamina_mod *= 0.1
		owner.log_message("gained blood-drunk stun immunity", LOG_ATTACK)
		owner.add_stun_absorption("blooddrunk", INFINITY, 4)
		owner.playsound_local(get_turf(owner), 'sound/effects/singlebeat.ogg', 40, 1, use_reverb = FALSE)

/datum/status_effect/blooddrunk/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.brute_mod *= 10
		H.physiology.burn_mod *= 10
		H.physiology.tox_mod *= 10
		H.physiology.oxy_mod *= 10
		H.physiology.clone_mod *= 10
		H.physiology.stamina_mod *= 10
	owner.log_message("lost blood-drunk stun immunity", LOG_ATTACK)
	REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, BLOODDRUNK_TRAIT);
	if(islist(owner.stun_absorption) && owner.stun_absorption["blooddrunk"])
		owner.stun_absorption -= "blooddrunk"

/datum/status_effect/sword_spin
	id = "Bastard Sword Spin"
	duration = 50
	tick_interval = 8
	alert_type = null


/datum/status_effect/sword_spin/on_apply()
	owner.visible_message(span_danger("[owner] begins swinging the sword with inhuman strength!"))
	var/oldcolor = owner.color
	owner.color = "#ff0000"
	owner.add_stun_absorption("bloody bastard sword", duration, 2, "doesn't even flinch as the sword's power courses through them!", "You shrug off the stun!", " glowing with a blazing red aura!")
	owner.spin(duration,1)
	animate(owner, color = oldcolor, time = duration, easing = EASE_IN)
	addtimer(CALLBACK(owner, /atom/proc/update_atom_colour), duration)
	playsound(owner, 'sound/weapons/fwoosh.ogg', 75, FALSE)
	return ..()


/datum/status_effect/sword_spin/tick()
	playsound(owner, 'sound/weapons/fwoosh.ogg', 75, FALSE)
	var/obj/item/slashy
	slashy = owner.get_active_held_item()
	for(var/mob/living/M in orange(1,owner))
		slashy.attack(M, owner)

/datum/status_effect/sword_spin/on_remove()
	owner.visible_message(span_warning("[owner]'s inhuman strength dissipates and the sword's runes grow cold!"))


//Used by changelings to rapidly heal
//Heals 10 brute and oxygen damage every second, and 5 fire
//Being on fire will suppress this healing
/datum/status_effect/fleshmend
	id = "fleshmend"
	duration = 100
	alert_type = /atom/movable/screen/alert/status_effect/fleshmend

/datum/status_effect/fleshmend/tick()
	if(owner.on_fire)
		linked_alert.icon_state = "fleshmend_fire"
		return
	else
		linked_alert.icon_state = "fleshmend"
	owner.adjustBruteLoss(-10, FALSE)
	owner.adjustFireLoss(-5, FALSE)
	owner.adjustOxyLoss(-10)
	if(!iscarbon(owner))
		return
	var/mob/living/carbon/C = owner
	QDEL_LIST(C.all_scars)

/atom/movable/screen/alert/status_effect/fleshmend
	name = "Fleshmend"
	desc = "Our wounds are rapidly healing. <i>This effect is prevented if we are on fire.</i>"
	icon_state = "fleshmend"

/datum/status_effect/exercised
	id = "Exercised"
	duration = 1200
	alert_type = null
	processing_speed = STATUS_EFFECT_NORMAL_PROCESS

//Hippocratic Oath: Applied when the Rod of Asclepius is activated.
/datum/status_effect/hippocratic_oath
	id = "Hippocratic Oath"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	tick_interval = 25
	alert_type = null

	var/datum/component/aura_healing/aura_healing
	var/hand
	var/deathTick = 0

/datum/status_effect/hippocratic_oath/on_apply()
	var/static/list/organ_healing = list(
		ORGAN_SLOT_BRAIN = 1.4,
	)

	aura_healing = owner.AddComponent( \
		/datum/component/aura_healing, \
		range = 7, \
		brute_heal = 1.4, \
		burn_heal = 1.4, \
		toxin_heal = 1.4, \
		suffocation_heal = 1.4, \
		stamina_heal = 1.4, \
		clone_heal = 0.4, \
		simple_heal = 1.4, \
		organ_healing = organ_healing, \
		healing_color = "#375637", \
	)

	//Makes the user passive, it's in their oath not to harm!
	ADD_TRAIT(owner, TRAIT_PACIFISM, HIPPOCRATIC_OATH_TRAIT)
	var/datum/atom_hud/med_hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	med_hud.show_to(owner)
	return ..()

/datum/status_effect/hippocratic_oath/on_remove()
	QDEL_NULL(aura_healing)
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, HIPPOCRATIC_OATH_TRAIT)
	var/datum/atom_hud/med_hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	med_hud.hide_from(owner)

/datum/status_effect/hippocratic_oath/get_examine_text()
	return span_notice("[owner.p_they(TRUE)] seem[owner.p_s()] to have an aura of healing and helpfulness about [owner.p_them()].")

/datum/status_effect/hippocratic_oath/tick()
	if(owner.stat == DEAD)
		if(deathTick < 4)
			deathTick += 1
		else
			consume_owner()
	else
		if(iscarbon(owner))
			var/mob/living/carbon/itemUser = owner
			var/obj/item/heldItem = itemUser.get_item_for_held_index(hand)
			if(heldItem == null || heldItem.type != /obj/item/rod_of_asclepius) //Checks to make sure the rod is still in their hand
				var/obj/item/rod_of_asclepius/newRod = new(itemUser.loc)
				newRod.activated()
				if(!itemUser.has_hand_for_held_index(hand))
					//If user does not have the corresponding hand anymore, give them one and return the rod to their hand
					if(((hand % 2) == 0))
						var/obj/item/bodypart/L = itemUser.newBodyPart(BODY_ZONE_R_ARM, FALSE, FALSE)
						if(L.attach_limb(itemUser))
							itemUser.put_in_hand(newRod, hand, forced = TRUE)
						else
							qdel(L)
							consume_owner() //we can't regrow, abort abort
							return
					else
						var/obj/item/bodypart/L = itemUser.newBodyPart(BODY_ZONE_L_ARM, FALSE, FALSE)
						if(L.attach_limb(itemUser))
							itemUser.put_in_hand(newRod, hand, forced = TRUE)
						else
							qdel(L)
							consume_owner() //see above comment
							return
					to_chat(itemUser, span_notice("Your arm suddenly grows back with the Rod of Asclepius still attached!"))
				else
					//Otherwise get rid of whatever else is in their hand and return the rod to said hand
					itemUser.put_in_hand(newRod, hand, forced = TRUE)
					to_chat(itemUser, span_notice("The Rod of Asclepius suddenly grows back out of your arm!"))
			//Because a servant of medicines stops at nothing to help others, lets keep them on their toes and give them an additional boost.
			if(itemUser.health < itemUser.maxHealth)
				new /obj/effect/temp_visual/heal(get_turf(itemUser), "#375637")
			itemUser.adjustBruteLoss(-1.5)
			itemUser.adjustFireLoss(-1.5)
			itemUser.adjustToxLoss(-1.5, forced = TRUE) //Because Slime People are people too
			itemUser.adjustOxyLoss(-1.5)
			itemUser.adjustStaminaLoss(-1.5)
			itemUser.adjustOrganLoss(ORGAN_SLOT_BRAIN, -1.5)
			itemUser.adjustCloneLoss(-0.5) //Becasue apparently clone damage is the bastion of all health

/datum/status_effect/hippocratic_oath/proc/consume_owner()
	owner.visible_message(span_notice("[owner]'s soul is absorbed into the rod, relieving the previous snake of its duty."))
	var/list/chems = list(/datum/reagent/medicine/sal_acid, /datum/reagent/medicine/c2/convermol, /datum/reagent/medicine/oxandrolone)
	var/mob/living/simple_animal/hostile/retaliate/snake/healSnake = new(owner.loc, pick(chems))
	healSnake.name = "Asclepius's Snake"
	healSnake.real_name = "Asclepius's Snake"
	healSnake.desc = "A mystical snake previously trapped upon the Rod of Asclepius, now freed of its burden. Unlike the average snake, its bites contain chemicals with minor healing properties."
	new /obj/effect/decal/cleanable/ash(owner.loc)
	new /obj/item/rod_of_asclepius(owner.loc)
	qdel(owner)


/datum/status_effect/good_music
	id = "Good Music"
	alert_type = null
	duration = 6 SECONDS
	tick_interval = 1 SECONDS
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/good_music/tick()
	if(owner.can_hear())
		owner.adjust_timed_status_effect(-4 SECONDS, /datum/status_effect/dizziness)
		owner.adjust_timed_status_effect(-4 SECONDS, /datum/status_effect/jitter)
		owner.adjust_timed_status_effect(-1 SECONDS, /datum/status_effect/confusion)
		SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "goodmusic", /datum/mood_event/goodmusic)

/atom/movable/screen/alert/status_effect/regenerative_core
	name = "Regenerative Core Tendrils"
	desc = "You can move faster than your broken body could normally handle!"
	icon_state = "regenerative_core"

/datum/status_effect/regenerative_core
	id = "Regenerative Core"
	duration = 1 MINUTES
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/regenerative_core

/datum/status_effect/regenerative_core/on_apply()
	ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, STATUS_EFFECT_TRAIT)
	owner.adjustBruteLoss(-25)
	owner.adjustFireLoss(-25)
	owner.remove_CC()
	owner.bodytemperature = owner.get_body_temp_normal()
	if(istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/humi = owner
		humi.set_coretemperature(humi.get_body_temp_normal())
	return TRUE

/datum/status_effect/regenerative_core/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, STATUS_EFFECT_TRAIT)

/datum/status_effect/crucible_soul
	id = "Blessing of Crucible Soul"
	status_type = STATUS_EFFECT_REFRESH
	duration = 15 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/crucible_soul
	var/turf/location

/datum/status_effect/crucible_soul/on_apply()
	to_chat(owner,span_notice("You phase through reality, nothing is out of bounds!"))
	owner.alpha = 180
	owner.pass_flags |= PASSCLOSEDTURF | PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSTABLE | PASSMOB | PASSDOORS | PASSVEHICLE
	location = get_turf(owner)
	return TRUE

/datum/status_effect/crucible_soul/on_remove()
	to_chat(owner,span_notice("You regain your physicality, returning you to your original location..."))
	owner.alpha = initial(owner.alpha)
	owner.pass_flags &= ~(PASSCLOSEDTURF | PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSTABLE | PASSMOB | PASSDOORS | PASSVEHICLE)
	owner.forceMove(location)
	location = null

/datum/status_effect/crucible_soul/get_examine_text()
	return span_notice("[owner.p_they(TRUE)] [owner.p_do()]n't seem to be all here.")

/datum/status_effect/duskndawn
	id = "Blessing of Dusk and Dawn"
	status_type = STATUS_EFFECT_REFRESH
	duration = 60 SECONDS
	alert_type =/atom/movable/screen/alert/status_effect/duskndawn

/datum/status_effect/duskndawn/on_apply()
	ADD_TRAIT(owner, TRAIT_XRAY_VISION, STATUS_EFFECT_TRAIT)
	owner.update_sight()
	return TRUE

/datum/status_effect/duskndawn/on_remove()
	REMOVE_TRAIT(owner, TRAIT_XRAY_VISION, STATUS_EFFECT_TRAIT)
	owner.update_sight()

/datum/status_effect/marshal
	id = "Blessing of Wounded Soldier"
	status_type = STATUS_EFFECT_REFRESH
	duration = 60 SECONDS
	tick_interval = 1 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/marshal

/datum/status_effect/marshal/on_apply()
	ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, STATUS_EFFECT_TRAIT)
	return TRUE

/datum/status_effect/marshal/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, STATUS_EFFECT_TRAIT)

/datum/status_effect/marshal/tick()
	if(!iscarbon(owner))
		return
	var/mob/living/carbon/carbie = owner

	for(var/BP in carbie.bodyparts)
		var/obj/item/bodypart/part = BP
		for(var/W in part.wounds)
			var/datum/wound/wound = W
			var/heal_amt = 0

			switch(wound.severity)
				if(WOUND_SEVERITY_MODERATE)
					heal_amt = 1
				if(WOUND_SEVERITY_SEVERE)
					heal_amt = 3
				if(WOUND_SEVERITY_CRITICAL)
					heal_amt = 6
			if(wound.wound_type == WOUND_BURN)
				carbie.adjustFireLoss(-heal_amt)
			else
				carbie.adjustBruteLoss(-heal_amt)
				carbie.blood_volume += carbie.blood_volume >= BLOOD_VOLUME_NORMAL ? 0 : heal_amt*3


/atom/movable/screen/alert/status_effect/crucible_soul
	name = "Blessing of Crucible Soul"
	desc = "You phased through reality. You are halfway to your final destination..."
	icon_state = "crucible"

/atom/movable/screen/alert/status_effect/duskndawn
	name = "Blessing of Dusk and Dawn"
	desc = "Many things hide beyond the horizon. With Owl's help I managed to slip past Sun's guard and Moon's watch."
	icon_state = "duskndawn"

/atom/movable/screen/alert/status_effect/marshal
	name = "Blessing of Wounded Soldier"
	desc = "Some people seek power through redemption. One thing many people don't know is that battle \
		is the ultimate redemption, and wounds let you bask in eternal glory."
	icon_state = "wounded_soldier"

/// Summons multiple foating knives around the owner.
/// Each knife will block an attack straight up.
/datum/status_effect/protective_blades
	id = "Silver Knives"
	alert_type = null
	status_type = STATUS_EFFECT_MULTIPLE
	tick_interval = -1
	/// The number of blades we summon up to.
	var/max_num_blades = 4
	/// The radius of the blade's orbit.
	var/blade_orbit_radius = 20
	/// The time between spawning blades.
	var/time_between_initial_blades = 0.25 SECONDS
	/// If TRUE, we self-delete our status effect after all the blades are deleted.
	var/delete_on_blades_gone = TRUE
	/// A list of blade effects orbiting / protecting our owner
	var/list/obj/effect/floating_blade/blades = list()

/datum/status_effect/protective_blades/on_creation(
	mob/living/new_owner,
	new_duration = -1,
	max_num_blades = 4,
	blade_orbit_radius = 20,
	time_between_initial_blades = 0.25 SECONDS,
)

	src.duration = new_duration
	src.max_num_blades = max_num_blades
	src.blade_orbit_radius = blade_orbit_radius
	src.time_between_initial_blades = time_between_initial_blades
	return ..()

/datum/status_effect/protective_blades/on_apply()
	RegisterSignal(owner, COMSIG_HUMAN_CHECK_SHIELDS, .proc/on_shield_reaction)
	for(var/blade_num in 1 to max_num_blades)
		var/time_until_created = (blade_num - 1) * time_between_initial_blades
		if(time_until_created <= 0)
			create_blade()
		else
			addtimer(CALLBACK(src, .proc/create_blade), time_until_created)

	return TRUE

/datum/status_effect/protective_blades/on_remove()
	UnregisterSignal(owner, COMSIG_HUMAN_CHECK_SHIELDS)
	QDEL_LIST(blades)

	return ..()

/// Creates a floating blade, adds it to our blade list, and makes it orbit our owner.
/datum/status_effect/protective_blades/proc/create_blade()
	if(QDELETED(src) || QDELETED(owner))
		return

	var/obj/effect/floating_blade/blade = new(get_turf(owner))
	blades += blade
	blade.orbit(owner, blade_orbit_radius)
	RegisterSignal(blade, COMSIG_PARENT_QDELETING, .proc/remove_blade)
	playsound(get_turf(owner), 'sound/items/unsheath.ogg', 33, TRUE)

/// Signal proc for [COMSIG_HUMAN_CHECK_SHIELDS].
/// If we have a blade in our list, consume it and block the incoming attack (shield it)
/datum/status_effect/protective_blades/proc/on_shield_reaction(
	mob/living/carbon/human/source,
	atom/movable/hitby,
	damage = 0,
	attack_text = "the attack",
	attack_type = MELEE_ATTACK,
	armour_penetration = 0,
)
	SIGNAL_HANDLER

	if(!length(blades))
		return

	if(HAS_TRAIT(source, TRAIT_BEING_BLADE_SHIELDED))
		return

	ADD_TRAIT(source, TRAIT_BEING_BLADE_SHIELDED, type)

	var/obj/effect/floating_blade/to_remove = blades[1]

	playsound(get_turf(source), 'sound/weapons/parry.ogg', 100, TRUE)
	source.visible_message(
		span_warning("[to_remove] orbiting [source] snaps in front of [attack_text], blocking it before vanishing!"),
		span_warning("[to_remove] orbiting you snaps in front of [attack_text], blocking it before vanishing!"),
		span_hear("You hear a clink."),
	)

	qdel(to_remove)

	addtimer(TRAIT_CALLBACK_REMOVE(source, TRAIT_BEING_BLADE_SHIELDED, type), 1)

	return SHIELD_BLOCK

/// Remove deleted blades from our blades list properly.
/datum/status_effect/protective_blades/proc/remove_blade(obj/effect/floating_blade/to_remove)
	SIGNAL_HANDLER

	if(!(to_remove in blades))
		CRASH("[type] called remove_blade() with a blade that was not in its blades list.")

	to_remove.stop_orbit(owner.orbiters)
	blades -= to_remove

	if(!length(blades) && !QDELETED(src) && delete_on_blades_gone)
		qdel(src)

	return TRUE

/// A subtype that doesn't self-delete / disappear when all blades are gone
/// It instead regenerates over time back to the max after blades are consumed
/datum/status_effect/protective_blades/recharging
	delete_on_blades_gone = FALSE
	/// The amount of time it takes for a blade to recharge
	var/blade_recharge_time = 1 MINUTES

/datum/status_effect/protective_blades/recharging/on_creation(
	mob/living/new_owner,
	new_duration = -1,
	max_num_blades = 4,
	blade_orbit_radius = 20,
	time_between_initial_blades = 0.25 SECONDS,
	blade_recharge_time = 1 MINUTES,
)

	src.blade_recharge_time = blade_recharge_time
	return ..()

/datum/status_effect/protective_blades/recharging/remove_blade(obj/effect/floating_blade/to_remove)
	. = ..()
	if(!.)
		return

	addtimer(CALLBACK(src, .proc/create_blade), blade_recharge_time)

/datum/status_effect/lightningorb
	id = "Lightning Orb"
	duration = 30 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/lightningorb

/datum/status_effect/lightningorb/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/yellow_orb)
	to_chat(owner, span_notice("You feel fast!"))

/datum/status_effect/lightningorb/on_remove()
	. = ..()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/yellow_orb)
	to_chat(owner, span_notice("You slow down."))

/atom/movable/screen/alert/status_effect/lightningorb
	name = "Lightning Orb"
	desc = "The speed surges through you!"
	icon_state = "lightningorb"

/datum/status_effect/mayhem
	id = "Mayhem"
	duration = 2 MINUTES
	/// The chainsaw spawned by the status effect
	var/obj/item/chainsaw/doomslayer/chainsaw

/datum/status_effect/mayhem/on_apply()
	. = ..()
	to_chat(owner, "<span class='reallybig redtext'>RIP AND TEAR</span>")
	SEND_SOUND(owner, sound('sound/hallucinations/veryfar_noise.ogg'))
	new /datum/hallucination/delusion(owner, forced = TRUE, force_kind = "demon", duration = duration, skip_nearby = FALSE)
	chainsaw = new(get_turf(owner))
	owner.log_message("entered a blood frenzy", LOG_ATTACK)
	ADD_TRAIT(chainsaw, TRAIT_NODROP, CHAINSAW_FRENZY_TRAIT)
	owner.drop_all_held_items()
	owner.put_in_hands(chainsaw, forced = TRUE)
	chainsaw.attack_self(owner)
	owner.reagents.add_reagent(/datum/reagent/medicine/adminordrazine,25)
	to_chat(owner, span_warning("KILL, KILL, KILL! YOU HAVE NO ALLIES ANYMORE, KILL THEM ALL!"))
	var/datum/client_colour/colour = owner.add_client_colour(/datum/client_colour/bloodlust)
	QDEL_IN(colour, 1.1 SECONDS)

/datum/status_effect/mayhem/on_remove()
	. = ..()
	to_chat(owner, span_notice("Your bloodlust seeps back into the bog of your subconscious and you regain self control."))
	owner.log_message("exited a blood frenzy", LOG_ATTACK)
	QDEL_NULL(chainsaw)

/datum/status_effect/speed_boost
	id = "speed_boost"
	duration = 2 SECONDS
	status_type = STATUS_EFFECT_REPLACE

/datum/status_effect/speed_boost/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/speed_boost/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_speed_boost, update = TRUE)
	return ..()

/datum/status_effect/speed_boost/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_speed_boost, update = TRUE)

/datum/movespeed_modifier/status_speed_boost
	multiplicative_slowdown = -1

///this buff provides a max health buff and a heal.
/datum/status_effect/limited_buff/health_buff
	id = "health_buff"
	alert_type = null
	///This var stores the mobs max health when the buff was first applied, and determines the size of future buffs.database.database.
	var/historic_max_health
	///This var determines how large the health buff will be. health_buff_modifier * historic_max_health * stacks
	var/health_buff_modifier = 0.1 //translate to a 10% buff over historic health per stack
	///This modifier multiplies the healing by the effect.
	var/healing_modifier = 2
	///If the mob has a low max health, we instead use this flat value to increase max health and calculate any heal.
	var/fragile_mob_health_buff = 10

/datum/status_effect/limited_buff/health_buff/on_creation(mob/living/new_owner)
	historic_max_health = new_owner.maxHealth
	. = ..()

/datum/status_effect/limited_buff/health_buff/on_apply()
	. = ..()
	var/health_increase = round(max(fragile_mob_health_buff, historic_max_health * health_buff_modifier))
	owner.maxHealth += health_increase
	owner.balloon_alert_to_viewers("health buffed")
	to_chat(owner, span_nicegreen("You feel healthy, like if your body is little stronger than it was a moment ago."))

	if(isanimal(owner))	//dumb animals have their own proc for healing.
		var/mob/living/simple_animal/healthy_animal = owner
		healthy_animal.adjustHealth(-(health_increase * healing_modifier))
	else
		owner.adjustBruteLoss(-(health_increase * healing_modifier))

/datum/status_effect/limited_buff/health_buff/maxed_out()
	. = ..()
	to_chat(owner, span_warning("You don't feel any healthier."))

/datum/status_effect/slime
	id = "slime_goo"
	status_type = STATUS_EFFECT_REPLACE
	duration = 1 MINUTES
	var/mutable_appearance/goo_overlay
	var/effect_icon_state

/datum/status_effect/slime/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_COMPONENT_CLEAN_ACT, .proc/slime_washed)

	goo_overlay = mutable_appearance('icons/effects/64x64.dmi', effect_icon_state)
	goo_overlay.pixel_x = -16
	goo_overlay.pixel_y = -16
	owner.add_overlay(goo_overlay)

/datum/status_effect/slime/on_remove()
	. = ..()
	owner.cut_overlay(goo_overlay)
	UnregisterSignal(owner, COMSIG_COMPONENT_CLEAN_ACT)

/datum/status_effect/slime/proc/slime_washed()
	SIGNAL_HANDLER
	qdel(src)
	return COMPONENT_CLEANED

/atom/movable/screen/alert/status_effect/orange_slime
	name = "Orange Slime"
	desc = "You are enveloped in a layer of fireproof orange slime!"
	icon_state = "orange_slime"

/datum/status_effect/slime/orange
	alert_type = /atom/movable/screen/alert/status_effect/orange_slime
	effect_icon_state = "orange_slime"

/datum/status_effect/slime/orange/on_apply()
	. = ..()
	to_chat(owner, span_notice("You are covered in a fine layer of fireproof orange goo!"))
	ADD_TRAIT(owner, TRAIT_NOFIRE, XENOBIO_TRAIT)
	ADD_TRAIT(owner, TRAIT_RESISTHEAT, XENOBIO_TRAIT)

/datum/status_effect/slime/orange/on_remove()
	. = ..()
	REMOVE_TRAIT(owner, TRAIT_NOFIRE, XENOBIO_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_RESISTHEAT, XENOBIO_TRAIT)

/datum/status_effect/slime/orange/get_examine_text()
	return span_notice("[owner.p_they(TRUE)] are covered in a layer of fireproof orange slime.")

/atom/movable/screen/alert/status_effect/dark_blue_slime
	name = "Dark Blue Slime"
	desc = "You are enveloped in a layer of stasis-inducing dark blue slime!"
	icon_state = "dark_blue_slime"

/datum/status_effect/slime/dark_blue
	alert_type = /atom/movable/screen/alert/status_effect/dark_blue_slime
	effect_icon_state = "dark_blue_slime"

/datum/status_effect/slime/dark_blue/on_apply()
	. = ..()
	to_chat(owner, span_notice("You are covered in a fine layer of stasis-inducing dark blue slime!"))
	owner.apply_status_effect(/datum/status_effect/grouped/stasis, STASIS_SLIME_EFFECT)
	ADD_TRAIT(owner, TRAIT_TUMOR_SUPPRESSED, XENOBIO_TRAIT)
	ADD_TRAIT(owner, TRAIT_RESISTLOWPRESSURE, XENOBIO_TRAIT) //Good way to survive if you/your friend get stuck in space without a way to get back in and have to wait for help
	ADD_TRAIT(owner, TRAIT_NOBREATH, XENOBIO_TRAIT)
	owner.extinguish_mob()

/datum/status_effect/slime/dark_blue/on_remove()
	. = ..()
	owner.remove_status_effect(/datum/status_effect/grouped/stasis, STASIS_SLIME_EFFECT)
	REMOVE_TRAIT(owner, TRAIT_TUMOR_SUPPRESSED, XENOBIO_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_RESISTLOWPRESSURE, XENOBIO_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_NOBREATH, XENOBIO_TRAIT)

/datum/status_effect/slime/dark_blue/get_examine_text()
	return span_notice("[owner.p_they(TRUE)] are covered in a layer of stasis-inducing dark blue slime.")

/atom/movable/screen/alert/status_effect/red_slime
	name = "Red Slime"
	desc = "You are enveloped in a layer of shiny red slime!"
	icon_state = "red_slime"

/datum/status_effect/slime/red
	alert_type = /atom/movable/screen/alert/status_effect/red_slime
	effect_icon_state = "red_slime"
	duration = 3 MINUTES

/datum/status_effect/slime/red/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, XENOBIO_TRAIT)
	ADD_TRAIT(owner, TRAIT_HARDLY_WOUNDED, XENOBIO_TRAIT)
	ADD_TRAIT(owner, TRAIT_NODISMEMBER, XENOBIO_TRAIT)
	owner.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/equipment_speedmod)

/datum/status_effect/slime/red/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, XENOBIO_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_HARDLY_WOUNDED, XENOBIO_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_NODISMEMBER, XENOBIO_TRAIT)
	owner.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/equipment_speedmod)

/datum/status_effect/slime/red/get_examine_text()
	return span_notice("[owner.p_they(TRUE)] are covered in a layer of shiny red slime.")

/atom/movable/screen/alert/status_effect/oil_slime
	name = "Oil Slime"
	desc = "Your feet are enveloped in a layer of flammable oily slime!"
	icon_state = "oil_slime"

/datum/status_effect/slime/oil
	alert_type = /atom/movable/screen/alert/status_effect/oil_slime
	effect_icon_state = "oil_slime_feet"
	tick_interval = 1

/datum/status_effect/slime/oil/tick(delta_time, times_fired)
	if(owner.fire_stacks >= 3)
		return
	owner.adjust_fire_stacks(3 - owner.fire_stacks, /datum/status_effect/fire_handler/fire_stacks/oil)

/datum/status_effect/slime/oil/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, .proc/on_moved)
	RegisterSignal(owner, COMSIG_LIVING_IGNITED, .proc/slime_washed)

/datum/status_effect/slime/oil/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_IGNITED))

/datum/status_effect/slime/oil/proc/on_moved(datum/source, old_loc)
	SIGNAL_HANDLER
	if(!isturf(owner.loc)) //No locker abuse
		return

	new /obj/effect/decal/cleanable/oil_pool(owner.loc)

/datum/status_effect/slime/oil/get_examine_text()
	return span_notice("[owner.p_their(TRUE)] feet are covered in a layer of flammable oily slime.")

/atom/movable/screen/alert/status_effect/adamantine_slime
	name = "Adamantine Slime"
	desc = "You are enveloped in a layer of thick and heavy adamantine slime!"
	icon_state = "red_slime"

/datum/status_effect/slime/adamantine
	alert_type = /atom/movable/screen/alert/status_effect/adamantine_slime
	effect_icon_state = "adamantine_slime"
	duration = 3 MINUTES

/datum/status_effect/slime/adamantine/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/adamantine_slime)
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/human_owner = owner
	human_owner.physiology.damage_resistance += 25

/datum/status_effect/slime/adamantine/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/adamantine_slime)
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/human_owner = owner
	human_owner.physiology.damage_resistance -= 25

/datum/status_effect/slime/adamantine/get_examine_text()
	return span_notice("[owner.p_they(TRUE)] are covered in a thick layer of heavy adamantine slime.")

/atom/movable/screen/alert/status_effect/golden_eyes
	name = "Golden Gaze"
	desc = "You are using golden slime's power to gaze through someone else's eyes! Click on this alert to toggle this effect on and off."
	icon_state = "golden_eyes"

/atom/movable/screen/alert/status_effect/golden_eyes/Click(location, control, params)
	. = ..()
	if(!.)
		return

	var/datum/status_effect/golden_eyes/golden_eyes = attached_effect
	if(golden_eyes.gazing)
		golden_eyes.stop_gazing()
	else
		golden_eyes.start_gazing()

/datum/status_effect/golden_eyes
	id = "golden_eyes"
	duration = 3 MINUTES
	tick_interval = 1
	alert_type = /atom/movable/screen/alert/status_effect/golden_eyes
	status_type = STATUS_EFFECT_REPLACE
	var/original_eye_color_left
	var/original_eye_color_right
	var/mob/living/following
	var/gazing = TRUE
	var/peers = 0

/datum/status_effect/golden_eyes/on_creation(mob/living/new_owner, mob/living/to_follow)
	if(!ishuman(new_owner))
		CRASH("[type] status effect added to non-human owner: [new_owner ? new_owner.type : "null owner"]")

	if(!to_follow || !istype(to_follow))
		CRASH("[type] status effect added with to_follow being non-living: [to_follow ? to_follow.type : "null to_follow"]")

	following = to_follow
	return ..()

/datum/status_effect/golden_eyes/on_apply()
	. = ..()
	var/mob/living/carbon/human/human_owner = owner
	original_eye_color_left = human_owner.eye_color_left
	original_eye_color_right = human_owner.eye_color_right
	human_owner.eye_color_left = "#EEAA01"
	human_owner.eye_color_right = "#EEAA01"
	human_owner.dna.update_ui_block(DNA_EYE_COLOR_LEFT_BLOCK)
	human_owner.dna.update_ui_block(DNA_EYE_COLOR_RIGHT_BLOCK)
	human_owner.update_body()
	start_gazing()

/datum/status_effect/golden_eyes/on_remove()
	if(!ishuman(owner))
		stack_trace("[type] status effect being removed from non-human owner: [owner ? owner.type : "null owner"]")

	var/mob/living/carbon/human/human_owner = owner
	human_owner.eye_color_left = original_eye_color_left
	human_owner.eye_color_right = original_eye_color_right
	human_owner.dna.update_ui_block(DNA_EYE_COLOR_LEFT_BLOCK)
	human_owner.dna.update_ui_block(DNA_EYE_COLOR_RIGHT_BLOCK)
	human_owner.update_body()
	stop_gazing()

/datum/status_effect/golden_eyes/proc/stop_gazing()
	owner.clear_fullscreen("golden_eyes")
	owner.cure_blind("golden_eyes")
	owner.cure_nearsighted("golden_eyes")
	owner.set_blurriness(min(20, owner.eye_blurry)) //No powergaming to get rid of blurry/blind
	owner.set_blindness(min(20, owner.eye_blind))
	owner.reset_perspective()
	gazing = FALSE

/datum/status_effect/golden_eyes/proc/start_gazing()
	owner.reset_perspective(following)
	owner.overlay_fullscreen("golden_eyes", /atom/movable/screen/fullscreen/golden_eyes, 0)
	gazing = TRUE
	peers += 1
	if(prob(25 * peers)) /// Don't overuse!
		to_chat(following, span_warning("Your head pounds as you feel something otherworldly connect to your mind..."))

/datum/status_effect/golden_eyes/tick(delta_time, times_fired)
	. = ..()
	if(!gazing)
		return

	if(HAS_TRAIT(following, TRAIT_BLIND) && !HAS_TRAIT_FROM(owner, TRAIT_BLIND, "golden_eyes"))
		owner.become_blind("golden_eyes")
	else if(!HAS_TRAIT(following, TRAIT_BLIND) && HAS_TRAIT_FROM(owner, TRAIT_BLIND, "golden_eyes"))
		owner.cure_blind("golden_eyes")

	if(HAS_TRAIT(following, TRAIT_NEARSIGHT) && !HAS_TRAIT_FROM(owner, TRAIT_NEARSIGHT, "golden_eyes"))
		owner.become_nearsighted("golden_eyes")
	else if(!HAS_TRAIT(following, TRAIT_NEARSIGHT) && HAS_TRAIT_FROM(owner, TRAIT_NEARSIGHT, "golden_eyes"))
		owner.cure_nearsighted("golden_eyes")

	if(owner.eye_blurry != following.eye_blurry)
		owner.set_blurriness(following.eye_blurry)
	if(owner.eye_blind != following.eye_blind)
		owner.set_blindness(following.eye_blind)

/datum/status_effect/golden_eyes/get_examine_text()
	if(!gazing)
		return span_notice("[owner.p_their(TRUE)] eyes are of unnatural bright golden color")
	return span_notice("[owner.p_their(TRUE)] eyes are of unnatural bright golden color and it seems like [owner.p_their()] mind is somewhere else...")

/atom/movable/screen/alert/status_effect/pyrite_morpher
	name = "Pyrite Morpher"
	desc = "Your body is being morphed by a pyrite extract!"
	icon_state = "pyrite_morpher"

/datum/status_effect/slime/pyrite
	duration = 5 MINUTES
	tick_interval = 1
	alert_type = /atom/movable/screen/alert/status_effect/pyrite_morpher
	effect_icon_state = "pyrite_slime"
	var/datum/icon_snapshot/impersonating
	var/masquerade_on = FALSE
	var/wibbling = TRUE
	var/regain_timer

/datum/status_effect/slime/pyrite/on_creation(mob/living/new_owner, mob/living/carbon/human/to_impersonate)
	if(!ishuman(new_owner))
		CRASH("[type] status effect added to non-human owner: [new_owner ? new_owner.type : "null owner"]")

	if(!iscarbon(to_impersonate))
		CRASH("[type] status effect added with non-human to_impersonate: [to_impersonate ? to_impersonate.type : "null to_impersonate"]")

	impersonating = new()
	impersonating.name = to_impersonate.name
	impersonating.icon = to_impersonate.icon
	impersonating.icon_state = to_impersonate.icon_state
	impersonating.overlays = to_impersonate.get_overlays_copy(list(HANDS_LAYER))
	return ..()

/datum/status_effect/slime/pyrite/on_apply()
	. = ..()
	RegisterSignal(owner, list(COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_HULK_ATTACK, COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW, COMSIG_ATOM_HITBY, COMSIG_ATOM_BULLET_ACT), .proc/drop_masquarade)
	apply_wibbly_filters(owner)
	playsound(owner, 'sound/effects/attackblob.ogg', 50, TRUE)
	regain_timer = addtimer(CALLBACK(src, .proc/masquarade), 10 SECONDS, TIMER_STOPPABLE)

/datum/status_effect/slime/pyrite/on_remove()
	UnregisterSignal(owner, list(COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_HULK_ATTACK, COMSIG_ATOM_ATTACK_HAND,
									  COMSIG_ATOM_ATTACK_PAW, COMSIG_ATOM_HITBY, COMSIG_ATOM_BULLET_ACT))
	drop_masquarade(regain = FALSE)

/datum/status_effect/slime/pyrite/proc/drop_masquarade(regain = TRUE)
	deltimer(regain_timer)
	if(regain)
		regain_timer = addtimer(CALLBACK(src, .proc/start_regaining), 5 SECONDS, TIMER_STOPPABLE)

	if(wibbling || masquerade_on)
		playsound(owner, 'sound/effects/bamf.ogg', 100, TRUE)

	wibbling = FALSE
	remove_wibbly_filters(owner)

	if(!masquerade_on)
		return

	masquerade_on = FALSE
	var/mob/living/carbon/human/human_owner = owner
	var/name_buffer = human_owner.name_override
	human_owner.name_override = null
	human_owner.cut_overlays()
	human_owner.regenerate_icons()
	human_owner.visible_message(span_danger("[name_buffer]'s flesh melts, revealing [human_owner.get_visible_name()]!"))
	human_owner.add_overlay(goo_overlay)

/datum/status_effect/slime/pyrite/proc/start_regaining()
	apply_wibbly_filters(owner)
	wibbling = TRUE
	playsound(owner, 'sound/effects/attackblob.ogg', 50, TRUE)
	regain_timer = addtimer(CALLBACK(src, .proc/masquarade), 5 SECONDS, TIMER_STOPPABLE)

/datum/status_effect/slime/pyrite/proc/masquarade()
	var/mob/living/carbon/human/human_owner = owner
	masquerade_on = TRUE
	wibbling = FALSE
	remove_wibbly_filters(human_owner)
	var/original_name = human_owner.name
	human_owner.name_override = impersonating.name
	human_owner.icon = impersonating.icon
	human_owner.icon_state = impersonating.icon_state
	human_owner.cut_overlays()
	human_owner.add_overlay(impersonating.overlays)
	human_owner.update_inv_hands()
	human_owner.visible_message(span_danger("[original_name]'s flesh melts, reforming into [human_owner.name_override]!"))
	playsound(owner, 'sound/effects/bamf.ogg', 100, TRUE)

/datum/status_effect/slime/pyrite/get_examine_text()
	if(!masquerade_on)
		return span_warning("[owner.p_they(TRUE)] are covered in a layer of pyrite slime!")

/atom/movable/screen/alert/status_effect/rainbow_shield
	name = "Rainbow Shield"
	desc = "You are protected by power of a rainbow slime extract!"
	icon_state = "rainbow_slime"

/datum/status_effect/rainbow_shield
	id = "rainbow_slime"
	duration = 15 SECONDS
	tick_interval = 1
	alert_type = /atom/movable/screen/alert/status_effect/rainbow_shield
	status_type = STATUS_EFFECT_REPLACE
	var/current_hue = 0 //+8 per sec
	var/orig_mutcolor
	var/list/original_limb_color = list()
	var/orig_facial
	var/orig_hair

/datum/status_effect/rainbow_shield/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_NEVER_WOUNDED, type)
	ADD_TRAIT(owner, TRAIT_NODISMEMBER, type)
	ADD_TRAIT(owner, TRAIT_NOLIMBDISABLE, type) //Even the crippled will walk!
	ADD_TRAIT(owner, TRAIT_NODISMEMBER, type)
	ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, type)
	ADD_TRAIT(owner, TRAIT_PACIFISM, type)

	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/human_owner = owner

	human_owner.physiology.damage_resistance += 90
	human_owner.physiology.bleed_mod *= 0.1
	human_owner.log_message("gained rainbow shield stun immunity", LOG_ATTACK)
	human_owner.add_stun_absorption("rainbow_shield", INFINITY, 5)

	orig_facial = human_owner.facial_hair_color
	orig_hair = human_owner.hair_color

	if(human_owner.dna && human_owner.dna.species)
		if(MUTCOLORS in human_owner.dna.species)
			orig_mutcolor = human_owner.dna.features["mcolor"]

	for(var/obj/item/bodypart/limb in human_owner.bodyparts)
		if(!limb.mutation_color)
			original_limb_color[WEAKREF(limb)] = FALSE
			continue

		original_limb_color[WEAKREF(limb)] = limb.mutation_color

	if(prob(5) && SSevents.holidays[APRIL_FOOLS])
		human_owner.say(";WOMEN FEAR ME", spans = list(SPAN_YELL, "colossus"), ignore_spam = TRUE, forced = type)
		addtimer(CALLBACK(human_owner, /atom/movable.proc/say, ";FISH FEAR ME", null, list(SPAN_YELL, "colossus"), TRUE, null, TRUE, type), 3 SECONDS)
		addtimer(CALLBACK(human_owner, /atom/movable.proc/say, ";MEN TURN THEIR EYES AWAY FROM ME", null, list(SPAN_YELL, "colossus"), TRUE, null, TRUE, type), 6 SECONDS)
		addtimer(CALLBACK(human_owner, /atom/movable.proc/say, ";AS I WALK NO BEAST DARES TO MAKE A SOUND IN MY PRESENCE", null, list(SPAN_YELL, "colossus"), TRUE, null, TRUE, type), 9 SECONDS)
		addtimer(CALLBACK(human_owner, /atom/movable.proc/say, ";I AM ALONE ON THIS BARREN EARTH", null, list(SPAN_YELL, "colossus"), TRUE, null, TRUE, type), 12 SECONDS)
		addtimer(CALLBACK(human_owner, /atom/movable.proc/say, ";I AM THY GOD [human_owner.gender == MALE ? "HIM" : (human_owner.gender == FEMALE ? "HER" : "IT")]SELF", null, list(SPAN_YELL, "colossus"), TRUE, null, TRUE, type), 15 SECONDS)

/datum/status_effect/rainbow_shield/on_remove()
	. = ..()
	REMOVE_TRAIT(owner, TRAIT_NEVER_WOUNDED, type)
	REMOVE_TRAIT(owner, TRAIT_NODISMEMBER, type)
	REMOVE_TRAIT(owner, TRAIT_NOLIMBDISABLE, type)
	REMOVE_TRAIT(owner, TRAIT_NODISMEMBER, type)
	REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, type)
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, type)

	if(!ishuman(owner))
		owner.remove_atom_colour(ADMIN_COLOUR_PRIORITY)
		return

	var/mob/living/carbon/human/human_owner = owner

	human_owner.physiology.damage_resistance -= 90
	human_owner.physiology.bleed_mod *= 10
	human_owner.log_message("lost rainbow shield stun immunity", LOG_ATTACK)
	if(islist(human_owner.stun_absorption) && human_owner.stun_absorption["blooddrunk"])
		human_owner.stun_absorption -= "rainbow_shield"

	human_owner.facial_hair_color = orig_facial
	human_owner.hair_color = orig_hair

	if(orig_mutcolor)
		human_owner.dna.features["mcolor"] = orig_mutcolor
		if(isluminescent(owner))
			var/datum/species/jelly/luminescent/species = human_owner.dna.species
			species.glow.set_light_color(orig_mutcolor)

	for(var/datum/weakref/limb_weakref in original_limb_color)
		var/obj/item/bodypart/our_limb = limb_weakref.resolve()
		if(!our_limb)
			continue

		if(original_limb_color[limb_weakref] == FALSE)
			our_limb.mutation_color = null
			continue

		our_limb.mutation_color = original_limb_color[limb_weakref]

	human_owner.update_body(TRUE)

/datum/status_effect/rainbow_shield/tick(delta_time, times_fired)
	. = ..()
	current_hue = (current_hue + 8) % 360

	var/light_shift = 60 + abs(current_hue % 120 - 60) / 4
	var/new_color = rgb(current_hue, 100, light_shift, space = COLORSPACE_HSL)

	if(!ishuman(owner)) //In case of admemery
		owner.remove_atom_colour(ADMIN_COLOUR_PRIORITY)
		owner.add_atom_colour(new_color, ADMIN_COLOUR_PRIORITY)
		return

	var/mob/living/carbon/human/human_owner = owner
	if(isjellyperson(human_owner))
		var/datum/species/jelly/jelly_species = human_owner.dna.species
		if(jelly_species.rainbow_active) //Already rad as fuck
			return

	human_owner.facial_hair_color = new_color
	human_owner.hair_color = new_color

	if(orig_mutcolor)
		human_owner.dna.features["mcolor"] = new_color
		if(isluminescent(owner))
			var/datum/species/jelly/luminescent/species = human_owner.dna.species
			species.glow.set_light_color(new_color)

	var/list/our_parts = human_owner.bodyparts.Copy()
	for(var/datum/weakref/limb_weakref in original_limb_color)
		var/obj/item/bodypart/our_limb = limb_weakref.resolve()
		if(!our_limb)
			original_limb_color -= limb_weakref
			continue

		our_parts -= our_limb
		our_limb.mutation_color = new_color

	for(var/obj/item/bodypart/limb in our_parts)
		if(!limb.mutation_color)
			original_limb_color[WEAKREF(limb)] = FALSE
			continue

		original_limb_color[WEAKREF(limb)] = limb.mutation_color
		limb.mutation_color = new_color

	human_owner.update_body(TRUE)

/atom/movable/screen/alert/status_effect/rainbow_dash
	name = "Rainbow Dash"
	desc = "You are filled with power of a rainbow slime extract!"
	icon_state = "rainbow_slime"

/atom/movable/screen/alert/status_effect/rainbow_dash/New()
	. = ..()
	if(prob(1))
		desc = "You can be a magical pony too!" //Bruh

/datum/status_effect/rainbow_dash
	id = "rainbow_slime"
	duration = 45 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/rainbow_dash
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	var/current_hue = 0 //+8 per sec
	var/orig_facial
	var/orig_hair

/datum/status_effect/rainbow_dash/on_apply()
	. = ..()
	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/human_owner = owner

	human_owner.add_movespeed_modifier(/datum/movespeed_modifier/rainbow_dash)

	orig_facial = human_owner.facial_hair_color
	orig_hair = human_owner.hair_color
	human_owner.update_body(TRUE)
	RegisterSignal(human_owner, COMSIG_MOVABLE_MOVED, .proc/handle_move)

/datum/status_effect/rainbow_dash/on_remove()
	. = ..()

	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/human_owner = owner

	human_owner.remove_movespeed_modifier(/datum/movespeed_modifier/rainbow_dash)

	human_owner.facial_hair_color = orig_facial
	human_owner.hair_color = orig_hair
	human_owner.update_body(TRUE)
	UnregisterSignal(human_owner, COMSIG_MOVABLE_MOVED)

/datum/status_effect/rainbow_dash/tick(delta_time, times_fired)
	. = ..()
	current_hue = (current_hue + 8) % 360

	var/light_shift = 60 + abs(current_hue % 120 - 60) / 4
	var/new_color = rgb(current_hue, 100, light_shift, space = COLORSPACE_HSL)

	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/human_owner = owner
	if(isjellyperson(human_owner))
		var/datum/species/jelly/jelly_species = human_owner.dna.species
		if(jelly_species.rainbow_active) //Already rad as fuck
			return

	human_owner.facial_hair_color = new_color
	human_owner.hair_color = new_color
	human_owner.update_body(TRUE)

/datum/status_effect/rainbow_dash/proc/handle_move(datum/source, atom/old_loc, move_dir, forced = FALSE)
	SIGNAL_HANDLER
	var/turf/owner_turf = get_turf(owner)
	if(!isturf(old_loc) || !owner_turf.Adjacent(old_loc))
		return

	var/light_shift = 60 + abs(current_hue % 120 - 60) / 4
	var/paint_color = rgb(current_hue, 100, light_shift, space = COLORSPACE_HSL)
	old_loc.AddComponent(/datum/component/rainbow_trail, paint_color, owner_turf)

/atom/movable/screen/alert/status_effect/silver_control
	name = "Silver Blorbie Control"
	desc = "You are currently controlling a slime blorbie. Click this alert to abandon it."
	icon_state = "silver_control"

/atom/movable/screen/alert/status_effect/silver_control/Click(location, control, params)
	. = ..()
	if(!.)
		return

	if(tgui_alert(owner, "Are you sure you want to abandon control over your silver blorbie?", "Silver Blorbie Control", list("Yes", "No")) != "Yes")
		return

	qdel(attached_effect)

/datum/status_effect/silver_control
	id = "silver_control"
	duration = 5 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/silver_control
	status_type = STATUS_EFFECT_REFRESH
	var/mob/living/simple_animal/hostile/slime_blorbie/player/blorbie
	var/datum/mind/owner_mind

/datum/status_effect/silver_control/on_apply()
	. = ..()
	if(!owner.mind)
		qdel(src)
		return

	blorbie = new(get_turf(owner))
	RegisterSignal(blorbie, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), .proc/blorbie_death)
	owner_mind = owner.mind
	owner_mind.transfer_to(blorbie)
	blorbie.copy_languages(owner, LANGUAGE_MIND)
	blorbie.faction = owner.faction.Copy()
	ADD_TRAIT(owner, TRAIT_NO_MINDLESS_MSG, XENOBIO_TRAIT)

	var/atom/movable/screen/alert/status_effect/blorbie_alert = blorbie.throw_alert(id, alert_type)
	blorbie_alert.attached_effect = src

/datum/status_effect/silver_control/on_remove()
	. = ..()
	owner_mind.transfer_to(owner)
	REMOVE_TRAIT(owner, TRAIT_NO_MINDLESS_MSG, XENOBIO_TRAIT)
	if(blorbie && !QDELETED(blorbie))
		UnregisterSignal(blorbie, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		blorbie.death(FALSE)

/datum/status_effect/silver_control/proc/blorbie_death(mob/living/dead_blorbie)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/silver_control/get_examine_text()
	return span_deadsay("[owner.p_they(TRUE)] look like [owner.p_their()] mind is somewhere else...")
