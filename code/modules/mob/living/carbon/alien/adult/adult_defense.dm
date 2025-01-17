

/mob/living/carbon/alien/adult/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(!.)
		return
	var/hitverb = "hit"
	if(mob_size < MOB_SIZE_LARGE)
		safe_throw_at(get_edge_target_turf(src, get_dir(user, src)), 2, 1, user)
		hitverb = "slam"
	playsound(loc, SFX_PUNCH, 25, TRUE, -1)
	visible_message(span_danger("[user] [hitverb]s [src]!"), \
					span_userdanger("[user] [hitverb]s you!"), span_hear("You hear a sickening sound of flesh hitting flesh!"), COMBAT_MESSAGE_RANGE, user)
	to_chat(user, span_danger("You [hitverb] [src]!"))
	apply_damage(15, BRUTE, MELEE, MELEE_ATTACK, user.zone_selected, attack_dir = get_dir(src, user), hit_by = user, source = user, wound_bonus = 10, check_armor = TRUE)

/mob/living/carbon/alien/adult/attack_hand(mob/living/carbon/human/user, list/modifiers)
	. = ..()
	if(.)
		return TRUE

	if (prob(10))
		playsound(loc, 'sound/items/weapons/punchmiss.ogg', 25, TRUE, -1)
		visible_message(span_danger("[user]'s punch misses [src]!"), \
						span_danger("You avoid [user]'s punch!"), span_hear("You hear a swoosh!"), COMBAT_MESSAGE_RANGE, user)
		to_chat(user, span_warning("Your punch misses [src]!"))
		return

	playsound(loc, SFX_PUNCH, 25, TRUE, -1)
	visible_message(span_danger("[user] punches [src]!"), \
					span_userdanger("[user] punches you!"), span_hear("You hear a sickening sound of flesh hitting flesh!"), COMBAT_MESSAGE_RANGE, user)
	to_chat(user, span_danger("You punch [src]!"))

	if (stat != DEAD && prob(5)) // Regular humans have a very small chance of knocking an alien down.
		Unconscious(4 SECONDS)
		visible_message(span_danger("[user] knocks [src] down!"), \
						span_userdanger("[user] knocks you down!"), span_hear("You hear a sickening sound of flesh hitting flesh!"), null, user)
		to_chat(user, span_danger("You knock [src] down!"))

	apply_damage_package(user.get_unarmed_package(src, rand(1, 9), null, get_random_valid_zone(user.zone_selected)), check_armor = TRUE)
	log_combat(user, src, "attacked")

/mob/living/carbon/alien/adult/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect && !visual_effect_icon)
		visual_effect_icon = ATTACK_EFFECT_CLAW
	..()
