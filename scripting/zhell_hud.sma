#include <amxmodx>
#include <fakemeta>

#include <zhell>
#include <zhell_const>
#include <crxranks>

#define PLUGIN_NAME "Zombie Hell: Hud"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

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

new  g_hudSync, g_hudSync1, g_hudSync2;

new g_level;
new g_boss_health, g_boss_speed;
new g_zombie_health, g_zombie_speed;

enum _:PlayerData
{
    Rank[32],
    XP,
    NextXP,
    Level
}
new g_ePlayerData[33][PlayerData], max_level;

new const Float:time_repeat = 5.0;
public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    new Ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
    set_pev(Ent,pev_classname,g_Classname)
    set_pev(Ent,pev_nextthink, 5.0)

    register_forward(FM_Think,"ForwardThink")


    g_hudSync = CreateHudSyncObj();
    g_hudSync1 = CreateHudSyncObj();
    g_hudSync2 = CreateHudSyncObj();

    max_level = crxranks_get_max_levels();

    zhell_round_start();
}
public client_putinserver(id) {
    if (!is_user_bot(id)) {
        set_task(time_repeat, "showHud", id, _, _, "b");
    }
}
public client_disconnected(id) {
    remove_task(id)
}

public zhell_spawn_human(id) {
    g_ePlayerData[id][XP] = crxranks_get_user_xp(id);
    g_ePlayerData[id][NextXP] = crxranks_get_user_next_xp(id);
    g_ePlayerData[id][Level] = crxranks_get_user_level(id);
    crxranks_get_user_rank(id, g_ePlayerData[id][Rank], charsmax(g_ePlayerData[][Rank]));
}
public zhell_round_start() {

    g_level = zhell_get_level();
    g_boss_health = zhell_get_boss_health();
    g_boss_speed = zhell_get_boss_speed();
    g_zombie_health = zhell_get_zombie_health();
    g_zombie_speed = zhell_get_zombie_speed();

}
public zhell_last_zombie_post(id) {
    new name[33];
    get_user_name(id, name, charsmax(name));

    set_hudmessage(0, 255, 100, -1.0, 0.30, 0, 0.0, 6.0, 0.1, 0.2, -1);
    ShowSyncHudMsg(0, g_hudSync1, "Xuất hiện BOSS [%s]", name);
}
public showHud(id)
{

    DisplayHUDRank(id);
    DisplayHUDLevel(id);

}



public crxranks_user_receive_xp(id, xp) {

    static bool:bPositive;
    bPositive = xp >= 0;

    if(bPositive) {
        set_dhudmessage(0, 255, random(256), -1.0, -1.0, 0, 0.0, 10.0);
    }
    else {
        set_dhudmessage(255, 0, random(256), -1.0, -1.0, 0, 0.0, 10.0);
    }

    show_dhudmessage(id, "%d XP", xp);
}
public DisplayHUDLevel(id) {
    set_hudmessage(id, 255, 0, -1.0, 0.0, 0, 0.0, time_repeat,  0.0, 0.2, -1);
    ShowSyncHudMsg(id, g_hudSync, "Ngày %d: - %s^nBOSS [HP: %d - SPEED: %.1f]^nZombie [HP: %d - SPEED: %.1f]",
                                    g_level, g_info[g_level - 1], g_boss_health, g_boss_speed, g_zombie_health, g_zombie_speed);
}
public DisplayHUDRank(id) {
    static iTarget;
    iTarget = id;

    if(!is_user_alive(id)) {
        iTarget = pev(id, pev_iuser2);

    }

    if(!iTarget) {
        return
    }

    set_hudmessage(106, -1, 208, 0.02, 0.17, 0, 0.0, time_repeat, 0.1, 0.1)
    ShowSyncHudMsg(id, g_hudSync2, "[ XP: %d/%d ]^n[ Level: %d/%d ]^n[ Rank: %s ]",
                   g_ePlayerData[iTarget][XP], g_ePlayerData[iTarget][NextXP], g_ePlayerData[iTarget][Level], max_level, g_ePlayerData[iTarget][Rank]);

}
public crxranks_user_xp_updated(id, xp) {
    g_ePlayerData[id][XP] = xp;
    g_ePlayerData[id][NextXP] = crxranks_get_user_next_xp(id);
}
public crxranks_user_level_updated(id, level) {

    g_ePlayerData[id][Level] = level;
    crxranks_get_user_rank(id, g_ePlayerData[id][Rank], charsmax(g_ePlayerData[][Rank]));
}
