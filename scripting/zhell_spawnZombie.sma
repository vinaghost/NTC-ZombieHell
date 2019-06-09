#include <amxmodx>


#define PLUGIN_NAME "Zombie Hell: Spawn Zombie"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

new g_player;

public plugin_init() {

    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    g_player = 0;
}
public client_authorized(id) {
    if(is_user_bot(id)) return;

    g_player++;

    set_task( 5.0, "creatZombie" );
}
public client_disconnected(id) {
    if(is_user_bot(id)) return;

    g_player--;
    set_task( 5.0, "creatZombie" );
}
public creatZombie() {
    if( g_player < 1) {
        server_cmd("yb_quota 0");
    }
    else {
        server_cmd("yb_quota 16");
    }
}
