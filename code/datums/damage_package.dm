/// An abstract damage datum, because BYOND lacks basic features (structures),
/// and using lists only provides a marginal benefit in performance and memory (if any, depending on usecase)
/datum/damage_package
	/// Amount of damage dealt
	var/amount = 0
	/// Type of damage dealt, can be BRUTE, BURN, TOX, OXY and STAMINA. Use BRAIN and I will obliterate you
	/// TODO: Axe BRAIN damage
	var/damage_type = BRUTE
	/// Defines what sort of armor protects from this damage
	var/armor_type = null
	/// Flags defining what sort of an attack this is: Melee, unarmed, projectile, magical, etc.
	var/damage_flags = NONE
	/// Direction from which this attack came
	var/attack_dir = NONE
	/// Deductive armor penetration efficiency of this attack. Anything above 100 will ignore armor completely
	var/armor_penetration = 0
	/// Multiplicative armor penetration, mostly used for attacks weak against armor
	var/armor_multiplier = 1
	/// Source of the attack - weapon, projectile, thrown item, or a maint-fu practicioner
	var/atom/hit_by = null
	/// Atom or mob that shot the projectile, or hit you with a weapon. Can be the same as source, can differ
	var/atom/source = null
	/// Short descriptor of the attack, like "John Doe's punch"
	var/attack_text = null
