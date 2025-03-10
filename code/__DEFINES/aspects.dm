#define ACTIVE_CHECK_SUCCESS_EXP 100
#define PASSIVE_CHECK_SUCCESS_EXP 20

/// Base value to add to pass floor in skillchecks
#define PASS_BASE_VALUE 5

#define SKILLCHECK_TRIVIAL 2
#define SKILLCHECK_EASY 3
#define SKILLCHECK_MEDIUM 5
#define SKILLCHECK_CHALLENGING 6
#define SKILLCHECK_FORMIDDABLE 7
#define SKILLCHECK_LEGENDARY 9
#define SKILLCHECK_HEROIC 11
#define SKILLCHECK_GODLY 13
#define SKILLCHECK_IMPOSSIBLE 99 // Pray for that Nat 20

#define CHECK_CRIT_FAILURE 1
#define CHECK_FAILURE 2
#define CHECK_SUCCESS 3
#define CHECK_CRIT_SUCCESS 4

// Aspect constants
/// Level of aspects which non-disco spessmen have (aka normal stats)
#define ASPECT_NEUTRAL_LEVEL 2

/// Health added per level of Endurance
#define ENDURANCE_HEALTH_BOOST 10
/// Increase to divider of damage slowdown per level of endurance
#define ENDURANCE_DAMAGE_SLOWDOWN_REDUCTION 7.5
/// Level of endurance at which you get analgesia
#define ENDURANCE_ANALGESIA_LEVEL 6

/// Movespeed increase per level of Savoir Faire
#define SAVOIR_FAIRE_MOVESPEED_MULTIPLIER -0.05
/// Attack speed reduction per level of Savoir Faire
#define SAVOIR_FAIRE_ATTACK_SPEED_REDUCTION 0.5

/// Hand/eye level at which you don't need to wield heavy guns
#define HAND_EYE_FREE_WIELD_LEVEL 4
/// Hand/eye level at which gun successes turn into critical successes
#define HAND_EYE_ALWAYS_CRIT_LEVEL 6
/// Hand/eye level at which you can akimbo fire *any* guns
#define HAND_EYE_AKIMBO_ANY_LEVEL 8
