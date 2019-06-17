/*
 * SIMPLE POINTS API
 * by xPaw
 *
 * Website: https://xpaw.me/
 *
 * This plugin provides basic interface for storing points
 * This plugin can be used as XP storage for mods
 */

#include < amxmodx >
#include < sqlx >

#pragma semicolon 1

#define IsPlayer(%1) ( 1 <= %1 <= g_iMaxPlayers )
#define IsUserAuthorized(%1) ( g_iPlayerData[ %1 ][ DATA_STATUS ] & FULL_STATUS == FULL_STATUS )
#define CallForward(%1) new iReturn; ExecuteForward( g_iFwdConnected, iReturn, %1 )

enum ( <<= 1 )
{
    CONNECTED = 1,
    AUTHORIZED
};

enum _:PLR_DATA
{
    DATA_INDEX,
    DATA_POINTS,
    DATA_STATUS
};

const FULL_STATUS = CONNECTED | AUTHORIZED;

new g_iPlayerData[ 33 ][ PLR_DATA ];
new g_szSqlTable[] = "point";

new g_iMaxPlayers;
new g_iFwdConnected;

new Handle:g_hSqlTuple;

public plugin_init( )
{
    new const VERSION[ ] = "1.0 Alpha";

    register_plugin( "Zombie Hell: Simple Points API", VERSION, "xPaw" );

    g_iFwdConnected = CreateMultiForward( "points_client_connected", ET_IGNORE, FP_CELL );
    g_iMaxPlayers   = get_maxplayers( );
    g_hSqlTuple     = SQL_MakeStdTuple();

    new szQuery[ 300 ];
    formatex( szQuery, 299,
        "CREATE TABLE IF NOT EXISTS `%s` ( \
            `Id` int NOT NULL AUTO_INCREMENT, \
            `Name` varchar(32) DEFAULT NULL, \
            `Points` int(6) NOT NULL DEFAULT '0', \
            PRIMARY KEY (`Id`), UNIQUE (`Name`) )", g_szSqlTable );

    SQL_ThreadQuery( g_hSqlTuple, "HandleNullRoute", szQuery );
}

public plugin_natives( )
{
    register_library( "zhell_point" );

    register_native( "points_add", "NativeAddPoints" );
    register_native( "points_set", "NativeSetPoints" );
    register_native( "points_get", "NativeGetPoints" );
}

public plugin_end( )
{
    SQL_FreeHandle( g_hSqlTuple );
    DestroyForward( g_iFwdConnected );
}

// Client Related
// ====================================
public client_disconnected( id )
{
    g_iPlayerData[ id ][ DATA_INDEX  ] = 0;
    g_iPlayerData[ id ][ DATA_POINTS ] = 0;
    g_iPlayerData[ id ][ DATA_STATUS ] = 0;
}

public client_authorized( id )
{
    if( ( g_iPlayerData[ id ][ DATA_STATUS ] |= AUTHORIZED ) & CONNECTED )
    {
        UserHasBeenAuthorized( id );
    }
}

public client_putinserver( id )
{
    if( ( g_iPlayerData[ id ][ DATA_STATUS ] |= CONNECTED ) & AUTHORIZED && !is_user_bot( id ) )
    {
        UserHasBeenAuthorized( id );
    }
}

// Natives
// ====================================
public NativeAddPoints( const iPlugin, const iParams )
{
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

    if( g_iPlayerData[ iPlayer ][ DATA_POINTS ] < 0 )
    {
        g_iPlayerData[ iPlayer ][ DATA_POINTS ] = 0;
    }

    new szQuery[ 128 ];
    formatex( szQuery, 127, "UPDATE `%s` SET `Points` = `Points` + '%i' WHERE `Id` = '%i'",
        g_szSqlTable, iPoints, g_iPlayerData[ iPlayer ][ DATA_INDEX ] );

    new iData[ 2 ];
    iData[ 0 ] = iPlayer;
    iData[ 1 ] = iPoints;

    SQL_ThreadQuery( g_hSqlTuple, "HandleNullRoute", szQuery, iData, 2 );

    return true;
}

public NativeSetPoints( const iPlugin, const iParams )
{
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

    new szQuery[ 128 ];
    formatex( szQuery, 127, "UPDATE `%s` SET `Points` = '%i' WHERE `Id` = '%i'",
        g_szSqlTable, iPoints, g_iPlayerData[ iPlayer ][ DATA_INDEX ] );

    new iData[ 2 ];
    iData[ 0 ] = iPlayer;
    iData[ 1 ] = iPoints;

    SQL_ThreadQuery( g_hSqlTuple, "HandleNullRoute", szQuery, iData, 2 );

    return true;
}

public NativeGetPoints( const iPlugin, const iParams )
{
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
    new szAuthID[ 32 ], szQuery[ 128 ];
    get_user_authid( id, szAuthID, 31 );
    formatex( szQuery, 127, "SELECT `Id`, `Points` FROM `%s` WHERE `SteamId` = '%s'", g_szSqlTable, szAuthID );

    new iData[ 1 ];
    iData[ 0 ] = id;

    SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerConnect", szQuery, iData, 1 );
}

public HandleNullRoute( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime )
{
    if( SQL_IsFail( iFailState, iError, szError ) && iSize == 2 )
    {
        // There was an error in connection or query...
        // We have to synchronize player data later, so it won't get completely lost
    }
}

public HandlePlayerConnect( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime )
{
    if( SQL_IsFail( iFailState, iError, szError ) )
        return;

    new id = iData[ 0 ];

    if( !IsUserAuthorized( id ) )
        return;

    if( SQL_NumResults( hQuery ) )
    {
        g_iPlayerData[ id ][ DATA_INDEX  ] = SQL_ReadResult( hQuery, 0 );
        g_iPlayerData[ id ][ DATA_POINTS ] = SQL_ReadResult( hQuery, 1 );

        CallForward( id );
    }
    else
    {
        new szAuthID[ 32 ], szQuery[ 128 ];
        get_user_authid( id, szAuthID, 31 );
        formatex( szQuery, 127, "INSERT INTO `%s` (`SteamId`) VALUES ('%s')", g_szSqlTable, szAuthID );

        SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerInsert", szQuery, iData, 1 );
    }
}

public HandlePlayerInsert( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime )
{
    if( SQL_IsFail( iFailState, iError, szError ) )
        return;

    new id = iData[ 0 ];

    if( !IsUserAuthorized( id ) )
        return;

    g_iPlayerData[ id ][ DATA_INDEX  ] = SQL_GetInsertId( hQuery );
    g_iPlayerData[ id ][ DATA_POINTS ] = 0;

    CallForward( id );
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
