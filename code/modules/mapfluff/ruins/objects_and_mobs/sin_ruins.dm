//These objects are used in the cardinal sin-themed ruins (i.e. Gluttony, Pride...)

/obj/effect/gluttony //Gluttony's wall: Used in the Gluttony ruin. Only lets the overweight through.
	name = "gluttony's wall"
	desc = "Only those who truly indulge may pass."
	anchored = TRUE
	density = TRUE
	icon_state = "blob"
	icon = 'icons/mob/nonhuman-player/blob.dmi'
	color = rgb(145, 150, 0)
	/// Balloons/animations are on a short cooldown as otherwise they can get really spammy, since CanAllowThrough can be called every tick
	COOLDOWN_DECLARE(message_cooldown)

/obj/effect/gluttony/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if (istype(mover, /mob/living/basic/morph))
		return TRUE

	if (!ishuman(mover))
		return

	var/mob/living/carbon/human/as_human = mover
	if (as_human.nutrition >= NUTRITION_LEVEL_FAT)
		as_human.visible_message(span_warning("[as_human] pushes through [src]!"), span_notice("You've seen and eaten worse than this."))
		return TRUE

	if	(!COOLDOWN_FINISHED(src, message_cooldown))
		return

	COOLDOWN_START(src, message_cooldown, 1 SECONDS)
	to_chat(as_human, span_warning("You're repulsed by even looking at [src]. Only a pig could force themselves to go through it."))
	balloon_alert(as_human, "not fat enough!")
	add_filter("gluttony_ripple", 2, list("type" = "ripple", "flags" = WAVE_BOUNDED, "radius" = 0, "size" = 2))
	animate(get_filter("gluttony_ripple"), radius = 32, time = 0.7 SECONDS, size = 0)
	animate(src, transform = matrix() * 1.5, time = 0.3 SECONDS, flags = ELASTIC_EASING|EASE_OUT)
	animate(transform = matrix(), time = 0.4 SECONDS, flags = BOUNCE_EASING|EASE_OUT)

//can't be bothered to do sloth right now, will make later

/obj/item/knife/envy //Envy's knife: Found in the Envy ruin. Attackers take on the appearance of whoever they strike.
	name = "envy's knife"
	desc = "Their success will be yours."
	icon = 'icons/obj/weapons/stabby.dmi'
	icon_state = "envyknife"
	inhand_icon_state = "knife"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	force = 18
	throwforce = 10
	w_class = WEIGHT_CLASS_NORMAL
	hitsound = 'sound/items/weapons/bladeslice.ogg'

/obj/item/knife/envy/afterattack(atom/target, mob/living/carbon/human/user, click_parameters)
	if(!istype(user) || !ishuman(target))
		return

	var/mob/living/carbon/human/H = target
	if(user.real_name == H.dna.real_name)
		return

	user.real_name = H.dna.real_name
	H.dna.transfer_identity(user, transfer_SE=1)
	user.updateappearance(mutcolor_update=1)
	user.domutcheck()
	user.visible_message(span_warning("[user]'s appearance shifts into [H]'s!"), \
	span_bolddanger("[H.p_They()] think[H.p_s()] [H.p_theyre()] <i>sooo</i> much better than you. Not anymore, [H.p_they()] won't."))
