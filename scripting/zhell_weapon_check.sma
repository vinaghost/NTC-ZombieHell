#include <amxmodx>

#include <zhell>
#include <zhell_const>

public plugin_init() {
	register_plugin("Zombie Hell:  Weapon Checker", "1.0", "VINAGHOST")
}

public zhell_wpn_select_pre( id, itemid, ignorecost) {
	// Ignore item costs?
	if (ignorecost)
		return ZHELL_WEAPON_AVAILABLE;
	new current,  required = zhell_weapons_get_cost(itemid);

	current = zhell_point_get(id)

	if (current < required)
		return ZHELL_WEAPON_NOT_AVAILABLE;

	return ZHELL_WEAPON_AVAILABLE;
}

public zhell_wpn_select_post(id, itemid, ignorecost) {
	// Ignore item costs?
	if (ignorecost)
		return;

	new current;
	new required = zhell_weapons_get_cost(itemid);

	current = zhell_point_get(id)
	zhell_point_set(id, current - required)
}
