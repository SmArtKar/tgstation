/datum/action/cooldown/mob_cooldown/shockwave
	name = "Shockwave"
	desc = "Create a shockwave to throw everything away from you."
	icon_icon = 'icons/mob/actions/actions_jungle.dmi'
	button_icon_state = "shockwave"
	cooldown_time = 1.5 SECONDS

	/// How big the shockwave is, in tiles. Tile below the caster does not count
	var/shockwave_range = 3

	/// Delay between the shockwave circles
	var/iteration_duration = 2

/datum/action/cooldown/mob_cooldown/shockwave/New(Target, shockwave_range, iteration_duration)
	. = ..()

	if(shockwave_range)
		src.shockwave_range = shockwave_range

	if(iteration_duration)
		src.iteration_duration = iteration_duration

/datum/action/cooldown/mob_cooldown/shockwave/Activate(atom/target_atom)
	StartCooldown()
	owner.visible_message(span_boldwarning("[owner] smashes the ground around them!</span>"))
	playsound(owner, 'sound/weapons/sonic_jackhammer.ogg', 200, 1)
	var/list/hit_things = list()
	var/turf/start_turf = get_turf(owner)
	for(var/i in 1 to shockwave_range)
		for(var/turf/target_turf in (view(i, start_turf) - view(i - 1, start_turf)))
			if(!target_turf)
				return
			new /obj/effect/temp_visual/small_smoke/halfsecond/above_all(target_turf)
			for(var/mob/living/victim in target_turf)
				if(victim != owner && !(victim in hit_things) && !faction_check(victim.faction, owner.faction))
					var/throwtarget = get_edge_target_turf(target_turf, get_dir(start_turf, victim))
					victim.throw_at(throwtarget, 6 / i, 1, owner, gentle = TRUE) //Don't want stunlocking
					victim.apply_damage_type(20 / i, BRUTE)
					hit_things += victim
		SLEEP_CHECK_DEATH(iteration_duration, owner)
