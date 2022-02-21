/datum/xenobio_bounty
	var/name = "Broken xenobio bounty"

	var/requirements = list()
	var/text_requirements = list()
	var/rewards = list()
	var/text_rewards = list()

	var/datum/xenobio_company/author
	var/bounty_level = 1

/datum/xenobio_bounty/New(datum/xenobio_company/author)
	. = ..()
	src.author = author
