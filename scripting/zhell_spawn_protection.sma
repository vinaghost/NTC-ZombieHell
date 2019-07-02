#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <cs_ham_bots_api>

#include <zhell>
#include <zhell_const>


#define PLUGIN_NAME "Zombie Hell: Spawn Protection"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

new g_protect;
public plugin_init() {

    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    RegisterHam( Ham_TakeDamage , "player" , "fw_HamTakeDamage" );
    RegisterHamBots( Ham_TakeDamage  , "fw_HamTakeDamage" );

}
public client_disconnected(id) {
    remove_task(id);
}
public zhell_spawn_human(id) {
    Set_BitVar(g_protect, id);
    set_user_rendering( id , kRenderFxGlowShell , 0 , 0 , 255 , kRenderNormal , 25 );
    set_task( 10.0 , "RemoveProtect" , id );
}

public RemoveProtect(id) {
    UnSet_BitVar(g_protect, id);
    set_user_rendering( id , kRenderFxGlowShell , 0 , 0 , 0 , kRenderNormal , 25 );
}

public fw_HamTakeDamage( iVictim , iInflictor , iAttacker , Float:fDamage , DmgBits ) {

    if( Get_BitVar(g_protect, iVictim) ) return HAM_SUPERCEDE;

    return HAM_IGNORED;
}
