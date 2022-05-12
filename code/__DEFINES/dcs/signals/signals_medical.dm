/// From /datum/surgery/New(): (datum/surgery/surgery, surgery_location (body zone), obj/item/bodypart/targeted_limb)
#define COMSIG_MOB_SURGERY_STARTED "mob_surgery_started"

/// From /datum/surgery_step/success(): (datum/surgery_step/step, mob/living/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results)
#define COMSIG_MOB_SURGERY_STEP_SUCCESS "mob_surgery_step_success"

///from base of /obj/item/bodypart/proc/attach_limb(): (new_limb, new_owner, special) allows you to fail limb attachment
#define COMSIG_ATTACH_LIMB "attach_limb"
	#define COMPONENT_NO_ATTACH (1<<0)
///from base of /obj/item/bodypart/proc/drop_limb(lost_limb, last_owner, dismembered)
#define COMSIG_REMOVE_LIMB "remove_limb"
