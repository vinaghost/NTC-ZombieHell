#if defined _ZHELL_
  #endinput
#endif

#define _ZHELL_

forward zhell_spawn_zombie(id);
forward zhell_spawn_human(id);

forward zhell_killed_zombie(id);
forward zhell_killed_human(id);

forward zhell_last_human_pre(id);
forward zhell_last_human_post(id);
forward zhell_last_zombie_pre(id);
forward zhell_last_zombie_post(id);

forward zhell_round_end();
forward zhell_round_start();


native zhell_is_round_start();
native zhell_is_round_restart();
native zhell_is_round_end();

native zhell_is_zombie(id);

native zhell_get_count_human();
native zhell_get_count_zombie();


//zhell_levelZombie
native zhell_get_level();

native zhell_get_zombie_health();
native zhell_get_zombie_speed();
native zhell_get_boss_health();
native zhell_get_boss_speed();

