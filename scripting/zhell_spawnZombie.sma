#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fun>
#include <fakemeta>
#include <cstrike>


#define PLUGIN_NAME "Zombie Hell: Spawn Zombie"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

new g_fakePlayer[2];
new const sBotName[ ][] = {
    "[NTC] Multimod DP",
    "Groups: fb.com/groups/csntcmod"
};

new g_player = 0;

public plugin_init() {

    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1);
    set_task( 5.0, "creatBot" );

    register_message( get_user_msgid( "DeathMsg" ), "MsgDeathMsg" );
}

public plugin_natives() {
    register_native("zhell_get_id_fakeCt","_zhell_get_id_fakeCt");
    register_native("zhell_get_id_fakeT","_zhell_get_id_fakeT");
}
public client_authorized(id) {
    if(is_user_bot(id)) return;
    if(id == g_fakePlayer[0] || id == g_fakePlayer[1]) return;

    g_player++;

    set_task( 5.0, "creatZombie" );
}
public client_disconnected(id) {
    if(is_user_bot(id)) return;

    g_player--;
    set_task( 5.0, "creatZombie" );
}
public fwHamPlayerSpawnPost(id) {
    if( id == g_fakePlayer[0] || id == g_fakePlayer[1] ) {
        set_user_origin(id, {999,999,999} )
    }
}
public creatBot( ) {

    new id = find_player("a", sBotName[0]);

    if( !id ) {
        id = engfunc( EngFunc_CreateFakeClient, sBotName[0] );
        if( pev_valid( id ) ) {
            engfunc( EngFunc_FreeEntPrivateData, id );
            dllfunc( MetaFunc_CallGameEntity, "player", id );
            set_user_info( id, "rate", "3500" );
            set_user_info( id, "cl_updaterate", "25" );
            set_user_info( id, "cl_lw", "1" );
            set_user_info( id, "cl_lc", "1" );
            set_user_info( id, "cl_dlmax", "128" );
            set_user_info( id, "cl_righthand", "1" );
            set_user_info( id, "_vgui_menus", "0" );
            set_user_info( id, "_ah", "0" );
            set_user_info( id, "dm", "0" );
            set_user_info( id, "tracker", "0" );
            set_user_info( id, "friends", "0" );
            set_user_info( id, "*bot", "1" );
            set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FAKECLIENT );
            set_pev( id, pev_colormap, id );

            new szMsg[ 128 ];
            dllfunc( DLLFunc_ClientConnect, id, sBotName, "127.0.0.1", szMsg );
            dllfunc( DLLFunc_ClientPutInServer, id );

            cs_set_user_team( id, CS_TEAM_T );

            ExecuteHamB( Ham_CS_RoundRespawn, id );



            set_pev( id, pev_effects, pev( id, pev_effects ) | EF_NODRAW );
            set_pev( id, pev_solid, SOLID_NOT );
            dllfunc( DLLFunc_Think, id );

            g_fakePlayer[0] = id;
            set_user_origin(id, {500, 500, 500})
        }

        id = find_player("a", sBotName[1]);

        if( !id ) {
            id = engfunc( EngFunc_CreateFakeClient, sBotName[1] );
            if( pev_valid( id ) ) {
                engfunc( EngFunc_FreeEntPrivateData, id );
                dllfunc( MetaFunc_CallGameEntity, "player", id );
                set_user_info( id, "rate", "3500" );
                set_user_info( id, "cl_updaterate", "25" );
                set_user_info( id, "cl_lw", "1" );
                set_user_info( id, "cl_lc", "1" );
                set_user_info( id, "cl_dlmax", "128" );
                set_user_info( id, "cl_righthand", "1" );
                set_user_info( id, "_vgui_menus", "0" );
                set_user_info( id, "_ah", "0" );
                set_user_info( id, "dm", "0" );
                set_user_info( id, "tracker", "0" );
                set_user_info( id, "friends", "0" );
                set_user_info( id, "*bot", "1" );
                set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FAKECLIENT );
                set_pev( id, pev_colormap, id );

                new szMsg[ 128 ];
                dllfunc( DLLFunc_ClientConnect, id, sBotName, "127.0.0.1", szMsg );
                dllfunc( DLLFunc_ClientPutInServer, id );

                cs_set_user_team( id, CS_TEAM_CT );

                ExecuteHamB( Ham_CS_RoundRespawn, id );



                set_pev( id, pev_effects, pev( id, pev_effects ) | EF_NODRAW );
                set_pev( id, pev_solid, SOLID_NOT );
                dllfunc( DLLFunc_Think, id );

                g_fakePlayer[1] = id;
            }
        }
    }
}

public creatZombie() {
    if( g_player < 1) {
        server_cmd("amx_cvar yb_quota 0");
    }
    else {
        const fakePlayer = 2;
        const antiFull = 2;

        const antiLag = 16;
        new count = get_maxplayers() - fakePlayer - antiFull ;
        if ( count > antiLag ) {
            count = antiLag;
        }
        server_cmd("amx_cvar yb_quota %d", count);
    }
}

public MsgDeathMsg( const iMsgId, const iMsgDest, const id ) {
    if( get_msg_arg_int( 2 ) == g_fakePlayer[0] )
    return PLUGIN_HANDLED;

    if( get_msg_arg_int( 2 ) == g_fakePlayer[1] )
    return PLUGIN_HANDLED;

    return PLUGIN_CONTINUE;
}

public _zhell_get_id_fakeCt(iPlugin,iParams)
{
    return g_fakePlayer[0];
}
public _zhell_get_id_fakeT(iPlugin,iParams)
{
    return g_fakePlayer[1];
}
