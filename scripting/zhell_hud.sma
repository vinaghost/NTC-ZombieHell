#include <amxmodx>
#include <fakemeta>

#include <zhell>
#include <zhell_const>

#define PLUGIN_NAME "Zombie Hell: Hud"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

#define TASK_COOLDOWN 2000
new const g_info[][] = {
    "Hoàng hôn định mệnh",
    "Màn đêm buông xuống",
    "Đường thoát thân",
    "Éo còn hi vọng",
    "Tia sáng trong bóng đêm",
    "Trận chiến đẫm máu",
    "Sống trong địa ngục",
    "Ác mộng trong đêm khuya",
    "Chương cuối",
    "Hồi kết"
};
new g_Classname[] = "vinaEntity";

new  g_hudSync, g_hudSync1/*, g_hudSync2*/;

new g_level;
new g_boss_health, Float:g_boss_speed;
new g_zombie_health, Float:g_zombie_speed;

enum _:PlayerData
{
    Rank[32],
    XP,
    NextXP,
    Level
}

new p_hud;
new g_cooldown;
new const Float:time_repeat = 5.0;
public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    new Ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
    set_pev(Ent,pev_classname,g_Classname)
    set_pev(Ent,pev_nextthink, 5.0)

    register_forward(FM_Think,"ForwardThink")


    register_clcmd("say /hud", "hud");

    g_hudSync = CreateHudSyncObj();
    g_hudSync1 = CreateHudSyncObj();
    //g_hudSync2 = CreateHudSyncObj();

    zhell_round_start();
}
public zhell_client_connected(id) {
    if (!is_user_bot(id)) {
        set_task(time_repeat, "showHud", id, _, _, "b");
        Set_BitVar(p_hud, id);
    }
}
public client_disconnected(id) {
    remove_task(id)
}
public zhell_round_cooldown() {
    g_cooldown = 10;

    set_dhudmessage(0, 255, 0, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0);
    show_dhudmessage( 0, "%d", g_cooldown );
    set_task(1.0, "cooldown", TASK_COOLDOWN + g_cooldown);

}
public cooldown(taskid) {
    taskid -= TASK_COOLDOWN;
    g_cooldown--;
    set_dhudmessage(0, 255, 0, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0);
    show_dhudmessage( 0, "%d", g_cooldown );

    if( g_cooldown <  1 ) {
        return;
    }
    set_task(1.0, "cooldown", TASK_COOLDOWN + g_cooldown);
}
public zhell_round_start() {

    g_level = zhell_get_level();
    g_boss_health = zhell_get_boss_health();
    g_boss_speed = zhell_get_boss_speed();
    g_zombie_health = zhell_get_zombie_health();
    g_zombie_speed = zhell_get_zombie_speed();
}
public zhell_round_end(team_win) {
    if (team_win == ZHELL_HUMAN) {
        set_dhudmessage(0, 0, 255, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0);
        show_dhudmessage( 0, "Human win." );
    }
    else {
        set_dhudmessage(255, 0, 0, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0);
        show_dhudmessage( 0, "Zombie win." );
    }
}
public zhell_last_zombie_post(id) {
    new name[33];
    get_user_name(id, name, charsmax(name));

    set_hudmessage(0, 255, 100, -1.0, 0.30, 0, 0.0, 6.0, 0.1, 0.2, -1);
    ShowSyncHudMsg(0, g_hudSync1, "Xuất hiện BOSS [%s]", name);
}
public showHud(id)
{
    if( Get_BitVar(p_hud, id) ) {
        //DisplayHUDRank(id);
        DisplayHUDLevel(id);
    }

}

public hud(id) {
    if( Get_BitVar(p_hud, id) ) {
        UnSet_BitVar(p_hud, id);
    }
    else {
        Set_BitVar(p_hud, id);
    }
}

public zhell_point_reward(id, point) {

    if( point <= 0 ) return;
    set_dhudmessage(0, 255, random(256), -1.0, -1.0, 0, 0.0, 10.0);
    show_dhudmessage(id, "%d", point);
}
public DisplayHUDLevel(id) {
    set_hudmessage(id, 255, 0, -1.0, 0.0, 0, 0.0, time_repeat,  0.0, 0.2, -1);
    ShowSyncHudMsg(id, g_hudSync, "Ngày %d: - %s^nBOSS [HP: %d - SPEED: %.1f]^nZombie [HP: %d - SPEED: %.1f]^nCòn lại: [%d/%d]",
                                    g_level, g_info[g_level - 1], g_boss_health, g_boss_speed, g_zombie_health, g_zombie_speed, zhell_get_zombie_last(), zhell_get_zombie_total() );
}
/*
public DisplayHUDRank(id) {
    static iTarget;
    iTarget = id;

    if(!is_user_alive(id)) {
        iTarget = pev(id, pev_iuser2);

    }

    if(!iTarget || is_user_bot(id)) {
        return
    }

    set_hudmessage(106, -1, 208, 0.02, 0.17, 0, 0.0, time_repeat, 0.1, 0.1)
    ShowSyncHudMsg(id, g_hudSync2, "[ XP: %d/%d ]^n[ Level: %d/%d ]^n[ Rank: %s ]",
                   g_ePlayerData[iTarget][XP], g_ePlayerData[iTarget][NextXP], g_ePlayerData[iTarget][Level], max_level, g_ePlayerData[iTarget][Rank]);

}*/
