/**
 * This type is used to indicate a lack of a job.
 * The mind variable assigned_role will point here by default.
 * As any other job datum, this is a singleton.
 **/

/datum/job/unassigned
	title = "Unassigned Crewmember"
	rpg_title = "Peasant"
	paycheck = PAYCHECK_ZERO

	attributes = list(
		/datum/attribute/intellect = 1,
		/datum/attribute/psyche = 1,
		/datum/attribute/physique = 1,
		/datum/attribute/motorics = 1,
	)
