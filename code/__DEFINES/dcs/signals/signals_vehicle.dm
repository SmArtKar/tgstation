/// Called on a mob when they start riding a vehicle (obj/vehicle)
#define COMSIG_VEHICLE_RIDDEN "vehicle-ridden"
	/// Return this to signal that the mob should be removed from the vehicle
	#define EJECT_FROM_VEHICLE (1<<0)

// /obj/vehicle/sealed/mecha signals

/// sent if you attach equipment to mecha
#define COMSIG_MECHA_EQUIPMENT_ATTACHED "mecha_equipment_attached"
/// sent if you detach equipment to mecha
#define COMSIG_MECHA_EQUIPMENT_DETACHED "mecha_equipment_detached"
/// sent when you are able to drill through a mob
#define COMSIG_MECHA_DRILL_MOB "mecha_drill_mob"

///sent from mecha action buttons to the mecha they're linked to
#define COMSIG_MECHA_ACTION_TRIGGER "mecha_action_activate"

///sent from clicking while you have no equipment selected. Sent before cooldown and adjacency checks, so you can use this for infinite range things if you want.
#define COMSIG_MECHA_MELEE_CLICK "mecha_action_melee_click"
	/// Prevents click from happening.
	#define COMPONENT_CANCEL_MELEE_CLICK (1<<0)
	/// Picks a random target in 3 tile range of intended one
	#define COMPONENT_RANDOMIZE_MELEE_CLICK (1<<1)

///sent from clicking while you have equipment selected.
#define COMSIG_MECHA_EQUIPMENT_CLICK "mecha_action_equipment_click"
	/// Prevents click from happening.
	#define COMPONENT_CANCEL_EQUIPMENT_CLICK (1<<0)
	/// Picks a random target in 3 tile range of intended one
	#define COMPONENT_RANDOMIZE_EQUIPMENT_CLICK (1<<1)

/// From /obj/vehicle/sealed/mecha/vehicle_move(direction): (direction)
#define COMSIG_MECHA_TRY_MOVE "mecha_action_try_move"
	#define COMPONENT_CANCEL_MECHA_MOVE (1<<0)
	#define COMPONENT_RANDOMIZE_MECHA_MOVE (1<<1)

/// From /obj/vehicle/sealed/mecha/proc/set_safety(mob/user): (mob/user)
#define COMSIG_MECHA_SAFETIES_TOGGLE "mecha_safeties_toggle"
