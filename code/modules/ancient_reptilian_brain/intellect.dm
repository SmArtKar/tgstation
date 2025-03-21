// Intellect: Nerd stuff, wire knowledge, etc.

/datum/attribute/intellect
	name = "Intellect"
	desc = "Raw brain power, how smart you are. Your capacity to reason."
	color = "#5f84b8"

// Aspects

// Random bullshit trivia, go
/datum/aspect/erudition
	name = "Erudition"
	desc = "Call upon all your knowledge. Produce fascinating trivia."
	attribute = /datum/attribute/intellect

// RND knowledge, xenobio, circuits
/datum/aspect/cognition // TODO: THIS but more effects
	name = "Cognition"
	desc = "Solve the mysteries of the Universe. Deduce the world."
	attribute = /datum/attribute/intellect

// Engineering knowledge related to machinery, atmos and construction (not hacking)
/datum/aspect/mental_clockwork
	name = "Mental Clockwork"
	desc = "Repair malfunctions. Construct your magnum opus out of scrap."
	attribute = /datum/attribute/intellect

// Knowledge related to robotics, implants, mechs, etc.
/datum/aspect/four_legged_wheelbarrel // Kapu i know you're reading this, its not a typo
	name = "Four Legged Wheelbarrel"
	desc = "Create cyborgs. Turn yourself into one."
	attribute = /datum/attribute/intellect

/datum/aspect/four_legged_wheelbarrel/New(datum/attribute/new_attribute)
	. = ..()
	if (prob(15))
		desc += " Get in the mech, [first_name(attribute.owner.name)]."

// Social camouflage, neat tricks, be a better clown
/datum/aspect/acting // TODO: THIS
	name = "Acting"
	desc = "Lights, curtains, stage. Fool the world."
	attribute = /datum/attribute/intellect

// Handles everything under art and cuisine
/datum/aspect/impression // TODO: THIS
	name = "Impression"
	desc = "Understand creativity. See Art in the world."
	attribute = /datum/attribute/intellect
