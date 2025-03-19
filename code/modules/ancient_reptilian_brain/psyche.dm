// Psyche: reading people, intimidation, paranormal effects

/datum/attribute/psyche
	name = "Psyche"
	desc = "Sensitivity, how emotionally intelligent you are. Your power to influence yourself and others."
	color = "#817aa6"

// Aspects

// Medical knowledge, ability to determine state that someone is in at a glance, patching people up with your bare hands
/datum/aspect/faveur_de_lame
	name = "Faveur de l'Âme"
	desc = "Feel the heartbeat, the rhytm of the soul. Revive the dead, and cure the living."
	attribute = /datum/attribute/psyche

// Looting maintenance, tiding departments, sort-of-hacking-related but in a weirder way
/datum/aspect/grey_tide // TODO: THIS
	name = "Grey Tide"
	desc = "Toolbelt, to store your tools. Toolbox, to apply to skulls."
	attribute = /datum/attribute/psyche

// Intimidating others, being more efficient in stun combat
/datum/aspect/command // TODO: THIS
	name = "Command"
	desc = "Intimidate the public. Assert yourself."
	attribute = /datum/attribute/psyche

// Gives you constant information about the state of your department and your colleagues
/datum/aspect/esprit_de_labos // TODO: THIS
	name = "Esprit de Labōs"
	desc = "Connect to your department. Understand the spacer culture."
	attribute = /datum/attribute/psyche

// Decreases effects of low sanity or negative moodlets, helps with addictions
/datum/aspect/morale
	name = "Morale"
	desc = "Hold yourself together. Keep your Sanity up."
	attribute = /datum/attribute/psyche

// See stuff that happened previously, useful for detectives or when you want to hunt someone down
/datum/aspect/rewind // TODO: THIS
	name = "Rewind"
	desc = "Move back in time, just a bit. Here, a drop of blood was spilled."
	attribute = /datum/attribute/psyche
