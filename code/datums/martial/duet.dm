/// A duet martial art, Dual Kick/Strike. Whenever user is alone, their strikes are weaker, but when they are together with their partner they get unique abilities and become more powerful.
/// Kick(White) gets more stamina, but is weaker, while Strike(Black) get lesser stamina boost, but has more powerful attacks
/// This art is based around managing your stamina as most of abilities either recover or drain it rapidly
/// Combos for this art are also unique, to perform them you'll need help from your partner. Moves are stored as following: Q is H from partner, W is D from partner and Z is G from partner

#define MARTIAL_DUET_STANCE_COOLDOWN 3 SECONDS
#define MARTIAL_DUET_DISTANCE 2
#define MARTIAL_DUET_CHARGE_DURATION 7 SECONDS
#define MARTIAL_DUET_AOE_RANGE 3

#define MARTIAL_DUET_DOUBLE_KICK "ZHH" //Main offencive move, deals a lot of stamina damage. 3 of those and you're out.
#define MARTIAL_DUET_FLOWING_ENERGY "GDWZDH" //A damaging move that throws the target and potentially knocks them out if executed perfectly
#define MARTIAL_DUET_BEATDOWN "DQGWH" //Applies s short-lasting status effect that allows us to attack them with North Star speed and regenerate stamina
#define MARTIAL_DUET_FURY "HHWGQHZH" //Generates a series of ying yang symbols and launches target into them. Whenever target crosses a symbol, it detonates, damaging them and healing the user. Powerful enough to softcrit someone(including damage from hits requires)


/datum/martial_art/duet //Defense
	name = "Dual Kick"
	id = MARTIALART_DUET_WHITE
	display_combos = TRUE
	block_chance = 40
	max_streak_length = 8
	help_verb = /mob/living/proc/duet_help

	var/mob/living/owner //Because for some fucking reason martial arts don't store their owner.
	var/list/time_streak = list()

	var/datum/action/duet_stance/back/back_stance
	var/datum/action/duet_stance/spin/spin_stance
	var/datum/action/duet_stance/charge/charge_stance

	var/color = "white" //For effects
	var/stance = "Default"
	var/meme_phrase = "Prepare for the trouble!" //This is what user shouts when they learn us
	var/mob/living/partner
	var/datum/martial_art/duet/partner_art

	var/damage_mod = 1 //Damage modifier for special moves
	var/stamina_damage_mod = 1 //Stamina damage modifier for special moves
	var/stamina_boost_mod = 1 //Stamina healing modifier
	var/focus_modifier = 1 //Damage modifier for Charged Punch stance

	var/are_we_together = FALSE //If we are near each other
	var/are_we_tight = FALSE //If we are REALLY close

	var/stance_charge = 0 //For Charged Punch stance, shows when we entered this stance
	var/obj/effect/temp_visual/ying_yang/ying_yang //For Charged Punch stance, contains concentration indicator

/datum/martial_art/duet/black //Offense
	name = "Dual Strike"
	id = MARTIALART_DUET_BLACK
	meme_phrase = "And make it double!"
	color = "black"
	block_chance = 25
	damage_mod = 1.5
	stamina_damage_mod = 1.5
	stamina_boost_mod = 0.5

/datum/martial_art/duet/New()
	. = ..()
	back_stance = new()
	spin_stance = new()
	charge_stance = new()

/datum/martial_art/duet/proc/cooldown_stances(cooldown = MARTIAL_DUET_STANCE_COOLDOWN)
	back_stance.cooldown = cooldown
	spin_stance.cooldown = cooldown
	charge_stance.cooldown = cooldown

/datum/martial_art/duet/add_to_streak(element, mob/living/D)
	. = ..()
	time_streak.Add(world.time)

/datum/martial_art/duet/proc/link_art(mob/living/target)
	partner = target
	partner_art = target.mind.martial_art

/datum/martial_art/duet/teach(mob/living/owner, make_temporary=FALSE)
	if(..())
		to_chat(owner, "<span class='userdanger'>You know the arts of [name]!</span>")
		to_chat(owner, "<span class='danger'>You can change stances using action button at the top of the screen. Hover your mouse over them to see what they do.</span>")
		owner.say(meme_phrase)
		back_stance.Grant(owner)
		spin_stance.Grant(owner)
		charge_stance.Grant(owner)
		src.owner = owner

		RegisterSignal(owner, COMSIG_MOVABLE_MOVED, .proc/check_distance)
		START_PROCESSING(SSfastprocess, src)

		ADD_TRAIT(owner, TRAIT_NOGUNS, DUALITY_TRAIT)
		ADD_TRAIT(owner, TRAIT_HARDLY_WOUNDED, DUALITY_TRAIT)

/datum/martial_art/duet/on_remove(mob/living/owner)
	to_chat(owner, "<span class='userdanger'>You feel your connection with [partner.real_name] break as you forget the arts of [src]...</span>")
	back_stance.Remove(owner)
	spin_stance.Remove(owner)
	charge_stance.Remove(owner)
	REMOVE_TRAIT(owner, TRAIT_NOGUNS, DUALITY_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_HARDLY_WOUNDED, DUALITY_TRAIT)
	src.owner = null

	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	STOP_PROCESSING(SSfastprocess, src)

/datum/action/duet_stance
	name = "Broken Stance - report if you see this"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	var/stance_name = "Default"
	var/cooldown = 0

/datum/action/duet_stance/Trigger()
	if(owner.incapacitated())
		to_chat(owner, "<span class='warning'>You can't change stances while you're incapacitated.</span>")
		return FALSE

	var/datum/martial_art/duet/art = owner.mind.martial_art
	if(!istype(art))
		return FALSE

	if(art.stance == stance_name)
		art.update_stance("Default", art.stance)
		return TRUE

	if(cooldown > world.time)
		to_chat(owner, "<span class='warning'>You can't change stances that fast.</span>")
		return FALSE

	art.cooldown_stances()
	art.update_stance(stance_name, art.stance)
	return TRUE

/datum/action/duet_stance/back
	name = "Back To Back - Only works as long as you and your partner are standing next to each other. In this stance you rapidly regenerate stamina and have much higher block chance and overall damage."
	stance_name = "Back To Back"
	button_icon_state = "duet_stance_back"

/datum/action/duet_stance/spin
	name = "Spinning Devil - All of your attacks get AoE damage, in cost of you recieving heavy stamina damage. If your partner is standing next to you in the same stance, they will also hit the target with you."
	stance_name = "Spinning Devil"
	button_icon_state = "duet_stance_spin"

/datum/action/duet_stance/charge
	name = "Charged Punch - As long as you're not moving, your hits deal up to double the amount of damage and stamina damage. Longer you don't move, higher your damage gets. Time required to reach peak damage is tripled if your partner is not nearby."
	stance_name = "Charged Punch"
	button_icon_state = "duet_stance_charge"

/datum/martial_art/duet/proc/check_distance(self_call = FALSE)
	if(!partner)
		are_we_together = FALSE
		return

	if(!self_call)
		partner_art.check_distance(TRUE)

	sleep(1) //We do a small sleep here so if we move in pair(aka push or pull one another) Back To Back stance doesn't break

	if(get_dist(owner, partner) <= MARTIAL_DUET_DISTANCE && partner in view(MARTIAL_DUET_DISTANCE, owner))
		are_we_together = TRUE
		if(get_dist(owner, partner) <= 1)
			are_we_tight = TRUE
		else
			are_we_tight = FALSE
	else
		are_we_together = FALSE
		are_we_tight = FALSE

	if(stance == "Back To Back")
		if(!are_we_tight)
			to_chat(owner, "<span class='warning'>You exit Back To Back stance as you move away from your partner.</span>")
			to_chat(partner, "<span class='warning'>You exit Back To Back stance as your partner moves away from you.</span>")
			update_stance("Default", "Back To Back")
			partner_art.update_stance("Default", "Back To Back")
		owner.setDir(get_dir(partner, owner))
		partner.setDir(get_dir(owner, partner))
	else if(stance == "Charged Punch")
		to_chat(owner, "<span class='warning'>You exit Charged Punch stance as you move.</span>")
		update_stance("Default", "Charged Punch")
		if(ying_yang)
			ying_yang.detonate()

/datum/martial_art/duet/proc/update_stance(new_stance, old_stance)
	stance = new_stance

	switch(old_stance)
		if("Back To Back")
			if(partner_art.stance == "Back To Back")
				partner_art.update_stance("Default", "Back To Back")

			block_chance -= 25
			damage_mod -= 0.5
			stamina_damage_mod -= 0.5

		if("Charged Punch")
			stance_charge = 0
			if(ying_yang)
				ying_yang.detonate()

	switch(stance)
		if("Back To Back")
			if(partner_art.stance != "Back To Back")
				partner_art.update_stance("Back To Back", partner_art.stance)

			block_chance += 25
			damage_mod += 0.5
			stamina_damage_mod += 0.5
			owner.setDir(get_dir(partner, owner))
			partner.setDir(get_dir(owner, partner))

			if(!are_we_tight)
				update_stance("Default", "Back To Back")
				partner_art.update_stance("Default", "Back To Back")
				return

		if("Charged Punch")
			stance_charge = world.time
			ying_yang = new /obj/effect/temp_visual/ying_yang/big(get_turf(owner), (are_we_together ? MARTIAL_DUET_CHARGE_DURATION : MARTIAL_DUET_CHARGE_DURATION * 3))
			ying_yang.icon_state = "duet_[are_we_together ? "full" : color]"
			ying_yang.parent_art = src


/datum/martial_art/duet/process(delta_time)
	if(stance == "Back To Back")
		if((owner.body_position == LYING_DOWN) || owner.incapacitated())
			update_stance("Default", "Back To Back")
			partner_art.update_stance("Default", "Back To Back")
			STOP_PROCESSING(SSfastprocess, src)
			return

		owner.adjustStaminaLoss(-3 * stamina_boost_mod * delta_time)
		owner.AdjustAllImmobility(-30 * stamina_boost_mod * delta_time)
	else
		if(stance == "Charged Punch" && ying_yang && ying_yang.icon_state != "duet_[are_we_together ? "full" : color]")
			ying_yang.icon_state = "duet_[are_we_together ? "full" : color]"

	if(are_we_together)
		if(prob(are_we_tight ? 15 : 5))
			new /obj/effect/temp_visual/duet(get_turf(owner))

/datum/martial_art/duet/proc/check_focus_damage()
	if(stance == "Charged Punch")
		focus_modifier = min(2, 1 + (world.time - stance_charge) / (are_we_together ? MARTIAL_DUET_CHARGE_DURATION : MARTIAL_DUET_CHARGE_DURATION * 3))
		return
	focus_modifier = 1

/datum/martial_art/duet/harm_act(mob/living/A, mob/living/D)
	if(!can_use(A))
		return FALSE

	if(A == D && are_we_together)
		if(A.IsKnockdown() || A.IsParalyzed() || A.IsStun())
			to_chat(A, "<span class='warning'>You can't seem to force yourself up right now!</span>")
			return
		A.visible_message("<span class='notice'>[A] forces [A.p_them()]self up to [A.p_their()] feet with [partner]'s help!</span>", "<span class='notice'>You force yourself up to your feet with [partner]'s help!</span>")
		A.set_resting(FALSE, TRUE, TRUE)
		playsound(A, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)

	add_to_streak("H", D)
	partner_art.add_to_streak("Q", D)

	if(check_streak(A, D))
		return TRUE

	log_combat(A, D, "attacked (Duality)")
	A.do_attack_animation(D)
	var/picked_hit_type = pick("kick", "punch")
	var/bonus_damage = 10
	if(D.body_position == LYING_DOWN)
		bonus_damage += 5
		picked_hit_type = "stomp"

	if(!are_we_together)
		bonus_damage -= 9 //You become REALLY weak without your partner nearby

	if(D.has_status_effect(STATUS_EFFECT_BEATDOWN))
		bonus_damage -= 7
		A.changeNext_move(CLICK_CD_RAPID)
		A.apply_damage(-bonus_damage * stamina_damage_mod, STAMINA) //You regenerate some stamina from beatdown punches

	bonus_damage = max(0, bonus_damage)

	check_focus_damage()

	D.apply_damage(bonus_damage * damage_mod * focus_modifier, A.get_attack_type())
	D.apply_damage(bonus_damage * stamina_damage_mod * focus_modifier, STAMINA)

	if(picked_hit_type == "kick" || picked_hit_type == "stomp")
		playsound(get_turf(D), 'sound/weapons/cqchit2.ogg', 50, TRUE, -1)
	else
		playsound(get_turf(D), 'sound/weapons/cqchit1.ogg', 50, TRUE, -1)

	D.visible_message("<span class='danger'>[A] [picked_hit_type]ed [D]!</span>", \
					"<span class='userdanger'>You're [picked_hit_type]ed by [A]!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", COMBAT_MESSAGE_RANGE, A)
	to_chat(A, "<span class='danger'>You [picked_hit_type] [D]!</span>")

	if(stance == "Spinning Devil" && !D.has_status_effect(STATUS_EFFECT_BEATDOWN)) //No shockwaves during beatdown
		shockwave(A, D, FALSE)

	log_combat(A, D, "[picked_hit_type]s (Duality)")
	return TRUE

/datum/martial_art/duet/proc/shockwave(mob/living/user, mob/living/target, self_call = FALSE)
	user.spin(2, 0.5)
	playsound(user, 'sound/effects/meteorimpact.ogg', 50, 1)
	var/list/hit_things = list()
	var/turf/user_turf = get_turf(user)
	var/orig_dir = user.dir
	var/turf/other_turf = get_step(user_turf, turn(orig_dir, 90))
	var/turf/other_turf2 = get_step(user_turf, turn(orig_dir, -90))

	user.apply_damage(25 / stamina_boost_mod, STAMINA) //Use this stance only if you're sure that you'll be okay or if shit really hits the fan. 4 hits for white, 2 hits for black and you're stamcritted
	for(var/i in 1 to MARTIAL_DUET_AOE_RANGE)
		new /obj/effect/temp_visual/small_smoke/halfsecond(user_turf)
		new /obj/effect/temp_visual/small_smoke/halfsecond(other_turf)
		new /obj/effect/temp_visual/small_smoke/halfsecond(other_turf2)
		for(var/mob/living/victim in (user_turf.contents + other_turf.contents + other_turf2.contents))
			if(victim == partner || victim == user || victim in hit_things)
				continue
			var/throwtarget = get_edge_target_turf(user_turf, get_dir(user_turf, victim))
			victim.safe_throw_at(throwtarget, 5, 2, user)
			victim.Stun(5 * stamina_damage_mod)
			victim.apply_damage_type(15 * damage_mod, BRUTE)
			hit_things += victim
		user_turf = get_step(user_turf, orig_dir)
		other_turf = get_step(other_turf, orig_dir)
		other_turf2 = get_step(other_turf2, orig_dir)
		if(isclosedturf(user_turf) || isclosedturf(other_turf)  || isclosedturf(other_turf2))
			break
		sleep(3)

	if(are_we_tight && partner_art.stance == "Spinning Devil" && get_dist(partner, target) <= 1)
		target.attack_hand(partner)

/datum/martial_art/duet/disarm_act(mob/living/A, mob/living/D)
	if(!can_use(A))
		return FALSE

	add_to_streak("D",D)
	partner_art.add_to_streak("W", D)
	var/obj/item/I = null
	if(check_streak(A,D))
		return TRUE

	check_focus_damage()

	if(prob(65) && are_we_together)
		if(!D.stat || !D.IsParalyzed())
			I = D.get_active_held_item()
			D.visible_message("<span class='danger'>[A] strikes [D]'s jaw with their hand!</span>", \
							"<span class='userdanger'>Your jaw is struck by [A], you feel disoriented!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", COMBAT_MESSAGE_RANGE, A)
			to_chat(A, "<span class='danger'>You strike [D]'s jaw, leaving [D.p_them()] disoriented!</span>")
			playsound(get_turf(D), 'sound/weapons/cqchit1.ogg', 50, TRUE, -1)
			if(I && D.temporarilyRemoveItemFromInventory(I))
				A.put_in_hands(I)
			D.Jitter(2)
			D.apply_damage(5 * damage_mod * focus_modifier, A.get_attack_type())
			return TRUE
	else
		D.visible_message("<span class='danger'>[A] fails to disarm [D]!</span>", \
						"<span class='userdanger'>You're nearly disarmed by [A]!</span>", "<span class='hear'>You hear a swoosh!</span>", COMBAT_MESSAGE_RANGE, A)
		to_chat(A, "<span class='warning'>You try [D][are_we_together ? "" : ", but fail miserably without your partner nearby"]!</span>")
		playsound(D, 'sound/weapons/punchmiss.ogg', 25, TRUE, -1)
		return TRUE
	return FALSE

/datum/martial_art/duet/grab_act(mob/living/A, mob/living/D)
	if(A!=D && can_use(A)) // A!=D prevents grabbing yourself
		add_to_streak("G",D)
		partner_art.add_to_streak("Z", D)
		if(check_streak(A,D))
			return TRUE

/datum/martial_art/duet/proc/check_streak(mob/living/A, mob/living/D)
	if(!can_use(A))
		return FALSE

	if(findtext(streak, MARTIAL_DUET_FLOWING_ENERGY))
		streak = ""
		flowing_energy(A,D)
		return TRUE

	if(findtext(streak, MARTIAL_DUET_BEATDOWN))
		streak = ""
		beatdown(A,D)
		return TRUE

	if(findtext(streak, MARTIAL_DUET_FURY))
		streak = ""
		unleash_fury(A,D)
		return TRUE

	if(findtext(streak, MARTIAL_DUET_DOUBLE_KICK))
		streak = ""
		double_kick(A,D)
		return TRUE

	return FALSE

/datum/martial_art/duet/proc/flowing_energy(mob/living/user, mob/living/victim)
	if(!can_use(user))
		return FALSE

	var/turf/turf_facing = get_step(partner, get_dir(user, get_step_away(victim, user)))
	var/is_open = TRUE
	for(var/atom/check in turf_facing)
		if(check.density)
			is_open = FALSE
			break

	if(!are_we_tight || get_dist(victim, partner) > 1 || isclosedturf(turf_facing) || !is_open) //You just throw em
		user.do_attack_animation(victim, ATTACK_EFFECT_PUNCH)
		var/atk_verb = pick("kick", "hit", "slam")
		victim.visible_message("<span class='danger'>[user] [atk_verb]s [victim] with such inhuman strength that it sends [victim.p_them()] flying backwards!</span>", \
						"<span class='userdanger'>You're [atk_verb]ed by [user] with such inhuman strength that it sends you flying backwards!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", null, user)
		to_chat(user, "<span class='danger'>You [atk_verb] [victim] with such inhuman strength that it sends [victim.p_them()] flying backwards!</span>")
		victim.apply_damage(rand(20,35) * damage_mod, user.get_attack_type())
		playsound(get_turf(victim), 'sound/effects/meteorimpact.ogg', 25, TRUE, -1)
		var/throwtarget = get_edge_target_turf(user, get_dir(user, get_step_away(victim, user)))
		victim.throw_at(throwtarget, 6, 2, user)
		victim.Paralyze(60)
		return TRUE
	else
		user.do_attack_animation(victim, ATTACK_EFFECT_PUNCH) //Epic punch
		var/atk_verb = pick("kick", "hit", "slam")
		victim.visible_message("<span class='danger'>[user] [atk_verb]s [victim], sending [victim.p_them()] flying towards [partner]!</span>", \
						"<span class='userdanger'>You're [atk_verb]ed by [user], sending you flying towards [partner]!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", null, user)
		to_chat(user, "<span class='danger'>You [atk_verb] [victim], sending [victim.p_them()] flying towards [partner]!</span>")
		victim.apply_damage(rand(10,15) * damage_mod, user.get_attack_type())
		playsound(get_turf(victim), 'sound/effects/meteorimpact.ogg', 25, TRUE, -1)
		victim.throw_at(turf_facing, 4, 1, user)

		sleep(1)

		partner.do_attack_animation(victim, ATTACK_EFFECT_PUNCH)
		atk_verb = pick("kick", "hit", "slam")
		victim.visible_message("<span class='danger'>[partner] [atk_verb]s [victim] with such inhuman strength that it sends [victim.p_them()] flying backwards!</span>", \
						"<span class='userdanger'>You're [atk_verb]ed by [partner] with such inhuman strength that it sends you flying backwards!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", null, user)
		to_chat(partner, "<span class='danger'>You [atk_verb] [victim] with such inhuman strength that it sends [victim.p_them()] flying backwards!</span>")
		victim.apply_damage(rand(20,30) * damage_mod, user.get_attack_type())
		playsound(get_turf(victim), 'sound/effects/meteorimpact.ogg', 25, TRUE, -1)
		var/throwtarget = get_edge_target_turf(partner, get_dir(partner, get_step_away(victim, partner)))
		victim.throw_at(throwtarget, 6, 2, partner)
		victim.Paralyze(60)
		victim.SetSleeping(120)
		victim.adjustOrganLoss(ORGAN_SLOT_BRAIN, 15, 150)
		return TRUE
	return FALSE

/datum/martial_art/duet/proc/beatdown(mob/living/user, mob/living/victim)
	if(!can_use(user))
		return FALSE

	playsound(get_turf(victim), 'sound/weapons/cqchit2.ogg', 50, TRUE, -1)
	victim.visible_message("<span class='danger'>[user] slams [victim] into the ground!</span>", \
					"<span class='userdanger'>You're slammed into the ground by [user]!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", COMBAT_MESSAGE_RANGE, user)
	to_chat(user, "<span class='danger'>You slam [victim] into the ground!</span>")
	victim.apply_damage(rand(20,25), user.get_attack_type())
	victim.apply_status_effect(STATUS_EFFECT_BEATDOWN)
	victim.Stun(1 SECONDS)
	return TRUE

/datum/martial_art/duet/proc/unleash_fury(mob/living/user, mob/living/victim)
	if(!can_use(user))
		return FALSE

	user.do_attack_animation(victim, ATTACK_EFFECT_PUNCH)
	var/atk_verb = pick("kick", "hit", "slam")
	victim.visible_message("<span class='danger'>[user] [atk_verb]s [victim] with such inhuman strength that it sends [victim.p_them()] flying backwards!</span>", \
					"<span class='userdanger'>You're [atk_verb]ed by [user] with such inhuman strength that it sends you flying backwards!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", null, user)
	to_chat(user, "<span class='danger'>You [atk_verb] [victim] with such inhuman strength that it sends [victim.p_them()] flying backwards!</span>")
	playsound(get_turf(victim), 'sound/effects/meteorimpact.ogg', 25, TRUE, -1)
	var/throwtarget = get_edge_target_turf(user, get_dir(user, get_step_away(victim, user)))

	var/turf/target_turf = get_turf(user)
	for(var/i = 1 to 3)
		target_turf = get_step(target_turf, get_dir(user, victim))

	new /obj/effect/temp_visual/ying_yang/detonator(target_turf, max(1, min(4, 4 * (8 SECONDS / (world.time - time_streak[LAZYLEN(time_streak) - LAZYLEN(MARTIAL_DUET_FURY)])))), victim, get_dir(user, victim), src)

	victim.throw_at(throwtarget, 6, 2, user)
	victim.Paralyze(60)

	return TRUE

/datum/martial_art/duet/proc/double_kick(mob/living/user, mob/living/victim)
	if(!can_use(user))
		return FALSE

	playsound(get_turf(victim), 'sound/weapons/cqchit1.ogg', 50, TRUE, -1)
	victim.visible_message("<span class='danger'>[user] kicks [victim] square in the chest!</span>", \
					"<span class='userdanger'>You're kicked square in the chest by [user]!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", COMBAT_MESSAGE_RANGE, user)
	to_chat(user, "<span class='danger'>You kick [victim] square in the chest!</span>")
	victim.apply_damage(rand(10,20), user.get_attack_type(), BODY_ZONE_CHEST)
	victim.apply_damage(rand(30,50), STAMINA)
	if(victim.losebreath <= 5)
		victim.losebreath = max(victim.losebreath + 3, 5)

	return TRUE

/mob/living/proc/duet_help()
	set name = "Remember The Basics"
	set desc = "You try to remember some of the basics of Dual martial arts."
	set category = "Duality"
	to_chat(usr, "<b><i>You try to remember some of the basics of Dual martial arts. (Partner-Something means that this action should be performed by your partner)</i></b>")

	to_chat(usr, "<span class='notice'>Double Kick: Partner-Grab Harm Harm. Deals some damage and stamina damage. This is your main offencive move.</span>")
	to_chat(usr, "<span class='notice'>Flowing Energy</span>: Grab Disarm Partner-Harm Partner-Grab Disarm Harm. Kicks your opponent with inhuman strength, knocking them out as a result. Full efficiency only can be reached if you and your partner are standing together") //It's fucking HARD
	to_chat(usr, "<span class='notice'>Beatdown</span>: Disarm Partner-Harm, Grab Partner-Disarm Harm. Slams your opponent into the ground for 3 seconds. Attacking them will regenerate your stamina.")
	to_chat(usr, "<span class='notice'>Unleash Fury</span>: Harm Harm Partner-Disarm Grab Partner-Harm Harm Partner-Grab Harm. Launches your opponent through a bunch of rings, damaging them and healing you and your partner. The faster combo is performed, the higher amount of rings is..")

	to_chat(usr, "<b><i>In addition, by having your throw mode on when being attacked, you enter an active defense mode where you have a small chance(much higher in Back To Back stance) to block and sometimes even counter attacks done to you.</i></b>")

/obj/effect/temp_visual/ying_yang
	name = "odd sigil"
	icon = 'icons/effects/effects.dmi'
	icon_state = "duet_full"
	layer = LOW_SIGIL_LAYER
	duration = -1

	var/datum/martial_art/duet/parent_art

/obj/effect/temp_visual/ying_yang/big
	icon = 'icons/effects/96x96.dmi'
	duration = MARTIAL_DUET_CHARGE_DURATION * 3
	alpha = 0
	pixel_x = -32
	pixel_y = -32

	var/leaving_mark = TRUE //Do we leave a smaller ying yang sigil upon deletion?

/obj/effect/temp_visual/ying_yang/big/Initialize(mapload, duration = MARTIAL_DUET_CHARGE_DURATION * 3)
	. = ..()
	src.duration = duration
	var/matrix/new_transform = matrix()
	new_transform = new_transform.Scale(1/3)
	animate(src, alpha = 255, transform = new_transform, time = duration)

/obj/effect/temp_visual/ying_yang/proc/detonate()
	var/matrix/new_transform = matrix()
	new_transform = new_transform.Scale(2)
	new_transform = new_transform.Turn(-180)
	animate(src, alpha = 0, transform = new_transform, time = 1 SECONDS)
	parent_art.ying_yang = null
	QDEL_IN(src, 1 SECONDS)

/obj/effect/temp_visual/ying_yang/big/detonate()
	leaving_mark = FALSE
	. = ..()

/obj/effect/temp_visual/ying_yang/big/Destroy()
	if(leaving_mark)
		var/obj/effect/temp_visual/ying_yang/new_symbol = new(get_turf(src))
		parent_art.ying_yang = new_symbol
		new_symbol.icon_state = icon_state
	. = ..()

/obj/effect/temp_visual/ying_yang/detonator
	duration = 10 SECONDS
	alpha = 0
	var/detonators_left = 4
	var/mob/living/target
	var/launch_direction

/obj/effect/temp_visual/ying_yang/detonator/Initialize(mapload, detonators_left = 4, mob/living/victim, launch_direction, parent_art)
	. = ..()
	src.detonators_left = detonators_left
	target = victim
	AddElement(/datum/element/connect_loc, src, list(COMSIG_ATOM_ENTERED = .proc/on_entered))
	src.launch_direction = launch_direction
	src.parent_art = parent_art
	animate(src, alpha = 255, time = 3)

/obj/effect/temp_visual/ying_yang/detonator/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(!isliving(AM))
		return
	var/mob/living/victim = AM
	if(victim != target)
		return
	victim.apply_damage(20, BURN)
	var/mob/living/parent_mob = parent_art.owner
	var/mob/living/partner_mob = parent_art.partner
	var/throwtarget = get_edge_target_turf(src, launch_direction)
	victim.throw_at(throwtarget, 6, 2, parent_mob)
	playsound(get_turf(victim), 'sound/effects/meteorimpact.ogg', 25, TRUE, -1)
	parent_mob.apply_damage(-10, BRUTE) //Small heal each detonation, up to 50 brute and burn if ideally executed
	parent_mob.apply_damage(-10, BURN)
	partner_mob.apply_damage(-10, BRUTE)
	partner_mob.apply_damage(-10, BURN)
	if(detonators_left >= 0)
		var/turf/target_turf = get_turf(src)
		for(var/i = 1 to 3)
			target_turf = get_step(target_turf, launch_direction)
			if(isclosedturf(target_turf))
				detonate()
				return

		if(!isclosedturf(target_turf))
			new /obj/effect/temp_visual/ying_yang/detonator(target_turf, detonators_left - 1, victim, launch_direction, parent_art)
	detonate()

/obj/effect/temp_visual/duet
	name = "odd symbol"
	icon_state = "duet"
	duration = 11.5

/obj/effect/temp_visual/duet/Initialize()
	. = ..()
	pixel_x = rand(-12, 12)
	pixel_y = rand(-9, 0)

#undef MARTIAL_DUET_STANCE_COOLDOWN
#undef MARTIAL_DUET_DISTANCE
#undef MARTIAL_DUET_CHARGE_DURATION
#undef MARTIAL_DUET_AOE_RANGE

#undef MARTIAL_DUET_FLOWING_ENERGY
#undef MARTIAL_DUET_BEATDOWN
#undef MARTIAL_DUET_FURY
#undef MARTIAL_DUET_DOUBLE_KICK
