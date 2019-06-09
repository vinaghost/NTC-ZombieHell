#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>
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

new cvar_level_spawn[10];
new cvar_level_health[10], cvar_level_maxspeed[10]
new cvar_level_bosshp[10], cvar_level_bossmaxspeed[10]
new cvar_level_lighting[10];

/*==============variable==============*/
new g_level = 1, g_zombie_spawn = 0;
new g_zombie_health, Float:g_zombie_maxspeed;
new g_boss_health, Float: g_boss_maxspeed;

new g_boss;
new g_spawn[33];

new g_round_starting, g_game_restart, g_roundend;

//new g_maxPlayer;
new g_msgCrosshair;

public plugin_init() {

    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    register_event("HLTV", "event_round_start", "a", "1=0", "2=0");

    RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1);
    RegisterHamBots(Ham_Spawn, "fwHamPlayerSpawnPost", 1);
    RegisterHam(Ham_Killed, "player", "fwHamPlayerKilledPost", 1);
    RegisterHamBots(Ham_Killed, "fwHamPlayerKilledPost", 1);


    register_message(get_user_msgid("Money"), "message_Money")
    register_message(get_user_msgid("TextMsg"), "message_TextMsg")


    g_msgCrosshair = get_user_msgid("Crosshair");
    //g_maxPlayer = get_maxplayers();

    cvar_zombiearmor = register_cvar("zhell_zombie_armor", "100");

    cvar_level_health[0] = register_cvar("zh_level1_health", "100")
    cvar_level_maxspeed[0] = register_cvar("zh_level1_maxspeed", "250.0")
    cvar_level_bosshp[0] = register_cvar("zh_level1_bosshp", "15000")
    cvar_level_bossmaxspeed[0] = register_cvar("zh_level1_bossmaxspeed", "275.0")
    cvar_level_lighting[0] = register_cvar("zh_level1_lighting", "f")
    cvar_level_spawn[0] = register_cvar("zh_level1_spawn", "2");

    cvar_level_health[1] = register_cvar("zh_level2_health", "200")
    cvar_level_maxspeed[1] = register_cvar("zh_level2_maxspeed", "255.0")
    cvar_level_bosshp[1] = register_cvar("zh_level2_bosshp", "20000")
    cvar_level_bossmaxspeed[1] = register_cvar("zh_level2_bossmaxspeed", "280.0")
    cvar_level_lighting[1] = register_cvar("zh_level2_lighting", "e")
    cvar_level_spawn[0] = register_cvar("zh_level1_spawn", "2");

    cvar_level_health[2] = register_cvar("zh_level3_health", "300")
    cvar_level_maxspeed[2] = register_cvar("zh_level3_maxspeed", "260.0")
    cvar_level_bosshp[2] = register_cvar("zh_level3_bosshp", "30000")
    cvar_level_bossmaxspeed[2] = register_cvar("zh_level3_bossmaxspeed", "285.0")
    cvar_level_lighting[2] = register_cvar("zh_level3_lighting", "d")
    cvar_level_spawn[2] = register_cvar("zh_level3_spawn", "3");

    cvar_level_health[3]     = register_cvar("zh_level4_health", "400")
    cvar_level_maxspeed[3]      = register_cvar("zh_level4_maxspeed", "265.0")
    cvar_level_bosshp[3]       = register_cvar("zh_level4_bosshp", "40000")
    cvar_level_bossmaxspeed[3]  = register_cvar("zh_level4_bossmaxspeed", "290.0")
    cvar_level_lighting[3]     = register_cvar("zh_level4_lighting", "c")
    cvar_level_spawn[3] = register_cvar("zh_level4_spawn", "4");

    cvar_level_health[4] = register_cvar("zh_level5_health", "500")
    cvar_level_maxspeed[4] = register_cvar("zh_level5_maxspeed", "275.0")
    cvar_level_bosshp[4] = register_cvar("zh_level5_bosshp", "50000")
    cvar_level_bossmaxspeed[4] = register_cvar("zh_level5_bossmaxspeed", "300.0")
    cvar_level_lighting[4] = register_cvar("zh_level5_lighting", "b")
    cvar_level_spawn[4] = register_cvar("zh_level5_spawn", "5");

    cvar_level_health[5] = register_cvar("zh_level6_health", "600")
    cvar_level_maxspeed[5] = register_cvar("zh_level6_maxspeed", "280.0")
    cvar_level_bosshp[5] = register_cvar("zh_level6_bosshp", "70000")
    cvar_level_bossmaxspeed[5] = register_cvar("zh_level6_bossmaxspeed", "305.0")
    cvar_level_lighting[5] = register_cvar("zh_level6_lighting", "c")
    cvar_level_spawn[5] = register_cvar("zh_level6_spawn", "6");

    cvar_level_health[6] = register_cvar("zh_level7_health", "750")
    cvar_level_maxspeed[6] = register_cvar("zh_level7_maxspeed", "285.0")
    cvar_level_bosshp[6] = register_cvar("zh_level7_bosshp", "80000")
    cvar_level_bossmaxspeed[6] = register_cvar("zh_level7_bossmaxspeed", "310.0")
    cvar_level_lighting[6] = register_cvar("zh_level7_lighting", "d")
    cvar_level_spawn[6] = register_cvar("zh_level7_spawn", "6");

    cvar_level_health[7] = register_cvar("zh_level8_health", "850")
    cvar_level_maxspeed[7] = register_cvar("zh_level8_maxspeed", "290.0")
    cvar_level_bosshp[7] = register_cvar("zh_level8_bosshp", "100000")
    cvar_level_bossmaxspeed[7] = register_cvar("zh_level8_bossmaxspeed", "315.0")
    cvar_level_lighting[7] = register_cvar("zh_level8_lighting", "c")
    cvar_level_spawn[7] = register_cvar("zh_level8_spawn", "7");

    cvar_level_health[8] = register_cvar("zh_level9_health", "1000")
    cvar_level_maxspeed[8] = register_cvar("zh_level9_maxspeed", "300.0")
    cvar_level_bosshp[8] = register_cvar("zh_level9_bosshp", "500000")
    cvar_level_bossmaxspeed[8] = register_cvar("zh_level9_bossmaxspeed", "325.0")
    cvar_level_lighting[8] = register_cvar("zh_level9_lighting", "b")
    cvar_level_spawn[8] = register_cvar("zh_level9_spawn", "8");

    cvar_level_health[9] = register_cvar("zh_level10_health", "1500")
    cvar_level_maxspeed[9] = register_cvar("zh_level10_maxspeed", "325.0")
    cvar_level_bosshp[9] = register_cvar("zh_level10_bosshp", "1000000")
    cvar_level_bossmaxspeed[9] = register_cvar("zh_level10_bossmaxspeed", "350.0")
    cvar_level_lighting[9] = register_cvar("zh_level10_lighting", "a")
    cvar_level_spawn[9] = register_cvar("zh_level10_spawn", "10");

}

public event_round_start() {
    g_round_starting = true;
    get_level_data();
    lighting_effects();

    new Players[32]
    new playerCount, i, player ;
    get_players(Players, playerCount, "ae", "TERRORIST");
    for (i=0; i<playerCount; i++) {

        player = Players[i];

        g_spawn[player] = g_zombie_spawn;
        zombie_power(player);
    }
    g_round_starting = false;
    g_game_restart = false;
}
public logevent_round_end() {
    if (g_game_restart) return;

    g_roundend = true

    // Prevent this from getting called twice when restarting (bugfix)
    static Float:lastendtime, Float:current_time;
    current_time = get_gametime();

    if (current_time - lastendtime < 0.5) return;

    lastendtime = current_time;

    static ts[32], ts_num, cts[32], cts_num;
    get_alive_players(ts, ts_num, cts, cts_num);


    if (ts_num > 0) {
        set_dhudmessage(255, 0, 0, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0);
        show_dhudmessage( 0, "Zombie win." );
        set_level(0);
    }
    else {
        set_dhudmessage(0, 0, 255, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0);
        show_dhudmessage( 0, "Human win." );
        set_level(1);
    }
}

public fwHamPlayerSpawnPost(id) {
    if( !is_user_alive(id) ) return;

    if( g_round_starting ) return;

    g_spawn[id] --;
    zombie_power(id);

}
public fwHamPlayerKilledPost(victim, attacker, shouldgib) {
    if( !is_user_connected(victim) ) return;

    cs_reset_player_maxspeed(victim);

    if( (cs_get_user_team(victim) == CS_TEAM_T && g_spawn[victim] > 0 ) || (cs_get_user_team(victim) == CS_TEAM_CT) ) {
        client_print(victim, print_center, "HOI SINH SAU 10 GIAY NUA");
        set_task(10.0, "reSpawn", victim + TASK_RESPAWN)
    }


}
public message_TextMsg()
{
    static message[32]
    get_msg_arg_string(2, message, charsmax(message))
    if (equal(message, "#Game_Commencing") || equal(message, "#Game_will_restart_in"))
    {
        g_game_restart = true
    }
    else if (equal(message, "#Hostages_Not_Rescued") || equal(message, "#Round_Draw") || equal(message, "#Terrorists_Win")
             || equal(message, "#CTs_Win"))
    {
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}
get_level_data() {
    g_zombie_spawn = get_pcvar_num(cvar_level_spawn[g_level - 1]);
    g_zombie_health = get_pcvar_num(cvar_level_health[g_level - 1 ]);
    g_zombie_maxspeed = get_pcvar_float(cvar_level_maxspeed[g_level - 1 ]);
    g_boss_health = get_pcvar_num(cvar_level_bosshp[g_level -1 ]);
    g_boss_maxspeed = get_pcvar_float(cvar_level_bossmaxspeed[g_level - 1 ]);
}
lighting_effects() {

    new lighting[5]
    lighting = "f"

    get_pcvar_string(cvar_level_lighting[g_level], lighting, charsmax(lighting));

    strtolower(lighting)
    engfunc(EngFunc_LightStyle, 0, lighting)
}

public zombie_power(id) {
    UnSet_BitVar(g_boss,id);

    cs_set_player_maxspeed_auto(id, g_zombie_maxspeed);
    fm_set_user_health(id, g_zombie_health);
    cs_set_user_armor(id, (get_pcvar_num(cvar_zombiearmor)*g_level), CS_ARMOR_VESTHELM);

    fm_strip_user_weapons(id);
    fm_give_item(id, "weapon_knife");
    cs_set_user_money(id, 0);
    set_task(0.1, "hide_user_money", id)
}


public hide_user_money(id){
    // Not alive
    if (!is_user_alive(id))
        return;

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
get_alive_players(ts[32], &ts_num, cts[32], &cts_num) {
    get_players(ts, ts_num, "ae", "TERRORIST");
    get_players(cts, cts_num, "ae", "CT");

}
