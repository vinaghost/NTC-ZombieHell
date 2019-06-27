#include <amxmodx>
#include <engine>
#include <cstrike>
#include <hamsandwich>


#include <cs_ham_bots_api>

#include <zhell_const>

#define PLUGIN_NAME "Zombie Hell: Core"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "VINAGHOST"

new bool:g_first_round;

new p_zombie;

enum _:TOTAL_FORWARDS
{
    FW_USER_SPAWN_ZOMBIE = 0,
    FW_USER_SPAWN_HUMAN,
    FW_USER_KILLED_ZOMBIE,
    FW_USER_KILLED_HUMAN,

    FW_USER_LAST_ZOMBIE_PRE,
    FW_USER_LAST_ZOMBIE_POST,
    FW_USER_LAST_HUMAN_PRE,
    FW_USER_LAST_HUMAN_POST,

    FW_ROUND_START,
    FW_ROUND_END
}

enum _: {
    COUNTDOWN,
    START,
    END
}

new g_ForwardResult;
new g_Forwards[TOTAL_FORWARDS];

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
    register_logevent("logevent_round_end", 2, "1=Round_End")

    RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1);
    RegisterHamBots(Ham_Spawn, "fwHamPlayerSpawnPost", 1);
    RegisterHam(Ham_Killed, "player", "fwHamPlayerKilledPost", 1);
    RegisterHamBots(Ham_Killed, "fwHamPlayerKilledPost", 1);


    register_message(get_user_msgid("TextMsg"), "message_TextMsg")

    g_Forwards[FW_USER_SPAWN_ZOMBIE] = CreateMultiForward("zhell_spawn_zombie", ET_CONTINUE, FP_CELL);
    g_Forwards[FW_USER_SPAWN_HUMAN] = CreateMultiForward("zhell_spawn_human", ET_CONTINUE, FP_CELL);
    g_Forwards[FW_USER_KILLED_ZOMBIE] = CreateMultiForward("zhell_killed_zombie", ET_CONTINUE, FP_CELL, FP_CELL);
    g_Forwards[FW_USER_KILLED_HUMAN] = CreateMultiForward("zhell_killed_human", ET_CONTINUE, FP_CELL, FP_CELL);
    g_Forwards[FW_USER_LAST_ZOMBIE_PRE] = CreateMultiForward("zhell_last_zombie_pre", ET_CONTINUE, FP_CELL);
    g_Forwards[FW_USER_LAST_ZOMBIE_POST] = CreateMultiForward("zhell_last_zombie_post", ET_CONTINUE, FP_CELL);
    g_Forwards[FW_USER_LAST_HUMAN_PRE] = CreateMultiForward("zhell_last_human_pre", ET_CONTINUE, FP_CELL);
    g_Forwards[FW_USER_LAST_HUMAN_POST] = CreateMultiForward("zhell_last_human_post", ET_CONTINUE, FP_CELL);
    g_Forwards[FW_ROUND_START] = CreateMultiForward("zhell_round_start", ET_CONTINUE);
    g_Forwards[FW_ROUND_END] = CreateMultiForward("zhell_round_end", ET_CONTINUE, FP_CELL);

    g_first_round = false;
}
public plugin_natives() {
    register_native("zhell_is_round_start", "_zhell_is_round_start");
    register_native("zhell_is_round_restart", "_zhell_is_round_restart");
    register_native("zhell_is_round_end", "_zhell_is_round_end");

    register_native("zhell_is_zombie", "_zhell_is_zombie");

    register_native("zhell_get_count_zombie", "_zhell_get_count_zombie");
    register_native("zhell_get_count_human", "_zhell_get_count_human");
}
public client_putinserver(id) {

    if( is_user_bot(id) ) {
        Set_BitVar(p_zombie, id);
    }
}
public client_disconnected(id) {
    UnSet_BitVar(p_zombie, id)
}

public event_round_start() {

    g_round_start = true;


    ExecuteForward(g_Forwards[FW_ROUND_START], g_ForwardResult);


    g_round_restart = false;
    g_round_start = false;
}
public logevent_round_end() {
    if (g_round_restart) return;

    g_round_end = true

    // Prevent this from getting called twice when restarting (bugfix)
    static Float:lastendtime, Float:current_time;
    current_time = get_gametime();

    if (current_time - lastendtime < 0.5) return;

    lastendtime = current_time;
    new players[32], num;
    getHuman(players, num)

    if( num > 0)
        ExecuteForward(g_Forwards[FW_ROUND_END], g_ForwardResult, ZHELL_HUMAN);
    else
        ExecuteForward(g_Forwards[FW_ROUND_END], g_ForwardResult, ZHELL_ZOMBIE);

}
public fwHamPlayerSpawnPost(id) {
    if( !is_user_alive(id) ) return;

    if( cs_get_user_team(id) == CS_TEAM_T && Get_BitVar(p_zombie, id) ) {
        ExecuteForward(g_Forwards[FW_USER_SPAWN_ZOMBIE], g_ForwardResult, id);

    }
    else if( cs_get_user_team(id) == CS_TEAM_CT ){

        ExecuteForward(g_Forwards[FW_USER_SPAWN_HUMAN], g_ForwardResult, id);
    }
}

public fwHamPlayerKilledPost(victim, attacker, shouldgib) {
    if( !is_user_connected(victim) ) return;

    if(Get_BitVar(p_zombie, victim)) {
        ExecuteForward(g_Forwards[FW_USER_KILLED_ZOMBIE], g_ForwardResult, victim, attacker);
    }
    else {
        ExecuteForward(g_Forwards[FW_USER_KILLED_HUMAN], g_ForwardResult, victim, attacker);
    }

    CheckLastZombieHuman();
}
CheckLastZombieHuman() {
    new humanPlayers[32], zombiePlayers[32];
    new humanCount, zombieCount;

    getZombie(zombiePlayers, zombieCount);
    getHuman(humanPlayers, humanCount);

    if(zombieCount == 1) {
        ExecuteForward(g_Forwards[FW_USER_LAST_ZOMBIE_PRE], g_ForwardResult, zombiePlayers[0]);

        if(g_ForwardResult < PLUGIN_HANDLED ){
            ExecuteForward(g_Forwards[FW_USER_LAST_ZOMBIE_POST], g_ForwardResult, zombiePlayers[0]);
        }
    }

    if (humanCount == 1) {

        ExecuteForward(g_Forwards[FW_USER_LAST_HUMAN_PRE], g_ForwardResult, humanPlayers[0]);

        if(g_ForwardResult < PLUGIN_HANDLED ){
            ExecuteForward(g_Forwards[FW_USER_LAST_HUMAN_POST], g_ForwardResult, zombiePlayers[0]);
        }

    }
}

public message_TextMsg()
{
    static message[32]
    get_msg_arg_string(2, message, charsmax(message))
    if (equal(message, "#Game_Commencing") || equal(message, "#Game_will_restart_in")) {
        g_round_restart = true;
    }
    else if (equal(message, "#Hostages_Not_Rescued") || equal(message, "#Round_Draw") || equal(message, "#Terrorists_Win") || equal(message, "#CTs_Win")) {
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public _zhell_is_round_start(iPlugin,iParams) {
    return g_round_start;
}

public _zhell_is_round_restart(iPlugin,iParams) {
    return g_round_restart;
}

public _zhell_is_round_end(iPlugin,iParams) {
    return g_round_end;
}

public _zhell_is_zombie(iPlugin, iParams) {
    if( iParams != 1) return -1;

    return Get_BitVar(p_zombie,  get_param(1)) ? 1 : 0;
}

public _zhell_get_count_human(iPlugin, iParams) {
    new players[32], num;
    getHuman(players, num);
    return num;
}
public _zhell_get_count_zombie(iPlugin, iParams) {
    new players[32], num;
    getZombie(players, num);
    return num;
}
