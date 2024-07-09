
/obj/item/disk/holodisk
	name = "holorecord disk"
	desc = "Stores recorder holocalls."
	icon_state = "holodisk"
	obj_flags = UNIQUE_RENAME
	custom_materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	var/datum/holorecord/record
	//Preset variables
	var/preset_image_type
	var/preset_record_text

/obj/item/disk/holodisk/Initialize(mapload)
	. = ..()
	if(preset_record_text)
		INVOKE_ASYNC(src, PROC_REF(build_record))

/obj/item/disk/holodisk/Destroy()
	QDEL_NULL(record)
	return ..()

/obj/item/disk/holodisk/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if (!istype(interacting_with, /obj/item/disk/holodisk))
		return ..()

	var/obj/item/disk/holodisk/holodisk = interacting_with
	if (!holodisk.record)
		balloon_alert(user, "no record")
		return ITEM_INTERACT_BLOCKING

	record = new
	record.caller_name = holodisk.record.caller_name
	record.caller_image = holodisk.record.caller_image
	record.entries = holodisk.record.entries.Copy()
	record.language = holodisk.record.language
	name = holodisk.name
	balloon_alert(user, "copied the record")

/obj/item/disk/holodisk/proc/build_record()
	record = new
	var/list/lines = splittext(preset_record_text,"\n")
	for(var/line in lines)
		var/prepared_line = trim(line)
		if(!length(prepared_line))
			continue
		var/splitpoint = findtext(prepared_line," ")
		if(!splitpoint)
			continue
		var/command = copytext(prepared_line, 1, splitpoint)
		var/value = copytext(prepared_line, splitpoint + length(prepared_line[splitpoint]))
		switch(command)
			if("DELAY")
				var/delay_value = text2num(value)
				if(!delay_value)
					continue
				record.entries += list(list(HOLORECORD_DELAY,delay_value))
			if("NAME")
				if(!record.caller_name)
					record.caller_name = value
				else
					record.entries += list(list(HOLORECORD_RENAME,value))
			if("SAY")
				record.entries += list(list(HOLORECORD_SAY,value))
			if("SOUND")
				record.entries += list(list(HOLORECORD_SOUND,value))
			if("LANGUAGE")
				var/lang_type = text2path(value)
				if(ispath(lang_type,/datum/language))
					record.entries += list(list(HOLORECORD_LANGUAGE,lang_type))
			if("PRESET")
				var/preset_type = text2path(value)
				if(ispath(preset_type,/datum/preset_holoimage))
					record.entries += list(list(HOLORECORD_PRESET,preset_type))
	if(!preset_image_type)
		record.caller_image = image('icons/mob/simple/animal.dmi',"old")
	else
		var/datum/preset_holoimage/H = new preset_image_type
		record.caller_image = H.build_image()

/datum/holorecord
	var/caller_name = "Unknown" //Caller name
	var/image/caller_image
	var/list/entries = list()
	var/language = /datum/language/common //Initial language, can be changed by HOLORECORD_LANGUAGE entries

/datum/holorecord/proc/set_caller_image(mob/user)
	var/olddir = user.dir
	user.setDir(SOUTH)
	caller_image = image(user)
	user.setDir(olddir)

//These build caller image from outfit and some additional data, for use by mappers for ruin holorecords
/datum/preset_holoimage
	var/nonhuman_mobtype //Fill this if you just want something nonhuman
	var/outfit_type
	var/species_type = /datum/species/human

/datum/preset_holoimage/proc/build_image()
	if(nonhuman_mobtype)
		var/mob/living/L = nonhuman_mobtype
		. = image(initial(L.icon),initial(L.icon_state))
	else
		var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy("HOLODISK_PRESET")
		if(species_type)
			mannequin.set_species(species_type)
		if(outfit_type)
			mannequin.equipOutfit(outfit_type,TRUE)
		mannequin.setDir(SOUTH)
		. = image(mannequin)
		unset_busy_human_dummy("HOLODISK_PRESET")

/datum/preset_holoimage/clown
	outfit_type = /datum/outfit/job/clown

/datum/preset_holoimage/engineer
	outfit_type = /datum/outfit/job/engineer

/datum/preset_holoimage/corgi
	nonhuman_mobtype = /mob/living/basic/pet/dog/corgi

/datum/preset_holoimage/engineer/mod
	outfit_type = /datum/outfit/job/engineer/mod

/datum/preset_holoimage/engineer/ce
	outfit_type = /datum/outfit/job/ce

/datum/preset_holoimage/engineer/ce/mod
	outfit_type = /datum/outfit/job/ce/mod

/datum/preset_holoimage/engineer/atmos
	outfit_type = /datum/outfit/job/atmos

/datum/preset_holoimage/engineer/atmos/mod
	outfit_type = /datum/outfit/job/atmos/mod

/datum/preset_holoimage/researcher
	outfit_type = /datum/outfit/job/scientist

/datum/preset_holoimage/captain
	outfit_type = /datum/outfit/job/captain

/datum/preset_holoimage/nanotrasenprivatesecurity
	outfit_type = /datum/outfit/nanotrasensoldiercorpse

/datum/preset_holoimage/syndicatebattlecruisercaptain
	outfit_type = /datum/outfit/syndicate_empty/battlecruiser

/datum/preset_holoimage/hivebot
	nonhuman_mobtype = /mob/living/basic/hivebot

/datum/preset_holoimage/ai
	nonhuman_mobtype = /mob/living/silicon/ai

/datum/preset_holoimage/robot
	nonhuman_mobtype = /mob/living/silicon/robot

/datum/preset_holoimage/assistant
	outfit_type = /datum/outfit/job/assistant

/obj/item/disk/holodisk/example
	preset_image_type = /datum/preset_holoimage/clown
	preset_record_text = {"
	NAME Clown
	DELAY 10
	SAY Why did the chaplain cross the maint ?
	DELAY 20
	SAY He wanted to get to the other side!
	SOUND clownstep
	DELAY 30
	LANGUAGE /datum/language/narsie
	SAY Helped him get there!
	DELAY 10
	SAY ALSO IM SECRETLY A GORILLA
	DELAY 10
	PRESET /datum/preset_holoimage/gorilla
	NAME Gorilla
	LANGUAGE /datum/language/common
	SAY OOGA
	DELAY 20"}

/obj/item/disk/holodisk/donutstation/whiteship
	name = "Blackbox Print-out #DS024"
	desc = "A holodisk containing the last viable recording of DS024's blackbox."
	preset_image_type = /datum/preset_holoimage/engineer/ce
	preset_record_text = {"
	NAME Geysr Shorthalt
	SAY Engine renovations complete and the ships been loaded. We all ready?
	DELAY 25
	PRESET /datum/preset_holoimage/engineer
	NAME Jacob Ullman
	SAY Lets blow this popsicle stand of a station.
	DELAY 20
	PRESET /datum/preset_holoimage/engineer/atmos
	NAME Lindsey Cuffler
	SAY Uh, sir? Shouldn't we call for a secondary shuttle? The bluespace drive on this thing made an awfully weird noise when we jumped here..
	DELAY 30
	PRESET /datum/preset_holoimage/engineer/ce
	NAME Geysr Shorthalt
	SAY Pah! Ship techie at the dock said to give it a good few kicks if it started acting up, let me just..
	DELAY 25
	SOUND punch
	SOUND sparks
	DELAY 10
	SOUND punch
	SOUND sparks
	DELAY 10
	SOUND punch
	SOUND sparks
	SOUND warpspeed
	DELAY 15
	PRESET /datum/preset_holoimage/engineer/atmos
	NAME Lindsey Cuffler
	SAY Uhh.. is it supposed to be doing that??
	DELAY 15
	PRESET /datum/preset_holoimage/engineer/ce
	NAME Geysr Shorthalt
	SAY See? Working as intended. Now, are we all ready?
	DELAY 10
	PRESET /datum/preset_holoimage/engineer
	NAME Jacob Ullman
	SAY Is it supposed to be glowing like that?
	DELAY 20
	SOUND explosion

	"}

/obj/item/disk/holodisk/ruin/snowengieruin
	name = "Blackbox Print-out #EB412"
	desc = "A holodisk containing the last moments of EB412. There's a bloody fingerprint on it."
	preset_image_type = /datum/preset_holoimage/engineer
	preset_record_text = {"
	NAME Dave Tundrale
	SAY Maria, how's Build?
	DELAY 10
	NAME Maria Dell
	PRESET /datum/preset_holoimage/engineer/atmos
	SAY It's fine, don't worry. I've got Plastic on it. And frankly, i'm kinda busy with, the, uhhm, incinerator.
	DELAY 30
	NAME Dave Tundrale
	PRESET /datum/preset_holoimage/engineer
	SAY Aight, wonderful. The science mans been kinda shit though. No RCDs-
	DELAY 20
	NAME Maria Dell
	PRESET /datum/preset_holoimage/engineer/atmos
	SAY Enough about your RCDs. They're not even that important, just bui-
	DELAY 15
	SOUND explosion
	DELAY 10
	SAY Oh, shit!
	DELAY 10
	PRESET /datum/preset_holoimage/engineer/atmos/mod
	LANGUAGE /datum/language/narsie
	NAME Unknown
	SAY RISE, MY LORD!!
	DELAY 10
	LANGUAGE /datum/language/common
	NAME Plastic
	PRESET /datum/preset_holoimage/engineer/mod
	SAY Fuck, fuck, fuck!
	DELAY 20
	NAME Maria Dell
	PRESET /datum/preset_holoimage/engineer/atmos
	SAY GEORGE, WAIT-
	DELAY 10
	PRESET /datum/preset_holoimage/corgi
	NAME Blackbox Automated Message
	SAY Connection lost. Dumping audio logs to disk.
	DELAY 50"}

/obj/item/disk/holodisk/ruin/ghost_restaurant
	name = "Blackbox Print-out #NG234"
	preset_image_type = /datum/preset_holoimage/assistant
	preset_record_text = {"
	NAME Aron Blue
	SAY Message from NTGrub Themed Surprise Deliveries, Trademark.
	DELAY 20
	NAME Henry Fresh
	SAY Must you always say the full name, dude?
	DELAY 20
	NAME Aron Blue
	SAY Ahem!
	DELAY 20
	NAME Aron Blue
	SAY It says that they loved our new robot themes!
	DELAY 20
	NAME Henry Fresh
	SAY Oh dang!
	DELAY 20
	NAME Henry Fresh
	SAY Will we be moved to the main team?
	DELAY 20
	NAME Aron Blue
	SAY Hell yeah we will! High five!
	DELAY 20
	SOUND punch
	NAME Henry Fresh
	SAY High five!
	DELAY 20
	NAME Henry Fresh
	SAY Oh, new order. Its for, hah, *Funny Food*.
	DELAY 20
	NAME Aron Blue
	SAY Easy!
	DELAY 20
	NAME Aron Blue
	SAY I will dress up this robot as a clown.
	DELAY 20
	NAME Henry Fresh
	SAY Well, if you are that basic, lets make it ask for a Banana Pie.
	DELAY 20
	NAME Aron Blue
	SAY Gateway to Planetside Pagliacci 15 is open.
	DELAY 20
	NAME Aron Blue
	SAY Feels appropriate.
	DELAY 15
	SOUND clown_step
	DELAY 10
	SOUND sparks
	DELAY 10
	NAME Aron Blue
	SAY Next order is for a simple farm dish.
	DELAY 20
	NAME Henry Fresh
	SAY Unlike you, I am creative.
	DELAY 20
	NAME Henry Fresh
	SAY I'll dress it up as a scarecrow.
	SOUND rustle
	DELAY 20
	NAME Aron Blue
	SAY Let's ask for uuuh, Hot Potato.
	DELAY 20
	NAME Henry Fresh
	SAY Send it to the new place. Firebase Balthazord.
	DELAY 20
	NAME Henry Fresh
	SAY Wait.
	DELAY 10
	NAME Henry Fresh
	SAY You know its called Baked Potato, right?
	DELAY 10
	SOUND sparks
	DELAY 20
	NAME Aron Blue
	SAY Shut up, they'll know what I meant!
	DELAY 20
	SOUND sparks
	DELAY 10
	NAME Henry Fresh
	SAY Its back.
	DELAY 20
	NAME Henry Fresh
	SAY Haha, it brought a raw potato.
	DELAY 20
	NAME Aron Blue
	SAY HENRY ITS TICK-
	DELAY 20
	SOUND explosion
	DELAY 20
	PRESET /datum/preset_holoimage/corgi
	NAME Blackbox Automated Message
	SAY Connection lost. Dumping audio logs to disk.
	DELAY 50
	"}

/obj/item/disk/holodisk/ruin/space/travelers_rest
	name = "Owner's memo"
	desc = "A holodisk containing a small memo from the previous owner, addressed to someone else."
	preset_image_type = /datum/preset_holoimage/engineer/atmos
	preset_record_text = {"
		NAME Space Adventurer
		SOUND PING
		DELAY 20
		SAY Hey, I left you this message for when you come back.
		DELAY 50
		SAY I picked up an emergency signal from a freighter and I'm going there to search for some goodies.
		DELAY 50
		SAY You can crash here if you need to, but make sure to check the anchor cables before you leave.
		DELAY 50
		SAY If you don't, this thing might drift off into space.
		DELAY 50
		SAY Then some weirdo could find it and potentially claim it as their own.
		DELAY 50
		SAY Anyway, gotta go, see ya!
		DELAY 40
		SOUND sparks
	"}
