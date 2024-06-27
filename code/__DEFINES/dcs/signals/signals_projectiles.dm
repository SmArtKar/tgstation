
// /obj/projectile signals (sent to the firer)

///from base of /obj/projectile/proc/on_hit(), like COMSIG_PROJECTILE_ON_HIT but on the projectile itself and with the hit limb (if any): (atom/movable/firer, atom/target, angle, hit_limb, blocked)
#define COMSIG_PROJECTILE_SELF_ON_HIT "projectile_self_on_hit"
///from base of /obj/projectile/proc/on_hit(): (atom/movable/firer, atom/target, angle, hit_limb, blocked)
#define COMSIG_PROJECTILE_ON_HIT "projectile_on_hit"
///from base of /obj/projectile/proc/fire(): (obj/projectile, atom/original_target)
#define COMSIG_PROJECTILE_BEFORE_FIRE "projectile_before_fire"
///from base of /obj/projectile/proc/fire(): (obj/projectile, atom/firer, atom/original_target)
#define COMSIG_PROJECTILE_FIRER_BEFORE_FIRE "projectile_firer_before_fire"
///from the base of /obj/projectile/proc/fire(): ()
#define COMSIG_PROJECTILE_FIRE "projectile_fire"
///sent to the projectile from the base of /obj/projectile/proc/process_impact(atom/target): (atom/target)
#define COMSIG_PROJECTILE_SELF_IMPACT "projectile_self_impact"
	#define PROJECTILE_INTERRUPT_IMPACT (1<<0)
///from the base of /obj/projectile/proc/process_hit(atom/target): (atom/target)
#define COMSIG_PROJECTILE_PREHIT "projectile_prehit"
	#define PROJECTILE_INTERRUPT_HIT (1<<0)
///from the base of /obj/projectile/after_move(): ()
#define COMSIG_PROJECTILE_AFTER_MOVE "projectile_after_move"
///from the base of /obj/projectile/max_range(): ()
#define COMSIG_PROJECTILE_MAX_RANGE "projectile_max_range"
///from [/obj/item/proc/tryEmbed] sent when trying to force an embed (mainly for projectiles and eating glass)
#define COMSIG_EMBED_TRY_FORCE "item_try_embed"
	#define COMPONENT_EMBED_SUCCESS (1<<1)
// FROM [/obj/item/proc/updateEmbedding] sent when an item's embedding properties are changed : ()
#define COMSIG_ITEM_EMBEDDING_UPDATE "item_embedding_update"

///sent to targets during the process_hit proc of projectiles
#define COMSIG_FIRE_CASING "fire_casing"

///from the base of /obj/item/ammo_casing/ready_proj() : (atom/target, mob/living/user, quiet, zone_override, atom/fired_from)
#define COMSIG_CASING_READY_PROJECTILE "casing_ready_projectile"

///sent to the projectile after an item is spawned by the projectile_drop element: (new_item)
#define COMSIG_PROJECTILE_ON_SPAWN_DROP "projectile_on_spawn_drop"
///sent to the projectile when spawning the item (shrapnel) that may be embedded: (new_item)
#define COMSIG_PROJECTILE_ON_SPAWN_EMBEDDED "projectile_on_spawn_embedded"

/// from /obj/projectile/energy/fisher/on_hit() or /obj/item/gun/energy/recharge/fisher when striking a target
#define COMSIG_HIT_BY_SABOTEUR "hit_by_saboteur"
	#define COMSIG_SABOTEUR_SUCCESS (1<<0)
