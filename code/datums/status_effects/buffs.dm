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
		owner.apply_status_effect(STATUS_EFFECT_HISWRATH)
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

/datum/status_effect/acid_sack //Lower damage protection but normal hits reset the timer so if you want you can trade mark detonation damage to protection.
	id = "acid_sack"
	duration = 20
	tick_interval = 0
	alert_type = /atom/movable/screen/alert/status_effect/acid_sack

/atom/movable/screen/alert/status_effect/acid_sack
	name = "Acidic Blood"
	desc = "A bunch of acidic blood was injected into your veins, making you stronger!"
	icon_state = "acid_sack"

/datum/status_effect/acid_sack/on_apply()
	. = ..()
	if(.)
		ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, BLOODDRUNK_TRAIT) //Let's just use blood drunk trait not to create too many of those
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.physiology.brute_mod *= 0.5
			H.physiology.burn_mod *= 0.5
			H.physiology.tox_mod *= 0.5
			H.physiology.oxy_mod *= 0.5
			H.physiology.clone_mod *= 0.5
			H.physiology.stamina_mod *= 0.5
		owner.log_message("gained acid sack stun immunity", LOG_ATTACK)
		owner.add_stun_absorption("acid_sack", INFINITY, 4)
		owner.playsound_local(get_turf(owner), 'sound/effects/singlebeat.ogg', 40, 1, use_reverb = FALSE)

/datum/status_effect/acid_sack/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.brute_mod *= 2
		H.physiology.burn_mod *= 2
		H.physiology.tox_mod *= 2
		H.physiology.oxy_mod *= 2
		H.physiology.clone_mod *= 2
		H.physiology.stamina_mod *= 2
	owner.log_message("lost acid sack stun immunity", LOG_ATTACK)
	REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, BLOODDRUNK_TRAIT);
	if(islist(owner.stun_absorption) && owner.stun_absorption["acid_sack"])
		owner.stun_absorption -= "acid_sack"

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
	examine_text = "<span class='notice'>They seem to have an aura of healing and helpfulness about them.</span>"
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
	var/datum/atom_hud/H = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	H.add_hud_to(owner)
	return ..()

/datum/status_effect/hippocratic_oath/on_remove()
	QDEL_NULL(aura_healing)
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, HIPPOCRATIC_OATH_TRAIT)
	var/datum/atom_hud/H = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	H.remove_hud_from(owner)

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
		owner.dizziness = max(0, owner.dizziness - 2)
		owner.jitteriness = max(0, owner.jitteriness - 2)
		owner.set_confusion(max(0, owner.get_confusion() - 1))
		SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "goodmusic", /datum/mood_event/goodmusic)

/atom/movable/screen/alert/status_effect/regenerative_core
	name = "Regenerative Core Tendrils"
	desc = "You can move faster than your broken body could normally handle!"
	icon_state = "regenerative_core"

/atom/movable/screen/alert/status_effect/shining_core
	name = "Shining Power"
	desc = "Shining core allows you to move as fast as you possibly could!"
	icon_state = "shining_core"

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

/datum/status_effect/regenerative_core/shining_core //Longer effect, more healing, prevents softcrit. But hey, killing seedlings is much harder than killing legions.
	id = "Shining Core"
	duration = 2 MINUTES
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/shining_core

/datum/status_effect/regenerative_core/shining_core/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_NOSOFTCRIT, STATUS_EFFECT_TRAIT)
	owner.adjustBruteLoss(-25)
	owner.adjustFireLoss(-25)

/datum/status_effect/regenerative_core/on_remove()
	. = ..()
	REMOVE_TRAIT(owner, TRAIT_NOSOFTCRIT, STATUS_EFFECT_TRAIT)

/datum/status_effect/antimagic
	id = "antimagic"
	duration = 10 SECONDS
	examine_text = "<span class='notice'>They seem to be covered in a dull, grey aura.</span>"

/datum/status_effect/antimagic/on_apply()
	owner.visible_message(span_notice("[owner] is coated with a dull aura!"))
	ADD_TRAIT(owner, TRAIT_ANTIMAGIC, MAGIC_TRAIT)
	//glowing wings overlay
	playsound(owner, 'sound/weapons/fwoosh.ogg', 75, FALSE)
	return ..()

/datum/status_effect/antimagic/on_remove()
	REMOVE_TRAIT(owner, TRAIT_ANTIMAGIC, MAGIC_TRAIT)
	owner.visible_message(span_warning("[owner]'s dull aura fades away..."))

/datum/status_effect/crucible_soul
	id = "Blessing of Crucible Soul"
	status_type = STATUS_EFFECT_REFRESH
	duration = 15 SECONDS
	examine_text = "<span class='notice'>They don't seem to be all here.</span>"
	alert_type = /atom/movable/screen/alert/status_effect/crucible_soul
	var/turf/location

/datum/status_effect/crucible_soul/on_apply()
	. = ..()
	to_chat(owner,span_notice("You phase through reality, nothing is out of bounds!"))
	owner.alpha = 180
	owner.pass_flags |= PASSCLOSEDTURF | PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSTABLE | PASSMOB | PASSDOORS | PASSVEHICLE
	location = get_turf(owner)

/datum/status_effect/crucible_soul/on_remove()
	to_chat(owner,span_notice("You regain your physicality, returning you to your original location..."))
	owner.alpha = initial(owner.alpha)
	owner.pass_flags &= ~(PASSCLOSEDTURF | PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSTABLE | PASSMOB | PASSDOORS | PASSVEHICLE)
	owner.forceMove(location)
	location = null
	return ..()

/datum/status_effect/duskndawn
	id = "Blessing of Dusk and Dawn"
	status_type = STATUS_EFFECT_REFRESH
	duration = 60 SECONDS
	alert_type =/atom/movable/screen/alert/status_effect/duskndawn

/datum/status_effect/duskndawn/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_XRAY_VISION, STATUS_EFFECT_TRAIT)
	owner.update_sight()

/datum/status_effect/duskndawn/on_remove()
	REMOVE_TRAIT(owner, TRAIT_XRAY_VISION, STATUS_EFFECT_TRAIT)
	owner.update_sight()
	return ..()

/datum/status_effect/marshal
	id = "Blessing of Wounded Soldier"
	status_type = STATUS_EFFECT_REFRESH
	duration = 60 SECONDS
	tick_interval = 1 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/marshal

/datum/status_effect/marshal/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, STATUS_EFFECT_TRAIT)

/datum/status_effect/marshal/on_remove()
	. = ..()
	REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, STATUS_EFFECT_TRAIT)

/datum/status_effect/marshal/tick()
	. = ..()
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
	desc = "You phased through the reality, you are halfway to your final destination..."
	icon_state = "crucible"

/atom/movable/screen/alert/status_effect/duskndawn
	name = "Blessing of Dusk and Dawn"
	desc = "Many things hide beyond the horizon, with Owl's help i managed to slip past sun's guard and moon's watch."
	icon_state = "duskndawn"

/atom/movable/screen/alert/status_effect/marshal
	name = "Blessing of Wounded Soldier"
	desc = "Some people seek power through redemption, one thing many people don't know is that battle is the ultimate redemption and wounds let you bask in eternal glory."
	icon_state = "wounded_soldier"

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

/atom/movable/screen/alert/status_effect/crystal_heart
	name = "Crystal Heart"
	desc = "You have been granted increased defence and endurance from consuming a crystal fruit."
	icon_state = "crystallization"

/datum/status_effect/crystal_heart
	id = "crystal_heart"
	duration = 1 MINUTES
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/crystal_heart

/datum/status_effect/crystal_heart/on_apply()
	. = ..()
	if(.)
		ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, TIME_CRYSTAL_TRAIT)
		ADD_TRAIT(owner, TRAIT_NOSOFTCRIT, TIME_CRYSTAL_TRAIT)
		ADD_TRAIT(owner, TRAIT_NOHARDCRIT, TIME_CRYSTAL_TRAIT)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.physiology.brute_mod *= 0.66
			H.physiology.burn_mod *= 0.66
			H.physiology.tox_mod *= 0.66
			H.physiology.oxy_mod *= 0.66
			H.physiology.clone_mod *= 0.66
			H.physiology.stamina_mod *= 0.66

/datum/status_effect/crystal_heart/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.brute_mod /= 0.66
		H.physiology.burn_mod /= 0.66
		H.physiology.tox_mod /= 0.66
		H.physiology.oxy_mod /= 0.66
		H.physiology.clone_mod /= 0.66
		H.physiology.stamina_mod /= 0.66
	REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, TIME_CRYSTAL_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_NOSOFTCRIT, TIME_CRYSTAL_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_NOHARDCRIT, TIME_CRYSTAL_TRAIT)

/// Demonic energy

#define SOULS_PER_HUMAN 5
#define SOULS_PER_MEGAFAUNA 20
#define SOUL_DAMAGE_COEFF 3

#define SOULS_LEVEL_ONE 10
#define SOULS_LEVEL_TWO 30
#define SOULS_LEVEL_THREE 50
#define SOULS_LEVEL_FOUR 75

#define LEVEL_ONE_TRAITS 	list(TRAIT_STUNRESISTANCE)
#define LEVEL_TWO_TRAITS 	list(TRAIT_STUNRESISTANCE, TRAIT_STRONG_MINER, TRAIT_NOHUNGER)
#define LEVEL_THREE_TRAITS  list(TRAIT_STUNRESISTANCE, TRAIT_STRONG_MINER, TRAIT_NOHUNGER, TRAIT_NOBREATH)
#define LEVEL_FOUR_TRAITS   list(TRAIT_NOFIRE, TRAIT_STUNIMMUNE, TRAIT_IGNORESLOWDOWN, TRAIT_STRONG_MINER, TRAIT_NOHUNGER, TRAIT_NOBREATH)

/datum/status_effect/demonic_energy
	id = "demonic_energy"
	duration = -1
	tick_interval = 4
	alert_type = /atom/movable/screen/alert/status_effect/demonic_energy
	var/consumed_souls = 0
	var/level = 0
	var/tracked_mobs = list()
	var/given_traits = list()
	var/prev_health = 0
	var/mutable_appearance/orb_underlay
	var/mutable_appearance/orb_overlay

/datum/status_effect/demonic_energy/on_apply()
	. = ..()
	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/target = owner
	prev_health = target.health
	target.dna.features["mcolor"] = "A02720"
	if(isethereal(target))
		var/datum/species/ethereal/species = target.dna.species
		species.current_color = "A02720" //Unique demon crystal-only color
		species.spec_updatehealth(target)
	target.updateappearance(mutcolor_update=1)

	RegisterSignal(target, COMSIG_CARBON_HEALTH_UPDATE, .proc/update_health)

/datum/status_effect/demonic_energy/on_remove()
	UnregisterSignal(owner, COMSIG_CARBON_HEALTH_UPDATE)
	. = ..()

/datum/status_effect/demonic_energy/tick()
	check_tracked_mobs()

/datum/status_effect/demonic_energy/proc/update_souls()
	if(consumed_souls < SOULS_LEVEL_ONE)
		level = 0
	else if(consumed_souls < SOULS_LEVEL_TWO)
		level = 1
	else if(consumed_souls < SOULS_LEVEL_THREE)
		level = 2
	else if(consumed_souls < SOULS_LEVEL_FOUR)
		level = 3
	else
		level = 4

	linked_alert.icon_state = "[initial(linked_alert.icon_state)][level]"
	for(var/trait_type in given_traits)
		REMOVE_TRAIT(owner, trait_type, DEMON_STONE_TRAIT)

	var/new_traits = list()

	if(orb_overlay && !QDELETED(orb_overlay))
		owner.underlays -= orb_underlay
		owner.overlays -= orb_overlay
		qdel(orb_underlay)
		qdel(orb_overlay)

	if(level > 0)
		orb_underlay = mutable_appearance('icons/effects/effects.dmi', "blood_orb_[level]_bottom")
		orb_overlay = mutable_appearance('icons/effects/effects.dmi', "blood_orb_[level]_top")

		orb_underlay.pixel_x = owner.pixel_x
		orb_underlay.pixel_y = owner.pixel_y
		orb_overlay.pixel_x = owner.pixel_x
		orb_overlay.pixel_y = owner.pixel_y

		owner.underlays += orb_underlay
		owner.overlays += orb_overlay

	switch(level)
		if(1)
			new_traits = LEVEL_ONE_TRAITS
		if(2)
			new_traits = LEVEL_TWO_TRAITS
		if(3)
			new_traits = LEVEL_THREE_TRAITS
		if(4)
			new_traits = LEVEL_FOUR_TRAITS

	for(var/trait_type in new_traits)
		ADD_TRAIT(owner, trait_type, DEMON_STONE_TRAIT)

	if(level >= 3)
		owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/demon_stone)
	else
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/demon_stone)

/datum/status_effect/demonic_energy/proc/souls_required()
	switch(level)
		if(0)
			return SOULS_LEVEL_ONE - consumed_souls
		if(1)
			return SOULS_LEVEL_TWO - consumed_souls
		if(2)
			return SOULS_LEVEL_THREE - consumed_souls
		if(3)
			return SOULS_LEVEL_FOUR - consumed_souls

/datum/status_effect/demonic_energy/proc/check_tracked_mobs()
	var/list/possible_targets = list()
	for(var/mob/living/possible_target in range(7, get_turf(owner)))
		if(possible_target.stat != DEAD && !faction_check(owner.faction, possible_target.faction))
			possible_targets.Add(possible_target)
			if(!(possible_target in tracked_mobs))
				register_death(possible_target)

	for(var/mob/living/being_tracked in tracked_mobs)
		if(!(being_tracked in possible_targets))
			UnregisterSignal(being_tracked, COMSIG_LIVING_DEATH)

	tracked_mobs = possible_targets

/datum/status_effect/demonic_energy/proc/register_death(mob/living/victim)
	if(ishuman(victim))
		RegisterSignal(victim, COMSIG_LIVING_DEATH, .proc/harvest_soul_human)
	else if(ismegafauna(victim))
		RegisterSignal(victim, COMSIG_LIVING_DEATH, .proc/harvest_soul_megafauna)
	else
		RegisterSignal(victim, COMSIG_LIVING_DEATH, .proc/harvest_soul)

/datum/status_effect/demonic_energy/proc/harvest_soul_human()
	SIGNAL_HANDLER
	consumed_souls += SOULS_PER_HUMAN
	update_souls()

/datum/status_effect/demonic_energy/proc/harvest_soul_megafauna() //Shitcode but I don't have much of a choice
	SIGNAL_HANDLER
	consumed_souls += SOULS_PER_MEGAFAUNA
	update_souls()

/datum/status_effect/demonic_energy/proc/harvest_soul()
	SIGNAL_HANDLER
	consumed_souls += 1
	update_souls()

/datum/status_effect/demonic_energy/proc/update_health(mob/living/source)
	SIGNAL_HANDLER

	if(owner.health >= prev_health)
		prev_health = owner.health
		return

	prev_health = owner.health

	if(consumed_souls > 0)
		owner.adjustCloneLoss(consumed_souls * SOUL_DAMAGE_COEFF)
		to_chat(owner, span_colossus("As you get attacked, souls contained withing you escape, damaging you even more!"))
		playsound(owner, 'sound/machines/clockcult/ark_scream.ogg', 50, TRUE)
		owner.emote("scream")

	consumed_souls = 0
	update_souls()

/atom/movable/screen/alert/status_effect/demonic_energy
	name = "Demonic Energy"
	desc = "Your soul has been consumed by the crystal, making you incredibly strong in cost of becoming really vunerable to attacks."
	icon_state = "demonic_energy"
	alerttooltipstyle = "cult"

/atom/movable/screen/alert/status_effect/demonic_energy/MouseEntered(location,control,params)
	desc = initial(desc)
	var/datum/status_effect/demonic_energy/status = attached_effect
	desc += "<br><font size=3><b>Current Consumed Souls: [status.consumed_souls]</b></font>\
	[status.level < 3 ? "<br>You need [status.souls_required()] souls to ascend to the next level" : ""]</b>"
	return ..()

#undef SOULS_PER_HUMAN
#undef SOULS_PER_MEGAFAUNA
#undef SOUL_DAMAGE_COEFF

#undef SOULS_LEVEL_ONE
#undef SOULS_LEVEL_TWO
#undef SOULS_LEVEL_THREE

#undef LEVEL_ONE_TRAITS
#undef LEVEL_TWO_TRAITS
#undef LEVEL_THREE_TRAITS
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

/datum/status_effect/vine_ring
	id = "vine_ring"
	duration = 300
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/vine_ring
	var/mutable_appearance/ring_underlay
	var/mutable_appearance/ring_overlay
	var/brute_loss
	var/fire_loss
	var/tox_loss
	var/oxy_loss

/datum/status_effect/vine_ring/on_apply()
	if(owner.stat != DEAD)
		ring_underlay = mutable_appearance('icons/effects/effects.dmi', "vine_ring_bottom")
		ring_underlay.pixel_x = owner.pixel_x
		ring_underlay.pixel_y = owner.pixel_y
		owner.underlays += ring_underlay

		ring_overlay = mutable_appearance('icons/effects/effects.dmi', "vine_ring_top")
		ring_overlay.pixel_x = owner.pixel_x
		ring_overlay.pixel_y = owner.pixel_y
		owner.overlays += ring_overlay

		brute_loss = owner.getBruteLoss()
		fire_loss = owner.getFireLoss()
		tox_loss = owner.getToxLoss()
		oxy_loss = owner.getOxyLoss()
		RegisterSignal(owner, COMSIG_CARBON_HEALTH_UPDATE, .proc/update_health)
		return TRUE
	return FALSE

/datum/status_effect/vine_ring/Destroy()
	if(owner)
		owner.underlays -= ring_underlay
		owner.overlays -= ring_overlay
		UnregisterSignal(owner, COMSIG_CARBON_HEALTH_UPDATE)
	QDEL_NULL(ring_underlay)
	QDEL_NULL(ring_overlay)
	return ..()

/datum/status_effect/vine_ring/proc/update_health(mob/living/source)
	SIGNAL_HANDLER

	if(owner.getBruteLoss() > brute_loss)
		addtimer(CALLBACK(owner, /mob/living.proc/adjustBruteLoss, ((owner.getBruteLoss() - brute_loss) * -0.33)), 1)

	if(owner.getFireLoss() > fire_loss)
		addtimer(CALLBACK(owner, /mob/living.proc/adjustFireLoss, ((owner.getFireLoss() - fire_loss) * -0.33)), 1)

	if(owner.getToxLoss() > tox_loss)
		addtimer(CALLBACK(owner, /mob/living.proc/adjustToxLoss,((owner.getToxLoss() - tox_loss) * -0.33)), 1)

	if(owner.getOxyLoss() > oxy_loss)
		addtimer(CALLBACK(owner, /mob/living.proc/adjustOxyLoss, ((owner.getOxyLoss() - oxy_loss) * -0.33)), 1)

	to_chat(owner, span_danger("Your vine ring partially reflects the attack, but breaks in the process!"))
	owner.remove_status_effect(STATUS_EFFECT_VINE_RING)

/datum/status_effect/vine_ring/be_replaced()
	owner.underlays -= ring_underlay
	owner.overlays -= ring_overlay
	..()

/atom/movable/screen/alert/status_effect/vine_ring
	name = "Blessing of the Jungle"
	desc = "You're surronded by a ring of thorny blooming vines that will reflect half of any incoming attack!"
	icon_state = "vine_ring"
