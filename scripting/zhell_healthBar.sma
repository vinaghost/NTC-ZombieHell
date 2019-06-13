#include <amxmodx>
#include <hamsandwich>

#include <cs_ham_bots_api>

#include <zhell>
#include <zhell_const>
// Integers

#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "meTaLiCroSS"

new g_bIsConnected;

public plugin_init()
{
    register_plugin("Zombie Hell: Health show", PLUGIN_VERSION, PLUGIN_AUTHOR)

    RegisterHam(Ham_TakeDamage, "player", "fw_Player_TakeDamage_Post", 1);
    RegisterHamBots(Ham_TakeDamage, "fw_Player_TakeDamage_Post", 1);

}

public client_putinserver(iId) Set_BitVar(g_bIsConnected,iId);
public client_disconnected(iId) UnSet_BitVar(g_bIsConnected,iId);

public fw_Player_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageType)
{
    if( !Get_BitVar(g_bIsConnected,iAttacker) || iVictim == iAttacker)
        return HAM_IGNORED;

    if(zhell_is_zombie(iVictim)) {
        static iVictimHealth;
        iVictimHealth = get_user_health(iVictim);

        if(iVictimHealth > 0)
            client_print(iAttacker, print_center, "HP: %d", iVictimHealth)
        else
            client_print(iAttacker, print_center, "CHẾT");

        return HAM_IGNORED;
    }

    return HAM_IGNORED;
}
