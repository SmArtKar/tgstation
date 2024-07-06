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

/// How long does it take a human to push through an unupgraded field
#define CORRAL_FIELD_PASS_DELAY 2 SECONDS
/// How much damage an unupgraded corral generator can sustain before rebooting
#define CORRAL_GENERATOR_BASE_CHARGE 300
/// How long does it take for the corral generator to start recovering
#define CORRAL_GENERATOR_RECOVERY_TIMER 5 SECONDS
/// How much energy the corral generator recovers per second after not being attacked
#define CORRAL_GENERATOR_RECOVERY 10
/// Maximum radius for corral floodfill
#define CORRAL_MAXIMUM_SEARCH_RANGE 9
