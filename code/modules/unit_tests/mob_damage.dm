/// Tests to make sure mob damage procs are working correctly
/datum/unit_test/mob_damage
	priority = TEST_LONGER

/datum/unit_test/mob_damage/Destroy()
	SSmobs.ignite()
	return ..()

/datum/unit_test/mob_damage/Run()
	SSmobs.pause()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human/consistent)
	dummy.maxHealth = 200 // tank mode

	/* The sanity tests: here we make sure that:
	1) That damage procs are returning the expected values. They should be returning the actual amount of damage taken/healed.
		(Negative values mean damage was taken, positive mean healing)
	2) Verifying that the damage has been accurately applied to the mob afterwards. */

	test_sanity_simple(dummy)
	test_sanity_complex(dummy)

	// Testing if biotypes are working as intended
	test_biotypes(dummy)

	// Testing whether or not TRAIT_NOBREATH is working as intended
	test_nobreath(dummy)

	// Testing whether or not TRAIT_TOXINLOVER and TRAIT_TOXIMMUNE are working as intended
	test_toxintraits(dummy)

	// Testing the proc ordered_healing()
	test_ordered_healing(dummy)

	// testing with godmode enabled
	test_godmode(dummy)

/**
 * Test whether the adjust damage procs return the correct values and that the mob's health is the expected value afterwards.
 *
 * By default this calls apply_damage(amount) followed by verify_damage(amount_after) and returns TRUE if both succeeded.
 * amount_after defaults to the mob's current stamina loss but can be overridden as needed.
 *
 * Arguments:
 * * testing_mob - the mob to apply the damage to
 * * amount - the amount of damage to apply to the mob
 * * expected - what the expected return value of the damage proc is
 * * amount_after - in case you want to specify what the damage amount on the mob should be afterwards
 * * included_types - Bitflag of damage types to apply
 * * biotypes - the biotypes of damage to apply
 * * bodytypes - the bodytypes of damage to apply
 * * forced - whether or not this is forced damage
 */
/datum/unit_test/mob_damage/proc/test_apply_damage(mob/living/testing_mob, amount, expected = -amount, amount_after, included_types, biotypes, bodytypes, forced)
	if(isnull(amount_after))
		amount_after = testing_mob.get_stamina_loss() - expected // stamina loss applies to both carbon and basic mobs the same way, so that's why we're using it here
	if(!apply_damage(testing_mob, amount, expected, included_types, biotypes, bodytypes, forced))
		return FALSE
	if(!verify_damage(testing_mob, amount_after, included_types))
		return FALSE
	return TRUE

/**
 * Check that the mob has a specific amount of damage
 *
 * By default this checks that the mob has <amount> of every type of damage.
 * Arguments:
 * * testing_mob - the mob to check the damage of
 * * amount - the amount of damage to verify that the mob has
 * * included_types - Bitflag of damage types to check.
 */
/datum/unit_test/mob_damage/proc/verify_damage(mob/living/testing_mob, amount, included_types = ALL)
	if(included_types & TOXLOSS)
		TEST_ASSERT_EQUAL(testing_mob.get_tox_loss(), amount, \
			"[testing_mob] should have [amount] toxin damage, instead they have [testing_mob.get_tox_loss()]!")
	if(included_types & BRUTELOSS)
		TEST_ASSERT_EQUAL(round(testing_mob.get_brute_loss(), 1), amount, \
			"[testing_mob] should have [amount] brute damage, instead they have [testing_mob.get_brute_loss()]!")
	if(included_types & BURNLOSS)
		TEST_ASSERT_EQUAL(round(testing_mob.get_burn_loss(), 1), amount, \
			"[testing_mob] should have [amount] burn damage, instead they have [testing_mob.get_burn_loss()]!")
	if(included_types & OXYLOSS)
		TEST_ASSERT_EQUAL(testing_mob.get_oxy_loss(), amount, \
			"[testing_mob] should have [amount] oxy damage, instead they have [testing_mob.get_oxy_loss()]!")
	if(included_types & STAMINALOSS)
		TEST_ASSERT_EQUAL(testing_mob.get_stamina_loss(), amount, \
			"[testing_mob] should have [amount] stamina damage, instead they have [testing_mob.get_stamina_loss()]!")
	return TRUE

/**
 * Apply a specific amount of damage to the mob using adjust_brute_loss(), adjust_tox_loss(), etc.
 *
 * By default this applies <amount> damage of every type to the mob, and checks that the damage procs return the <expected> value
 * Arguments:
 * * testing_mob - the mob to apply the damage to
 * * amount - the amount of damage to apply to the mob
 * * expected - what the expected return value of the damage proc is
 * * included_types - Bitflag of damage types to apply
 * * biotypes - the biotypes of damage to apply
 * * bodytypes - the bodytypes of damage to apply
 * * forced - whether or not this is forced damage
 */
/datum/unit_test/mob_damage/proc/apply_damage(mob/living/testing_mob, amount, expected = -amount, included_types = ALL, biotypes = ALL, bodytypes = ALL, forced = FALSE)
	var/damage_returned
	if(included_types & TOXLOSS)
		damage_returned = testing_mob.adjust_tox_loss(amount, updating_health = FALSE, forced = forced, required_biotype = biotypes)
		TEST_ASSERT_EQUAL(damage_returned, expected, \
			"adjust_tox_loss() should have returned [expected], but returned [damage_returned] instead!")
	if(included_types & BRUTELOSS)
		damage_returned = round(testing_mob.adjust_brute_loss(amount, updating_health = FALSE, forced = forced, required_bodytype = bodytypes), 1)
		TEST_ASSERT_EQUAL(damage_returned, expected, \
			"adjust_brute_loss() should have returned [expected], but returned [damage_returned] instead!")
	if(included_types & BURNLOSS)
		damage_returned = round(testing_mob.adjust_burn_loss(amount, updating_health = FALSE, forced = forced, required_bodytype = bodytypes), 1)
		TEST_ASSERT_EQUAL(damage_returned, expected, \
			"adjust_burn_loss() should have returned [expected], but returned [damage_returned] instead!")
	if(included_types & OXYLOSS)
		damage_returned = testing_mob.adjust_oxy_loss(amount, updating_health = FALSE, forced = forced, required_biotype = biotypes)
		TEST_ASSERT_EQUAL(damage_returned, expected, \
			"adjust_oxy_loss() should have returned [expected], but returned [damage_returned] instead!")
	if(included_types & STAMINALOSS)
		damage_returned = testing_mob.adjust_stamina_loss(amount, updating_stamina = FALSE, forced = forced, required_biotype = biotypes)
		TEST_ASSERT_EQUAL(damage_returned, expected, \
			"adjust_stamina_loss() should have returned [expected], but returned [damage_returned] instead!")
	return TRUE

///	Sanity tests damage and healing using adjust_tox_loss, adjust_brute_loss, etc
/datum/unit_test/mob_damage/proc/test_sanity_simple(mob/living/carbon/human/consistent/dummy)
	// Apply 5 damage and then heal it
	if(!test_apply_damage(dummy, amount = 5))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! damage was not applied correctly")

	if(!test_apply_damage(dummy, amount = -5))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! healing was not applied correctly")

	// Apply 15 damage and heal 3
	if(!test_apply_damage(dummy, amount = 15))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! damage was not applied correctly")

	if(!test_apply_damage(dummy, amount = -3))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! underhealing was not applied correctly")

	// Now overheal by 666. It should heal for 12.

	if(!test_apply_damage(dummy, amount = -666, expected = 12))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! overhealing was not applied correctly")

///	Sanity tests damage and healing using the more complex procs like take_overall_damage(), heal_overall_damage(), etc
/datum/unit_test/mob_damage/proc/test_sanity_complex(mob/living/carbon/human/consistent/dummy)
	// Heal up, so that errors from the previous tests we won't cause this one to fail
	dummy.fully_heal(HEAL_DAMAGE)

	var/damage_returned
	// take 5 brute, 2 burn
	damage_returned = round(dummy.take_bodypart_damage(5, 2, updating_health = FALSE), 1)
	TEST_ASSERT_EQUAL(damage_returned, -7, \
		"take_bodypart_damage() should have returned -7, but returned [damage_returned] instead!")

	TEST_ASSERT_EQUAL(round(dummy.get_brute_loss(), 1), 5, \
		"Dummy should have 5 brute damage, instead they have [dummy.get_brute_loss()]!")
	TEST_ASSERT_EQUAL(round(dummy.get_burn_loss(), 1), 2, \
		"Dummy should have 2 burn damage, instead they have [dummy.get_burn_loss()]!")

	// heal 4 brute, 1 burn
	damage_returned = round(dummy.heal_bodypart_damage(4, 1, updating_health = FALSE), 1)
	TEST_ASSERT_EQUAL(damage_returned, 5, \
		"heal_bodypart_damage() should have returned 5, but returned [damage_returned] instead!")

	if(!verify_damage(dummy, 1, included_types = BRUTELOSS|BURNLOSS))
		TEST_FAIL("heal_bodypart_damage did not apply its healing correctly on the mob!")

	// heal 1 brute, 1 burn
	damage_returned = round(dummy.heal_overall_damage(1, 1, updating_health = FALSE), 1)
	TEST_ASSERT_EQUAL(damage_returned, 2, \
		"heal_overall_damage() should have returned 2, but returned [damage_returned] instead!")

	if(!verify_damage(dummy, 0, included_types = BRUTELOSS|BURNLOSS))
		TEST_FAIL("heal_overall_damage did not apply its healing correctly on the mob!")

	// take 50 brute, 50 burn
	damage_returned = round(dummy.take_overall_damage(50, 50, updating_health = FALSE), 1)
	TEST_ASSERT_EQUAL(damage_returned, -100, \
		"take_overall_damage() should have returned -100, but returned [damage_returned] instead!")

	if(!verify_damage(dummy, 50, included_types = BRUTELOSS|BURNLOSS))
		TEST_FAIL("take_overall_damage did not apply its damage correctly on the mob!")

	// testing negative damage amount args with the overall damage procs - the sign should be ignored for these procs

	damage_returned = round(dummy.take_bodypart_damage(-5, -5, updating_health = FALSE), 1)
	TEST_ASSERT_EQUAL(damage_returned, -10, \
		"take_bodypart_damage() should have returned -10, but returned [damage_returned] instead!")

	damage_returned = round(dummy.heal_bodypart_damage(-5, -5, updating_health = FALSE), 1)
	TEST_ASSERT_EQUAL(damage_returned, 10, \
		"heal_bodypart_damage() should have returned 10, but returned [damage_returned] instead!")

	damage_returned = round(dummy.take_overall_damage(-5, -5, updating_health = FALSE), 1)
	TEST_ASSERT_EQUAL(damage_returned, -10, \
		"take_overall_damage() should have returned -10, but returned [damage_returned] instead!")

	damage_returned = round(dummy.heal_overall_damage(-5, -5, updating_health = FALSE), 1)
	TEST_ASSERT_EQUAL(damage_returned, 10, \
		"heal_overall_damage() should have returned 10, but returned [damage_returned] instead!")

	if(!verify_damage(dummy, 50, included_types = BRUTELOSS|BURNLOSS))
		TEST_FAIL("heal_overall_damage did not apply its healingcorrectly on the mob!")

	// testing overhealing

	damage_returned = round(dummy.heal_overall_damage(75, 99, updating_health = FALSE), 1)
	TEST_ASSERT_EQUAL(damage_returned, 100, \
		"heal_overall_damage() should have returned 100, but returned [damage_returned] instead!")

	if(!verify_damage(dummy, 0, included_types = BRUTELOSS|BURNLOSS))
		TEST_FAIL("heal_overall_damage did not apply its healing correctly on the mob!")

///	Tests damage procs with godmode on
/datum/unit_test/mob_damage/proc/test_godmode(mob/living/carbon/human/consistent/dummy)
	// Heal up, so that errors from the previous tests we won't cause this one to fail
	dummy.fully_heal(HEAL_DAMAGE)
	// add godmode
	ADD_TRAIT(dummy, TRAIT_GODMODE, TRAIT_GENERIC)

	// Apply 9 damage and then heal it
	if(!test_apply_damage(dummy, amount = 9, expected = 0))
		TEST_FAIL("ABOVE FAILURE: failed test_godmode! mob took damage despite having godmode enabled.")

	if(!test_apply_damage(dummy, amount = -9, expected = 0))
		TEST_FAIL("ABOVE FAILURE: failed test_godmode! mob healed when they should've been at full health.")

	// Apply 11 damage and then heal it, this time with forced enabled. The damage should go through regardless of godmode.
	if(!test_apply_damage(dummy, amount = 11, forced = TRUE))
		TEST_FAIL("ABOVE FAILURE: failed test_godmode! godmode did not respect forced = TRUE")

	if(!test_apply_damage(dummy, amount = -11, forced = TRUE))
		TEST_FAIL("ABOVE FAILURE: failed test_godmode! godmode did not respect forced = TRUE")

	// remove godmode
	REMOVE_TRAIT(dummy, TRAIT_GODMODE, TRAIT_GENERIC)

/// Testing biotypes
/datum/unit_test/mob_damage/proc/test_biotypes(mob/living/carbon/human/consistent/dummy)
	// Heal up, so that errors from the previous tests we won't cause this one to fail
	dummy.fully_heal(HEAL_DAMAGE)
	// Testing biotypes using a plasmaman, who is MOB_MINERAL and MOB_HUMANOID
	dummy.set_species(/datum/species/plasmaman)

	// argumentless default: should default to required_biotype = ALL. The damage should be applied in that case.
	if(!test_apply_damage(dummy, 1, included_types = TOXLOSS|STAMINALOSS))
		TEST_FAIL("ABOVE FAILURE: plasmaman did not take damage with biotypes = ALL")

	// If we specify MOB_ORGANIC, the damage should not get applied because plasmamen lack that biotype.
	if(!test_apply_damage(dummy, 1, expected = 0, included_types = TOXLOSS|STAMINALOSS, biotypes = MOB_ORGANIC))
		TEST_FAIL("ABOVE FAILURE: plasmaman took damage with biotypes = MOB_ORGANIC")

	// Now if we specify MOB_MINERAL the damage should get applied.
	if(!test_apply_damage(dummy, 1, included_types = TOXLOSS|STAMINALOSS, biotypes = MOB_MINERAL))
		TEST_FAIL("ABOVE FAILURE: plasmaman did not take damage with biotypes = MOB_MINERAL")

	// Transform back to human
	dummy.set_species(/datum/species/human)

	// We have 2 damage presently.
	// Try to heal it; let's specify MOB_MINERAL, which should no longer work because we have changed back to a human.
	if(!test_apply_damage(dummy, -2, expected = 0, included_types = TOXLOSS|STAMINALOSS, biotypes = MOB_MINERAL))
		TEST_FAIL("ABOVE FAILURE: human took damage with biotypes = MOB_MINERAL")

	// Force heal some of the damage. When forced = TRUE the damage/healing gets applied no matter what.
	if(!test_apply_damage(dummy, -1, included_types = TOXLOSS|STAMINALOSS, biotypes = MOB_MINERAL, forced = TRUE))
		TEST_FAIL("ABOVE FAILURE: human did not get healed when biotypes = MOB_MINERAL and forced = TRUE")

	// Now heal the rest of it with the correct biotype. Make sure that this works. We should have 0 damage afterwards.
	if(!test_apply_damage(dummy, -1, included_types = TOXLOSS|STAMINALOSS, biotypes = MOB_ORGANIC))
		TEST_FAIL("ABOVE FAILURE: human did not get healed with biotypes = MOB_ORGANIC")

/// Testing oxyloss with the TRAIT_NOBREATH
/datum/unit_test/mob_damage/proc/test_nobreath(mob/living/carbon/human/consistent/dummy)
	// Heal up, so that errors from the previous tests we won't cause this one to fail
	dummy.fully_heal(HEAL_DAMAGE)

	// TRAIT_NOBREATH is supposed to prevent oxyloss damage (but not healing). Let's make sure that's the case.
	ADD_TRAIT(dummy, TRAIT_NOBREATH, TRAIT_SOURCE_UNIT_TESTS)
	// force some oxyloss here
	dummy.set_oxy_loss(2, updating_health = FALSE, forced = TRUE)

	// Try to take more oxyloss damage with TRAIT_NOBREATH. It should not work.
	if(!test_apply_damage(dummy, 2, expected = 0, amount_after = dummy.get_oxy_loss(), included_types = OXYLOSS))
		TEST_FAIL("ABOVE FAILURE: failed test_nobreath! mob took oxyloss damage while having TRAIT_NOBREATH")

	// Make sure we are still be able to heal the oxyloss. This should work.
	if(!test_apply_damage(dummy, -2, amount_after = dummy.get_oxy_loss()-2, included_types = OXYLOSS))
		TEST_FAIL("ABOVE FAILURE: failed test_nobreath! mob could not heal oxyloss damage while having TRAIT_NOBREATH")

	REMOVE_TRAIT(dummy, TRAIT_NOBREATH, TRAIT_SOURCE_UNIT_TESTS)

/// Testing toxloss with TRAIT_TOXINLOVER and TRAIT_TOXIMMUNE
/datum/unit_test/mob_damage/proc/test_toxintraits(mob/living/carbon/human/consistent/dummy)
	// Heal up, so that errors from the previous tests we won't cause this one to fail
	dummy.fully_heal(HEAL_DAMAGE)

	// TRAIT_TOXINLOVER is supposed to invert toxin damage and healing. Things that would normally cause toxloss now heal it, and vice versa.
	ADD_TRAIT(dummy, TRAIT_TOXINLOVER, TRAIT_SOURCE_UNIT_TESTS)
	// force some toxloss here
	dummy.set_tox_loss(2, updating_health = FALSE, forced = TRUE)

	// Try to take more toxloss damage with TRAIT_TOXINLOVER. It should heal instead.
	if(!test_apply_damage(dummy, 2, expected = 2, amount_after = dummy.get_tox_loss()-2, included_types = TOXLOSS))
		TEST_FAIL("ABOVE FAILURE: failed test_toxintraits! mob did not heal from toxin damage with TRAIT_TOXINLOVER")

	// If we try to heal the toxloss we should take damage instead
	if(!test_apply_damage(dummy, -2, expected = -2, amount_after = dummy.get_tox_loss()+2, included_types = TOXLOSS))
		TEST_FAIL("ABOVE FAILURE: failed test_toxintraits! mob did not take damage from toxin healing with TRAIT_TOXINLOVER")

	// TOXIMMUNE trait should prevent the damage you get from being healed by toxins medicines while having TRAIT_TOXINLOVER
	ADD_TRAIT(dummy, TRAIT_TOXIMMUNE, TRAIT_SOURCE_UNIT_TESTS)

	// need to force apply some toxin damage since the TOXIMUNNE trait sets toxloss to 0 upon being added
	dummy.set_tox_loss(2, updating_health = FALSE, forced = TRUE)

	// try to 'heal' again - this time it should just do nothing because we should be immune to any sort of toxin damage - including from inverted healing
	if(!test_apply_damage(dummy, -2, expected = 0, amount_after = dummy.get_tox_loss(), included_types = TOXLOSS))
		TEST_FAIL("ABOVE FAILURE: failed test_toxintraits! mob should not have taken any damage or healing with TRAIT_TOXINLOVER + TRAIT_TOXIMMUNE")

	// ok, let's try taking 'damage'. The inverted damage should still heal mobs with the TOXIMMUNE trait.
	if(!test_apply_damage(dummy, 2, expected = 2, amount_after = dummy.get_tox_loss()-2, included_types = TOXLOSS))
		TEST_FAIL("ABOVE FAILURE: failed test_toxintraits! mob did not heal from taking toxin damage with TRAIT_TOXINLOVER + TRAIT_TOXIMMUNE")

	REMOVE_TRAIT(dummy, TRAIT_TOXINLOVER, TRAIT_SOURCE_UNIT_TESTS)
	REMOVE_TRAIT(dummy, TRAIT_TOXIMMUNE, TRAIT_SOURCE_UNIT_TESTS)

/// Testing heal_ordered_damage()
/datum/unit_test/mob_damage/proc/test_ordered_healing(mob/living/carbon/human/consistent/dummy)
	// Heal up, so that errors from the previous tests we won't cause this one to fail
	dummy.fully_heal(HEAL_DAMAGE)
	var/damage_returned

	// We apply 20 brute, 20 burn, and 20 toxin damage. 60 damage total
	apply_damage(dummy, 20, included_types = TOXLOSS|BRUTELOSS|BURNLOSS)

	// Heal 30 damage of that, starting from brute
	damage_returned = round(dummy.heal_ordered_damage(30, list(BRUTE, BURN, TOX)), 1)
	TEST_ASSERT_EQUAL(damage_returned, 30, \
		"heal_ordered_damage() should have returned 30, but returned [damage_returned] instead!")

	// Should have 10 burn damage and 20 toxins damage remaining, let's check
	TEST_ASSERT_EQUAL(dummy.get_brute_loss(), 0, \
		"[src] should have 0 brute damage, but has [dummy.get_brute_loss()] instead!")
	TEST_ASSERT_EQUAL(dummy.get_burn_loss(), 10, \
		"[src] should have 10 burn damage, but has [dummy.get_burn_loss()] instead!")
	TEST_ASSERT_EQUAL(dummy.get_tox_loss(), 20, \
		"[src] should have 20 toxin damage, but has [dummy.get_tox_loss()] instead!")

	// Now heal the remaining 30, overhealing by 5.
	damage_returned = round(dummy.heal_ordered_damage(35, list(BRUTE, BURN, TOX)), 1)
	TEST_ASSERT_EQUAL(damage_returned, 30, \
		"heal_ordered_damage() should have returned 30, but returned [damage_returned] instead!")

	// Should have no damage remaining
	TEST_ASSERT_EQUAL(dummy.get_brute_loss(), 0, \
		"[src] should have 0 brute damage, but has [dummy.get_brute_loss()] instead!")
	TEST_ASSERT_EQUAL(dummy.get_burn_loss(), 0, \
		"[src] should have 0 burn damage, but has [dummy.get_burn_loss()] instead!")
	TEST_ASSERT_EQUAL(dummy.get_tox_loss(), 0, \
		"[src] should have 0 toxin damage, but has [dummy.get_tox_loss()] instead!")

/// Tests that mob damage procs are working as intended for basic mobs
/datum/unit_test/mob_damage/basic

/datum/unit_test/mob_damage/basic/Run()
	SSmobs.pause()
	var/mob/living/basic/mouse/gray/gusgus = allocate(/mob/living/basic/mouse/gray)
	// give gusgus a damage_coeff of 1 for this test
	gusgus.damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, STAMINA = 1, OXY = 1)
	// tank mouse
	gusgus.maxHealth = 200

	test_sanity_simple(gusgus)
	test_sanity_complex(gusgus)

/**
 * Check that the mob has a specific amount of damage. Note: basic mobs have all incoming damage types besides stam converted into brute damage.
 *
 * By default this checks that the mob has <amount> of every type of damage.
 * Arguments:
 * * testing_mob - the mob to check the damage of
 * * amount - the amount of damage to verify that the mob has
 * * expected - the expected return value of the damage procs, if it differs from the default of (amount * 4)
 * * included_types - Bitflag of damage types to check.
 */
/datum/unit_test/mob_damage/basic/verify_damage(mob/living/testing_mob, amount, expected, included_types = ALL)
	if(included_types & TOXLOSS)
		TEST_ASSERT_EQUAL(testing_mob.get_tox_loss(), 0, \
			"[testing_mob] should have [0] toxin damage, instead they have [testing_mob.get_tox_loss()]!")
	if(included_types & BRUTELOSS)
		TEST_ASSERT_EQUAL(round(testing_mob.get_brute_loss(), 1), expected || amount * 4, \
			"[testing_mob] should have [expected || amount * 4] brute damage, instead they have [testing_mob.get_brute_loss()]!")
	if(included_types & BURNLOSS)
		TEST_ASSERT_EQUAL(round(testing_mob.get_burn_loss(), 1), 0, \
			"[testing_mob] should have [0] burn damage, instead they have [testing_mob.get_burn_loss()]!")
	if(included_types & OXYLOSS)
		TEST_ASSERT_EQUAL(testing_mob.get_oxy_loss(), 0, \
			"[testing_mob] should have [0] oxy damage, instead they have [testing_mob.get_oxy_loss()]!")
	if(included_types & STAMINALOSS)
		TEST_ASSERT_EQUAL(testing_mob.get_stamina_loss(), amount, \
			"[testing_mob] should have [amount] stamina damage, instead they have [testing_mob.get_stamina_loss()]!")
	return TRUE

/datum/unit_test/mob_damage/basic/test_sanity_simple(mob/living/basic/mouse/gray/gusgus)
	// check to see if basic mob damage works

	// Simple damage and healing
	// Take 1 damage, heal for 1
	if(!test_apply_damage(gusgus, amount = 1))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! damage was not applied correctly")

	if(!test_apply_damage(gusgus, amount = -1))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! healing was not applied correctly")

	// Give 2 damage of every time (translates to 8 brute, 2 staminaloss)
	if(!test_apply_damage(gusgus, amount = 2))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! damage was not applied correctly")

	// underhealing: heal 1 damage of every type (translates to 4 brute, 1 staminaloss)
	if(!test_apply_damage(gusgus, amount = -1))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! healing was not applied correctly")

	// overhealing

	// heal 11 points of toxloss (should take care of all 4 brute damage remaining)
	if(!apply_damage(gusgus, -11, expected = 4, included_types = TOXLOSS))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! toxloss was not applied correctly")
	// heal the remaining point of staminaloss
	if(!apply_damage(gusgus, -11, expected = 1, included_types = STAMINALOSS))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! failed to heal staminaloss correctly")
	// heal 35 points of each type, we should already be at full health so nothing should happen
	if(!test_apply_damage(gusgus, amount = -35, expected = 0))
		TEST_FAIL("ABOVE FAILURE: failed test_sanity_simple! overhealing was not applied correctly")

/datum/unit_test/mob_damage/basic/test_sanity_complex(mob/living/basic/mouse/gray/gusgus)
	// Heal up, so that errors from the previous tests we won't cause this one to fail
	gusgus.fully_heal(HEAL_DAMAGE)
	var/damage_returned
	// overall damage procs

	// take 5 brute, 2 burn
	damage_returned = gusgus.take_bodypart_damage(5, 2, updating_health = FALSE)
	TEST_ASSERT_EQUAL(damage_returned, -7, \
		"take_bodypart_damage() should have returned -7, but returned [damage_returned] instead!")

	TEST_ASSERT_EQUAL(gusgus.bruteloss, 7, \
		"Mouse should have 7 brute damage, instead they have [gusgus.bruteloss]!")
	TEST_ASSERT_EQUAL(gusgus.burnloss, 0, \
		"Mouse should have 0 burn damage, instead they have [gusgus.burnloss]!")

	// heal 4 brute, 1 burn
	damage_returned = gusgus.heal_bodypart_damage(4, 1, updating_health = FALSE)
	TEST_ASSERT_EQUAL(damage_returned, 5, \
		"heal_bodypart_damage() should have returned 5, but returned [damage_returned] instead!")

	TEST_ASSERT_EQUAL(gusgus.bruteloss, 2, \
		"Mouse should have 2 brute damage, instead they have [gusgus.bruteloss]!")
	TEST_ASSERT_EQUAL(gusgus.burnloss, 0, \
		"Mouse should have 0 burn damage, instead they have [gusgus.burnloss]!")

	// heal 1 brute, 1 burn
	damage_returned = gusgus.heal_overall_damage(1, 1, updating_health = FALSE)
	TEST_ASSERT_EQUAL(damage_returned, 2, \
		"heal_overall_damage() should have returned 2, but returned [damage_returned] instead!")

	TEST_ASSERT_EQUAL(gusgus.bruteloss, 0, \
		"Mouse should have 0 brute damage, instead they have [gusgus.bruteloss]!")
	TEST_ASSERT_EQUAL(gusgus.burnloss, 0, \
		"Mouse should have 0 burn damage, instead they have [gusgus.burnloss]!")

	// take 50 brute, 50 burn
	damage_returned = gusgus.take_overall_damage(3, 3, updating_health = FALSE)
	TEST_ASSERT_EQUAL(damage_returned, -6, \
		"take_overall_damage() should have returned -6, but returned [damage_returned] instead!")

	if(!verify_damage(gusgus, 1, expected = 6, included_types = BRUTELOSS))
		TEST_FAIL("take_overall_damage did not apply its damage correctly on the mouse!")

	// testing negative args with the overall damage procs

	damage_returned = gusgus.take_bodypart_damage(-1, -1, updating_health = FALSE)
	TEST_ASSERT_EQUAL(damage_returned, -2, \
		"take_bodypart_damage() should have returned -2, but returned [damage_returned] instead!")

	damage_returned = gusgus.heal_bodypart_damage(-1, -1, updating_health = FALSE)
	TEST_ASSERT_EQUAL(damage_returned, 2, \
		"heal_bodypart_damage() should have returned 2, but returned [damage_returned] instead!")

	damage_returned = gusgus.take_overall_damage(-1, -1, updating_health = FALSE)
	TEST_ASSERT_EQUAL(damage_returned, -2, \
		"take_overall_damage() should have returned -2, but returned [damage_returned] instead!")

	damage_returned = gusgus.heal_overall_damage(-1, -1, updating_health = FALSE)
	TEST_ASSERT_EQUAL(damage_returned, 2, \
		"heal_overall_damage() should have returned 2, but returned [damage_returned] instead!")

	if(!verify_damage(gusgus, 1, expected = 6, included_types = BRUTELOSS))
		TEST_FAIL("heal_overall_damage did not apply its healing correctly on the mouse!")

	// testing overhealing

	damage_returned = gusgus.heal_overall_damage(75, 99, updating_health = FALSE)
	TEST_ASSERT_EQUAL(damage_returned, 6, \
		"heal_overall_damage() should have returned 6, but returned [damage_returned] instead!")

	if(!verify_damage(gusgus, 0, included_types = BRUTELOSS))
		TEST_FAIL("heal_overall_damage did not apply its healing correctly on the mouse!")

/// Tests that humans get the tox_vomit status effect when heavily poisoned
/datum/unit_test/human_tox_damage

/datum/unit_test/human_tox_damage/Run()
	// Spawn a dummy, give it a bunch of tox damage. It should get the status effect.
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human/consistent)
	dummy.set_tox_loss(75)
	var/datum/status_effect/tox_effect = dummy.has_status_effect(/datum/status_effect/tox_vomit)
	TEST_ASSERT_NOTNULL(tox_effect, "Dummy didn't get tox_vomit status effect despite at [dummy.get_tox_loss()] toxin damage (Method: SET)!")
	// Clear the toxin damage away, and force a status effect tick: It should delete itself
	dummy.set_tox_loss(0)
	tox_effect.tick(initial(tox_effect.tick_interval))
	TEST_ASSERT(QDELETED(tox_effect), "Dummy still has tox_vomit status effect despite at [dummy.get_tox_loss()] toxin damage (Method: SET)!")
	// Test another method of gaining tox damage, use an entirely clean slate just to be sure
	var/mob/living/carbon/human/dummy_two = allocate(/mob/living/carbon/human/consistent)
	dummy_two.adjust_tox_loss(75)
	var/datum/status_effect/tox_effect_two = dummy_two.has_status_effect(/datum/status_effect/tox_vomit)
	TEST_ASSERT_NOTNULL(tox_effect_two, "Dummy didn't get tox_vomit status effect at [dummy_two.get_tox_loss()] toxin damage (METHOD: ADJUST)!")
