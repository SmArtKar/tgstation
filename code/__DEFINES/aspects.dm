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
/// Level of Endurance at which we have 100 health and no slowdown mod
#define ENDURANCE_NEUTRAL_LEVEL 2
/// Health added per level of Endurance
#define ENDURANCE_HEALTH_BOOST 10
/// Increase to divider of damage slowdown per level of enduracne
#define ENDURANCE_DAMAGE_SLOWDOWN_REDUCTION 7.5

/// Level of Savoir Faire at which attack and movement speed becomes neutral
#define SAVOIR_FAIRE_NEUTRAL_LEVEL 2
/// Movespeed increase per level of Savoir Faire
#define SAVOIR_FAIRE_MOVESPEED_MULTIPLIER -0.05
/// Attack speed reduction per level of Savoir Faire
#define SAVOIR_FAIRE_ATTACK_SPEED_REDUCTION 0.5
