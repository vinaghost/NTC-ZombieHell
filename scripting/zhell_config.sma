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
}

