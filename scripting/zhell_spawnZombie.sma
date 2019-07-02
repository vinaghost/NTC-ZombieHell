#include <amxmodx>

#include <zhell>
#include <zhell_const>


#define PLUGIN_NAME "Zombie Hell: Zombie Spawn"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

new g_player, g_connect;
new g_quota;
public plugin_init() {

    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    g_player = 0;

    set_task(1.0, "setting");


}
public setting() {
    g_quota = get_cvar_pointer("yb_quota")

    set_pcvar_num(g_quota, 0);
}

public zhell_client_connected(id){
    Set_BitVar(g_connect, id);
    g_player ++;

    if( get_pcvar_num(g_quota) == 0 )
        set_pcvar_num(g_quota, 16);
}

public client_disconnected(id) {
    if( Get_BitVar(g_connect, id ) ) {
        g_player --;
        if ( g_player < 0 ) g_player = 0;

        if( get_pcvar_num(g_quota) == 16  && !g_player )
            set_pcvar_num(g_quota, 0);
    }

}
