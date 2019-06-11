#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#include <cs_ham_bots_api>

#include <zhell>
#include <zhell_const>


#define VERSION 		"3.0"

new const HEALTH_BAR_MODEL[ ] = "sprites/health.spr";

new g_playerBar[ 33 ], g_isAlive, g_isBot, g_playerMaxHealth[ 33 ]
new g_maxPlayers

public plugin_init( ) {
	register_plugin( "Zombie Hell: Health Bar", VERSION, "Bboy Grun" );

	register_event( "DeathMsg", "evDeathMsg", "a" );
	register_event( "Health", "evHealth", "be" );

	register_forward(FM_AddToFullPack, "fwAddToFullPack", 1)

	g_maxPlayers = get_maxplayers( );

	new playerBar, allocString = engfunc( EngFunc_AllocString, "env_sprite" );

	for( new id = 1; id <= g_maxPlayers; id ++ ) {
		g_playerBar[ id ] = engfunc( EngFunc_CreateNamedEntity, allocString );

		playerBar = g_playerBar[ id ];

		if( pev_valid( playerBar ) ) {
			set_pev( playerBar, pev_scale, 0.1 );
			engfunc( EngFunc_SetModel, playerBar, HEALTH_BAR_MODEL );
		}
	}
}

public plugin_precache( ) {
	precache_model( HEALTH_BAR_MODEL );
}

public client_putinserver( id ) {
	if( is_user_bot(id) ) {
		Set_BitVar(g_isBot, id);
	}
	UnSet_BitVar(g_isAlive, id);

	g_playerMaxHealth[ id ] = 0;

}

public client_disconnected( id )
{
	if( is_user_bot(id) ) {
		UnSet_BitVar(g_isBot, id);
	}

	UnSet_BitVar(g_isAlive, id);

	g_playerMaxHealth[ id ] = 0;
}

public fwAddToFullPack( es, e, user, host, host_flags, player, p_set ) {
	if(!player || !Get_BitVar(g_isAlive, user) || !Get_BitVar(g_isBot, user))
		return FMRES_IGNORED

	new Float:PlayerOrigin[3]
	pev(user, pev_origin, PlayerOrigin)
	PlayerOrigin[2] += 15.0
	engfunc(EngFunc_SetOrigin, g_playerBar[user], PlayerOrigin)
	set_pev(g_playerBar[user], pev_effects, pev(g_playerBar[user], pev_effects) & ~EF_NODRAW)
	return FMRES_HANDLED
}

public zhell_spawn_zombie( id ) {
	new Float: playerOrigin[ 3 ];
	pev( id, pev_origin, playerOrigin );

	Set_BitVar(g_isAlive, id);

	engfunc( EngFunc_SetOrigin, g_playerBar[ id ], playerOrigin );
	evHealth( id );
}

public zhell_last_zombie(id) {
	evHealth(id);
}

public evDeathMsg( ) {
	new id = read_data( 2 );

	UnSet_BitVar(g_isAlive, id);
	g_playerMaxHealth[ id ] = 0;
}

public evHealth( id ) {
	new hp = get_user_health( id );

	if( g_playerMaxHealth[ id ] < hp ) {
		g_playerMaxHealth[ id ] = hp;
		set_pev( g_playerBar[ id ], pev_frame, 99.0 );
	}
	else  {
		set_pev( g_playerBar[ id ], pev_frame, 0.0 + ( ( ( hp - 1 ) * 100 ) / g_playerMaxHealth[ id ] ) );
	}
}
