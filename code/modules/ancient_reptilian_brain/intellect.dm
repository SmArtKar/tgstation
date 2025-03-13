// Intellect: Nerd stuff, wire knowledge, etc.

/datum/attribute/intellect
	name = "Intellect"
	desc = "Raw brain power, how smart you are. Your capacity to reason."
	color = "#5f84b8"

// Aspects

// Random bullshit trivia, go
/datum/aspect/encyclopedia
	name = "Encyclopedia"
	desc = "Call upon all your knowledge. Produce fascinating trivia."
	attribute = /datum/attribute/intellect

// RND knowledge, xenobio, circuits
/datum/aspect/cognition
	name = "Cognition"
	desc = "Solve the mysteries of the Universe. Deduce the world."
	attribute = /datum/attribute/intellect

// Engineering knowledge related to machinery, atmos and construction (not hacking)
/datum/aspect/mental_clockwork
	name = "Mental Clockwork"
	desc = "Repair malfunctions. Construct your magnum opus out of scrap."
	attribute = /datum/attribute/intellect

// Knowledge related to robotics, implants, mechs, etc.
/datum/aspect/four_legged_wheelbarrel
	name = "Four Legged Wheelbarrel"
	desc = "Construct cyborgs. Be angry about nobody wanting MODsuits."
	attribute = /datum/attribute/intellect

/datum/aspect/four_legged_wheelbarrel/New(datum/attribute/new_attribute)
	. = ..()
	if (prob(25))
		var/list/owner_name = splittext(attribute.owner.name, regex("\[ -\]"))
		desc += " Get in the goddamn mech, [owner_name[1]]."
