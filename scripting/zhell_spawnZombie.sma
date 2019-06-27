#include <amxmodx>


#include <zhell>

#define PLUGIN_NAME "Zombie Hell: Spawn Zombie"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"


new bot_quota;
public plugin_init() {

    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    bot_quota = get_cvar_pointer("yb_quota");

    set_pcvar_num(bot_quota, 0);

}
public zhell_spawn_human(id) {

    if( get_pcvar_num(bot_quota) < 1 ) set_task( 1.0, "creatZombie" );
}
public client_disconnected(id) {
    if(is_user_bot(id)) return;

    new players[32], num;
    get_players(players, num, "c")
    if( num < 1 ) {
        if( get_pcvar_num(bot_quota) > 1 ) set_task( 1.0, "destroyZombie" );
    }

}
public creatZombie() {
    set_pcvar_num(bot_quota, 16);
}
public destroyZombie() {
    set_pcvar_num(bot_quota, 0);
}
