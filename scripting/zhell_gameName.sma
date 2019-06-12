#include <amxmodx>
#include <fakemeta>

new const g_ModName[] = "NTC - Zombie hell";

#define PLUGIN_NAME "Zombie Hell: Gamename changer"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    register_forward(FM_GetGameDescription, "fw_GetGameDescription");
}

public fw_GetGameDescription()
{
    forward_return(FMV_STRING, g_ModName);

    return FMRES_SUPERCEDE;
}
