
/mob/living/basic/slime/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	powerlevel = 0 // oh no, the power!

///If a slime is attack with an empty hand, shoves included, try to wrestle them off the mob they are on
/mob/living/basic/slime/proc/on_attack_hand(mob/living/basic/slime/defender_slime, mob/living/attacker)
	SIGNAL_HANDLER

	if(isnull(buckled))
		return

	if(buckled == attacker ? prob(60) : prob(30)) //its easier to remove the slime from yourself
		attacker.visible_message(span_warning("[attacker] attempts to wrestle \the [defender_slime.name] off [buckled == attacker ? "" : buckled] !"), \
		span_danger("[buckled == attacker ? "You attempt" : "[attacker] attempts" ] to wrestle \the [defender_slime.name] off [buckled == attacker ? "" : buckled]!"))
		playsound(loc, 'sound/weapons/punchmiss.ogg', 25, TRUE, -1)
		return

	attacker.visible_message(span_warning("[attacker] manages to wrestle \the [defender_slime.name] off!"), span_notice("You manage to wrestle \the [defender_slime.name] off!"))
	playsound(loc, 'sound/weapons/shove.ogg', 50, TRUE, -1)

	defender_slime.discipline_slime()

/mob/living/basic/slime/attackby(obj/item/attacking_item, mob/living/user, params)

	//Lets you feed slimes plasma. Checks before the passthrough force check
	if(istype(attacking_item, /obj/item/stack/sheet/mineral/plasma) && stat == CONSCIOUS)
		use_sheet(attacking_item, user)
		return

	//Checks if the item passes through the slime first. Safe items can be used simply
	if(check_item_passthrough(attacking_item, user))
		return

	try_discipline_slime(attacking_item)

	if(!istype(attacking_item, /obj/item/storage/bag/xeno))
		return ..()

	use_xeno_bag(attacking_item, user)


///Checks if an item harmlessly passes through the slime
/mob/living/basic/slime/proc/check_item_passthrough(obj/item/attacking_item, mob/living/user)
	if(attacking_item.force <= 0)
		return FALSE

	if(!prob(25))
		return FALSE

	user.do_attack_animation(src)
	user.changeNext_move(CLICK_CD_MELEE)
	to_chat(user, span_danger("[attacking_item] passes right through [src]!"))
	return TRUE

///Attempts to use the item to discipline the unruly slime
/mob/living/basic/slime/proc/try_discipline_slime(obj/item/attacking_item)
	if(attacking_item.force < 3)
		return

	var/force_effect =  attacking_item.force * (life_stage == SLIME_LIFE_STAGE_BABY ? 2 : 1)
	if(prob(10 + force_effect))
		discipline_slime()

///Handles feeding a sheet of plasma to a slime
/mob/living/basic/slime/proc/use_sheet(obj/item/stack/sheet/mineral/plasma/delicious_sheet, mob/living/user)
	befriend(user)
	to_chat(user, span_notice("You feed the slime the plasma. It chirps happily."))
	delicious_sheet.use(1)
	new /obj/effect/temp_visual/heart(loc)
	return

///Handles the adverse effects of water on slimes
/mob/living/basic/slime/proc/apply_water()
	adjustBruteLoss(rand(15,20))
	discipline_slime()

///Stops the slime from feeding, and might remove rabidity and targets
/mob/living/basic/slime/proc/discipline_slime()
	stop_feeding(silent = TRUE)
	if(life_stage == SLIME_LIFE_STAGE_BABY && prob(80))
		ai_controller?.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		ai_controller?.clear_blackboard_key(BB_CURRENT_HUNTING_TARGET)

	if(prob(10))
		ai_controller?.set_blackboard_key(BB_SLIME_RABID, FALSE)
