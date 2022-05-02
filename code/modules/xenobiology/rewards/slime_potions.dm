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
	qdel(src)



/obj/item/slimepotion/transference
/obj/item/slimepotion/slime/sentience/nuclear
/obj/item/slimepotion/speed
