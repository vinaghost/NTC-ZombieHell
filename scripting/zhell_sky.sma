#include <amxmodx>
/*
#include <zhell>
#include <zhell_const>
*/

#define PLUGIN_NAME "Zombie Hell: Sky"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "VINAGHOST"

new const SKY_NAMES[] = "zombiehell";


public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);


    set_cvar_string("sv_skyname", SKY_NAMES);

}
