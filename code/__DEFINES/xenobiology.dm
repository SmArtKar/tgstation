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

#define BLUESPACE_ANCHOR_RANGE 5

/// Slime core prices

#define SLIME_VALUE_TIER_1 200
#define SLIME_VALUE_TIER_2 400
#define SLIME_VALUE_TIER_3 800
#define SLIME_VALUE_TIER_4 1600
#define SLIME_VALUE_TIER_5 3200
#define SLIME_VALUE_TIER_6 6400
#define SLIME_VALUE_TIER_7 12800

#define SLIME_SELL_MODIFIER_MIN 	  -0.09
#define SLIME_SELL_MODIFIER_MAX 	  -0.06
#define SLIME_SELL_OTHER_MODIFIER_MIN 0.02
#define SLIME_SELL_OTHER_MODIFIER_MAX 0.05
#define SLIME_SELL_MAXIMUM_MODIFIER   2
#define SLIME_SELL_MINIMUM_MODIFIER   0.25

/// How many seconds it takes for slime to generate a core
#define SLIME_MAX_CORE_GENERATION 20

/// If slime requires high temperatures and a hotspot is located, damage will be multiplied by this
#define HOT_SLIME_HOTSPOT_DAMAGE_MODIFIER 0.35
/// How much warp chance is added per second when a bluespace connected slime is being anchored
#define SLIME_WARPCHANCE_INCREASE 1

/// Damages per second when slimes' requirements are not satisfied
#define SLIME_DAMAGE_LOW  (150 / 600)  //10 minutes to die
#define SLIME_DAMAGE_MED  (150 / 420)  //7 minutes to die
#define SLIME_DAMAGE_HIGH (150 / 300)   //5 minutes to die


/// Slime requirements


/// At what temperature orange slimes start losing nutrition
#define ORANGE_SLIME_UNHAPPY_TEMP T0C+60
/// At what temperature orange slimes start taking damage
#define ORANGE_SLIME_DANGEROUS_TEMP T0C+30

/// At what concentration purple slimes become rabid and start taking damage
#define PURPLE_SLIME_N2O_REQUIRED 35

/// At what temperature blue slimes start taking damage
#define BLUE_SLIME_DANGEROUS_TEMP T0C-10
/// How much water vapor blue slimes create after finishing digesting
#define BLUE_SLIME_PUFF_AMOUNT 10
/// Blue slimes won't puff water vapor if there's more gas than this
#define BLUE_SLIME_MAX_WATER_VAPOR 15

/// How much CO2 metal slimes require
#define METAL_SLIME_CO2_REQUIRED 40

/// How likely it's for yellow slime to zap per second, multiplied by it's power level
#define YELLOW_SLIME_ZAP_PROB 4
#define YELLOW_SLIME_ZAP_POWER 3000
/// How much damage yellow slime takes as a result of uncontained discharge
#define YELLOW_SLIME_DISCHARGE_DAMAGE 15 //10 discharges will kill the slime

/// How likely it is for silver slime to implode every second
#define SILVER_SLIME_IMPLODE_PROB 10

/// How much plasma does dark purple slime need
#define DARK_PURPLE_SLIME_PLASMA_REQUIRED 25
/// Maximum amount of oxygen dark purple slimes can handle
#define DARK_PURPLE_SLIME_OXYGEN_MAXIMUM 2
/// How likely it is for dark purple slimes to puff out flaming plasma when they're not satisfied
#define DARK_PURPLE_SLIME_PUFF_PROBABILITY 25

/// How cold it should be for dark blue slime
#define DARK_BLUE_SLIME_DANGEROUS_TEMP T0C-40
/// How much water vapor do dark blue slimes want
#define DARK_BLUE_SLIME_VAPOR_REQUIRED 7
/// How fast are we losing cores
#define DARK_BLUE_SLIME_CORE_LOSE 10

/// How likely it is for a bluespace slime to teleport through something
#define BLUESPACE_SLIME_TELEPORT_CHANCE 5
/// How much can bluespace slime travel in one teleport
#define BLUESPACE_SLIME_TELEPORT_DISTANCE 3

/// How much bz sepia slimes need
#define SEPIA_SLIME_BZ_REQUIRED 10
/// How likely it is for sepia slime to stop time when there's not enough hydrogen in the air
#define SEPIA_SLIME_TIMESTOP_CHANCE 10
/// How likely it is for sepia slime to stop time when it's attacking
#define SEPIA_SLIME_ATTACK_TIMESTOP_CHANCE 15
/// How long sepia timestop lasts
#define SEPIA_SLIME_TIMESTOP_DURATION 3 SECONDS
/// How long sepia slimes recover from timestop
#define SEPIA_SLIME_TIMESTOP_RECOVERY 17 SECONDS

/// Pyrite slimes will either need this temperature OR a hotspot ontop of them
#define PYRITE_SLIME_COMFORTABLE_TEMPERATURE T0C + 480
/// How long pyrite slimes can survive without fire before they get damaged, in seconds. While fiery charge is higher than zero their attacks also apply fire stacks and ignite
/// This is required due to flame and hotspot inconsistency
#define PYRITE_SLIME_MAX_FIERY_CHARGE 25

/// Cerulean slimes will check for starlight in this range
#define CERULEAN_SLIME_STARLIGHT_RANGE 2
/// How much charge can cerulean slime hold
#define CERULEAN_SLIME_MAX_CHARGE 100
/// How much charged a slime needs to make a wall
#define CERULEAN_SLIME_CHARGE_PER_WALL 20
/// How much cerulean charge is gained per second
#define CERULEAN_SLIME_CHARGE_PER_SECOND 1
/// How much cerulean charge is gained additionnaly through starlight turfs
#define CERULEAN_SLIME_CHARGE_PER_STARLIGHT 0.05
/// How much damage cerulean slimes do
#define CERULEAN_SLIME_UNHAPPY_OBJECT_DAMAGE 25 /// Enough to break airlocks. GIVE THEM THE STARLIGHT THEY WANT
/// Probability of cerulean slime knockbacking their target and fabricating a wall
#define CERULEAN_SLIME_WALL_PROBABILITY 30

/// Required pressure for oil slimes
#define OIL_SLIME_REQUIRED_PRESSURE ONE_ATMOSPHERE * 6
/// How likely is oil slime explosion when there's no vacuole stabilizer
#define OIL_SLIME_EXPLOSION_CHANCE 45
/// How likely it is for oil slime to use an explosive attack
#define OIL_SLIME_EXPLOSIVE_ATTACK_CHANCE 25


/// Tags for slime colors


/// These slimes lose nutrition while in range of a slime discharger.
#define SLIME_DISCHARGER_WEAKENED (1<<0)
/// These slimes get damaged when they're affected by a bluespace anchor
#define SLIME_BLUESPACE_CONNECTION (1<<1)
/// These slimes are immune to damage from water
#define SLIME_WATER_IMMUNITY (1<<2)
/// These slimes will trigger pyrite thrower
#define SLIME_HOT_LOVING (1<<3)
/// These slimes are immune to BZ stasis effect. Still affected by backpack stasis!
#define SLIME_BZ_IMMUNE (1<<4)
