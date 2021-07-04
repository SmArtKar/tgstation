/mob/living/simple_animal/hostile/rogue_drone
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
