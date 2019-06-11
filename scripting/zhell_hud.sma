#include <amxmodx>
#include <fakemeta>

#include <zhell>
#include <zhell_const>


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

new  g_hudSync, g_hudSync1;

new g_level;
new g_boss_health, g_boss_speed;
new g_zombie_health, g_zombie_speed;


public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    new Ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
    set_pev(Ent,pev_classname,g_Classname)
    set_pev(Ent,pev_nextthink,5.0)

    register_forward(FM_Think,"ForwardThink")


    g_hudSync = CreateHudSyncObj();
    g_hudSync1 = CreateHudSyncObj();

    zhell_round_start();
}

public zhell_round_start() {

    g_level = zhell_get_level();
    g_boss_health = zhell_get_boss_health();
    g_boss_speed = zhell_get_boss_speed();
    g_zombie_health = zhell_get_zombie_health();
    g_zombie_speed = zhell_get_zombie_speed();

}
public ForwardThink(Ent)
{
    static Classname[33]
    pev(Ent,pev_classname,Classname,32);

    if(!equal(Classname,g_Classname)) return FMRES_IGNORED;
    set_hudmessage(0, 255, 0, -1.0, 0.0, 0, 0.0, 0.5, 0.0, 0.2, -1);
    ShowSyncHudMsg(0, g_hudSync, "Ngày %d: - %s^nBOSS [HP: %d - SPEED: %.1f]^nZombie [HP: %d - SPEED: %.1f]",
                                    g_level, g_info[g_level - 1], g_boss_health, g_boss_speed, g_zombie_health, g_zombie_speed);

    set_pev(Ent,pev_nextthink, 0.5);

    return FMRES_IGNORED
}

public zhell_last_zombie_post(id) {
    new name[33];
    get_user_name(id, name, charsmax(name));

    set_hudmessage(0, 255, 100, -1.0, 0.30, 0, 6.0, 6.0, 0.1, 0.2, -1);
    ShowSyncHudMsg(0, g_hudSync1, "Xuất hiện BOSS [%s]", name);
}
