#include <amxmodx>

#include <cs_player_models_api>

#include <zhell>
#include <zhell_const>


#define PLUGIN_NAME "Zombie Hell: Core"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "VINAGHOST"

new const g_model_zombie_path[] = "models/player/zh_zombie/zh_zombie.mdl";
new const g_model_zombie[] = "zh_zombie";
/*new const g_model_boss_path[] = "models/player/zh_boss/zh_boss.mdl";
new const g_model_boss[] = "zh_boss";*/


public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

}
public plugin_precache() {

    precache_model(g_model_zombie_path);
    //precache_model(g_model_boss_path);
}

public zhell_spawn_human(id) {
    cs_reset_player_model(id);
}


public zhell_spawn_zombie(id) {

    cs_set_player_model(id, g_model_zombie);
}
/*
public zhell_last_zombie_post(id) {
    cs_set_player_model(id, g_model_boss);
}
*/
