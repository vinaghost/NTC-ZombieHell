#include <amxmodx>

#define PLUGIN "Zombie Hel: HUD Customizer 0.4"
#define VERSION "0.4"
#define AUTHOR "Igoreso"


// Hides Flashlight, but adds Crosshair ( Flash in code )
#define HUD_HIDE_FLASH (1<<1)

// Hides Timer
#define HUD_HIDE_TIMER (1<<4)

new g_msgHideWeapon
new iHideFlags;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	g_msgHideWeapon = get_user_msgid("HideWeapon")
	register_event("ResetHUD", "onResetHUD", "b")
	register_message(g_msgHideWeapon, "msgHideWeapon")

	iHideFlags = 0;
	iHideFlags |= HUD_HIDE_FLASH;
	iHideFlags |= HUD_HIDE_TIMER;
}

public onResetHUD(id)
{
	if(iHideFlags)
	{
		message_begin(MSG_ONE, g_msgHideWeapon, _, id)
		write_byte(iHideFlags)
		message_end()
	}
}

public msgHideWeapon()
{
	if(iHideFlags)
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | iHideFlags)
}
