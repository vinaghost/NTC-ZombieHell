/*
 * SIMPLE POINTS API
 * by xPaw
 *
 * Website: https://xpaw.me/
 */

#include < amxmodx >

#include <zhell>
#include <zhell_const>

new g_bConnected;

public plugin_init( ) {
    register_event( "DeathMsg", "EventDeathMsg", "a" );
}

public client_disconnected( id ) {
    UnSet_BitVar(g_bConnected, id);
}
public client_connect(id) {
    UnSet_BitVar(g_bConnected, id);
}
public zhell_client_connected(  id ) {
    Set_BitVar(g_bConnected, id);
}

public EventDeathMsg( ) {
    new iKiller = read_data( 1 ),
        iVictim = read_data( 2 );

    if( !Get_BitVar(g_bConnected, iKiller) || iKiller == iVictim ) return;

    new headShot = read_data(3)

    new point = 10;

    if( headShot ) point += 5;

    if( iVictim == zhell_get_boss() ) point += 10;


    zhell_point_add( iKiller,  point );
}
