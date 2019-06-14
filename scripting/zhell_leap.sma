#include <amxmodx>
#include <fakemeta>
#include <engine>

#include <zhell>
#include <zhell_const>


#define PLUGIN_NAME "Zombie Hell: Leap ability"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "VINAGHOST"

new Float:g_LastLeap[33];

new const g_sound_leap[] = "zombieHell/leap.wav";

new cvar_LeapCooldown, cvar_LeapForce, cvar_LeapHeight;

new g_zombie_alive, g_human_alive;

new Float: g_leapCooldown;
new Float: g_leapMax;
new Float: g_leapMin;


public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    register_forward(FM_TraceLine, "Forward_TraceLine_Post", 1);

    cvar_LeapCooldown = register_cvar("zhell_leap_cooldown", "10.0");
    cvar_LeapForce = register_cvar("zhell_leap_force", "500.0");
    cvar_LeapHeight = register_cvar("zhell_leap_height", "800.0");
}

public plugin_precache() {
    precache_sound(g_sound_leap);
}


public zhell_round_start() {
    g_zombie_alive = 0;
    g_human_alive = 0;

    g_leapCooldown = get_pcvar_float(cvar_LeapCooldown);

    g_leapMax = get_pcvar_float(cvar_LeapForce);
    g_leapMin = get_pcvar_float(cvar_LeapHeight);

}
public client_authorized(id) {
    UnSet_BitVar(g_zombie_alive,id);
    UnSet_BitVar(g_human_alive,id);
}
public zhell_spawn_zombie(id) {
    Set_BitVar(g_zombie_alive, id);
}
public zhell_spawn_human(id) {
    Set_BitVar(g_human_alive, id);
}
public zhell_killed_human(id) {
    UnSet_BitVar(g_human_alive,id);
}
public zhell_killed_zombie(id) {
    UnSet_BitVar(g_zombie_alive,id);
}

public Forward_TraceLine_Post(Float:start[3], Float:end[3], noMonsters, id, trace) {
    if( !is_user_alive(id) ) return FMRES_IGNORED;
    if( !Get_BitVar(g_zombie_alive, id) ) return FMRES_IGNORED;

    static Float: gameTime ; gameTime = get_gametime();


    if (gameTime - g_leapCooldown > g_LastLeap[id]) {

        static distance;
        static target; target = get_tr2(trace, TR_pHit);

        static Float:leapMin; leapMin = g_leapMin;
        static Float:leapMax; leapMax = g_leapMax;
        leapMax *= 2.0;
        leapMin *= 1.5;

        if(Get_BitVar(g_human_alive, target)) {

            static chance ; chance = random_num(1, 100);
            distance = get_entity_distance(id, target);
            if (leapMin < distance && distance < leapMax && chance <= 30) {
                clcmd_leap(id);
                g_LastLeap[id] = gameTime;
            }
        }
    }

    return FMRES_IGNORED;
}
public clcmd_leap(id) {
    static Float: velocity[3];
    static Float: lheight; lheight = g_leapMin;
    static lforce; lforce = floatround(g_leapMax);


    velocity_by_aim(id, lforce, velocity);

    velocity[2] = lheight;

    entity_set_vector(id, EV_VEC_velocity, velocity);

    emit_sound(id, CHAN_VOICE, g_sound_leap, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
