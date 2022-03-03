/datum/xenobio_corporation/damocles
	name = "Damocles Solutions"
	desc = "While technically being a private military organisation, Damocles Solutions also produces a variety of security-related goods, mainly focusing on automated security robots."
	icon = "battery-half"

	bounty_type = /datum/xenobio_bounty/damocles

/datum/xenobio_bounty/damocles
	name = "Broken Damocles Solutions bounty"

/datum/xenobio_bounty/damocles/quasar
	name = "Experimental \"Quasar\" disabler rifle"
	desc = "If you can get us a powerful enough energy source we can create a disabler rifle heavy enough to stop anybody in a couple of shots."
	rewards = list(/obj/item/weaponcrafting/gunkit/quasar = 1)
	text_rewards = "Heavy disabler rifle parts kit"

	bounty_level = 4 //It's pretty powerful so we put it further down the list
	levels_per_bounty = 0.5
