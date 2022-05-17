/datum/slime_color/rainbow
	color = "rainbow"
	coretype = /obj/item/slime_extract/special/rainbow
	slime_tags = SLIME_BLUESPACE_CONNECTION | SLIME_NO_RANDOM_SPAWN
	environmental_req = "Non-standard slime located. Database entry missing."

/datum/slime_color/fiery
	color = "fiery"
	coretype = /obj/item/slime_extract/special/fiery
	slime_tags = SLIME_HOT_LOVING | SLIME_NO_RANDOM_SPAWN | SLIME_ATTACK_SLIMES | SLIME_WATER_WEAKNESS
	environmental_req = "Non-standard slime located. Subject can manipulate flames and ignite it's targets on attack."

/datum/slime_color/biohazard
	color = "biohazard"
	coretype = /obj/item/slime_extract/special/biohazard
	slime_tags = SLIME_NO_RANDOM_SPAWN | SLIME_ATTACK_SLIMES | SLIME_BZ_IMMUNE | SLIME_WATER_RESISTANCE
	environmental_req = "Non-standard slime located. Quarantine or immediate destruction recommended."

/datum/slime_color/biohazard/New(mob/living/simple_animal/slime/slime)
	. = ..()
	slime.AddElement(/datum/element/lifesteal, 5)
	RegisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET, .proc/attempt_poison) //Not using venomous element because it ignores bio armor

/datum/slime_color/biohazard/remove()
	slime.RemoveElement(/datum/element/lifesteal)
	UnregisterSignal(slime, COMSIG_SLIME_ATTACK_TARGET)
	REMOVE_TRAIT(slime, TRAIT_SLIME_RABID, "biohazard_slime")

/datum/slime_color/biohazard/Life(delta_time, times_fired)
	. = ..()
	if(!HAS_TRAIT(slime, TRAIT_SLIME_RABID))
		ADD_TRAIT(slime, TRAIT_SLIME_RABID, "biohazard_slime")

/datum/slime_color/biohazard/proc/attempt_poison(datum/source, atom/target)
	SIGNAL_HANDLER

	if(!iscarbon(target))
		return

	var/mob/living/carbon/victim = target
	if(prob(victim.getarmor(null, BIO)))
		return

	victim.reagents?.add_reagent(/datum/reagent/toxin/tuporixin, 3) //2 hits to start infection

/datum/slime_color/biohazard/get_attack_cd(atom/attack_target) //Faster than normal ones
	return 2.5 SECONDS
