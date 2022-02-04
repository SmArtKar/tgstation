/datum/design/experi_scanner
	name = "Experimental Scanner"
	desc = "Experimental scanning unit used for performing scanning experiments."
	id = "experi_scanner"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/glass = 500, /datum/material/iron = 500)
	build_path = /obj/item/experi_scanner
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/slime_scanner
	name = "Slime Scanner"
	desc = "A small handheld device used for analyzing slimes."
	id = "slime_scanner"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/glass = 500, /datum/material/iron = 500)
	build_path = /obj/item/slime_scanner
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/adv_slime_scanner
	name = "Advanced Slime Scanner"
	desc = "An advanced version of a slime scanner, capable of precise measurements and ranged scans."
	id = "slime_scanner_adv"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = 2000, /datum/material/glass = 1000, /datum/material/silver = 500, /datum/material/gold = 500)
	build_path = /obj/item/slime_scanner/advanced
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE
