#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#include <cs_ham_bots_api>

#include <zhell_const>


#define VERSION 		"3.0"

new const HEALTH_BAR_MODEL[ ] = "sprites/health.spr";

new g_playerBar[ 33 ], g_isAlive, g_isBot, g_playerMaxHealth[ 33 ]
new g_maxPlayers

public plugin_init( ) {
	register_plugin( "Zombie Hell: Health Bar", VERSION, "Bboy Grun" );

	register_event( "DeathMsg", "evDeathMsg", "a" );
	register_event( "Health", "evHealth", "be" );

	RegisterHam( Ham_Spawn, "player", "fwHamSpawn", true );
	RegisterHamBots( Ham_Spawn, "fwHamSpawn", true);

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

public fwAddToFullPack( es, e, ent, host, host_flags, player, p_set ) {
	if( !player && !Get_BitVar(g_isBot, host) ) {
		new user;

		for( user = g_maxPlayers; user > 0; -- user ) {
			if( g_playerBar[ user ] == ent  ) {
				if( user != host && Get_BitVar(g_isAlive, user) && Get_BitVar(g_isBot, user )) {
					new Float: playerOrigin[ 3 ];
					pev( user, pev_origin, playerOrigin );

					playerOrigin[ 2 ] += 30.0;

					set_es( es, ES_Origin, playerOrigin );
				}
				else {
					set_es( es, ES_Effects, EF_NODRAW );
				}

				break;
			}
		}
	}
}

public fwHamSpawn( id ) {
	if(is_user_alive( id ) ) {
		new Float: playerOrigin[ 3 ];
		pev( id, pev_origin, playerOrigin );

		Set_BitVar(g_isAlive, id);

		engfunc( EngFunc_SetOrigin, g_playerBar[ id ], playerOrigin );
		evHealth( id );
	}
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
