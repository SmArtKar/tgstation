/obj/effect/abstract/creepy_effect
	icon = 'icons/effects/mapping_helpers.dmi'
	var/datum/proximity_monitor/detector
	var/range = 5
	var/activation_chance = 5
	var/list/former_victims = list() // One trigger per person, so you can't unbolt a bolted door by running around it

/obj/effect/abstract/creepy_effect/Initialize(mapload)
	. = ..()
	detector = new(loc, range)

/obj/effect/abstract/creepy_effect/HasProximity(atom/movable/other)
	if (prob(activation_chance) && !former_victims[other])
		former_victims[other] = TRUE
		trigger(other)

/obj/effect/abstract/creepy_effect/proc/trigger(atom/movable/other)
	return

/obj/effect/abstract/creepy_effect/bolts
	icon_state = "bolt_from_move"

/obj/effect/abstract/creepy_effect/bolts/trigger(atom/movable/other)
	for (var/obj/machinery/door/airlock/airlock in loc)
		if (airlock.locked)
			airlock.unbolt()
		else
			airlock.bolt()

/obj/effect/abstract/creepy_effect/flicker
	icon_state = "flick_from_move"

/obj/effect/abstract/creepy_effect/flicker/trigger(atom/movable/other)
	playsound(loc, 'sound/effects/light_flicker.ogg', 50, FALSE)
	for (var/obj/machinery/light/lights in loc)
		INVOKE_ASYNC(lights, TYPE_PROC_REF(/obj/machinery/light, flicker), rand(3, 5), rand(1, 3))
