/datum/slime_color/oil
	color = "oil"
	coretype = /obj/item/slime_extract/oil
	mutations = null
	slime_tags = SLIME_WATER_RESISTANCE
	environmental_req = ""



/obj/effect/decal/cleanable/oil_pool
	name = "pool of oil"
	desc = "A pool of flammable oil. It's probably wise to clean this off before something ignites it..."
	icon_state = "oil_pool"
	layer = LOW_OBJ_LAYER
	beauty = -50
	clean_type = CLEAN_TYPE_BLOOD
	var/burn_amount = 5
	var/burning = FALSE

/obj/effect/decal/cleanable/oil_pool/proc/ignite()
	if(burning)
		return
	burning = TRUE
	addtimer(CALLBACK(src, .proc/ignite_others), 0.5 SECONDS)
	while(burn_amount)
		burn_amount -= 1
		new /obj/effect/hotspot(get_turf(src))
		sleep(0.5 SECONDS)
	qdel(src)

/obj/effect/decal/cleanable/oil_pool/proc/ignite_others()
	for(var/obj/effect/decal/cleanable/oil/oil in range(1, get_turf(src)))
		oil.ignite()

/datum/slime_color/black
	color = "black"
	coretype = /obj/item/slime_extract/black
	mutations = null
	environmental_req = "Subject has an ability to terraform it's surroundings into slime-like turfs. This ability can be neutered by making the pen look like a natural habitat."
	slime_tags = SLIME_WATER_RESISTANCE
	var/list/required_turfs

/datum/slime_color/black/New(slime)
	. = ..()
	if(!required_turfs)
		required_turfs = typecacheof(list(
			/turf/open/misc/asteroid,
			/turf/open/misc/ashplanet,
			/turf/open/misc/dirt,
			/turf/open/floor/fakebasalt,
		))

/datum/slime_color/black/Life(delta_time, times_fired)
	. = ..()

	if(SLIME_SHOULD_MISBEHAVE(slime, delta_time) && DT_PROB(BLACK_SLIME_CHANGE_TURF_CHANCE, delta_time))
		convert_turf()

	var/turf/our_turf = get_turf(slime)
	if(is_type_in_typecache(our_turf, required_turfs))
		fitting_environment = TRUE
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * get_passive_damage_modifier())

	if(DT_PROB(BLACK_SLIME_CHANGE_TURF_CHANCE, delta_time))
		convert_turf()

/datum/slime_color/black/proc/convert_turf()

	var/list/convertable_turfs = list()
	for(var/turf/possible_target in circle_range_turfs(get_turf(slime), BLACK_SLIME_TURF_CHANGE_RANGE))
		if(istype(possible_target, /turf/open/misc/slime) || istype(possible_target, /turf/closed/wall/slime))
			continue

		if(isfloorturf(possible_target) || istype(possible_target, /turf/open/misc) || ismineralturf(possible_target))
			convertable_turfs[possible_target] = BLACK_SLIME_TURF_CHANGE_RANGE + 3 - get_dist(slime, possible_target) //Floors have a bit higher chance to be converted
		else if(iswallturf(possible_target))
			var/turf/closed/wall/target_wall = possible_target
			if(!prob(min(100, target_wall.hardness * 2)))
				continue
			convertable_turfs[possible_target] = BLACK_SLIME_TURF_CHANGE_RANGE + 1 - get_dist(slime, possible_target)

	var/turf/target_turf = pick_weight(convertable_turfs)
	if(isclosedturf(target_turf))
		target_turf.ChangeTurf(/turf/closed/wall/slime, flags = CHANGETURF_INHERIT_AIR)
	else if(locate(/obj/structure/window) in target_turf)
		for(var/obj/structure/window/window in target_turf)
			window.deconstruct(FALSE)
		target_turf.ChangeTurf(/turf/closed/wall/slime, flags = CHANGETURF_INHERIT_AIR)
	else
		target_turf.ChangeTurf(/turf/open/misc/slime, flags = CHANGETURF_INHERIT_AIR)

	var/obj/structure/grille/grille = locate() in target_turf
	if(grille)
		grille.deconstruct(FALSE)

/datum/slime_color/adamantine
	color = "adamantine"
	coretype = /obj/item/slime_extract/adamantine
	mutations = null

/datum/slime_color/light_pink
	color = "light pink"
	icon_color = "light_pink"
	coretype = /obj/item/slime_extract/lightpink
	mutations = null
	slime_tags = SLIME_DISCHARGER_WEAKENED
	environmental_req = "Subject can mind-control whoever it latches onto and requires a host to survive."
	var/mind_control_timer
	var/mob/living/carbon/human/puppet
	var/mutable_appearance/goop_overlay
	var/full_control = FALSE
	var/mob/living/slime_mind_holder/mind_holder
	var/datum/move_loop/move_loop
	var/obj/item/new_weapon_targeting
	var/list/blacklisted_targets = list()
	var/list/initial_puppet_faction = list()

/datum/slime_color/light_pink/New(slime)
	. = ..()
	RegisterSignal(slime, COMSIG_SLIME_FEEDON, .proc/start_feeding)
	RegisterSignal(slime, COMSIG_SLIME_FEEDSTOP, .proc/stop_feeding)
	RegisterSignal(slime, COMSIG_SLIME_BUCKLED_AI, .proc/allow_buckled_ai)
	RegisterSignal(slime, COMSIG_SLIME_START_MOVE_LOOP, .proc/start_moveloop)
	RegisterSignal(slime, COMSIG_SLIME_STOP_MOVE_LOOP, .proc/stop_moveloop)
	RegisterSignal(slime, COMSIG_SLIME_CAN_FEEDON, .proc/can_feed)
	RegisterSignal(slime, COMSIG_SLIME_ATTEMPT_SAY, .proc/attempt_say)
	RegisterSignal(slime, COMSIG_SLIME_SET_TARGET, .proc/set_target)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/attempt_attack)

	blacklisted_targets = typecacheof(list(/obj/machinery/atmospherics/components/unary/vent_pump,
										   /obj/machinery/atmospherics/components/unary/vent_scrubber,
										   /obj/item/giant_slime_plushie,
										   ))

/datum/slime_color/light_pink/remove()
	UnregisterSignal(slime, list(COMSIG_SLIME_FEEDON, COMSIG_SLIME_FEEDSTOP, COMSIG_SLIME_BUCKLED_AI,
								 COMSIG_SLIME_START_MOVE_LOOP, COMSIG_SLIME_STOP_MOVE_LOOP, COMSIG_SLIME_CAN_FEEDON,
								 COMSIG_SLIME_ATTEMPT_SAY, COMSIG_SLIME_SET_TARGET, COMSIG_SLIME_ATTACK_TARGET))

/datum/slime_color/light_pink/Life(delta_time, times_fired)
	. = ..()
	if(slime.buckled && isliving(slime.buckled))
		fitting_environment = TRUE
		if(full_control)
			handle_puppet(delta_time, times_fired)
		return

	fitting_environment = FALSE
	slime.adjustBruteLoss(SLIME_DAMAGE_MED * delta_time * get_passive_damage_modifier())

/datum/slime_color/light_pink/get_attack_cd(atom/attack_target)
	if(full_control)
		if(isliving(attack_target) && HAS_TRAIT(attack_target, TRAIT_CRITICAL_CONDITION))
			return 4.5 SECONDS
		return 0.8 SECONDS
	return ..()

/datum/slime_color/light_pink/proc/handle_puppet(delta_time, times_fired)
	var/best_force = 5
	var/obj/item/main_item = puppet.get_active_held_item()
	var/obj/item/secondary_item = puppet.get_inactive_held_item()
	if(main_item)
		if(secondary_item)
			if(secondary_item.force > max(best_force, main_item.force))
				puppet.swap_hand(puppet.get_inactive_hand_index())
				best_force = secondary_item.force
			else if(main_item.force > best_force)
				best_force = main_item.force
			else
				puppet.drop_all_held_items()
		else
			if(main_item.force > best_force)
				best_force = main_item.force
			else
				puppet.drop_all_held_items()
	else if(secondary_item)
		if(secondary_item.force > best_force)
			best_force = secondary_item.force
			puppet.swap_hand(puppet.get_inactive_hand_index())
		else
			puppet.drop_all_held_items()

	var/obj/item/new_weapon
	var/weapon_range = 7
	if(slime.Target && isliving(slime.Target))
		weapon_range = 3
	for(var/obj/item/possible_weapon in view(weapon_range, get_turf(puppet)))
		var/actual_force = possible_weapon.force
		var/datum/component/two_handed/wielding = possible_weapon.GetComponent(/datum/component/two_handed)
		if(wielding)
			if(wielding.force_wielded)
				actual_force = wielding.force_wielded
			else if(wielding.force_multiplier)
				actual_force *= wielding.force_multiplier
		else
			var/datum/component/transforming/transforming = possible_weapon.GetComponent(/datum/component/transforming)
			if(transforming)
				actual_force = transforming.force_on
		if(possible_weapon.force <= best_force)
			continue

		if(!get_step_to(puppet, possible_weapon))
			continue

		best_force = actual_force
		new_weapon = possible_weapon

	if(!new_weapon)
		return

	new_weapon_targeting = new_weapon
	slime.set_target(new_weapon_targeting)
	slime.target_patience = 10

/datum/slime_color/light_pink/proc/attempt_attack(datum/source, atom/attack_target)
	SIGNAL_HANDLER

	if(!full_control)
		return

	if(attack_target == new_weapon_targeting)
		var/obj/item/new_weapon = attack_target
		puppet.drop_all_held_items()
		puppet.put_in_active_hand(new_weapon)
		var/datum/component/two_handed/wielding = new_weapon.GetComponent(/datum/component/two_handed)
		if(wielding)
			wielding.wield(puppet)
		else
			var/datum/component/transforming/transforming = new_weapon.GetComponent(/datum/component/transforming)
			if(transforming)
				transforming.set_active(new_weapon)
		stop_moveloop()
		slime.set_target(null)
		return COMPONENT_SLIME_NO_ATTACK

	if(isliving(attack_target) && HAS_TRAIT(attack_target, TRAIT_CRITICAL_CONDITION)) //If target is critted, the slime itself finishes itself and yoinks some nutrition.
		slime.adjust_nutrition(LIGHT_PINK_SLIME_FINISHER_NUTRITION)
		return

	if(isliving(attack_target))
		var/mob/living/victim = attack_target
		var/turf/shove_turf = get_step(attack_target, get_dir(slime, attack_target))
		if(shove_turf.is_blocked_turf() && !victim.IsKnockdown())
			INVOKE_ASYNC(puppet, /mob.proc/UnarmedAttack, attack_target, TRUE, list(RIGHT_CLICK = "1"))
			return COMPONENT_SLIME_NO_ATTACK
		if(victim.IsKnockdown() && !victim.IsParalyzed() && prob(65) && !victim.stat) //Don't want horrible stunlocks
			INVOKE_ASYNC(puppet, /mob.proc/UnarmedAttack, attack_target, TRUE, list(RIGHT_CLICK = "1"))
			return COMPONENT_SLIME_NO_ATTACK

	if(puppet.get_active_held_item())
		var/obj/item/weapon = puppet.get_active_held_item()
		if(weapon.throwforce > weapon.force * 2)
			puppet.throw_mode_on(THROW_MODE_TOGGLE)
			puppet.throw_item(attack_target)
			return COMPONENT_SLIME_NO_ATTACK

		puppet.throw_mode_off(THROW_MODE_TOGGLE)
		INVOKE_ASYNC(weapon, /obj/item.proc/melee_attack_chain, puppet, attack_target)
		return COMPONENT_SLIME_NO_ATTACK

	INVOKE_ASYNC(puppet, /mob.proc/UnarmedAttack, attack_target, TRUE)
	return COMPONENT_SLIME_NO_ATTACK

/datum/slime_color/light_pink/proc/set_target(datum/source, atom/old_target, atom/new_target)
	SIGNAL_HANDLER

	if(puppet && is_type_in_typecache(new_target, blacklisted_targets))
		return COMPONENT_SLIME_NO_SET_TARGET

/datum/slime_color/light_pink/proc/attempt_say(datum/source, to_say)
	SIGNAL_HANDLER

	if(puppet && full_control)
		INVOKE_ASYNC(puppet, /atom/movable.proc/say, to_say)
		return COMPONENT_SLIME_NO_SAY

/datum/slime_color/light_pink/proc/can_feed(datum/source, atom/feed_target)
	SIGNAL_HANDLER

	if(puppet)
		if(isliving(feed_target) && HAS_TRAIT(feed_target, TRAIT_CRITICAL_CONDITION) && !slime.Atkcool)
			slime.attack_target(feed_target)
		return COMPONENT_SLIME_NO_FEEDON

/datum/slime_color/light_pink/proc/start_feeding(datum/source, atom/target)
	SIGNAL_HANDLER

	if(puppet)
		if(isliving(target) && !slime.Atkcool)
			slime.attack_target(target)
		return COMPONENT_SLIME_NO_FEEDON

	if(!ishuman(target) || HAS_TRAIT(target, TRAIT_SLIME_RESISTANCE))
		return

	start_puppeteering(target)

/datum/slime_color/light_pink/proc/start_puppeteering(mob/living/carbon/human/new_puppet)
	puppet = new_puppet
	goop_overlay = mutable_appearance('icons/effects/effects.dmi', "light_pink_slime_goop")
	puppet.add_overlay(goop_overlay)
	slime.alpha = 1
	to_chat(puppet, span_userdanger("You feel [slime]'s tendrils entering thgough your mouth and ears and start connecting to your brain!"))
	mind_control_timer = addtimer(CALLBACK(src, .proc/start_control), LIGHT_PINK_SLIME_MIND_CONTROL_TIMER, TIMER_STOPPABLE)
	puppet.overlay_fullscreen("slime_control", /atom/movable/screen/fullscreen/slime_control, 0)

/datum/slime_color/light_pink/proc/stop_feeding(datum/source, atom/target)
	SIGNAL_HANDLER

	if(!isliving(target) || target != puppet) //SOMEHOW
		return

	stop_puppeteering()

/datum/slime_color/light_pink/proc/stop_puppeteering()
	puppet.clear_fullscreen("slime_control")
	puppet.faction = initial_puppet_faction.Copy()
	if(full_control)
		to_chat(mind_holder, span_notice("You feel [slime] losing control over your body as your senses return to you!"))
		if(mind_holder.mind)
			mind_holder.mind.transfer_to(puppet)
		QDEL_NULL(mind_holder)
		stop_moveloop()
		UnregisterSignal(puppet, list(COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_HULK_ATTACK, COMSIG_ATOM_ATTACK_HAND,
									  COMSIG_ATOM_ATTACK_PAW, COMSIG_ATOM_HITBY, COMSIG_ATOM_BULLET_ACT))

	puppet.cut_overlay(goop_overlay)
	QDEL_NULL(goop_overlay)
	full_control = FALSE
	slime.alpha = initial(slime.alpha)
	if(mind_control_timer)
		deltimer(mind_control_timer)
	puppet = null

/datum/slime_color/light_pink/proc/start_control()
	full_control = TRUE
	mind_holder = new(puppet, src)
	mind_holder.overlay_fullscreen("slime_control", /atom/movable/screen/fullscreen/slime_control, 0)
	to_chat(puppet, span_userdanger("You feel a terrible headache as your consiousness is being forced out of your body!"))
	puppet.combat_mode = TRUE
	initial_puppet_faction = puppet.faction.Copy()
	puppet.faction = list("slime", "neutral")
	if(puppet.mind)
		puppet.mind.transfer_to(mind_holder)

	RegisterSignal(puppet, COMSIG_PARENT_ATTACKBY, .proc/puppet_parent_attack)
	RegisterSignal(puppet, COMSIG_ATOM_HULK_ATTACK, .proc/puppet_hulk_attack)
	RegisterSignal(puppet, COMSIG_ATOM_ATTACK_HAND, .proc/puppet_hand_attack)
	RegisterSignal(puppet, COMSIG_ATOM_ATTACK_PAW, .proc/puppet_paw_attack)
	RegisterSignal(puppet, COMSIG_ATOM_HITBY, .proc/puppet_throw_impact)
	RegisterSignal(puppet, COMSIG_ATOM_BULLET_ACT, .proc/puppet_bullet_act)

/datum/slime_color/light_pink/proc/puppet_parent_attack(datum/source, obj/item/I, mob/attacker)
	SIGNAL_HANDLER

	if(isslime(attacker))
		return

	slime.attacked += 10

/datum/slime_color/light_pink/proc/puppet_hulk_attack(datum/source, mob/attacker)
	SIGNAL_HANDLER

	if(isslime(attacker))
		return

	slime.attacked += 10

/datum/slime_color/light_pink/proc/puppet_hand_attack(datum/source, mob/living/attacker)
	SIGNAL_HANDLER

	if(isslime(attacker))
		return

	slime.attacked += 10

/datum/slime_color/light_pink/proc/puppet_paw_attack(datum/source, mob/living/attacker)
	SIGNAL_HANDLER

	if(isslime(attacker))
		return

	slime.attacked += 10

/datum/slime_color/light_pink/proc/puppet_throw_impact(datum/source, atom/movable/thrown_movable, skipcatch = FALSE, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(istype(thrown_movable, /obj/item))
		var/obj/item/thrown_item = thrown_movable
		var/mob/thrown_by = thrown_item.thrownby?.resolve()

		if(isslime(thrown_by) || !thrown_item.force)
			return

		slime.attacked += 10

/datum/slime_color/light_pink/proc/puppet_bullet_act(datum/participant, obj/projectile/proj)
	SIGNAL_HANDLER

	if(isslime(proj.firer))
		return

	slime.attacked += 10

/datum/slime_color/light_pink/get_feed_damage_modifier()
	if(slime.health >= slime.maxHealth)
		return 0.025 //About 15 minutes to finish a host off
	else if(slime.health < slime.maxHealth * 0.5)
		return 0.2
	return 0.075

/datum/slime_color/light_pink/proc/allow_buckled_ai()
	if(full_control)
		return COMPONENT_SLIME_ALLOW_BUCKLED_AI

/datum/slime_color/light_pink/proc/start_moveloop(datum/source, atom/move_target)
	if(!full_control || slime.current_loop_target == move_target)
		return

	var/sleeptime = puppet.cached_multiplicative_slowdown + 1.5 //Slower than a normal human
	if(sleeptime <= 0)
		sleeptime = 0

	stop_moveloop()
	slime.current_loop_target = move_target

	move_loop = SSmove_manager.mixed_move(puppet,
										  slime.current_loop_target,
										  sleeptime,
										  repath_delay = 0.5 SECONDS,
										  max_path_length = AI_MAX_PATH_LENGTH,
										  minimum_distance = 1,
										  id = puppet.get_idcard()
										  )

	RegisterSignal(move_loop, COMSIG_PARENT_QDELETING, .proc/loop_ended)

	return COMPONENT_SLIME_NO_MOVE_LOOP_START

/datum/slime_color/light_pink/proc/stop_moveloop()
	qdel(move_loop)
	if(slime.current_loop_target == new_weapon_targeting)
		new_weapon_targeting = null
	slime.current_loop_target = null

/datum/slime_color/light_pink/proc/loop_ended()
	slime.current_loop_target = null
	move_loop = null

/mob/living/slime_mind_holder
	name = "slime mind holder"
	var/mob/living/carbon/body
	var/datum/slime_color/light_pink/color_holder

/mob/living/slime_mind_holder/Initialize(mapload, color_holder)
	if(ishuman(loc))
		body = loc
		name = body.real_name
		src.color_holder = color_holder
	return ..()

/mob/living/slime_mind_holder/Life(delta_time = SSMOBS_DT, times_fired)
	if(QDELETED(body))
		qdel(src)

	return ..()

/mob/living/slime_mind_holder/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null, filterproof = null)
	to_chat(src, span_warning("You attempt to speak, but fail to control your body!"))
	return FALSE

/mob/living/slime_mind_holder/emote(act, m_type = null, message = null, intentional = FALSE, force_silence = FALSE)
	return FALSE

/mob/living/slime_mind_holder/resist()
	set name = "Resist"
	set category = "IC"

	changeNext_move(CLICK_CD_RESIST)
	SEND_SIGNAL(src, COMSIG_LIVING_RESIST, src)
	to_chat(src, span_notice("You start resisting [color_holder.slime]'s control."))
	if(!do_after(src, LIGHT_PINK_SLIME_RESIST_TIME, target = body, timed_action_flags = (IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE), extra_checks = CALLBACK(src, .proc/can_resist_control)))
		return
	to_chat(src, span_notice("You break free from [color_holder.slime]'s control!"))
	color_holder.slime.Feedstop(TRUE)

/mob/living/slime_mind_holder/proc/can_resist_control()
	if(QDELETED(color_holder) || color_holder.slime.buckled != body)
		return FALSE
	return TRUE
