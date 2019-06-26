#include < amxmodx >
#include < sqlx >
#include < cstrike >

#include <zhell>
#include <zhell_const>


#pragma semicolon 1

#define IsPlayer(%1) ( 1 <= %1 <= g_iMaxPlayers )
#define IsUserAuthorized(%1) ( g_iPlayerData[ %1 ][ DATA_STATUS ] )
#define CallForwardReward(%1,%2) new iReturn; ExecuteForward( g_iFwdReward, iReturn, %1, %2 )

enum _:PLR_DATA
{
    DATA_INDEX,
    DATA_POINTS,
    DATA_STATUS
};
new g_iPlayerData[ 33 ][ PLR_DATA ];


new g_iMaxPlayers;
new g_iFwdReward;

new Handle:g_hSqlTuple;

public plugin_init( )
{
    new const VERSION[ ] = "1.0 Alpha";

    register_plugin( "Zombie Hell: Simple Points", VERSION, "xPaw" );

    g_iFwdReward = CreateMultiForward( "zhell_point_reward", ET_IGNORE, FP_CELL, FP_CELL );
    g_iMaxPlayers   = get_maxplayers( );

    register_clcmd("say /point", "showPoint");

    set_task(2.0, "sql");
}
public sql() {
    g_hSqlTuple     = SQL_MakeStdTuple();

    new szQuery[ 300 ];
    formatex( szQuery, 299, "SHOW COLUMNS FROM `%s` LIKE 'point'", g_szSqlTable  );

    SQL_ThreadQuery( g_hSqlTuple, "HandleCreatColumn", szQuery );
}
public showPoint(id) {
    client_print(id, print_chat, "ID: %d Point: %d", g_iPlayerData[id][DATA_INDEX],  g_iPlayerData[id][DATA_POINTS]);
}
public plugin_natives( )
{
    register_native( "zhell_point_add", "NativeAddPoints" );
    register_native( "zhell_point_set", "NativeSetPoints" );
    register_native( "zhell_point_get", "NativeGetPoints" );
}

public plugin_end( )
{
    SQL_FreeHandle( g_hSqlTuple );
    DestroyForward( g_iFwdReward );
}
public zhell_client_connected(id) {
    g_iPlayerData[ id ][ DATA_INDEX  ] = zhell_get_index(id);
    g_iPlayerData[ id ][ DATA_POINTS ] = 0;
    g_iPlayerData[ id ][ DATA_STATUS ] = 1;

    UserHasBeenAuthorized(id);
}
// Client Related
// ====================================
public client_disconnected( id )
{
    g_iPlayerData[ id ][ DATA_INDEX  ] = 0;
    g_iPlayerData[ id ][ DATA_POINTS ] = 0;
    g_iPlayerData[ id ][ DATA_STATUS ] = 0;
}

// Natives
// ====================================
public NativeAddPoints( const iPlugin, const iParams ) {
    if( iParams != 2 )
    {
        log_error( AMX_ERR_PARAMS, "Wrong parameters" );
        return false;
    }

    new iPlayer = get_param( 1 );

    if( !IsPlayer( iPlayer ) )
    {
        log_error( AMX_ERR_PARAMS, "Not a player (%i)", iPlayer );
        return false;
    }
    else if( !IsUserAuthorized( iPlayer ) || !g_iPlayerData[ iPlayer ][ DATA_INDEX ] )
    {
        log_error( AMX_ERR_PARAMS, "Player is not authorized (%i)", iPlayer );
        return false;
    }

    new iPoints = get_param( 2 );

    if( !iPoints )
    {
        log_error( AMX_ERR_PARAMS, "Tried to add zero points" );
        return false;
    }

    g_iPlayerData[ iPlayer ][ DATA_POINTS ] += iPoints;
    cs_set_user_money(iPlayer, iPoints);
    CallForwardReward(iPlayer, iPoints);

    if( g_iPlayerData[ iPlayer ][ DATA_POINTS ] < 0 )
    {
        g_iPlayerData[ iPlayer ][ DATA_POINTS ] = 0;
    }

    new szQuery[ 128 ];
    formatex( szQuery, 127, "UPDATE `%s` SET `point` = `point` + '%i' WHERE `Id` = '%i'",
        g_szSqlTable, iPoints, g_iPlayerData[ iPlayer ][ DATA_INDEX ] );

    new iData[ 2 ];
    iData[ 0 ] = iPlayer;
    iData[ 1 ] = iPoints;

    SQL_ThreadQuery( g_hSqlTuple, "HandleNullRoute", szQuery, iData, 2 );

    return true;
}

public NativeSetPoints( const iPlugin, const iParams ) {
    if( iParams != 2 )
    {
        log_error( AMX_ERR_PARAMS, "Wrong parameters" );
        return false;
    }

    new iPlayer = get_param( 1 );

    if( !IsPlayer( iPlayer ) )
    {
        log_error( AMX_ERR_PARAMS, "Not a player (%i)", iPlayer );
        return false;
    }
    else if( !IsUserAuthorized( iPlayer ) || !g_iPlayerData[ iPlayer ][ DATA_INDEX ] )
    {
        log_error( AMX_ERR_PARAMS, "Player is not authorized (%i)", iPlayer );
        return false;
    }

    new iPoints = get_param( 2 );

    if( iPoints <= 0 )
    {
        log_error( AMX_ERR_PARAMS, "Tried to force points less than a zero (%i)", iPoints );
        return false;
    }

    g_iPlayerData[ iPlayer ][ DATA_POINTS ] = iPoints;
    cs_set_user_money(iPlayer, iPoints);


    new szQuery[ 128 ];
    formatex( szQuery, 127, "UPDATE `%s` SET `point` = '%i' WHERE `Id` = '%i'",
        g_szSqlTable, iPoints, g_iPlayerData[ iPlayer ][ DATA_INDEX ] );

    new iData[ 2 ];
    iData[ 0 ] = iPlayer;
    iData[ 1 ] = iPoints;

    SQL_ThreadQuery( g_hSqlTuple, "HandleNullRoute", szQuery, iData, 2 );

    return true;
}

public NativeGetPoints( const iPlugin, const iParams ) {
    if( iParams != 1 )
    {
        log_error( AMX_ERR_PARAMS, "Wrong parameters" );
        return 0;
    }

    new iPlayer = get_param( 1 );

    if( !IsPlayer( iPlayer ) )
    {
        log_error( AMX_ERR_PARAMS, "Not a player (%i)", iPlayer );
        return 0;
    }

    return g_iPlayerData[ iPlayer ][ DATA_POINTS ];
}

// SQL Related
// ====================================
UserHasBeenAuthorized( const id )
{
    new szName[ 32 ], szQuery[ 128 ];
    get_user_name( id, szName, 31 );
    formatex( szQuery, 127, "SELECT `point` FROM `%s` WHERE `Id` = '%d'", g_szSqlTable, g_iPlayerData[id][DATA_INDEX] );

    new iData[ 1 ];
    iData[ 0 ] = id;

    SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerConnect", szQuery, iData, 1 );
}

public HandleNullRoute( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime ) {
    if( SQL_IsFail( iFailState, iError, szError ) && iSize == 2 ) {
    }
}
public HandleCreatColumn( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime ) {
    if( SQL_IsFail( iFailState, iError, szError ) )
        return;

    if( !SQL_NumResults( hQuery ) ) {
        new szQuery[ 300 ];
        formatex( szQuery, 299, "ALTER TABLE %s ADD COLUMN point INT(6) NOT NULL DEFAULT '0' NOT NULL", g_szSqlTable  );

        SQL_ThreadQuery( g_hSqlTuple, "HandleNullRoute", szQuery);
    }
}

public HandlePlayerConnect( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime ) {
    if( SQL_IsFail( iFailState, iError, szError ) )
        return;

    new id = iData[ 0 ];

    if( !IsUserAuthorized( id ) )
        return;

    if( SQL_NumResults( hQuery )  > -1)
    {
        g_iPlayerData[ id ][ DATA_POINTS ] = SQL_ReadResult( hQuery, 0 );
        cs_set_user_money(id, g_iPlayerData[ id ][ DATA_POINTS ]);

    }
}

stock bool:SQL_IsFail( const iFailState, const iError, const szError[ ] )
{
    if( iFailState == TQUERY_CONNECT_FAILED )
    {
        log_amx( "[POINTS] Could not connect to SQL database: %s", szError );
        return true;
    }
    else if( iFailState == TQUERY_QUERY_FAILED )
    {
        log_amx( "[POINTS] Query failed: %s", szError );
        return true;
    }
    else if( iError )
    {
        log_amx( "[POINTS] Error on query: %s", szError );
        return true;
    }

    return false;
}
