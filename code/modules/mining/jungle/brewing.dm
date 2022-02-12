
/obj/item/food/meat/slab/leaper
	name = "leaper meat"
	desc = "A slab of red meat with bright green skin. It vaguely smells of baguettes."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "leapermeat"
	food_reagents = list(/datum/reagent/consumable/nutriment/protein = 8, /datum/reagent/toxin/leaper_venom = 5)
	bite_consumption = 4
	tastes = list("meat" = 1, "french cuisine" = 1, "surrender" = 1)

/obj/item/food/meat/slab/leaper/MakeProcessable()
	return

/obj/item/food/meat/slab/leaper/MakeGrillable()
	AddComponent(/datum/component/grillable, /obj/item/food/meat/steak/leaper, rand(40 SECONDS, 70 SECONDS), TRUE, TRUE)

/obj/item/food/meat/steak/leaper
	name = "leaper steak"
	desc = "A piece of hot spicy frog meat."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "leapersteak"
	tastes = list("meat" = 1, "french cuisine" = 1, "surrender" = 1)
	food_reagents = list(/datum/reagent/consumable/nutriment/protein = 8, /datum/reagent/consumable/nutriment/vitamin = 1, /datum/reagent/toxin/lesser_leaper_venom = 4)

/obj/item/food/meat/slab/arachnid
	name = "leaper meat"
	desc = "A slab of toxic purple meat with dark red skin."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "arachnidmeat"
	food_reagents = list(/datum/reagent/consumable/nutriment/protein = 8, /datum/reagent/toxin/leaper_venom = 5)
	bite_consumption = 4
	tastes = list("meat" = 1, "french cuisine" = 1, "surrender" = 1)

/obj/item/food/meat/slab/arachnid/MakeProcessable()
	return

/obj/item/food/meat/slab/arachnid/MakeGrillable()
	AddComponent(/datum/component/grillable, /obj/item/food/meat/steak/arachnid, rand(40 SECONDS, 70 SECONDS), TRUE, TRUE)

/obj/item/food/meat/steak/arachnid
	name = "mega arachnid steak"
	desc = "A piece of hot spicy giant spider meat."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "arachnidsteak"
	tastes = list("meat" = 1, "spiders" = 1)

/obj/item/food/meat/slab/snakeman
	name = "snakeman meat"
	desc = "A few good pieces of snakeman meat. These are pretty tender but if cooked right can be pretty tasty."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "snakemanmeat"
	tastes = list("meat" = 1, "hissing" = 1, "racism" = 1)
	//food_reagents = list(/datum/reagent/consumable/nutriment/protein = 8, /datum/reagent/snakeman_blood = 5)

/obj/item/food/meat/slab/snakeman/MakeProcessable()
	return

/obj/item/food/meat/slab/snakeman/MakeGrillable()
	AddComponent(/datum/component/grillable, /obj/item/food/meat/steak/snakeman, rand(40 SECONDS, 70 SECONDS), TRUE, TRUE)

/obj/item/food/meat/steak/snakeman
	name = "cooked snakeman meat"
	desc = "A few pieces of hot spicy snake meat. Just like space cops like it."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "snakemanmeat_cooked"
	tastes = list("meat" = 1, "hissing" = 1, "racism" = 1)

/obj/item/food/meat/slab/mook
	name = "mook meat"
	desc = "A slab of rock hard shiny flesh of some mook. You aren't even sure if you can call this meat."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "mookmeat"
	tastes = list("rock salt" = 1, "nanites" = 1)
	food_reagents = list(/datum/reagent/iron = 8)

/obj/item/food/meat/slab/mook/MakeGrillable()
	return

/obj/item/food/meat/slab/mook/MakeProcessable()
	return

/obj/item/food/leaper_toxin_sack
	name = "toxin sack"
	desc = "A fleshy bubble with leaper venom inside. Probably not a very good idea to eat this raw."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "leaper_bubble"
	foodtypes = MEAT | GROSS
	tastes = list("swamp" = 1, "french cuisine" = 1)
	food_reagents = list(/datum/reagent/toxin/leaper_venom = 12) //Enough to poison you

/obj/item/food/leaper_toxin_sack/attack_self(mob/user, modifiers)
	. = ..()


/*
 * Code below belongs to the brewing system, unique to Jungle
 * First you need to make a bowl and fill it with something, any chemical works but water is preferred. Just don't take it from the supermatter cooling lake.
 * Then you need some meat, doesn't matter if it's raw or cooked. You also can add some toppings if you want. Heat the results on a bonfire and your brew is finished!
 * Brew's effects depend on it's ingridients, both meat and toppings. Some combinations have unique effects.
 */

#define COOK_TIME_MIN 5 SECONDS
#define COOK_TIME_MAX 15 SECONDS

/obj/item/reagent_containers/glass/jungle_bowl
	name = "wooden bowl"
	desc = "A bowl made out of dark jungle wood."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "jungle_bowl"
	base_icon_state = "jungle_bowl"
	fill_icon_thresholds = list(0)
	amount_per_transfer_from_this = 10
	fill_icon_state = "jungle_bowl"
	volume = 30
	possible_transfer_amounts = list(5, 10, 15, 20, 25, 30)
	reagent_flags = OPENCONTAINER | DUNKABLE

	var/meat_type
	var/topping_type
	var/topping_amount = 0
	var/cooked = FALSE
	var/cook_time = 0
	var/required_cook_time = 0

	var/static/list/meats = list(/obj/item/food/meat/slab/leaper =    list("leaper", "#FF0800", null),
								 /obj/item/food/meat/steak/leaper =   list("leaper_cooked", "#A5130F", null),
								 /obj/item/food/meat/slab/arachnid =    list("arachnid", "#882274", null),
								 /obj/item/food/meat/steak/arachnid =   list("arachnid_cooked", "#D63EB8", null),
								 /obj/item/food/meat/slab/snakeman =  list("snakeman", "#9EFF00", null),
								 /obj/item/food/meat/steak/snakeman = list("snakeman_cooked", "#FFDA00", null),
								 /obj/item/food/meat/slab/mook =      list("mook", "#FFFFFF", null),
								 )

	var/static/list/toppings = list(/obj/item/food/grown/jungle_flora/rapsberry =  list("rapsberries", 3, null),
									/obj/item/food/cut_beerroot =				   list("beerroot", 3, null),
									/obj/item/food/cut_bagelshroom =  			   list("bagelshrooms", 2, null),
									/obj/item/food/fried_bagelshroom = 			   list("bagelshrooms_cooked", 2, null),
									/obj/item/food/grown/jungle_flora/wild_herbs = list("herbs", 3, null),
									/obj/item/food/leaper_toxin_sack =			   list("leaper_bubbles", 3, null),
									)

	var/static/list/special_combos = list()

/obj/item/reagent_containers/glass/jungle_bowl/update_overlays()
	. = ..()
	if(meat_type)
		var/mutable_appearance/meat = mutable_appearance(icon, "jungle_bowl_meat")
		meat.color = meats[meat_type][2]
		. += meat

	if(topping_type)
		. += mutable_appearance(icon, "[icon_state]_[toppings[topping_type][1]][topping_amount]")

	if(cooked)
		. += mutable_appearance('icons/effects/steam.dmi', "steam_triple", ABOVE_OBJ_LAYER)

/obj/item/reagent_containers/glass/jungle_bowl/attackby(obj/item/attacking_item, mob/living/user)
	if((attacking_item.type in meats) && !meat_type)
		meat_type = attacking_item.type
		to_chat(user, span_notice("You add [attacking_item] to [src]."))
		qdel(attacking_item)
		required_cook_time = rand(COOK_TIME_MIN, COOK_TIME_MAX)
		update_overlays()

	else if(attacking_item.type in toppings)
		if(!meat_type)
			to_chat(user, span_warning("You need to add some sort of meat to [src] first!"))
		else if(!topping_type)
			topping_type = attacking_item.type
			topping_amount = 1
			to_chat(user, span_notice("You add [attacking_item] to [src]."))
			qdel(attacking_item)
			update_icon()
		else if(topping_type == attacking_item.type)
			if(topping_amount >= toppings[topping_type][2])
				to_chat(user, span_warning("You can't add more topping to [src]!"))
				return
			to_chat(user, span_notice("You add [attacking_item] to [src]."))
			topping_amount += 1
			qdel(attacking_item)
			update_icon()
		else
			to_chat(user, span_warning("You can't add a second type of topping to [src]!"))
	else
		return ..()

/obj/item/reagent_containers/glass/jungle_bowl/attack(mob/target, mob/living/user, params)
	if(!meat_type)
		return ..()

	if(!cooked)
		to_chat(user, span_warning("[src] is raw, you should cook it first!"))
		return

	if(!canconsume(target, user) || !istype(target))
		return



/obj/item/reagent_containers/glass/jungle_bowl/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_GRILLED, .proc/OnGrill)

/obj/item/reagent_containers/glass/jungle_bowl/proc/OnGrill(datum/source, atom/used_grill, delta_time = 1)
	SIGNAL_HANDLER

	cook_time += delta_time * 10
	reagents.expose_temperature(reagents.chem_temp + 100)
	if(cook_time >= required_cook_time && !cooked)
		cooked = TRUE
		update_icon()

/obj/item/reagent_containers/glass/jungle_bowl/microwave_act(obj/machinery/microwave/M)
	. = ..()
	cooked = TRUE
	update_icon()

#undef COOK_TIME_MIN
#undef COOK_TIME_MAX
