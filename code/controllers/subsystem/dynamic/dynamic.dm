/// If enabled does not accept or execute any rulesets.
GLOBAL_VAR_INIT(dynamic_forced_extended, FALSE)
/// Forced threat tier, 0-5
GLOBAL_VAR_INIT(dynamic_forced_threat_tier, null)
/// List of forced rulesets
GLOBAL_LIST_EMPTY(dynamic_forced_rulesets)

/// Ordered list of all threat tiers, to check as fallbacks
GLOBAL_LIST_INIT(dynamic_threat_tier_types, list(
	THREAT_TIER_ZERO = /datum/threat_tier/zero,
	THREAT_TIER_ONE = /datum/threat_tier/one,
	THREAT_TIER_TWO = /datum/threat_tier/two,
	THREAT_TIER_THREE = /datum/threat_tier/three,
	THREAT_TIER_FOUR = /datum/threat_tier/four,
	THREAT_TIER_FIVE = /datum/threat_tier/five,
))

/// Modify the threat level for station traits before dynamic can be Initialized. List(instance = threat_reduction)
GLOBAL_LIST_EMPTY(dynamic_station_traits)

SUBSYSTEM_DEF(dynamic)
	name = "Dynamic"
	flags = SS_NO_INIT
	wait = 1 SECONDS

	/// Shift threat tier
	/// Defines how many rulesets can roll in a round, and how likely specific rulesets are to occur
	var/threat_tier = THREAT_TIER_ZERO

	/// How many more light midrounds have we summoned already
	var/midrounds_spent = 0
	/// How many heavy midrounds have we summoned already
	var/heavy_midrounds_spent = 0
	/// How many latejoins have we summoned already
	var/latejoins_spent = 0

	/// Number of players who were ready on roundstart.
	var/roundstart_pop_ready = 0
	/// List of candidates used on roundstart rulesets.
	var/list/candidates = list()
	/// Rules that are processed, rule_process is called on the rules in this list.
	var/list/current_rules = list()
	/// List of executed rulesets.
	var/list/executed_rules = list()

	// ----------- Configurable values ------------
	// These are the values you should edit via dynamic.json config, these and only these

	/// When world.time is over this number the mode tries to inject a latejoin ruleset.
	var/latejoin_injection_cooldown = 0
	/// The minimum time the recurring latejoin ruleset timer is allowed to be.
	var/latejoin_delay_min = (5 MINUTES)
	/// The maximum time the recurring latejoin ruleset timer is allowed to be.
	var/latejoin_delay_max = (25 MINUTES)

	/// What is the lower bound of when the roundstart announcement is sent out?
	var/roundstart_announcement_min = 1 MINUTE
	/// What is the higher bound of when the roundstart announcement is sent out?
	var/roundstart_announcement_max = 3 MINUTES

	// ----------- Automatically generated values ------------
	// Do not edit anything below this line, its all fetched from configs or generated on runtime
	/// Dynamic configuration, loaded on pre_setup
	var/list/configuration = null
	/// All threat tier datums, loaded and modified from config
	var/list/dynamic_threat_tiers = null
	/// All roundstart rulesets
	var/list/roundstart_rulesets = null
	/// All midround rulesets
	var/list/midround_rulesets = null
	/// All heavy midround rulesets
	var/list/heavy_midround_rulesets = null
	/// All latejoin rulesets
	var/list/latejoin_rulesets = null

/// Dynamic initialization proc. Called BEFORE everyone is equipped with their job
/datum/controller/subsystem/dynamic/proc/pre_setup()
	initialize_threats()
	load_config()

/// Initializes all threats and rulesets
/datum/controller/subsystem/dynamic/proc/initialize_threats()
	for (var/tier_id in GLOB.dynamic_threat_tier_types)
		var/tier_type = GLOB.dynamic_threat_tier_types[tier_id]
		var/datum/dynamic_tier/tier = new tier_type()
		dynamic_threat_tiers[tier_id] = tier

	roundstart_rulesets = init_rulesets(/datum/dynamic_ruleset/roundstart)
	midround_rulesets = init_rulesets(/datum/dynamic_ruleset/midround)
	heavy_midround_rulesets = init_rulesets(/datum/dynamic_ruleset/midround, heavy = TRUE)
	latejoin_rulesets = init_rulesets(/datum/dynamic_ruleset/latejoin)

/// Populates our lists with rulesets of passed type. Avoids HEAVY_RULESET ones unless heavy is TRUE, otherwise returns only them
/datum/controller/subsystem/dynamic/proc/init_rulesets(ruleset_type, heavy = FALSE)
	. = list()
	for (var/datum/dynamic_ruleset/ruleset_type as anything in subtypesof(ruleset_subtype))
		if (initial(ruleset_type.name) == "")
			continue
		if (initial(ruleset_type.weight) == 0)
			continue
		if ((initial(ruleset_type.flags) & HEAVY_RULESET) != heavy)
			continue
		var/datum/dynamic_ruleset/ruleset = new ruleset_type
		configure_ruleset(ruleset)
		. += ruleset

/// Loads dynamic data from dynamic.json
/datum/controller/subsystem/dynamic/proc/load_config()
	if (!CONFIG_GET(flag/dynamic_config_enabled))
		return
	var/json_file = file("[global.config.directory]/dynamic.json")
	if (!fexists(json_file))
		return

	configuration = json_decode(file2text(json_file))
	if (configuration["Dynamic"])
		load_dynamic_config()

	if (configuration["Station"])
		load_station_config()

	if (configuration["Threat"])
		load_threat_config()

/// Loads dynamic configuraton
/datum/controller/subsystem/dynamic/proc/load_dynamic_config()
	for (var/variable in configuration["Dynamic"])
		if (!(variable in vars))
			stack_trace("Invalid dynamic configuration variable [variable] in game mode variable changes.")
			continue
		vars[variable] = configuration["Dynamic"][variable]

/// Loads station trait configuraton
/datum/controller/subsystem/dynamic/proc/load_station_config()
	for (var/datum/station_trait/station_trait as anything in GLOB.dynamic_station_traits)
		var/list/station_trait_config = LAZYACCESSASSOC(configuration, "Station", station_trait.dynamic_threat_id)
		var/cost = station_trait_config["cost"]
		if (isnull(cost)) // 0 is valid so check for null specifically
			return
		if (cost != GLOB.dynamic_station_traits[station_trait])
			log_dynamic("Config set [station_trait.dynamic_threat_id] cost from [station_trait.threat_reduction] to [cost]")
		GLOB.dynamic_station_traits[station_trait] = cost

/// Loads threat level configuraton
/datum/controller/subsystem/dynamic/proc/load_threat_config()
	for (var/tier_id in GLOB.dynamic_threat_tier_types)
		var/datum/dynamic_tier/tier = dynamic_threat_tiers[tier_id]
		var/list/tier_config = LAZYACCESSASSOC(configuration, "Threat", tier_id)
		if (!tier_config)
			continue
		for (var/variable in tier_config)
			if (!(variable in tier.vars))
				stack_trace("Invalid dynamic configuration variable [variable] in threat variable changes.")
				continue
			tier.vars[variable] = tier_config[variable]

/// Loads ruleset configuration
/datum/controller/subsystem/dynamic/proc/configure_ruleset(datum/dynamic_ruleset/ruleset)
	var/rule_conf = LAZYACCESSASSOC(configuration, ruleset.ruletype, ruleset.name)
	for (var/variable in rule_conf)
		if (!(variable in ruleset.vars))
			stack_trace("Invalid dynamic configuration variable [variable] in [ruleset.ruletype] [ruleset.name].")
			continue
		ruleset.vars[variable] = rule_conf[variable]
	ruleset.restricted_roles |= SSstation.antag_restricted_roles
	if (length(ruleset.protected_roles)) //if we care to protect any role, we should protect station trait roles too
		ruleset.protected_roles |= SSstation.antag_protected_roles
	if (CONFIG_GET(flag/protect_roles_from_antagonist))
		ruleset.restricted_roles |= ruleset.protected_roles
	if (CONFIG_GET(flag/protect_assistant_from_antagonist))
		ruleset.restricted_roles |= JOB_ASSISTANT
