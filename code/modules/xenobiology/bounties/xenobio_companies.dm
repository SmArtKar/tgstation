//Each company has their own specialisation and is focused on one or two branches of xenobio gene tree. Most of them represent one of the departaments(or subdepartaments) and manufacture gear related to it.

/datum/xenobio_company
	var/name = "Coderbus Inc."
	var/desc = "Something went wrong and you'd better report it to us!"
	var/icon = "bug"

	var/relationship_level = 1 //Dating sims all over again
	var/bounties_finished = 0
	var/illegal = FALSE //If this company only shows up on emag
	var/contract_type

/datum/xenobio_company/proc/get_bounties_by_level(bounty_level = 1)
	return list(new /datum/xenobio_bounty(src), new /datum/xenobio_bounty(src))

/datum/xenobio_company/xynergy //Xenobiology
	name = "Xynergy Solutions"
	desc = "Xynergy Solutions is a newly founded company that focuses on alien life and DNA manipulation. They offer a wide variety of products ranging from vacuum pack upgrades to stasis containers for xenofauna."
	icon = "globe"
	relationship_level = 2

/datum/xenobio_company/morpheus //Mining
	name = "Morpheus Inc"
	desc = "Morpheus Incorporated is the leading company in the world of heavy mining operations. They can provide you and your station's miners with the best equipment out there."
	icon = "hammer"

/datum/xenobio_company/frontier //Science
	name = "The Frontier"
	desc = "Frontier is a somewhat small unionised research organisation focused on plasma research. NanoTrasen usually doesn't work with unions, but these guys have too much valuable research to ignore them."
	icon = "flask"

/datum/xenobio_company/nakamura //Engineering
	name = "Nakamura Engineering"
	desc = "Nakamura Engineering are well-known for their MODsuits and engineering tools. If your supermatter crystal explodes you can bet these guys can offer you a solution."
	icon = "magnet"

/datum/xenobio_company/deforest //Medical
	name = "DeForest Medical Corporation"
	desc = "DeForest Medical Corporation have a unique technology of hyposprays which allowed them to monopolise medical market. They've also probably produced all of your medbay's equipment."
	icon = "briefcase-medical"

/datum/xenobio_company/honk //Service
	name = "Honk.org"
	desc = "Honk.org initially started as an NTnet forum but gradually evolved into a full-blown company and started producing service goods. Just don't let them get their hands on any bananium."
	icon = "award"

/datum/xenobio_company/damocles //Security
	name = "Damocles Solutions"
	desc = "While technically being a private military organisation, Damocles Solutions also produces a variety of security-related goods, mainly focusing on automated security robots."
	icon = "battery-half"

/datum/xenobio_company/lexury //Command
	name = "Le Xury Corporated"
	desc = "Le Xury Corporated produces only the finest, comfortable and most extravagant goods for the heads of staff on any space station."
	icon = "paw"

/datum/xenobio_company/haul //Cargo
	name = "Haul-Y"
	desc = "Haul-Y is the leading company in terms of hauling tools, bots and workplace revolutions. We suggest you ignore their union propaganda and promises of \"fair pays\"."
	icon = "id-card"

/datum/xenobio_company/cybersun //Syndicate
	name = "Cybersun Industries"
	desc = "Cybersun Industries is a widely-known illegal corporation that's part of The Syndicate. They manufacture all kinds of different illegal technologies, armor and weaponery."
	icon = "sun"
	illegal = TRUE
