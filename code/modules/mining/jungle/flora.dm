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
	harvest_message_low = "You take a few berries from the bush but accidentally squish most of them."
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
	tastes = list("incredible sweetness" = 5, "bitter raspberries" = 2, "chineese noodles" = 1) //Hard joke
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
	genes = list(/datum/plant_gene/trait/repeated_harvest, /datum/plant_gene/trait/maxchem)
	reagents_add = list(/datum/reagent/consumable/sugar = 0.04, /datum/reagent/consumable/nutriment = 0.02, /datum/reagent/consumable/nutriment/vitamin = 0.1)

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
