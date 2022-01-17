/// Heart of the thing those poor genetisists experimented on. Not really that hard to get, so nothing extraordinare here. Gives owner some toxin protection(pretty useful in jungle)
/// Downside of it is that you will randomly get spider-related hallucinations as a tradeoff. Hallucinations themselves are not really that bad actually.

/obj/item/organ/heart/spider_mother
	name = "spider heart"
	desc = "A strange, black heart covered in something oily. It stinks of venom."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "heart-x-on"
	base_icon_state = "heart-x"
	decay_factor = 0

/obj/item/organ/heart/spider_mother/attack(mob/M, mob/living/carbon/user, obj/target) //Stolen from demon heart code
	if(M != user)
		return ..()
	user.visible_message("<span class='warning'>[user] raises [src] to [user.p_their()] mouth and devours it in a single bite!</span>", \
		"<span class='warning'>You close your eyes and devour [src]! Suddenly, you feel unnatural heat flowing through your veins! You are now much more resistant to poison!</span>")
	playsound(user, 'sound/magic/demon_consume.ogg', 50, TRUE)
	user.temporarilyRemoveItemFromInventory(src, TRUE)
	src.Insert(user)

/obj/item/organ/heart/spider_mother/Insert(mob/living/carbon/human/target, special = 0)
	. = ..()
	if(!istype(target))
		return

	target.physiology.tox_mod *= 0.75

/obj/item/organ/heart/spider_mother/Remove(mob/living/carbon/human/target, special = 0)
	. = ..()
	if(!istype(target))
		return

	target.physiology.tox_mod /= 0.75

/obj/item/organ/heart/spider_mother/on_life(delta_time, times_fired)
	. = ..()

	if(!owner)
		return

	if(DT_PROB(2.5, delta_time))
		if(prob(50))
			new /datum/hallucination/delusion(owner, forced = TRUE, force_kind = "spider", duration = rand(300, 600), skip_nearby = FALSE)
		else
			new /datum/hallucination/self_delusion(owner, TRUE = TRUE, force_kind = "spider", duration = rand(300, 600))
