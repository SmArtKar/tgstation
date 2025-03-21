/*
 * Allows mobs to crawl under tables
 * It takes some time to get under an atom with this element, and crawling prevents people from being elevated or standing up.
 */

/datum/element/crawlable_under
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH_ON_HOST_DESTROY
	argument_hash_start_idx = 2
	/// How long it takes to crawl under our parent
	var/delay
	/// Layer that mobs are adjusted to when crawling
	var/layer

/datum/element/crawlable_under/Attach(atom/movable/target, crawl_delay, crawl_layer)
	. = ..()
	if(!istype(target))
		return ELEMENT_INCOMPATIBLE

	delay = crawl_delay
	layer = crawl_layer

	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(target, COMSIG_ATOM_BUMPED, PROC_REF(on_bumped_into))
	//if (isliving(target))
	//	RegisterSignal(target, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(on_position_change))
	if (isturf(target.loc))
		register_turf(target.loc)

/datum/element/crawlable_under/Detach(atom/movable/source)
	. = ..()
	UnregisterSignal(source, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_BUMPED))
	if (isturf(source.loc))
		unregister_turf(source.loc)

/datum/element/crawlable_under/proc/on_moved(atom/movable/mover, turf/old_loc)
	SIGNAL_HANDLER
	if (istype(old_loc))
		unregister_turf(old_loc)
	if (isturf(mover.loc))
		register_turf(mover.loc)

/datum/element/crawlable_under/proc/on_bumped_into(atom/movable/source, atom/movable/hit_object) // CRAWLING_TRAIT
	SIGNAL_HANDLER

	if (!isliving(hit_object))
		return

	var/mob/living/bumped = hit_object
	if (bumped.body_position != LYING_DOWN || !(bumped.mobility_flags & MOBILITY_MOVE))
		return

	// This is jank, but bumped can be called from things like shoves, etc, so we check if they want to move under us
	if (bumped.client?.intended_direction & get_dir(bumped, source))
		INVOKE_ASYNC(src, PROC_REF(crawl_under), source, bumped)

/datum/element/crawlable_under/proc/crawl_under(atom/movable/target, mob/living/crawler)
	crawler.visible_message(span_warning("[crawler] starts crawling under [target]"), span_notice("You start crawling under [target]..."))
	if (!do_after(crawler, delay, target))
		crawler.balloon_alert(crawler, "interrupted!")
		return

	// do_after should stop if target gets qdeleted so we're safe
	var/old_density = target.density
	target.set_density(FALSE)
	if (!step(crawler, target))
		target.set_density(old_density)
		return

	target.set_density(old_density)
	crawler.visible_message(span_warning("[crawler] crawls under [target]."), span_notice("You crawl under [target]."))
	log_combat(crawler, target, "crawled under")


/datum/element/crawlable_under/proc/register_turf(atom/movable/source, turf/new_turf)
	return

/datum/element/crawlable_under/proc/unregister_turf(atom/movable/source, turf/old_turf)
	return
