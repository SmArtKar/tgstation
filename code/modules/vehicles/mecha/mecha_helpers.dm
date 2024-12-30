/*
///////////////////////
///// Power stuff /////
///////////////////////

//////////////////////
///// Ammo stuff /////
//////////////////////

///Max the ammo stored in all ballistic weapons for this mech
/obj/vehicle/sealed/mecha/proc/max_ammo()
	for(var/obj/item/I as anything in flat_equipment)
		if(istype(I, /obj/item/mecha_equipment/weapon/ballistic))
			var/obj/item/mecha_equipment/weapon/ballistic/gun = I
			gun.projectiles_cache = gun.projectiles_cache_max
*/
