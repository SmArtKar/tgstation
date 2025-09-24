#define NEXT_PARENT_COMMAND "next_parent"

SUBSYSTEM_DEF(overlays)
	name = "Overlay"
	flags = SS_NO_FIRE|SS_NO_INIT
	var/list/stats

/datum/controller/subsystem/overlays/PreInit()
	stats = list()

/datum/controller/subsystem/overlays/Shutdown()
	text2file(render_stats(stats), "[GLOB.log_directory]/overlay.log")

/datum/controller/subsystem/overlays/Recover()
	stats = SSoverlays.stats

/// Converts an overlay list into text for debug printing
/// Of note: overlays aren't actually mutable appearances, they're just appearances
/// Don't have access to that type tho, so this is the best you're gonna get
/proc/overlays2text(list/overlays)
	var/list/unique_overlays = list()
	// As anything because we're basically doing type coercion, rather then actually filtering for mutable appearances
	for(var/mutable_appearance/overlay as anything in overlays)
		var/key = "[overlay.icon]-[overlay.icon_state]-[overlay.dir]"
		unique_overlays[key] += 1
	var/list/output_text = list()
	for(var/key in unique_overlays)
		output_text += "([key]) = [unique_overlays[key]]"
	return output_text.Join("\n")

/proc/iconstate2appearance(icon, iconstate)
	var/static/image/stringbro = new()
	stringbro.icon = icon
	stringbro.icon_state = iconstate
	return stringbro.appearance

/proc/icon2appearance(icon)
	var/static/image/iconbro = new()
	iconbro.icon = icon
	return iconbro.appearance

/atom/proc/build_appearance_list(list/build_overlays)
	if (!islist(build_overlays))
		build_overlays = list(build_overlays)
	for (var/overlay in build_overlays)
		if(!overlay)
			build_overlays -= overlay
			continue
		if (istext(overlay))
			// This is too expensive to run normally but running it during CI is a good test
			if (PERFORM_ALL_TESTS(focus_only/invalid_overlays))
				if(!icon_exists(icon, overlay))
					var/icon_file = "[icon]" || "Unknown Generated Icon"
					stack_trace("Invalid overlay: Icon object '[icon_file]' [REF(icon)] used in '[src]' [type] is missing icon state [overlay].")
					continue

			var/index = build_overlays.Find(overlay)
			build_overlays[index] = iconstate2appearance(icon, overlay)
		else if(isicon(overlay))
			var/index = build_overlays.Find(overlay)
			build_overlays[index] = icon2appearance(overlay)
	return build_overlays

/atom/proc/cut_overlays()
	STAT_START_STOPWATCH
	overlays = null
	POST_OVERLAY_CHANGE(src)
	STAT_STOP_STOPWATCH
	STAT_LOG_ENTRY(SSoverlays.stats, type)

/atom/proc/cut_overlay(list/remove_overlays)
	if(!overlays)
		return
	STAT_START_STOPWATCH
	overlays -= build_appearance_list(remove_overlays)
	POST_OVERLAY_CHANGE(src)
	STAT_STOP_STOPWATCH
	STAT_LOG_ENTRY(SSoverlays.stats, type)

/atom/proc/add_overlay(list/add_overlays)
	if(!overlays)
		return
	STAT_START_STOPWATCH
	overlays += build_appearance_list(add_overlays)
	VALIDATE_OVERLAY_LIMIT(src)
	POST_OVERLAY_CHANGE(src)
	STAT_STOP_STOPWATCH
	STAT_LOG_ENTRY(SSoverlays.stats, type)

/atom/proc/copy_overlays(atom/other, cut_old) //copys our_overlays from another atom
	if(!other)
		if(cut_old)
			cut_overlays()
		return

	STAT_START_STOPWATCH
	var/list/cached_other = other.overlays.Copy()
	if(cut_old)
		if(cached_other)
			overlays = cached_other
		else
			overlays = null
		VALIDATE_OVERLAY_LIMIT(src)
		POST_OVERLAY_CHANGE(src)
		STAT_STOP_STOPWATCH
		STAT_LOG_ENTRY(SSoverlays.stats, type)
	else if(cached_other)
		overlays += cached_other
		VALIDATE_OVERLAY_LIMIT(src)
		POST_OVERLAY_CHANGE(src)
		STAT_STOP_STOPWATCH
		STAT_LOG_ENTRY(SSoverlays.stats, type)

//TODO: Better solution for these?
/image/proc/add_overlay(x)
	overlays |= x

/image/proc/cut_overlay(x)
	overlays -= x

/image/proc/cut_overlays(x)
	overlays.Cut()

/image/proc/copy_overlays(atom/other, cut_old)
	if(!other)
		if(cut_old)
			cut_overlays()
		return

	var/list/cached_other = other.overlays.Copy()
	if(cached_other)
		if(cut_old || !overlays.len)
			overlays = cached_other
		else
			overlays |= cached_other
	else if(cut_old)
		cut_overlays()

// Debug procs

/atom
	/// List of overlay "keys" (info about the appearance) -> mutable versions of static appearances
	/// Drawn from the overlays list
	var/list/realized_overlays
	/// List of underlay "keys" (info about the appearance) -> mutable versions of static appearances
	/// Drawn from the underlays list
	var/list/realized_underlays

/image
	/// List of overlay "keys" (info about the appearance) -> mutable versions of static appearances
	/// Drawn from the overlays list
	var/list/realized_overlays
	/// List of underlay "keys" (info about the appearance) -> mutable versions of static appearances
	/// Drawn from the underlays list
	var/list/realized_underlays

/// Takes the atoms's existing overlays and underlays, and makes them mutable so they can be properly vv'd in the realized_overlays/underlays list
/atom/proc/realize_overlays()
	realized_overlays = realize_appearance_queue(overlays)
	realized_underlays = realize_appearance_queue(underlays)

/// Takes the image's existing overlays, and makes them mutable so they can be properly vv'd in the realized_overlays list
/image/proc/realize_overlays()
	realized_overlays = realize_appearance_queue(overlays)
	realized_underlays = realize_appearance_queue(underlays)

/// Takes a list of appearnces, makes them mutable so they can be properly vv'd and inspected
/proc/realize_appearance_queue(list/appearances)
	var/list/real_appearances = list()
	var/list/queue = appearances.Copy()
	var/queue_index = 0
	while(queue_index < length(queue))
		queue_index++
		// If it's not a command, we assert that it's an appearance
		var/mutable_appearance/appearance = queue[queue_index]
		if(!appearance) // Who fucking adds nulls to their sublists god you people are the worst
			continue

		var/mutable_appearance/new_appearance = new /mutable_appearance()
		new_appearance.appearance = appearance
		var/key = "[appearance.icon]-[appearance.icon_state]-[appearance.plane]-[appearance.layer]-[appearance.dir]-[appearance.color]"
		var/tmp_key = key
		var/appearance_indx = 1
		while(real_appearances[tmp_key])
			tmp_key = "[key]-[appearance_indx]"
			appearance_indx++

		real_appearances[tmp_key] = new_appearance
		var/add_index = queue_index
		// Now check its children
		for(var/mutable_appearance/child_appearance as anything in appearance.overlays)
			add_index++
			queue.Insert(add_index, child_appearance)
		for(var/mutable_appearance/child_appearance as anything in appearance.underlays)
			add_index++
			queue.Insert(add_index, child_appearance)
	return real_appearances

/// Takes two appearances as args, prints out, logs, and returns a text representation of their differences
/// Including suboverlays
/proc/diff_appearances(mutable_appearance/first, mutable_appearance/second, iter = 0)
	var/list/diffs = list()
	var/list/firstdeet = first.vars
	var/list/seconddeet = second.vars
	var/diff_found = FALSE
	for(var/name in first.vars)
		var/firstv = firstdeet[name]
		var/secondv = seconddeet[name]
		if(firstv ~= secondv)
			continue
		if((islist(firstv) || islist(secondv)) && length(firstv) == 0 && length(secondv) == 0)
			continue
		if(name == "vars") // Go away
			continue
		if(name == "_listen_lookup") // This is just gonna happen with marked datums, don't care
			continue
		if(name == "overlays")
			first.realize_overlays()
			second.realize_overlays()
			var/overlays_differ = FALSE
			for(var/i in 1 to length(first.realized_overlays))
				if(diff_appearances(first.realized_overlays[i], second.realized_overlays[i], iter + 1))
					overlays_differ = TRUE

			if(!overlays_differ)
				continue

		diff_found = TRUE
		diffs += "Diffs detected at [name]: First ([firstv]), Second ([secondv])"

	var/text = "Depth of: [iter]\n\t[diffs.Join("\n\t")]"
	message_admins(text)
	log_world(text)
	return diff_found

/// Takes a list of mutable appearances
/// Returns a list in the form:
/// 1 - a list of all mutable appearances that would need to be updated to change planes in the event of a z layer change, alnongside the commands required
/// 	to properly track parents to update
/// 2 - a list of all parents that will require updating
/proc/build_planeed_apperance_queue(list/mutable_appearance/appearances)
	var/list/queue
	if(islist(appearances))
		queue = appearances.Copy()
	else
		queue = list(appearances)
	var/queue_index = 0
	var/list/parent_queue = list()

	// We are essentially going to unroll apperance overlays into a flattened list here, so we can filter out floating planes laster
	// It will look like "overlay overlay overlay (change overlay parent), overlay overlay etc"
	// We can use this list to dynamically update these non floating planes, later
	while(queue_index < length(queue))
		queue_index++
		// If it's not a command, we assert that it's an appearance
		var/mutable_appearance/appearance = queue[queue_index]
		if(!appearance || appearance == NEXT_PARENT_COMMAND) // Who fucking adds nulls to their sublists god you people are the worst
			continue

		var/mutable_appearance/new_appearance = new /mutable_appearance()
		new_appearance.appearance = appearance
		// Now check its children
		if(length(appearance.overlays))
			queue += NEXT_PARENT_COMMAND
			parent_queue += appearance
			for(var/mutable_appearance/child_appearance as anything in appearance.overlays)
				queue += child_appearance

	// Now we have a flattened list of parents and their children
	// Setup such that walking the list backwards will allow us to properly update overlays
	// (keeping in mind that overlays only update if an apperance is removed and added, and this pattern applies in a nested fashion)

	// If we found no results, return null
	if(!length(queue))
		return null

	// ALRIGHT MOTHERFUCKER
	// SO
	// DID YOU KNOW THAT OVERLAY RENDERING BEHAVIOR DEPENDS PARTIALLY ON THE ORDER IN WHICH OVERLAYS ARE ADDED?
	// WHAT WE'RE DOING HERE ENDS UP REVERSING THE OVERLAYS ADDITION ORDER (when it's walked back to front)
	// SO GUESS WHAT I'VE GOTTA DO, I'VE GOTTA SWAP ALLLL THE MEMBERS OF THE SUBLISTS
	// I HATE IT HERE
	var/lower_parent = 0
	var/upper_parent = 0
	var/queue_size = length(queue)
	while(lower_parent <= queue_size)
		// Let's reorder our "lists" (spaces between parent changes)
		// We've got a delta index, and we're gonna essentially use it to get "swap" positions from the top and bottom
		// We only need to loop over half the deltas to swap all the entries, any more and it'd be redundant
		// We floor so as to avoid over flipping, and ending up flipping "back" a delta
		// etc etc
		var/target = FLOOR((upper_parent - lower_parent) / 2, 1)
		for(var/delta_index in 1 to target)
			var/old_lower = queue[lower_parent + delta_index]
			queue[lower_parent + delta_index] = queue[upper_parent - delta_index]
			queue[upper_parent - delta_index] = old_lower

		// lower bound moves to the old upper, upper bound finds a new home
		// Note that the end of the list is a valid upper bound
		lower_parent = upper_parent // our old upper bound is now our lower bound
		while(upper_parent <= queue_size)
			upper_parent += 1
			if(length(queue) < upper_parent) // Parent found
				break
			if(queue[upper_parent] == NEXT_PARENT_COMMAND) // We found em lads
				break

	// One more thing to do
	// It's much more convinient for the parent queue to be a list of indexes pointing at queue locations
	// Rather then a list of copied appearances
	// Let's turn what we have now into that yeah?
	// This'll require a loop over both queues
	// We're using an assoc list here rather then several find()s because I feel like that's more sane
	var/list/apperance_to_position = list()
	for(var/i in 1 to length(queue))
		apperance_to_position[queue[i]] = i

	var/list/parent_indexes = list()
	for(var/mutable_appearance/parent as anything in parent_queue)
		parent_indexes += apperance_to_position[parent]

	// Alright. We should now have two queues, a command/appearances one, and a parents queue, which contain no fluff
	// And when walked backwards allow for proper plane updating
	var/list/return_pack = list(queue, parent_indexes)
	return return_pack

/atom/proc/update_appearance_planes(list/mutable_appearance/appearances, new_offset)
	var/list/build_list = build_planeed_apperance_queue(appearances)

	if(!length(build_list))
		return appearances

	// hand_back contains a new copy of the passed in list, with updated values
	var/list/hand_back = list()

	var/list/processing_queue = build_list[1]
	var/list/parents_queue = build_list[2]
	// Now that we have our queues, we're going to walk them forwards to remove, and backwards to add
	// Note, we need to do this separately because you can only remove a mutable appearance when it
	// Exactly matches the appearance it had when it was first "made static" (by being added to the overlays list)
	var/parents_index = 0
	for(var/item in processing_queue)
		if(item == NEXT_PARENT_COMMAND)
			parents_index++
			continue
		var/mutable_appearance/iter_apper = item
		if(parents_index)
			var/parent_src_index = parents_queue[parents_index]
			var/mutable_appearance/parent = processing_queue[parent_src_index]
			parent.overlays -= iter_apper.appearance
		else // Otherwise, we're at the end of the list, and our parent is the mob
			cut_overlay(iter_apper)

	// Now the back to front stuff, to readd the updated appearances
	var/queue_index = length(processing_queue)
	parents_index = length(parents_queue)
	while(queue_index >= 1)
		var/item = processing_queue[queue_index]
		if(item == NEXT_PARENT_COMMAND)
			parents_index--
			queue_index--
			continue
		var/mutable_appearance/new_iter = new /mutable_appearance()
		new_iter.appearance = item
		if(new_iter.plane != FLOAT_PLANE)
			// Here, finally, is where we actually update the plane offsets
			SET_PLANE_W_SCALAR(new_iter, PLANE_TO_TRUE(new_iter.plane), new_offset)
		if(parents_index)
			var/parent_src_index = parents_queue[parents_index]
			var/mutable_appearance/parent = processing_queue[parent_src_index]
			parent.overlays += new_iter.appearance
		else
			add_overlay(new_iter)
			// chant a protective overlays.Copy to prevent appearance theft and overlay sticking
			// I'm not joking without this overlays can corrupt and be replaced by other appearances
			// the compiler might call it useless but I swear it works
			// we conjure the spirits of the computer with our spells, we conjur- (Hey lemon make a damn issue report already)
			var/list/does_nothing = new_iter.overlays.Copy()
			pass(does_nothing)
			hand_back += new_iter

		queue_index--
	return hand_back

#undef NEXT_PARENT_COMMAND
