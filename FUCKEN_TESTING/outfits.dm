/datum/outfit/debug_miner
	name = "Debug Miner"

	belt = /obj/item/storage/belt/mining/healeys
	ears = /obj/item/radio/headset/headset_cargo/mining
	shoes = /obj/item/clothing/shoes/workboots/mining/explorer
	gloves = /obj/item/clothing/gloves/combat
	uniform = /obj/item/clothing/under/syndicate
	l_pocket = /obj/item/gps
	r_pocket = /obj/item/storage/bag/ore/holding
	glasses = /obj/item/clothing/glasses/meson/night
	suit = /obj/item/clothing/suit/hooded/explorer
	mask = /obj/item/clothing/mask/gas/explorer
	neck = /obj/item/clothing/neck/cloak/skill_reward/mining
	backpack_contents = list(
		/obj/item/storage/box/healeys = 1,\
		/obj/item/flashlight/seclite=1,\
		/obj/item/kitchen/knife/combat/survival=1,\
		/obj/item/mining_voucher=2,\
		/obj/item/gun/energy/kinetic_accelerator=1,\
		/obj/item/kinetic_crusher=1,\
		/obj/item/gun/energy/plasmacutter/adv = 1,\
		)

	back = /obj/item/storage/backpack/holding
	box = /obj/item/storage/box/full_ka_upgrades

	id = /obj/item/card/id/advanced/centcom
	id_trim = /datum/id_trim/centcom/deathsquad

	suit_store = /obj/item/tank/internals/oxygen
	internals_slot = ITEM_SLOT_SUITSTORE

/datum/outfit/debug_miner/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	var/obj/item/organ/cyberimp/eyes/hud/medical/hud = new(H)
	hud.Insert(H)

	H.fully_replace_character_name(null, H.ckey)
	var/obj/item/clothing/suit/hooded/explorer/suit = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(suit))
		suit.ToggleHood()

	var/obj/item/card/id/id = H.get_item_by_slot(ITEM_SLOT_ID)
	id.registered_name = H.ckey
	id.update_label()

/obj/item/storage/box/full_ka_upgrades/PopulateContents()
	..()
	for(var/i = 1 to 3)
		new /obj/item/borg/upgrade/modkit/range(src)
		new /obj/item/borg/upgrade/modkit/damage(src)
		new /obj/item/borg/upgrade/modkit/cooldown(src)

	new /obj/item/borg/upgrade/modkit/trigger_guard(src)
	new /obj/item/borg/upgrade/modkit/chassis_mod/orange(src)
	new /obj/item/borg/upgrade/modkit/tracer/adjustable(src)
	new /obj/item/borg/upgrade/modkit/aoe/turfs(src)
	new /obj/item/borg/upgrade/modkit/human_passthrough(src)
	var/obj/item/t_scanner/adv_mining_scanner/scanner = new(src)
	scanner.toggle_on()

/obj/item/storage/box/healeys/PopulateContents()
	for (var/i = 1 to 3)
		var/obj/item/organ/regenerative_core/legion/shining_core/core = new(src)
		core.preserved()
		new /obj/item/reagent_containers/hypospray/medipen/survival/luxury(src)

	for(var/i = 1 to 6)
		new /obj/item/reagent_containers/hypospray/medipen/survival/luxury(src)

	new /obj/item/storage/pill_bottle/psicodine(src)
	new /obj/item/storage/pill_bottle/stimulant(src)

/obj/item/storage/belt/mining/healeys/PopulateContents()
	for (var/i = 1 to 3)
		var/obj/item/organ/regenerative_core/legion/shining_core/core = new(src)
		core.preserved()
		new /obj/item/reagent_containers/hypospray/medipen/survival/luxury(src)

/obj/item/storage/box/kc_debug/PopulateContents()
	for(var/T in subtypesof(/obj/item/crusher_trophy))
		new T(src)

/obj/item/storage/box/boss_loot/PopulateContents()
	new /obj/item/stack/sheet/spidersilk(src)
	new /obj/item/spider_eye(src)
	new /obj/item/organ/eyes/night_vision/spider(src)
	new /obj/item/worm_tongue(src)
	new /obj/item/dual_sword(src)
	new /obj/item/book/granter/spell/powerdash(src)
	new /obj/item/crystal_fruit(src)
	new /obj/item/demon_stone(src)
	new /obj/item/gun/magic/staff/blood_claymore(src)
	new /obj/item/book/granter/spell/throwing_knives(src)
	new /obj/item/experimental_components(src)
	new /obj/item/armor_scales(src)
	new /obj/item/amber_core(src)

/datum/outfit/debug_miner/ultra
	name = "Ultra Debug Miner"

	belt = /obj/item/storage/belt/mining/healeys
	ears = /obj/item/radio/headset/headset_cargo/mining
	shoes = /obj/item/clothing/shoes/workboots/mining/explorer
	gloves = /obj/item/clothing/gloves/crystal
	uniform = /obj/item/clothing/under/syndicate
	l_pocket = /obj/item/gps
	r_pocket = /obj/item/storage/bag/ore/holding
	glasses = /obj/item/clothing/glasses/meson/night
	suit = /obj/item/clothing/suit/space/hardsuit/exosuit

	backpack_contents = list(
		/obj/item/storage/box/healeys = 1,\
		/obj/item/flashlight/seclite=1,\
		/obj/item/kitchen/knife/combat/survival=1,\
		/obj/item/gun/energy/kinetic_accelerator=1,\
		/obj/item/kinetic_crusher=1,\
		/obj/item/gun/energy/plasmacutter/adv = 1,\
		/obj/item/storage/box/boss_loot = 1,\
		/obj/item/storage/box/kc_debug = 1,\
		)

/obj/effect/mob_spawn/human/debug_miner
	name = "debug mining cryostasis sleeper"
	desc = "A humming sleeper with a silhouetted occupant inside. Its stasis function is broken and it's likely being used as a bed."
	mob_name = "a debug miner"
	icon = 'icons/obj/lavaland/spawners.dmi'
	icon_state = "cryostasis_sleeper"
	outfit = /datum/outfit/debug_miner
	roundstart = FALSE
	death = FALSE
	random = TRUE
	mob_species = /datum/species/human
	short_desc = "You're a debug miner on some jungle planet. Blame SmArtKar for forcing you to do this."
	flavour_text = "You're a debug miner on some jungle planet. Blame SmArtKar for forcing you to do this. Explore this land, kill monsters, die and repeat again! Just don't abuse suicides to get infinite starting gear, okay?"

/obj/effect/mob_spawn/human/debug_miner/Destroy()
	new type(get_turf(src))
	return ..()

/obj/effect/mob_spawn/human/debug_miner/ultra
	outfit = /datum/outfit/debug_miner/ultra
