/obj/item/slime_potion
	name = "slime potion"
	desc = "A gelatinous flask with filled with a mysterious substance produced by a slime."
	icon = 'icons/obj/xenobiology/slime_extracts.dmi'

/obj/item/slime_potion/slime_steroid
	name = "slime steroid potion"
	desc = "A gelatinous flask with filled with a slime steroid that will make slimes produce more cores. This effect is somewhat inherited upon splitting."
	icon_state = "potion_steroid"

/obj/item/slime_potion/slime_steroid/attack(mob/living/simple_animal/slime/slime, mob/user)
	if(!isslime(slime))
		to_chat(user, span_warning("[src] only works on slimes!"))
		return ..()

	if(slime.stat == DEAD)
		to_chat(user, span_warning("[slime] is dead!"))
		return

	if(slime.max_cores >= 5)
		to_chat(user, span_warning("[slime]'s core can't split anymore!"))
		return

	to_chat(user, span_notice("You feed [slime] [src]. It will now produce one more extract."))
	slime.max_cores++
	qdel(src)

/obj/item/slime_potion/slime_stabilizer
	name = "slime stabilizer potion"
	desc = "A gelatinous flask with filled with a slime stabilizer that will lower slime's mutation chance."
	icon_state = "potion_stabilizer"

/obj/item/slime_potion/slime_stabilizer/attack(mob/living/simple_animal/slime/slime, mob/user)
	if(!isslime(slime))
		to_chat(user, span_warning("[src] only works on slimes!"))
		return ..()

	if(slime.stat == DEAD)
		to_chat(user, span_warning("[slime] is dead!"))
		return

	if(slime.mutation_chance == 0)
		to_chat(user, span_warning("[slime] already has no chance of mutating!"))
		return

	to_chat(user, span_notice("You feed [slime] [src]]. It is now less likely to mutate."))
	slime.mutation_chance = clamp(slime.mutation_chance - 15, 0, 100)
	new /obj/effect/temp_visual/arrow_down(get_turf(slime))
	qdel(src)

/obj/item/slime_potion/slime_destabilizer
	name = "slime destabilizer potion"
	desc = "A gelatinous flask with filled with a slime destabilizer that will increase slime's mutation chance."
	icon_state = "potion_destabilizer"

/obj/item/slime_potion/slime_stabilizer/attack(mob/living/simple_animal/slime/slime, mob/user)
	if(!isslime(slime))
		to_chat(user, span_warning("[src] only works on slimes!"))
		return ..()

	if(slime.stat == DEAD)
		to_chat(user, span_warning("[slime] is dead!"))
		return

	if(slime.mutation_chance == 100)
		to_chat(user, span_warning("[slime] already has maximum chance of mutating!"))
		return

	to_chat(user, span_notice("You feed [slime] [src]]. It is now more likely to mutate."))
	slime.mutation_chance = clamp(slime.mutation_chance + 15, 0, 100)
	new /obj/effect/temp_visual/arrow_up(get_turf(slime))
	qdel(src)

/obj/item/slimepotion/transference
	name = "consciousness transference potion"
	desc = "A strange slime-based chemical that, when used, allows the user to transfer their consciousness to a lesser being."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potorange"
	var/prompted = 0
	var/animal_type = SENTIENCE_ORGANIC

/obj/item/slimepotion/transference/afterattack(mob/living/switchy_mob, mob/living/user, proximity)
	if(!proximity)
		return

	if(prompted || !ismob(switchy_mob))
		return

	if(!(isanimal(switchy_mob) || isbasicmob(switchy_mob))|| switchy_mob.ckey) //much like sentience, these will not work on something that is already player controlled
		to_chat(user, span_warning("[switchy_mob] already has a higher consciousness!"))
		return ..()

	if(switchy_mob.stat)
		to_chat(user, span_warning("[switchy_mob] is dead!"))
		return ..()

	if(isanimal(switchy_mob))
		var/mob/living/simple_animal/switchy_animal= switchy_mob
		if(switchy_animal.sentience_type != animal_type)
			to_chat(user, span_warning("You cannot transfer your consciousness to [switchy_animal].") )
			return ..()
	else	//ugly code duplication, but necccesary as sentience_type is implemented twice.
		var/mob/living/basic/basic_mob = switchy_mob
		if(basic_mob.sentience_type != animal_type)
			to_chat(user, span_warning("You cannot transfer your consciousness to [basic_mob].") )
			return ..()

	var/job_banned = is_banned_from(user.ckey, ROLE_MIND_TRANSFER)
	if(QDELETED(src) || QDELETED(switchy_mob) || QDELETED(user))
		return

	if(job_banned)
		to_chat(user, span_warning("Your mind goes blank as you attempt to use the potion."))
		return

	prompted = 1
	if(tgui_alert(usr,"This will permanently transfer your consciousness to [switchy_mob]. Are you sure you want to do this?",,list("Yes","No"))=="No")
		prompted = 0
		return

	to_chat(user, span_notice("You drink the potion then place your hands on [switchy_mob]..."))

	user.mind.transfer_to(switchy_mob)
	switchy_mob.faction = user.faction.Copy()
	user.death()
	to_chat(switchy_mob, span_notice("In a quick flash, you feel your consciousness flow into [switchy_mob]!"))
	to_chat(switchy_mob, span_warning("You are now [switchy_mob]. Your allegiances, alliances, and role is still the same as it was prior to consciousness transfer!"))
	switchy_mob.name = "[user.real_name]"
	qdel(src)

	if(isanimal(switchy_mob))
		var/mob/living/simple_animal/switchy_animal = switchy_mob
		switchy_animal.sentience_act()

/obj/item/slimepotion/slime/sentience
	name = "intelligence potion"
	desc = "A miraculous chemical mix that grants human like intelligence to living beings."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potpink"
	var/list/not_interested = list()
	var/being_used = FALSE
	var/sentience_type = SENTIENCE_ORGANIC

/obj/item/slimepotion/slime/sentience/attack(mob/living/dumb_mob, mob/user)
	if(being_used || !ismob(dumb_mob))
		return

	if((!isanimal(dumb_mob) && !isbasicmob(dumb_mob)) || dumb_mob.ckey) //only works on animals that aren't player controlled
		to_chat(user, span_warning("[dumb_mob] is already too intelligent for this to work!"))
		return

	if(dumb_mob.stat)
		to_chat(user, span_warning("[dumb_mob] is dead!"))
		return

	if(isanimal(dumb_mob))
		var/mob/living/simple_animal/dumb_animal = dumb_mob
		if(dumb_animal.sentience_type != sentience_type)
			to_chat(user, span_warning("[src] won't work on [dumb_animal]."))
			return

	else if(isbasicmob(dumb_mob)) //duplicate shit code until all simple animasls are made into basic mobs. sentience_type is not on living, but it duplicated  on basic and animal
		var/mob/living/basic/basic_dumb_bitch = dumb_mob
		if(basic_dumb_bitch.sentience_type != sentience_type)
			to_chat(user, span_warning("[src] won't work on [basic_dumb_bitch]."))
			return

	to_chat(user, span_notice("You offer [src] to [dumb_mob]..."))
	being_used = TRUE

	var/list/candidates = poll_candidates_for_mob("Do you want to play as [dumb_mob.name]?", ROLE_SENTIENCE, ROLE_SENTIENCE, 5 SECONDS, dumb_mob, POLL_IGNORE_SENTIENCE_POTION) // see poll_ignore.dm
	if(LAZYLEN(candidates))
		var/mob/dead/observer/C = pick(candidates)
		dumb_mob.key = C.key
		dumb_mob.mind.enslave_mind_to_creator(user)
		SEND_SIGNAL(dumb_mob, COMSIG_SIMPLEMOB_SENTIENCEPOTION, user)
		if(isanimal(dumb_mob))
			var/mob/living/simple_animal/smart_animal = dumb_mob
			smart_animal.sentience_act()
		to_chat(dumb_mob, span_warning("All at once it makes sense: you know what you are and who you are! Self awareness is yours!"))
		to_chat(dumb_mob, span_userdanger("You are grateful to be self aware and owe [user.real_name] a great debt. Serve [user.real_name], and assist [user.p_them()] in completing [user.p_their()] goals at any cost."))
		if(dumb_mob.flags_1 & HOLOGRAM_1) //Check to see if it's a holodeck creature
			to_chat(dumb_mob, span_userdanger("You also become depressingly aware that you are not a real creature, but instead a holoform. Your existence is limited to the parameters of the holodeck."))
		to_chat(user, span_notice("[dumb_mob] accepts [src] and suddenly becomes attentive and aware. It worked!"))
		dumb_mob.copy_languages(user)
		after_success(user, dumb_mob)
		qdel(src)
	else
		to_chat(user, span_notice("[dumb_mob] looks interested for a moment, but then looks back down. Maybe you should try again later."))
		being_used = FALSE
		return ..()

/obj/item/slimepotion/slime/sentience/proc/after_success(mob/living/user, mob/living/smart_mob)
	return

/obj/item/slimepotion/slime/sentience/nuclear
	name = "syndicate intelligence potion"
	desc = "A miraculous chemical mix that grants human like intelligence to living beings. It has been modified with Syndicate technology to also grant an internal radio implant to the target and authenticate with identification systems."

/obj/item/slimepotion/slime/sentience/nuclear/after_success(mob/living/user, mob/living/smart_mob)
	var/obj/item/implant/radio/syndicate/imp = new(src)
	imp.implant(smart_mob, user)
	smart_mob.AddComponent(/datum/component/simple_access, list(ACCESS_SYNDICATE, ACCESS_MAINT_TUNNELS))
