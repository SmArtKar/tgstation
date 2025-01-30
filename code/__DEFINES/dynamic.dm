/*
/// This is the only ruleset that should be picked this round, used by admins and should not be on rulesets in code.
#define ONLY_RULESET (1<<0)

/// Only one ruleset with this flag will be picked.
#define HIGH_IMPACT_RULESET (1<<1)

/// This ruleset can only be picked once. Anything that does not have a scaling_cost MUST have this.
#define LONE_RULESET (1<<2)

/// This is a "heavy" midround ruleset, and should be run later into the round
#define HEAVY_RULESET (1<<3)

/// Max number of teams we can have for the abductor ruleset
#define ABDUCTOR_MAX_TEAMS 4

// Ruletype defines
#define ROUNDSTART_RULESET "Roundstart"
#define LATEJOIN_RULESET "Latejoin"
#define MIDROUND_RULESET "Midround"

#define RULESET_NOT_FORCED "not forced"
/// Ruleset should run regardless of population and threat available
#define RULESET_FORCE_ENABLED "force enabled"
/// Ruleset should not run regardless of population and threat available
#define RULESET_FORCE_DISABLED "force disabled"

/// Kill this ruleset from continuing to process
#define RULESET_STOP_PROCESSING 1

// Flavor ruletypes, used by station traits
/// Rulesets selected by dynamic at default
#define RULESET_CATEGORY_DEFAULT (1 << 0)
/// Rulesets not including crew antagonists, non-witting referring to antags like obsessed which aren't really enemies of the station
#define RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS (1 << 1)

// Threat tiers
/// Core sector, no antags
#define THREAT_TIER_ZERO "core_sector"
/// Yellow star, low threat for lowpop
#define THREAT_TIER_ONE "yellow_star"
/// Orange star, low-mid threat
#define THREAT_TIER_TWO "orange_star"
/// Red star, mid-high threat
#define THREAT_TIER_THREE "red_star"
/// Black orbit, extreme threat
#define THREAT_TIER_FOUR "black_orbit"
/// Midnight sun, may god have mercy on your soul
#define THREAT_TIER_FIVE "midnight_sun"

/*
/// No round event was hijacked this cycle
#define HIJACKED_NOTHING "HIJACKED_NOTHING"

/// This cycle, a round event was hijacked when the last midround event was too recent.
#define HIJACKED_TOO_RECENT "HIJACKED_TOO_RECENT"


/// Requirements when something needs a lot of threat to run, but still possible at low-pop
#define REQUIREMENTS_VERY_HIGH_THREAT_NEEDED list(90,90,90,80,60,50,40,40,40,40)
*/
*/
