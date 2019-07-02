#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

#include <cs_ham_bots_api>

#include <zhell>
#include <zhell_const>


#define PLUGIN_NAME "Zombie Hell: Leap ability"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "VINAGHOST"

new Float:g_LastLeap[33];

new const g_sound_leap[] = "zombieHell/leap.wav";

new cvar_LeapCooldown, cvar_LeapForce, cvar_LeapHeight;

new Float: g_leapCooldown;
new Float: g_leapForce;
new Float: g_leapHeight;
new lforce;

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	register_forward(FM_TraceLine, "Forward_TraceLine_Post", 1);

	RegisterHam(Ham_TakeDamage, "player", "fwHamPlayerTakeDamagePre", 0);
	RegisterHamBots(Ham_TakeDamage, "fwHamPlayerTakeDamagePre", 1);

	cvar_LeapCooldown = register_cvar("zhell_leap_cooldown", "10.0");
	cvar_LeapForce = register_cvar("zhell_leap_force", "500.0");
	cvar_LeapHeight = register_cvar("zhell_leap_height", "800.0");
}

public plugin_precache() {
	precache_sound(g_sound_leap);
}


public zhell_round_start() {

	g_leapCooldown = get_pcvar_float(cvar_LeapCooldown);

	g_leapForce = get_pcvar_float(cvar_LeapForce);
	g_leapHeight = get_pcvar_float(cvar_LeapHeight);

	lforce = floatround(g_leapForce)

}
public fwHamPlayerTakeDamagePre(victim, inflictor, attacker, Float:damage, bits) {
	if( bits == DMG_FALL && zhell_is_zombie(victim) ) {

		SetHamParamFloat(4, 0.0);
		return HAM_HANDLED;
	}

	return HAM_IGNORED;
}
public Forward_TraceLine_Post(Float:start[3], Float:end[3], noMonsters, id, trace) {
	if( !is_user_alive(id) ) return FMRES_IGNORED;
	if( !zhell_is_zombie(id) ) return FMRES_IGNORED;

	static Float: gameTime ; gameTime = get_gametime();


	if (gameTime - g_leapCooldown > g_LastLeap[id]) {
		if( random_num(0, 1) ) {
			static target; target = get_tr2(trace, TR_pHit);

			if(!zhell_is_zombie(target)) {

				clcmd_leap(id);
				g_LastLeap[id] = gameTime;

			}
		}
	}

	return FMRES_IGNORED;
}
public clcmd_leap(id) {
	static Float: velocity[3];

	velocity_by_aim(id, lforce, velocity);

	velocity[2] = g_leapHeight;

	entity_set_vector(id, EV_VEC_velocity, velocity);

	emit_sound(id, CHAN_VOICE, g_sound_leap, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
