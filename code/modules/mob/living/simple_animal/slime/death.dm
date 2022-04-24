/mob/living/simple_animal/slime/death(gibbed)
	if(stat == DEAD)
		return
	if(!gibbed)
		if(is_adult)
			var/mob/living/simple_animal/slime/M = new(drop_location(), slime_color.type)
			M.rabid = TRUE
			M.regenerate_icons()

			is_adult = FALSE
			maxHealth = 150
			for(var/datum/action/innate/slime/reproduce/R in actions)
				R.Remove(src)
			var/datum/action/innate/slime/evolve/E = new
			E.Grant(src)
			revive(full_heal = TRUE, admin_revive = FALSE)
			regenerate_icons()
			update_name()
			return

	if(buckled)
		Feedstop(silent = TRUE) //releases ourselves from the mob we fed on.

	set_stat(DEAD)
	regenerate_icons()
	for(var/mob/living/simple_animal/slime/slime in view(5, get_turf(src)))
		slime.adjust_mood(SLIME_MOOD_DEATH_LOSS)
		if(Target) //Likely our killer
			slime.add_friendship(Target, -1)
	stop_moveloop()
	return ..(gibbed)

/mob/living/simple_animal/slime/gib()
	death(TRUE)
	qdel(src)
