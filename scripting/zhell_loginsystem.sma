#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <sqlx>
#include <cstrike>
#include <engine>
#include <fakemeta>

#include <cs_weap_models_api>
#include <cs_player_models_api>

#include <zhell_const>

#include <cromchat>

#define PLUGIN_NAME "Zombie Hell: Login System"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "VINAGHOST"

/*
Credit:

Sylwester   - the idea for the encrypt
m0skVi4a ;] - code RegisterSystem
xPaw        - code SQL in SimplePointSystem

*/
#define SALT "8c4f4370c67e0c1e1ae9acd577dddbed"

#define IsUserAuthorized(%1) ( g_iPlayerData[ %1 ][ DATA_STATUS ] & FULL_STATUS == FULL_STATUS )
#define CallForward(%1) new iReturn; ExecuteForward( g_iFwdConnected, iReturn, %1 )

#define MOTD_FLAG_ARG 1
#define MOTD_FLAG_END 1

#define PEV_PDATA_SAFE    2
#define OFFSET_TEAM            114

enum ( <<= 1 )
{
    CONNECTED = 1,
    AUTHORIZED
};
enum _:TASK (+= 100) {
    NHACNHO = 1000,
    NHACNHO_LOGIN,
    RESPAWN_ONGAME,
    COOLDOWN,
    TIME_OUT,
    RESPAWN,
    BATTLE
}
enum {
    FAIL,
    REGISTER,
    LOGIN
}
enum _:PLR_DATA {
    DATA_INDEX,
    DATA_PASSWORD[33],
    DATA_STATUS,
    DATA_LOGIN
};
enum
{
    SKIN_MALE_PRI_N = 0,
    SKIN_MALE_PRI_G,
    SKIN_MALE_PRI_R,
    PL_FEMALE_PRI_N,
    PL_FEMALE_PRI_G,
    PL_FEMALE_PRI_R
}
new const nameChar[][] = { "'",  "^"",  "`",  "\" };


const FULL_STATUS = CONNECTED | AUTHORIZED;

new hash[34];
new typedpass[33];
new g_iPlayerData[ 33 ][ PLR_DATA ];
new g_iFwdConnected;

new const v_login_path[] = "models/v_login.mdl";
new const zhell_login_path[] = "models/player/zh_login/zh_login.mdl";
new const zhell_login[] = "zh_login";
new Handle:g_hSqlTuple;

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    register_clcmd("say /dangki", "dangKi");
    register_clcmd("say /dangnhap", "dangNhap");

    register_clcmd("REGISTER_PASS", "Register")
    register_clcmd("LOGIN_PASS", "Login")

    register_clcmd("chooseteam", "blockChangeTeam");
    register_clcmd("jointeam", "blockChangeTeam");
    register_menucmd(register_menuid("Team_Select", 1), (1<<0)|(1<<1)|(1<<4)|(1<<5), "blockChangeTeam");

    set_msg_block(get_user_msgid("MOTD"),BLOCK_SET)

    g_iFwdConnected = CreateMultiForward("zhell_client_connected", ET_IGNORE, FP_CELL);


    CC_SetPrefix("!g[NTC]");

    set_task(2.0, "sql");
}
public plugin_precache() {
    precache_model(v_login_path);
    precache_model(zhell_login_path);
}

public sql() {
    g_hSqlTuple     = SQL_MakeStdTuple();

    new szQuery[ 300 ];
    formatex( szQuery, 299,
        "CREATE TABLE IF NOT EXISTS `%s` ( \
            `Id` int NOT NULL AUTO_INCREMENT, \
            `Name` varchar(32) DEFAULT NULL, \
            `Password` varchar(32) NOT NULL DEFAULT '0', \
            PRIMARY KEY (`Id`), UNIQUE (`Name`) )", g_szSqlTable );

    SQL_ThreadQuery( g_hSqlTuple, "QuerySetData", szQuery );
}
public plugin_natives() {
    register_native("zhell_get_index", "_zhell_get_index");
}

public plugin_end( ) {
    SQL_FreeHandle( g_hSqlTuple );
    DestroyForward( g_iFwdConnected );
}

public client_disconnected( id ) {
    g_iPlayerData[ id ][ DATA_INDEX  ] = 0;
    g_iPlayerData[ id ][ DATA_STATUS ] = 0;
    g_iPlayerData[ id ][ DATA_LOGIN ] = FAIL;

    remove_task(id + NHACNHO);
    remove_task(id + NHACNHO_LOGIN);
    remove_task(id + COOLDOWN);
    remove_task(id + TIME_OUT);
    remove_task(id + RESPAWN);

}
public client_connect(id) {
    g_iPlayerData[ id ][ DATA_INDEX  ] = 0;
    g_iPlayerData[ id ][ DATA_STATUS ] = 0;
    g_iPlayerData[ id ][ DATA_LOGIN ] = FAIL;
}
public client_authorized( id ) {
   if( ( g_iPlayerData[ id ][ DATA_STATUS ] |= AUTHORIZED ) & CONNECTED ) {
        UserHasBeenAuthorized( id );
    }
}

public client_putinserver( id ) {
    if( ( g_iPlayerData[ id ][ DATA_STATUS ] |= CONNECTED ) & AUTHORIZED && !is_user_bot( id ) ) {
        UserHasBeenAuthorized( id );
    }
}
public blockChangeTeam(id) {
    if( g_iPlayerData[id][DATA_STATUS] == LOGIN )  return PLUGIN_HANDLED_MAIN;

    return PLUGIN_CONTINUE;
}
UserHasBeenAuthorized( const id ) {
    new szName[ 32 ], szQuery[ 128 ];
    get_user_name( id, szName, 31 );

    for( new i = 0; i < 4; i++ ) {
        if( contain(szName, nameChar[i]) != -1 ) {
            server_cmd("kick #%i ^"%s^"", get_user_userid(id), "Ten chua ki tu la" );
            return;
        }
    }

    formatex( szQuery, 127, "SELECT `Id`, `Password` FROM `%s` WHERE `Name` = '%s'", g_szSqlTable, szName );

    new iData[ 1 ];
    iData[ 0 ] = id;

    SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerConnect", szQuery, iData, 1 );


    set_task(1.0, "respawn_login", id + RESPAWN);

}
public respawn_login(id) {
    id -= RESPAWN;


    //ExecuteHamB(Ham_CS_RoundRespawn, id);
    cs_set_user_team(id, CS_TEAM_SPECTATOR);
    set_user_origin(id, {-2043, 3491, 68});
    strip_user_weapons(id);
    give_item(id, "weapon_knife");

    cs_set_player_view_model(id, CSW_KNIFE, v_login_path);
    cs_set_player_weap_model(id, CSW_KNIFE, "");
    cs_set_player_model(id, zhell_login);

    if( random_num(0, 1) ) {
        set_pev(id, pev_skin, 0)

        set_pev(id, pev_body, 3)

    }
    else {
        set_pev(id, pev_body, 4)
    }

}
public respawn_ongame(id) {
    id -= RESPAWN_ONGAME;

    cs_set_user_team(id, CS_TEAM_CT);
    cs_reset_player_model(id);
    cs_reset_player_view_model(id, CSW_KNIFE);
    cs_reset_player_weap_model(id, CSW_KNIFE);

    ExecuteHamB(Ham_CS_RoundRespawn, id);
}

public HandlePlayerConnect( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime ) {
    if( SQL_IsFail( iFailState, iError, szError ) )
        return;

    new id = iData[ 0 ];

    if( !IsUserAuthorized( id ) )
        return;
    if( SQL_NumResults( hQuery ) ) {

        g_iPlayerData[ id ][ DATA_INDEX ] = SQL_ReadResult( hQuery, 0 );
        SQL_ReadResult( hQuery, 1, g_iPlayerData[ id ][ DATA_PASSWORD ], charsmax(g_iPlayerData[][ DATA_PASSWORD ]) );

        if(equal(g_iPlayerData[ id ][ DATA_PASSWORD ], "")) {
            set_task(5.0, "showNhacNho", id + NHACNHO);
            g_iPlayerData[ id ][ DATA_LOGIN ] = REGISTER;

            CallForward( id );
        }
        else {
            set_task(5.0, "showCoolDown", id + COOLDOWN);
            g_iPlayerData[ id ][ DATA_LOGIN ] = FAIL;
        }
    }
    else {
        new szName[ 32 ], szQuery[ 128 ];
        get_user_name( id, szName, 31 );
        formatex( szQuery, 127, "INSERT INTO `%s` (`Name`, `Password`) VALUES ('%s', '')", g_szSqlTable, szName);

        SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerInsert", szQuery, iData, 1 );
    }

}


public HandlePlayerInsert( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime ) {
    if( SQL_IsFail( iFailState, iError, szError ) )
        return;

    new id = iData[ 0 ];

    if( !IsUserAuthorized( id ) )
        return;

    g_iPlayerData[ id ][ DATA_INDEX  ] = SQL_GetInsertId( hQuery );
    formatex(g_iPlayerData[ id ][ DATA_PASSWORD ], charsmax(g_iPlayerData[ ][ DATA_PASSWORD ]), "");
    g_iPlayerData[ id ][ DATA_LOGIN ] = REGISTER;

    set_task(5.0, "showNhacNho", id + NHACNHO);
    CallForward( id );
}
public dangKi(id) {
    if( !IsUserAuthorized( id ) ) return PLUGIN_HANDLED;

    if( g_iPlayerData[ id ][ DATA_LOGIN ] == FAIL ) {
        CC_SendMessage(id, "Tài khoản đã đăng kí, < /dangnhap > để đăng nhập");
        return PLUGIN_HANDLED;
    }

    if( g_iPlayerData[ id ][ DATA_LOGIN ] != REGISTER ) {
        CC_SendMessage(id, "Bạn đã đăng nhập");
        return PLUGIN_HANDLED;
    }

    new menu = menu_create( "\r[NTC] Đăng kí:", "menuDangKi" );

    menu_additem( menu, "\wNhập mật khẩu", "", 0 );

    menu_display( id, menu, 0 );
    return PLUGIN_HANDLED;
}
public menuDangKi(id, menu, item) {
    if( !IsUserAuthorized( id ) ) {
        menu_destroy(menu);
        return;
    }

    if( item == MENU_EXIT ) {
        menu_destroy(menu);
        return;
    }
    if( g_iPlayerData[ id ][ DATA_LOGIN ] == FAIL ) {
        CC_SendMessage(id, "Tài khoản đã đăng kí, < /dangnhap > để đăng nhập");
        menu_destroy(menu);
        return;
    }

    if( g_iPlayerData[ id ][ DATA_LOGIN ] != REGISTER ) {
        CC_SendMessage(id, "Bạn đã đăng nhập");
        menu_destroy(menu);
        return;
    }

    client_cmd(id, "messagemode REGISTER_PASS");

    menu_destroy(menu);
    return;
}

public dangNhap(id) {
    if( !IsUserAuthorized( id ) ) return PLUGIN_HANDLED;

    if( g_iPlayerData[ id ][ DATA_LOGIN ] == REGISTER ) {
        CC_SendMessage(id, "Tài khoản chưa được đăng kí, !g< /dangki > để đăng kí tài khoản");
        return PLUGIN_HANDLED;
    }

    if( g_iPlayerData[ id ][ DATA_LOGIN ] != FAIL ) {
        CC_SendMessage(id, "Bạn đã đăng nhập");
        return PLUGIN_HANDLED;
    }

    new menu = menu_create( "\r[NTC] Đăng nhập:", "menuDangNhap" );

    menu_additem( menu, "\wNhập mật khẩu", "", 0 );

    menu_display( id, menu, 0 );

    return PLUGIN_HANDLED;
}
public menuDangNhap(id, menu, item) {
    if( !IsUserAuthorized( id ) ) {
        menu_destroy(menu);
        return;
    }

    if( item == MENU_EXIT ) {
        menu_destroy(menu);
        return;
    }
    if( g_iPlayerData[ id ][ DATA_LOGIN ] == REGISTER ) {
        CC_SendMessage(id, "Tài khoản chưa được đăng kí, !g< /dangki > để đăng kí tài khoản");
        return;
    }

    if( g_iPlayerData[ id ][ DATA_LOGIN ] != FAIL ) {
        CC_SendMessage(id, "Bạn đã đăng nhập");
        return;
    }

    client_cmd(id, "messagemode LOGIN_PASS");

    menu_destroy(menu);
    return;
}
public showNhacNho(id) {

    id -= NHACNHO;
    if(  g_iPlayerData[ id ][ DATA_LOGIN ] != REGISTER ) {
        remove_task(id + NHACNHO);
        return;
    }

    CC_SendMessage(id, "Tài khoản này chưa được đăng kí, !g< /dangki > !nđể đăng kí");
    set_task(10.0, "showNhacNho", id + NHACNHO);
}
public showNhacNho_login(id) {

    id -= NHACNHO_LOGIN;
    if(  g_iPlayerData[ id ][ DATA_LOGIN ] == LOGIN ) {
        remove_task(id + NHACNHO_LOGIN);
        return;
    }

    CC_SendMessage(id, "Tài khoản này đã đăng kí, !g< /dangnhap > !nđể đăng nhập");
    set_task(10.0, "showNhacNho_login", id + NHACNHO_LOGIN);
}
public showCoolDown(id) {

    id -= COOLDOWN;
    if(  g_iPlayerData[ id ][ DATA_LOGIN ] != FAIL ) {
        remove_task(id + COOLDOWN);
        return;
    }
    CC_SendMessage(id, "Bạn có !g59 giây!n để đăng nhập. Dùng !g< /dangnhap >");
    set_task(5.0, "showNhacNho_login", id + NHACNHO_LOGIN);
    set_task(59.0, "showTimeOut", id + TIME_OUT);
    return;
}

public showTimeOut(id) {

    id -= TIME_OUT;
    if(  g_iPlayerData[ id ][ DATA_LOGIN ] == FAIL ) {
        server_cmd("kick #%i ^"%s^"", get_user_userid(id), "Ban dang nhap qua cham" )
        return;
    }
    return;
}
public Register(id) {
    if( !IsUserAuthorized( id ) ) return PLUGIN_HANDLED;

    if(g_iPlayerData[id][DATA_LOGIN] == LOGIN) {
        CC_SendMessage(id, "Bạn đã đăng nhập");
        return PLUGIN_HANDLED
    }
    read_args(typedpass, charsmax(typedpass))
    remove_quotes(typedpass)

    new passlength = strlen(typedpass)

    if(equal(typedpass, ""))
        return PLUGIN_HANDLED



    if(passlength < 6)
    {
        CC_SendMessage(id, "Mật khẩu tối thiểu 6 kí tự");
        client_cmd(id, "messagemode REGISTER_PASS")
        return PLUGIN_HANDLED
    }

    convert_password(typedpass, hash, charsmax(hash))


    formatex(g_iPlayerData[id][DATA_PASSWORD], charsmax(g_iPlayerData[][DATA_PASSWORD]), hash)
    UpdatePassword(id)


    return PLUGIN_HANDLED
}
public Login(id)
{
    if( !IsUserAuthorized( id ) ) return PLUGIN_HANDLED;

    if( g_iPlayerData[ id ][ DATA_LOGIN ] == REGISTER ) {
        CC_SendMessage(id, "Tài khoản chưa đươc đăng kí, !g< /dangki > !nđể đăng kí");
        return PLUGIN_HANDLED;
    }

    if( g_iPlayerData[ id ][ DATA_LOGIN ] != FAIL ) {
        CC_SendMessage(id, "Bạn đã đăng nhập");
        return PLUGIN_HANDLED;
    }

    read_args(typedpass, charsmax(typedpass))
    remove_quotes(typedpass)

    if(equal(typedpass, ""))
        return PLUGIN_HANDLED

    convert_password(typedpass, hash, charsmax(hash))

    if(!equal(hash, g_iPlayerData[id][DATA_PASSWORD]))
    {
        server_cmd("kick #%i ^"%s^"", get_user_userid(id), "Sai mat khau" )
        return PLUGIN_HANDLED
    }

    g_iPlayerData[ id ][ DATA_LOGIN ] = LOGIN;
    CC_SendMessage(id, "Đăng nhập thành công");
    set_task(1.0, "respawn_ongame", id + RESPAWN_ONGAME);
    CallForward(id)


    if( task_exists(id + TIME_OUT ) ) remove_task(id + TIME_OUT);
    if( task_exists(id + COOLDOWN ) ) remove_task(id + COOLDOWN);

    return PLUGIN_HANDLED
}
public UpdatePassword(id) {


    static szQuery[ 256 ];
    formatex( szQuery, charsmax(szQuery), "UPDATE `%s` SET `Password` = '%s' WHERE `Id` = '%i'",
        g_szSqlTable, g_iPlayerData[id][DATA_PASSWORD], g_iPlayerData[id][DATA_INDEX]);


    SQL_ThreadQuery( g_hSqlTuple, "QuerySetData", szQuery);

    server_cmd("kick #%i ^"%s^"", get_user_userid(id), "Dang ki tai khoan thanh cong" )
}


stock bool:SQL_IsFail( const iFailState, const iError, const szError[ ] ) {
    if( iFailState == TQUERY_CONNECT_FAILED ) {
        server_print( "[POINTS] Could not connect to SQL database: %s", szError );
        return true;
    }
    else if( iFailState == TQUERY_QUERY_FAILED ) {
        server_print( "[POINTS] Query failed: %s", szError );
        return true;
    }
    else if( iError ) {
        server_print( "[POINTS] Error on query: %s", szError );
        return true;
    }

    return false;
}
stock convert_password(const password[], converted_password[34], len)
{
    static pass_salt[80]

    formatex(pass_salt, charsmax(pass_salt), "%s%s", password, SALT)
    hash_string(pass_salt, Hash_Md5, converted_password, len );
}

public QuerySetData(FailState, Handle:Query, error[],errcode, data[], datasize) {
    if(SQL_IsFail(FailState, errcode, error) ) {
        return
    }
}

public _zhell_get_index( iPlugin, iParams ) {

    new id = get_param(1);

    return g_iPlayerData[id][DATA_INDEX];
}
