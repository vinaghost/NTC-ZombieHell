#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <fun>

#define PLUGIN_NAME "Zombie Hell: TEST"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "VINAGHOST"


public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    register_clcmd("say /respawn", "reSpawn");
    register_clcmd("say /noclip", "noClip");
    register_clcmd("say /origin", "origin");
    register_clcmd("say /godmode", "godmode");
    register_clcmd("say /money", "money");

}

// -2043 3491 68

public money(id) {
    cs_set_user_money(id, 70000);
}
public reSpawn(id) {
    ExecuteHamB(Ham_CS_RoundRespawn, id);
}

public noClip(id) {
    set_user_noclip(id, !get_user_noclip(id))
}

public godmode(id) {
    client_print(id, print_chat, "%d", get_user_godmode(id));
}

public origin(id) {
    new origi[3];
    get_user_origin(id, origi);
    client_print(id, print_chat, "%d %d %d", origi[0], origi[1], origi[2]);
}
