/// Chance that a quest will spawn in a certain round
#define QUEST_ROUND_PROBABILITY 66
/// Chance that there'll be more than one quest per round (if there's enough quest types)
#define ADDITIONAL_QUEST_PROBABILITY 33
// Questing subsystem, responsible for spawning (and later probably ticking) different round quests
SUBSYSTEM_DEF(questing)
	name = "Questing"
	flags = SS_NO_FIRE

	var/list/quest_types = list(
		/obj/machinery/hoverfab,
	)

/datum/controller/subsystem/questing/Initialize()
	if (!prob(QUEST_ROUND_PROBABILITY))
		return
	while (length(quest_types) && length(GLOB.quest_spawns))
		var/turf/point = pick_n_take(GLOB.quest_spawns)
		var/quest_type = pick_n_take(quest_types)
		new quest_type(point)
		if (!prob(ADDITIONAL_QUEST_PROBABILITY))
			break
	return SS_INIT_SUCCESS

#undef QUEST_ROUND_PROBABILITY
#undef ADDITIONAL_QUEST_PROBABILITY
