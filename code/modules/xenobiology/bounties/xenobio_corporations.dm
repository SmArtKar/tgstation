//Each company has their own specialisation and is focused on one or two branches of xenobio gene tree. Most of them represent one of the departaments(or subdepartaments) and manufacture gear related to it.

/datum/xenobio_corporation
	var/name = "Coderbus Inc."
	var/desc = "Something went wrong and you'd better report it to us!"
	var/icon = "bug"

	var/relationship_level = 1 //Dating sims all over again
	var/bounties_finished = 0
	var/illegal = FALSE //If this company only shows up on emag
	var/bounty_type = /datum/xenobio_bounty

	var/list/bounties_by_level = list()

/datum/xenobio_corporation/proc/get_bounties_by_level(bounty_level = 1)
	if(bounty_level in bounties_by_level)
		return bounties_by_level[bounty_level]

	var/list/bounties_to_return = list()
	for(var/bounty_subtype in subtypesof(bounty_type))
		var/datum/xenobio_bounty/bounty = bounty_subtype
		if(initial(bounty.bounty_level) != bounty_level)
			continue
		bounties_to_return.Add(new bounty_subtype(src))
	bounties_by_level[bounty_level] = bounties_to_return
	return bounties_to_return
