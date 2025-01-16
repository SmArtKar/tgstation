/// An abstract damage datum, because BYOND lacks basic features (structures),
/// and using lists only provides a marginal benefit in performance and memory (if any, depending on usecase)
/datum/damage_package
	/// Amount of damage dealt
	var/amount = 0
	/// Type of damage dealt, can be BRUTE, BURN, TOX, OXY and STAMINA.
	var/damage_type = BRUTE
	/// Defines what sort of armor protects from this damage
	var/damage_flag = null
	/// Flags defining what sort of an attack this is: Melee, unarmed, projectile, magical, etc.
	var/attack_flags = NONE
	/// Bodypart which this attack was targeting. Should be a body_zone define, or a list of body_zone defines - automatically converted to latter by damage procs.
	var/def_zone = null
	/// If the damage gets spread out evenly between all bodyparts on mobs when not passed a bodypart
	var/spread_damage = TRUE
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
	/// Atom or mob that shot the projectile, or hit you with a weapon. Can be the same as hit_by, can differ
	var/atom/source = null
	/// Short descriptor of the attack, like "John Doe's punch"
	var/attack_text = null
	/// Override for normal "X ineffectively stabs Y, without leaving a mark!" attack messages
	var/attack_message_spectator = null
	/// Override for attack messages that user sees. If null, defaults to attack_message_spectator if it is set
	var/attack_message_attacker = null
	/// Additional chance this attack has to wound living beings
	var/wound_bonus = 0
	/// Additional wound bonus against bodyparts not protected by clothing
	var/bare_wound_bonus = 0
	/// Sharpness of the tool this attack was made with
	var/sharpness = NONE
	/// Biotype of mob/bodypart that is required for it to be able to take this damage
	var/required_biotype = ALL
	/// Damage multiplier, applied last in order to avoid comsig order issues
	var/amount_multiplier = 1

	/// Assigned by armor procs to signify what percentage of this attack was blocked by armor
	var/armor_block = 0
	/// Initial amount of damage that the package dealt before any side mods
	VAR_FINAL/initial_amount = 0

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
	attack_message_spectator = null,
	attack_message_attacker = null,
	spread_damage = FALSE,
	wound_bonus = 0,
	bare_wound_bonus = 0,
	sharpness = NONE,
	required_biotype = ALL,
	amount_multiplier = 1,
	initial_amount = null
)
	. = ..()
	src.amount = amount
	src.damage_type = damage_type
	src.damage_flag = damage_flag
	src.attack_flags = attack_flags
	src.def_zone = def_zone
	src.spread_damage = spread_damage
	src.attack_dir = attack_dir
	src.armor_penetration = armor_penetration
	src.armor_multiplier = armor_multiplier
	src.forced = forced
	src.hit_by = hit_by
	src.source = source
	src.attack_text = attack_text
	src.attack_message_spectator = attack_message_spectator
	src.attack_message_attacker = attack_message_attacker
	src.wound_bonus = wound_bonus
	src.bare_wound_bonus = bare_wound_bonus
	src.sharpness = sharpness
	src.required_biotype = required_biotype
	src.amount_multiplier = amount_multiplier

	if (!isnull(initial_amount))
		src.initial_amount = initial_amount
	else
		src.initial_amount = amount

/datum/damage_package/Destroy(force)
	hit_by = null
	source = null
	return ..()

/// Creates a copy of this package, optionally with reduced/increased damage
/datum/damage_package/proc/Copy(total_mult = 1)
	return new /datum/damage_package(
		amount = amount * total_mult,
		damage_type = damage_type,
		damage_flag = damage_flag,
		attack_flags = attack_flags,
		def_zone = def_zone,
		spread_damage = spread_damage,
		attack_dir = attack_dir,
		armor_penetration = armor_penetration,
		armor_multiplier = armor_multiplier,
		forced = forced,
		hit_by = hit_by,
		source = source,
		attack_text = attack_text,
		attack_message_spectator = attack_message_spectator,
		attack_message_attacker = attack_message_attacker,
		wound_bonus = wound_bonus,
		bare_wound_bonus = bare_wound_bonus,
		sharpness = sharpness,
		required_biotype = required_biotype,
		amount_multiplier = amount_multiplier,
		initial_amount = initial_amount * total_mult,
	)
