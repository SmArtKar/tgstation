/datum/job/nuclear_operative
	title = ROLE_NUCLEAR_OPERATIVE

	attributes = list(
		/datum/attribute/intellect = 1,
		/datum/attribute/psyche = 0,
		/datum/attribute/physique = 4,
		/datum/attribute/motorics = 4,
	)

/datum/job/nuclear_operative/get_roundstart_spawn_point()
	return pick(GLOB.nukeop_start)

/datum/job/nuclear_operative/get_latejoin_spawn_point()
	return pick(GLOB.nukeop_start)
