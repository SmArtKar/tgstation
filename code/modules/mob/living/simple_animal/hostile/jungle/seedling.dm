#define SEEDLING_STATE_NEUTRAL 0
#define SEEDLING_STATE_WARMUP 1
#define SEEDLING_STATE_ACTIVE 2
#define SEEDLING_STATE_RECOVERY 3

//A plant rooted in the ground that forfeits its melee attack in favor of ranged barrages.
//It will fire flurries of solar energy, and occasionally charge up a powerful blast that makes it vulnerable to attack.
/mob/living/simple_animal/hostile/jungle/seedling
	name = "seedling"
	desc = "This oversized, predatory flower conceals what can only be described as an organic energy cannon, and it will not die until its hidden vital organs are sliced out. \
		The concentrated streams of energy it sometimes produces require its full attention, attacking it during this time will prevent it from finishing its attack."
	icon = 'icons/mob/jungle/seedling.dmi'
	icon_state = "seedling"
	icon_living = "seedling"
	icon_dead = "seedling_dead"
	mob_biotypes = MOB_ORGANIC | MOB_PLANT
	maxHealth = 380
	health = 380
	melee_damage_lower = 30
	melee_damage_upper = 30
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -14
	base_pixel_y = -14
	minimum_distance = 3
	move_to_delay = 20
	vision_range = 5
	aggro_vision_range = 15
	ranged = TRUE
	ranged_cooldown_time = 10
	projectiletype = /obj/projectile/seedling
	projectilesound = 'sound/weapons/pierce.ogg'
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	move_resist = MOVE_FORCE_EXTREMELY_STRONG
	var/combatant_state = SEEDLING_STATE_NEUTRAL
	loot = list(/obj/item/organ/regenerative_core/legion/shining_core)
	crusher_loot = /obj/item/crusher_trophy/tail_spike/seedling_petal
	var/mob/living/beam_debuff_target
	var/solar_beam_identifier = 0

/obj/projectile/seedling
	name = "solar energy"
	icon_state = "seedling"
	damage = 10
	damage_type = BURN
	light_range = 2
	flag = ENERGY
	light_color = LIGHT_COLOR_YELLOW
	hitsound = 'sound/weapons/sear.ogg'
	hitsound_wall = 'sound/weapons/effects/searwall.ogg'
	nondirectional_sprite = TRUE

/obj/projectile/seedling/Bump(atom/A)//Stops seedlings from destroying other jungle mobs through FF
	if(isliving(A))
		var/mob/living/L = A
		if("jungle" in L.faction)
			return FALSE
	return ..()

/obj/effect/temp_visual/solarbeam_killsat
	name = "beam of solar energy"
	icon_state = "solar_beam"
	icon = 'icons/effects/beam.dmi'
	plane = LIGHTING_PLANE
	duration = 5
	randomdir = FALSE

/datum/status_effect/seedling_beam_indicator
	id = "seedling beam indicator"
	duration = 30
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null
	tick_interval = 1
	var/atom/movable/screen/seedling/seedling_screen_object
	var/atom/target


/datum/status_effect/seedling_beam_indicator/on_creation(mob/living/new_owner, target_plant)
	. = ..()
	if(.)
		target = target_plant
		tick()

/datum/status_effect/seedling_beam_indicator/on_apply()
	if(owner.client)
		seedling_screen_object = new /atom/movable/screen/seedling()
		owner.client.screen += seedling_screen_object
	tick()
	return ..()

/datum/status_effect/seedling_beam_indicator/Destroy()
	if(owner)
		if(owner.client)
			owner.client.screen -= seedling_screen_object
	return ..()

/datum/status_effect/seedling_beam_indicator/tick()
	var/target_angle = get_angle(owner, target)
	var/matrix/final = matrix()
	final.Turn(target_angle)
	seedling_screen_object.transform = final

/atom/movable/screen/seedling
	icon = 'icons/mob/jungle/seedling.dmi'
	icon_state = "seedling_beam_indicator"
	screen_loc = "CENTER:-16,CENTER:-16"

/mob/living/simple_animal/hostile/jungle/seedling/Goto()
	if(combatant_state != SEEDLING_STATE_NEUTRAL)
		return
	return ..()

/mob/living/simple_animal/hostile/jungle/seedling/AttackingTarget()
	if(isliving(target))
		if(ranged_cooldown <= world.time && combatant_state == SEEDLING_STATE_NEUTRAL)
			OpenFire(target)
		return
	return ..()

/mob/living/simple_animal/hostile/jungle/seedling/OpenFire()
	WarmupAttack()

/mob/living/simple_animal/hostile/jungle/seedling/proc/WarmupAttack()
	if(combatant_state == SEEDLING_STATE_NEUTRAL)
		combatant_state = SEEDLING_STATE_WARMUP
		walk(src,0)
		update_icons()
		var/target_dist = get_dist(src,target)
		var/living_target_check = isliving(target)
		if(living_target_check)
			if(target_dist > 7)//Offscreen check
				SolarBeamStartup(target)
				return
			if(get_dist(src,target) >= 4 && prob(40))
				SolarBeamStartup(target)
				return
		addtimer(CALLBACK(src, .proc/Volley), 5)

/mob/living/simple_animal/hostile/jungle/seedling/proc/SolarBeamStartup(mob/living/living_target)//It's more like requiem than final spark
	if(combatant_state == SEEDLING_STATE_WARMUP && target)
		combatant_state = SEEDLING_STATE_ACTIVE
		living_target.apply_status_effect(/datum/status_effect/seedling_beam_indicator, src)
		beam_debuff_target = living_target
		playsound(src,'sound/effects/seedling_chargeup.ogg', 100, FALSE)
		if(get_dist(src,living_target) > 7)
			playsound(living_target,'sound/effects/seedling_chargeup.ogg', 100, FALSE)
		solar_beam_identifier = world.time
		addtimer(CALLBACK(src, .proc/Beamu, living_target, solar_beam_identifier), 35)

/mob/living/simple_animal/hostile/jungle/seedling/proc/Beamu(mob/living/living_target, beam_id = 0)
	if(combatant_state == SEEDLING_STATE_ACTIVE && living_target && beam_id == solar_beam_identifier)
		if(living_target.z == z || get_dist(src, living_target) <= aggro_vision_range)
			update_icons()
			var/obj/effect/temp_visual/solarbeam_killsat/S = new (get_turf(src))
			var/matrix/starting = matrix()
			starting.Scale(1,32)
			starting.Translate(0,520)
			S.transform = starting
			var/obj/effect/temp_visual/solarbeam_killsat/K = new (get_turf(living_target))
			var/matrix/final = matrix()
			final.Scale(1,32)
			final.Translate(0,512)
			K.transform = final
			living_target.adjustFireLoss(30)
			living_target.adjust_fire_stacks(0.2)//Just here for the showmanship
			living_target.IgniteMob()
			playsound(living_target,'sound/weapons/sear.ogg', 50, TRUE)
			addtimer(CALLBACK(src, .proc/AttackRecovery), 5)
			return
	AttackRecovery()

/mob/living/simple_animal/hostile/jungle/seedling/proc/Volley()
	if(combatant_state == SEEDLING_STATE_WARMUP && target)
		combatant_state = SEEDLING_STATE_ACTIVE
		update_icons()
		var/datum/callback/cb = CALLBACK(src, .proc/InaccurateShot)
		for(var/i in 1 to 7)
			addtimer(cb, i)
		addtimer(CALLBACK(src, .proc/AttackRecovery), 14)

/mob/living/simple_animal/hostile/jungle/seedling/proc/InaccurateShot()
	if(!QDELETED(target) && combatant_state == SEEDLING_STATE_ACTIVE && !stat)
		if(get_dist(src,target) <= 3)//If they're close enough just aim straight at them so we don't miss at point blank ranges
			Shoot(target)
			return
		var/turf/our_turf = get_turf(src)
		var/obj/projectile/seedling/readied_shot = new /obj/projectile/seedling(our_turf)
		readied_shot.preparePixelProjectile(target, src, null, rand(-10, 10))
		readied_shot.fire()
		playsound(src, projectilesound, 100, TRUE)

/mob/living/simple_animal/hostile/jungle/seedling/proc/AttackRecovery()
	if(combatant_state == SEEDLING_STATE_ACTIVE)
		combatant_state = SEEDLING_STATE_RECOVERY
		update_icons()
		ranged_cooldown = world.time + ranged_cooldown_time
		if(target)
			face_atom(target)
		addtimer(CALLBACK(src, .proc/ResetNeutral), 10)

/mob/living/simple_animal/hostile/jungle/seedling/proc/ResetNeutral()
	combatant_state = SEEDLING_STATE_NEUTRAL
	if(target && !stat)
		update_icons()
		Goto(target, move_to_delay, minimum_distance)

/mob/living/simple_animal/hostile/jungle/seedling/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(combatant_state == SEEDLING_STATE_ACTIVE && beam_debuff_target)
		beam_debuff_target.remove_status_effect(/datum/status_effect/seedling_beam_indicator)
		beam_debuff_target = null
		solar_beam_identifier = 0
		AttackRecovery()

/mob/living/simple_animal/hostile/jungle/seedling/update_icons()
	. = ..()
	if(!stat)
		switch(combatant_state)
			if(SEEDLING_STATE_NEUTRAL)
				icon_state = "seedling"
			if(SEEDLING_STATE_WARMUP)
				icon_state = "seedling_charging"
			if(SEEDLING_STATE_ACTIVE)
				icon_state = "seedling_fire"
			if(SEEDLING_STATE_RECOVERY)
				icon_state = "seedling"

/mob/living/simple_animal/hostile/jungle/seedling/GiveTarget()
	if(target)
		if(combatant_state == SEEDLING_STATE_WARMUP || combatant_state == SEEDLING_STATE_ACTIVE)//So it doesn't 180 and blast you in the face while it's firing at someone else
			return
	return ..()

/mob/living/simple_animal/hostile/jungle/seedling/LoseTarget()
	if(combatant_state == SEEDLING_STATE_WARMUP || combatant_state == SEEDLING_STATE_ACTIVE)
		return
	return ..()

/obj/item/organ/regenerative_core/legion/shining_core
	name = "shining core"
	desc = "A shining core of some dead seedling. Rumors say that these core can heal and stim you, providing a combat boost. It will quickly decay if not preserved."
	icon_state = "sun_core"

/obj/item/organ/regenerative_core/legion/shining_core/go_inert()
	..()
	name = "decayed shining core"
	desc = "A shining core of some dead seedling. This one is decayed for too long and became useless."

/obj/item/organ/regenerative_core/legion/shining_core/preserved(implanted = 0)
	. = ..()
	desc = "A shining core of some dead seedling. Rumors say that these core can heal and stim you, providing a combat boost. It's been preserved and won't decay."

/obj/item/organ/regenerative_core/legion/shining_core/applyto(atom/target, mob/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(inert)
			to_chat(user, "<span class='notice'>[src] has decayed and can no longer be used to heal.</span>")
			return
		else
			if(H.stat == DEAD)
				to_chat(user, "<span class='notice'>[src] is useless on the dead.</span>")
				return

			if(H != user)
				H.visible_message("<span class='notice'>[user] applies [src] to [H]'s skin, smearing the oozing liquid into their skin.</span>")
				SSblackbox.record_feedback("nested tally", "shining_core", 1, list("[type]", "used", "other"))
			else
				to_chat(user, "<span class='notice'>You start to smear liquid from [src]'s insides on yourself. Sudden feeling of power floods your mind, but gosh, it burns like hell!</span>")
				SSblackbox.record_feedback("nested tally", "shining_core", 1, list("[type]", "used", "self"))

			H.apply_status_effect(STATUS_EFFECT_SUN_CORE)
			SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "core", /datum/mood_event/healsbadman)
			playsound(H, 'sound/magic/staff_healing.ogg', 20, TRUE)
			new /obj/effect/temp_visual/seedling_sparks(get_turf(H))
			qdel(src)

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

/obj/effect/temp_visual/seedling_sparks
	icon = 'icons/effects/effects.dmi'
	icon_state = "seedling_sparks"
	light_range = LIGHT_RANGE_FIRE
	light_color = LIGHT_COLOR_FIRE
	duration = 12

#undef SEEDLING_STATE_NEUTRAL
#undef SEEDLING_STATE_WARMUP
#undef SEEDLING_STATE_ACTIVE
#undef SEEDLING_STATE_RECOVERY
