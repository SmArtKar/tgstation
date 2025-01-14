//Stores several modifiers in a way that isn't cleared by changing species
/datum/physiology
	/// Multipliers to damage received by type.
	/// IE: A brute mod of 0.9 = 10% less brute damage.
	var/list/damage_mods = list(
		BRUTE = 1,
		BURN = 1,
		TOX = 1,
		OXY = 1,
		STAMINA = 1,
		)

	// Multiplier for all damage
	var/damage_multiplier = 1

	/// Multiplier to damage taken from high / low pressure exposure, stacking with the brute modifier
	var/pressure_mod = 1
	/// Multiplier to damage taken from high temperature exposure, stacking with the burn modifier
	var/heat_mod = 1
	/// Multiplier to damage taken from low temperature exposure, stacking with the toxin modifier
	var/cold_mod = 1

	/// Flat damage reduction from taking damage
	/// Unlike the other modifiers, this is not a multiplier.
	/// IE: DR of 10 = 10% less damage.
	var/damage_resistance = 0

	var/siemens_coeff = 1 // resistance to shocks

	/// Multiplier applied to all incapacitating stuns (knockdown, stun, paralyze, immobilize)
	var/stun_mod = 1
	/// Multiplied aplpied to just knockdowns, stacks with above multiplicatively
	var/knockdown_mod = 1

	var/bleed_mod = 1 // % bleeding modifier
	var/datum/armor/armor // internal armor datum

	var/hunger_mod = 1 //% of hunger rate taken per tick.

/datum/physiology/New()
	armor = new
