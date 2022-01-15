/mob/living/simple_animal/hostile/guardian/spacetime //This is supposed to be exclusive to bluespace spirit loot
	combat_mode = FALSE
	friendly_verb_continuous = "quietly assesses"
	friendly_verb_simple = "quietly assess"
	melee_damage_lower = 15
	melee_damage_upper = 15
	damage_coeff = list(BRUTE = 0.75, BURN = 0.75, TOX = 0.75, CLONE = 0.75, STAMINA = 0, OXY = 0.75)
	ranged_cooldown_time = 20
	ranged = 1
	range = 13
	playstyle_string = "<span class='holoparasite'>As a <b>space-time</b> type, you have medium armor and are able to perform a variety of different attacks and abilities. Use toggle mode button to enter bluespace mode in which you can't attack, but also can't be attacked. You can still cast abilities in that form, but their damage is significantly lowered.</span>"
	magic_fluff_string = "<span class='holoparasite'>..And draw the Chrono Legionnaire, the master of unknown.</span>"
	tech_fluff_string = "<span class='holoparasite'>Boot sequence complete. Bluespace combat modules active. Holoparasite swarm online.</span>"
	carp_fluff_string = "<span class='holoparasite'>CARP CARP CARP! Caught one, it's a bluespace carp. This fishy can manipulate space-time!</span>"
	miner_fluff_string = "<span class='holoparasite'>You encounter... Bluespace, a master of space and time.</span>"
	see_invisible = SEE_INVISIBLE_LIVING
	see_in_dark = 8
	toggle_button_type = /atom/movable/screen/guardian/toggle_mode
	var/toggle = FALSE

/mob/living/simple_animal/hostile/guardian/spacetime/ToggleLight()
	var/msg
	switch(lighting_alpha)
		if (LIGHTING_PLANE_ALPHA_VISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
			msg = "You activate your night vision."
		if (LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
			msg = "You increase your night vision."
		if (LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_INVISIBLE
			msg = "You maximize your night vision."
		else
			lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
			msg = "You deactivate your night vision."

	to_chat(src, span_notice("[msg]"))

/mob/living/simple_animal/hostile/guardian/spacetime/ToggleMode()
	if(loc == summoner)
		if(toggle)
			melee_damage_lower = initial(melee_damage_lower)
			melee_damage_upper = initial(melee_damage_upper)
			obj_damage = initial(obj_damage)
			environment_smash = initial(environment_smash)
			pass_flags &= ~(PASSCLOSEDTURF | PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSTABLE | PASSMOB | PASSDOORS | PASSVEHICLE)
			alpha = 255
			color = "#ffffff"
			density = TRUE
			to_chat(src, "[span_danger("<B>You switch to combat mode.")]</B>")
			toggle = FALSE
		else
			melee_damage_lower = 0
			melee_damage_upper = 0
			obj_damage = 0
			environment_smash = ENVIRONMENT_SMASH_NONE
			alpha = 125
			density = FALSE
			color = "#4794ff"
			pass_flags |= PASSCLOSEDTURF | PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSTABLE | PASSMOB | PASSDOORS | PASSVEHICLE
			to_chat(src, "[span_danger("<B>You switch to bluespace mode.")]</B>")
			toggle = TRUE
	else
		to_chat(src, "[span_danger("<B>You have to be recalled to toggle modes!")]</B>")

/mob/living/simple_animal/hostile/guardian/spacetime/OpenFire(atom/A)
	if(ranged_cooldown < world.time)
		ranged_cooldown = world.time + ranged_cooldown_time
		Shoot(A)

/mob/living/simple_animal/hostile/guardian/spacetime/Shoot(atom/targeted_atom)
	for(var/turf/target_turf in range(1, get_turf(targeted_atom)))
		new /obj/effect/temp_visual/bluespace_blast_warning(target_turf, src)
		SLEEP_CHECK_DEATH(1, src)

/obj/effect/temp_visual/bluespace_blast_warning
	name = "bluespace blast warning"
	icon_state = "bluespace_blast_warning"
	duration = 4
	light_range = 1
	light_power = 0.5
	light_color = COLOR_BLUE_LIGHT
	var/mob/living/author

/obj/effect/temp_visual/bluespace_blast_warning/Initialize(mapload, creator)
	. = ..()
	author = creator

/obj/effect/temp_visual/bluespace_blast_warning/Destroy()
	new /obj/effect/temp_visual/bluespace_blast(get_turf(src), author)
	. = ..()

/obj/effect/temp_visual/bluespace_blast
	name = "bluespace blast"
	icon_state = "bluespace_blast"
	duration = 5
	light_range = 2
	light_power = 0.5
	light_color = COLOR_BLUE_LIGHT

/obj/effect/temp_visual/bluespace_blast/Initialize(mapload, mob/living/author)
	. = ..()
	var/turf/my_turf = get_turf(src)
	if(!locate(/mob/living) in my_turf)
		return

	playsound(src, 'sound/magic/mm_hit.ogg', 100, TRUE)
	for(var/mob/living/target in my_turf)
		if(target == author)
			continue
		var/damage = 1
		if(isguardian(author))
			var/mob/living/simple_animal/hostile/guardian/spacetime/guardian = author
			if(guardian.summoner)
				if(target == guardian.summoner)
					continue
			if(guardian.toggle)
				damage *= 0.5

		if(!isanimal(target))
			damage *= 0.5
		target.adjustFireLoss(20 * damage)
		to_chat(target, span_userdanger("You're hit by a bluespace blast!"))

/mob/living/simple_animal/hostile/guardian/spacetime/ranged_secondary_attack(atom/target, modifiers)
	if(ranged_cooldown > world.time)
		return

	ranged_cooldown = world.time + 15 SECONDS
	new /obj/effect/temp_visual/bluespace_collapse/nodamage(get_turf(target))
	SLEEP_CHECK_DEATH(7, src)
	new /obj/effect/temp_visual/chronoexplosion(get_turf(target))
	playsound(get_turf(target), 'sound/magic/lightningbolt.ogg', 50, TRUE)
	for(var/mob/living/victim in range(1, get_turf(target)))
		if(victim == src)
			continue
		if(summoner)
			if(victim == summoner)
				continue
		var/damage_mod = 1
		if(!isanimal(victim))
			damage_mod *= 0.5
		if(toggle)
			damage_mod *= 0.5
		if(victim in get_turf(target))
			to_chat(victim, span_userdanger("Bluespace collapses around, crushing you!"))
			victim.adjustBruteLoss(60 * damage_mod)
		else
			to_chat(victim, span_userdanger("The tremors from the bluespace collapse landing sends you flying!"))
			var/fly_away_direction = get_dir(src, victim)
			victim.throw_at(get_edge_target_turf(victim, fly_away_direction), 4, 2)
			victim.adjustBruteLoss(30 * damage_mod)
