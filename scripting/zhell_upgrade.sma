#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <sqlx>

#include <cs_ham_bots_api>
#include <cs_maxspeed_api>

#include <zhell>
#include <zhell_const>

#include <cromchat>


#define PLUGIN_NAME "Zombie Hell: Upgrade"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "VINAGHOST"
\
enum _:PLR_UPGRADE {
    HP,
    AP,
    SPEED,
    JUMP,
    DMG,
    HEALING
}
enum _:UPGRADE {
    Float:BASE,
    POINT,
    POINT_MULTIPLY
}


new p_index[33];
new p_connected;
new Float:p_healer[33];
new g_iPlayerData[ 33 ][ PLR_UPGRADE ];

new const info_upgrade[][] = {
    "HP",
    "AP",
    "SPEED",
    "JUMP",
    "DMG",
    "HEALING"
}

new const upgrade[PLR_UPGRADE][UPGRADE] = {
    {2.0, 10, 2},
    {0.1, 40, 3},
    {0.1, 25, 2},
    {0.1, 50, 3},
    {0.1, 15, 2},
    {5.0, 30, 4}
}
new Handle:g_hSqlTuple;
new g_iHealer = -1;
public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_pre");
    RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage_pre");

    RegisterHam(Ham_Touch, "trigger_hurt", "HurtTouch");

    register_clcmd("say /nangcap", "showUpgrade");
    set_task(2.0, "sql");
}

public sql() {
    g_hSqlTuple = SQL_MakeStdTuple();
}
public client_disconnected( id ) {
    p_index[id] = 0;
    UnSet_BitVar(p_connected, id);
    g_iPlayerData[ id ][ HP ] = 0;
    g_iPlayerData[ id ][ AP ] = 0;
    g_iPlayerData[ id ][ SPEED ] = 0;
    g_iPlayerData[ id ][ JUMP ] = 0;
    g_iPlayerData[ id ][ DMG ] = 0;
    g_iPlayerData[ id ][ HEALING ] = 0;
}

public client_putinserver(id) {

    g_iPlayerData[ id ][ HP ] = 0;
    g_iPlayerData[ id ][ AP ] = 0;
    g_iPlayerData[ id ][ SPEED ] = 0;
    g_iPlayerData[ id ][ JUMP ] = 0;
    g_iPlayerData[ id ][ DMG ] = 0;
    g_iPlayerData[ id ][ HEALING ] = 0;

}
public zhell_client_connected(id) {
    p_index[id] = zhell_get_index(id);
    Set_BitVar(p_connected, id);

    UserHasBeenAuthorized( id )
}
public zhell_spawn_human(id) {
    if( !Get_BitVar(p_connected, id) ) {
        return;
    }

    if( g_iPlayerData[id][HP] ) {
        new Float:health = upgrade[HP][BASE] * g_iPlayerData[id][HP];

        entity_set_float(id, EV_FL_health, 100 + health );
        entity_set_float(id, EV_FL_max_health, 100 + health )
    }

    if( g_iPlayerData[id][SPEED] ) {
        cs_reset_player_maxspeed(id);
        cs_set_player_maxspeed_auto(id, 1 + upgrade[SPEED][BASE] * g_iPlayerData[id][SPEED]);
    }

    if( g_iPlayerData[id][JUMP] ) {
        set_user_gravity(id, 1.0 - upgrade[JUMP][BASE] * g_iPlayerData[id][JUMP]);
    }

}
public fw_TakeDamage_pre(victim, inflictor, attacker, Float:damage, bits) {

    if( !Get_BitVar(p_connected, attacker) && !zhell_is_zombie(attacker) ) {
        SetHamParamFloat(4, 0.0);
        return HAM_OVERRIDE;
    }


    if( g_iPlayerData[attacker][DMG] && !zhell_is_zombie(attacker)) {
        SetHamParamFloat(4, damage * ( 1 + upgrade[DMG][BASE] * g_iPlayerData[attacker][DMG] ) );
    }

    if( g_iPlayerData[victim][AP] && zhell_is_zombie(attacker) ) {
        SetHamParamFloat(4, damage * ( 1 - upgrade[AP][BASE] * g_iPlayerData[victim][AP]) )
    }
    return HAM_HANDLED;

}
public creatHealer() {

    g_iHealer = create_entity("trigger_hurt")

    if( !is_valid_ent(g_iHealer) ) {

        DispatchSpawn(g_iHealer);
        entity_set_size(g_iHealer, Float:{-8192.0, -8192.0, -8192.0} , Float:{8192.0, 8192.0, 8192.0});
        entity_set_int(g_iHealer, EV_INT_spawnflags, SF_TRIGGER_HURT_CLIENTONLYTOUCH);
    }
}
public HurtTouch(iEnt, id)
{
    if( iEnt != g_iHealer ) {
        return HAM_IGNORED;
    }

    if( !Get_BitVar(p_connected, id) ) {
        return HAM_IGNORED;
    }

    if( !g_iPlayerData[id][HEALING] ) {
        return HAM_IGNORED;
    }

    static Float:flTime;
    flTime = get_gametime();

    if ( p_healer[id] > flTime )
        return HAM_IGNORED;

    static Float:flHealth, Float:flMaxHealth

    flHealth = entity_get_float(id, EV_FL_health)
    flMaxHealth = entity_get_float(id, EV_FL_max_health)

    if( flMaxHealth <= flHealth ) {
        return HAM_SUPERCEDE
    }

    flHealth += upgrade[HEALING][BASE] * g_iPlayerData[id][HEALING];

    if( flHealth > flMaxHealth ) {
        flHealth = flMaxHealth
    }

    entity_set_float(id, EV_FL_health, flHealth)

    p_healer[id] = flTime + 1.0;

    return HAM_SUPERCEDE
}
public showUpgrade(id)  {
    if( !Get_BitVar(p_connected, id ) )
        return;
    static menu_content[64];
    formatex(menu_content, charsmax(menu_content), "\r[NTC] Upgrade \w- \y%d point", zhell_point_get(id));
    new menu = menu_create( menu_content, "menuUpgrade" );


    formatex(menu_content, charsmax(menu_content), "\wHP %d - tăng %dHP \R%dP", \
            g_iPlayerData[id][HP],  g_iPlayerData[id][HP] * floatround(upgrade[HP][BASE]) , pointNeed(HP,  g_iPlayerData[id][HP] + 1));
    menu_additem( menu, menu_content, "", 0 );

    formatex(menu_content, charsmax(menu_content), "\wAP %d - giảm %d% sát thương \R%dP", \
            g_iPlayerData[id][AP], g_iPlayerData[id][AP] * floatround(upgrade[AP][BASE] * 100) , pointNeed(AP,  g_iPlayerData[id][AP] + 1));
    menu_additem( menu, menu_content, "", 0 );

    formatex(menu_content, charsmax(menu_content), "\wSPEED %d - tăng %d% tốc độ di chuyển \R%dP", \
            g_iPlayerData[id][SPEED], g_iPlayerData[id][SPEED] * floatround(upgrade[SPEED][BASE] * 100) , pointNeed(SPEED,  g_iPlayerData[id][SPEED] + 1));
    menu_additem( menu, menu_content, "", 0 );


    formatex(menu_content, charsmax(menu_content), "\wJUMP %d - tăng %d% độ cao khi nhảy \R%dP", \
            g_iPlayerData[id][JUMP], g_iPlayerData[id][JUMP] * floatround(upgrade[JUMP][BASE] * 100) , pointNeed(JUMP,  g_iPlayerData[id][JUMP] + 1));
    menu_additem( menu, menu_content, "", 0 );

    formatex(menu_content, charsmax(menu_content), "\wDMG %d - tăng %d% sát thương \Rt%dP", \
             g_iPlayerData[id][DMG], g_iPlayerData[id][DMG] * floatround(upgrade[DMG][BASE] * 100) , pointNeed(DMG,  g_iPlayerData[id][DMG] + 1));
    menu_additem( menu, menu_content, "", 0 );

    formatex(menu_content, charsmax(menu_content), "\wHEALING %d - hồi %dHP mỗi giây \R%dP", \
            g_iPlayerData[id][HEALING], g_iPlayerData[id][HEALING] * floatround(upgrade[HEALING][BASE]) , pointNeed(HEALING,  g_iPlayerData[id][HEALING] + 1));
    menu_additem( menu, menu_content, "", 0 );


    menu_display( id, menu, 0 );

}

public menuUpgrade( id, menu, item ) {
    if ( item == MENU_EXIT ) {
        menu_destroy( menu );
        return;
    }

    new point_need = pointNeed(item,  g_iPlayerData[id][item] + 1);
    if(zhell_point_get(id) < point_need ) {
        menu_destroy(menu);
        CC_SendMessage(id, "Không đủ point để nâng cấp")
        return;
    }

    g_iPlayerData[id][item] ++;
    zhell_point_add(id, -point_need);

    CC_SendMessage(id, "Nâng cấp thành công, %s lên cấp %d", info_upgrade[item], g_iPlayerData[id][item]);

    new szQuery[ 128 ];
    formatex( szQuery, 127, "UPDATE `%s` SET `%s` = `%s` + 1 WHERE `Id` = '%i'",
        g_szSqlTable, info_upgrade[item], info_upgrade[item] , p_index[id] );

    SQL_ThreadQuery( g_hSqlTuple, "HandleNullRoute", szQuery);

    menu_display(id, menu);
    return;
 }

UserHasBeenAuthorized( const id ) {
    new szQuery[128]
    formatex( szQuery, 127, "SELECT `HP`, `AP`, `SPEED`, `JUMP`, `DMG`, `HEALING` FROM `%s` WHERE `ID` = '%d'", g_szSqlTable, p_index[id] );

    new iData[ 1 ];
    iData[ 0 ] = id;

    SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerConnect", szQuery, iData, 1 );
}

public HandleNullRoute( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime ) {
    if( SQL_IsFail( iFailState, iError, szError ) && iSize == 2 ) {
    }
}

public HandlePlayerConnect( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime ) {
    if( SQL_IsFail( iFailState, iError, szError ) )
        return;

    new id = iData[ 0 ];

    if( !Get_BitVar(p_connected, id ) ) return;

    if( SQL_NumResults( hQuery ) ) {
        g_iPlayerData[ id ][ HP ]           =   SQL_ReadResult( hQuery, 0 );
        g_iPlayerData[ id ][ AP ]           =   SQL_ReadResult( hQuery, 1 );
        g_iPlayerData[ id ][ SPEED ]        =   SQL_ReadResult( hQuery, 2 );
        g_iPlayerData[ id ][ JUMP ]         =   SQL_ReadResult( hQuery, 3 );
        g_iPlayerData[ id ][ DMG ]          =   SQL_ReadResult( hQuery, 4 );
        g_iPlayerData[ id ][ HEALING ]      =   SQL_ReadResult( hQuery, 5 );
    }
}

stock bool:SQL_IsFail( const iFailState, const iError, const szError[ ] ) {
    if( iFailState == TQUERY_CONNECT_FAILED ) {
        log_amx( "[SkillTree] Could not connect to SQL database: %s", szError );
        return true;
    }
    else if( iFailState == TQUERY_QUERY_FAILED ) {
        log_amx( "[SkillTree] Query failed: %s", szError );
        return true;
    }
    else if( iError ) {
        log_amx( "[SkillTree] Error on query: %s", szError );
        return true;
    }

    return false;
}

stock pointNeed(upgrades, level) {
    return upgrade[upgrades][POINT] * power( 1 + upgrade[upgrades][POINT_MULTIPLY], level );
}
