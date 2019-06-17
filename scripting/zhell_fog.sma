#include <amxmodx>

#include <zhell>


new cvar_fog_density, cvar_fog_color[3]

new g_density, g_color[3];
new msg_fog;
// Fog density offsets [Thnx to DA]
new const g_fog_density[] = { 0, 0, 0, 0, 111, 18, 3, 58, 111, 18, 125, 58, 66, 96, 27, 59, 90, 101, 60, 59, 90,
			101, 68, 59, 10, 41, 95, 59, 111, 18, 125, 59, 111, 18, 3, 60, 68, 116, 19, 60 }

// The unique id of the fog task
new const TASK_FOG = 5942

// Plugin init
public plugin_init() {
	// Plugin Registeration
	register_plugin("Zombie Hell: Advanced Fog System", "1.0", "Saad706");

	// Register some cvars [Edit these]
	cvar_fog_density = 	register_cvar("zhell_fog_density", "4");
	cvar_fog_color[0] = 	register_cvar("zhell_fog_color_R", "250");
	cvar_fog_color[1] =	register_cvar("zhell_fog_color_G", "0");
	cvar_fog_color[2] = 	register_cvar("zhell_fog_color_B", "0");

	msg_fog = get_user_msgid("Fog");
	zhell_round_start();

}

// Round start
public zhell_round_start() {

	g_density = (4 * get_pcvar_num(cvar_fog_density));

	g_color[0] = get_pcvar_num(cvar_fog_color[0]);
	g_color[1] = get_pcvar_num(cvar_fog_color[1]);
	g_color[2] = get_pcvar_num(cvar_fog_color[2]);

	//remove_task(TASK_FOG)
	//set_task(0.5, "task_update_fog", TASK_FOG, _, _, "b")
	task_update_fog();
}

// Task: update fog message
public task_update_fog()
{
	message_begin(MSG_ALL, msg_fog , {0,0,0}, 0)
	write_byte(g_color[0]) // Red
	write_byte(g_color[1]) // Green
	write_byte(g_color[2]) // Blue
	write_byte(g_fog_density[g_density]) // SD
	write_byte(g_fog_density[g_density+1]) // ED
	write_byte(g_fog_density[g_density+2]) // D1
	write_byte(g_fog_density[g_density+3]) // D2
	message_end()
}
