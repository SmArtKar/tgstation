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
// Had to mix endurance and pain threshold together for this one
/datum/aspect/endurance
	name = "Endurance"
	desc = "Shrug off the pain. They'll have to hurt you more."
	attribute = /datum/attribute/physique

/datum/aspect/endurance/update_effects(prev_level)
	var/mob/living/owner = get_body()
	if (!isnull(prev_level))
		owner.maxHealth -= (prev_level - ASPECT_NEUTRAL_LEVEL) * ENDURANCE_HEALTH_BOOST
	owner.maxHealth += (get_level() - ASPECT_NEUTRAL_LEVEL) * ENDURANCE_HEALTH_BOOST
	if (get_level() >= ENDURANCE_ANALGESIA_LEVEL)
		ADD_TRAIT(owner, TRAIT_ANALGESIA, ASPECT_TRAIT)

/datum/aspect/endurance/unregister_body(mob/living/old_body)
	old_body.maxHealth -= (get_level() - ASPECT_NEUTRAL_LEVEL) * ENDURANCE_HEALTH_BOOST
	REMOVE_TRAIT(old_body, TRAIT_ANALGESIA, ASPECT_TRAIT)

// Handling paranormal items, holy stuff
/datum/aspect/shivers
	name = "Shivers"
	desc = "Raise the hair on your neck. Tune in to the forces beyond this world."
	attribute = /datum/attribute/physique

// Affects your metabolization and resistance to chemicals, positive and negative
/datum/aspect/electrochemistry
	name = "Electrochemistry"
	desc = "Go to party planet. Love and be loved by drugs."
	attribute = /datum/attribute/physique

// Unarmed damage, lifting/dragging heavy things, prying doors open with your bare hands. Also being a racist, for some reason.
/datum/aspect/physical_instrument
	name = "Physical Instrument"
	desc = "Flex powerful muscles. Enjoy healthy organs."
	attribute = /datum/attribute/physique

// How good are you with working heavy tools, also provides buffs to hand-eye for more precise ones
/datum/aspect/handicraft
	name = "Handicraft"
	desc = "Work with your hands. Lift heavy equipment."
	attribute = /datum/attribute/physique
