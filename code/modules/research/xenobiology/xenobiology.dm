////Slime-derived potions///

/**
* #Slime potions
*
* Feed slimes potions either by hand or using the slime console.
*
* Slime potions either augment the slime's behavior, its extract output, or its intelligence. These all come either from extract effects or cross cores.
* A few of the more powerful ones can modify someone's equipment or gender.
* New ones should probably be accessible only through cross cores as all the normal core types already have uses. Rule of thumb is 'stronger effects go in cross cores'.
*/

/obj/item/slimepotion
	name = "slime potion"
	desc = "A hard yet gelatinous capsule excreted by a slime, containing mysterious substances."
	w_class = WEIGHT_CLASS_TINY

/obj/item/slimepotion/afterattack(obj/item/reagent_containers/target, mob/user , proximity)
	. = ..()
	if(!proximity)
		return
	if (istype(target))
		to_chat(user, span_warning("You cannot transfer [src] to [target]! It appears the potion must be given directly to a slime to absorb.") )
		return

/obj/item/slimepotion/slime/docility
	name = "docility potion"
	desc = "A potent chemical mix that nullifies a slime's hunger, causing it to become docile and tame."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potsilver"

/obj/item/slimepotion/slime/docility/attack(mob/living/simple_animal/slime/M, mob/user)
	if(!isslime(M))
		to_chat(user, span_warning("The potion only works on slimes!"))
		return ..()
	if(M.stat)
		to_chat(user, span_warning("The slime is dead!"))
		return
	if(M.rabid) //Stops being rabid, but doesn't become truly docile.
		to_chat(M, span_warning("You absorb the potion, and your rabid hunger finally settles to a normal desire to feed."))
		to_chat(user, span_notice("You feed the slime the potion, calming its rabid rage."))
		M.rabid = FALSE
		qdel(src)
		return
	M.docile = 1
	M.set_nutrition(700)
	to_chat(M, span_warning("You absorb the potion and feel your intense desire to feed melt away."))
	to_chat(user, span_notice("You feed the slime the potion, removing its hunger and calming it."))
	var/newname = sanitize_name(tgui_input_text(user, "Would you like to give the slime a name?", "Name your new pet", "Pet Slime", MAX_NAME_LEN))

	if (!newname)
		newname = "Pet Slime"
	M.name = newname
	M.real_name = newname
	qdel(src)

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
		..()

/obj/item/slimepotion/slime/sentience/proc/after_success(mob/living/user, mob/living/smart_mob)
	return

/obj/item/slimepotion/slime/sentience/nuclear
	name = "syndicate intelligence potion"
	desc = "A miraculous chemical mix that grants human like intelligence to living beings. It has been modified with Syndicate technology to also grant an internal radio implant to the target and authenticate with identification systems."

/obj/item/slimepotion/slime/sentience/nuclear/after_success(mob/living/user, mob/living/smart_mob)
	var/obj/item/implant/radio/syndicate/imp = new(src)
	imp.implant(smart_mob, user)
	smart_mob.AddComponent(/datum/component/simple_access, list(ACCESS_SYNDICATE, ACCESS_MAINT_TUNNELS))

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
		var/mob/living/simple_animal/switchy_animal= switchy_mob
		switchy_animal.sentience_act()

/obj/item/slimepotion/slime/steroid
	name = "slime steroid"
	desc = "A potent chemical mix that will cause a baby slime to generate more extract."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potred"

/obj/item/slimepotion/slime/steroid/attack(mob/living/simple_animal/slime/M, mob/user)
	if(!isslime(M))//If target is not a slime.
		to_chat(user, span_warning("The steroid only works on baby slimes!"))
		return ..()
	if(M.is_adult) //Can't steroidify adults
		to_chat(user, span_warning("Only baby slimes can use the steroid!"))
		return
	if(M.stat)
		to_chat(user, span_warning("The slime is dead!"))
		return
	if(M.cores >= 5)
		to_chat(user, span_warning("The slime already has the maximum amount of extract!"))
		return

	to_chat(user, span_notice("You feed the slime the steroid. It will now produce one more extract."))
	M.cores++
	qdel(src)

/obj/item/slimepotion/enhancer
	name = "extract enhancer"
	desc = "A potent chemical mix that will give a slime extract an additional use."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potpurple"

/obj/item/slimepotion/slime/stabilizer
	name = "slime stabilizer"
	desc = "A potent chemical mix that will reduce the chance of a slime mutating."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potcyan"

/obj/item/slimepotion/slime/stabilizer/attack(mob/living/simple_animal/slime/M, mob/user)
	if(!isslime(M))
		to_chat(user, span_warning("The stabilizer only works on slimes!"))
		return ..()
	if(M.stat)
		to_chat(user, span_warning("The slime is dead!"))
		return
	if(M.mutation_chance == 0)
		to_chat(user, span_warning("The slime already has no chance of mutating!"))
		return

	to_chat(user, span_notice("You feed the slime the stabilizer. It is now less likely to mutate."))
	M.mutation_chance = clamp(M.mutation_chance-15,0,100)
	qdel(src)

/obj/item/slimepotion/slime/mutator
	name = "slime mutator"
	desc = "A potent chemical mix that will increase the chance of a slime mutating."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potgreen"

/obj/item/slimepotion/slime/mutator/attack(mob/living/simple_animal/slime/M, mob/user)
	if(!isslime(M))
		to_chat(user, span_warning("The mutator only works on slimes!"))
		return ..()
	if(M.stat)
		to_chat(user, span_warning("The slime is dead!"))
		return
	if(M.mutator_used)
		to_chat(user, span_warning("This slime has already consumed a mutator, any more would be far too unstable!"))
		return
	if(M.mutation_chance == 100)
		to_chat(user, span_warning("The slime is already guaranteed to mutate!"))
		return

	to_chat(user, span_notice("You feed the slime the mutator. It is now more likely to mutate."))
	M.mutation_chance = clamp(M.mutation_chance+12,0,100)
	M.mutator_used = TRUE
	qdel(src)

/obj/item/slimepotion/speed
	name = "slime speed potion"
	desc = "A potent chemical mix that will remove the slowdown from any item."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potyellow"

/obj/item/slimepotion/speed/afterattack(obj/C, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(!istype(C))
		to_chat(user, span_warning("The potion can only be used on objects!"))
		return
	if(SEND_SIGNAL(C, COMSIG_SPEED_POTION_APPLIED, src, user) & SPEED_POTION_STOP)
		return
	if(isitem(C))
		var/obj/item/I = C
		if(I.slowdown <= 0 || I.obj_flags & IMMUTABLE_SLOW)
			to_chat(user, span_warning("The [C] can't be made any faster!"))
			return ..()
		I.slowdown = 0

	to_chat(user, span_notice("You slather the red gunk over the [C], making it faster."))
	C.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
	C.add_atom_colour("#FF0000", FIXED_COLOUR_PRIORITY)
	qdel(src)

/obj/item/slimepotion/speed/attackby_storage_insert(datum/component/storage, atom/storage_holder, mob/user)
	if(!isitem(storage_holder))
		return TRUE
	if(istype(storage_holder, /obj/item/mod/control))
		var/obj/item/mod/control/mod = storage_holder
		return mod.slowdown_inactive <= 0
	var/obj/item/storage_item = storage_holder
	return storage_item.slowdown <= 0

/obj/item/slimepotion/fireproof
	name = "slime chill potion"
	desc = "A potent chemical mix that will fireproof any article of clothing. Has three uses."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potblue"
	resistance_flags = FIRE_PROOF
	var/uses = 3

/obj/item/slimepotion/fireproof/afterattack(obj/item/clothing/C, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(!uses)
		qdel(src)
		return
	if(!istype(C))
		to_chat(user, span_warning("The potion can only be used on clothing!"))
		return
	if(C.max_heat_protection_temperature >= FIRE_IMMUNITY_MAX_TEMP_PROTECT)
		to_chat(user, span_warning("The [C] is already fireproof!"))
		return
	to_chat(user, span_notice("You slather the blue gunk over the [C], fireproofing it."))
	C.name = "fireproofed [C.name]"
	C.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
	C.add_atom_colour("#000080", FIXED_COLOUR_PRIORITY)
	C.max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	C.heat_protection = C.body_parts_covered
	C.resistance_flags |= FIRE_PROOF
	uses --
	if(!uses)
		qdel(src)

/obj/item/slimepotion/genderchange
	name = "gender change potion"
	desc = "An interesting chemical mix that changes the biological gender of what its applied to. Cannot be used on things that lack gender entirely."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potlightpink"

/obj/item/slimepotion/genderchange/attack(mob/living/L, mob/user)
	if(!istype(L) || L.stat == DEAD)
		to_chat(user, span_warning("The potion can only be used on living things!"))
		return

	if(L.gender != MALE && L.gender != FEMALE)
		to_chat(user, span_warning("The potion can only be used on gendered things!"))
		return

	if(L.gender == MALE)
		L.gender = FEMALE
		L.visible_message(span_boldnotice("[L] suddenly looks more feminine!"), span_boldwarning("You suddenly feel more feminine!"))
	else
		L.gender = MALE
		L.visible_message(span_boldnotice("[L] suddenly looks more masculine!"), span_boldwarning("You suddenly feel more masculine!"))
	L.regenerate_icons()
	qdel(src)

/obj/item/slimepotion/slime/renaming
	name = "renaming potion"
	desc = "A potion that allows a self-aware being to change what name it subconciously presents to the world."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potgreen"

	var/being_used = FALSE

/obj/item/slimepotion/slime/renaming/attack(mob/living/M, mob/user)
	if(being_used || !ismob(M))
		return
	if(!M.ckey) //only works on animals that aren't player controlled
		to_chat(user, span_warning("[M] is not self aware, and cannot pick its own name."))
		return

	being_used = TRUE

	to_chat(user, span_notice("You offer [src] to [user]..."))

	var/new_name = sanitize_name(tgui_input_text(M, "What would you like your name to be?", "Input a name", M.real_name, MAX_NAME_LEN))

	if(!new_name || QDELETED(src) || QDELETED(M) || new_name == M.real_name || !M.Adjacent(user))
		being_used = FALSE
		return

	M.visible_message(span_notice("[span_name("[M]")] has a new name, [span_name("[new_name]")]."), span_notice("Your old name of [span_name("[M.real_name]")] fades away, and your new name [span_name("[new_name]")] anchors itself in your mind."))
	message_admins("[ADMIN_LOOKUPFLW(user)] used [src] on [ADMIN_LOOKUPFLW(M)], letting them rename themselves into [new_name].")
	log_game("[key_name(user)] used [src] on [key_name(M)], letting them rename themselves into [new_name].")

	// pass null as first arg to not update records or ID/PDA
	M.fully_replace_character_name(null, new_name)

	qdel(src)

/obj/item/slimepotion/slime/slimeradio
	name = "bluespace radio potion"
	desc = "A strange chemical that grants those who ingest it the ability to broadcast and receive subscape radio waves."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potgrey"

/obj/item/slimepotion/slime/slimeradio/attack(mob/living/M, mob/user)
	if(!ismob(M))
		return
	if(!isanimal(M))
		to_chat(user, span_warning("[M] is too complex for the potion!"))
		return
	if(M.stat)
		to_chat(user, span_warning("[M] is dead!"))
		return

	to_chat(user, span_notice("You feed the potion to [M]."))
	to_chat(M, span_notice("Your mind tingles as you are fed the potion. You can hear radio waves now!"))
	var/obj/item/implant/radio/slime/imp = new(src)
	imp.implant(M, user)
	qdel(src)

///Definitions for slime products that don't have anywhere else to go (Floor tiles, blueprints).

/obj/item/stack/tile/bluespace
	name = "bluespace floor tile"
	singular_name = "floor tile"
	desc = "Through a series of micro-teleports these tiles let people move at incredible speeds."
	icon_state = "tile_bluespace"
	inhand_icon_state = "tile-bluespace"
	w_class = WEIGHT_CLASS_NORMAL
	force = 6
	mats_per_unit = list(/datum/material/iron=500)
	throwforce = 10
	throw_speed = 3
	throw_range = 7
	flags_1 = CONDUCT_1
	max_amount = 60
	turf_type = /turf/open/floor/bluespace
	merge_type = /obj/item/stack/tile/bluespace

/obj/item/stack/tile/sepia
	name = "sepia floor tile"
	singular_name = "floor tile"
	desc = "Time seems to flow very slowly around these tiles."
	icon_state = "tile_sepia"
	inhand_icon_state = "tile-sepia"
	w_class = WEIGHT_CLASS_NORMAL
	force = 6
	mats_per_unit = list(/datum/material/iron=500)
	throwforce = 10
	throw_speed = 0.1
	throw_range = 28
	flags_1 = CONDUCT_1
	max_amount = 60
	turf_type = /turf/open/floor/sepia
	merge_type = /obj/item/stack/tile/sepia

/obj/item/areaeditor/blueprints/slime
	name = "cerulean prints"
	desc = "A one use yet of blueprints made of jelly like organic material. Extends the reach of the management console."
	color = "#2956B2"

/obj/item/areaeditor/blueprints/slime/edit_area()
	..()
	var/area/A = get_area(src)
	for(var/turf/T in A)
		T.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
		T.add_atom_colour("#2956B2", FIXED_COLOUR_PRIORITY)
	A.area_flags |= XENOBIOLOGY_COMPATIBLE
	qdel(src)
