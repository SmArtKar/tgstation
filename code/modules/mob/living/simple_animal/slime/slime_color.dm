/datum/slime_color
	var/color = "error" //I hate british people, there was C O L O U R everywhere
	var/coretype = /obj/item/slime_extract
	var/list/mutations
	var/list/food_types = list() //Mob nutrition value is based on their health, while items' is always the same and only depends on the coeff

	var/mob/living/simple_animal/slime/slime

/datum/slime_color/New(slime)
	. = ..()
	src.slime = slime
	if(!mutations)
		mutations = list(type, type, type, type)

/datum/slime_color/proc/Life(delta_time, times_fired) //For handling special behavior

/datum/slime_color/proc/finished_digesting(food)

/datum/slime_color/proc/finished_digesting_living(food)

//Tier 1

/datum/slime_color/grey
	color = "grey"
	coretype = /obj/item/slime_extract/grey
	mutations = list(/datum/slime_color/orange, /datum/slime_color/metal, /datum/slime_color/blue, /datum/slime_color/purple)
	food_types = list(/datum/species/monkey = 1)

//Tier 2

/datum/slime_color/purple
	color = "purple"
	coretype = /obj/item/slime_extract/purple
	mutations = list(/datum/slime_color/dark_blue, /datum/slime_color/dark_purple, /datum/slime_color/green, /datum/slime_color/green)

/datum/slime_color/blue
	color = "blue"
	coretype = /obj/item/slime_extract/blue
	mutations = list(/datum/slime_color/dark_blue, /datum/slime_color/silver, /datum/slime_color/pink, /datum/slime_color/pink)

/datum/slime_color/metal
	color = "metal"
	coretype = /obj/item/slime_extract/metal
	mutations = list(/datum/slime_color/yellow, /datum/slime_color/silver, /datum/slime_color/gold, /datum/slime_color/gold)

/datum/slime_color/orange
	color = "orange"
	coretype = /obj/item/slime_extract/orange
	mutations = list(/datum/slime_color/yellow, /datum/slime_color/dark_purple, /datum/slime_color/red, /datum/slime_color/red)
	food_types = list(/mob/living/simple_animal/xenofauna/wobble_chicken = 4, /mob/living/simple_animal/xenofauna/wobble_chicken/chick = 3, /obj/item/food/wobble_egg = 0.75)

/datum/slime_color/orange/Life(delta_time, times_fired)
	var/turf/our_turf = get_turf(src)
	var/datum/gas_mixture/our_mix = our_turf.return_air()
	if(our_mix?.temperature >= T0C+40)
		return

	slime.adjust_nutrition(-10 * delta_time)
	if(slime.nutrition <= 0)
		slime.set_nutrition(0)

	if(our_mix?.temperature >= T0C+20)
		return

	slime.adjustBruteLoss(3)

//Tier 3

/datum/slime_color/dark_blue
	color = "dark blue"
	coretype = /obj/item/slime_extract/darkblue
	mutations = list(/datum/slime_color/blue, /datum/slime_color/purple, /datum/slime_color/cerulean, /datum/slime_color/cerulean)

/datum/slime_color/dark_purple
	color = "dark purple"
	coretype = /obj/item/slime_extract/darkpurple
	mutations = list(/datum/slime_color/purple, /datum/slime_color/orange, /datum/slime_color/sepia, /datum/slime_color/sepia)

/datum/slime_color/silver
	color = "silver"
	coretype = /obj/item/slime_extract/silver
	mutations = list(/datum/slime_color/blue, /datum/slime_color/metal, /datum/slime_color/pyrite, /datum/slime_color/pyrite)

/datum/slime_color/yellow
	color = "yellow"
	coretype = /obj/item/slime_extract/yellow
	mutations = list(/datum/slime_color/orange, /datum/slime_color/metal, /datum/slime_color/bluespace, /datum/slime_color/bluespace)

//Tier 4

/datum/slime_color/red
	color = "red"
	coretype = /obj/item/slime_extract/red
	mutations = list(/datum/slime_color/red, /datum/slime_color/red, /datum/slime_color/oil, /datum/slime_color/oil)

/datum/slime_color/green
	color = "green"
	coretype = /obj/item/slime_extract/green
	mutations = list(/datum/slime_color/green, /datum/slime_color/green, /datum/slime_color/black, /datum/slime_color/black)

/datum/slime_color/pink
	color = "pink"
	coretype = /obj/item/slime_extract/pink
	mutations = list(/datum/slime_color/pink, /datum/slime_color/pink, /datum/slime_color/light_pink, /datum/slime_color/light_pink)

/datum/slime_color/gold
	color = "gold"
	coretype = /obj/item/slime_extract/gold
	mutations = list(/datum/slime_color/gold, /datum/slime_color/gold, /datum/slime_color/adamantine, /datum/slime_color/adamantine)

//Tier 4.5

/datum/slime_color/cerulean
	color = "cerulean"
	coretype = /obj/item/slime_extract/cerulean
	mutations = null

/datum/slime_color/sepia
	color = "sepia"
	coretype = /obj/item/slime_extract/sepia
	mutations = null

/datum/slime_color/pyrite
	color = "pyrite"
	coretype = /obj/item/slime_extract/pyrite
	mutations = null

/datum/slime_color/bluespace
	color = "bluespace"
	coretype = /obj/item/slime_extract/bluespace
	mutations = null

//Tier 5

/datum/slime_color/oil
	color = "oil"
	coretype = /obj/item/slime_extract/oil
	mutations = null

/datum/slime_color/black
	color = "black"
	coretype = /obj/item/slime_extract/black
	mutations = null

/datum/slime_color/adamantine
	color = "adamantine"
	coretype = /obj/item/slime_extract/adamantine
	mutations = null

/datum/slime_color/light_pink
	color = "light pink"
	coretype = /obj/item/slime_extract/lightpink
	mutations = null

//Tier 6

/datum/slime_color/rainbow
	color = "rainbow"
	coretype = /obj/item/slime_extract/rainbow
	mutations = null
