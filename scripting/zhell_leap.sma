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

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    register_forward(FM_TraceLine, "Forward_TraceLine_Post", 1);

    cvar_LeapCooldown = register_cvar("zhell_leap_cooldown", "10.0");
    cvar_LeapForce = register_cvar("zhell_leap_force", "500");
    cvar_LeapHeight = register_cvar("zhell_leap_height", "300");
}

public plugin_precache() {
    precache_sound(g_sound_leap);
}
public Forward_TraceLine_Post(Float:start[3], Float:end[3], noMonsters, id, trace)
{
    if(!is_user_alive(id) ) return FMRES_IGNORED;
    if(!zhell_is_zombie(id)) return FMRES_IGNORED;

    static Float: gameTime ; gameTime = get_gametime();
    static Float: leapCooldown ; leapCooldown = get_pcvar_float(cvar_LeapCooldown);
    static Float: leapMax ; leapMax = get_pcvar_float(cvar_LeapForce);
    static Float: leapMin ; leapMin = get_pcvar_float(cvar_LeapHeight);


    static distance;
    static target; target = get_tr2(trace, TR_pHit);

    leapMax *= 2.0;
    leapMin *= 1.5;
    if (gameTime - leapCooldown > g_LastLeap[id]) {
        if(is_user_alive(target) && !zhell_is_zombie(target)) {

            static chance ; chance = random_num(1, 100);
            distance = get_entity_distance(id, target);
            if (leapMin < distance && distance < leapMax && chance <= 15) {
                clcmd_leap(id);
                g_LastLeap[id] = gameTime;
            }
        }
    }

    return FMRES_IGNORED;
}
public clcmd_leap(id)
{
    new Float: velocity[3];
    new Float: lheight, lforce;
    lforce = get_pcvar_num(cvar_LeapForce);
    lheight = get_pcvar_float(cvar_LeapHeight);

    velocity_by_aim(id, lforce, velocity);
    velocity[2] = lheight;
    entity_set_vector(id, EV_VEC_velocity, velocity);
    emit_sound(id, CHAN_VOICE, g_sound_leap, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
