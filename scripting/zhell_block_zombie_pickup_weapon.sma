#include <amxmodx>
#include <hamsandwich>
#include <engine>

#include <zhell>

#define PLUGIN_NAME "Zombie Hell: Remove Object"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"


public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    RegisterHam(Ham_Touch, "armoury_entity", "FwdHamPickupWeapon");
    RegisterHam(Ham_Touch, "weaponbox", "FwdHamPickupWeapon");

    register_touch("weapon_shield", "player", "OnPlayerTouchShield");

}

public FwdHamPickupWeapon(ent, id)
{
    if(is_user_alive(id) && zhell_is_zombie(id)) return HAM_SUPERCEDE;

    return HAM_IGNORED;
}
public OnPlayerTouchShield(ent, id)
{
    if(is_user_alive(id) && zhell_is_zombie(id)) return PLUGIN_HANDLED;

    return PLUGIN_CONTINUE;
}
