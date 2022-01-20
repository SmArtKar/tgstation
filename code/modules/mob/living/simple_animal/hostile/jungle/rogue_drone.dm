#define HEALTH_LOST_PER_REPAIR 75
#define ATTACK_LOST_PER_REPAIR 5

/mob/living/simple_animal/hostile/jungle/rogue_drone
	name = "rogue drone"
	desc = "A malfunctioning repair drone that now has only one goal - to kill. It's monitor is glowing bright red and it is holding a small handdrill in it's claws."
	icon = 'icons/mob/drone.dmi'
	icon_state = "drone_repair_hacked"
	icon_living = "drone_repair_hacked"
	icon_dead = "drone_repair_hacked_dead"
	mob_biotypes = MOB_ROBOTIC
	mob_size = MOB_SIZE_SMALL
	gender = NEUTER
	environment_smash = ENVIRONMENT_SMASH_NONE
	speak_emote = list("chirps")
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	health = 70
	maxHealth = 70
	damage_coeff = list(BRUTE = 1, BURN = 0.5, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	melee_damage_lower = 10
	melee_damage_upper = 10
	obj_damage = 0
	faction = list("jungle", "boss")
	attack_sound = 'sound/weapons/drill.ogg'
	attack_verb_continuous = "drills"
	attack_verb_simple = "drills"
	vision_range = 9
	del_on_death = TRUE //or else there will be A LOT of corpses after and during the fight
	var/nogib = FALSE
	var/mob/living/simple_animal/hostile/megafauna/jungle/ancient_ai/master_ai

/mob/living/simple_animal/hostile/jungle/rogue_drone/death(gibbed)
	if(master_ai)
		master_ai.drones -= src
	. = ..()

/mob/living/simple_animal/hostile/jungle/rogue_drone/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_CRUSHER_VUNERABLE, INNATE_TRAIT)

/mob/living/simple_animal/hostile/jungle/rogue_drone/electrocute_act(shock_damage, source, siemens_coeff = 1, flags = NONE)
	return

/mob/living/simple_animal/hostile/jungle/rogue_drone/AttackingTarget()
	. = ..()
	if(. && isliving(target) && !istype(target, /mob/living/simple_animal/hostile/jungle/rogue_drone) && !nogib)
		var/mob/living/L = target
		if(L.stat != DEAD)
			if(L.health <= HEALTH_THRESHOLD_DEAD && HAS_TRAIT(L, TRAIT_NODEATH)) //Gibs the poor dead souls
				L.gib()
		else
			L.gib()

/mob/living/simple_animal/hostile/jungle/rogue_drone/pet_drone
	name = "experimental drone"
	desc = "An experimental companion drone with additional reinforcements."
	icon_state = "drone_repair_green"
	icon_living = "drone_repair_green"
	icon_dead = "drone_repair_dead"
	health = 300
	maxHealth = 300
	melee_damage_lower = 20
	melee_damage_upper = 20
	faction = list("neutral")
	nogib = TRUE
	del_on_death = FALSE
	ai_controller = /datum/ai_controller/hostile_friend
	var/steel_applied = FALSE

/mob/living/simple_animal/hostile/jungle/rogue_drone/pet_drone/Initialize(mapload)
	. = ..()
	REMOVE_TRAIT(src, TRAIT_CRUSHER_VUNERABLE, INNATE_TRAIT)

/mob/living/simple_animal/hostile/jungle/rogue_drone/pet_drone/proc/activate(mob/owner)
	faction.Add("[REF(owner)]")
	if(ai_controller)
		var/datum/ai_controller/hostile_friend/ai_current_controller = ai_controller
		ai_current_controller.befriend(owner)
		can_have_ai = FALSE
		toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/jungle/rogue_drone/pet_drone/attackby(obj/item/I, mob/living/user, params)
	if(stat == DEAD)
		if(istype(I, /obj/item/stack/sheet/iron))
			if(maxHealth <= 0)
				to_chat(user, span_warning("[src] there's nothing to repare anymore!"))
				return

			if(steel_applied)
				to_chat(user, span_warning("[src] is already in good condition, you only need to boot it up!"))
				return
			var/obj/item/stack/sheet/iron/sheet = I
			if(!sheet.use(5))
				to_chat(user, span_warning("You need at least 5 sheets to repair [src]!"))
				return
			steel_applied = TRUE
			return

		if(I.tool_behaviour == TOOL_MULTITOOL)
			if(!do_after(user, 40, target = src))
				return
			maxHealth -= HEALTH_LOST_PER_REPAIR //With each repair it becomes weaker and weaker
			melee_damage_lower -= ATTACK_LOST_PER_REPAIR
			melee_damage_upper -= ATTACK_LOST_PER_REPAIR
			revive(TRUE, TRUE)
			to_chat(user, span_notice("You successfully boot [src] up!"))
			steel_applied = FALSE

	. = ..()

#undef HEALTH_LOST_PER_REPAIR
#undef ATTACK_LOST_PER_REPAIR
