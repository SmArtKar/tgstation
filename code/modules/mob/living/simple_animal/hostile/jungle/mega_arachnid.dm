//Large and powerful, but timid. It won't engage anything above 50 health, or anything without legcuffs.
//It can fire fleshy snares that legcuff anyone that it hits, making them look especially tasty to the arachnid.
/mob/living/simple_animal/hostile/jungle/mega_arachnid
	name = "mega arachnid"
	desc = "Though physically imposing, it prefers to ambush its prey, and it will only engage with an already crippled opponent."
	icon = 'icons/mob/jungle/arachnid.dmi'
	icon_state = "arachnid"
	icon_living = "arachnid"
	icon_dead = "arachnid_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BUG
	melee_damage_lower = 30
	melee_damage_upper = 30
	butcher_results = list(/obj/item/food/meat/slab/xeno = 4, /obj/item/stack/sheet/bone = 4)
	maxHealth = 500
	health = 500
	speed = 14
	ranged = 1
	pixel_x = -16
	base_pixel_x = -16
	move_to_delay = 10
	aggro_vision_range = 9
	speak_emote = list("chitters")
	attack_sound = 'sound/weapons/bladeslice.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	ranged_cooldown_time = 60
	projectiletype = /obj/projectile/mega_arachnid
	projectilesound = 'sound/weapons/pierce.ogg'
	alpha = 50

	footstep_type = FOOTSTEP_MOB_CLAW

	crusher_loot = /obj/item/crusher_trophy/acid_sack

/mob/living/simple_animal/hostile/jungle/mega_arachnid/Life(delta_time = SSMOBS_DT, times_fired)
	..()
	if(target && ranged_cooldown > world.time && iscarbon(target))
		var/mob/living/carbon/C = target
		if(!C.legcuffed && C.health < 50)
			retreat_distance = 9
			minimum_distance = 9
			alpha = 125
			return
	retreat_distance = 0
	minimum_distance = 0
	alpha = 255


/mob/living/simple_animal/hostile/jungle/mega_arachnid/Aggro()
	..()
	alpha = 255

/mob/living/simple_animal/hostile/jungle/mega_arachnid/LoseAggro()
	..()
	alpha = 50

/obj/projectile/mega_arachnid
	name = "flesh snare"
	nodamage = TRUE
	damage = 0
	icon_state = "tentacle_end"

/obj/projectile/mega_arachnid/on_hit(atom/target, blocked = FALSE)
	if(iscarbon(target) && blocked < 100)
		var/obj/item/restraints/legcuffs/beartrap/mega_arachnid/B = new /obj/item/restraints/legcuffs/beartrap/mega_arachnid(get_turf(target))
		B.spring_trap(null, target)
	return ..()

/obj/item/restraints/legcuffs/beartrap/mega_arachnid
	name = "fleshy restraints"
	desc = "Used by mega arachnids to immobilize their prey."
	item_flags = DROPDEL
	flags_1 = NONE
	icon_state = "tentacle_end"
	icon = 'icons/obj/guns/projectiles.dmi'

/obj/item/crusher_trophy/acid_sack //Blood-drunk eye analogue. Works slightly different
	name = "acid sack"
	desc = "A still pulsing sack full of acidic blood. Suitable as a trophy for a kinetic crusher."
	icon_state = "acid_sack"
	denied_type = /obj/item/crusher_trophy/acid_sack

/obj/item/crusher_trophy/acid_sack/effect_desc()
	return "mark detonation to gain temporal stun and slowdown immunity. Each normal hit with crusher while it's active makes the effect last slightly longer."

/obj/item/crusher_trophy/acid_sack/on_mark_detonation(mob/living/target, mob/living/user)
	user.apply_status_effect(STATUS_EFFECT_ACID_SACK)

/obj/item/crusher_trophy/acid_sack/on_melee_hit(mob/living/target, mob/living/user)
	var/datum/status_effect/acid_sack/C = user.has_status_effect(STATUS_EFFECT_ACID_SACK)
	if(C)
		C.duration += 0.5 SECONDS //Not enough time to infinitely stack it.

/obj/item/crusher_trophy/acid_sack/add_to(obj/item/kinetic_crusher/H, mob/living/user)
	for(var/t in H.trophies)
		var/obj/item/crusher_trophy/T = t
		if(istype(T, denied_type) || istype(T, /obj/item/crusher_trophy/axe_head) || istype(src, T.denied_type))	//Conflicts with Axe Head. I don't want them to stack sack effect infinitely
			to_chat(user, "<span class='warning'>You can't seem to attach [src] to [H]. Maybe remove a few trophies?</span>")
			return FALSE
	if(!user.transferItemToLoc(src, H))
		return
	H.trophies += src
	to_chat(user, "<span class='notice'>You attach [src] to [H].</span>")
	return TRUE
