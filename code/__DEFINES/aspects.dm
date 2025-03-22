#define SKILLCHECK_SUCCESS_EXP 45
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
/// We have slightly roughly 75% (on per-job basis) allocated roundstart, slightly worse than a normal spaceman if you exclude player-allocated points
#define ASPECT_LEVEL_NEUTRAL 2
/// Maximum level that any aspect can have, after all modifiers applied
#define ASPECT_LEVEL_MAXIMUM 16

/// Percentile health boost for mechs, cyborgs and bots per level of Four Legged Wheelbarrel that crafter has
#define FOUR_LEGGED_WHEELBARREL_HEALTH_BOOST 0.1
/// Percentile speed boost for mechs per level of Four Legged Wheelbarrel that crafter has
#define FOUR_LEGGED_WHEELBARREL_SPEED_BOOST 0.05

/// Flat nightvision increase in maintenance per level of Grey Tide past ASPECT_LEVEL_NEUTRAL
#define GREY_TIDE_MAINT_NIGHTVIS 2
/// Level at which we get full value out of Grey Tide nightvision
#define GREY_TIDE_NIGHTVIS_LEVEL 6

/// How much armor penetration do batons get per level of Command?
#define COMMAND_BATON_PENETRATION 5

/// Increase/reduction of high/low sanity effects per level of Morale
#define MORALE_SANITY_EFFECT_MODIFIER 0.1
/// Percentile increase of addiction points required to develop one per level of Morale
#define MORALE_ADDICTION_RESISTANCE 0.05

/// Health added per level of Endurance
#define ENDURANCE_HEALTH_BOOST 7.5
/// Increase to divider of damage slowdown per level of Endurance
#define ENDURANCE_DAMAGE_SLOWDOWN_REDUCTION 5
/// Level of Endurance at which you get analgesia
#define ENDURANCE_ANALGESIA_LEVEL 8

/// Level of Shivers at which user gets antimagic rolls
#define SHIVERS_ANTIMAGIC_LEVEL 4
/// Level of Shivers at which user can freely wield magical items
#define SHIVERS_MAGIC_GIFT_LEVEL 8

/// Percentile increase of OD threshold per level of Electrochemistry
#define ELECTROCHEMISTRY_OD_BOOST 0.05

/// Damage increase per level of Physical Instrument
#define PHYSICAL_INSTRUMENT_DAMAGE_BOOST 2
/// Percentile decrease of equipment slowdowns per level of Physical Instrument
#define PHYSICAL_INSTRUMENT_SLOWDOWN_NEGATION 0.075
/// Level of Physical Instrument at which you can pry doors open with your bare hands
#define PHYSICAL_INSTRUMENT_DOORPRYER_LEVEL 10
#define PHYSICAL_INSTRUMENT_INTERACTION "physical_instrument"
/// How much experience you get by prying open a door
#define DOOR_PRIED_EXP 150

/// Movespeed increase per level of Savoir Faire
#define SAVOIR_FAIRE_MOVESPEED_MULTIPLIER -0.04
/// Attack speed reduction per level of Savoir Faire
#define SAVOIR_FAIRE_ATTACK_SPEED_REDUCTION 0.4

/// Hand/Eye level at which you don't need to wield heavy guns
#define HAND_EYE_FREE_WIELD_LEVEL 6
/// Hand/Eye level at which you can akimbo fire *any* guns
#define HAND_EYE_AKIMBO_ANY_LEVEL 8
/// Hand/Eye level at which gun successes turn into critical successes
#define HAND_EYE_ALWAYS_CRIT_LEVEL 10

/// How much night vision do we gain per level of Perception past ASPECT_LEVEL_NEUTRAL
#define PERCEPTION_NIGHTVIS_MULT 2.5

/// Receive +1 difficulty per X wires
#define WIRE_RAT_WIRES_PER_DIFFICULTY 3
/// Boost you receive for having wire knowledge
#define WIRE_RAT_KNOWLEDGE_BOOST 7

/// Level at which you hold your breath when you see dangerous gases
#define IN_AND_OUT_HOLD_BREATH_LEVEL 4
/// Speed boost per additional level of In and Out while holding your breath
#define IN_AND_OUT_MOVESPEED_MULTIPLIER -0.075
/// Stop, drop and roll speed boost by square of current level of In and Out
#define IN_AND_OUT_EXTINGUISH_DELAY_REDUCTION 0.15 SECONDS
