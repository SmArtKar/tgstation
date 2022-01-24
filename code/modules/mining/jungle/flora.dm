/obj/structure/flora/aquatic
	icon = 'icons/obj/flora/waterflora.dmi'

/obj/structure/flora/aquatic/rock
	name = "rock"
	desc = "A volcanic rock. Pioneers used to ride these babies for miles."
	icon_state = "bigwaterrock"
	resistance_flags = FIRE_PROOF
	density = TRUE
	var/obj/item/stack/mineResult = /obj/item/stack/ore/glass/basalt
	var/mineAmount = 20

/obj/structure/flora/aquatic/rock/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)][rand(1,3)]"

/obj/structure/flora/aquatic/rock/attackby(obj/item/W, mob/user, params)
	if(!mineResult || W.tool_behaviour != TOOL_MINING)
		return ..()
	if(flags_1 & NODECONSTRUCT_1)
		return ..()
	to_chat(user, "<span class='notice'>You start mining...</span>")
	if(W.use_tool(src, user, 40, volume=50))
		to_chat(user, "<span class='notice'>You finish mining the rock.</span>")
		if(mineResult && mineAmount)
			new mineResult(loc, mineAmount)
		SSblackbox.record_feedback("tally", "pick_used_mining", 1, W.type)
		qdel(src)

/obj/structure/flora/aquatic/rock/pile
	name = "pile of rocks"
	desc = "A pile of rocks."
	icon_state = "waterrock"

/obj/structure/flora/aquatic/rock/pile/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)][rand(1,2)]"

/obj/structure/flora/aquatic/seaweed
	name = "seaweed"
	desc = "Some seaweed. It's not growing in sea and it's not weed, but it's still called seaweed."
	icon_state = "seaweed"

/obj/structure/flora/aquatic/seaweed/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)][rand(1,3)]"


/// Harvestable food


/obj/structure/flora/ash/jungle_plant
	name = "berry bush"
	desc = "A small bush with some berries on it. Tasty!"
	icon = 'icons/obj/flora/jungleflora.dmi'
	icon_state = "bush_raps"

	harvested_name = "harvested bush"
	harvested_desc = "A wild berry bush. You can see that there were some rapsberries on it but they were harvested."
	needs_sharp_harvest = FALSE

	harvest = /obj/item/food/grown/jungle_flora/rapsberry
	harvest_message_low = "You take a few berries from the bush, but accidentally squish most of them."
	harvest_message_med = "You carefully collect some berries from the bush."
	harvest_message_high = "You collect all berries from the bush."
	number_of_variants = 3

/obj/item/seeds/jungle
	name = "jungle seeds"
	desc = "You should never see this."
	lifespan = 40
	endurance = 15
	maturation = 7
	production = 4
	yield = 2
	potency = 15
	growthstages = 6
	rarity = 20
	reagents_add = list(/datum/reagent/consumable/nutriment = 0.02, /datum/reagent/consumable/nutriment/vitamin = 0.1)
	resistance_flags = ACID_PROOF
	growing_icon = 'icons/obj/hydroponics/growing_fruits.dmi'
	species = "rapsberry" //fucking unit tests
	genes = list(/datum/plant_gene/trait/repeated_harvest)
	graft_gene = /datum/plant_gene/trait/repeated_harvest

/obj/item/food/grown/jungle_flora
	name = "error fruit"
	desc = "You should never see this."
	seed = /obj/item/seeds/jungle
	resistance_flags = FLAMMABLE | ACID_PROOF
	max_integrity = 100

/// Rapsberries

/obj/item/food/grown/jungle_flora/rapsberry
	name = "rapsberry"
	desc = "A big, juicy berry named after raspberries because they posess the same color and taste."
	icon_state = "rapsberry"
	w_class = WEIGHT_CLASS_TINY
	foodtypes = FRUIT
	tastes = list("incredible sweetness" = 5, "bitter raspberries" = 2, "chineese noodles" = 1) //Hard joke, basically a chineese knockoff of normal raspberries
	seed = /obj/item/seeds/jungle/rapsberry
	wine_power = 20

/obj/item/seeds/jungle/rapsberry
	name = "pack of rapsberry seeds"
	desc = "These seeds grow into rapsberry bushes with big, tasty berries."
	icon_state = "seed-rapsberry"
	species = "rapsberry"
	plantname = "Rapsberry Bush"
	icon_grow = "berry-grow"
	icon_dead = "berry-dead"
	product = /obj/item/food/grown/jungle_flora/rapsberry
	genes = list(/datum/plant_gene/trait/repeated_harvest, /datum/plant_gene/trait/maxchem, /datum/plant_gene/trait/injector)
	reagents_add = list(/datum/reagent/consumable/sugar = 0.04, /datum/reagent/consumable/nutriment = 0.04, /datum/reagent/consumable/vitfro = 0.08, /datum/reagent/consumable/capsaicin = 0.15)

/// Beer Root

/obj/structure/flora/ash/jungle_plant/beerroot
	name = "beerroot"
	desc = "A bunch of thick brown roots, these are known for producing beer naturally."
	icon_state = "beerroot"

	harvested_name = "beerroot sprouts"
	harvested_desc = "Small brown sprouts of beerroot."
	needs_sharp_harvest = TRUE

	harvest = /obj/item/food/grown/jungle_flora/beerroot
	harvest_message_low = "You collect a few good roots from the ground."
	harvest_message_med = "You carefully collect a bunch of nice, thick roots from the ground."
	harvest_message_high = "You collect all the roots from the ground you can find, that's a really good harvest!"

/obj/item/food/grown/jungle_flora/beerroot
	name = "beerroot"
	desc = "A thick root that is known for naturally producing beer."
	icon_state = "beerroot"
	w_class = WEIGHT_CLASS_TINY
	foodtypes = VEGETABLES | ALCOHOL
	seed = /obj/item/seeds/jungle/beerroot
	distill_reagent = /datum/reagent/consumable/ethanol/beer

/obj/item/food/grown/jungle_flora/beerroot/MakeProcessable()
	AddElement(/datum/element/processable, TOOL_KNIFE, /obj/item/food/cut_beerroot, 4, 30)

/obj/item/food/cut_beerroot
	name = "beerroot slice"
	desc = "Tasty slice of beerroot full of alcholol."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "beerroot_slices"
	foodtypes = VEGETABLES | ALCOHOL
	tastes = list("beer" = 1, "piss water" = 3, "parties" = 1)
	food_reagents = list(/datum/reagent/consumable/ethanol/beer = 3)

/obj/item/seeds/jungle/beerroot
	name = "pack of beerroot seeds"
	desc = "These seeds grow into thick roots that produce beer."
	icon_state = "seed-beerroot"
	species = "beerroot"
	plantname = "Beerroots"
	icon_grow = "mold-grow"
	icon_dead = "mold-dead"
	growthstages = 2
	growing_icon = 'icons/obj/hydroponics/growing.dmi'
	product = /obj/item/food/grown/jungle_flora/beerroot
	genes = list(/datum/plant_gene/trait/brewing)
	graft_gene = /datum/plant_gene/trait/brewing

	reagents_add = list(/datum/reagent/consumable/ethanol/beer = 0.2)

/// Bagelshroom

/obj/structure/flora/ash/jungle_plant/bagelshroom
	name = "bagelshroom"
	desc = "Small mushrooms with orange caps. These are especially good if fried!"
	icon_state = "bagelshroom"

	harvested_name = "harvested bagelshrooms"
	harvested_desc = "A colony of tiny bagelshrooms. Looks like someone already had harvested them recently, let em grow up."

	harvest = /obj/item/food/grown/jungle_flora/bagelshroom
	harvest_message_low = "Almost all of bagelshrooms were too young and you only managed to find one good."
	harvest_message_med = "You pick up a few decent bagelshrooms."
	harvest_message_high = "You collect almost whole colony, nice one!"
	number_of_variants = 2

/obj/item/food/grown/jungle_flora/bagelshroom
	name = "bagelshroom"
	desc = "An nice orange mushroom on a white leg. It smells of bread."
	icon_state = "bagelshroom"
	w_class = WEIGHT_CLASS_TINY
	foodtypes = VEGETABLES
	seed = /obj/item/seeds/jungle/bagelshroom

/obj/item/food/grown/jungle_flora/bagelshroom/MakeProcessable()
	AddElement(/datum/element/processable, TOOL_KNIFE, /obj/item/food/cut_bagelshroom, 2, 15)

/obj/item/food/cut_bagelshroom
	name = "cut bagelshroom"
	desc = "Half of a bagelshroom. Where did the other one go?"
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "cut_bagelshroom"
	tastes = list("bread" = 2, "mushrooms" = 1, "dirt" = 1)
	foodtypes = VEGETABLES
	food_reagents = list(/datum/reagent/consumable/nutriment = 2, /datum/reagent/consumable/flour/bagelshroom = 4, /datum/reagent/drug/space_drugs = 4)

/obj/item/food/cut_bagelshroom/MakeGrillable()
	AddComponent(/datum/component/grillable, /obj/item/food/fried_bagelshroom, rand(10 SECONDS, 20 SECONDS), TRUE)

/obj/item/food/fried_bagelshroom
	name = "fried bagelshroom"
	desc = "A tasty, griled bagelshroom."
	icon = 'icons/obj/jungle/brewing.dmi'
	icon_state = "cut_bagelshroom"
	tastes = list("bread" = 2, "mushrooms" = 1, "bagels" = 3)
	foodtypes = VEGETABLES | GRAIN
	food_reagents = list(/datum/reagent/consumable/nutriment = 6)

/obj/item/seeds/jungle/bagelshroom
	name = "bagelshroom mycelium"
	desc = "This mycelium grows into bagelshrooms."
	icon_state = "mycelium-bagelshroom"
	species = "bagelshroom"
	plantname = "Bagelshrooms"
	icon_grow = "bagelshroom-grow"
	icon_dead = "bagelshroom-dead"
	growthstages = 3
	growing_icon = 'icons/obj/hydroponics/growing_mushrooms.dmi'
	product = /obj/item/food/grown/jungle_flora/bagelshroom
	genes = list(/datum/plant_gene/trait/repeated_harvest)
	graft_gene = /datum/plant_gene/trait/repeated_harvest

	reagents_add = list(/datum/reagent/consumable/nutriment = 0.1, /datum/reagent/consumable/flour/bagelshroom = 0.2, /datum/reagent/drug/space_drugs = 0.2)

/// Wild Herbs

/obj/structure/flora/ash/jungle_plant/wild_herbs
	name = "wild herbs"
	desc = "A patch of wild jungle herbs with healing properties."
	icon_state = "herbs"

	needs_sharp_harvest = TRUE

	harvest = /obj/item/food/grown/jungle_flora/wild_herbs
	harvest_message_low = "You pick up a few good herbs."
	harvest_message_med = "You collect some of the herbs."
	harvest_message_high = "You carefully collect all wild herbs from the patch."
	number_of_variants = 5

/obj/structure/flora/ash/jungle_plant/wild_herbs/harvest(user)
	var/rand_harvested = rand(harvest_amount_low, harvest_amount_high)
	if(rand_harvested)
		if(user)
			var/msg = harvest_message_med
			if(rand_harvested == harvest_amount_low)
				msg = harvest_message_low
			else if(rand_harvested == harvest_amount_high)
				msg = harvest_message_high
			to_chat(user, span_notice("[msg]"))
		for(var/i in 1 to rand_harvested)
			new harvest(get_turf(src))

	qdel(src) //These don't regrow
	return TRUE

/obj/item/food/grown/jungle_flora/wild_herbs
	name = "wild herbs"
	desc = "A pack of wild jungle herbs with healing properties."
	icon_state = "jungle_herbs"
	w_class = WEIGHT_CLASS_TINY
	seed = /obj/item/seeds/jungle/wild_herbs
	distill_reagent = /datum/reagent/consumable/ethanol/fernet

/obj/item/seeds/jungle/wild_herbs
	name = "pack of wild herb seeds"
	desc = "These seeds grow into some jungle herbs."
	icon_state = "seed-jungle_herbs"
	species = "jungle_herbs"
	plantname = "Beerroots"
	icon_grow = "jungle_herbs"
	icon_dead = "herbs-dead"
	growthstages = 2
	growing_icon = 'icons/obj/hydroponics/growing.dmi'
	product = /obj/item/food/grown/jungle_flora/wild_herbs

	reagents_add = list(/datum/reagent/medicine/salbutamol = 0.05, /datum/reagent/consumable/nutriment = 0.03, /datum/reagent/consumable/menthol = 0.02)

/obj/item/stack/jungle_log
	name = "jungle wood log"
	desc = "A dark, sturdy log from a jungle tree."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "logs_jungle"
	force = 5
	throwforce = 5
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 2
	throw_range = 3
	attack_verb_continuous = list("bashes", "batters", "bludgeons", "whacks")
	attack_verb_simple = list("bash", "batter", "bludgeon", "whack")

	grind_results = list(/datum/reagent/cellulose = 5)

/obj/item/stack/jungle_log/attackby(obj/item/W, mob/user, params)
	if(W.get_sharpness())
		user.show_message(span_notice("You make wooden planks out of \the [src]!"), MSG_VISUAL)
		var/obj/item/stack/plank = new /obj/item/stack/sheet/mineral/wood(user.loc, 3, FALSE)
		var/old_plank_amount = plank.amount
		for (var/obj/item/stack/ST in user.loc)
			if (ST != plank && istype(ST, /obj/item/stack/sheet/mineral/wood) && ST.amount < ST.max_amount)
				ST.attackby(plank, user)
		if (plank.amount > old_plank_amount)
			to_chat(user, span_notice("You add the newly-formed wooden plank to the stack. It now contains [plank.amount] wooden planks."))
		qdel(src)
	else
		return ..()
