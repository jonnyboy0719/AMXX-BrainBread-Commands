//------------------
//	Include Files
//------------------

#include <amxmodx>
#include <amxmisc>
#include <brainbread>
#include <fakemeta>
#include <hamsandwich>
#include <fun>

//------------------
//	Defines
//------------------

#define PLUGIN	"BrainBread Commands"
#define AUTHOR	"Reperio Studios"
#define VERSION	"1.0"
#define NbWeapon 21

//------------------
//	Handles & more
//------------------

new TabWeapon[NbWeapon][]={
	"44sw",
	"benlli",
//	"canister",
	"hand",
	"microuzi",
	"microuzi_a",
//	"knife",
	"minigun",
	"p225",
//	"pdw",
	"sawed",
	"winchester",
	"usp",
	"beretta",
	"beretta_a",
	"glock",
	"glock_auto",
	"glock_auto_a",
	"stoner",
	"mp5",
	"flame",
	"m16",
	"deagle",
//	"case",
	"ak47"
}

//------------------
//	plugin_init()
//------------------

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar("bbcmds_version", VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	
	set_cvar_string("bbcmds_version", VERSION)

	// Commands
	register_concmd("bb_give_weapon", "BBcmd_GiveWeapon", ADMIN_SLAY, "<name or #userid> [item]")
	register_concmd("bb_give_ammo", "BBcmd_GiveAmmo", ADMIN_SLAY, "<name or #userid> [item] [primary] [secondary]")
	register_concmd("bb_set_skill", "BBcmd_SetSkill", ADMIN_SLAY, "<name or #userid> [skill] [amount]")
	register_concmd("bb_set_level", "BBcmd_SetLevel", ADMIN_SLAY, "<name or #userid> [level]")
}

//------------------
//	BBcmd_SetLevel()
//------------------

public BBcmd_SetLevel(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[32]

	read_argv(1, arg, 31)
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)

	if (!player)
		return PLUGIN_HANDLED

	new level[32], authid[32], name2[32], authid2[32], name[32]

	read_argv(2, level, 31)

	new bb_lvl = str_to_num(level)

	if (bb_lvl < -1) {
		client_print(id,print_console,"[BB] You need to specify an amount!")
		return PLUGIN_HANDLED
	}

	bb_set_user_level(player, bb_lvl);

	get_user_authid(id, authid, 31)
	get_user_name(id, name, 31)
	get_user_authid(player, authid2, 31)
	get_user_name(player, name2, 31)

	log_amx("BB CMD: ^"%s<%d><%s><>^" have set ^"%s<%d><%s><>^" level to %d", name, get_user_userid(id), authid, name2, get_user_userid(player), authid2, bb_lvl)

	return PLUGIN_HANDLED
}

//------------------
//	BBcmd_SetSkill()
//------------------

public BBcmd_SetSkill(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[32]

	read_argv(1, arg, 31)
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)

	if (!player)
		return PLUGIN_HANDLED

	new bb_set_skill_name[32], authid[32], name2[32], authid2[32], name[32], bb_amount[32]

	read_argv(2, bb_set_skill_name, 31)
	read_argv(3, bb_amount, 31)

	new bb_set_skill = str_to_num(bb_amount)

	if (bb_set_skill < -1) {
		client_print(id,print_console,"[BB] You need to specify an amount!")
		return PLUGIN_HANDLED
	}

	new Skills_health[]="hps health";
	new Skills_speed[]="speed movement";
	new Skills_skill[]="damage skill";

	if (containi(Skills_health,bb_set_skill_name) != -1) {
		bb_set_user_hps(player, bb_set_skill);
	}
	else if (containi(Skills_speed,bb_set_skill_name) != -1) {
		bb_set_user_speed(player, bb_set_skill);
	}
	else if (containi(Skills_skill,bb_set_skill_name) != -1) {
		bb_set_user_skill(player, bb_set_skill);
	}
	else
	{
		client_print(id,print_console,"[BB] %s is not valid! The valid skills are the following:", bb_set_skill_name)
		client_print(id,print_console,"[BB] health, speed & skill")
		return PLUGIN_HANDLED
	}

	get_user_authid(id, authid, 31)
	get_user_name(id, name, 31)
	get_user_authid(player, authid2, 31)
	get_user_name(player, name2, 31)

	log_amx("BB CMD: ^"%s<%d><%s><>^" have set ^"%s<%d><%s><>^" skill %s to %d", name, get_user_userid(id), authid, name2, get_user_userid(player), authid2, bb_set_skill_name, bb_set_skill)

	return PLUGIN_HANDLED
}

//------------------
//	BBcmd_GiveWeapon()
//------------------

public BBcmd_GiveWeapon(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[32]

	read_argv(1, arg, 31)
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE)

	if (!player)
		return PLUGIN_HANDLED

	new weapon[32], authid[32], name2[32], authid2[32], name[32]

	read_argv(2, weapon, 31)

	give_weapon(id, player, weapon)

	get_user_authid(id, authid, 31)
	get_user_name(id, name, 31)
	get_user_authid(player, authid2, 31)
	get_user_name(player, name2, 31)

	log_amx("BB CMD: ^"%s<%d><%s><>^" gave %s to ^"%s<%d><%s><>^"", name, get_user_userid(id), authid, weapon, name2, get_user_userid(player), authid2)

	return PLUGIN_HANDLED
}

//------------------
//	BBcmd_GiveAmmo()
//------------------

public BBcmd_GiveAmmo(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[32]

	read_argv(1, arg, 31)
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE)

	if (!player)
		return PLUGIN_HANDLED

	new weapon[32], authid[32], name2[32], authid2[32], name[32], ammo[32], ammo2[32]

	read_argv(2, weapon, 31)
	read_argv(3, ammo, 31)
	read_argv(4, ammo2, 31)

	new ammo_int = str_to_num(ammo)
	new ammo2_int = str_to_num(ammo2)

	give_ammo_to_player(player, weapon, ammo_int, ammo2_int)

	get_user_authid(id, authid, 31)
	get_user_name(id, name, 31)
	get_user_authid(player, authid2, 31)
	get_user_name(player, name2, 31)

	log_amx("BB CMD: ^"%s<%d><%s><>^" set ^"%s<%d><%s><>^" weapon ^"%s^" primary ammo to %d and secondary ammo to %d", name, get_user_userid(id), authid, name2, get_user_userid(player), authid2, weapon, ammo_int, ammo2_int)

	return PLUGIN_HANDLED
}

//------------------
//	give_weapon()
//------------------

public give_weapon(id,player,weapon_give[]){
	new index_weapon = 0
	index_weapon = find_weapon(weapon_give)

	if (index_weapon<0) {
		client_print(id,print_console,"[BB] Cannot find the weapon Index!")
		return PLUGIN_CONTINUE
	}

	if (player) {
		free_weapon(player,index_weapon)
		set_hudmessage(255,100,0, 0.05,0.65, 0, 6.0, 6.0, 0.5, 0.15, 4)
		show_hudmessage(0,"[BB] You got %s!", weapon_give)
		return PLUGIN_CONTINUE
	}
	else
	{
		client_print(id,print_console,"[BB] Player not found!")
		return PLUGIN_CONTINUE
	}

	return PLUGIN_CONTINUE
}

//------------------
//	find_weapon()
//------------------

public find_weapon(txtweapon[]) {
	new weapon_index
	weapon_index = -1
	for(new i = 0 ;i < NbWeapon ;++i) {
		if (containi(TabWeapon[i],txtweapon)>-1) {
			weapon_index = i
			i =  NbWeapon
		}
	}
	return weapon_index
}

//------------------
//	free_weapon()
//------------------

public free_weapon(id,weapon_index) {
	new txtweapon[32]
	if (containi(TabWeapon[weapon_index],"item")<0) {
		format(txtweapon,32,"weapon_%s",TabWeapon[weapon_index],25)
	}
	else {
		format(txtweapon,32,"%s",TabWeapon[weapon_index],25)
	}

	if (containi(TabWeapon[weapon_index],"flame")>-1) {
		engclient_cmd(id,"drop") 
	}
	bb_give_item_ex(id,txtweapon)
	return PLUGIN_CONTINUE
}

//------------------
//	give_ammo_to_player()
//------------------

public give_ammo_to_player(id, weapon[], ammo_pri, ammo_sec) {
	new weapon_index = 0
	weapon_index = find_weapon(weapon);

	if (weapon_index<0) {
		client_print(id,print_console,"[BB] Cannot find the weapon Index!")
		return PLUGIN_CONTINUE
	}

	new txtweapon[32]
	if (containi(TabWeapon[weapon_index],"item")<0) {
		format(txtweapon,32,"weapon_%s",TabWeapon[weapon_index],25)
	}
	else {
		format(txtweapon,32,"%s",TabWeapon[weapon_index],25)
	}

	bb_setammo_primary(id, txtweapon, ammo_pri)
	bb_setammo_secondary(id, txtweapon, ammo_sec)
//	bb_debugvalues(id, txtweapon)
	return PLUGIN_CONTINUE
}

//------------------
//	give_item_ex_task()
//------------------

public give_item_ex_task(weapon) {
	dllfunc(DLLFunc_Touch,weapon,entity_get_edict(weapon,EV_ENT_euser4));
}
