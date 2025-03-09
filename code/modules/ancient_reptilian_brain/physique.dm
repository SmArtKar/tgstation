// Physique: throw punches, break through doors, don't die

/datum/attribute/physique
	name = "Physique"
	desc = "Your musculature, how strong you are. How well your body is built."
	color = "#d13b3b"

// Aspects

// Melee brawling skill
/datum/aspect/half_light
	name = "Half Light"
	desc = "Let the body take control. Threaten people."
	attribute = /datum/attribute/physique

// How well you handle damage, each level gives max HP and negates some damage slowdown
/datum/aspect/endurance
	name = "Endurance"
	desc = "Shrug off the pain. They'll have to hurt you more."
	attribute = /datum/attribute/physique

/datum/aspect/endurance/update_effects(prev_level)
	var/mob/living/owner = get_body()
	owner.maxHealth += (get_level() - prev_level) * ENDURANCE_HEALTH_BOOST
