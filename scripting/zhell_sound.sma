#include <amxmodx>

#include <zhell>
#include <zhell_const>

#define PLUGIN_NAME "Zombie Hell: Sound system"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

new const sound_win_zombies[][] = {
	"sound/NTC/ntc_hwin081214.mp3",
	"sound/NTC/ntc_hwin106.mp3",
	"sound/NTC/ntc_hwin291115.mp3",
	"sound/NTC/ntc_hwin_090916.mp3",
	"sound/NTC/win_human_110517.mp3"
}
new const sound_win_humans[][] = {
	"sound/NTC/ntc_zwin081214.mp3",
	"sound/NTC/ntc_zwin106.mp3",
	"sound/NTC/ntc_zwin291115.mp3",
	"sound/NTC/ntc_zwin_090916.mp3",
	"sound/NTC/win_zombie_110517.mp3"
}

new const sound_win_no_one[] = "ambience/3dmstart.wav";

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	register_message(get_user_msgid("SendAudio"), "message_sendaudio")

}

public plugin_precache() {
	for(new i = 0; i < 5; i++) {
		precache_generic(sound_win_zombies[i]);
		precache_generic(sound_win_humans[i]);
	}
	precache_sound(sound_win_no_one);
}

public  zhell_round_end(team_win) {

	if( team_win == ZHELL_HUMAN ) {
		PlaySoundToClients(sound_win_humans[random_num(0, 5)], 1);
	}
	else if ( team_win == ZHELL_ZOMBIE ) {
		PlaySoundToClients(sound_win_zombies[random_num(0, 5)], 1);
	}
	else {
		PlaySoundToClients(sound_win_no_one, 1 );
	}
}

public message_sendaudio() {
	new audio[17]
	get_msg_arg_string(2, audio, charsmax(audio))

	if(equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw"))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}
