// simple_animal signals
/// called when a simplemob is given sentience from a potion (target = person who sentienced)
#define COMSIG_SIMPLEMOB_SENTIENCEPOTION "simplemob_sentiencepotion"

// /mob/living/simple_animal/hostile signals
///before attackingtarget has happened, source is the attacker and target is the attacked
#define COMSIG_HOSTILE_PRE_ATTACKINGTARGET "hostile_pre_attackingtarget"
	#define COMPONENT_HOSTILE_NO_ATTACK (1<<0) //cancel the attack, only works before attack happens
///after attackingtarget has happened, source is the attacker and target is the attacked, extra argument for if the attackingtarget was successful
#define COMSIG_HOSTILE_POST_ATTACKINGTARGET "hostile_post_attackingtarget"
///from base of mob/living/simple_animal/hostile/regalrat: (mob/living/simple_animal/hostile/regalrat/king)
#define COMSIG_RAT_INTERACT "rat_interaction"
///FROM mob/living/simple_animal/hostile/ooze/eat_atom(): (atom/target, edible_flags)
#define COMSIG_OOZE_EAT_ATOM "ooze_eat_atom"
	#define COMPONENT_ATOM_EATEN  (1<<0)
///From mob/living/simple_animal/slime/attack_target(): (atom/target)
#define COMSIG_SLIME_ATTACK_TARGET "slime_attack_target"
	#define COLOR_SLIME_NO_ATTACK  (1<<0) //Cancels the attack
///From mob/living/simple_animal/slime/CanFeedon(): (atom/target)
#define COMSIG_SLIME_CAN_FEED "slime_can_feed"
	#define COLOR_SLIME_NO_FEED  (1<<0) //Cancels the feeding
///From mob/living/simple_animal/slime/regenerate_icons(): ()
#define COMSIG_SLIME_REGENERATE_ICONS "slime_regenerate_icons"
	#define COLOR_SLIME_NO_ICON_REGENERATION  (1<<0) //Cancels icon regeneration in case you, for some reason, want to keep the appearance
///From mob/living/simple_animal/slime/start_moveloop(): (atom/move_target, datum/move_loop/new_loop)
#define COMSIG_SLIME_START_MOVELOOP "slime_start_moveloop"
