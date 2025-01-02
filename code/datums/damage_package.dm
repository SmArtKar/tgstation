/// An abstract damage datum, because BYOND lacks basic features (structures),
/// and using lists only provides a marginal benefit in performance and memory (if any, depending on usecase)
/datum/damage_package
	/// Amount of damage dealt
	var/amount = 0
	/// Type of damage dealt, can be BRUTE, BURN, TOX, OXY and STAMINA. Use BRAIN and I will obliterate you
	/// SMARTKAR TODO: Axe BRAIN damage
	var/damage_type = BRUTE
	/// Defines what sort of armor protects from this damage
	var/damage_flag = null
	/// Flags defining what sort of an attack this is: Melee, unarmed, projectile, magical, etc.
	var/attack_flags = NONE
	/// Bodypart which this attack was targeting, can be both a bodypart object or just a zone define
	var/def_zone = null
	/// Direction from which this attack came
	var/attack_dir = NONE
	/// Additive armor penetration of this attack. Anything above 100 will ignore armor completely
	var/armor_penetration = 0
	/// Multiplicative armor penetration, mostly used for attacks weak against armor. Applied before armor_penetration
	var/armor_multiplier = 1
	/// Ignores damage multipliers (not armor)
	var/forced = FALSE
	/// Source of the attack - weapon, projectile, thrown item, or a maint-fu practicioner
	var/atom/hit_by = null
	/// Atom or mob that shot the projectile, or hit you with a weapon. Can be the same as source, can differ
	var/atom/source = null
	/// Short descriptor of the attack, like "John Doe's punch"
	var/attack_text = null
	/// Additional chance this attack has to wound living beings
	var/wound_bonus = 0
	/// Additional wound bonus against bodyparts not protected by clothing
	var/bare_wound_bonus = 0
	/// Sharpness of the tool this attack was made with
	var/sharpness = NONE

/datum/damage_package/New(
	amount = 0,
	damage_type = BRUTE,
	damage_flag = null,
	attack_flags = NONE,
	def_zone = null,
	attack_dir = NONE,
	armor_penetration = 0,
	armor_multiplier = 1,
	forced = FALSE,
	atom/hit_by = null,
	atom/source = null,
	attack_text = null,
	wound_bonus = 0,
	bare_wound_bonus = 0,
	sharpness = NONE,
	)
	. = ..()
	// This is rather ugly, but nullchecks allow for easy macro passing
	if (!isnull(amount))
		src.amount = amount
	if (!isnull(damage_type))
		src.damage_type = damage_type
	if (!isnull(damage_flag))
		src.damage_flag = damage_flag
	if (!isnull(attack_flags))
		src.attack_flags = attack_flags
	if (!isnull(def_zone))
		src.def_zone = def_zone
	if (!isnull(attack_dir))
		src.attack_dir = attack_dir
	if (!isnull(armor_penetration))
		src.armor_penetration = armor_penetration
	if (!isnull(armor_multiplier))
		src.armor_multiplier = armor_multiplier
	if (!isnull(forced))
		src.forced = forced
	if (!isnull(hit_by))
		src.hit_by = hit_by
	if (!isnull(source))
		src.source = source
	if (!isnull(attack_text))
		src.attack_text = attack_text
	if (!isnull(wound_bonus))
		src.wound_bonus = wound_bonus
	if (!isnull(bare_wound_bonus))
		src.bare_wound_bonus = bare_wound_bonus
	if (!isnull(sharpness))
		src.sharpness = sharpness

/datum/damage_package/Destroy(force)
	hit_by = null
	source = null
	return ..()
