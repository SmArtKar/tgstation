///From mob/living/simple_animal/slime/attack_target(): (atom/target)
#define COMSIG_SLIME_ATTACK_TARGET "slime_attack_target"
	#define COMPONENT_SLIME_NO_ATTACK  (1<<0) //Cancels the attack
///From mob/living/simple_animal/slime/CanFeedon(): (atom/target)
#define COMSIG_SLIME_CAN_FEED "slime_can_feed"
	#define COMPONENT_SLIME_NO_FEED  (1<<0) //Cancels the feeding
///From mob/living/simple_animal/slime/regenerate_icons(): ()
#define COMSIG_SLIME_REGENERATE_ICONS "slime_regenerate_icons"
	#define COMPONENT_SLIME_NO_ICON_REGENERATION  (1<<0) //Cancels icon regeneration in case you, for some reason, want to keep the appearance
#define COMSIG_SLIME_POST_REGENERATE_ICONS "slime_post_regenerate_icons"
///From mob/living/simple_animal/slime/Feedstop() and mob/living/simple_animal/slime/handle_digestion(): (atom/target)
#define COMSIG_SLIME_DIGESTED "slime_digested"
///From mob/living/simple_animal/slime/start_moveloop(atom/move_target): (datum/move_loop/move_loop)
#define COMSIG_SLIME_START_MOVE_LOOP "slime_start_move_loop"
///From mob/living/simple_animal/slime/post_move(): (direction, datum/move_loop/move_loop, bumped)
#define COMSIG_SLIME_SQUEESING_ATTEMPT "slime_squeesing_attempt"
	#define COMPONENT_SLIME_NO_SQUEESING  (1<<0) //Cancels default squeesing in this direction
