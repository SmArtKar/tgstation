#define PANEL_OPEN (1<<0)
#define ID_LOCK_ON (1<<1)
#define CAN_STRAFE (1<<2)
/// Can move in diagonals
#define CAN_MOVE_DIAGONALLY (1<<3)
/// Piloted by an AI or a COMP unit
#define SILICON_PILOT (1<<4)
/// Allows the cockpit to be sealed, and the pilot cannot be hit by projectiles or bombs
#define IS_ENCLOSED (1<<5)
#define HAS_LIGHTS (1<<6)
/// Completely disables all mouseclicks, such as melee or utilities.
#define MECH_ACTIONS_DISABLED (1<<7)
/// MMIs and posibrains can be inserted into this mech as a COMP unit
#define MMI_COMPATIBLE (1<<8)
/// Can click from any direction and perform stuff
#define OMNIDIRECTIONAL_ATTACKS (1<<9)
/// This mech turns and moves at the same time
#define RAPID_TURNING (1<<10)
/// We break though walls like Kool-Aid man when running into them
#define BUMP_SMASH (1<<11)

// Mech armor modifiers
/// Multiplier for damage taken from the front, or adjacent diagonals
#define MECHA_FRONT_ARMOUR "mecha_front"
#define MECHA_SIDE_ARMOUR "mecha_side"
#define MECHA_BACK_ARMOUR "mecha_back"

/// Slots in which this module can be installed
#define MECHA_ARMS_SLOT "arms_slot"
#define MECHA_ARM_LEFT_SLOT "arm_left_slot"
#define MECHA_ARM_RIGHT_SLOT "arm_right_slot"
#define MECHA_UTILITY_SLOT "utility_slot"

// Some mechs must (at least for now) use snowflake handling of their UI elements, these defines are for that
// when changing MUST update the same-named tsx file constants
#define MECHA_SNOWFLAKE_ID_SLEEPER "sleeper_snowflake"
#define MECHA_SNOWFLAKE_ID_SYRINGE "syringe_snowflake"
#define MECHA_SNOWFLAKE_ID_MODE "mode_snowflake"
#define MECHA_SNOWFLAKE_ID_EXTINGUISHER "extinguisher_snowflake"
#define MECHA_SNOWFLAKE_ID_EJECTOR "ejector_snowflake"
#define MECHA_SNOWFLAKE_ID_OREBOX_MANAGER "orebox_manager_snowflake"
#define MECHA_SNOWFLAKE_ID_RADIO "radio_snowflake"
#define MECHA_SNOWFLAKE_ID_AIR_TANK "air_tank_snowflake"
#define MECHA_SNOWFLAKE_ID_WEAPON_BALLISTIC "ballistic_weapon_snowflake"
#define MECHA_SNOWFLAKE_ID_GENERATOR "generator_snowflake"
#define MECHA_SNOWFLAKE_ID_ORE_SCANNER "orescanner_snowflake"
#define MECHA_SNOWFLAKE_ID_CLAW "lawclaw_snowflake"
#define MECHA_SNOWFLAKE_ID_RCD "rcd_snowflake"

#define MECHA_AMMO_INCENDIARY "Incendiary bullet"
#define MECHA_AMMO_BUCKSHOT "Buckshot shell"
#define MECHA_AMMO_LMG "LMG bullet"
#define MECHA_AMMO_MISSILE_SRM "SRM missile"
#define MECHA_AMMO_MISSILE_PEP "PEP missile"
#define MECHA_AMMO_FLASHBANG "Flashbang"
#define MECHA_AMMO_CLUSTERBANG "Clusterbang"
#define MECHA_AMMO_PUNCHING_GLOVE "Punching glove"
#define MECHA_AMMO_BANANA_PEEL "Banana peel"
#define MECHA_AMMO_MOUSETRAP "Mousetrap"

/// Chance of equipment getting destroyed with the mech
#define MECHA_EQUIPMENT_DESTRUCTION_PROB 70
/// Chance of open-cabin mechs redirecting projectiles at their driver
#define MECHA_OPEN_CABIN_DRIVER_HIT_CHANCE 75
/// Percentage of charge deducted when a mech is hit by an EMP
#define MECHA_EMP_CHARGE_DRAIN 0.15
/// How long does it take for a mech to gain back control of its' equipment after being EMPd?
#define MECHA_EMP_EQUIPMENT_REBOOT_TIME 3 SECONDS

/// Melee damage over which living mobs get thrown away from the mech
#define MECHA_MELEE_THROW_DAMAGE 15
