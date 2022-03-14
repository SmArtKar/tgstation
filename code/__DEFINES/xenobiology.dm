//gold slime core spawning (used with var/gold_core_spawnable)
/// Mob cannot be spawned with a gold slime core
#define NO_SPAWN 0
/// Mob can spawned with a gold slime core with plasma reaction as a hostile creature
#define HOSTILE_SPAWN 1
/// Mob can be spawned with a gold slime core with blood reaction as a friendly creature
#define FRIENDLY_SPAWN 2

//slime core activation type
/// Jelly species slime ability that causes simple effects that require energized jelly
#define SLIME_ACTIVATE_MINOR 1
/// Jelly species slime ability that causes complex effects that require plasma jelly
#define SLIME_ACTIVATE_MAJOR 2

/// Determines how much light the jelly species emit
#define LUMINESCENT_DEFAULT_GLOW 2

/// How much gases and chemicals can xenoflora pod contain
#define XENOFLORA_MAX_MOLES 3000
#define XENOFLORA_MAX_CHEMS 500
/// How much gases our pod injects per tick(so if plant needs 3 moles of CO2 per tick, pod will inject CO2 until there's 3 * XENOFLORA_POD_INPUT_MULTIPLIER moles)
#define XENOFLORA_POD_INPUT_MULTIPLIER 10

/// How big can a slime pen be
#define MAXIMUM_SLIME_PEN_SIZE 50

/// Slime core prices

#define SLIME_VALUE_TIER_1 200
#define SLIME_VALUE_TIER_2 400
#define SLIME_VALUE_TIER_3 800
#define SLIME_VALUE_TIER_4 1600
#define SLIME_VALUE_TIER_5 3200
#define SLIME_VALUE_TIER_6 6400
#define SLIME_VALUE_TIER_7 12800

#define SLIME_SELL_MODIFIER_MIN 0.94
#define SLIME_SELL_MODIFIER_MAX 0.97
#define SLIME_SELL_OTHER_MODIFIER_MIN 1.01
#define SLIME_SELL_OTHER_MODIFIER_MAX 1.03

/// Slime requirements

/// How much ticks it requires for slime to generate a core
#define SLIME_MAX_CORE_GENERATION 20

/// At what temperature orange slimes start losing nutrition
#define ORANGE_SLIME_UNHAPPY_TEMP T0C+60
/// At what temperature orange slimes start taking damage
#define ORANGE_SLIME_DANGEROUS_TEMP T0C+30

/// At what concentration purple slimes become rabid and start taking damage
#define PURPLE_SLIME_N2O_REQUIRED 3

/// At what temperature blue slimes start taking damage
#define BLUE_SLIME_DANGEROUS_TEMP T0C-10
/// How much water vapor blue slimes create after finishing digesting
#define BLUE_SLIME_PUFF_AMOUNT 10

/// How much CO2 metal slimes require
#define METAL_SLIME_CO2_REQUIRED 3

/// How likely it's for yellow slime to zap per second, multiplied by it's power level
#define YELLOW_SLIME_ZAP_PROB 4
#define YELLOW_SLIME_ZAP_POWER 3000

/// How likely it is for silver slime to implode every second
#define SILVER_SLIME_IMPLODE_PROB 15

/// How much plasma does dark purple slime need
#define DARK_PURPLE_SLIME_PLASMA_REQUIRED 15
/// How likely it is for dark purple slimes to puff out flaming plasma when they're not satisfied
#define DARK_PURPLE_SLIME_PUFF_PROBABILITY 25

/// How cold it should be for dark blue slime
#define DARK_BLUE_SLIME_DANGEROUS_TEMP T0C-40
/// How much water vapor do dark blue slimes want
#define DARK_BLUE_SLIME_VAPOR_REQUIRED 5
/// How fast are we losing cores
#define DARK_BLUE_SLIME_CORE_LOSE 10

/// How likely it is for a bluespace slime to teleport through something
#define BLUESPACE_SLIME_TELEPORT_CHANCE 5
/// How much can bluespace slime travel in one teleport
#define BLUESPACE_SLIME_TELEPORT_DISTANCE 3

/// Tags for slime colors

/// These slimes lose nutrition while in range of a slime discharger.
#define DISCHARGER_WEAKENED (1<<0)
