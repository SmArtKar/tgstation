
//**********************************************************************
//**************************** Spider Queen ****************************
//**********************************************************************

// Spider Eyes - give you night vision, thermals and make spiders your friends until they get attacked

/obj/item/organ/eyes/night_vision/spider
	name = "spider eyes"
	desc = "Eight eyes instead of two!"
	eye_icon_state = "spidereyes"
	icon_state = "eyeballs-spider"
	flash_protect = FLASH_PROTECTION_SENSITIVE
	overlay_ignore_lighting = TRUE
	var/active_icon = FALSE
	var/list/active_friends = list()
	var/list/former_friends = list()

/obj/item/organ/eyes/night_vision/spider/on_life(delta_time, times_fired)
	var/turf/owner_turf = get_turf(owner)
	var/lums = owner_turf.get_lumcount()
	if(lums > 0.75 || lighting_alpha == LIGHTING_PLANE_ALPHA_VISIBLE)
		if(active_icon)
			active_icon = FALSE
			eye_icon_state = initial(eye_icon_state)
			icon_state = initial(icon_state)

			for(var/X in actions)
				var/datum/action/A = X
				A.UpdateButtonIcon()

			if(ishuman(owner))
				var/mob/living/carbon/human/human_owner = owner
				human_owner.update_body_parts_head_only()
	else
		if(!active_icon)
			active_icon = TRUE
			eye_icon_state = "[initial(eye_icon_state)]_active"
			icon_state = "[initial(icon_state)]_active"

			for(var/X in actions)
				var/datum/action/A = X
				A.UpdateButtonIcon()

			if(ishuman(owner))
				var/mob/living/carbon/human/human_owner = owner
				human_owner.update_body_parts_head_only()

	for(var/mob/living/simple_animal/possible_friend in view(7, owner_turf)) //You also look like spider so they don't attack you as long as you don't attack them
		if(!(possible_friend in active_friends) && !(possible_friend in former_friends) && isspider(possible_friend) && !istype(possible_friend, /mob/living/simple_animal/hostile/jungle/cave_spider/baby))
			active_friends += possible_friend
			possible_friend.apply_status_effect(/datum/status_effect/spider_damage_tracker)
			possible_friend.faction |= "[REF(owner)]"

	for(var/mob/living/simple_animal/possible_friend in active_friends)
		if(!(possible_friend in view(7, get_turf(owner_turf))))
			possible_friend.faction -= owner.real_name
			possible_friend.remove_status_effect(/datum/status_effect/spider_damage_tracker)
			active_friends -= "[REF(owner)]"
			continue

		var/datum/status_effect/spider_damage_tracker/C = possible_friend.has_status_effect(/datum/status_effect/spider_damage_tracker)
		if(istype(C) && C.damage > 0)
			possible_friend.faction -= "[REF(owner)]"
			possible_friend.remove_status_effect(/datum/status_effect/spider_damage_tracker)
			active_friends -= possible_friend
			former_friends += possible_friend

	. = ..()

/obj/item/organ/eyes/night_vision/spider/Insert(mob/living/carbon/eye_owner, special = FALSE)
	. = ..()
	ADD_TRAIT(eye_owner, TRAIT_THERMAL_VISION, ORGAN_TRAIT)

/obj/item/organ/eyes/night_vision/spider/Remove(mob/living/carbon/eye_owner, special = FALSE)
	REMOVE_TRAIT(eye_owner, TRAIT_THERMAL_VISION, ORGAN_TRAIT)
	for(var/mob/living/simple_animal/possible_friend in active_friends)
		possible_friend.faction -= "[REF(eye_owner)]"
		possible_friend.remove_status_effect(/datum/status_effect/spider_damage_tracker)
		active_friends -= possible_friend
		former_friends += possible_friend

	active_friends = list()
	former_friends = list()

	. = ..()

/obj/item/organ/eyes/night_vision/spider/attack(mob/attacker, mob/living/carbon/user, obj/target) //Surgery sucks
	if(attacker != user)
		return ..()

	user.visible_message(span_warning("[user] presses [src] against [user.p_their()] face and they grow in!"), span_userdanger("You press [src] against your face and scream in agony as they grow in!"))
	user.temporarilyRemoveItemFromInventory(src, TRUE)
	user.emote("scream")
	src.Insert(user)

/datum/status_effect/spider_damage_tracker
	id = "spider_damage_tracker"
	duration = -1
	alert_type = null
	var/damage = 0
	var/lasthealth

/datum/status_effect/spider_damage_tracker/tick()
	if((lasthealth - owner.health) > 0)
		damage += (lasthealth - owner.health)
	lasthealth = owner.health

// Spider Silk Cloth - Allows you to upgrade your gear up to 60 melee armor, 10 per stack

#define SPIDER_SILK_LIMIT 60
#define SPIDER_SILK_BUFF 10

/obj/item/stack/sheet/spidersilk
	name = "spider silk cloth"
	icon = 'icons/obj/mining.dmi'
	desc = "A very tough and resistant cloth made from spider silk."
	singular_name = "spider silk cloth"
	icon_state = "sheet-spidersilk"
	max_amount = 3
	novariants = FALSE
	item_flags = NOBLUDGEON
	w_class = WEIGHT_CLASS_SMALL
	merge_type = /obj/item/stack/sheet/spidersilk

/obj/item/stack/sheet/spidersilk/afterattack(atom/A, mob/living/user, proximity_flag, clickparams)
	if(!istype(A, /obj/item/clothing/suit) && !istype(A, /obj/item/clothing/head))
		return ..()


	var/obj/item/clothing/target = A
	if(((MELEE in target.armor) && target.armor[MELEE] >= SPIDER_SILK_LIMIT) || HAS_TRAIT(target, TRAIT_SPIDER_SILK_UPGRADED))
		to_chat(user, span_warning("[target] can't be upgraded further!"))
		return ..()


	if(!target.armor.melee)
		target.armor.melee = SPIDER_SILK_BUFF
	else
		target.armor.melee = min(SPIDER_SILK_LIMIT, target.armor.melee + SPIDER_SILK_BUFF)
	to_chat(user, span_notice("You successfully upgrade [target] with [src]"))
	ADD_TRAIT(target, TRAIT_SPIDER_SILK_UPGRADED, MEGAFAUNA_TRAIT)
	use(1)

#undef SPIDER_SILK_LIMIT
#undef SPIDER_SILK_BUFF

//Tamed Cave Spider - a nice mount that ignores terrain slowdown. Just don't forget to heal it with bagelshrooms and you'll be fine

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/mount
	name = "tamed cave spider"
	desc = "A small pitch-black cave spider with glowing purple eyes and turquoise stripe on it's back. It seems completely friendly and non-hostile."
	maxHealth = 300 //Made it tough so it won't get instakilled by fauna
	health = 300
	melee_damage_lower = 0
	melee_damage_upper = 0
	ranged = FALSE
	faction = list("neutral", "jungle", "spiders")
	can_buckle = TRUE
	buckle_lying = 0
	move_force = MOVE_FORCE_NORMAL
	move_resist = MOVE_FORCE_NORMAL
	pull_force = MOVE_FORCE_NORMAL
	ai_controller = /datum/ai_controller/hostile_friend

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/mount/Initialize()
	. = ..()
	AddElement(/datum/element/ridable, /datum/component/riding/creature/cave_spider_mount)
	AddElement(/datum/element/pet_bonus, "chitters happily!")
	can_have_ai = FALSE
	toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/mount/proc/set_owner(mob/living/owner)
	faction.Add("[REF(owner)]")
	if(ai_controller)
		var/datum/ai_controller/hostile_friend/ai_current_controller = ai_controller
		ai_current_controller.befriend(owner)
		can_have_ai = FALSE
		toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/jungle/cave_spider/baby/mount/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(!istype(I, /obj/item/food/grown/jungle_flora/bagelshroom) && !istype(I, /obj/item/food/cut_bagelshroom))
		return

	if(stat == DEAD)
		to_chat(user, span_warning("[src] is dead!"))

	user.visible_message(span_notice("[user] hand-feeds [I] to [src]."), span_notice("You hand-feed [src] to [user]."))
	new /obj/effect/temp_visual/heart(loc)
	if(prob(50))
		manual_emote("chitters happily!")
	qdel(I)
	adjustHealth(-75) //Heal it with bagelshrooms!

// Spider Queen Eye - A crafting component that also can be used as a squishy flashlight

/obj/item/spider_eye
	name = "spider queen eye"
	desc = "A giant eye of a spider queen. It looks squishy..."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "spider_eye"
	inhand_icon_state = null
	worn_icon_state = null
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = null
	custom_materials = list()
	actions_types = list()
	light_system = MOVABLE_LIGHT_DIRECTIONAL
	light_range = 3
	light_color = "#993FD4"
	light_on = FALSE

/obj/item/spider_eye/attack_self(mob/user)
	playsound(user, 'sound/misc/splort.ogg', 40, TRUE)
	icon_state = initial(icon_state)
	set_light_on(TRUE)
	addtimer(CALLBACK(src, .proc/turnOff, user), 5 SECONDS)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/item/spider_eye/proc/turnOff(mob/user)
	playsound(user, 'sound/misc/splort.ogg', 40, TRUE)
	icon_state = "[initial(icon_state)]-on"
	set_light_on(FALSE)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/effect/spawner/random/boss/spider_queen
	name = "spider queen loot spawner"
	loot = list(/obj/item/stack/sheet/spidersilk = 1, /obj/item/organ/eyes/night_vision/spider = 1)
