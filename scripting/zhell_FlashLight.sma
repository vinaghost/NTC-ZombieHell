#include <amxmodx>
#include <amxmisc>
#include <engine>

#include <zhell>
#include <zhell_const>


#define PLUGIN "Zombie Hell: Custom Flashlight"
#define AUTHOR "ConnorMcLeod"
#define VERSION "0.5.4"

/* **************************** CUSTOMIZATION AREA ******************************** */

new const SOUND_FLASHLIGHT_ON[] = "items/flashlight1.wav"
new const SOUND_FLASHLIGHT_OFF[] = "items/flashlight1.wav"

#define LIFE	1	// try 2 if light is flickering

/* ******************************************************************************** */

new g_bFlashLight;

new g_iRadius = 9
new g_iAttenuation = 5
new g_iDistanceMax = 2000

public plugin_precache()
{
	precache_sound(SOUND_FLASHLIGHT_ON)
	precache_sound(SOUND_FLASHLIGHT_OFF)
}

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )

	register_impulse(100, "Impulse_100")

	register_event("HLTV", "Event_HLTV_newround", "a", "1=0", "2=0")
	register_event("DeathMsg", "Event_DeathMsg", "a")

}


public client_putinserver(id) {
	reset(id)
}

public Event_HLTV_newround() {
	g_bFlashLight = 0;
}

public Event_DeathMsg() {
	reset(read_data(2))
}

reset(id) {
    UnSet_BitVar(g_bFlashLight, id);
}

public Impulse_100( id )
{
	if(is_user_alive(id)) {
		if( Get_BitVar(g_bFlashLight, id) ) {
				FlashlightTurnOff(id)
		}
		else {
			FlashlightTurnOn(id)
		}
		return PLUGIN_HANDLED_MAIN
	}
	return PLUGIN_CONTINUE
}

public client_PreThink(id)
{
	if(Get_BitVar(g_bFlashLight,id)) {
		Make_FlashLight(id)
	}
}

Make_FlashLight(id) {

	static iOrigin[3], iAim[3], iDist
	get_user_origin(id, iOrigin, 1)
	get_user_origin(id, iAim, 3)

	iDist = get_distance(iOrigin, iAim)

	if( iDist > g_iDistanceMax )
		return

	static iDecay, iAttn

	iDecay = iDist * 255 / g_iDistanceMax
	iAttn = 256 + iDecay * g_iAttenuation // barney/dontaskme

	//message_begin(MSG_BROADCAST, SVC_TEMPENTITY)

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)

	write_byte( TE_DLIGHT )
	write_coord( iAim[0] )
	write_coord( iAim[1] )
	write_coord( iAim[2] )
	write_byte( g_iRadius )
	write_byte( (0<<8) / iAttn )
	write_byte( (122<<8) / iAttn )
	write_byte( (0<<8) / iAttn )
	write_byte( LIFE )
	write_byte( iDecay )
	message_end()
}

FlashlightTurnOff(id) {
	emit_sound(id, CHAN_WEAPON, SOUND_FLASHLIGHT_OFF, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	UnSet_BitVar(g_bFlashLight,id)
}

FlashlightTurnOn(id)
{
	emit_sound(id, CHAN_WEAPON, SOUND_FLASHLIGHT_ON, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	Set_BitVar(g_bFlashLight,id);
}
