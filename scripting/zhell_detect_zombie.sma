#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <xs>

#include <zhell>
#include <zhell_const>

#define PLUGIN_NAME "Zombie Hell: Detect Zombie"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

new g_alive_zombie, g_alive_human, g_last;
new sprite_playerheat
new Float:g_fDelay[33];
public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_forward(FM_PlayerPreThink,"FW_PlayerPreThink");
}
public plugin_precache()
{
	sprite_playerheat = precache_model("sprites/poison.spr")

}
public zhell_round_start() {
	g_last = zhell_get_zombie_total();
}
public zhell_spawn_zombie(id) {
	Set_BitVar(g_alive_zombie, id);
}

public zhell_killed_zombie(id) {
	UnSet_BitVar(g_alive_zombie, id);

	g_last = zhell_get_zombie_last();
}

public zhell_spawn_human(id) {
	Set_BitVar(g_alive_human, id);
}

public zhell_killed_human(id) {
	UnSet_BitVar(g_alive_human, id);
}
public client_putinserver(id) {
	UnSet_BitVar(g_alive_zombie, id);
	UnSet_BitVar(g_alive_human, id);
	g_fDelay[id] = 0.0;
}
public FW_PlayerPreThink(id) // THANKS TO CHEAPSUIT FOR THERMAL CODE
{
	if(!Get_BitVar(g_alive_human ,id) || Get_BitVar(g_alive_zombie, id)) return PLUGIN_CONTINUE;

	if( g_last > 10 ) return PLUGIN_CONTINUE


	if(g_fDelay[id] + 0.5 > get_gametime()) return PLUGIN_CONTINUE;


	g_fDelay[id] = get_gametime()

	new Float:fMyOrigin[3]
	entity_get_vector(id, EV_VEC_origin, fMyOrigin)

	static Players[32], iNum
	get_players(Players, iNum, "ad");


	for(new i = 0; i < iNum; ++i)
	{
		if(id != Players[i]) {
			new target = Players[i]

			new Float:fTargetOrigin[3]
			entity_get_vector(target, EV_VEC_origin, fTargetOrigin)

			new Float:fMiddle[3], Float:fHitPoint[3]
			xs_vec_sub(fTargetOrigin, fMyOrigin, fMiddle)
			trace_line(-1, fMyOrigin, fTargetOrigin, fHitPoint)

			new Float:fWallOffset[3], Float:fDistanceToWall
			fDistanceToWall = vector_distance(fMyOrigin, fHitPoint) - 10.0
			normalize(fMiddle, fWallOffset, fDistanceToWall)

			new Float:fSpriteOffset[3]
			xs_vec_add(fWallOffset, fMyOrigin, fSpriteOffset)
			new Float:fScale, Float:fDistanceToTarget = vector_distance(fMyOrigin, fTargetOrigin)
			if(fDistanceToWall > 100.0)
				fScale = 8.0 * (fDistanceToWall / fDistanceToTarget)
			else
				fScale = 2.0

			te_sprite(id, fSpriteOffset, sprite_playerheat, floatround(fScale), 125)
		}
	}
	return PLUGIN_CONTINUE
}

stock te_sprite(id, Float:origin[3], sprite, scale, brightness)
{
	message_begin(MSG_ONE, SVC_TEMPENTITY, _, id)
	write_byte(TE_SPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(sprite)
	write_byte(scale)
	write_byte(brightness)
	message_end()
}
stock normalize(Float:fIn[3], Float:fOut[3], Float:fMul)
{
	new Float:fLen = xs_vec_len(fIn)
	xs_vec_copy(fIn, fOut)

	fOut[0] /= fLen, fOut[1] /= fLen, fOut[2] /= fLen
	fOut[0] *= fMul, fOut[1] *= fMul, fOut[2] *= fMul
}
