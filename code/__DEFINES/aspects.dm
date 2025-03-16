#define SKILLCHECK_SUCCESS_EXP 20
#define SKILLCHECK_DIFFICULTY_BONUS 3

// Because we're working with 3d6 the distribution is *not linear*
// Probabilities for winning/losing a certain roll, creds to Kapu
//   Success % | Failure %
// 3 -  100.00 | 0.00
// 4 -  99.54  | 0.46
// 5 -  98.15  | 1.85
// 6 -  95.37  | 4.63
// 7 -  90.74  | 9.26
// 8 -  83.80  | 16.20
// 9 -  74.07  | 25.93
// 10 - 62.50  | 37.50
// 11 - 50.00  | 50.00
// 12 - 37.50  | 62.50
// 13 - 25.93  | 74.07
// 14 - 16.20  | 83.80
// 15 - 9.26   | 90.74
// 16 - 4.63   | 95.37
// 17 - 1.85   | 98.15
// 18 - 0.46   | 99.54

// These are probabilities that would be shown at ASPECT_LEVEL_NEUTRAL
#define SKILLCHECK_GUARANTEED 4 // Just for crit failures, not displayed as separate difficulty
#define SKILLCHECK_PRIMITIVE 6 // Hard to lose, but possible. Also not displayed, for the same reason
#define SKILLCHECK_TRIVIAL 7
#define SKILLCHECK_EASY 9
#define SKILLCHECK_MEDIUM 10
#define SKILLCHECK_HARD 11
#define SKILLCHECK_CHALLENGING 12
#define SKILLCHECK_FORMIDDABLE 13
#define SKILLCHECK_LEGENDARY 14
#define SKILLCHECK_GODLY 16
#define SKILLCHECK_IMPOSSIBLE 99 // Cannot be won outside of triple 6

#define CHECK_CRIT_FAILURE 1
#define CHECK_FAILURE 2
#define CHECK_SUCCESS 3
#define CHECK_CRIT_SUCCESS 4

// Aspect constants
/// Level of aspects which non-disco spessmen have (aka normal stats).
/// We have slightly roughly 75% (on per-job basis) allocated roundstart, slightly worse if you exclude player-allocated points
/// Multiply this by amount of attributes, divide by 2 - that's the amount of points people should be allowed to allocate
#define ASPECT_LEVEL_NEUTRAL 2

/// Health added per level of Endurance
#define ENDURANCE_HEALTH_BOOST 7.5
/// Increase to divider of damage slowdown per level of endurance
#define ENDURANCE_DAMAGE_SLOWDOWN_REDUCTION 5
/// Level of endurance at which you get analgesia
#define ENDURANCE_ANALGESIA_LEVEL 8

/// Movespeed increase per level of Savoir Faire
#define SAVOIR_FAIRE_MOVESPEED_MULTIPLIER -0.04
/// Attack speed reduction per level of Savoir Faire
#define SAVOIR_FAIRE_ATTACK_SPEED_REDUCTION 0.5

/// Hand/eye level at which you don't need to wield heavy guns
#define HAND_EYE_FREE_WIELD_LEVEL 6
/// Hand/eye level at which you can akimbo fire *any* guns
#define HAND_EYE_AKIMBO_ANY_LEVEL 8
/// Hand/eye level at which gun successes turn into critical successes
#define HAND_EYE_ALWAYS_CRIT_LEVEL 10

/// How much night vision do we gain per level of perception past ASPECT_LEVEL_NEUTRAL
#define PERCEPTION_NIGHTVIS_MULT 2.5

/// Receive +1 difficulty per X wires
#define WIRE_RAT_WIRES_PER_DIFFICULTY 3
/// Boost you receive for having wire knowledge
#define WIRE_RAT_KNOWLEDGE_BOOST 7
