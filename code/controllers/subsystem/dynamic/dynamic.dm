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
	/// Actual rolled threat for tier recalculation roundstart_recalculation_time dcs after roundstart
	/// This is done so that if most pop joins immediatelly after roundstart, we still can roll black orbit and above despite a "lowpop" launch
	var/threat_roll = 0

	/// How many more light midrounds have we summoned already
	var/midrounds_spent = 0
	/// How many heavy midrounds have we summoned already
	var/heavy_midrounds_spent = 0
	/// How many latejoins have we summoned already
	var/latejoins_spent = 0

	/// Number of players who were ready on roundstart.
	var/roundstart_pop_ready = 0
	/// List of candidates used on roundstart rulesets.
	var/list/roundstart_candidates = list()
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
	var/roundstart_announcement_min = 1 MINUTES
	/// What is the higher bound of when the roundstart announcement is sent out?
	var/roundstart_announcement_max = 3 MINUTES

	/// How long do we wait before attempting to recalculate threat if the roundstart pop was too low?
	/// Setting this to 0 disables the recalculation
	var/roundstart_recalculation_time = 3 MINUTES

	// ----------- Automatically generated values ------------
	// Do not edit anything below this line, its all fetched from configs or generated on runtime
	/// Dynamic configuration, loaded on pre_setup
	var/list/configuration = null
	/// All threat tier datums, loaded and modified from config
	var/list/dynamic_threat_tiers = null
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
	setup_threat()
	// Roundstart rulesets are assigned here because they may hang refs to new_player
	var/list/roundstart_rulesets = init_rulesets(/datum/dynamic_ruleset/roundstart)
	// Assign roles between players
	SSjob.divide_occupations(pure = TRUE, allow_all = TRUE)

	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		// Only consider readied up players
		if(player.ready != PLAYER_READY_TO_PLAY || !player.mind || !player.check_preferences())
			continue
		// If the player has a job assigned, add them to the list of candidates for antags
		if(!is_unassigned_job(player.mind.assigned_role))
			roundstart_pop_ready++
			roundstart_candidates.Add(player)
			continue
		// Someone has an unassigned job as they weren't able to get a spot in the round
		var/list/job_data = list()
		var/job_prefs = player.client.prefs.job_preferences
		for(var/job in job_prefs)
			var/priority = job_prefs[job]
			job_data += "[job]: [SSjob.job_priority_level_to_string(priority)]"
		to_chat(player, span_danger("You were unable to qualify for any roundstart antagonist role this round because your job preferences presented a high chance of all of your selected jobs being unavailable, along with 'return to lobby if job is unavailable' enabled. Increase the number of roles set to medium or low priority to reduce the chances of this happening."))
		log_admin("[player.ckey] failed to qualify for any roundstart antagonist role because their job preferences presented a high chance of all of their selected jobs being unavailable, along with 'return to lobby if job is unavailable' enabled and has [player.client.prefs.be_special.len] antag preferences enabled. They will be unable to qualify for any roundstart antagonist role. These are their job preferences - [job_data.Join(" | ")]")

	SSjob.reset_occupations()
	log_dynamic("Listing [roundstart_rules.len] round start rulesets, and [candidates.len] players ready.")
	if (candidates.len <= 0)
		log_dynamic("Found [candidates.len] candidates, aborting.")
		return TRUE

	var/list/forced_roundstart = list()
	for (var/datum/dynamic_ruleset/roundstart/ruleset in GLOB.dynamic_forced_rulesets)
		forced_roundstart += ruleset

	if(length(forced_roundstart) > 0)
		rigged_roundstart(forced_roundstart)
	else
		roundstart(roundstart_rules)

	var/starting_rulesets = list()
	// This should only contain roundstart rules
	for (var/datum/dynamic_ruleset/roundstart/rule as anything in executed_rules)
		starting_rulesets += rule.name
	log_dynamic("Picked the following roundstart rules: [english_list(starting_rulesets)].")
	candidates.Cut()
	return TRUE

/// Called after everyone is equipped with their job
/datum/controller/subsystem/dynamic/proc/post_setup()
	for(var/datum/dynamic_ruleset/roundstart/rule as anything in executed_rules)
		rule.candidates.Cut() // The rule should not use candidates at this point as they all are null.
		addtimer(CALLBACK(src, PROC_REF(execute_roundstart_rule), rule), rule.delay)

	if (!CONFIG_GET(flag/no_intercept_report))
		addtimer(CALLBACK(src, PROC_REF(send_intercept)), rand(roundstart_announcement_min, roundstart_announcement_max))

	// Handle roundstart suicides/logouts
	addtimer(CALLBACK(src, PROC_REF(display_roundstart_logout_report)), ROUNDSTART_LOGOUT_REPORT_TIME)
	if(CONFIG_GET(flag/reopen_roundstart_suicide_roles))
		var/delay = CONFIG_GET(number/reopen_roundstart_suicide_roles_delay)
		if(delay)
			delay *= (1 SECONDS)
		else
			delay = (4 MINUTES) //default to 4 minutes if the delay isn't defined.
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(reopen_roundstart_suicide_roles)), delay)

/// Initializes all threats and rulesets
/datum/controller/subsystem/dynamic/proc/initialize_threats()
	for (var/tier_id in GLOB.dynamic_threat_tier_types)
		var/tier_type = GLOB.dynamic_threat_tier_types[tier_id]
		var/datum/dynamic_tier/tier = new tier_type()
		dynamic_threat_tiers[tier_id] = tier

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

/// Calculates the threat level for the round
/datum/controller/subsystem/dynamic/proc/setup_threat()
	log_dynamic("Dynamic mode parameters for the round:")
	if (GLOB.dynamic_forced_threat_tier)
		threat_tier = GLOB.dynamic_threat_tier_types[GLOB.dynamic_forced_threat_tier]
		set_cooldowns()
		log_dynamic("Dynamic mode was forced to threat tier [threat_tier]!")
		return

	var/maximum_roll = 0
	var/list/roll_values = list()
	for (var/tier_id in dynamic_threat_tiers)
		var/datum/threat_tier/tier = dynamic_threat_tiers[tier_id]
		maximum_roll += tier.weight
		roll_values[tier_id] = maximum_roll
	threat_roll = rand(1, maximum_roll)
	for (var/tier_id in dynamic_threat_tiers)
		if (threat_roll <= roll_values[tier_id])
			threat_tier = tier_id
			break

	log_dynamic("Dynamic mode initialized with a threat tier [threat_tier]!")
	set_cooldowns()

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

/// Reports a list of logged out / suicided crew to admins
/datum/controller/subsystem/dynamic/proc/display_roundstart_logout_report()
	var/list/msg = list("[span_boldnotice("Roundstart logout report")]\n\n")
	for(var/mob/living/player as anything in GLOB.mob_living_list)
		if (iscarbon(player) && !player.last_mind)
			continue  // never had a client

		if(player.ckey && !GLOB.directory[player.ckey])
			msg += "<b>[player.name]</b> ([player.key]), the [player.job] (<font color='#ffcc00'><b>Disconnected</b></font>)\n"

		if(player.ckey && player.client)
			var/failed = FALSE
			if(player.client.inactivity >= ROUNDSTART_LOGOUT_AFK_THRESHOLD) //Connected, but inactive (alt+tabbed or something)
				msg += "<b>[player.name]</b> ([player.key]), the [player.job] (<font color='#ffcc00'><b>Connected, Inactive</b></font>)\n"
				failed = TRUE //AFK client
			if(!failed && player.stat)
				if(HAS_TRAIT(player, TRAIT_SUICIDED)) //Suicider
					msg += "<b>[player.name]</b> ([player.key]), the [player.job] ([span_bolddanger("Suicide")])\n"
					failed = TRUE //Disconnected client
				if(!failed && (player.stat == UNCONSCIOUS || player.stat == HARD_CRIT))
					msg += "<b>[player.name]</b> ([player.key]), the [player.job] (Dying)\n"
					failed = TRUE //Unconscious
				if(!failed && player.stat == DEAD)
					msg += "<b>[player.name]</b> ([player.key]), the [player.job] (Dead)\n"
					failed = TRUE //Dead

			continue //Happy connected client

		for(var/mob/dead/observer/ghost as anything in GLOB.dead_mob_list)
			if(ghost.mind && ghost.mind.current == player)
				if(player.stat == DEAD)
					if(HAS_TRAIT(player, TRAIT_SUICIDED)) //Suicider
						msg += "<b>[player.name]</b> ([ckey(ghost.mind.key)]), the [player.job] ([span_bolddanger("Suicide")])\n"
						continue //Disconnected client
					else
						msg += "<b>[player.name]</b> ([ckey(ghost.mind.key)]), the [player.job] (Dead)\n"
						continue //Dead mob, ghost abandoned
				else
					if(ghost.can_reenter_corpse)
						continue //Adminghost, or cult/wizard ghost
					else
						msg += "<b>[player.name]</b> ([ckey(ghost.mind.key)]), the [player.job] ([span_bolddanger("Ghosted")])\n"
						continue //Ghosted while alive

	var/concatenated_message = msg.Join()
	log_admin(concatenated_message)
	to_chat(GLOB.admins, concatenated_message)


/proc/reopen_roundstart_suicide_roles()
	var/include_command = CONFIG_GET(flag/reopen_roundstart_suicide_roles_command_positions)
	var/list/reopened_jobs = list()

	for(var/mob/living/quitter as anything in GLOB.suicided_mob_list)
		var/datum/job/job = SSjob.get_job(quitter.job)
		if(!job || !(job.job_flags & JOB_REOPEN_ON_ROUNDSTART_LOSS))
			continue
		if(!include_command && job.departments_bitflags & DEPARTMENT_BITFLAG_COMMAND)
			continue
		job.current_positions = max(job.current_positions - 1, 0)
		reopened_jobs += quitter.job

	if(CONFIG_GET(flag/reopen_roundstart_suicide_roles_command_report))
		if(reopened_jobs.len)
			var/reopened_job_report_positions
			for(var/dead_dudes_job in reopened_jobs)
				reopened_job_report_positions = "[reopened_job_report_positions ? "[reopened_job_report_positions]\n":""][dead_dudes_job]"

			var/suicide_command_report = {"
				<font size = 3><b>[command_name()] Human Resources Board</b><br>
				Notice of Personnel Change</font><hr>
				To personnel management staff aboard [station_name()]:<br><br>
				Our medical staff have detected a series of anomalies in the vital sensors
				of some of the staff aboard your station.<br><br>
				Further investigation into the situation on our end resulted in us discovering
				a series of rather... unforturnate decisions that were made on the part of said staff.<br><br>
				As such, we have taken the liberty to automatically reopen employment opportunities for the positions of the crew members
				who have decided not to partake in our research. We will be forwarding their cases to our employment review board
				to determine their eligibility for continued service with the company (and of course the
				continued storage of cloning records within the central medical backup server.)<br><br>
				<i>The following positions have been reopened on our behalf:<br><br>
				[reopened_job_report_positions]</i>
			"}

			print_command_report(suicide_command_report, "Central Command Personnel Update")
