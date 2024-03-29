#include <amxmodx>


#define PLUGIN_NAME "Zombie Hell: Config"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"


public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

}
public plugin_cfg() {
    server_cmd("mp_autoteambalance 0");
    server_cmd("mp_freezetime 0");
    server_cmd("mp_roundtime 5");
    server_cmd("mp_buytime 5");
    server_cmd("mp_limitteams 0");
    server_cmd("mp_timelimit 0");
    server_cmd("mp_forcechasecam 1");
    server_cmd("mp_forcecamera 1");
    server_cmd("humans_join_team T");
    server_cmd("sv_skycolor_r 0")
    server_cmd("sv_skycolor_g 0")
    server_cmd("sv_skycolor_b 0")
    server_cmd("mp_round_infinite a");
    //reGameDLL
    server_cmd("mp_maxmoney 999999");
    server_cmd("mp_nadedrops 1");
    server_cmd("mp_auto_reload_weapons 1");
    server_cmd("mp_refill_bpammo_weapons 3");
    server_cmd("mp_auto_join_team 1");

    server_cmd("mp_scoreboard_showhealth 3");

    //yabp
    server_cmd("yb_join_after_player 0");

    //semiclip
    server_cmd("semiclip_effects 1");

}

