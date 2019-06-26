#include <amxmodx>

#include <zhell>
#include <zhell_const>

#include <cs_weap_models_api>

#define PLUGIN "[ZP] Weapon: Kinfe default"
#define VERSION "1.0"
#define AUTHOR "VINAGHOST"

new Machete, Bornbeast
new h_Machete, h_Bornbeast


new const v_Machete[] = "models/v_machete.mdl"
new const p_Machete[] = "models/p_machete.mdl"


new const v_bornbeast[] = "models/v_bornbeast.mdl"
new const p_bornbeast[] = "models/p_bornbeast.mdl"


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)

	Machete = zhell_weapons_register("Machete", 0, ZHELL_KNIFE)
	Bornbeast = zhell_weapons_register("Born beast", 0, ZHELL_KNIFE)
}

public plugin_precache() {
	precache_model(v_Machete);
	precache_model(p_Machete);

	precache_model(v_bornbeast);
	precache_model(p_bornbeast);
}

public zp_fw_wpn_select_post(id, itemid) {

	if( itemid == Machete) {

		Set_BitVar(h_Machete, id);
		cs_set_player_view_model(id, CSW_KNIFE, v_Machete)
		cs_set_player_weap_model(id, CSW_KNIFE, p_Machete)

	}
	else if( itemid == Bornbeast) {

		Set_BitVar(h_Machete, id);
		cs_set_player_view_model(id, CSW_KNIFE, v_bornbeast)
		cs_set_player_weap_model(id, CSW_KNIFE, p_bornbeast)

	}
}

public zp_fw_wpn_remove(id, itemid) {

	if( itemid == Machete) {

		UnSet_BitVar(h_Machete, id);
		cs_reset_player_view_model(id, CSW_KNIFE)
		cs_reset_player_weap_model(id, CSW_KNIFE)

	}
	else if( itemid == Bornbeast) {

		UnSet_BitVar(h_Bornbeast, id);
		cs_reset_player_view_model(id, CSW_KNIFE)
		cs_reset_player_weap_model(id, CSW_KNIFE)

	}


}
