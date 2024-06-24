PROCESSING_SUBSYSTEM_DEF(projectiles)
	name = "Projectiles"
	wait = 1
	stat_tag = "PP"
	flags = SS_NO_INIT|SS_TICKER
	// These are kept as variables so they are editable from adminbus panel in case of lag issues.
	/// Cap on amount of times a projectile can move each tick
	/// This would prevent projectiles teleporting each lag spike since they move based on time delta, not ticks
	var/global_max_tick_moves = 16
	/// How many pixels does a projectile pass each iteration. Increasing this would help with performance but may cause them to pass through tiles if shot at their edge
	var/global_pixel_speed = 2

/datum/controller/subsystem/processing/projectiles/proc/set_pixel_speed(new_speed)
	global_pixel_speed = new_speed
	for(var/obj/projectileP in processing)
		P.set_pixel_speed(new_speed)

/datum/controller/subsystem/processing/projectiles/vv_edit_var(var_name, var_value)
	switch(var_name)
		if(NAMEOF(src, global_pixel_speed))
			set_pixel_speed(var_value)
			return TRUE
		else
			return ..()
