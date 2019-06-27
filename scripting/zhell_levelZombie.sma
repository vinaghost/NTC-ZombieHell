#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <fun>
#include <cstrike>

#include <cs_maxspeed_api>
#include <cs_ham_bots_api>

#include <zhell>
#include <zhell_const>


#define PLUGIN_NAME "Zombie Hell: Level Zombie"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

enum {
    TASK_RESPAWN = 1000
};

/*==============cvar==============*/
new cvar_zombiearmor;
new cvar_zombieHealth;
new cvar_lighting;

/*==============variable==============*/
new g_level, g_zombie_spawn, g_zombie_total, g_zombie_died;
new g_boss;
new g_zombie_health;

new const Float:g_speedZombie[10] = {
    1.0,
    1.2,
    1.3,
    1.4,
    1.5,
    1.6,
    1.7,
    1.8,
    1.9,
    3.0
};

new const Float:g_speedBoss[10] = {
    1.4,
    1.5,
    1.6,
    1.7,
    1.8,
    1.9,
    2.0,
    2.4,
    2.5,
    5.0
};


public plugin_init() {

    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    //g_maxPlayer = get_maxplayers();

    cvar_zombiearmor = register_cvar("zhell_zombie_armor", "100");
    cvar_zombieHealth = register_cvar("zhell_zombie_health", "100");
    cvar_lighting = register_cvar("zhell_lighting", "f");

    register_clcmd("say /test", "test");

    g_level = 1;
    zhell_round_start();
}
public plugin_natives() {
    register_native("zhell_get_level", "_zhell_get_level");

    register_native("zhell_get_zombie_health", "_zhell_get_zombie_health");
    register_native("zhell_get_zombie_speed", "_zhell_get_zombie_speed");
    register_native("zhell_get_boss_health", "_zhell_get_boss_health");
    register_native("zhell_get_boss_speed", "_zhell_get_boss_speed");

    register_native("zhell_get_zombie_total", "_zhell_get_zombie_total");
    register_native("zhell_get_zombie_last", "_zhell_get_zombie_last");



    register_native("zhell_get_boss", "_zhell_get_boss");
}
public test(id) {
    client_print(id, print_chat, "Zom da spawn: %d, Zom da die: %d", g_zombie_spawn, g_zombie_died );
}
public zhell_round_start() {

    get_level_data();
    lighting_effects();
    g_boss = 0;

    g_zombie_total = 16 * (g_level + 1);
    g_zombie_spawn = 0;

    g_zombie_died = 0;

    new players[32], num;

    get_players(players, num, "e", "CT");
    //new id;
    for(new i = 0; i < num; i++) {
        //id = players[i];
        remove_task(players[i] + TASK_RESPAWN);
    }
}
public zhell_round_end(team_win) {

    if (team_win == ZHELL_HUMAN) {
        set_level(1);
    }
    else {
        set_level(0);
    }
}

public zhell_spawn_zombie(id) {
    if( !is_user_alive(id) ) return;

    zombie_power(id);
    g_zombie_spawn++;
}
public zhell_killed_zombie(id) {
    cs_reset_player_maxspeed(id);

    if( g_zombie_spawn < g_zombie_total) {
        set_task(5.0, "reSpawn", id + TASK_RESPAWN);
    }
    g_zombie_died ++;
}
public zhell_killed_human(id) {
    set_task(10.0, "reSpawn", id + TASK_RESPAWN);
}
public zhell_last_zombie_pre(id) {

    if( g_boss ) return PLUGIN_HANDLED;

    return PLUGIN_CONTINUE;

}
public zhell_last_zombie_post(id) {

    g_boss = id;
    set_user_health(id, get_user_health(id) + g_zombie_health * ( 1 + g_level ) * ( 5 ) );
    cs_set_user_armor(id, ((get_pcvar_num(cvar_zombiearmor)*g_level)*2), CS_ARMOR_VESTHELM);
    cs_reset_player_maxspeed(id);
    cs_set_player_maxspeed_auto(id, g_speedBoss[g_level - 1]);
    set_pev(id, pev_gravity, 0.7);

}
get_level_data() {
    g_zombie_spawn = g_level;
    g_zombie_health = get_pcvar_num(cvar_zombieHealth);
}
lighting_effects() {

    new lighting[5]
    lighting = "f"

    get_pcvar_string(cvar_lighting, lighting, charsmax(lighting));

    strtolower(lighting)
    engfunc(EngFunc_LightStyle, 0, lighting)
}

public zombie_power(id) {

    cs_set_player_maxspeed_auto(id, g_speedZombie[g_level -1]);
    cs_set_user_armor(id, (get_pcvar_num(cvar_zombiearmor)*g_level), CS_ARMOR_VESTHELM);

    strip_user_weapons(id);
    give_item(id, "weapon_knife");
    cs_set_user_money(id, 0);
}

public reSpawn(id) {
    id -= TASK_RESPAWN;

    if( is_user_connected(id ) )
        ExecuteHamB(Ham_CS_RoundRespawn, id);

}

set_level(level_up) // level_up:[1=level up/0=level back]
{
    if (level_up) {
        if (g_level >= 10) {
            server_cmd("restart");
        }
        else {
            g_level ++
        }
    }
    else {
        g_level --;
        if( g_level < 1 ) g_level = 1;
    }
}
public _zhell_get_level() {
    return g_level;
}

public _zhell_get_zombie_health() {
    return g_zombie_health * ( g_level);
}

public Float:_zhell_get_zombie_speed() {
    return g_speedZombie[ g_level - 1];
}
public _zhell_get_boss_health() {
    return g_zombie_health * ( 1 + g_level ) * ( 5 ) ;
}
public Float:_zhell_get_boss_speed() {
    return g_speedBoss[ g_level - 1];
}
public _zhell_get_boss() {
    return g_boss;
}

public _zhell_get_zombie_total() {
    return g_zombie_total;
}

public _zhell_get_zombie_last() {
    return g_zombie_total - g_zombie_died + 1;
}
