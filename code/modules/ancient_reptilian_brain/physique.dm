// Physique: throw punches, break through doors, don't die

/datum/attribute/physique
	name = "Physique"
	desc = "Your musculature, how strong you are. How well your body is built."
	color = "#d13b3b"

// Aspects

// Melee brawling skill
/datum/aspect/half_light // todo: additonal effects?
	name = "Half Light"
	desc = "Let the body take control. Threaten people."
	attribute = /datum/attribute/physique

/datum/aspect/half_light/update_effects(prev_level)
	var/mob/living/owner = get_body()
	if (get_level() >= HALF_LIGHT_TACKLER_LEVEL)
		owner.AddComponentFrom(REF(src), /datum/component/tackler, stamina_cost = 25, base_knockdown = 1 SECONDS, range = 4, speed = 1, skill_mod = 1, min_distance = 0)
	else
		owner.RemoveComponentSource(REF(src), /datum/component/tackler)

/datum/aspect/half_light/unregister_body(mob/living/old_body)
	. = ..()
	old_body.RemoveComponentSource(REF(src), /datum/component/tackler)

// How well you handle damage, each level gives max HP and negates some damage slowdown
// Had to mix endurance and pain threshold together for this one
/datum/aspect/endurance // todo: additonal effects?
	name = "Endurance"
	desc = "Shrug off the pain. They'll have to hurt you more."
	attribute = /datum/attribute/physique

/datum/aspect/endurance/update_effects(prev_level)
	var/mob/living/owner = get_body()
	if (!isnull(prev_level))
		owner.maxHealth -= (prev_level - ASPECT_LEVEL_NEUTRAL) * ENDURANCE_HEALTH_BOOST
	owner.maxHealth += (get_level() - ASPECT_LEVEL_NEUTRAL) * ENDURANCE_HEALTH_BOOST
	if (get_level() >= ENDURANCE_ANALGESIA_LEVEL)
		ADD_TRAIT(owner, TRAIT_ANALGESIA, ASPECT_TRAIT)
	else
		REMOVE_TRAIT(owner, TRAIT_ANALGESIA, ASPECT_TRAIT)

/datum/aspect/endurance/unregister_body(mob/living/old_body)
	. = ..()
	old_body.maxHealth -= (get_level() - ASPECT_LEVEL_NEUTRAL) * ENDURANCE_HEALTH_BOOST
	REMOVE_TRAIT(old_body, TRAIT_ANALGESIA, ASPECT_TRAIT)

// Handling paranormal items, holy stuff
/datum/aspect/shivers
	name = "Shivers"
	desc = "Raise the hair on your neck. Tune in to the forces beyond this world."
	attribute = /datum/attribute/physique

/datum/aspect/shivers/update_effects(prev_level)
	var/mob/living/owner = get_body()
	if (get_level() >= SHIVERS_MAGIC_GIFT_LEVEL)
		ADD_TRAIT(owner, TRAIT_MAGICALLY_GIFTED, ASPECT_TRAIT)
	else
		REMOVE_TRAIT(owner, TRAIT_MAGICALLY_GIFTED, ASPECT_TRAIT)

/datum/aspect/shivers/unregister_body(mob/living/old_body)
	. = ..()
	REMOVE_TRAIT(old_body, TRAIT_MAGICALLY_GIFTED, ASPECT_TRAIT)

// Affects your metabolization and resistance to chemicals, positive and negative
/datum/aspect/electrochemistry
	name = "Electrochemistry"
	desc = "Go to party planet. Love and be loved by drugs."
	attribute = /datum/attribute/physique

// Unarmed damage, lifting/dragging heavy things, prying doors open with your bare hands. Also being a racist, for some reason.
/datum/aspect/physical_instrument // todo: additional effects?
	name = "Physical Instrument"
	desc = "Flex powerful muscles. Enjoy healthy organs."
	attribute = /datum/attribute/physique

/datum/aspect/physical_instrument/update_effects(prev_level)
	var/mob/living/owner = get_body()
	if (get_level() >= PHYSICAL_INSTRUMENT_DOORPRYER_LEVEL)
		owner.AddElement(/datum/element/door_pryer, pry_time = 5 SECONDS, interaction_key = PHYSICAL_INSTRUMENT_INTERACTION)
	else
		owner.RemoveElement(/datum/element/door_pryer, pry_time = 5 SECONDS, interaction_key = PHYSICAL_INSTRUMENT_INTERACTION)

/datum/aspect/physical_instrument/unregister_body(mob/living/old_body)
	. = ..()
	old_body.RemoveElement(/datum/element/door_pryer, pry_time = 5 SECONDS, interaction_key = PHYSICAL_INSTRUMENT_INTERACTION)

// How good are you at working with tools, may depend on hand-eye for precision stuff
/datum/aspect/handicraft
	name = "Handicraft"
	desc = "Work with your hands. Perform delicate procedures."
	attribute = /datum/attribute/physique
