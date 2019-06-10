#include <amxmodx>
#include <fakemeta>

#define PLUGIN_NAME "Zombie Hell: Level Zombie"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

new const objective_ents[][] = {
    "func_bomb_target",
    "info_bomb_target",
    "info_vip_start",
    "func_vip_safetyzone",
    "func_escapezone",
    "hostage_entity",
    "monster_scientist",
    "func_hostage_rescue",
    "info_hostage_rescue"
}

new g_fwSpawn
new g_fwPrecacheSound

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    unregister_forward(FM_Spawn, g_fwSpawn)
    unregister_forward(FM_PrecacheSound, g_fwPrecacheSound)

    register_forward(FM_EmitSound, "fw_EmitSound")
    register_message(get_user_msgid("Scenario"), "message_scenario")
    register_message(get_user_msgid("HostagePos"), "message_hostagepos")
}

public plugin_precache() {
    new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"))
    if (pev_valid(ent)) {
        engfunc(EngFunc_SetOrigin, ent, Float:{8192.0,8192.0,8192.0})
        dllfunc(DLLFunc_Spawn, ent)
    }

    g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")

    g_fwPrecacheSound = register_forward(FM_PrecacheSound, "fw_PrecacheSound")


    disable_buyzone();
}

// Entity Spawn Forward
public fw_Spawn(entity) {
    // Invalid entity
    if (!pev_valid(entity))
        return FMRES_IGNORED;

    // Get classname
    new classname[32]
    pev(entity, pev_classname, classname, charsmax(classname))

    new index
    for (index = 0; index < 9; index++) {
        if (equal(classname, objective_ents[index])) {
            engfunc(EngFunc_RemoveEntity, entity)
            return FMRES_SUPERCEDE;
        }
    }

    return FMRES_IGNORED;
}

public fw_PrecacheSound(const sound[]) {
    if (equal(sound, "hostage", 7))
        return FMRES_SUPERCEDE;

    return FMRES_IGNORED;
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch) {
    if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
        return FMRES_SUPERCEDE;

    return FMRES_IGNORED;
}

public message_scenario() {
    if (get_msg_args() > 1) {
        new sprite[8]
        get_msg_arg_string(2, sprite, charsmax(sprite))

        if (equal(sprite, "hostage"))
            return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}

public message_hostagepos() {
    return PLUGIN_HANDLED;
}
public disable_buyzone() {
    new ent = find_ent_by_class(-1,"info_map_parameters");

    // if we couldn't find one, make our own
    if(!ent)
        ent = create_entity("info_map_parameters");

    // disable buying for TS team
    DispatchKeyValue(ent,"buying","1");
    DispatchSpawn(ent);
}
