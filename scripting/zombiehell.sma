///////////////////////////////////////////////////////////
///         ZombieHell 2.0 - www.zombiehell.co.cc       ///
///////////////////////////////////////////////////////////
///        Developer: Hector Carvalho(hectorz0r)        ///
///////////////////////////////////////////////////////////
///          Fixed By: Tonyyoung(MyChat Taiwan)         ///
///     http://bbs.mychat.to/thread.php?cck=1&fid=437   ///
///////////////////////////////////////////////////////////
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <fun>

#define PLUGIN_NAME	"ZombieHell"
#define PLUGIN_VERSION	"2.0Z"
#define PLUGIN_AUTHOR	"hectorz0r"

///////////////////////////////////////////////////////////////////
/// Custom Settings                                             ///
///////////////////////////////////////////////////////////////////
// 天氣效果(把要開啟的天氣前面的"//"去掉即可啟用)
//#define AMBIENCE_RAIN // Rain ##下雨
//#define AMBIENCE_SNOW // Snow ##下雪
#define AMBIENCE_FOG 	// Fog ##霧

#if defined AMBIENCE_FOG // 霧的設定(於霧開啟時作用)
new const FOG_DENSITY[] = "0.0003" // Density ##霧的密度
new const FOG_COLOR[] = "1 1 1" // Color: Red Green Blue ##霧的顏色
#endif

// 如果你不想改變天空貼圖就把"//"去掉
//#define DONT_CHANGE_SKY //不改變天空背景

#if !(defined DONT_CHANGE_SKY)
// 天空背景的名稱(設置多組天空時系統將會從中隨機選擇一組)
new const SKY_NAMES[][] = { "zombiehell" }
#endif

// Explosion radius for custom grenades
const Float:NADE_EXPLOSION_RADIUS = 300.0 //火焰彈和冰凍彈爆炸時,燃燒和冰凍的作用範圍

///////////////////////////////////////////////////////////////////
/// Game Maps                                                   ///
///////////////////////////////////////////////////////////////////
// 玩家完成10關挑戰後系統將會自動隨機切換以下地圖
new const Random_Map[][] =
{
	"cs_assault",
	"cs_italy",
	"de_dust",
	"de_dust2",
	"de_inferno",
	"de_train"
}

///////////////////////////////////////////////////////////////////
/// Task Defines                                                ///
///////////////////////////////////////////////////////////////////
#define TASK_MODEL 	2000
#define TASK_RESPAWN 	2100
#define TASK_TEAM	2200
#define TASK_BURN	2300
#define TASK_UNFROZEN	2400
#define TASK_NVG	2500
#define TASK_SPEC_NVG	2600
#define TASK_AMBIENCE_SOUND		454545
#define TASK_BOSS_AMBIENCE_SOUND	565656

///////////////////////////////////////////////////////////////////
/// Const Items                                                 ///
///////////////////////////////////////////////////////////////////
// Map Objective Entities (Removed)
new const OBJECTIVE_ENTITYS[][] =
{
	"func_bomb_target", "info_bomb_target", "info_vip_start", "func_vip_safetyzone", "func_escapezone",
	"hostage_entity", "monster_scientist", "func_hostage_rescue", "info_hostage_rescue",
	"env_fog", "env_rain", "env_snow", "item_longjump", "func_vehicle"
}

// Hegrenade explode make dmage type
const DMG_HEGRENADE = (1<<24)

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|
(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|
(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

// Weapon IDs for ammo types
new const AMMOID_WEAPON[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_M3, CSW_MAC10, CSW_FIVESEVEN,
CSW_DEAGLE, CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4 }

// Ammo IDs for weapons
new const WEAPON_AMMOID[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }

// Ammo Type Names for weapons
new const AMMO_TYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm",
"45acp", "556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot", "556nato",
"9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// 購買各項武器彈匣可獲得的子彈數
new const BUY_AMMO[] = { -1, 15, -1, 30, -1, 8, -1, 15, 30, -1, 30, 50, 15,
30, 30, 30, 15, 30, 10, 30, 30, 8, 30, 30, 30, -1, 7, 30, 30, -1, 50 }

// 各項武器之最大備彈數量
new const MAX_BPAMMO[] = { -1, 250, -1, 250, 1, 250, 1, 250, 250, 1, 250, 250, 250, 250,
250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 2, 250, 250, 250, -1, 250 }

// 顯示在武器選單上的各項武器名稱
new const WEAPON_NAME[CSW_P90+1][] = { "", "P228", "", "Scout", "", "XM1014", "", "MAC10", "AUG",
"", "Elite", "Five-Seven", "UMP45", "SG550", "Galil", "Famas", "USP", "Glock18", "AWP", "MP5",
"M249", "M3", "M4A1", "TMP", "G3SG1", "", "Desert-Eagle", "SG5g52", "AK47", "", "P90" }

// Weapons calssname
new const WEAPON_CLASSNAME[CSW_P90+1][] = { "", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10",
"weapon_aug", "", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas",
"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
"weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552", "weapon_ak47", "", "weapon_p90" }

// Weapons Offsets (win32)
const OFFSET_flNextPrimaryAttack = 46
const OFFSET_flNextSecondaryAttack = 47
const OFFSET_flTimeWeaponIdle = 48

// Linux diff's
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux
const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds

// HACK: pev_ field used to store custom nade types and their values
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_FIRE = 2222
const NADE_TYPE_FROST = 3333
const NADE_TYPE_FLARE = 4444
const PEV_FLARE_COLOR = pev_punchangle
const PEV_FLARE_DURATION = pev_flSwimTime
const BREAK_GLASS = 0x01
const FFADE_IN = 0x0000
const FFADE_STAYOUT = 0x0004
const UNIT_SECOND = (1<<12)

///////////////////////////////////////////////////////////////////
/// Cvars                                                       ///
///////////////////////////////////////////////////////////////////
new cvar_zombie_knife, cvar_zombie_maxslots, cvar_zombie_effect, cvar_level, cvar_zombie_spawnpoint, cvar_zombie_respawn_delay, cvar_zombie_scores, cvar_survivor_giveweap, cvar_survivor_ulammo,
cvar_survivor_respawn, cvar_survivor_respawns, cvar_survivor_respawn_delay, cvar_fire_duration, cvar_fire_damage, cvar_fire_slowdown, cvar_flare_duration, cvar_flare_color, cvar_flare_rgb,
cvar_flare_size,cvar_remove_weapon_time, cvar_boss_dmg_multiplier, cvar_boss_leap, cvar_leap_cooldown, cvar_freeze_duration, cvar_leap_force, cvar_leap_height, cvar_custom_nvg, cvar_nvg_color,
cvar_nvg_size, cvar_armor_protect, cvar_level1_respawns, cvar_level1_health, cvar_level1_maxspeed, cvar_level1_bosshp, cvar_level1_bossmaxspeed, cvar_level1_lighting, cvar_level2_respawns,
cvar_level2_health, cvar_level2_maxspeed, cvar_level2_bosshp, cvar_level2_bossmaxspeed, cvar_level2_lighting, cvar_zombie_random, cvar_level3_respawns, cvar_level3_health, cvar_level3_maxspeed,
cvar_level3_bosshp, cvar_level3_bossmaxspeed, cvar_level3_lighting, cvar_level4_respawns, cvar_level4_health, cvar_level4_maxspeed, cvar_level4_bosshp, cvar_level4_bossmaxspeed, cvar_level4_lighting,
cvar_level5_respawns, cvar_level5_health, cvar_level5_maxspeed, cvar_level5_bosshp,/* cvar_bot_type, */cvar_level5_bossmaxspeed, cvar_level5_lighting, cvar_level6_respawns, cvar_level6_health,
cvar_level6_maxspeed, cvar_level6_bosshp, cvar_level6_bossmaxspeed, cvar_level6_lighting, cvar_level7_respawns, cvar_level7_health, cvar_level7_maxspeed, cvar_level7_bosshp, cvar_level7_bossmaxspeed,
cvar_level7_lighting, cvar_level8_respawns, cvar_cvar_zombiebar, cvar_level8_health, cvar_level8_maxspeed, cvar_level8_bosshp, cvar_level8_bossmaxspeed, cvar_level8_lighting, cvar_level9_respawns,
cvar_level9_health, cvar_level9_maxspeed, cvar_removedoors, cvar_level9_bosshp, cvar_level9_bossmaxspeed, cvar_level9_lighting, cvar_level10_respawns, cvar_level10_health, cvar_level10_maxspeed,
cvar_level10_bosshp, cvar_level10_bossmaxspeed, cvar_level10_lighting, cvar_lockfrdkill, cvar_zombieheal, cvar_bosskill_bonus, cvar_zombiekill_bonus, cvar_maxmoney, cvar_bot_giveweap, cvar_final_secret,
cvar_survivor_protect, cvar_zombie_protect, cvar_map_time, cvar_render_zr, cvar_render_zg, cvar_render_zb, cvar_render_ctr, cvar_render_ctg, cvar_render_ctb, cvar_batk, cvar_boss_knife,
cvar_zatk, cvar_fire_damagemul, cvar_zombiearmor, cvar_zombieappear, cvar_survivor_buyzone

///////////////////////////////////////////////////////////////////
/// Models                                                      ///
///////////////////////////////////////////////////////////////////
// 人類的人物模型
new const MODEL_HUMAN[][] = { "arctic", "guerilla", "leet", "terror", "gign", "gsg9", "sas", "urban" }

// 殭屍的人物模型 (可設定多個模型使用)
new const MODEL_ZOMBIE[][] = { "zombie_source" }

// 殭屍BOSS的人物模型 (可設定多個模型使用)
new const MODEL_ZOMBIE_BOSS[][] = { "zombie_depredador" }

// 殭屍的手部模型 (只可設定單一模型使用)
new const model_vknife_zombie[] = { "models/zombie_plague/v_knife_zombie3.mdl" }

// 殭屍王的手部模型 (只可設定單一模型使用)
new const model_vknife_boss[] = { "models/zombie_plague/v_depredador_claws.mdl" }

// 手榴彈模型
new const model_grenade_fire[] = { "models/zombie_plague/v_grenade_fire.mdl" }
new const model_grenade_frost[] = { "models/zombie_plague/v_grenade_frost.mdl" }
new const model_grenade_flare[] = { "models/zombie_plague/v_grenade_flare.mdl" }

//BOSS血條
new const healthbar_spr[] = { "sprites/zombie_plague/zmhpbar.spr" }

///////////////////////////////////////////////////////////////////
/// Sounds	                                                ///
///////////////////////////////////////////////////////////////////
// 場景音樂 (可設定多個場景音樂,會隨機選取一首播放.)
// *每個設定的場景音樂都必須有一個播放聲音長度對應到,不然會出現錯誤.
new const SOUND_AMBIENCE[][] = { "zombiehell/zh_intro.mp3" } 		//開局的場景音樂
new const Float:ambience_duration[] = { 23.0 } 				//開局的場景音樂的聲音長度(單位:秒)
new const SOUND_AMBIENCE_BOSS[][] = { "zombiehell/zh_boss.wav" }	//BOSS的場景音樂
new const Float:boss_ambience_duration[] = { 5.0 } 			//BOSS的場景音樂的聲音長度(單位:秒)

// 其它聲音
new const SOUND_ZOMBIE_MISS_SLASH[][] = { "zombie_plague/zombie_swing1.wav", "zombie_plague/zombie_swing2.wav", "zombie_plague/zombie_swing3.wav" } 	//殭屍揮爪的音效
new const SOUND_ZOMBIE_MISS_WALL[][] = { "zombie_plague/zombie_wall1.wav", "zombie_plague/zombie_wall2.wav", "zombie_plague/zombie_wall3.wav" }	//殭屍打牆壁的音效
new const SOUND_ZOMBIE_HIT_NORMAL[][] = { "zombie_plague/zombie_attack1.wav", "zombie_plague/zombie_attack2.wav", "zombie_plague/zombie_attack3.wav" }//殭屍攻擊敵人的音效(左鍵攻擊)
new const SOUND_ZOMBIE_HIT_STAB[][] = { "zombie_plague/zombie_stab.wav" } //殭屍攻擊敵人的音效(右鍵攻擊)
new const SOUND_ZOMBIE_DIE[][] = { "zombiehell/zbs_death_1.wav" }	  //殭屍死亡時的叫聲
new const SOUND_ZOMBIE_PAIN[][] = { "zombie_plague/zombie_pain1.wav", "zombie_plague/zombie_pain2.wav" }	//殭屍受到傷害時的叫聲
new const SOUND_BOSS_PAIN[][] = { "zombie_plague/nemesis_pain1.wav", "zombie_plague/nemesis_pain2.wav" }	//殭屍王受到傷害時的叫聲
new const SOUND_FIRE_PLAYER_SCREAM[][] = { "zombie_plague/zombie_burn3.wav", "zombie_plague/zombie_burn4.wav",
"zombie_plague/zombie_burn5.wav", "zombie_plague/zombie_burn6.wav" , "zombie_plague/zombie_burn7.wav" }		//殭屍被火燒時的哀號聲
new const SOUND_ZOMBIE_WIN[] = { "ambience/the_horror1.wav" }		 //殭屍勝利的音效
new const SOUND_SURVIVOR_WIN[] = { "zombiehell/win_humans1.wav" }	 //人類勝利的音效
new const SOUND_DRAW[] = { "zombiehell/win_no_one.wav" }		 //平手時的音效
new const SOUND_EAT_BRAIN[] = { "zombiehell/zh_brain.wav" }		 //殭屍吃掉人類的音效
new const SOUND_BOSS_BEACON[] = { "zombiehell/zh_beacon.wav" }		 //BOSS發出的聲音
new const SOUND_FIRE_EXPLODE[] = { "zombie_plague/grenade_explode.wav" } //火焰彈爆炸時的音效
new const SOUND_FROST_EXPLODE[] = { "warcraft3/frostnova.wav" }		 //冰凍彈爆炸時的音效
new const SOUND_FLARE_ON[] = { "items/nvg_on.wav" }			 //照明彈啟動時的音效
new const SOUND_FROST_PLAYER[] = { "warcraft3/impalehit.wav" }		 //殭屍被冰凍時的音效
new const SOUND_FROST_BREAK[] = { "warcraft3/impalelaunch1.wav" }	 //殭屍解除冰凍時的音效
new const SOUND_TURN_NVG_ON[] = { "items/nvg_on.wav" }			 //夜視鏡開啟的音效
new const SOUND_TURN_NVG_OFF[] = { "items/nvg_off.wav" }		 //關閉夜視鏡時的音效
new const SOUND_PICK_GRENADE[] = { "items/gunpickup2.wav" } 		 //取得投擲彈時的音效
new const SOUND_PICK_AMMO[] = { "items/9mmclip1.wav" }			 //取得彈藥時的音效
new const SOUND_PICK_ARMOR[] = { "items/ammopickup2.wav" }		 //取得護甲時的音效

///////////////////////////////////////////////////////////////////
/// Give Gun Sets                                               ///
///////////////////////////////////////////////////////////////////
// 給予人類槍支的配套組合,每一組給予2把槍,主槍副槍皆可.(可設定多個組合)
#define GUN_SETS_NUM 18	//武器組合數量

// 武器組合:[第一把槍]
new const GIVE_GUN_1[GUN_SETS_NUM][] =
{
	"weapon_galil",
	"weapon_famas",
	"weapon_aug",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_m249",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_tmp",
	"weapon_mac10",
	"weapon_mp5navy",
	"weapon_ump45",
	"weapon_p90",
	"weapon_scout",
	"weapon_awp",
	"weapon_sg550",
	"weapon_g3sg1"
}

// 武器組合:[第二把槍]
new const GIVE_GUN_2[GUN_SETS_NUM][] =
{
	"weapon_glock18",
	"weapon_glock18",
	"weapon_glock18",
	"weapon_usp",
	"weapon_usp",
	"weapon_usp",
	"weapon_p228",
	"weapon_p228",
	"weapon_p228",
	"weapon_fiveseven",
	"weapon_fiveseven",
	"weapon_fiveseven",
	"weapon_elite",
	"weapon_elite",
	"weapon_elite",
	"weapon_deagle",
	"weapon_deagle",
	"weapon_deagle"
}

///////////////////////////////////////////////////////////////////
// Weapon Menu Items                                             //
///////////////////////////////////////////////////////////////////
// 武器選單的主武器選項 (可自行設定欲加入選單的槍支武器)
new const MenuPriWeaponItems[][] =
{
	"weapon_galil",
	"weapon_famas",
	"weapon_aug",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_m249",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_tmp",
	"weapon_mac10",
	"weapon_mp5navy",
	"weapon_ump45",
	"weapon_p90",
	"weapon_scout",
	"weapon_awp",
	"weapon_sg550",
	"weapon_g3sg1"
}

// 武器選單的副武器選項 (可自行設定欲加入選單的槍支武器)
new const MenuSecWeaponItems[][] =
{
	"weapon_glock18",
	"weapon_usp",
	"weapon_p228",
	"weapon_deagle",
	"weapon_fiveseven",
	"weapon_elite"
}

///////////////////////////////////////////////////////////////////
// Weapon Items const                                            //
///////////////////////////////////////////////////////////////////
// 各項武器價格設定
new const WEAPON_COST[CSW_P90+1] =
{
//----[設定價格]//[武器名稱][CS預設價格]
	-1, 	//----
	600,	//p228 (600)
	-1, 	//----
	2750,	//scout (2750)
	-1, 	//----
	3000, 	//xm1014 (3000)
	-1, 	//----
	1400,	//mac10 (1400)
	3500, 	//aug (3500)
	-1, 	//----
	800, 	//elite (800)
	750, 	//fiveseven (750)
	1700, 	//ump45 (1700)
	4200, 	//sg550 (4200)
	2000,	//galil (2000)
	2250,	//famas (2250)
	500, 	//usp (500)
	400, 	//glock18 (400)
	4750, 	//awp (4750)
	1500, 	//mp5navy (1500)
	5750, 	//m249 (5750)
	1700, 	//m3 (1700)
	3100,	//m4a1 (3100)
	1250,	//tmp (1250)
	5000, 	//g3sg1 (5000)
	-1, 	//----
	650, 	//deagle (650)
	3500, 	//sg552 (3500)
	2500,	//ak47 (2500)
	-1, 	//----
	2350 	//p90 (2350)
}

// 各類子彈價格設定
new const AMMO_COST[15] =
{
//----[設定價格]//[子彈名稱][CS預設價格][使用武器種類]
	-1, 	//----
	125,	//338magnum (125) (awp)
	80,	//762nato (80) (ak47,scout,g3sg1)
	60,	//556natobox (60) (m249)
	60,	//556nato (60) (m4a1,aug,sg552,famas,sg550)
	65,	//buckshot (65) (m3,xm1014)
	25,	//45acp (25) (usp,mac10,ump45)
	45,	//57mm (45) (fiveseven,p90)
	35,	//50ae (35) (deagle)
	30,	//357sig (30) (p228)
	20,	//9mm (20) (glock18,elite,mp5navy,tmp)
	-1,	//----
	-1,	//----
	-1,	//----
	-1	//----
}

// 護甲設定
const ARMOR_VESTHELM_COST = 1000//護甲價格
const MAX_ARMOR_VALUE = 500	//人類可以擁有的護甲最大數值

// 投擲彈設定
const FIRE_GRENADE_COST = 300	//火焰彈價格
const FROST_GRENADE_COST = 200	//冰凍彈價格
const FLARE_GRENADE_COST =  300	//照明彈價格
const MAX_FIRE_VALUE = 3	//玩家可以持有的火焰彈最大數量
const MAX_FROST_VALUE = 3	//玩家可以持有的冷凍彈最大數量
const MAX_FLARE_VALUE = 5	//玩家可以持有的照明彈最大數量

// 夜視鏡設定
const NIGHT_VISION_COST = 1250 //夜視鏡的價格

///////////////////////////////////////////////////////////////////
// Variables                                                     //
///////////////////////////////////////////////////////////////////
new g_has_custom_model[33], g_player_model[33][33], bool:g_zombie[33], bool:g_boss[33], g_survivor_class[33], g_user_kill[33],
bool:g_set_user_kill[33], g_zombie_respawn_count[33], g_survivor_respawn_count[33], Float:g_spawn_time[33], Float:g_user_maxspeed[33],
bool:g_burning[33], bool:g_frozen[33], Float:g_lastleaptime[33], g_nvg_enabled[33], bool:g_give_nvg[33]

new g_fwPrecacheSound
new g_bossSprite, g_trailSprite, g_exploSprite, g_fireSprite, g_smokeSprite, g_glassSprite
new g_msgDamage, g_msgScreenShake, g_msgScreenFade, g_msgNVGToggle, g_msgCrosshair, g_msgAmmoPickup
new g_maxplayers, g_hudSync, g_hudSync2, g_hudSync3
new g_fwSpawn
new g_total_spawn = 0
new Float:g_spawn_vec[60][3]
new Float:g_spawn_angle[60][3]
new Float:g_spawn_v_angle[60][3]
new Float:g_vec_last_origin[33][3]
new bool:g_first_spawn[33]
new bool:g_can_random_spawn
new Float:g_will_respawn_time[33]
new bool:g_game_restart
new bool:g_roundend
new bool:g_freeze_time
new bool:g_only_one_survivor
new g_newround
new g_level
new g_zombie_respawns
new g_zombie_health
new Float:g_zombie_maxspeed
new g_boss_health
new Float:g_boss_maxspeed
new g_currentweapon[33] // current weapon the player is holding
new bot_add
new g_botslots
new g_bot_slotsadded = false
new Float:g_roundstart_time
new Float:g_models_target_time

// Bot Support(PBOT&ZBOT Only)
new cvar_botquota, cvar_pbotquota
new bool:BotHasDebug

//Get TSpawnPoint
new g_SpawnT

//Zombie's HP Bar
new g_playerbar[64]
new Float:g_playerMaxHealth[64]

///////////////////////////////////////////////////////////////////
// Downloads                                                     //
///////////////////////////////////////////////////////////////////
public plugin_precache()
{
	new i
	for (i = 0; i < sizeof SOUND_AMBIENCE; i++)
		PrecacheSound(SOUND_AMBIENCE[i])
	for (i = 0; i < sizeof SOUND_AMBIENCE_BOSS; i++)
		PrecacheSound(SOUND_AMBIENCE_BOSS[i])
	for (i = 0; i < sizeof SOUND_ZOMBIE_MISS_SLASH; i++)
		precache_sound(SOUND_ZOMBIE_MISS_SLASH[i])
	for (i = 0; i < sizeof SOUND_ZOMBIE_MISS_WALL; i++)
		precache_sound(SOUND_ZOMBIE_MISS_WALL[i])
	for (i = 0; i < sizeof SOUND_ZOMBIE_HIT_NORMAL; i++)
		precache_sound(SOUND_ZOMBIE_HIT_NORMAL[i])
	for (i = 0; i < sizeof SOUND_ZOMBIE_HIT_STAB; i++)
		precache_sound(SOUND_ZOMBIE_HIT_STAB[i])
	for (i = 0; i < sizeof SOUND_ZOMBIE_PAIN; i++)
		precache_sound(SOUND_ZOMBIE_PAIN[i])
	for (i = 0; i < sizeof SOUND_BOSS_PAIN; i++)
		precache_sound(SOUND_BOSS_PAIN[i])
	for (i = 0; i < sizeof SOUND_ZOMBIE_DIE; i++)
		precache_sound(SOUND_ZOMBIE_DIE[i])
	for (i = 0; i < sizeof SOUND_FIRE_PLAYER_SCREAM; i++)
		precache_sound(SOUND_FIRE_PLAYER_SCREAM[i])

	precache_sound(SOUND_SURVIVOR_WIN)
	precache_sound(SOUND_ZOMBIE_WIN)
	precache_sound(SOUND_DRAW)
	precache_sound(SOUND_EAT_BRAIN)
	precache_sound(SOUND_BOSS_BEACON)
	precache_sound(SOUND_FIRE_EXPLODE)
	precache_sound(SOUND_FROST_EXPLODE)
	precache_sound(SOUND_FLARE_ON)
	precache_sound(SOUND_FROST_PLAYER)
	precache_sound(SOUND_FROST_BREAK)
	precache_sound(SOUND_TURN_NVG_ON)
	precache_sound(SOUND_TURN_NVG_OFF)
	precache_sound(SOUND_PICK_GRENADE)
	precache_sound(SOUND_PICK_AMMO)
	precache_sound(SOUND_PICK_ARMOR)

	for (i = 0; i < sizeof MODEL_HUMAN; i++)
	{
		PrecachePlayerModel(MODEL_HUMAN[i])
	}

	for (i = 0; i < sizeof MODEL_ZOMBIE; i++)
	{
		PrecachePlayerModel(MODEL_ZOMBIE[i])
	}

	for (i = 0; i < sizeof MODEL_ZOMBIE_BOSS; i++)
	{
		PrecachePlayerModel(MODEL_ZOMBIE_BOSS[i])
	}

	engfunc(EngFunc_PrecacheModel, model_vknife_zombie)
	engfunc(EngFunc_PrecacheModel, model_vknife_boss)
	engfunc(EngFunc_PrecacheModel, model_grenade_fire)
	engfunc(EngFunc_PrecacheModel, model_grenade_frost)
	engfunc(EngFunc_PrecacheModel, model_grenade_flare)
	engfunc(EngFunc_PrecacheModel, healthbar_spr)
	g_glassSprite = precache_model("models/glassgibs.mdl")
	g_bossSprite = precache_model("sprites/zh_beacon.spr")
	g_trailSprite = precache_model("sprites/laserbeam.spr")
	g_exploSprite = precache_model("sprites/shockwave.spr")
	g_fireSprite = precache_model("sprites/flame.spr")
	g_smokeSprite = precache_model("sprites/black_smoke3.spr")

	#if defined AMBIENCE_RAIN
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	#endif

	#if defined AMBIENCE_SNOW
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))
	#endif

	#if defined AMBIENCE_FOG
	new fog = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
	if (pev_valid(fog))
	{
		fm_set_kvd(fog, "density", FOG_DENSITY, "env_fog")
		fm_set_kvd(fog, "rendercolor", FOG_COLOR, "env_fog")
	}
	#endif

	// Prevent some entities from spawning
	g_fwSpawn = register_forward(FM_Spawn, "forward_spawn")
	g_fwPrecacheSound = register_forward(FM_PrecacheSound, "fw_PrecacheSound")
}

public fw_PrecacheSound(const sound[])
{
	// Block all those unneeeded hostage sounds
	if (equal(sound, "hostage", 7))
		return FMRES_SUPERCEDE;
	return FMRES_IGNORED;
}

PrecacheSound(const sound[])
{
	new temp[100]
	if (equali(sound[strlen(sound) - 4], ".mp3"))
	{
		formatex(temp, charsmax(temp), "sound/%s", sound)
		precache_generic(temp)
	}
	else
	{
		precache_sound(sound)
	}
}

PrecachePlayerModel(const model[])
{
	new temp[100]
	format(temp, charsmax(temp), "models/player/%s/%s.mdl", model, model)
	precache_model(temp)
}

///////////////////////////////////////////////////////////////////
// Plugin Start                                                  //
///////////////////////////////////////////////////////////////////
public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_dictionary("zombiehell.txt")
	cvar_map_time = register_cvar("zh_nextmap_time", "5.0")			//通過10關考驗後地圖轉換的延遲時間(單位:秒)
	cvar_level = register_cvar("zh_zombie_level", "1")		 	//開始進行遊戲的關卡等級[1~10]
	cvar_cvar_zombiebar = register_cvar("zh_zombie_hpbar", "1")		//殭屍血條是否開啟
	cvar_zombie_random = register_cvar("zh_zombie_random", "1")		//殭屍素質(血量 護甲 速度...等)是否會隨機變化
	cvar_armor_protect = register_cvar("zh_armor_protect", "1")		//當人類護甲被打完時,才會開始扣血量
	cvar_zombie_scores = register_cvar("zh_zombie_scores", "1")		//顯示殺死殭屍時的擊殺評語
	cvar_zatk = register_cvar("zh_zombie_atk", "1.1")			//殭屍攻擊力加乘(X.0 = 攻擊力X倍)
	cvar_zombie_knife = register_cvar("zh_zombie_onehitkill", "0") 	 	//殭屍是否有一擊死的能力
	cvar_zombiearmor = register_cvar("zh_zombie_armor", "100")		//是否給予殭屍護甲(預設100=100x關卡數)
	cvar_zombieappear = register_cvar("zh_zombie_appeartime", "3.0")	//玩家進入遊戲幾秒後才開始加入殭屍(單位:秒)
	//cvar_bot_type = register_cvar("zh_bot_type", "1") 			//選擇BOT種類(1=PBOT/2=ZBOT)
	cvar_zombie_maxslots = register_cvar("zh_zombie_maxslots", "0") 	//加入多少BOT當殭屍(預設0=自動取得當前地圖的T重生點總數-X(X=預留1~3個空位以防止快速重生時出現SpawnKill))
	cvar_zombie_effect = register_cvar("zh_zombie_effect", "0")		//開啟殭屍死亡時和重生時的特效[1=開啟/0=關閉]
	cvar_zombie_spawnpoint = register_cvar("zh_zombie_spawnpoint", "1")	//殭屍死亡後,重生時是否會隨機重生[1=載入CSDM重生點隨機重生/2=不載入CSDM重生點正常重生]
	cvar_zombie_respawn_delay = register_cvar("zh_zombie_respawn_delay", "1.0")	//殭屍的重生的延遲時間(單位:秒)
	cvar_zombie_protect = register_cvar("zh_zombie_protect", "0.0")		//開啟殭屍重生防護(單位:秒)[0.0=無防護(設1.0就是1秒,以此類推)]
	cvar_render_zr = register_cvar("zh_render_zr", "255")			//殭屍重生防護顏色(R)
	cvar_render_zg = register_cvar("zh_render_zg", "0")			//殭屍重生防護顏色(G)
	cvar_render_zb = register_cvar("zh_render_zb", "0")			//殭屍重生防護顏色(B)
	cvar_zombieheal = register_cvar("zh_zombie_heal", "500")		//殭屍每殺死一位人類可以獲得多少血量
	cvar_zombiekill_bonus = register_cvar("zh_zombiekill_bonus","75")	//人類每殺死一隻殭屍可以額外獲得多少錢(底薪, 過一關翻一倍XD)[0 = 只會獲得預設殺敵獎金300]
	cvar_bosskill_bonus = register_cvar("zh_bosskill_bonus", "5000")	//殺死殭屍王的人類玩家可以額外獲得多少錢做為獎勵(底薪, 過一關翻一倍XD)[0 = 只會獲得預設殺敵獎金300]
	cvar_bot_giveweap = register_cvar("zh_bot_give_weapon", "3")		//人類BOT重生時是否自動給予武器[0=關閉/1=只給主武/2=只給副武/3=全部給]
	cvar_survivor_giveweap = register_cvar("zh_survivor_give_weapon", "3")	//人類重生時是否自動給予武器[0=關閉/1=只給主武/2=只給副武/3=全部給]
	cvar_survivor_ulammo = register_cvar("zh_survivor_unlimited_ammo", "0")	//人類的有無限的備用子彈[1=開啟/0=關閉]
	cvar_survivor_buyzone = register_cvar("zh_survivor_buyzone", "1")	//開啟人類購買區域限制(只能在購買區購買裝備)[1=開啟/0=關閉]
	cvar_survivor_respawn = register_cvar("zh_survivor_respawn", "1")	//開啟人類重生[1=開啟/0=關閉]
	cvar_survivor_respawn_delay = register_cvar("zh_survivor_respawn_delay", "15.0") //人類重生間隔時間(單位:秒)
	cvar_survivor_respawns = register_cvar("zh_survivor_respawns", "0")	//人類的重生次數(預設0為不限制次數)
	cvar_survivor_protect = register_cvar("zh_survivor_protect", "5.0")	//開啟人類重生防護[0.0=無防護 預設5.0=5秒]
	cvar_render_ctr = register_cvar("zh_render_ctr", "255")			//人類重生防護顏色(R)
	cvar_render_ctg = register_cvar("zh_render_ctg", "255")			//人類重生防護顏色(G)
	cvar_render_ctb = register_cvar("zh_render_ctb", "255")			//人類重生防護顏色(B)
	cvar_fire_duration = register_cvar("zh_fire_duration", "10.0")		//火焰彈的燃燒時間(單位:秒)
	cvar_fire_damage = register_cvar("zh_fire_damage", "5")			//火焰彈造成的傷害數值
	cvar_fire_damagemul = register_cvar("zh_fire_damagemul", "1.0")		//火焰彈燃燒傷害間隔(單位:秒)
	cvar_fire_slowdown = register_cvar("zh_fire_slowdown", "0.8")		//火焰彈造成的傷害時的速度減緩乘數(每0.1秒)(設定成0.0代表不會減緩速度)
	cvar_freeze_duration = register_cvar("zh_freeze_duration", "5.0") 	//冰凍彈的凍結時間(單位:秒)
	cvar_flare_duration = register_cvar("zh_flare_duration", "100.0")	//照明彈的照明時間(單位秒)
	cvar_flare_color = register_cvar("zh_flare_color", "4")			//照明彈光照顏色 [0=白/1=紅/2=綠/3=藍/4=隨機顏色/5=隨機選定 紅,綠,藍/6=自訂顏色]
	cvar_flare_rgb = register_cvar("zh_flare_rgb", "150 200 255")		//照明彈光照顏色,自訂{R.G.B}設定值
	cvar_flare_size = register_cvar("zh_flare_size", "50")			//照明彈的照明範圍(半徑距離)
	cvar_remove_weapon_time = register_cvar("zh_remove_weapon_time", "10.0")//移除掉落在地上的武器的延遲時間(單位:秒)(設定成0.0代表不移除武器)
	cvar_boss_knife = register_cvar("zh_boss_onehitkill", "1")		//殭屍王是否有一擊死的能力
	cvar_batk = register_cvar("zh_boss_atk", "1.5")			//殭屍王攻擊力加乘(X.0 = 攻擊力X倍)
	cvar_boss_dmg_multiplier = register_cvar("zh_boss_dmg_multiplier", "0.8")//殭屍王遭受攻擊時所受到的傷害減少乘數(設定成0.0代表不作用)
	cvar_boss_leap = register_cvar("zh_boss_leap", "0")			//殭屍王可使用長跳[1=開啟/0=關閉]
	cvar_leap_cooldown = register_cvar("zh_leap_cooldown", "10.0") 		//長跳的冷卻時間(單位:秒)
	cvar_leap_force = register_cvar("zh_leap_force", "500") 		//長跳的跳躍距離
	cvar_leap_height = register_cvar("zh_leap_height", "300")		//長跳的跳躍高度
	cvar_custom_nvg = register_cvar("zh_custom_nvg", "1")			//使用自訂夜視鏡效果[1=開啟/0=關閉]
	cvar_nvg_color = register_cvar("zh_nvg_color", "0 250 255")		//自訂夜視鏡光線顏色{R.G.B}設定值
	cvar_nvg_size = register_cvar("zh_nvg_size", "1000")			//自訂夜視鏡光線照射範圍距離
	cvar_maxmoney = register_cvar("zh_maxmoney", "99999")			//人類金錢上限(需配合金錢上限破解使用)
	cvar_lockfrdkill = register_cvar("zh_friendlyfire_lock","0")		//是否開啟強制封鎖隊友傷害
	cvar_final_secret = register_cvar("zh_final_secret","1")		//是否隱藏最後一關的資訊
	cvar_removedoors = register_cvar("zh_remove_doors", "3")		//是否移除地圖裡的門[0-不移除 // 1-移除普通門 // 2-移除旋轉門 // 3-移除全部的門]
	cvar_level1_respawns = register_cvar("zh_level1_respawns", "")
	cvar_level1_health = register_cvar("zh_level1_health", "")
	cvar_level1_maxspeed = register_cvar("zh_level1_maxspeed", "")
	cvar_level1_bosshp = register_cvar("zh_level1_bosshp", "")
	cvar_level1_bossmaxspeed = register_cvar("zh_level1_bossmaxspeed", "")
	cvar_level1_lighting = register_cvar("zh_level1_lighting", "")
	cvar_level2_respawns = register_cvar("zh_level2_respawns", "")
	cvar_level2_health = register_cvar("zh_level2_health", "")
	cvar_level2_maxspeed = register_cvar("zh_level2_maxspeed", "")
	cvar_level2_bosshp = register_cvar("zh_level2_bosshp", "")
	cvar_level2_bossmaxspeed = register_cvar("zh_level2_bossmaxspeed", "")
	cvar_level2_lighting = register_cvar("zh_level2_lighting", "")
	cvar_level3_respawns = register_cvar("zh_level3_respawns", "")
	cvar_level3_health = register_cvar("zh_level3_health", "")
	cvar_level3_maxspeed = register_cvar("zh_level3_maxspeed", "")
	cvar_level3_bosshp = register_cvar("zh_level3_bosshp", "")
	cvar_level3_bossmaxspeed = register_cvar("zh_level3_bossmaxspeed", "")
	cvar_level3_lighting = register_cvar("zh_level3_lighting", "")
	cvar_level4_respawns = register_cvar("zh_level4_respawns", "")
	cvar_level4_health = register_cvar("zh_level4_health", "")
	cvar_level4_maxspeed = register_cvar("zh_level4_maxspeed", "")
	cvar_level4_bosshp = register_cvar("zh_level4_bosshp", "")
	cvar_level4_bossmaxspeed = register_cvar("zh_level4_bossmaxspeed", "")
	cvar_level4_lighting = register_cvar("zh_level4_lighting", "")
	cvar_level5_respawns = register_cvar("zh_level5_respawns", "")
	cvar_level5_health = register_cvar("zh_level5_health", "")
	cvar_level5_maxspeed = register_cvar("zh_level5_maxspeed", "")
	cvar_level5_bosshp = register_cvar("zh_level5_bosshp", "")
	cvar_level5_bossmaxspeed = register_cvar("zh_level5_bossmaxspeed", "")
	cvar_level5_lighting = register_cvar("zh_level5_lighting", "")
	cvar_level6_respawns = register_cvar("zh_level6_respawns", "")
	cvar_level6_health = register_cvar("zh_level6_health", "")
	cvar_level6_maxspeed = register_cvar("zh_level6_maxspeed", "")
	cvar_level6_bosshp = register_cvar("zh_level6_bosshp", "")
	cvar_level6_bossmaxspeed = register_cvar("zh_level6_bossmaxspeed", "")
	cvar_level6_lighting = register_cvar("zh_level6_lighting", "")
	cvar_level7_respawns = register_cvar("zh_level7_respawns", "")
	cvar_level7_health = register_cvar("zh_level7_health", "")
	cvar_level7_maxspeed = register_cvar("zh_level7_maxspeed", "")
	cvar_level7_bosshp = register_cvar("zh_level7_bosshp", "")
	cvar_level7_bossmaxspeed = register_cvar("zh_level7_bossmaxspeed", "")
	cvar_level7_lighting = register_cvar("zh_level7_lighting", "")
	cvar_level8_respawns = register_cvar("zh_level8_respawns", "")
	cvar_level8_health = register_cvar("zh_level8_health", "")
	cvar_level8_maxspeed = register_cvar("zh_level8_maxspeed", "")
	cvar_level8_bosshp = register_cvar("zh_level8_bosshp", "")
	cvar_level8_bossmaxspeed = register_cvar("zh_level8_bossmaxspeed", "")
	cvar_level8_lighting = register_cvar("zh_level8_lighting", "")
	cvar_level9_respawns = register_cvar("zh_level9_respawns", "")
	cvar_level9_health = register_cvar("zh_level9_health", "")
	cvar_level9_maxspeed = register_cvar("zh_level9_maxspeed", "")
	cvar_level9_bosshp = register_cvar("zh_level9_bosshp", "")
	cvar_level9_bossmaxspeed = register_cvar("zh_level9_bossmaxspeed", "")
	cvar_level9_lighting = register_cvar("zh_level9_lighting", "")
	cvar_level10_respawns = register_cvar("zh_level10_respawns", "")
	cvar_level10_health = register_cvar("zh_level10_health", "")
	cvar_level10_maxspeed = register_cvar("zh_level10_maxspeed", "")
	cvar_level10_bosshp = register_cvar("zh_level10_bosshp", "")
	cvar_level10_bossmaxspeed = register_cvar("zh_level10_bossmaxspeed", "")
	cvar_level10_lighting = register_cvar("zh_level10_lighting", "")
	register_clcmd("jointeam", "cmd_jointeam")
	register_clcmd("nightvision", "cmd_nightvision")
	register_clcmd("buy", "cmd_buy")
	register_clcmd("chooseteam", "cmd_chooseteam")
	register_clcmd("buyequip", "cmd_buyequip")
	register_clcmd("buyammo1", "cmd_buyammo1")
	register_clcmd("buyammo2", "cmd_buyammo2")
	register_clcmd("primammo", "cmd_primammo")
	register_clcmd("secammo", "cmd_secammo")
	register_event("WeapPickup", "event_weap_pickup", "be")
	register_event("AmmoX", "event_check_bpammo", "be", "1=1", "1=2", "1=3", "1=4", "1=5", "1=6", "1=7", "1=8", "1=9", "1=10")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("ResetHUD", "event_resethud", "be")
	register_event("DeathMsg", "event_death", "a")
	register_event("Health", "event_health", "be")
	register_logevent("logevent_round_start", 2, "1=Round_Start")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_WeaponCleaner")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	register_forward(FM_SetClientKeyValue, "fw_ClientKey")
	register_forward(FM_ClientUserInfoChanged, "fw_ClientInfo")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_AddToFullPack, "fm_addtofullpack_post", 1)
	g_msgDamage = get_user_msgid("Damage")
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgNVGToggle = get_user_msgid("NVGToggle")
	g_msgCrosshair = get_user_msgid("Crosshair")
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	unregister_forward(FM_PrecacheSound, g_fwPrecacheSound)
	unregister_forward(FM_Spawn, g_fwSpawn)
	register_message(get_user_msgid("SendAudio"), "message_SendAudio")
	register_message(get_user_msgid("TeamInfo"), "message_TeamInfo")
	register_message(g_msgNVGToggle, "message_NVGToggle")
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
	register_message(get_user_msgid("Money"), "message_Money")
	register_message(get_user_msgid("Health"), "message_Health")
	register_message(get_user_msgid("RoundTime"), "message_RoundTime")
	register_message(get_user_msgid("HideWeapon"), "message_HideWeapon")

	#if !defined DONT_CHANGE_SKY
	// Set a random skybox
	set_cvar_string("sv_skyname", SKY_NAMES[random_num(0, sizeof SKY_NAMES - 1)])
	#endif

	// Disable sky lighting so it doesn't mess with our custom lighting
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)

	// Set display hud level information task
	g_level = 0 // Prevent show invalid level information (bugfix)
	set_task(0.1, "show_level_hud", _, _, _, "b")
	TSpawns_Count()
	csdm_respawn()
	g_maxplayers = get_maxplayers()
	g_hudSync = CreateHudSyncObj()
	g_hudSync2 = CreateHudSyncObj()
	g_hudSync3 = CreateHudSyncObj()
	register_message(get_user_msgid("TextMsg"), "message_TextMsg")

	// Bot support
	server_cmd("pb_mapstartbotdelay 0.1")
	server_cmd("pb_minbots 0")
	server_cmd("pb_maxbots 0")
	server_cmd("pb_bot_quota_match 0")
	server_cmd("pb_chat 0")
	server_cmd("pb_spray 0")
	server_cmd("pb_dangerfactor 0")
	cvar_botquota = get_cvar_pointer("bot_quota")
	cvar_pbotquota = get_cvar_pointer("pb_bot_quota_match")

	// Check config files is exists. If not exists then create the files.
	new ConfigDir[128], ConfigFile[192], LevelConfigFile[192]
	get_configsdir(ConfigDir, charsmax(ConfigDir))
	formatex(ConfigFile, charsmax(ConfigFile), "%s/zombiehell.cfg", ConfigDir)
	formatex(LevelConfigFile, charsmax(LevelConfigFile), "%s/zombiehell_levels.cfg", ConfigDir)
	if (!file_exists(ConfigFile))
		create_config_file(ConfigFile)

	if (!file_exists(LevelConfigFile))
		create_level_config_file(LevelConfigFile)

	// Set up game start settings
	server_cmd("mp_limitteams 0")
	server_cmd("mp_autoteambalance 0")
	server_cmd("sv_maxspeed 10000")

	// Set up config files
	server_cmd("exec addons/amxmodx/configs/zombiehell.cfg")
	server_cmd("exec addons/amxmodx/configs/zombiehell_levels.cfg")

	// Bot support
	bot_cfg()

	//Make Zombie's Hp Bar
	make_healthbar()
}

///////////////////////////////////////////////////////////////////
// Create Config File Function                                   //
///////////////////////////////////////////////////////////////////
create_config_file(const FilePatch[])
{
	new FileHandle = fopen(FilePatch, "w")
	if (!FileHandle)
	{
		log_amx("[Zombie Hell] Debug: Create config file ^"%s^" failed!", FilePatch)
		return;
	}
	fputs(FileHandle, "////////////////////////////////////////////////////////////////////////////^n")
	fputs(FileHandle, "////////////////////////Zombie Hell 2.0Z Config File////////////////////////^n")
	fputs(FileHandle, "////////////////////////////////////////////////////////////////////////////^n")
	fputs(FileHandle, "zh_nextmap_time 5.0            //通過10關考驗後地圖轉換的延遲時間(單位:秒)^n")
	fputs(FileHandle, "zh_zombie_spawnpoint 1         //殭屍死亡後,重生時是否會隨機重生[1=載入CSDM重生點隨機重生/2=不載入CSDM重生點正常重生]^n")
	fputs(FileHandle, "zh_zombie_onehitkill 0         //殭屍是否有一擊死的能力[0=關閉/1=開啟]^n")
	fputs(FileHandle, "zh_zombie_atk 1.0              //殭屍攻擊力加乘(X.0 = 攻擊力X倍)^n")
	fputs(FileHandle, "zh_zombie_armor 100            //是否給予殭屍護甲(預設100 = 100x關卡數)^n")
	fputs(FileHandle, "zh_zombie_appeartime 3.0       //玩家進入遊戲幾秒後才開始加入殭屍(單位:秒)^n")
	fputs(FileHandle, "zh_zombie_maxslots 0           //加入多少BOT當殭屍(預設0=自動取得當前地圖的T重生點總數-X(X=根據總數數量隨機預留數個空位以防止人數過多及SpawnKill)^n")
	fputs(FileHandle, "zh_bot_type 1                  //選擇BOT種類[1=PBOT/2=ZBOT]^n")
	fputs(FileHandle, "zh_zombie_hpbar 1              //殭屍血條是否開啟^n")
	fputs(FileHandle, "zh_zombie_effect 0             //開啟殭屍死亡時和重生時的特效[1=開啟/0=關閉]^n")
	fputs(FileHandle, "zh_zombie_level 1              //開始進行遊戲的關卡等級[1~10]^n")
	fputs(FileHandle, "zh_zombie_random 1             //殭屍素質(血量 護甲 速度...等)是否會隨機變化^n")
	fputs(FileHandle, "zh_zombie_respawn_delay 0.5    //殭屍的重生的延遲時間(單位:秒)[0.0=無防護]^n")
	fputs(FileHandle, "zh_zombie_protect 0.0          //開啟殭屍重生防護(X.0 = X秒)^n")
	fputs(FileHandle, "zh_render_zr 255               //殭屍重生防護顏色(R)^n")
	fputs(FileHandle, "zh_render_zg 0                 //殭屍重生防護顏色(G)^n")
	fputs(FileHandle, "zh_render_zb 0                 //殭屍重生防護顏色(B)^n")
	fputs(FileHandle, "zh_zombie_heal 500             //殭屍每擊殺一位人類可以增加多少血量^n")
	fputs(FileHandle, "zh_zombie_scores 1             //顯示殺死殭屍時的擊殺評語^n")
	fputs(FileHandle, "zh_zombiekill_bonus 75         //玩家每幹掉一隻殭屍可以額外獲得多少錢(底薪, 每過一關加一倍XD)[0 = 只會獲得預設殺敵獎金300]^n")
	fputs(FileHandle, "zh_bosskill_bonus 5000         //玩家幹掉殭屍王可以獲得多少獎勵金(底薪, 每過一關加一倍XD)[0 = 只會獲得預設殺敵獎金300]^n")
	fputs(FileHandle, "zh_bot_give_weapon 3           //人類BOT重生時是否自動給予武器[0=關閉/1=只給主武/2=只給副武/3=全部給]^n")
	fputs(FileHandle, "zh_survivor_give_weapon 3      //人類重生時是否自動給予武器[0=關閉/1=只給主武/2=只給副武/3=全部給]^n")
	fputs(FileHandle, "zh_survivor_unlimited_ammo 0   //人類是否有無限備彈[1=開啟/0=關閉]^n")
	fputs(FileHandle, "zh_survivor_buyzone 1          //開啟人類購買區域限制(只能在購買區購買裝備)[1=開啟/0=關閉]^n")
	fputs(FileHandle, "zh_maxmoney 99999              //人類金錢上限(需配合金錢上限破解使用)^n")
	fputs(FileHandle, "zh_survivor_respawn 1          //開啟人類重生[1=開啟/0=關閉]^n")
	fputs(FileHandle, "zh_survivor_respawn_delay 15.0 //人類重生間隔時間(單位:秒)^n")
	fputs(FileHandle, "zh_survivor_respawns 0         //人類的重生次數(設定成0代表不限制次數)^n")
	fputs(FileHandle, "zh_survivor_protect 5.0        //開啟人類重生防護(X.0 = X秒)[0.0=無防護]^n")
	fputs(FileHandle, "zh_render_ctr 255              //人類重生防護顏色(R)^n")
	fputs(FileHandle, "zh_render_ctg 255              //人類重生防護顏色(G)^n")
	fputs(FileHandle, "zh_render_ctb 255              //人類重生防護顏色(B)^n")
	fputs(FileHandle, "zh_fire_duration 10.0          //火焰彈的燃燒時間(單位:秒)^n")
	fputs(FileHandle, "zh_fire_damage 10              //火焰彈造成的傷害數值^n")
	fputs(FileHandle, "zh_fire_damagemul 1.0          //火焰彈燃燒傷害間隔(單位:秒)^n")
	fputs(FileHandle, "zh_fire_slowdown 0.8           //火焰彈造成的傷害時的速度減緩乘數(每隔0.1秒)(設定成0.0代表不會減緩速度)^n")
	fputs(FileHandle, "zh_freeze_duration 5.0         //冰凍彈的凍結時間(單位:秒)^n")
	fputs(FileHandle, "zh_flare_duration 100.0        //照明彈的照明時間(單位秒)^n")
	fputs(FileHandle, "zh_flare_color 4               //照明彈光照顏色 [0=白/1=紅/2=綠/3=藍/4=隨機顏色/5=隨機選定 紅,綠,藍/6=自訂顏色]^n")
	fputs(FileHandle, "zh_flare_rgb ^"200 255 200^"     //照明彈光照顏色,自訂{R.G.B}設定值^n")
	fputs(FileHandle, "zh_flare_size 50               //照明彈的照明範圍(半徑距離)^n")
	fputs(FileHandle, "zh_remove_weapon_time 10.0     //移除掉落在地上的武器的延遲時間(單位:秒)(設定成0.0代表不移除武器)^n")
	fputs(FileHandle, "zh_boss_atk 1.5                //殭屍王攻擊力加乘(X.0 = 攻擊力X倍)^n")
	fputs(FileHandle, "zh_boss_onehitkill 0           //殭屍王是否有一擊死的能力[1=開啟/0=關閉]^n")
	fputs(FileHandle, "zh_boss_dmg_multiplier 0.8     //殭屍王遭受攻擊時所受到的傷害減少乘數(設定成0.0代表不作用)^n")
	fputs(FileHandle, "zh_boss_leap 0                 //殭屍王可使用長跳[1=開啟/0=關閉]^n")
	fputs(FileHandle, "zh_leap_cooldown 10.0          //長跳的冷卻時間(單位:秒)^n")
	fputs(FileHandle, "zh_leap_force 500              //長跳的跳躍距離^n")
	fputs(FileHandle, "zh_leap_height 300             //長跳的跳躍高度^n")
	fputs(FileHandle, "zh_custom_nvg 1                //使用自訂夜視鏡效果[1=開啟/0=關閉]^n")
	fputs(FileHandle, "zh_nvg_color ^"0 250 255^"       //自訂夜視鏡光線顏色{R.G.B}設定值^n")
	fputs(FileHandle, "zh_nvg_size 1000               //自訂夜視鏡光線照射範圍距離^n")
	fputs(FileHandle, "zh_armor_protect 1             //當護甲被打完時,才會開始扣血量^n")
	fputs(FileHandle, "zh_friendlyfire_lock 0         //是否開啟強制封印隊友傷害^n")
	fputs(FileHandle, "zh_final_secret 1              //是否隱藏最後一關的資訊^n")
	fputs(FileHandle, "zh_remove_doors 3              //是否移除地圖裡的門[0-不移除 // 1-移除普通門 // 2-移除旋轉門 // 3-移除全部的門]")
	fclose(FileHandle)
}

create_level_config_file(const FilePatch[])
{
	new FileHandle = fopen(FilePatch, "w")
	if (!FileHandle)
	{
		log_amx("[Zombie Hell] Debug: Create config file ^"%s^" failed!", FilePatch)
		return;
	}
	fputs(FileHandle, "//////////////////////////////////////////////////////////////////////////////////^n")
	fputs(FileHandle, "////////////////////////Zombie Hell 2.0Z Level Config File////////////////////////^n")
	fputs(FileHandle, "//////////////////////////////////////////////////////////////////////////////////^n")
	fputs(FileHandle, "// level 1^n")
	fputs(FileHandle, "zh_level1_respawns 1                //殭屍重生的次數^n")
	fputs(FileHandle, "zh_level1_health 100                //殭屍的生命值^n")
	fputs(FileHandle, "zh_level1_maxspeed 250.0            //殭屍的速度^n")
	fputs(FileHandle, "zh_level1_bosshp 15000              //殭屍王的生命值^n")
	fputs(FileHandle, "zh_level1_bossmaxspeed 275.0        //殭屍王的速度^n")
	fputs(FileHandle, "zh_level1_lighting ^"f^"	       //地圖亮度[^"a^"最暗-^"z^"最亮]^n")
	fputs(FileHandle, "^n")
	fputs(FileHandle, "// level 2^n")
	fputs(FileHandle, "zh_level2_respawns 2^n")
	fputs(FileHandle, "zh_level2_health 200^n")
	fputs(FileHandle, "zh_level2_maxspeed 255.0^n")
	fputs(FileHandle, "zh_level2_bosshp 20000^n")
	fputs(FileHandle, "zh_level2_bossmaxspeed 280.0^n")
	fputs(FileHandle, "zh_level2_lighting ^"e^"^n")
	fputs(FileHandle, "^n")
	fputs(FileHandle, "// level 3^n")
	fputs(FileHandle, "zh_level3_respawns 3^n")
	fputs(FileHandle, "zh_level3_health 300^n")
	fputs(FileHandle, "zh_level3_maxspeed 260.0^n")
	fputs(FileHandle, "zh_level3_bosshp 30000^n")
	fputs(FileHandle, "zh_level3_bossmaxspeed 285.0^n")
	fputs(FileHandle, "zh_level3_lighting ^"d^"^n")
	fputs(FileHandle, "^n")
	fputs(FileHandle, "// level 4^n")
	fputs(FileHandle, "zh_level4_respawns 4^n")
	fputs(FileHandle, "zh_level4_health 400^n")
	fputs(FileHandle, "zh_level4_maxspeed 265.0^n")
	fputs(FileHandle, "zh_level4_bosshp 40000^n")
	fputs(FileHandle, "zh_level4_bossmaxspeed 290.0^n")
	fputs(FileHandle, "zh_level4_lighting ^"c^"^n")
	fputs(FileHandle, "^n")
	fputs(FileHandle, "// level 5^n")
	fputs(FileHandle, "zh_level5_respawns 5^n")
	fputs(FileHandle, "zh_level5_health 500^n")
	fputs(FileHandle, "zh_level5_maxspeed 275.0^n")
	fputs(FileHandle, "zh_level5_bosshp 50000^n")
	fputs(FileHandle, "zh_level5_bossmaxspeed 300.0^n")
	fputs(FileHandle, "zh_level5_lighting ^"b^"^n")
	fputs(FileHandle, "^n")
	fputs(FileHandle, "// level 6^n")
	fputs(FileHandle, "zh_level6_respawns 6^n")
	fputs(FileHandle, "zh_level6_health 600^n")
	fputs(FileHandle, "zh_level6_maxspeed 280.0^n")
	fputs(FileHandle, "zh_level6_bosshp 70000^n")
	fputs(FileHandle, "zh_level6_bossmaxspeed 305.0^n")
	fputs(FileHandle, "zh_level6_lighting ^"c^"^n")
	fputs(FileHandle, "^n")
	fputs(FileHandle, "// level 7^n")
	fputs(FileHandle, "zh_level7_respawns 7^n")
	fputs(FileHandle, "zh_level7_health 750^n")
	fputs(FileHandle, "zh_level7_maxspeed 285.0^n")
	fputs(FileHandle, "zh_level7_bosshp 80000^n")
	fputs(FileHandle, "zh_level7_bossmaxspeed 310.0^n")
	fputs(FileHandle, "zh_level7_lighting ^"d^"^n")
	fputs(FileHandle, "^n")
	fputs(FileHandle, "// level 8^n")
	fputs(FileHandle, "zh_level8_respawns 8^n")
	fputs(FileHandle, "zh_level8_health 850^n")
	fputs(FileHandle, "zh_level8_maxspeed 290.0^n")
	fputs(FileHandle, "zh_level8_bosshp 100000^n")
	fputs(FileHandle, "zh_level8_bossmaxspeed 315.0^n")
	fputs(FileHandle, "zh_level8_lighting ^"c^"^n")
	fputs(FileHandle, "^n")
	fputs(FileHandle, "// level 9^n")
	fputs(FileHandle, "zh_level9_respawns 9^n")
	fputs(FileHandle, "zh_level9_health 1000^n")
	fputs(FileHandle, "zh_level9_maxspeed 300.0^n")
	fputs(FileHandle, "zh_level9_bosshp 500000^n")
	fputs(FileHandle, "zh_level9_bossmaxspeed 325.0^n")
	fputs(FileHandle, "zh_level9_lighting ^"b^"^n")
	fputs(FileHandle, "^n")
	fputs(FileHandle, "// level 10^n")
	fputs(FileHandle, "zh_level10_respawns 10^n")
	fputs(FileHandle, "zh_level10_health 1500^n")
	fputs(FileHandle, "zh_level10_maxspeed 325.0^n")
	fputs(FileHandle, "zh_level10_bosshp 1000000^n")
	fputs(FileHandle, "zh_level10_bossmaxspeed 350.0^n")
	fputs(FileHandle, "zh_level10_lighting ^"a^"^n")
	fclose(FileHandle)
}

///////////////////////////////////////////////////////////////////
// Replace Zombie's Sound					 //
///////////////////////////////////////////////////////////////////
// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Replace these sounds for zombies only
	if (!is_user_connected(id) || (cs_get_user_team(id) != CS_TEAM_T))
		return FMRES_IGNORED;

	// Zombie being hit
	if (equal(sample[7], "bhit", 4))
	{
		if (g_boss[id])
			engfunc(EngFunc_EmitSound, id, channel, SOUND_BOSS_PAIN[random_num(0, sizeof SOUND_BOSS_PAIN-1)], volume, attn, flags, pitch)
		else
			engfunc(EngFunc_EmitSound, id, channel, SOUND_ZOMBIE_PAIN[random_num(0, sizeof SOUND_ZOMBIE_PAIN-1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}

	// Zombie attacks with knife
	if (equal(sample[8], "kni", 3))
	{
		if (equal(sample[14], "sla", 3)) // slash
		{
			engfunc(EngFunc_EmitSound, id, channel, SOUND_ZOMBIE_MISS_SLASH[random_num(0, sizeof SOUND_ZOMBIE_MISS_SLASH-1)], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}

		if (equal(sample[14], "hit", 3))
		{
			if (sample[17] == 'w') // wall
			{
				engfunc(EngFunc_EmitSound, id, channel, SOUND_ZOMBIE_MISS_WALL[random_num(0, sizeof SOUND_ZOMBIE_MISS_WALL-1)], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			else // hit
			{
				engfunc(EngFunc_EmitSound, id, channel, SOUND_ZOMBIE_HIT_NORMAL[random_num(0, sizeof SOUND_ZOMBIE_HIT_NORMAL-1)], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}

		if (equal(sample[14], "sta", 3)) // stab
		{
			engfunc(EngFunc_EmitSound, id, channel, SOUND_ZOMBIE_HIT_STAB[random_num(0, sizeof SOUND_ZOMBIE_HIT_STAB-1)], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}

	// Zombie dies
	if (equal(sample[7], "die", 3) || equal(sample[7], "dea", 3))
	{
		engfunc(EngFunc_EmitSound, id, channel, SOUND_ZOMBIE_DIE[random_num(0, sizeof SOUND_ZOMBIE_DIE-1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}

	// Zombie falls off
	if (equal(sample[10], "fall", 4))
	{
		engfunc(EngFunc_EmitSound, id, channel, SOUND_ZOMBIE_PAIN[random_num(0, sizeof SOUND_ZOMBIE_PAIN-1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}

	// Block Unneeded sound to save some memory
	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;
	return FMRES_IGNORED;
}

///////////////////////////////////////////////////////////////////
// Plugin Cfg	                                                 //
///////////////////////////////////////////////////////////////////
public plugin_cfg()
{
	set_task(1.0, "event_round_start")
}

///////////////////////////////////////////////////////////////////
// Remove Weapon Entities                                        //
///////////////////////////////////////////////////////////////////
public fw_WeaponCleaner(entity)
{
	fm_call_think(entity)
}

///////////////////////////////////////////////////////////////////
// Zombie Can't Pick Up Weapon                                   //
///////////////////////////////////////////////////////////////////
public fw_TouchWeapon(weapon, id)
{
	// Not a player
	if (!is_user_connected(id) || !is_user_alive(id))
		return HAM_IGNORED;

	// Dont pickup weapons if player is zombie
	if (cs_get_user_team(id) != CS_TEAM_CT)
		return HAM_SUPERCEDE;
	return HAM_IGNORED;
}

///////////////////////////////////////////////////////////////////
// User Take Damage                                              //
///////////////////////////////////////////////////////////////////
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Non-player damage or self damage
	if ((victim == attacker) || !is_user_connected(attacker))
		return HAM_IGNORED;

	// Round ended no care
	if (g_roundend)
		return HAM_SUPERCEDE;
	return HAM_IGNORED;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!is_user_connected(victim) || !is_user_alive(victim))
		return HAM_IGNORED;

	// Prevent survivors take hegrenade damage
	if ((cs_get_user_team(victim) == CS_TEAM_CT) && (damage_type & DMG_HEGRENADE))
		return HAM_SUPERCEDE;

	// Non-player damage or self damage
	if ((victim == attacker) || !is_user_connected(attacker))
		return HAM_IGNORED;

	// Round ended no care
	if (g_roundend)
		return HAM_SUPERCEDE;

	// Can't damage same team player
	if ((get_pcvar_num(cvar_lockfrdkill) == 1) && (cs_get_user_team(victim) == cs_get_user_team(attacker)))
		return HAM_SUPERCEDE;

	// Zombie boss take damage be lower
	if ((cs_get_user_team(victim) == CS_TEAM_T) && g_boss[victim])
	{
		static Float:dmg_multiplier
		dmg_multiplier = get_pcvar_float(cvar_boss_dmg_multiplier)
		if (dmg_multiplier > 0.0)
		{
			damage *= dmg_multiplier
			SetHamParamFloat(4, damage)
		}
	}

	// Survivors armor protect effect
	new Float:zatk = get_pcvar_float(cvar_zatk), Float:batk = get_pcvar_float(cvar_batk)
	if (get_pcvar_num(cvar_armor_protect) && ((cs_get_user_team(attacker) == CS_TEAM_T) && (cs_get_user_team(victim) == CS_TEAM_CT)))
	{
		static Float:flArmor, CsArmorType:iArmortype, Float:flDamage
		flArmor = float(cs_get_user_armor(victim, iArmortype))
		if (((flArmor) > 0.0) && (damage > 0.0))
		{
			if ((cs_get_user_team(attacker) == CS_TEAM_T) && !g_boss[attacker] && !g_zombie[victim] && (get_pcvar_num(cvar_zombie_knife) != 1))
			{
				flDamage = (damage*0.1)*(float(g_level)*zatk)
			}

			if ((cs_get_user_team(attacker) == CS_TEAM_T) && g_boss[attacker] && !g_zombie[victim] && (get_pcvar_num(cvar_boss_knife) != 1))
			{
				flDamage = (damage*0.1)*(float(g_level)*batk)
			}
			cs_set_user_armor(victim, max(floatround(flArmor-flDamage), 0), iArmortype)
			flDamage = floatmax((flDamage-flArmor), 0.0)
			damage = flDamage/0.8 //把未被護甲防護到的傷害數值,還原成未計算成減低傷害80%的數值
			SetHamParamFloat(4, damage)
		}
	}

	// Zombie & Boss damage (Zombie boss or knife extra damage enable, can one hit kill anyone survivor.)
	if ((((get_pcvar_num(cvar_zombie_knife) == 1) && (g_zombie[attacker] && !g_boss[attacker])) || ((get_pcvar_num(cvar_boss_knife) == 1) && g_boss[attacker])) && !g_zombie[victim])
	{
		if ((inflictor == attacker) && (get_user_weapon(attacker) == CSW_KNIFE))
		{
			new Float:flHealth
			pev(victim, pev_health, flHealth)
			SetHamParamFloat(4, flHealth*5)
		}
	}
	else
	{
		if (cs_get_user_team(attacker) == CS_TEAM_T)
		{
			if (g_boss[attacker] && ((get_pcvar_num(cvar_boss_knife) == 0) && (batk > 0.0)))
			{
				SetHamParamFloat(4, damage*(batk*float(g_level)))
			}
			else
			{
				if (!g_boss[attacker] && ((get_pcvar_num(cvar_zombie_knife) == 0) && (zatk > 0.0)))
				{
					SetHamParamFloat(4, damage*(zatk*float(g_level)))
				}
			}
		}
	}
	return HAM_IGNORED;
}

///////////////////////////////////////////////////////////////////
// Round Start                                                   //
///////////////////////////////////////////////////////////////////
public event_round_start()
{
	set_task(0.1, "remove_stuff")
	for (new i = 1; i <= g_maxplayers; i++)
	{
		remove_task(i)
		remove_task(i+TASK_MODEL)
		remove_task(i+TASK_RESPAWN)
		remove_task(i+TASK_TEAM)
		remove_task(i+TASK_BURN)
		remove_task(i+TASK_UNFROZEN)
		g_zombie_respawn_count[i] = 0
		g_survivor_respawn_count[i] = 0
		g_first_spawn[i] = true
	}
	g_newround = true
	g_game_restart = false
	g_roundend = false
	g_freeze_time = true
	g_only_one_survivor = false
	g_roundstart_time = get_gametime()
	if (!(1 <= get_pcvar_num(cvar_level) <= 10))
	{
		set_pcvar_num(cvar_level, 1)
	}
	g_level = get_pcvar_num(cvar_level)
	lighting_effects()
	get_level_data()
	set_task(1.0, "zombie_game_start")
}

public zombie_game_start()
{
	// Play Ambience Music
	set_task(0.5, "ambience_sound_effect", TASK_AMBIENCE_SOUND)
	g_newround = false

	// Bot support
	TSpawns_Count()
	set_task(0.1, "bot_cfg")
}

public ambience_sound_effect()
{
	remove_task(TASK_AMBIENCE_SOUND)
	remove_task(TASK_BOSS_AMBIENCE_SOUND)
	new sound_index = random_num(0, sizeof SOUND_AMBIENCE - 1)
	PlaySound(0, SOUND_AMBIENCE[sound_index])
	set_task(ambience_duration[sound_index], "ambience_sound_effect", TASK_AMBIENCE_SOUND)
}

lighting_effects()
{
	new lighting[5]
	lighting = "f"
	switch (g_level)
	{
		case 1: //第1個關卡的地圖亮度 (亮度設定值,由最暗到最亮 "a"~"z")
		{
			get_pcvar_string(cvar_level1_lighting, lighting, charsmax(lighting))
		}
		case 2: //第2個關卡的地圖亮度
		{
			get_pcvar_string(cvar_level2_lighting, lighting, charsmax(lighting))
		}
		case 3: //第3個關卡的地圖亮度
		{
			get_pcvar_string(cvar_level3_lighting, lighting, charsmax(lighting))
		}
		case 4: //第4個關卡的地圖亮度
		{
			get_pcvar_string(cvar_level4_lighting, lighting, charsmax(lighting))
		}
		case 5: //第5個關卡的地圖亮度
		{
			get_pcvar_string(cvar_level5_lighting, lighting, charsmax(lighting))
		}
		case 6: //第6個關卡的地圖亮度
		{
			get_pcvar_string(cvar_level6_lighting, lighting, charsmax(lighting))
		}
		case 7: //第7個關卡的地圖亮度
		{
			get_pcvar_string(cvar_level7_lighting, lighting, charsmax(lighting))
		}
		case 8: //第8個關卡的地圖亮度
		{
			get_pcvar_string(cvar_level8_lighting, lighting, charsmax(lighting))
		}
		case 9: //第9個關卡的地圖亮度
		{
			get_pcvar_string(cvar_level9_lighting, lighting, charsmax(lighting))
		}
		case 10: //第10個關卡的地圖亮度
		{
			get_pcvar_string(cvar_level10_lighting, lighting, charsmax(lighting))
		}
	}
	// Set lighting
	strtolower(lighting)
	engfunc(EngFunc_LightStyle, 0, lighting)
}

get_level_data()
{
	switch (g_level)
	{
		case 1:
		{
			g_zombie_respawns = get_pcvar_num(cvar_level1_respawns)
			g_zombie_health = get_pcvar_num(cvar_level1_health)
			g_zombie_maxspeed = get_pcvar_float(cvar_level1_maxspeed)
			g_boss_health = get_pcvar_num(cvar_level1_bosshp)
			g_boss_maxspeed = get_pcvar_float(cvar_level1_bossmaxspeed)

		}
		case 2:
		{
			g_zombie_respawns = get_pcvar_num(cvar_level2_respawns)
			g_zombie_health = get_pcvar_num(cvar_level2_health)
			g_zombie_maxspeed = get_pcvar_float(cvar_level2_maxspeed)
			g_boss_health = get_pcvar_num(cvar_level2_bosshp)
			g_boss_maxspeed = get_pcvar_float(cvar_level2_bossmaxspeed)
		}
		case 3:
		{
			g_zombie_respawns = get_pcvar_num(cvar_level3_respawns)
			g_zombie_health = get_pcvar_num(cvar_level3_health)
			g_zombie_maxspeed = get_pcvar_float(cvar_level3_maxspeed)
			g_boss_health = get_pcvar_num(cvar_level3_bosshp)
			g_boss_maxspeed = get_pcvar_float(cvar_level3_bossmaxspeed)
		}
		case 4:
		{
			g_zombie_respawns = get_pcvar_num(cvar_level4_respawns)
			g_zombie_health = get_pcvar_num(cvar_level4_health)
			g_zombie_maxspeed = get_pcvar_float(cvar_level4_maxspeed)
			g_boss_health = get_pcvar_num(cvar_level4_bosshp)
			g_boss_maxspeed = get_pcvar_float(cvar_level4_bossmaxspeed)
		}
		case 5:
		{
			g_zombie_respawns = get_pcvar_num(cvar_level5_respawns)
			g_zombie_health = get_pcvar_num(cvar_level5_health)
			g_zombie_maxspeed = get_pcvar_float(cvar_level5_maxspeed)
			g_boss_health = get_pcvar_num(cvar_level5_bosshp)
			g_boss_maxspeed = get_pcvar_float(cvar_level5_bossmaxspeed)
		}
		case 6:
		{
			g_zombie_respawns = get_pcvar_num(cvar_level6_respawns)
			g_zombie_health = get_pcvar_num(cvar_level6_health)
			g_zombie_maxspeed = get_pcvar_float(cvar_level6_maxspeed)
			g_boss_health = get_pcvar_num(cvar_level6_bosshp)
			g_boss_maxspeed = get_pcvar_float(cvar_level6_bossmaxspeed)
		}
		case 7:
		{
			g_zombie_respawns = get_pcvar_num(cvar_level7_respawns)
			g_zombie_health = get_pcvar_num(cvar_level7_health)
			g_zombie_maxspeed = get_pcvar_float(cvar_level7_maxspeed)
			g_boss_health = get_pcvar_num(cvar_level7_bosshp)
			g_boss_maxspeed = get_pcvar_float(cvar_level7_bossmaxspeed)
		}
		case 8:
		{
			g_zombie_respawns = get_pcvar_num(cvar_level8_respawns)
			g_zombie_health = get_pcvar_num(cvar_level8_health)
			g_zombie_maxspeed = get_pcvar_float(cvar_level8_maxspeed)
			g_boss_health = get_pcvar_num(cvar_level8_bosshp)
			g_boss_maxspeed = get_pcvar_float(cvar_level8_bossmaxspeed)
		}
		case 9:
		{
			g_zombie_respawns = get_pcvar_num(cvar_level9_respawns)
			g_zombie_health = get_pcvar_num(cvar_level9_health)
			g_zombie_maxspeed = get_pcvar_float(cvar_level9_maxspeed)
			g_boss_health = get_pcvar_num(cvar_level9_bosshp)
			g_boss_maxspeed = get_pcvar_float(cvar_level9_bossmaxspeed)
		}
		case 10:
		{
			g_zombie_respawns = get_pcvar_num(cvar_level10_respawns)
			g_zombie_health = get_pcvar_num(cvar_level10_health)
			g_zombie_maxspeed = get_pcvar_float(cvar_level10_maxspeed)
			g_boss_health = get_pcvar_num(cvar_level10_bosshp)
			g_boss_maxspeed = get_pcvar_float(cvar_level10_bossmaxspeed)
		}
	}
}

///////////////////////////////////////////////////////////////////
// Display Hud Level Information      	                         //
///////////////////////////////////////////////////////////////////
public show_level_hud()
{
	set_hudmessage(0, 255, 0, -1.0, 0.0, 0, 0.0, 1.0, 0.0, 0.2, -1)
	if (g_level == 1)
	{
		ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE1",
			g_level, g_boss_health, g_boss_maxspeed, g_zombie_health, g_zombie_maxspeed, g_zombie_respawns)
	}
	else if (g_level == 2)
	{
		ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE2",
			g_level, g_boss_health, g_boss_maxspeed, g_zombie_health, g_zombie_maxspeed, g_zombie_respawns)
	}
	else if (g_level == 3)
	{
		ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE3",
			g_level, g_boss_health, g_boss_maxspeed, g_zombie_health, g_zombie_maxspeed, g_zombie_respawns)
	}
	else if (g_level == 4)
	{
		ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE4",
			g_level, g_boss_health, g_boss_maxspeed, g_zombie_health, g_zombie_maxspeed, g_zombie_respawns)
	}
	else if (g_level == 5)
	{
		ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE5",
			g_level, g_boss_health, g_boss_maxspeed, g_zombie_health, g_zombie_maxspeed, g_zombie_respawns)
	}
	else if (g_level == 6)
	{
		ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE6",
			g_level, g_boss_health, g_boss_maxspeed, g_zombie_health, g_zombie_maxspeed, g_zombie_respawns)
	}
	else if (g_level == 7)
	{
		ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE7",
			g_level, g_boss_health, g_boss_maxspeed, g_zombie_health, g_zombie_maxspeed, g_zombie_respawns)
	}
	else if (g_level == 8)
	{
		ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE8",
			g_level, g_boss_health, g_boss_maxspeed, g_zombie_health, g_zombie_maxspeed, g_zombie_respawns)
	}
	else if (g_level == 9)
	{
		ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE9",
			g_level, g_boss_health, g_boss_maxspeed, g_zombie_health, g_zombie_maxspeed, g_zombie_respawns)
	}
	else if (g_level == 10)
	{
		if (get_pcvar_num(cvar_final_secret) >= 1)
		{
			ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE10S", g_level)
		}
		else
		{
			ShowSyncHudMsg(0, g_hudSync, "%L", LANG_PLAYER, "ZH_TITLE10",
				g_level, g_boss_health, g_boss_maxspeed, g_zombie_health, g_zombie_maxspeed, g_zombie_respawns)
		}
	}
}

///////////////////////////////////////////////////////////////////
// Bot Settings                                                  //
///////////////////////////////////////////////////////////////////
public bot_cfg()
{
	// PodBot&Zbot support
	if (cvar_pbotquota || cvar_botquota)
	{
		new z = 0, h = 0
		for (new id = 1; id <= 32; id++)
		{
			if (is_user_connected(id) && (cs_get_user_team(id) == CS_TEAM_T))
			{
				z++
			}

			if (is_user_connected(id) && (cs_get_user_team(id) == CS_TEAM_CT))
			{
				if (is_user_bot(id))
				{
					h++
				}
			}
		}

		if (z < 1)
		{
			if (h < 1)
			{

				server_cmd("yb_quota 0")

			}
			g_botslots = 0
			g_bot_slotsadded = 0
		}

		new maxslots = get_pcvar_num(cvar_zombie_maxslots)
		if (g_bot_slotsadded == 0)
		{
			if (g_SpawnT < 21)
			{
				if ((maxslots > 0) && (maxslots < g_SpawnT))
				{
					bot_add = maxslots
					g_bot_slotsadded = true
				}

				if ((maxslots < 1) || (maxslots >= g_SpawnT))
				{
				 	bot_add = (g_SpawnT-1)
					g_bot_slotsadded = true
				}
			}
			else
			{
				if ((maxslots >= 20) || (maxslots < 1))
				{
 					bot_add = (20-random_num(1,5))
					g_bot_slotsadded = true
				}
				else
				{
					bot_add = maxslots
					g_bot_slotsadded = true
				}
			}
		}

		if (g_bot_slotsadded && (g_botslots < bot_add))
		{
			set_task(get_pcvar_float(cvar_zombieappear), "add_bot", bot_add)
		}
	}
}

public add_bot(bot_add)
{
	new p = 0
	for (new id = 1; id <= 32; id++)
	{
		if (is_user_alive(id) && (cs_get_user_team(id) == CS_TEAM_CT))
		{
			p++
		}
	}

	if (p >= 1)
	{
		if (g_botslots < bot_add)
		{
			server_cmd("add")
			g_botslots++
			set_task(0.0, "add_bot", bot_add)

		}
		else
		{
			return;
		}
	}
	else
	{
		set_task(1.0, "add_bot", bot_add)
	}
}

///////////////////////////////////////////////////////////////////
// Player Put In Server                                          //
///////////////////////////////////////////////////////////////////
public client_putinserver(id)
{
	g_first_spawn[id] = true
	set_task(1.0, "respawn_check", id)
	if (is_user_bot(id) && cvar_botquota && !BotHasDebug)
	{
		set_task(0.1, "_Debug", id)
	}
}

public respawn_check(id)
{
	if (!g_roundend && is_user_connected(id) && !is_user_alive(id))
	{
		if ((cs_get_user_team(id) == CS_TEAM_T) || (cs_get_user_team(id) == CS_TEAM_CT))
		{
			set_task(1.0, "you_will_respawn_ch", id)
		}
	}
	set_task(1.0, "respawn_check", id)
}

///////////////////////////////////////////////////////////////////
// Bot Debug                                                     //
///////////////////////////////////////////////////////////////////
// Bot support
public _Debug(id)
{
	// Make sure it's a Bot and it's still connected and not debug yet.
	if (!is_user_connected(id) || !get_pcvar_num(cvar_botquota) || !is_user_bot(id) || BotHasDebug)
		return;

	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled")
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled_Post", 1)
	if (is_user_alive(id))
		fw_PlayerSpawn_Post(id)
	BotHasDebug = true
}

///////////////////////////////////////////////////////////////////
// Player Disconnected                                           //
///////////////////////////////////////////////////////////////////
public client_disconnected(id)
{
	remove_task(id)
	remove_task(id+TASK_MODEL)
	remove_task(id+TASK_RESPAWN)
	remove_task(id+TASK_TEAM)
	remove_task(id+TASK_BURN)
	remove_task(id+TASK_UNFROZEN)
	remove_task(id+TASK_NVG)
	remove_task(id+TASK_SPEC_NVG)
	remove_task(TASK_AMBIENCE_SOUND)
	remove_task(TASK_BOSS_AMBIENCE_SOUND)
	g_zombie_respawn_count[id] = 0
	g_survivor_respawn_count[id] = 0
	set_pev(g_playerbar[id], pev_effects, pev(g_playerbar[id], pev_effects) | EF_NODRAW)
}

///////////////////////////////////////////////////////////////////
// Freeze Time Over                                              //
///////////////////////////////////////////////////////////////////
// Log Event Round Start
public logevent_round_start()
{
	g_freeze_time = false
}

///////////////////////////////////////////////////////////////////
// User Spawn and Set Zombie/Survivor Values                     //
///////////////////////////////////////////////////////////////////
public fw_PlayerSpawn_Post(id)
{
	if (!is_user_connected(id) || !cs_get_user_team(id))
		return;

	set_pev(id, pev_effects, pev(id, pev_effects) & ~EF_NODRAW)
	set_pev(id, pev_gravity, 1.0)
	fm_set_rendering(id)
	remove_task(id+TASK_MODEL)
	remove_task(id+TASK_RESPAWN)
	remove_task(id+TASK_BURN)
	remove_task(id+TASK_UNFROZEN)
	g_burning[id] = false
	g_frozen[id] = false
	g_set_user_kill[id] = false
	g_spawn_time[id] = get_gametime()
	fm_set_user_godmode(id, 0)
	fm_set_rendering(id, kRenderFxNone, 0, 0, 0,kRenderNormal, 255)

	// 消去HUD回合時間顯示
	message_begin(MSG_ONE, get_user_msgid("HideWeapon"), _, id)
	write_byte((1<<4))
	message_end()

	// 重置玩家的觀戰夜視鏡
	remove_task(id+TASK_NVG)
	remove_task(id+TASK_SPEC_NVG)
	toggle_user_nvg(id, 0)
	g_nvg_enabled[id] = false

	// 移除扮演殭屍時給予的夜視鏡
	if (g_give_nvg[id])
	{
		cs_set_user_nvg(id, 0)
		g_give_nvg[id] = false
	}

	// 設定人類與殭屍的模組及能力
	g_zombie[id] = cs_get_user_team(id) == CS_TEAM_T
	if (is_user_alive(id))
	{
		if (g_zombie[id])
		{
			copy(g_player_model[id], charsmax(g_player_model[]), MODEL_ZOMBIE[random_num(0, (sizeof MODEL_ZOMBIE - 1))])
			set_task(0.1, "zombie_power", id)
			pev(id, pev_health, g_playerMaxHealth[id])
			event_health(id)
		}
		else if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			copy(g_player_model[id], charsmax(g_player_model[]), MODEL_HUMAN[random_num(0, (sizeof MODEL_HUMAN - 1))])
			set_task(0.1, "human_power", id)
			set_pev(g_playerbar[id], pev_effects, pev(g_playerbar[id], pev_effects) | EF_NODRAW)
		}
		else if (g_has_custom_model[id])
		{
			fm_reset_user_model(id)
		}

		new currentmodel[33]
		fm_get_user_model(id, currentmodel, charsmax(currentmodel))
		if (!equal(currentmodel, g_player_model[id]))
		{
			if (g_newround)
			{
				set_task(0.1, "fm_user_model_update", id+TASK_MODEL)
			}
			else
			{
				fm_user_model_update(id+TASK_MODEL)
			}
		}
	}

	// 載入殭屍重生特效
	set_task(0.1, "user_spawn_effects", id)

	// 讓殭屍在隨機地點重生
	if ((get_pcvar_num(cvar_zombie_spawnpoint) == 1) && (g_can_random_spawn && (cs_get_user_team(id) == CS_TEAM_T)))
	{
		set_task(0.1, "csdm_player_spawn", id)
	}

	// 檢查人類是否只剩最後一人,如果不是則把最後人類出現的flag重置.
	if (cs_get_user_team(id) == CS_TEAM_CT)
	{
		static ts[32], ts_num, cts[32], cts_num
		get_alive_players(ts, ts_num, cts, cts_num)
		if (cts_num > 1)
			g_only_one_survivor = false
	}
}

public zombie_power(id)
{
	g_boss[id] = false
	g_user_maxspeed[id] = g_zombie_maxspeed
	if(get_pcvar_num(cvar_zombie_random) == 1)
	{
		new rnum = random_num(0,5)
		new rhealth = random_num(g_zombie_health,(g_zombie_health+(random_num(100,100*g_level))))
		new rarmor = random_num(((get_pcvar_num(cvar_zombiearmor)*g_level)-(random_num(25,(50*g_level)))),((get_pcvar_num(cvar_zombiearmor)*g_level)+(50*g_level)))
		new Float:rspd = random_float((g_user_maxspeed[id]-float(15-g_level)),(g_user_maxspeed[id]+float(g_level+5)))
		cs_set_user_armor(id, rarmor, CS_ARMOR_VESTHELM)
		set_pev(id, pev_maxspeed, rspd)
		set_pev(id, pev_gravity, random_float(0.7,1.1))
		if ((rnum >= 1) && (rnum <= 4))
		{
			fm_set_user_health(id, g_zombie_health)
		}
		else if (rnum == 5)
		{
			fm_set_user_health(id, rhealth)
		}
		else
		{
			fm_set_user_health(id, rhealth*2*g_level)
		}
	}
	else
	{
		set_pev(id, pev_maxspeed, g_user_maxspeed[id])
		fm_set_user_health(id, g_zombie_health)
		cs_set_user_armor(id, (get_pcvar_num(cvar_zombiearmor)*g_level), CS_ARMOR_VESTHELM)
	}
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	g_give_nvg[id] = true
	g_nvg_enabled[id] = true
	cs_set_user_nvg(id, 1)
	toggle_user_nvg(id, 1)
	cs_set_user_money(id, 0)
	set_task(0.1, "hide_user_money", id)
}

public human_power(id)
{
	g_user_maxspeed[id] = 250.0
	fm_set_user_maxspeed(id, g_user_maxspeed[id])
	if (cs_get_user_money(id) > get_pcvar_num(cvar_maxmoney))
	{
		cs_set_user_money(id, get_pcvar_num(cvar_maxmoney))
	}
}

public fw_ClientKey(id, const infobuffer[], const key[])
{
	if (g_has_custom_model[id] && equal(key, "model"))
		return FMRES_SUPERCEDE;
	return FMRES_IGNORED;
}

public fw_ClientInfo(id)
{
	if (!g_has_custom_model[id])
		return FMRES_IGNORED;

	static currentmodel[33]
	fm_get_user_model(id, currentmodel, charsmax(currentmodel))
	if (!equal(currentmodel, g_player_model[id]) && !task_exists(id+TASK_MODEL))
		fm_set_user_model(id+TASK_MODEL)
	return FMRES_IGNORED;
}

public fm_user_model_update(taskid)
{
	static Float:current_time
	current_time = get_gametime()
	if ((current_time-g_models_target_time) >= 0.5)
	{
		fm_set_user_model(taskid)
		g_models_target_time = current_time
	}
	else
	{
		set_task(((g_models_target_time+0.5)-current_time), "fm_set_user_model", taskid)
		g_models_target_time = g_models_target_time + 0.1
	}
}

public fm_set_user_model(taskid)
{
	new id = taskid-TASK_MODEL
	engfunc(EngFunc_SetClientKeyValue, id, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", g_player_model[id])
	g_has_custom_model[id] = true
}

public make_healthbar()
{
	static playerBar, allocString
	allocString = engfunc(EngFunc_AllocString, "env_sprite")
	for(new id = 1; id <= get_maxplayers(); id ++)
	{
		g_playerbar[id] = engfunc(EngFunc_CreateNamedEntity, allocString)
		playerBar = g_playerbar[id]
		if(pev_valid(playerBar))
		{
			set_pev(playerBar, pev_scale, 0.25)
			engfunc(EngFunc_SetModel, playerBar, healthbar_spr)
			set_pev(playerBar, pev_effects, pev(playerBar, pev_effects ) | EF_NODRAW)
		}
	}
}

public event_resethud(id)
{
	set_pev(g_playerbar[id], pev_effects, pev(g_playerbar[id], pev_effects) | EF_NODRAW)
}

public event_death()
{
	new id = read_data(2)
	g_playerMaxHealth[id] = 0.0
	set_pev(g_playerbar[id], pev_effects, pev(g_playerbar[id], pev_effects) | EF_NODRAW)
}

public event_health(id)
{
	if ((get_pcvar_num(cvar_cvar_zombiebar) == 1) && (cs_get_user_team(id) == CS_TEAM_T))
	{
		new Float:hp[33]
		pev(id, pev_health, hp[id])
		if(hp[id] >= g_playerMaxHealth[id])
		{
			g_playerMaxHealth[id] = hp[id]
			set_pev(g_playerbar[id], pev_frame, 100.0)
		}
		else
		{
			set_pev(g_playerbar[id], pev_frame, 0.0+(((hp[id]-1.0)*100.0)/g_playerMaxHealth[id]))
		}
	}
	else
	{
		set_pev(g_playerbar[id], pev_effects, pev(g_playerbar[id], pev_effects) | EF_NODRAW)
	}
}

public fm_addtofullpack_post(es, e, user, host, host_flags, player, p_set)
{
	if((get_pcvar_num(cvar_cvar_zombiebar) != 1) || !player || !is_user_alive(user) || (cs_get_user_team(user) != CS_TEAM_T))
		return FMRES_IGNORED

	new Float:PlayerOrigin[3]
	pev(user, pev_origin, PlayerOrigin)
	PlayerOrigin[2] += 60.0
	engfunc(EngFunc_SetOrigin, g_playerbar[user], PlayerOrigin)
	set_pev(g_playerbar[user], pev_effects, pev(g_playerbar[user], pev_effects) & ~EF_NODRAW)
	return FMRES_HANDLED
}

///////////////////////////////////////////////////////////////////
// User Spawn Screen Effects                  	 		 //
///////////////////////////////////////////////////////////////////
public user_spawn_effects(id)
{
	new Float:screen_shake[3]
	screen_shake[0] = random_float(100.0, 175.0)
	screen_shake[1] = random_float(20.0, 80.0)
	screen_shake[2] = random_float(550.0, 1200.0)
	message_begin(MSG_ONE, g_msgScreenShake, {0,0,0}, id)
	write_short((1<<14))
	write_short((1<<14))
	write_short((1<<14))
	message_end()
}

///////////////////////////////////////////////////////////////////
// Lock Zombie Team                                              //
///////////////////////////////////////////////////////////////////
public cmd_jointeam(id)
{
	new class[2]
	num_to_str(random_num(1, 4), class, 1)
	engclient_cmd(id, "jointeam", "2", class)
}

///////////////////////////////////////////////////////////////////
// CSDM Respawn                                                  //
///////////////////////////////////////////////////////////////////
csdm_respawn()
{
	new map[32], config[32],  mapfile[64]
	get_mapname(map, 31)
	get_configsdir(config, 31)
	format(mapfile, 63, "%s\csdm\%s.spawns.cfg", config, map)
	g_total_spawn = 0
	if (file_exists(mapfile))
	{
		new new_data[124], len
		new line = 0
		new pos[12][8]
		while (g_total_spawn < 60 && (line = read_file(mapfile, line, new_data, charsmax(new_data), len)) != 0)
		{
			if (strlen(new_data) < 2 || new_data[0] == '[')
				continue;

			parse(new_data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7)
			g_spawn_vec[g_total_spawn][0] = str_to_float(pos[1])
			g_spawn_vec[g_total_spawn][1] = str_to_float(pos[2])
			g_spawn_vec[g_total_spawn][2] = str_to_float(pos[3])
			g_spawn_angle[g_total_spawn][0] = str_to_float(pos[4])
			g_spawn_angle[g_total_spawn][1] = str_to_float(pos[5])
			g_spawn_angle[g_total_spawn][2] = str_to_float(pos[6])
			g_spawn_v_angle[g_total_spawn][0] = str_to_float(pos[8])
			g_spawn_v_angle[g_total_spawn][1] = str_to_float(pos[9])
			g_spawn_v_angle[g_total_spawn][2] = str_to_float(pos[10])
			g_total_spawn++
		}

		if ((g_total_spawn >= 2) && (get_pcvar_num(cvar_zombie_spawnpoint) == 1))
		{
			g_can_random_spawn = true
		}
		else
		{
			g_can_random_spawn = false
		}
	}
	return 1;
}

public csdm_player_spawn(id)
{
	if (!is_user_alive(id) || (cs_get_user_team(id) == CS_TEAM_CT) || (get_pcvar_num(cvar_zombie_spawnpoint) != 1))
		return;

	if (g_first_spawn[id])
	{
		g_first_spawn[id] = false
		return;
	}

	new list[60]
	new num = 0
	new final = -1
	new total = 0
	new players[32], n, x = 0
	new Float:loc[32][3], locnum
	get_players(players, num)
	for (new i = 0; i < num; i++)
	{
		if (is_user_alive(players[i]) && players[i] != id)
		{
			pev(players[i], pev_origin, loc[locnum])
			locnum++
		}
	}

	num = 0
	while (num <= g_total_spawn)
	{
		if (num == g_total_spawn)
			break;

		n = random_num(0, g_total_spawn-1)
		if (!list[n])
		{
			list[n] = 1
			num++
		}
		else
		{
			total++
			if (total > 100)
				break;
			continue;
		}

		if (locnum < 1)
		{
			final = n
			break;
		}

		final = n
		for (x = 0; x < locnum; x++)
		{
			new Float:distance = get_distance_f(g_spawn_vec[n], loc[x])
			if (distance < 250.0)
			{
				final = -1
				break;
			}
		}
		if (final != -1)
			break;
	}

	if (final != -1)
	{
		new Float:mins[3], Float:maxs[3]
		pev(id, pev_mins, mins)
		pev(id, pev_maxs, maxs)
		engfunc(EngFunc_SetSize, id, mins, maxs)
		engfunc(EngFunc_SetOrigin, id, g_spawn_vec[final])
		set_pev(id, pev_fixangle, 1)
		set_pev(id, pev_angles, g_spawn_angle[final])
		set_pev(id, pev_v_angle, g_spawn_v_angle[final])
		set_pev(id, pev_fixangle, 1)
	}
}

///////////////////////////////////////////////////////////////////
// Death Event                                                   //
///////////////////////////////////////////////////////////////////
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Killed by Non-Player Object or Self Killed
	if ((victim == attacker) || !is_user_connected(attacker))
		return;

	g_user_kill[victim] = 0
	new CsTeams:team2 = cs_get_user_team(attacker)
	if ((victim != attacker) && (cs_get_user_team(victim) != cs_get_user_team(attacker)))
	{
		if (team2 == CS_TEAM_T)
		{
			static name[32], name2[32], health, zombieheal
			get_user_name(attacker, name, charsmax(name))
			get_user_name(victim, name2, charsmax(name2))
			health = get_user_health(attacker)
			zombieheal = get_pcvar_num(cvar_zombieheal)
			fm_set_user_health(attacker, health+zombieheal)
			set_hudmessage(100, 255, 0, -1.0, 0.27, 0, 6.0, 6.0, 0.1, 0.2, -1)
			ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZOMBIEHEAL", name, name2, zombieheal)
			PlaySound(0, SOUND_EAT_BRAIN)
		}
		else
		{
			if ((team2 == CS_TEAM_CT) && ((cs_get_user_team(victim) == CS_TEAM_T) && !g_boss[victim]))
			{
				new money  = cs_get_user_money(attacker), maxmoney = get_pcvar_num(cvar_maxmoney)
				new zombiebonus = ((get_pcvar_num(cvar_zombiekill_bonus))*g_level)
				if ((money+zombiebonus) <= maxmoney)
				{
					cs_set_user_money(attacker, money+zombiebonus)
				}
				else
				{
					cs_set_user_money(attacker, maxmoney-300)
				}
			}
		}

		g_user_kill[attacker]++
		if (get_pcvar_num(cvar_zombie_scores))
		{
			new name3[33]
			get_user_name(attacker, name3, charsmax(name3))
			if (team2 == CS_TEAM_T)
				set_hudmessage(100, 255, 0, -1.0, 0.27, 0, 6.0, 6.0, 0.1, 0.2, -1)
			else if (team2 == CS_TEAM_CT)
				set_hudmessage(0, 255, 100, -1.0, 0.27, 0, 6.0, 6.0, 0.1, 0.2, -1)

			switch (g_user_kill[attacker])
			{
				case 5:
				{
					switch (team2)
					{
						case CS_TEAM_T:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZSCORE1", name3)
						}
						case CS_TEAM_CT:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_HSCORE1", name3)
						}
					}
				}
				case 10:
				{
					switch (team2)
					{
						case CS_TEAM_T:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZSCORE2", name3)
						}
						case CS_TEAM_CT:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_HSCORE2", name3)
						}
					}
				}
				case 20:
				{
					switch (team2)
					{
						case CS_TEAM_T:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZSCORE3", name3)
						}
						case CS_TEAM_CT:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_HSCORE3", name3)
						}
					}
				}
				case 30:
				{
					switch (team2)
					{
						case CS_TEAM_T:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZSCORE4", name3)
						}
						case CS_TEAM_CT:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_HSCORE4", name3)
						}
					}
				}
				case 40:
				{
					switch (team2)
					{
						case CS_TEAM_T:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZSCORE5", name3)
						}
						case CS_TEAM_CT:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_HSCORE5", name3)
						}
					}
				}
				case 50:
				{
					switch (team2)
					{
						case CS_TEAM_T:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZSCORE6", name3)
						}
						case CS_TEAM_CT:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_HSCORE6", name3)
						}
					}
				}
				case 60:
				{
					switch (team2)
					{
						case CS_TEAM_T:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZSCORE7", name3)
						}
						case CS_TEAM_CT:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_HSCORE7", name3)
						}
					}
				}
				case 75:
				{
					switch (team2)
					{
						case CS_TEAM_T:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZSCORE8", name3)
						}
						case CS_TEAM_CT:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_HSCORE8", name3)
						}
					}
				}
				case 100:
				{
					switch (team2)
					{
						case CS_TEAM_T:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZSCORE9", name3)
						}
						case CS_TEAM_CT:
						{
							ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_HSCORE9", name3)
						}
					}
				}
			}
		}
	}

	// 檢查是否只剩下最後一個人類還存活著.(還能重生的或是正在重生的,都算是存活著)
	static ts[32], ts_num, cts[32], cts_num
	get_alive_players(ts, ts_num, cts, cts_num)
	if (cs_get_user_team(victim) == CS_TEAM_CT && cts_num == 1 && !g_set_user_kill[victim])
	{
		if (!g_only_one_survivor)
		{
			static i, last_survivor_id, name[32]
			last_survivor_id = cts[0]
			g_only_one_survivor = true
			for (i = 1; i <= g_maxplayers; i++)
			{
				if (!is_user_connected(i) || i == last_survivor_id || cs_get_user_team(i) != CS_TEAM_CT)
					continue;

				if (g_survivor_respawn_count[i] > 0 || task_exists(i+TASK_RESPAWN))
				{
					g_only_one_survivor = false
					break;
				}
			}

			if (g_only_one_survivor)
			{
				get_user_name(last_survivor_id, name, charsmax(name))
				set_hudmessage(0, 255, 100, -1.0, 0.30, 0, 6.0, 6.0, 0.1, 0.2, -1)
				ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_LASTMAN", name)
			}
		}
	}

	// 當剩下最後一隻殭屍時,設定讓他變成殭屍王.
	if (ts_num == 1)
	{
		static last_zombie_id
		last_zombie_id = ts[0]
		if (!g_boss[last_zombie_id]) // 檢查是否已經是成為殭屍王了
		{
			g_survivor_class[last_zombie_id] = 0
			g_boss[last_zombie_id] = true
			set_boss_model(last_zombie_id)
			StopSound(0)
			play_boss_ambience_sound()
			fm_set_user_health(last_zombie_id, get_user_health(last_zombie_id)+g_boss_health)
			cs_set_user_armor(last_zombie_id, ((get_pcvar_num(cvar_zombiearmor)*g_level)*2), CS_ARMOR_VESTHELM)
			if(get_pcvar_num(cvar_zombie_random) == 1)
			{
				g_user_maxspeed[last_zombie_id] = g_boss_maxspeed+float(g_level*5)
			}
			else
			{
				if(get_pcvar_num(cvar_zombie_random) == 0)
				{
					g_user_maxspeed[last_zombie_id] = g_boss_maxspeed
				}
			}
			pev(last_zombie_id, pev_health, g_playerMaxHealth[last_zombie_id])
			set_pev(last_zombie_id, pev_gravity, 0.7)
			set_pev(last_zombie_id, pev_maxspeed, g_user_maxspeed[last_zombie_id])
			set_task(1.0, "boss_beacon_effect", last_zombie_id)
			static tname[32]
			get_user_name(last_zombie_id, tname, charsmax(tname))
			set_hudmessage(255, 50, 50, -1.0, 0.21, 0, 6.0, 5.0, 0.1, 0.2, -1)
			ShowSyncHudMsg(0, g_hudSync3, "%L", LANG_PLAYER, "ZH_BOSSAPPEAR", tname)
		}
	}

	// 當殭屍死亡後,會出現特殊效果.
	if (cs_get_user_team(victim) == CS_TEAM_T && get_pcvar_num(cvar_zombie_effect))
	{
		static Float:FOrigin2[3]
		pev(victim, pev_origin, FOrigin2)
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, FOrigin2, 0)
		write_byte(TE_PARTICLEBURST)
		engfunc(EngFunc_WriteCoord, FOrigin2[0])
		engfunc(EngFunc_WriteCoord, FOrigin2[1])
		engfunc(EngFunc_WriteCoord, FOrigin2[2])
		write_short(50)
		write_byte(75)
		write_byte(10)
		message_end()
	}

	// 殺死殭屍王的玩家可以獲得額外獎勵
	if ((cs_get_user_team(attacker) == CS_TEAM_CT) && g_boss[victim])
	{
		static ctname[32]
		get_user_name(attacker, ctname, charsmax(ctname))
		new money  = cs_get_user_money(attacker), maxmoney = get_pcvar_num(cvar_maxmoney)
		new bossbonus = ((get_pcvar_num(cvar_bosskill_bonus))*g_level)
		if ((money+bossbonus) <= maxmoney)
		{
			cs_set_user_money(attacker, money+bossbonus)
		}
		else
		{
			cs_set_user_money(attacker, maxmoney-300)
		}

		if (g_level < 10)
		{
			set_hudmessage(255, 255, 100, -1.0, 0.25, 0, 1.5, 5.0, 0.0, 0.0, -1)
			ShowSyncHudMsg(0, g_hudSync3, "%L", LANG_PLAYER, "ZH_BOSS_BONUS", ctname, bossbonus)
		}
	}

	// 當殭屍王被人類殺死時會變成碎塊
	if (g_boss[victim])
		SetHamParamInteger(3, 2)
}

public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	fm_set_rendering(victim)
	if (!g_boss[victim])
	{
		set_pev(victim, pev_effects, pev(victim, pev_effects) | EF_NODRAW)
	}

	remove_task(victim)
	remove_task(victim+TASK_MODEL)
	remove_task(victim+TASK_TEAM)
	remove_task(victim+TASK_RESPAWN)
	remove_task(victim+TASK_BURN)
	remove_task(victim+TASK_UNFROZEN)
	g_frozen[victim] = false
	g_burning[victim] = false

	// 重置玩家的夜視鏡
	remove_task(victim+TASK_NVG)
	remove_task(victim+TASK_SPEC_NVG)
	toggle_user_nvg(victim, 0)
	g_nvg_enabled[victim] = false

	// 移除扮演殭屍時給予的夜視鏡
	if (g_give_nvg[victim])
	{
		cs_set_user_nvg(victim, 0)
		g_give_nvg[victim] = false
	}

	// Enable dead players nightvision
	set_task(0.1, "spectator_nvg", victim+TASK_SPEC_NVG)

	if ((cs_get_user_team(victim) == CS_TEAM_T) && !is_user_bot(victim))
	{
		g_zombie_respawn_count[victim] = 0
		g_survivor_respawn_count[victim] = 0
		cs_set_user_team(victim, CS_TEAM_CT)
	}

	if (g_set_user_kill[victim])
	{
		g_set_user_kill[victim] = false
		return;
	}

	// Respawn world killed players
	if (!attacker && ((get_gametime() - g_spawn_time[victim]) <= 3.0))
	{
		if (cs_get_user_team(victim) == CS_TEAM_T)
		{
			set_task(1.0, "zombie_respawner", victim+TASK_RESPAWN)
		}
		else if (cs_get_user_team(victim) == CS_TEAM_CT)
		{
			set_task(1.0, "survivor_respawner", victim+TASK_RESPAWN)
		}
		return;
	}

	// Respawn killed players
	if (attacker)
	{
		if (cs_get_user_team(victim) == CS_TEAM_T)
		{
			g_will_respawn_time[victim] = get_pcvar_float(cvar_zombie_respawn_delay)
		}
		else if (cs_get_user_team(victim) == CS_TEAM_CT)
		{
			g_will_respawn_time[victim] = get_pcvar_float(cvar_survivor_respawn_delay)
		}
		set_task(1.0, "you_will_respawn_ch", victim)
	}
}

public you_will_respawn_ch(id)
{
	if (!is_user_connected(id))
	{
		return;
	}

	new survivor_max_respawns = get_pcvar_num(cvar_survivor_respawns)
	if (((cs_get_user_team(id) == CS_TEAM_T) && (g_zombie_respawns >= 1) && (g_zombie_respawn_count[id] >= g_zombie_respawns)) || ((cs_get_user_team(id) == CS_TEAM_CT) && (survivor_max_respawns >= 1) && (g_survivor_respawn_count[id] >= survivor_max_respawns)))
	{
		return;
	}

	if(g_roundend)
	{
		client_print(id, print_center, " ")
		return;
	}

	if (g_will_respawn_time[id] <= 0.9)
	{
		client_print(id, print_center," ")
		if (cs_get_user_team(id) == CS_TEAM_T)
		{
			if (g_zombie_respawn_count[id] < g_zombie_respawns)
			{
				g_zombie_respawn_count[id]++
				set_task(0.1, "zombie_respawner", id+TASK_RESPAWN)
			}
		}
		else if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			if (get_pcvar_num(cvar_survivor_respawn))
			{
				new survivor_max_respawns = get_pcvar_num(cvar_survivor_respawns)
				if (!survivor_max_respawns || (g_survivor_respawn_count[id] < survivor_max_respawns))
				{
					g_survivor_respawn_count[id]++
					set_task(0.1, "survivor_respawner", id+TASK_RESPAWN)
				}
			}
		}
		return;
	}

	if (g_will_respawn_time[id] > 0)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_RESPAWN", g_will_respawn_time[id])
		g_will_respawn_time[id] -= 1.0
	}
	set_task(1.0, "you_will_respawn_ch", id)
}

set_boss_model(id)
{
	if (g_boss[id])
	{
		new currentmodel[33]
		copy(g_player_model[id], charsmax(g_player_model[]), MODEL_ZOMBIE_BOSS[random_num(0, sizeof MODEL_ZOMBIE_BOSS -1)])
		fm_get_user_model(id, currentmodel, charsmax(currentmodel))
		if (!equal(currentmodel, g_player_model[id]))
		{
			if ((get_gametime()-g_roundstart_time) < 5.0)
				set_task(0.1, "fm_user_model_update", id+TASK_MODEL)
			else
				fm_user_model_update(id+TASK_MODEL)
		}
	}
}

public boss_beacon_effect(id)
{
	if (g_boss[id] && is_user_alive(id))
	{
		static origin[3]
		get_user_origin(id, origin)
		emit_sound(id, CHAN_ITEM, SOUND_BOSS_BEACON, 1.0, ATTN_NORM, 0, PITCH_NORM)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMCYLINDER) // TE_BEAMCYLINDER (21)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]-20)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+200)
		write_short(g_bossSprite)
		write_byte(0)
		write_byte(1)
		write_byte(6)
		write_byte(2)
		write_byte(1)
		write_byte(255)
		write_byte(0)
		write_byte(0)
		write_byte(255)
		write_byte(6)
		message_end()
		set_task(1.5, "boss_beacon_effect", id)
	}
}

play_boss_ambience_sound()
{
	remove_task(TASK_AMBIENCE_SOUND)
	remove_task(TASK_BOSS_AMBIENCE_SOUND)
	set_task(0.5, "boss_ambience_sound_effect", TASK_BOSS_AMBIENCE_SOUND)
}

public boss_ambience_sound_effect()
{
	remove_task(TASK_AMBIENCE_SOUND)
	remove_task(TASK_BOSS_AMBIENCE_SOUND)
	new sound_index = random_num(0, sizeof SOUND_AMBIENCE_BOSS - 1)
	PlaySound(0, SOUND_AMBIENCE_BOSS[sound_index])
	set_task(boss_ambience_duration[sound_index], "boss_ambience_sound_effect", TASK_BOSS_AMBIENCE_SOUND)
}

///////////////////////////////////////////////////////////////////
// Zombie/Survivor Respawn                                       //
///////////////////////////////////////////////////////////////////
public zombie_respawner(taskid)
{
	if (g_roundend)
		return;

	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET)
	new id = taskid-TASK_RESPAWN
	new cts[32], ts[32], ctsnum, tsnum
	new CsTeams:team
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_alive(i))
			continue;

		team = cs_get_user_team(i)
		if (team == CS_TEAM_T)
			ts[tsnum++] = i
		else if (team == CS_TEAM_CT)
			cts[ctsnum++] = i
	}

	if (tsnum > 1)
	{
		static zr ,zg, zb
		zr = get_pcvar_num(cvar_render_zr)
		zg = get_pcvar_num(cvar_render_zg)
		zb = get_pcvar_num(cvar_render_zb)
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")
		cs_set_user_armor(id, (get_pcvar_num(cvar_zombiearmor)*g_level), CS_ARMOR_VESTHELM)
		switch (get_pcvar_num(cvar_zombie_spawnpoint))
		{
			case 0:
			{
				ExecuteHamB(Ham_CS_RoundRespawn, id)
			}
			case 1:
			{
				pev(id, pev_origin, g_vec_last_origin[id])
				engfunc(EngFunc_SetOrigin, id, g_vec_last_origin[id])
				ExecuteHamB(Ham_CS_RoundRespawn, id)
			}
		}
		if ((get_pcvar_float(cvar_zombie_protect) > 0.0) && (cs_get_user_team(id) == CS_TEAM_T))
		{
			fm_set_user_godmode(id, 1)
			fm_set_rendering(id, kRenderFxGlowShell, zr, zg, zb, kRenderNormal, 0)
			set_task(1.0, "respawn_effect", id)
		}
		set_task((get_pcvar_float(cvar_zombie_protect)), "remove_zombie_protection", id)
	}
}

public survivor_respawner(taskid)
{
	if (g_roundend)
		return;

	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET)
	new id = taskid-TASK_RESPAWN
	pev(id, pev_origin, g_vec_last_origin[id])
	engfunc(EngFunc_SetOrigin, id, g_vec_last_origin[id])
	ExecuteHamB(Ham_CS_RoundRespawn, id)
	if (get_pcvar_float(cvar_survivor_protect) > 0.0)
	{
		static ctr ,ctg, ctb
		ctr = get_pcvar_num(cvar_render_ctr)
		ctg = get_pcvar_num(cvar_render_ctg)
		ctb = get_pcvar_num(cvar_render_ctb)
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			fm_set_user_godmode(id, 1)
			fm_set_rendering(id, kRenderFxGlowShell, ctr, ctg, ctb, kRenderNormal, 0)
		}
	}

	if ((!is_user_bot(id) && (get_pcvar_num(cvar_survivor_giveweap) >= 1)) || (is_user_bot(id) && (get_pcvar_num(cvar_bot_giveweap) >= 1)))
	{
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")
		new pri_weapons[18], pri_weapon_num, sec_weapons[6], sec_weapon_num
		get_user_has_weapons(id, pri_weapons, pri_weapon_num, sec_weapons, sec_weapon_num)
		new gun_sets_index, weapon_id, weapon_id2
		gun_sets_index = random_num(0, (GUN_SETS_NUM - 1))
		weapon_id = get_weaponid(GIVE_GUN_1[gun_sets_index])
		weapon_id2 = get_weaponid(GIVE_GUN_2[gun_sets_index])
		if (((!is_user_bot(id) && ((get_pcvar_num(cvar_survivor_giveweap) == 1) || (get_pcvar_num(cvar_survivor_giveweap) == 3))) || (is_user_bot(id) && ((get_pcvar_num(cvar_bot_giveweap) == 1) || (get_pcvar_num(cvar_bot_giveweap) == 3)))) && ((1<<weapon_id) & PRIMARY_WEAPONS_BIT_SUM))
		{
			fm_give_item(id, GIVE_GUN_1[gun_sets_index])
			cs_set_user_bpammo(id, weapon_id, MAX_BPAMMO[weapon_id])
		}

		if (((!is_user_bot(id) && ((get_pcvar_num(cvar_survivor_giveweap) == 2) || (get_pcvar_num(cvar_survivor_giveweap) == 3))) || (is_user_bot(id) && ((get_pcvar_num(cvar_bot_giveweap) == 2) || (get_pcvar_num(cvar_bot_giveweap) == 3)))) && ((1<<weapon_id2) & SECONDARY_WEAPONS_BIT_SUM))
		{
			fm_give_item(id, GIVE_GUN_2[gun_sets_index])
			cs_set_user_bpammo(id, weapon_id2, MAX_BPAMMO[weapon_id])
		}
	}
	else
	{
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")
		fm_give_item(id, "weapon_usp")
	}
	set_task((get_pcvar_float(cvar_survivor_protect)), "remove_survivor_protection", id)
}

///////////////////////////////////////////////////////////////////
// Respawn Effect                                                //
///////////////////////////////////////////////////////////////////
public respawn_effect(id)
{
	if (get_pcvar_num(cvar_zombie_effect))
	{
		static Float:FOrigin3[3]
		pev(id, pev_origin, FOrigin3)
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, FOrigin3, 0)
		write_byte(TE_IMPLOSION)
		engfunc(EngFunc_WriteCoord, FOrigin3[0])
		engfunc(EngFunc_WriteCoord, FOrigin3[1])
		engfunc(EngFunc_WriteCoord, FOrigin3[2])
		write_byte(255)
		write_byte(255)
		write_byte(5)
		message_end()
	}
}

///////////////////////////////////////////////////////////////////
// Respawn Protection                                            //
///////////////////////////////////////////////////////////////////
public remove_zombie_protection(id)
{
	if (get_pcvar_float(cvar_survivor_protect) > 0.0)
	{
		fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
		fm_set_user_godmode(id, 0)
	}
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
}

public remove_survivor_protection(id)
{
	if (get_pcvar_float(cvar_survivor_protect) > 0.0)
	{
		fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
		fm_set_user_godmode(id, 0)
	}
}

///////////////////////////////////////////////////////////////////
// Fire Grenade / Frost Grenade / Flare Grenade                  //
///////////////////////////////////////////////////////////////////
public fw_SetModel(ent, model[])
{
	if (!pev_valid(ent))
		return FMRES_IGNORED;

	// We don't care
	if (strlen(model) < 8)
		return FMRES_IGNORED;

	if (get_pcvar_float(cvar_remove_weapon_time) > 0.0)
	{
		static classname[10]
		pev(ent, pev_classname, classname, charsmax(classname))
		if (equal(classname, "weaponbox"))
		{
			set_pev(ent, pev_nextthink, get_gametime() + get_pcvar_float(cvar_remove_weapon_time))
		}
	}

	// Narrow down our matches a bit
	if (model[7] != 'w' || model[8] != '_')
		return FMRES_IGNORED;

	// Get damage time of grenade
	static Float:dmgtime
	pev(ent, pev_dmgtime, dmgtime)
	if (dmgtime == 0.0)
		return FMRES_IGNORED;

	if (equal(model[7], "w_he", 4)) // Fire Grenade
	{
		// Give it a glow
		fm_set_rendering(ent, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 16)

		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(ent) // entity
		write_short(g_trailSprite) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(255) // r
		write_byte(0) // g
		write_byte(0) // b
		write_byte(255) // brightness
		message_end()

		// Set grenade type on the thrown grenade entity
		set_pev(ent, PEV_NADE_TYPE, NADE_TYPE_FIRE)
	}
	else if (equal(model[7], "w_fl", 4)) // Frost Grenade
	{
		// Give it a glow
		fm_set_rendering(ent, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 16)

		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(ent) // entity
		write_short(g_trailSprite) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(0) // r
		write_byte(100) // g
		write_byte(200) // b
		write_byte(200) // brightness
		message_end()

		// Set grenade type on the thrown grenade entity
		set_pev(ent, PEV_NADE_TYPE, NADE_TYPE_FROST)
	}
	else if (equal(model[7], "w_sm", 4)) // Flare Grenade
	{
		// Build flare's color
		static rgb[3]
		switch (get_pcvar_num(cvar_flare_color))
		{
			case 0: // white
			{
				rgb[0] = 255 // r
				rgb[1] = 255 // g
				rgb[2] = 255 // b
			}
			case 1: // red
			{
				rgb[0] = random_num(50, 255) // r
				rgb[1] = 0 // g
				rgb[2] = 0 // b
			}
			case 2: // green
			{
				rgb[0] = 0 // r
				rgb[1] = random_num(50, 255) // g
				rgb[2] = 0 // b
			}
			case 3: // blue
			{
				rgb[0] = 0 // r
				rgb[1] = 0 // g
				rgb[2] = random_num(50, 255) // b
			}
			case 4: // random (all colors)
			{
				rgb[0] = random_num(50, 200) // r
				rgb[1] = random_num(50, 200) // g
				rgb[2] = random_num(50, 200) // b
			}
			case 5: // random (r,g,b)
			{
				switch (random_num(1, 3))
				{
					case 1: // red
					{
						rgb[0] = random_num(50, 255) // r
						rgb[1] = 0 // g
						rgb[2] = 0 // b
					}
					case 2: // green
					{
						rgb[0] = 0 // r
						rgb[1] = random_num(50, 255) // g
						rgb[2] = 0 // b
					}
					case 3: // blue
					{
						rgb[0] = 0 // r
						rgb[1] = 0 // g
						rgb[2] = random_num(50, 255) // b
					}
				}
			}
			case 6: // custom (r,g,b)
			{
				static flare_rgb[32], red[4], green[4], blue[4]
				get_pcvar_string(cvar_flare_rgb, flare_rgb, charsmax(flare_rgb))
				parse(flare_rgb, red, charsmax(red), green, charsmax(green), blue, charsmax(blue))
				rgb[0] = str_to_num(red) // r
				rgb[1] = str_to_num(green) // g
				rgb[2] = str_to_num(blue) // b
			}
		}

		// Give it a glow
		fm_set_rendering(ent, kRenderFxGlowShell, rgb[0], rgb[1], rgb[2], kRenderNormal, 16)

		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(ent) // entity
		write_short(g_trailSprite) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(rgb[0]) // r
		write_byte(rgb[1]) // g
		write_byte(rgb[2]) // b
		write_byte(200) // brightness
		message_end()

		// Set grenade type on the thrown grenade entity
		set_pev(ent, PEV_NADE_TYPE, NADE_TYPE_FLARE)

		// Set flare color on the thrown grenade entity
		set_pev(ent, PEV_FLARE_COLOR, rgb)

		// Light up flag clear
		set_pev(ent, PEV_FLARE_DURATION, 0)
	}
	return FMRES_IGNORED;
}

public fw_ThinkGrenade(ent)
{
	// Invalid entity
	if (!pev_valid(ent))
		return HAM_IGNORED;

	// Get damage time of grenade
	static Float:dmgtime, Float:current_time
	pev(ent, pev_dmgtime, dmgtime)
	current_time = get_gametime()

	// Check if it's time to go off
	if (dmgtime > current_time)
		return HAM_IGNORED;

	// Check if it's one of our custom nades
	switch (pev(ent, PEV_NADE_TYPE))
	{
		case NADE_TYPE_FIRE: // Fire Grenade
		{
			// Reset nada to prevent loop in here again
			set_pev(ent, PEV_NADE_TYPE, 0)

			// Fire grenade explode sound
			emit_sound(ent, CHAN_WEAPON, SOUND_FIRE_EXPLODE, 1.0, ATTN_NORM, 0, PITCH_NORM)

			static Float:origin[3]
			pev(ent, pev_origin, origin)
			fire_explode(origin)
		}
		case NADE_TYPE_FROST: // Frost Grenade
		{
			frost_explode(ent)
			return HAM_SUPERCEDE;
		}
		case NADE_TYPE_FLARE: // Flare Grenade
		{
			static duration
			duration = pev(ent, PEV_FLARE_DURATION)
			if (duration > 0)
			{
				// Check whether this is the last loop
				if (duration <= 1)
				{
					engfunc(EngFunc_RemoveEntity, ent)
					return HAM_SUPERCEDE;
				}
				flare_lighting(ent, duration)
				set_pev(ent, PEV_FLARE_DURATION, --duration)
				set_pev(ent, pev_dmgtime, current_time + 5.0)
			}
			else if ((pev(ent, pev_flags) & FL_ONGROUND) && fm_get_speed(ent) < 10)
			{
				emit_sound(ent, CHAN_WEAPON, SOUND_FLARE_ON, 1.0, ATTN_NORM, 0, PITCH_NORM)
				set_pev(ent, PEV_FLARE_DURATION, 1 + floatround(get_pcvar_float(cvar_flare_duration) / 5.0))
				set_pev(ent, pev_dmgtime, current_time + 0.1)
			}
			else
			{
				set_pev(ent, pev_dmgtime, current_time + 0.5)
			}
		}
	}
	return HAM_IGNORED;
}

// Fire Grenade Explosion
fire_explode(Float:originF[3])
{
	// Make the explosion
	fire_blast_effect(originF)

	// Collisions
	new target, Float:duration
	target = -1
	while ((target = engfunc(EngFunc_FindEntityInSphere, target, originF, NADE_EXPLOSION_RADIUS)) != 0)
	{
		// Only effect alive zombies, but not no dmage players.
		if (!(1 <= target <= g_maxplayers) || !is_user_connected(target) || !is_user_alive(target) || !g_zombie[target] ||
		get_user_godmode(target) || fm_get_user_godmode(target))
			continue;

		// Heat icon
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, target)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_BURN) // damage type
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()

		if (g_boss[target])
			duration = get_pcvar_float(cvar_fire_duration) / 2.0	//火焰彈對殭屍王的傷害時間減半
		else
			duration = get_pcvar_float(cvar_fire_duration)

		g_burning[target] = true
		remove_task(target+TASK_BURN)
		set_task(0.1, "burning_flame", target+TASK_BURN)
		set_task(0.1, "burning_damage", target+TASK_BURN)
		set_task(duration, "burning_over", target+TASK_BURN)
	}
}

// Fire Grenade: Fire Blast
fire_blast_effect(const Float:originF[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_exploSprite) // sprite
	write_byte(1) // startframe
	write_byte(1) // framerate
	write_byte(3) // life
	write_byte(50) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(150) // green
	write_byte(0) // blue
	write_byte(250) // brightness
	write_byte(1) // speed
	message_end()

	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_exploSprite) // sprite
	write_byte(1) // startframe
	write_byte(1) // framerate
	write_byte(3) // life
	write_byte(50) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(100) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(1) // speed
	message_end()

	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_exploSprite) // sprite
	write_byte(1) // startframe
	write_byte(1) // framerate
	write_byte(3) // life
	write_byte(50) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(50) // green
	write_byte(0) // blue
	write_byte(150) // brightness
	write_byte(1) // speed
	message_end()
}

// Burning Flames
public burning_flame(taskid)
{
	new id = taskid-TASK_BURN
	if (!g_burning[id])
		return;

	// Get player origin and flags
	new origin[3], flags
	get_user_origin(id, origin)
	flags = pev(id, pev_flags)
	if ((flags & FL_INWATER))
	{
		// Set over burning task
		set_task(1.0, "burning_over", id+TASK_BURN)
		return;
	}

	// Randomly play burning zombie scream sounds
	if (random_num(0, 25) == 0)
	{
		static sound_index
		sound_index = random_num(0, sizeof SOUND_FIRE_PLAYER_SCREAM - 1)
		emit_sound(id, CHAN_VOICE, SOUND_FIRE_PLAYER_SCREAM[sound_index], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	// Fire slow down
	if ((flags & FL_ONGROUND) && get_pcvar_float(cvar_fire_slowdown) > 0.0)
	{
		static Float:velocity[3]
		pev(id, pev_velocity, velocity)
		xs_vec_mul_scalar(velocity, get_pcvar_float(cvar_fire_slowdown), velocity)
		set_pev(id, pev_velocity, velocity)
	}

	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+random_num(-10, 10)) // z
	write_short(g_fireSprite) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()
	set_task(0.1, "burning_flame", taskid)
}

// Burning Make Damage
public burning_damage(taskid)
{
	new id = taskid-TASK_BURN
	if (!is_user_alive(id) || !g_burning[id])
		return;

	// Get player origin
	new origin[3]
	get_user_origin(id, origin)

	// Get player's health
	new health, damage
	health = pev(id, pev_health)
	damage = floatround(get_pcvar_float(cvar_fire_damage), floatround_ceil)
	if (health - damage > 0)
	{
		fm_set_user_health(id, health - damage)
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, id)
		write_byte(30)
		write_byte(30)
		write_long(DMG_SLOWBURN)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		message_end()
	}
	set_task(get_pcvar_float(cvar_fire_damagemul), "burning_damage", taskid)
}

// User Burning Over
public burning_over(taskid)
{
	new id = taskid-TASK_BURN
	// Not alive or not burning anymore
	if (!is_user_alive(id) || !g_burning[id])
		return;

	// Task not needed anymore
	remove_task(id+TASK_BURN)

	// Over burning
	g_burning[id] = false

	// Get player origin
	new origin[3]
	get_user_origin(id, origin)

	// Smoke sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SMOKE) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]-50) // z
	write_short(g_smokeSprite) // sprite
	write_byte(random_num(15, 20)) // scale
	write_byte(random_num(10, 20)) // framerate
	message_end()
}

// Frost Grenade Explosion
frost_explode(ent)
{
	// Get origin
	new Float:originF[3]
	pev(ent, pev_origin, originF)

	// Make the explosion
	frost_blast_effect(originF)

	// Frost grenade explode sound
	emit_sound(ent, CHAN_WEAPON, SOUND_FROST_EXPLODE, 1.0, ATTN_NORM, 0, PITCH_NORM)

	// Collisions
	new target
	target = -1
	while ((target = engfunc(EngFunc_FindEntityInSphere, target, originF, NADE_EXPLOSION_RADIUS)) != 0)
	{
		// Only effect alive unfrozen zombies, but not no dmage players.
		if (!(1 <= target <= g_maxplayers) || !is_user_connected(target) || !g_zombie[target] || g_frozen[target] ||
		get_user_godmode(target) || fm_get_user_godmode(target))
			continue;

		// Freeze icon
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, target)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_DROWN) // damage type - DMG_FREEZE
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()

		// Light blue glow while frozen
		fm_set_rendering(target, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 25)

		// Freeze sound
		emit_sound(target, CHAN_BODY, SOUND_FROST_PLAYER, 1.0, ATTN_NORM, 0, PITCH_NORM)

		// Add a blue tint to their screen
		message_begin(MSG_ONE, g_msgScreenFade, _, target)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(FFADE_STAYOUT) // fade type
		write_byte(0) // red
		write_byte(50) // green
		write_byte(200) // blue
		write_byte(100) // alpha
		message_end()

		// Prevent from jumping
		if (pev(target, pev_flags) & FL_ONGROUND)
			set_pev(target, pev_gravity, 999999.9) // set really high
		else
			set_pev(target, pev_gravity, 0.000001) // no gravity

		// Set a task to remove the freeze
		g_frozen[target] = true

		if (g_boss[target])
			set_task(0.5, "freeze_over", target+TASK_UNFROZEN)
		else
			set_task(get_pcvar_float(cvar_freeze_duration), "freeze_over", target+TASK_UNFROZEN)
	}
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, ent)
}

// Frost Grenade: Freeze Blast
frost_blast_effect(const Float:originF[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_exploSprite) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()

	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_exploSprite) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()

	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_exploSprite) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

// User Freeze Over
public freeze_over(taskid)
{
	new id = taskid-TASK_UNFROZEN
	if (!is_user_alive(id) || !g_frozen[id])
		return;

	// Unfreeze
	g_frozen[id] = false

	// Restore maxspeed and gravity
	fm_set_user_maxspeed(id, g_user_maxspeed[id])
	set_pev(id, pev_gravity, 1.0)

	// Restore rendering
	fm_set_rendering(id)

	// Gradually remove screen's blue tint
	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short(UNIT_SECOND) // duration
	write_short(0) // hold time
	write_short(FFADE_IN) // fade type
	write_byte(0) // red
	write_byte(50) // green
	write_byte(200) // blue
	write_byte(100) // alpha
	message_end()

	// Broken glass sound
	emit_sound(id, CHAN_BODY, SOUND_FROST_BREAK, 1.0, ATTN_NORM, 0, PITCH_NORM)

	// Get player's origin
	new origin[3]
	get_user_origin(id, origin)

	// Glass shatter
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_BREAKMODEL) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]+24) // z
	write_coord(16) // size x
	write_coord(16) // size y
	write_coord(16) // size z
	write_coord(random_num(-50, 50)) // velocity x
	write_coord(random_num(-50, 50)) // velocity y
	write_coord(25) // velocity z
	write_byte(10) // random velocity
	write_short(g_glassSprite) // model
	write_byte(10) // count
	write_byte(25) // life
	write_byte(BREAK_GLASS) // flags
	message_end()
}

// Flare Lighting Effects
flare_lighting(ent, duration)
{
	// Get origin and color
	new Float:originF[3], color[3]
	pev(ent, pev_origin, originF)
	pev(ent, PEV_FLARE_COLOR, color)

	// Lighting
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(get_pcvar_num(cvar_flare_size)) // radius
	write_byte(color[0]) // r
	write_byte(color[1]) // g
	write_byte(color[2]) // b
	write_byte(51) //life
	write_byte((duration < 2) ? 3 : 0) //decay rate
	message_end()

	// Sparks
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPARKS) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	message_end()
}

// Remove Stuff Task
public remove_stuff()
{
	static ent, removedoors
	removedoors = get_pcvar_num(cvar_removedoors)
	if ((removedoors == 1) || (removedoors == 3))
	{
		ent = -1;
		while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_door")) != 0)
			engfunc(EngFunc_SetOrigin, ent, Float:{8192.0 ,8192.0 ,8192.0})
	}

	if ((removedoors == 2) || (removedoors == 3))
	{
		ent = -1;
		while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_door_rotating")) != 0)
			engfunc(EngFunc_SetOrigin, ent, Float:{8192.0 ,8192.0 ,8192.0})
	}
	set_task(0.1, "remove_stuff")
}

///////////////////////////////////////////////////////////////////
// Survivor Weapon Menu                                          //
///////////////////////////////////////////////////////////////////
public cmd_buy(id)
{
	return PLUGIN_HANDLED;
}

public cmd_chooseteam(id)
{
	new CsTeams:team = cs_get_user_team(id)
	if (team == CS_TEAM_UNASSIGNED || team == CS_TEAM_SPECTATOR)
		return PLUGIN_CONTINUE;

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return PLUGIN_HANDLED;
	}

	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		weapons_menu(id)
	}
	return PLUGIN_HANDLED;
}

public cmd_buyequip(id)
{
	new CsTeams:team = cs_get_user_team(id)
	if (team == CS_TEAM_UNASSIGNED || team == CS_TEAM_SPECTATOR)
		return PLUGIN_CONTINUE;

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return PLUGIN_HANDLED;
	}

	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		equip_menu(id)
	}
	return PLUGIN_HANDLED;
}

public cmd_buyammo1(id)
{
	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return PLUGIN_HANDLED;
	}

	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		buy_pri_ammo(id)
	}
	return PLUGIN_HANDLED;
}

public cmd_buyammo2(id)
{
	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return PLUGIN_HANDLED;
	}

	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		buy_sec_ammo(id)
	}
	return PLUGIN_HANDLED;
}

public cmd_primammo(id)
{
	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return PLUGIN_HANDLED;
	}

	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		primammo(id)
	}
	return PLUGIN_HANDLED;
}

public cmd_secammo(id)
{
	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return PLUGIN_HANDLED;
	}

	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		secammo(id)
	}
	return PLUGIN_HANDLED;
}

weapons_menu(id)
{
	if (!is_user_alive(id) || (cs_get_user_team(id) != CS_TEAM_CT))
		return;

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return;
	}

	new menu_name[32]
	formatex(menu_name, sizeof menu_name - 1, "\y%L", id, "ZH_BUYMENU")
	new menu = menu_create(menu_name, "weapons_select")
	new itemname[64], data[2]
	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_PRIMENU")
	data[0] = 1
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_SECMENU")
	data[0] = 2
	//data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_EQUIP")
	data[0] = 3
	//data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_PRIAMMO")
	data[0] = 4
	//data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_SECAMMO")
	data[0] = 5
	//data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_PRIAMMOS")
	data[0] = 6
	//data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_SECAMMOS")
	data[0] = 7
	//data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	new exit_n[32]
	formatex(exit_n, sizeof exit_n - 1, "%L", id, "ZH_QUIT")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_EXITNAME, exit_n)
	menu_display(id, menu, 0)
}

public weapons_select(id, menu, item)
{
	if (!is_user_alive(id) || (item == MENU_EXIT))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return PLUGIN_HANDLED;
	}

	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		new data[2], itemname[64], access, callback, itemid
		menu_item_getinfo(menu, item, access, data, 5, itemname, 63, callback)
		itemid = data[0]
		switch (itemid)
		{
			case 1: pri_weap_menu(id)
			case 2: sec_weap_menu(id)
			case 3: equip_menu(id)
			case 4: buy_pri_ammo(id)
			case 5: buy_sec_ammo(id)
			case 6: primammo(id)
			case 7: secammo(id)
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED;
}

pri_weap_menu(id)
{
	if (!is_user_alive(id) || cs_get_user_team(id) != CS_TEAM_CT)
		return;

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return;
	}

	new menu_name[32]
	formatex(menu_name, sizeof menu_name - 1, "\y%L", id, "ZH_PRIMENU")
	new menu = menu_create(menu_name, "pri_weap_select")
	new i, itemname[64], data[2], weapon_id
	for (i = 0; i < sizeof MenuPriWeaponItems; i++)
	{
		weapon_id = get_string_index(WEAPON_CLASSNAME, (CSW_P90+1), MenuPriWeaponItems[i])
		if (weapon_id && ((1<<weapon_id) & PRIMARY_WEAPONS_BIT_SUM))
		{
			format(itemname, 63, "\w%s ($%d)", WEAPON_NAME[weapon_id], WEAPON_COST[weapon_id])
			data[0] = weapon_id
			data[1] = '^0'
			menu_additem(menu, itemname, data, 0, -1)
		}
	}
	new back_n[32], next_n[32], exit_n[32]
	formatex(back_n, sizeof back_n - 1, "%L", id, "ZH_PREV")
	formatex(next_n, sizeof next_n - 1, "%L", id, "ZH_NEXT")
	formatex(exit_n, sizeof exit_n - 1, "%L", id, "ZH_QUIT")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_BACKNAME, back_n)
	menu_setprop(menu, MPROP_NEXTNAME, next_n)
	menu_setprop(menu, MPROP_EXITNAME, exit_n)
	menu_display(id, menu, 0)
}

public pri_weap_select(id, menu, item)
{
	if (!is_user_alive(id) || (item == MENU_EXIT))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return PLUGIN_HANDLED;
	}

	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		new data[2], itemname[64], access, callback, weapon_id
		menu_item_getinfo(menu, item, access, data, 5, itemname, 63, callback)
		weapon_id = data[0]
		if (weapon_id)
		{
			buy_pri_weapon(id, weapon_id)
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED;
}

sec_weap_menu(id)
{
	if (!is_user_alive(id) || cs_get_user_team(id) != CS_TEAM_CT)
		return;

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return;
	}

	new menu_name[32]
	formatex(menu_name, sizeof menu_name - 1, "\y%L", id, "ZH_SECMENU")
	new menu = menu_create(menu_name, "sec_weap_select")
	new i, itemname[64], data[2], weapon_id
	for (i = 0; i < sizeof MenuSecWeaponItems; i++)
	{
		weapon_id = get_string_index(WEAPON_CLASSNAME, (CSW_P90+1), MenuSecWeaponItems[i])
		if (weapon_id && ((1<<weapon_id) & SECONDARY_WEAPONS_BIT_SUM))
		{
			format(itemname, 63, "\w%s ($%d)", WEAPON_NAME[weapon_id], WEAPON_COST[weapon_id])
			data[0] = weapon_id
			data[1] = '^0'
			menu_additem(menu, itemname, data, 0, -1)
		}
	}
	new exit_n[32]
	formatex(exit_n, sizeof exit_n - 1, "%L", id, "ZH_QUIT")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_EXITNAME, exit_n)
	menu_display(id, menu, 0)
}

public sec_weap_select(id, menu, item)
{
	if (!is_user_alive(id) || (item == MENU_EXIT))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return PLUGIN_HANDLED;
	}

	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		new data[6], itemname[64], access, callback, weapon_id
		menu_item_getinfo(menu, item, access, data,5, itemname, 63, callback)
		weapon_id = data[0]
		if (weapon_id)
		{
			buy_sec_weapon(id, weapon_id)
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED;
}

equip_menu(id)
{
	if (!is_user_alive(id) || cs_get_user_team(id) != CS_TEAM_CT)
		return;

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return;
	}

	new menu_name[32]
	formatex(menu_name, sizeof menu_name - 1, "\y%L", id, "ZH_EQUIP")
	new menu = menu_create(menu_name, "equip_select")
	new itemname[64], data[2]
	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_ARMOR")
	data[0] = 1
	data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_FIREBANG")
	data[0] = 2
	//data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_FROZEBANG")
	data[0] = 3
	//data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_FLAREBANG")
	data[0] = 4
	//data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)

	formatex(itemname, sizeof itemname - 1, "%L", id, "ZH_NVG")
	data[0] = 5
	//data[1] = '^0'
	menu_additem(menu, itemname, data, 0, -1)
	new exit_n[32]
	formatex(exit_n, sizeof exit_n - 1, "%L", id, "ZH_QUIT")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_EXITNAME, exit_n)
	menu_display(id, menu, 0)
}

public equip_select(id, menu, item)
{
	if (!is_user_alive(id) || (item == MENU_EXIT))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return PLUGIN_HANDLED;
	}

	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		new data[6], itemname[64], access, callback, itemid
		menu_item_getinfo(menu, item, access, data,5, itemname, 63, callback)
		itemid = data[0]
		switch (itemid)
		{
			case 1: //護甲(VESTHELM)
			{
				buy_armor(id)
			}
			case 2: //火焰彈
			{
				buy_grenade(id, CSW_HEGRENADE)
			}
			case 3: //冰凍彈
			{
				buy_grenade(id, CSW_FLASHBANG)
			}
			case 4: //照明彈
			{
				buy_grenade(id, CSW_SMOKEGRENADE)
			}
			case 5: //夜視鏡
			{
				buy_nvg(id)
			}
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED;
}

buy_pri_weapon(id, weapon_id)
{
	if ((!((1<<weapon_id) & PRIMARY_WEAPONS_BIT_SUM)))
		return;

	new pri_weapons[18], pri_weapon_num, sec_weapons[6], sec_weapon_num
	get_user_has_weapons(id, pri_weapons, pri_weapon_num, sec_weapons, sec_weapon_num)
	new i, bool:already_has_weapon
	already_has_weapon = false
	for (i = 0; i < pri_weapon_num; i++)
	{
		if (pri_weapons[i] == weapon_id)
			already_has_weapon = true
	}

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return;
	}

	if (already_has_weapon)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_ALREADYHAVE")
		return;
	}

	new money, cost
	money = cs_get_user_money(id)
	cost = WEAPON_COST[weapon_id]
	if (money < cost)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_NOMONEY")
		return;
	}

	if (pri_weapon_num > 0)
		drop_weapons(id, 1)

	fm_give_item(id, WEAPON_CLASSNAME[weapon_id])
	cs_set_user_money(id, money - cost)
}

buy_sec_weapon(id, weapon_id)
{
	if (!((1<<weapon_id) & SECONDARY_WEAPONS_BIT_SUM))
		return;

	new pri_weapons[18], pri_weapon_num, sec_weapons[6], sec_weapon_num
	get_user_has_weapons(id, pri_weapons, pri_weapon_num, sec_weapons, sec_weapon_num)
	new i, bool:already_has_weapon
	already_has_weapon = false
	for (i = 0; i < sec_weapon_num; i++)
	{
		if (sec_weapons[i] == weapon_id)
			already_has_weapon = true
	}

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return;
	}

	if (already_has_weapon)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_ALREADYHAVE")
		return;
	}

	new money, cost
	money = cs_get_user_money(id)
	cost = WEAPON_COST[weapon_id]
	if (money < cost)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_NOMONEY")
		return;
	}

	if (sec_weapon_num > 0)
		drop_weapons(id, 2)

	fm_give_item(id, WEAPON_CLASSNAME[weapon_id])
	cs_set_user_money(id, money - cost)
}

buy_armor(id)
{
	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return;
	}

	new iArmor, CsArmorType:iArmortype
	iArmor = cs_get_user_armor(id, iArmortype)
	if (iArmor >= MAX_ARMOR_VALUE)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_AMORFULL")
		return;
	}

	new money, cost
	money = cs_get_user_money(id)
	cost = ARMOR_VESTHELM_COST
	if (money < cost)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_NOMONEY")
		return;
	}
	new give_armor_value
	give_armor_value = min(iArmor + 100, MAX_ARMOR_VALUE)
	cs_set_user_armor(id, give_armor_value, CS_ARMOR_VESTHELM)
	emit_sound(id, CHAN_BODY, SOUND_PICK_ARMOR, 1.0, ATTN_NORM, 0, PITCH_NORM)
	cs_set_user_money(id, money - cost)
}

buy_grenade(id, grenade_id)
{
	if (!(grenade_id == CSW_HEGRENADE || grenade_id == CSW_FLASHBANG || grenade_id == CSW_SMOKEGRENADE))
		return;

	new money, cost, n
	money = cs_get_user_money(id)
	switch (grenade_id)
	{
		case CSW_HEGRENADE:
		{
			cost = FIRE_GRENADE_COST
			n = MAX_FIRE_VALUE
		}
		case CSW_FLASHBANG:
		{
			cost = FROST_GRENADE_COST
			n = MAX_FROST_VALUE
		}
		case CSW_SMOKEGRENADE:
		{
			cost = FLARE_GRENADE_COST
			n = MAX_FLARE_VALUE
		}
	}

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return;
	}

	if (cs_get_user_bpammo(id, grenade_id) >= n)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_FULL")
		return;
	}

	if (money < cost)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_NOMONEY")
		return;
	}

	new grenade_name[32], grenade_num
	get_weaponname(grenade_id, grenade_name, charsmax(grenade_name))
	grenade_num = cs_get_user_bpammo(id, grenade_id)
	if (grenade_num <= 0)
	{
		fm_give_item(id, grenade_name)
	}
	else
	{
		cs_set_user_bpammo(id, grenade_id, ++grenade_num)
		emit_sound(id, CHAN_ITEM, SOUND_PICK_GRENADE, 1.0, ATTN_NORM, 0, PITCH_NORM)

		// Flash ammo in hud
		message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, _, id)
		write_byte(WEAPON_AMMOID[grenade_id]) // ammo id
		write_byte(1) // ammo amount
		message_end()
	}
	cs_set_user_money(id, money - cost)
}

buy_nvg(id)
{
	if (cs_get_user_nvg(id))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_ALREADYHAVE")
		return;
	}

	if ((get_pcvar_num(cvar_survivor_buyzone) == 1) && (cs_get_user_buyzone(id) == 0))
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_BUYZONE")
		return;
	}

	new money, cost
	money = cs_get_user_money(id)
	cost = NIGHT_VISION_COST
	if (money < cost)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_NOMONEY")
		return;
	}
	cs_set_user_nvg(id, 1)
	cs_set_user_money(id, money - cost)
}

buy_pri_ammo(id)
{
	new pri_weapons[18], pri_weapon_num, sec_weapons[6], sec_weapon_num
	get_user_has_weapons(id, pri_weapons, pri_weapon_num, sec_weapons, sec_weapon_num)
	if (pri_weapon_num <= 0)
		return;

	new weapon_id = pri_weapons[0]
	if (cs_get_user_bpammo(id, weapon_id) >= MAX_BPAMMO[weapon_id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_FULL")
		return;
	}

	new money, cost
	money = cs_get_user_money(id)
	cost = AMMO_COST[WEAPON_AMMOID[weapon_id]]
	if (money < cost)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_NOMONEY")
		return;
	}
	ExecuteHamB(Ham_GiveAmmo, id, BUY_AMMO[weapon_id], AMMO_TYPE[weapon_id], MAX_BPAMMO[weapon_id])
	emit_sound(id, CHAN_ITEM, SOUND_PICK_AMMO, 1.0, ATTN_NORM, 0, PITCH_NORM)
	cs_set_user_money(id, money - cost)
}

buy_sec_ammo(id)
{
	new pri_weapons[18], pri_weapon_num, sec_weapons[6], sec_weapon_num
	get_user_has_weapons(id, pri_weapons, pri_weapon_num, sec_weapons, sec_weapon_num)
	if (sec_weapon_num <= 0)
		return;

	new weapon_id = sec_weapons[0]
	if (cs_get_user_bpammo(id, weapon_id) >= MAX_BPAMMO[weapon_id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_FULL")
		return;
	}

	new money, cost
	money = cs_get_user_money(id)
	cost = AMMO_COST[WEAPON_AMMOID[weapon_id]]
	if (money < cost)
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_NOMONEY")
		return;
	}
	ExecuteHamB(Ham_GiveAmmo, id, BUY_AMMO[weapon_id], AMMO_TYPE[weapon_id], MAX_BPAMMO[weapon_id])
	emit_sound(id, CHAN_ITEM, SOUND_PICK_AMMO, 1.0, ATTN_NORM, 0, PITCH_NORM)
	cs_set_user_money(id, money - cost)
}

primammo(id)
{
	new pri_weapons[18], pri_weapon_num, sec_weapons[6], sec_weapon_num
	get_user_has_weapons(id, pri_weapons, pri_weapon_num, sec_weapons, sec_weapon_num)
	if (pri_weapon_num <= 0)
		return;

	new weapon_id = pri_weapons[0]
	if (cs_get_user_bpammo(id, weapon_id) >= MAX_BPAMMO[weapon_id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_FULL")
		return;
	}

	new money, cost, maxcost, ammo
	money = cs_get_user_money(id)
	maxcost = AMMO_COST[WEAPON_AMMOID[weapon_id]] * ((MAX_BPAMMO[weapon_id] - cs_get_user_bpammo(id, weapon_id))/BUY_AMMO[weapon_id])
	if ((MAX_BPAMMO[weapon_id] - cs_get_user_bpammo(id, weapon_id)) >= BUY_AMMO[weapon_id])
	{
		cost = (AMMO_COST[WEAPON_AMMOID[weapon_id]])*(((MAX_BPAMMO[weapon_id] - cs_get_user_bpammo(id, weapon_id))/BUY_AMMO[weapon_id]))
	}
	else
	{
		if ((MAX_BPAMMO[weapon_id] - cs_get_user_bpammo(id, weapon_id)) < BUY_AMMO[weapon_id])
		{
			cost = AMMO_COST[WEAPON_AMMOID[weapon_id]]
		}
	}

	if (money >= maxcost)
	{
		ammo = MAX_BPAMMO[weapon_id] - cs_get_user_bpammo(id, weapon_id)
	}
	else if (money >= AMMO_COST[WEAPON_AMMOID[weapon_id]])
	{
		ammo = BUY_AMMO[weapon_id] * (money / AMMO_COST[WEAPON_AMMOID[weapon_id]])
	}

	if (money < AMMO_COST[WEAPON_AMMOID[weapon_id]])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_NOMONEY")
		return;
	}

	emit_sound(id, CHAN_ITEM, SOUND_PICK_AMMO, 1.0, ATTN_NORM, 0, PITCH_NORM)
	ExecuteHamB(Ham_GiveAmmo, id, ammo, AMMO_TYPE[weapon_id], MAX_BPAMMO[weapon_id])
	if ((money - cost) >= 0)
	{
		cs_set_user_money(id, money - cost)
	}
	else
	{
		cs_set_user_money(id, 0)
	}
}

secammo(id)
{
	new pri_weapons[18], pri_weapon_num, sec_weapons[6], sec_weapon_num
	get_user_has_weapons(id, pri_weapons, pri_weapon_num, sec_weapons, sec_weapon_num)
	if (sec_weapon_num <= 0)
		return;

	new weapon_id = sec_weapons[0]
	if (cs_get_user_bpammo(id, weapon_id) >= MAX_BPAMMO[weapon_id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_FULL")
		return;
	}

	new money, cost, maxcost, ammo
	money = cs_get_user_money(id)
	cost = AMMO_COST[WEAPON_AMMOID[weapon_id]]
	maxcost = AMMO_COST[WEAPON_AMMOID[weapon_id]] * ((MAX_BPAMMO[weapon_id] - cs_get_user_bpammo(id, weapon_id))/BUY_AMMO[weapon_id])
	if ((MAX_BPAMMO[weapon_id] - cs_get_user_bpammo(id, weapon_id)) >= BUY_AMMO[weapon_id])
	{
		cost = (AMMO_COST[WEAPON_AMMOID[weapon_id]])*(((MAX_BPAMMO[weapon_id] - cs_get_user_bpammo(id, weapon_id))/BUY_AMMO[weapon_id]))
	}
	else
	{
		if ((MAX_BPAMMO[weapon_id] - cs_get_user_bpammo(id, weapon_id)) < BUY_AMMO[weapon_id])
		{
			cost = AMMO_COST[WEAPON_AMMOID[weapon_id]]
		}
	}

	if (money >= maxcost)
	{
		ammo = MAX_BPAMMO[weapon_id] - cs_get_user_bpammo(id, weapon_id)
	}
	else if (money >= AMMO_COST[WEAPON_AMMOID[weapon_id]])
	{
		ammo = BUY_AMMO[weapon_id] * (money / AMMO_COST[WEAPON_AMMOID[weapon_id]])
	}

	if (money < AMMO_COST[WEAPON_AMMOID[weapon_id]])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZH_NOMONEY")
		return;
	}

	emit_sound(id, CHAN_ITEM, SOUND_PICK_AMMO, 1.0, ATTN_NORM, 0, PITCH_NORM)
	ExecuteHamB(Ham_GiveAmmo, id, ammo, AMMO_TYPE[weapon_id], MAX_BPAMMO[weapon_id])
	if ((money - cost) >= 0)
	{
		cs_set_user_money(id, money - cost)
	}
	else
	{
		cs_set_user_money(id, 0)
	}
}

///////////////////////////////////////////////////////////////////
// Check User Speed and Zombie Boss Leap                         //
///////////////////////////////////////////////////////////////////
// Current Weapon info
public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	// Player not alive or not an active weapon
	if (!is_user_alive(msg_entity) || get_msg_arg_int(1) != 1)
		return;

	// Get weapon id
	static weapon
	weapon = get_msg_arg_int(2)

	// Store weapon id for reference
	g_currentweapon[msg_entity] = weapon

	// Replace weapon models with custom ones
	replace_models(msg_entity)
}

// Set Custom Weapon Models
public replace_models(id)
{
	// Not alive
	if (!is_user_alive(id))
		return;

	switch (g_currentweapon[id])
	{
		case CSW_KNIFE: // Custom knife models
		{
			if (cs_get_user_team(id) == CS_TEAM_T)
			{
				if (g_zombie[id]) // Zombies
				{
					set_pev(id, pev_viewmodel2, model_vknife_zombie)
					set_pev(id, pev_weaponmodel2, "")
				}
				else // ZombieBoss
				{
					set_pev(id, pev_viewmodel2, model_vknife_boss)
					set_pev(id, pev_weaponmodel2, "")
				}
			}
			else
			{
				set_pev(id, pev_viewmodel2, "models/v_knife.mdl")
				set_pev(id, pev_weaponmodel2, "models/p_knife.mdl")
			}
		}
		case CSW_HEGRENADE: //Fire grenade
		{
			set_pev(id, pev_viewmodel2, model_grenade_fire)
		}
		case CSW_FLASHBANG: // Frost grenade
		{
			set_pev(id, pev_viewmodel2, model_grenade_frost)
		}
		case CSW_SMOKEGRENADE: // Flare grenade
		{
			set_pev(id, pev_viewmodel2, model_grenade_flare)
		}
	}
}

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	if (g_frozen[id])
	{
		set_pev(id, pev_velocity, Float:{ 0.0, 0.0, 0.0 }) // stop motion
		fm_set_user_maxspeed(id, 1.0) // prevent from moving
		freeze_user_attack(id)
		return FMRES_IGNORED;
	}
	else
	{
		fm_set_user_maxspeed(id, g_user_maxspeed[id]) // make user maxspeed be correct
	}

	// 檢查殭屍王是否可使用長跳
	if (!get_pcvar_num(cvar_boss_leap) || !g_boss[id] || g_freeze_time)
		return FMRES_IGNORED;

	static Float:current_time
	current_time = get_gametime()
	if (current_time - g_lastleaptime[id] < get_pcvar_float(cvar_leap_cooldown))
		return FMRES_IGNORED;

	if (!is_user_bot(id) && !(pev(id, pev_button) & (IN_JUMP | IN_DUCK) == (IN_JUMP | IN_DUCK)))
		return FMRES_IGNORED;

	if (!(pev(id, pev_flags) & FL_ONGROUND) || fm_get_speed(id) < 80)
		return FMRES_IGNORED;

	static Float:velocity[3]
	velocity_by_aim(id, get_pcvar_num(cvar_leap_force), velocity)
	velocity[2] = get_pcvar_float(cvar_leap_height)
	set_pev(id, pev_velocity, velocity)
	g_lastleaptime[id] = current_time
	return FMRES_IGNORED;
}

freeze_user_attack(id)
{
	new weapon, weapon_name[32], weapon_ent
	weapon = get_user_weapon(id)
	get_weaponname(weapon, weapon_name, charsmax(weapon_name))
	weapon_ent = fm_find_ent_by_owner(-1, weapon_name, id)
	if (get_weapon_next_pri_attack(weapon_ent) <= 0.1)
		set_weapon_next_pri_attack(weapon_ent, 0.5)

	if (get_weapon_next_sec_attack(weapon_ent) <= 0.1)
		set_weapon_next_sec_attack(weapon_ent, 0.5)

	if (weapon == CSW_XM1014 || weapon == CSW_M3)
	{
		if (get_weapon_idle_time(weapon_ent) <= 0.1)
			set_weapon_idle_time(weapon_ent, 0.5)
	}
}

///////////////////////////////////////////////////////////////////
// Messages Set or Block					 //
///////////////////////////////////////////////////////////////////
// Fix for the HL engine bug when HP is multiples of 256
public message_Health(msg_id, msg_dest, msg_entity)
{
	// Get player's health
	static health
	health = get_msg_arg_int(1)

	// Don't bother
	if (health < 256) return;

	// Check if we need to fix it
	if (health % 256 == 0)
		fm_set_user_health(msg_entity, pev(msg_entity, pev_health) + 1)

	// HUD can only show as much as 255 hp
	set_msg_arg_int(1, get_msg_argtype(1), 255)
}

///////////////////////////////////////////////////////////////////
// Hide User Money 						 //
///////////////////////////////////////////////////////////////////
// Task Hide Player's Money
public hide_user_money(id)
{
	// Not alive
	if (!is_user_alive(id))
		return;

	// Hide money
	message_begin(MSG_ONE, get_user_msgid("HideWeapon"), _, id)
	write_byte((1<<5)) // what to hide bitsum
	message_end()

	// Hide the HL crosshair that's drawn
	message_begin(MSG_ONE, g_msgCrosshair, _, id)
	write_byte(0) // toggle
	message_end()
}

// Take off player's money
public message_Money(msg_id, msg_dest, msg_entity)
{
	if (!is_user_connected(msg_entity))
		return PLUGIN_CONTINUE;

	// Block zombies money message
	if (cs_get_user_team(msg_entity) == CS_TEAM_T)
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

/////////////////////////////////////////
// Remove Map's Obiective & Round Time //
/////////////////////////////////////////
public forward_spawn(entity)
{
	if (!pev_valid(entity))
	{
		return FMRES_IGNORED;
	}

	static classname[32];
	pev(entity, pev_classname, classname, charsmax(classname));
	for (new i = 0; i < sizeof OBJECTIVE_ENTITYS; i++)
	{
		if (equal(classname, OBJECTIVE_ENTITYS[i]))
		{
			engfunc(EngFunc_RemoveEntity, entity);
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

// Block round time message
public message_RoundTime()
{
	return PLUGIN_HANDLED;
}

// Hide user round time message
public message_HideWeapon()
{
	set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | (1<<4))
	return PLUGIN_CONTINUE;
}

///////////////////////////////////////////////////////////////////
// Unlimited Ammo                                                //
///////////////////////////////////////////////////////////////////
// Check user back pack ammo
public event_check_bpammo(id)
{
	new ammo_id, ammo_amount, weapon, ammo_type_offset
	ammo_id = read_data(1)
	if (ammo_id >= sizeof AMMOID_WEAPON)
		return;

	ammo_amount = read_data(2)
	weapon = AMMOID_WEAPON[ammo_id]
	ammo_type_offset = 376 + ammo_id
	if (get_pcvar_num(cvar_survivor_ulammo) || ammo_amount > MAX_BPAMMO[weapon])
		set_pdata_int(id, ammo_type_offset, MAX_BPAMMO[weapon], OFFSET_LINUX)
}

// Pick Weapon Auto Full Ammo
public event_weap_pickup(id)
{
	if (get_pcvar_num(cvar_survivor_ulammo))
	{
		new weapon = read_data(1)
		if (MAX_BPAMMO[weapon] > 2)
			cs_set_user_bpammo(id, weapon, MAX_BPAMMO[weapon])
	}
}

///////////////////////////////////////////////////////////////////
// Night Vision                                                  //
///////////////////////////////////////////////////////////////////
// Nightvision toggle
public cmd_nightvision(id)
{
	if (!is_user_alive(id) || (is_user_alive(id) && cs_get_user_nvg(id)))
	{
		// Enable-disable
		g_nvg_enabled[id] = !g_nvg_enabled[id]
		if (g_nvg_enabled[id])
			emit_sound(id, CHAN_ITEM, SOUND_TURN_NVG_ON, 1.0, ATTN_NORM, 0, PITCH_NORM)
		else
			emit_sound(id, CHAN_ITEM, SOUND_TURN_NVG_OFF, 1.0, ATTN_NORM, 0, PITCH_NORM)

		// Custom nvg?
		if (get_pcvar_num(cvar_custom_nvg))
		{
			remove_task(id+TASK_NVG)
			if (g_nvg_enabled[id])
				set_task(0.1, "set_nvg_effect", id+TASK_NVG, _, _, "b")
		}
		else
		{
			toggle_user_nvg(id, g_nvg_enabled[id])
		}
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

// Set Nightvision Effect
public set_nvg_effect(taskid)
{
	new id = taskid-TASK_NVG

	// Get player's origin
	static origin[3]
	get_user_origin(id, origin)

	// Nightvision message
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(get_pcvar_num(cvar_nvg_size)) // radius

	// Set night vision color
	new nvg_color[32], red[4], green[4], blue[4]
	get_pcvar_string(cvar_nvg_color, nvg_color, charsmax(nvg_color))
	parse(nvg_color, red, charsmax(red), green, charsmax(green), blue, charsmax(blue))
	write_byte(str_to_num(red)) // r
	write_byte(str_to_num(green)) // g
	write_byte(str_to_num(blue)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

// Prevent spectators' nightvision from being turned off when switching targets, etc.
public message_NVGToggle(msg_id, msg_dest, msg_entity)
{
	return PLUGIN_HANDLED;
}

// Team Switch (or player joining a team for first time)
public message_TeamInfo(msg_id, msg_dest)
{
	// Only hook global messages
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return;

	// Get player's id
	static id
	id = get_msg_arg_int(1)

	// Enable spectators' nightvision if not spawning right away
	set_task(0.1, "spectator_nvg", id+TASK_SPEC_NVG)
}

// Set spectators nightvision
public spectator_nvg(taskid)
{
	new id = taskid-TASK_SPEC_NVG
	if (!is_user_connected(id) || is_user_alive(id) || is_user_bot(id))
		return;

	g_nvg_enabled[id] = true

	// Custom nvg?
	if (get_pcvar_num(cvar_custom_nvg))
	{
		remove_task(id+TASK_NVG)
		set_task(0.1, "set_nvg_effect", id+TASK_NVG, _, _, "b")
	}
	else
	{
		toggle_user_nvg(id, 1)
	}
}

// User Nightvision Toggle
toggle_user_nvg(id, toggle)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_msgNVGToggle, _, id)
	write_byte(toggle) // toggle
	message_end()
}

///////////////////////////////////////////////////////////////////
// Round End Text & Sounds                                       //
///////////////////////////////////////////////////////////////////
// Block round end event sound
public message_SendAudio()
{
	static Sound[32]
	get_msg_arg_string(2, Sound, charsmax(Sound))
	if (equal(Sound, "%!MRAD_terwin") || equal(Sound, "&%!MRAD_ctwin"))
	{
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

// Round end message text
public message_TextMsg()
{
	static message[32]
	get_msg_arg_string(2, message, charsmax(message))
	if (equal(message, "#Game_Commencing") || equal(message, "#Game_will_restart_in"))
	{
		g_game_restart = true
	}
	else if (equal(message, "#Hostages_Not_Rescued") || equal(message, "#Round_Draw") || equal(message, "#Terrorists_Win")
	|| equal(message, "#CTs_Win"))
	{
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

// Log Event Round End
public logevent_round_end()
{
	if (g_game_restart)
		return;

	g_roundend = true

	// Prevent this from getting called twice when restarting (bugfix)
	static Float:lastendtime, Float:current_time
	current_time = get_gametime()
	if (current_time - lastendtime < 0.5) return;
	lastendtime = current_time
	static ts[32], ts_num, cts[32], cts_num
	get_alive_players(ts, ts_num, cts, cts_num)
	if (ts_num > 0) //回合結束時,只有殭屍的陣營有生還者.
	{
		set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ZWIN")
		StopSound(0)
		remove_task(TASK_AMBIENCE_SOUND)
		remove_task(TASK_BOSS_AMBIENCE_SOUND)
		PlaySound(0, SOUND_ZOMBIE_WIN)
		set_level(0)
	}
	else if (cts_num > 0) //回合結束時,只有人類的陣營有生還者.
	{
		set_hudmessage(0, 0, 255, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_HWIN")
		StopSound(0)
		remove_task(TASK_AMBIENCE_SOUND)
		remove_task(TASK_BOSS_AMBIENCE_SOUND)
		PlaySound(0, SOUND_SURVIVOR_WIN)
		set_level(1)
	}
	else //回合結束時雙方不分勝負.
	{
		if ((ts_num > 0) && (cts_num > 0))
		{
			set_hudmessage(150, 255, 150, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0, -1)
			ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_DRAW")
			StopSound(0)
			remove_task(TASK_AMBIENCE_SOUND)
			remove_task(TASK_BOSS_AMBIENCE_SOUND)
			PlaySound(0, SOUND_DRAW)
			set_level(0)
		}
		else
		{
			if ((ts_num <= 0) && (cts_num <= 0))
			{
				set_hudmessage(100, 255, 100, -1.0, 0.17, 0, 3.0, 5.0, 0.0, 0.0, -1)
				ShowSyncHudMsg(0, g_hudSync2, "%L", LANG_PLAYER, "ZH_ALLDEAD")
				StopSound(0)
				remove_task(TASK_AMBIENCE_SOUND)
				remove_task(TASK_BOSS_AMBIENCE_SOUND)
				PlaySound(0, SOUND_DRAW)
				set_level(0)
			}
		}
	}
}

get_alive_players(ts[32], &ts_num, cts[32], &cts_num)
{
	new i, CsTeams:team
	ts_num = 0
	cts_num = 0
	for (i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_connected(i) || !is_user_alive(i))
			continue;

		team = cs_get_user_team(i)
		if (team == CS_TEAM_T)
		{
			ts[ts_num] = i
			ts_num++
		}
		else if (team == CS_TEAM_CT)
		{
			cts[cts_num] = i
			cts_num++
		}
	}
}

static nextmap
set_level(level_up) // level_up:[1=level up/0=level back]
{
	if (level_up)
	{
		if (g_level >= 10)
		{
			for (new id = 1; id <= 32; id++)
			{
				fm_set_user_godmode(id, 1)
			}
			new Float:time = get_pcvar_float(cvar_map_time)
			nextmap = random_num(1, sizeof Random_Map - 1)
			set_hudmessage(0, 250, 255, -1.0, 0.35, 0, 0.0, 5.0, 0.0, 0.0, -1)
			ShowSyncHudMsg(0, g_hudSync3, "%L", LANG_PLAYER, "ZH_NEXTMAP", Random_Map[nextmap])
			set_task(time, "change_to_next_map")
		}
		else
		{
			set_pcvar_num(cvar_level, g_level + 1)
		}
	}
	else
	{
		set_pcvar_num(cvar_level, max(g_level - 1, 1))
	}
}

public change_to_next_map()
{
	if (g_level >= 10)
	{

		server_cmd("yb_quota 0")

		server_cmd("changelevel %s", Random_Map[nextmap])
		set_task(0.1, "change_to_next_map")
	}
}

///////////////////////////////////////////////////////////////////
// Stocks		                                         //
///////////////////////////////////////////////////////////////////
stock TSpawns_Count()
{
	new entity
	g_SpawnT = 0
	while ((entity = find_ent_by_class(entity, "info_player_deathmatch")))
		g_SpawnT++
}

stock fm_reset_user_model(player)
{
	g_has_custom_model[player] = false
	dllfunc(DLLFunc_ClientUserInfoChanged, player, engfunc(EngFunc_GetInfoKeyBuffer, player))
}

stock fm_get_user_model(player, model[], len)
{
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", model, len)
}

stock get_user_has_weapons(id, pri_weapons[18], &pri_weapon_num, sec_weapons[6], &sec_weapon_num)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	pri_weapon_num = 0
	sec_weapon_num = 0
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		if ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)
		{
			pri_weapons[pri_weapon_num] = weaponid
			pri_weapon_num++
		}
		else if ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)
		{
			sec_weapons[sec_weapon_num] = weaponid
			sec_weapon_num++
		}
	}
}

stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon name
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock fm_strip_user_weapons(id)
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
	if (!pev_valid(ent))
		return;

	dllfunc(DLLFunc_Spawn, ent)
	dllfunc(DLLFunc_Use, ent, id)
	engfunc(EngFunc_RemoveEntity, ent)
}

stock fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent)
	return -1;
}

stock fm_get_user_godmode(index)
{
	new Float:val;
	pev(index, pev_takedamage, val);
	return (val == DAMAGE_NO);
}

stock fm_set_user_godmode(index, godmode = 0)
{
	set_pev(index, pev_takedamage, godmode == 1 ? DAMAGE_NO : DAMAGE_AIM);
	return 1;
}

stock fm_set_user_maxspeed(index, Float:speed = -1.0)
{
	engfunc(EngFunc_SetClientMaxspeed, index, speed);
	set_pev(index, pev_maxspeed, speed);
	return 1;
}

stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	return 1;
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock StopSound(id)
{
	client_cmd(id, "mp3 stop; stopsound")
}

stock fm_set_kvd(entity, const key[], const value[], const classname[] = "")
{
	if (classname[0])
	{
		set_kvd(0, KV_ClassName, classname);
	}
	else
	{
		new class[32];
		pev(entity, pev_classname, class, sizeof class - 1);
		set_kvd(0, KV_ClassName, class);
	}
	set_kvd(0, KV_KeyName, key);
	set_kvd(0, KV_Value, value);
	set_kvd(0, KV_fHandled, 0);
	return dllfunc(DLLFunc_KeyValue, entity, 0);
}

stock fm_get_speed(entity)
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	return floatround(vector_length(velocity));
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

stock fm_user_kill(index, flag = 0)
{
	if (flag)
	{
		new Float:frags;
		pev(index, pev_frags, frags);
		set_pev(index, pev_frags, ++frags);
	}
	dllfunc(DLLFunc_ClientKill, index);
	return 1;
}

stock fm_call_think(entity)
{
	return dllfunc(DLLFunc_Think, entity)
}

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && (pev(entity, pev_owner) != owner)) {}
	return entity;
}

stock Float:get_weapon_next_pri_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextPrimaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_pri_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextPrimaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_next_sec_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextSecondaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_sec_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextSecondaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_idle_time(entity)
{
	return get_pdata_float(entity, OFFSET_flTimeWeaponIdle, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_idle_time(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flTimeWeaponIdle, time, OFFSET_LINUX_WEAPONS)
}

stock get_string_index(const string_array[][], string_num, const dest_string[])
{
	new i
	for (i = 0; i < string_num; i++)
	{
		if (equal(string_array[i], dest_string))
			return i;
	}
	return -1;
}
