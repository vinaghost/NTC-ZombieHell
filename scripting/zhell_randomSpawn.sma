#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#include <zhell>
#include <zhell_const>

#define PLUGIN_NAME "Zombie Hell: Random spawn"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "VINAGHOST"

new g_total_spawn = 0;

new Float:g_spawn_vec[60][3];
new Float:g_spawn_angle[60][3];
new Float:g_spawn_v_angle[60][3];

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

}
public plugin_cfg() {
    csdm_respawn();
}

public zhell_spawn_zombie(id) {

    set_task(0.1, "csdm_player_spawn", id);

}
csdm_respawn()
{
    new map[32], config[32],  mapfile[64]
    get_mapname(map, 31)
    get_configsdir(config, 31)
    format(mapfile, 63, "%s\csdm\%s.spawns.cfg", config, map)
    g_total_spawn = 0
    if (file_exists(mapfile))
    {
        new new_data[124], len
        new line = 0
        new pos[12][8]
        while (g_total_spawn < 60 && (line = read_file(mapfile, line, new_data, charsmax(new_data), len)) != 0)
        {
            if (strlen(new_data) < 2 || new_data[0] == '[')
                continue;

            parse(new_data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7)
            g_spawn_vec[g_total_spawn][0] = str_to_float(pos[1])
            g_spawn_vec[g_total_spawn][1] = str_to_float(pos[2])
            g_spawn_vec[g_total_spawn][2] = str_to_float(pos[3])
            g_spawn_angle[g_total_spawn][0] = str_to_float(pos[4])
            g_spawn_angle[g_total_spawn][1] = str_to_float(pos[5])
            g_spawn_angle[g_total_spawn][2] = str_to_float(pos[6])
            g_spawn_v_angle[g_total_spawn][0] = str_to_float(pos[8])
            g_spawn_v_angle[g_total_spawn][1] = str_to_float(pos[9])
            g_spawn_v_angle[g_total_spawn][2] = str_to_float(pos[10])
            g_total_spawn++
        }
    }
    return 1;
}

public csdm_player_spawn(id)
{
    if (!is_user_alive(id))
        return;

    new list[60]
    new num = 0
    new final = -1
    new total = 0
    new players[32], n, x = 0
    new Float:loc[32][3], locnum
    get_players(players, num)
    for (new i = 0; i < num; i++)
    {
        if (is_user_alive(players[i]) && players[i] != id)
        {
            pev(players[i], pev_origin, loc[locnum])
            locnum++
        }
    }

    num = 0
    while (num <= g_total_spawn)
    {
        if (num == g_total_spawn)
            break;

        n = random_num(0, g_total_spawn-1)
        if (!list[n])
        {
            list[n] = 1
            num++
        }
        else
        {
            total++
            if (total > 100)
                break;
            continue;
        }

        if (locnum < 1)
        {
            final = n
            break;
        }

        final = n
        for (x = 0; x < locnum; x++)
        {
            new Float:distance = get_distance_f(g_spawn_vec[n], loc[x])
            if (distance < 250.0)
            {
                final = -1
                break;
            }
        }
        if (final != -1)
            break;
    }

    if (final != -1)
    {
        new Float:mins[3], Float:maxs[3]
        pev(id, pev_mins, mins)
        pev(id, pev_maxs, maxs)
        engfunc(EngFunc_SetSize, id, mins, maxs)
        engfunc(EngFunc_SetOrigin, id, g_spawn_vec[final])
        set_pev(id, pev_fixangle, 1)
        set_pev(id, pev_angles, g_spawn_angle[final])
        set_pev(id, pev_v_angle, g_spawn_v_angle[final])
        set_pev(id, pev_fixangle, 1)
    }
}
