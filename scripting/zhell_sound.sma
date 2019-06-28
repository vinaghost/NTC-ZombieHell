#include <amxmodx>

#include <zhell>
#include <zhell_const>

#define PLUGIN_NAME "Zombie Hell: Sound system"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

#define TASK_COOLDOWN 2000

new const sound_win_zombies[][] = {
	"sound/NTC/end_round/ntc_hwin081214.mp3",
	"sound/NTC/end_round/ntc_hwin106.mp3",
	"sound/NTC/end_round/ntc_hwin291115.mp3",
	"sound/NTC/end_round/ntc_hwin_090916.mp3",
	"sound/NTC/end_round/win_human_110517.mp3"
}
new const sound_win_humans[][] = {
	"sound/NTC/end_round/ntc_zwin081214.mp3",
	"sound/NTC/end_round/ntc_zwin106.mp3",
	"sound/NTC/end_round/ntc_zwin291115.mp3",
	"sound/NTC/end_round/ntc_zwin_090916.mp3",
	"sound/NTC/end_round/win_zombie_110517.mp3"
}

new const sound_win_no_one[] = "ambience/3dmstart.wav";

new const sound_cooldown[][] = {
	"vfox/one.wav",
	"vfox/two.wav",
	"vfox/three.wav",
	"vfox/four.wav",
	"vfox/five.wav",
	"vfox/six.wav",
	"vfox/seven.wav",
	"vfox/eight.wav",
	"vfox/nine.wav",
	"vfox/ten.wav"
}

new g_cooldown;
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
public zhell_round_cooldown() {
    g_cooldown = 10;

    PlaySoundToClients(sound_cooldown[g_cooldown - 1]);
    set_task(1.0, "cooldown", TASK_COOLDOWN + g_cooldown);

}
public cooldown(taskid) {
    taskid -= TASK_COOLDOWN;
    g_cooldown--;

    PlaySoundToClients(sound_cooldown[g_cooldown - 1]);

    if( g_cooldown <  1 ) {
        return;
    }
    set_task(1.0, "cooldown", TASK_COOLDOWN + g_cooldown);
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
