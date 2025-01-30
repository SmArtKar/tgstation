/// Dynamic threat tier datum, one of these is picked randomly roundstart as the threat tier for the round.
/datum/threat_tier
	// Name and description shown in the roundstart report
	var/name = "Hole in Reality"
	var/description = "A coder has messed with your sector, resulting in a broken threat tier. Report this."
	/// How likely is this threat tier to be picked, relative to the others
	var/weight = 0
	/// How many roundstart rulesets can get executed, list(min, max)
	var/roundstart_rulesets = list("min" = 0, "max" = 0)
	/// How many light midrounds can get executed, list(min, max)
	var/midround_rulesets = list("min" = 0, "max" = 0)
	/// How many heavy midrounds can get executed, list(min, max)
	var/heavy_midround_rulesets = list("min" = 0, "max" = 0)
	/// How many latejoin rulesets can get executed, list(min, max)
	var/latejoin_rulesets = list("min" = 0, "max" = 0)
	/// Can multiple high impact rulesets roll together?
	var/high_impact_stacking = FALSE

	/// Time before heavy midrounds can start rolling
	var/heavy_midround_delay = 0
	/// Minimum population required for this ruleset to be considered valid for the taking
	var/minimum_population = 0
	/// "Ideal" population for this ruleset, at which point the amount of rulesets it can execute is evenly weighted
	var/ideal_population = 0

/datum/threat_tier/zero
	name = "Sector Core"
	desc = "Your station is positioned in the core of the Spinward Sector. Surveillance information shows no credible threats to Nanotrasen assets within the area at this time. \
		As always, the Department of Intelligence advises maintaining vigilance against potential threats, regardless of a lack of known threats."
	weight = 3

/datum/threat_tier/one
	name = "Yellow Star"
	desc = "Your sector's advisory level is Yellow Star. Surveillance shows a credible risk of enemy attack against our assets in the Spinward Sector. \
		We advise a heightened level of security alongside maintaining vigilance against potential threats."

	weight = 8

	roundstart_rulesets = list("min" = 1, "max" = 1)
	midround_rulesets = list("min" = 1, "max" = 2)
	heavy_midround_rulesets = list("min" = 0, "max" = 1)
	latejoin_rulesets = list("min" = 1, "max" = 1)

	heavy_midround_delay = 60 MINUTES
	ideal_population = 20

/datum/threat_tier/two
	name = "Orange Star"
	desc = "Your sector's advisory level is Orange Star. Upon reviewing your sector's intelligence, the Department has determined that the risk of enemy activity is moderate to severe. \
		At this advisory, we recommend maintaining a higher degree of security and reviewing red alert protocols with command and the crew."

	weight = 22

	roundstart_rulesets = list("min" = 1, "max" = 2)
	midround_rulesets = list("min" = 1, "max" = 2)
	heavy_midround_rulesets = list("min" = 1, "max" = 1)
	latejoin_rulesets = list("min" = 1, "max" = 2)

	heavy_midround_delay = 60 MINUTES
	ideal_population = 25

/datum/threat_tier/three
	name = "Red Star"
	desc = "Your sector's advisory level is Red Star. The Department of Intelligence has decrypted Cybersun communications suggesting a high likelihood of attacks on Nanotrasen assets within the Spinward Sector. \
	Stations in the region are advised to remain highly vigilant for signs of enemy activity and to be on high alert."

	weight = 50

	roundstart_rulesets = list("min" = 2, "max" = 3)
	midround_rulesets = list("min" = 2, "max" = 3)
	heavy_midround_rulesets = list("min" = 0, "max" = 2)
	latejoin_rulesets = list("min" = 1, "max" = 3)

	heavy_midround_delay = 60 MINUTES
	ideal_population = 30

/datum/threat_tier/four
	name = "Black Orbit"
	desc = "Your sector's advisory level is Black Orbit. Your sector's local communications network is currently undergoing a blackout, and we are therefore unable to accurately judge enemy movements within the region. \
		However, information passed to us by GDI suggests a high amount of enemy activity in the sector, indicative of an impending attack. \
		Remain on high alert and vigilant against any other potential threats."
	weight = 15

	roundstart_rulesets = list("min" = 3, "max" = 4)
	midround_rulesets = list("min" = 1, "max" = 2)
	heavy_midround_rulesets = list("min" = 1, "max" = 2)
	latejoin_rulesets = list("min" = 2, "max" = 3)

	heavy_midround_delay = 30 MINUTES
	minimum_population = 25
	ideal_population = 35
	high_impact_stacking = TRUE

/datum/threat_tier/five
	name = "Midnight Sun"
	desc = "Your sector's advisory level is Midnight Sun. Credible information passed to us by GDI suggests that the Syndicate is preparing to mount a major concerted offensive on Nanotrasen assets in the Spinward Sector to cripple our foothold there. \
	All stations should remain on high alert and prepared to defend themselves."

	weight = 1

	roundstart_rulesets = list("min" = 3, "max" = 4)
	midround_rulesets = list("min" = 1, "max" = 2)
	heavy_midround_rulesets = list("min" = 2, "max" = 3)
	latejoin_rulesets = list("min" = 1, "max" = 2)

	heavy_midround_delay = 15 MINUTES
	minimum_population = 35
	ideal_population = 45
	high_impact_stacking = TRUE
