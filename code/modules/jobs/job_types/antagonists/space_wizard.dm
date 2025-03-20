/datum/job/space_wizard
	title = ROLE_WIZARD
	faction = ROLE_WIZARD

	attributes = list(
		/datum/attribute/intellect = 4,
		/datum/attribute/psyche = 0,
		/datum/attribute/physique = 3,
		/datum/attribute/motorics = 2,
	)

/datum/job/space_wizard/get_roundstart_spawn_point()
	return pick(GLOB.wizardstart)

/datum/job/space_wizard/get_latejoin_spawn_point()
	return pick(GLOB.wizardstart)
