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

new cvar_zombieHealth, cvar_zombieMaxSpeed;
new cvar_level_lighting[10];

/*==============variable==============*/
new g_level, g_zombie_spawn = 0;
new g_zombie_health, Float:g_zombie_maxspeed;

new boss, g_last_zombie;

new g_boss;
new g_spawn_first;
new g_spawn[33];

//new g_maxPlayer;
new g_msgCrosshair;

public plugin_init() {

    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    register_message(get_user_msgid("Money"), "message_Money")

    g_msgCrosshair = get_user_msgid("Crosshair");
    //g_maxPlayer = get_maxplayers();

    cvar_zombiearmor = register_cvar("zhell_zombie_armor", "100");

    cvar_zombieHealth = register_cvar("zh_zombie_health", "100");
    cvar_zombieMaxSpeed = register_cvar("zh_zombe_maxspeed", "250.0");


    cvar_level_lighting[0] = register_cvar("zh_level1_lighting", "f")

    cvar_level_lighting[1] = register_cvar("zh_level2_lighting", "e");

    cvar_level_lighting[2] = register_cvar("zh_level3_lighting", "d");

    cvar_level_lighting[3] = register_cvar("zh_level4_lighting", "c");

    cvar_level_lighting[4] = register_cvar("zh_level5_lighting", "b");

    cvar_level_lighting[5] = register_cvar("zh_level6_lighting", "c");

    cvar_level_lighting[6] = register_cvar("zh_level7_lighting", "d");

    cvar_level_lighting[7] = register_cvar("zh_level8_lighting", "c");

    cvar_level_lighting[8] = register_cvar("zh_level9_lighting", "b");

    cvar_level_lighting[9] = register_cvar("zh_level10_lighting", "a");
    g_level = 1;
    zhell_round_start();
}
public plugin_natives() {
    register_native("zhell_get_level", "_zhell_get_level");

    register_native("zhell_get_zombie_health", "_zhell_get_zombie_health");
    register_native("zhell_get_zombie_speed", "_zhell_get_zombie_speed");
    register_native("zhell_get_boss_health", "_zhell_get_boss_health");
    register_native("zhell_get_boss_speed", "_zhell_get_boss_speed");
}

public zhell_round_start() {

    get_level_data();
    lighting_effects();
    boss = 0;
    g_spawn_first = 0;

    new players[32], num;

    get_players(players, num, "e", "CT");
    //new id;
    for(new i = 0; i < num; i++) {
        //id = players[i];
        remove_task(players[i] + TASK_RESPAWN);
    }
}
public zhell_round_end() {

    if (zhell_get_count_human() > 0) {
        set_dhudmessage(0, 0, 255, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0);
        show_dhudmessage( 0, "Human win." );
        set_level(1);
    }
    else {
        set_dhudmessage(255, 0, 0, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0);
        show_dhudmessage( 0, "Zombie win." );
        set_level(0);
    }
}

public zhell_spawn_zombie(id) {
    if( !is_user_alive(id) ) return;

    if( !Get_BitVar(g_spawn_first, id) ) {
        Set_BitVar(g_spawn_first, id);
        g_spawn[id] = g_zombie_spawn;
    }
    else {
        g_spawn[id] --;
    }

    zombie_power(id);


}
public zhell_killed_zombie(id) {
    cs_reset_player_maxspeed(id);
    if( g_spawn[id] > 0) {
        set_task(5.0, "reSpawn", id + TASK_RESPAWN);

        g_last_zombie = 0;

        g_spawn[id] --;
        return;
    }

    g_last_zombie = 1;
}
public zhell_killed_human(id) {
    client_print(id, print_center, "HOI SINH SAU 10 GIAY NUA");
    set_task(10.0, "reSpawn", id + TASK_RESPAWN);
}
public zhell_last_zombie_pre(id) {

    if( !g_last_zombie ) return PLUGIN_HANDLED;
    if( boss ) return PLUGIN_HANDLED;

    return PLUGIN_CONTINUE;

}
public zhell_last_zombie_post(id) {

    Set_BitVar(g_boss, id);

    set_user_health(id, get_user_health(id) + g_zombie_health * (3 + g_level ));
    cs_set_user_armor(id, ((get_pcvar_num(cvar_zombiearmor)*g_level)*2), CS_ARMOR_VESTHELM);
    cs_set_player_maxspeed_auto(id, g_zombie_maxspeed * (1.5 + g_level / 10 ));
    set_pev(id, pev_gravity, 0.7);

}
get_level_data() {
    g_zombie_spawn = g_level;
    g_zombie_health = get_pcvar_num(cvar_zombieHealth);
    g_zombie_maxspeed = get_pcvar_float(cvar_zombieMaxSpeed);
}
lighting_effects() {

    new lighting[5]
    lighting = "f"

    get_pcvar_string(cvar_level_lighting[g_level - 1], lighting, charsmax(lighting));

    strtolower(lighting)
    engfunc(EngFunc_LightStyle, 0, lighting)
}

public zombie_power(id) {
    UnSet_BitVar(g_boss,id);

    cs_set_player_maxspeed_auto(id, g_zombie_maxspeed);
    set_user_health(id, g_zombie_health);
    cs_set_user_armor(id, (get_pcvar_num(cvar_zombiearmor)*g_level), CS_ARMOR_VESTHELM);

    strip_user_weapons(id);
    give_item(id, "weapon_knife");
    cs_set_user_money(id, 0);
    set_task(0.1, "hide_user_money", id)
}


public hide_user_money(id){
    // Not alive
    if (!is_user_alive(id)) return;

    // Hide money
    message_begin(MSG_ONE, get_user_msgid("HideWeapon"), _, id)
    write_byte((1<<5)) // what to hide bitsum
    message_end()

    // Hide the HL crosshair that's drawn
    message_begin(MSG_ONE, g_msgCrosshair, _, id)
    write_byte(0) // toggle
    message_end()
}

// Take off player's money
public message_Money(msg_id, msg_dest, msg_entity) {
    if (!is_user_connected(msg_entity))   return PLUGIN_CONTINUE;

    // Block zombies money message
    if (cs_get_user_team(msg_entity) == CS_TEAM_T) return PLUGIN_HANDLED;

    return PLUGIN_CONTINUE;
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
    return g_zombie_health;
}

public Float:_zhell_get_zombie_speed() {
    return g_zombie_maxspeed;
}
public _zhell_get_boss_health() {
    return g_zombie_health * (3 + g_level );
}
public Float:_zhell_get_boss_speed() {
    return g_zombie_maxspeed * (1.5 + g_level / 10 );
}
