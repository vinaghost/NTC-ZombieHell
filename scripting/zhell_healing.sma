#include <amxmodx>
#include <hamsandwich>
#include <fun>

#include <cs_ham_bots_api>

#include <zhell>
#include <zhell_const>

#define PLUGIN_NAME "Zombie Hell: Healing"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "VINAGHOST"

new g_bIsConnected;

new cvar_zombieHealing, cvar_humanHealing;
new level;
public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    RegisterHam(Ham_TakeDamage, "player", "fwHamPlayerTakeDamagePost", 1);
    RegisterHamBots(Ham_TakeDamage, "fwHamPlayerTakeDamagePost", 1);

    cvar_zombieHealing = register_cvar("zhell_zombie_healing", "10");
    cvar_humanHealing = register_cvar("zhell_zombie_healing", "30");

}

public client_putinserver(iId) Set_BitVar(g_bIsConnected,iId);
public client_disconnected(iId) UnSet_BitVar(g_bIsConnected,iId);

public zhell_round_start() {

    level = zhell_get_level();
}
public fwHamPlayerTakeDamagePost(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageType)
{
    if( !Get_BitVar(g_bIsConnected,iAttacker) || iVictim == iAttacker)
        return HAM_IGNORED;

    if(zhell_is_zombie(iAttacker)) {

        set_user_health(iAttacker, get_user_health(iAttacker) + get_pcvar_num(cvar_zombieHealing) + level);

        return HAM_IGNORED;
    }

    return HAM_IGNORED;
}


public zhell_killed_human(victim, attacker) {
    if( !Get_BitVar(g_bIsConnected,attacker) || victim == attacker)
        return;

    if(zhell_is_zombie(attacker)) {

        set_user_health(attacker, get_user_health(attacker) + (get_pcvar_num(cvar_zombieHealing) + level) * 2);

        return;
    }

}

public zhell_killed_zombie(victim, attacker) {
    if( !Get_BitVar(g_bIsConnected,attacker) || victim == attacker)
        return;

    if(!zhell_is_zombie(attacker)) {


        static health; health = get_user_health(attacker);
        if( health < 100 ) {
            static reward; reward = (get_pcvar_num(cvar_humanHealing) + level);

            if( victim == zhell_get_boss()) {
                reward *=2;
            }

            if( health + reward > 100) {
                set_user_health(attacker, 100);
            }
            else {
                set_user_health(attacker, health);
            }
        }

        return;
    }

}
