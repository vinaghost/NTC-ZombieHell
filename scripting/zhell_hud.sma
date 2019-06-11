#include <amxmodx>


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

new  g_hudSync, g_hudSync1;
public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    g_hudSync = CreateHudSyncObj();
    g_hudSync1 = CreateHudSyncObj();
}

public zhell_round_start() {
    set_hudmessage(0, 255, 0, -1.0, 0.0, 0, 0.0, 300.0, 0.0, 0.2, -1);
    ShowSyncHudMsg(0, g_hudSync, "Ngày %d: - %s^nBOSS [HP: %d - SPEED: %.1f]^nZombie [HP: %d - SPEED: %.1f])",
                                   zhell_get_level(), g_info[zhell_get_level() - 1],
                                   zhell_get_boss_health(), zhell_get_boss_speed(),
                                   zhell_get_zombie_health(), zhell_get_zombie_speed());


}
public zhell_last_zombie(id) {
    new name[33];
    get_user_name(id, name, charsmax(name));

    set_hudmessage(0, 255, 100, -1.0, 0.30, 0, 6.0, 6.0, 0.1, 0.2, -1);
    ShowSyncHudMsg(0, g_hudSync1, "Xuất hiện BOSS [%s]", name);
}
