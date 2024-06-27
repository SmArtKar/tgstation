/turf/closed
	layer = CLOSED_TURF_LAYER
	plane = WALL_PLANE
	turf_flags = IS_SOLID
	opacity = TRUE
	density = TRUE
	blocks_air = TRUE
	init_air = FALSE
	rad_insulation = RAD_MEDIUM_INSULATION
	pass_flags_self = PASSCLOSEDTURF

/turf/closed/AfterChange()
	. = ..()
	SSair.high_pressure_delta -= src

/turf/closed/get_smooth_underlay_icon(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	return FALSE

/turf/closed/bullet_act(obj/projectile/hitting_projectile, def_zone)
	. = ..()
	if(. != BULLET_ACT_HIT)
		return

	if(hitting_projectile.damage > 0 && (hitting_projectile.damage_type == BRUTE || hitting_projectile.damage_type == BURN) && prob(75))
		add_dent(WALL_DENT_SHOT, pixel_x + rand(-8, 8), pixel_y + rand(-8, 8))
