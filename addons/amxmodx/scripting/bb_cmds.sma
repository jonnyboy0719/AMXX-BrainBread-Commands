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
#define VERSION	"1.3"
#define NbWeapon 19
#define SteamIDs 12

//------------------
//	Handles & more
//------------------

new bool:HasRadarDot[33]
new lastDeadflag[33]
new GetPlayerDot[33]

// Used to show the moderators and/or important people on the radar.
new Developers[SteamIDs][]={
	// BB2 Devs
	// Give us some love, will ya? :)
	"STEAM_0:1:43775360",
	"STEAM_0:0:7019991",
	"STEAM_0:0:13717184",
	"STEAM_0:1:23317724",
	"STEAM_0:1:9029043",
	"STEAM_0:0:17339670",
	"STEAM_0:1:12798748",
	"STEAM_0:0:2218475",
	"STEAM_0:1:2248646",
	"STEAM_0:0:16318420",
	"STEAM_0:1:24323838",
//	"EDIT_ME",
	"STEAM_0:0:40025702"
}

// The commented out weapons is basically non-working, bugged weapons. Some might even be removed and/or never been added into v1.2 of BrainBread.
new TabWeapon[NbWeapon][]={
	"44sw",
	"benelli",
//	"canister",
//	"hand",
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
//	"glock_auto",
	"glock_auto_a",
	"stoner",
	"mp5",
	"flame",
	"m16",
	"deagle",
//	"case",
	"ak47"
}

// Names
new TabWeapon_name[NbWeapon][]={
	".44 Magnum",
	"Benelli",
//	"Canister",
//	"Zombie Hands",
	"Micro Uzi",
	"Micro Uzi (Akimbo)",
//	"Axe",
	"Minigun",
	"P225",
//	"UNKNOWN",
	"Sawed Off",
	"Winchester",
	"USP",
	"Beretta",
	"Beretta (Akimbo)",
	"Glock17",
//	"Glock18 Auto",
	"Glock18 Auto (Akimbo)",
	"Stoner",
	"MP5",
	"Flamethrower",
	"M16",
	"Desert Eagle",
//	"Breifcase",
	"AK-47"
}

//------------------
//	plugin_init()
//------------------

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar("bbcmds_version", VERSION, FCVAR_SPONLY|FCVAR_SERVER)

	set_cvar_string("bbcmds_version", VERSION)

	// Register
	register_forward(FM_PlayerPreThink,"OnPlayerPreThink")

	// Set Tasks
	set_task(0.5,"PluginThinkLoop",0,"",0,"b")

	// Commands (Kick Privlages)
	register_concmd("bb_give_weapon", "BBcmd_GiveWeapon", ADMIN_KICK, "<name or #userid> [item]")
	register_concmd("bb_give_ammo", "BBcmd_GiveAmmo", ADMIN_KICK, "<name or #userid> [item] [primary] [secondary]")

	// Commands (Ban Privlages)
	register_concmd("bb_set_skill", "BBcmd_SetSkill", ADMIN_BAN, "<name or #userid> [skill] [amount]")
	register_concmd("bb_set_level", "BBcmd_SetLevel", ADMIN_BAN, "<name or #userid> [level]")
	register_concmd("bb_set_points", "BBcmd_SetPoints", ADMIN_BAN, "<name or #userid> [amount]")

	// Commands (Admin values)
	register_concmd("bb_admin_reset", "BBcmd_Admin_Reset", ADMIN_BAN, "<name or #userid>")
	register_concmd("bb_admin_fullreset", "BBcmd_Admin_FullReset", ADMIN_BAN, "<name or #userid>")
	register_concmd("bb_admin_announce", "BBcmd_Admin_Announce", ADMIN_BAN, "[duration] [string] [string]")

	// Commands (RCON Privlages)
	register_concmd("bb_radar_add", "BBcmd_Rcon_RadarList", ADMIN_RCON, "<name or #userid>")

	// Convars
	register_cvar ("bb_allow_adminresets", "1"); // If its set to 2, admins can reset any player (if their immunie is not the same/higher than theirs), if its its set to 1, admins can't make a full reset (level and all skills goes back to 0), and if its set to 0, resets are disabled.
	register_cvar ("bb_show_staff", "1"); // If its set to 1, it will show all admins as orange and all mods as light blue, if its set to 0, its disabled (NOTE: it doesn't show if you are a zombie!)
}

//------------------
//	BBcmd_Rcon_RadarList()
//------------------

public BBcmd_Rcon_RadarList(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[32]

	read_argv(1, arg, 31)
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)

	if (!player)
		return PLUGIN_HANDLED

	new authid[32], name2[32], authid2[32], name[32]

	get_user_authid(id, authid, 31)
	get_user_name(id, name, 31)
	get_user_authid(player, authid2, 31)
	get_user_name(player, name2, 31)

	AddToRadarList(id, authid2)

	log_amx("BB CMD: ^"%s<%d><%s><>^" added ^"%s<%d><%s><>^" to the radar list", name, get_user_userid(id), authid, name2, get_user_userid(player), authid2)

	return PLUGIN_HANDLED
}

//------------------
//	AddToRadarList()
//------------------

AddToRadarList(id, auth[])
{
	// Make sure that the bb_radarlist.ini file exists.
	new configsDir[64]
	get_configsdir(configsDir, 63)
	format(configsDir, 63, "%s/bb_radarlist.ini", configsDir)

	if (!file_exists(configsDir))
	{
		console_print(id, "[BB] File ^"%s^" doesn't exist.", configsDir)
		return
	}

	// Make sure steamid isn't already in file.
	new line = 0, textline[256], len
	const SIZE = 63
	new line_steamid[SIZE + 1], parsedParams
	
	// <steamid>
	while ((line = read_file(configsDir, line, textline, 255, len)))
	{
		if (len == 0 || equal(textline, ";", 1))
			continue // comment line

		parsedParams = parse(textline, line_steamid, SIZE)

		if (parsedParams != 4)
			continue	// Send warning/error?

		if (equal(line_steamid, auth))
		{
			console_print(id, "[BB] %s already exists!", auth)
			return
		}
	}

	// If we came here, steamid doesn't exist in bb_radarlist.ini. Add it.
	new linetoadd[512]

	formatex(linetoadd, 511, "^r^n^"%s^"", auth)

	console_print(id, "Adding:^n%s", linetoadd)

	if (!write_file(configsDir, linetoadd))
		console_print(id, "[BB] Failed writing to %s!", configsDir)

}

//------------------
//	GrabSteamID_INI()
//------------------

GrabSteamID_INI(szFilename[], get_auth[])
{
	new File=fopen(szFilename,"r");

	if (File)
	{
		new Text[512];
		new AuthData[44];
		new DotType[32];
		
		while (!feof(File))
		{
			fgets(File,Text,sizeof(Text)-1);

			trim(Text);

			// comment
			if (Text[0]==';') 
			{
				continue;
			}

			AuthData[0]=0;
			DotType[0]=0;

			// not enough parameters
			if (parse(Text,AuthData,sizeof(AuthData)-1,DotType,sizeof(DotType)-1) < 2)
			{
				continue;
			}

			if (containi(get_auth,AuthData)>-1)
				return true;
		}

		fclose(File);
	}

	return false;
}

//------------------
//	PluginThinkLoop()
//------------------

public PluginThinkLoop()
{
	new iPlayers[32],iNum
	get_players(iPlayers,iNum)
	for(new i=0;i<iNum;i++)
	{
		new id=iPlayers[i]
		if(is_user_connected(id))
		{
			if(bb_get_user_human(id))
			{
				new origin[3]
				get_user_origin(id, origin, 0);

				if(!is_user_alive(id))
					Delete_Staff(id)

				if (HasRadarDot[id])
					Show_Staff(id)
			}
		}
	}
}

//------------------
//	OnPlayerPreThink()
//------------------

public OnPlayerPreThink(id)
{
	new deadflag=pev(id,pev_deadflag)
	if(!deadflag&&lastDeadflag[id])
	{
		OnPlayerSpawn(id)
	}
	lastDeadflag[id]=deadflag
}

//------------------
//	OnPlayerSpawn()
//------------------

public OnPlayerSpawn(id)
{
	Show_Staff(id);
}

//------------------
//	client_connect()
//------------------

public client_connect(id)
{
	HasRadarDot[id] = false;
	GetPlayerDot[id] = DOT_FLGREEN;
}

//------------------
//	client_disconnect()
//------------------

public client_disconnect(id)
{
	Delete_Staff(id);
}

//------------------
//	FindSteamID()
//------------------

public FindSteamID(auth[]) {
	new found_steamid
	found_steamid = false
	for(new i = 0 ;i < SteamIDs ;++i) {
		if (containi(Developers[i],auth)>-1) {
			found_steamid = true
			i = SteamIDs
		}
	}
	return found_steamid
}

//------------------
//	FindSteamID_INI()
//------------------

public FindSteamID_INI(auth[]) {
	new configsDir[64], found_steamid
	get_configsdir(configsDir, 63)

	format(configsDir, 63, "%s/bb_radarlist.ini", configsDir)
	found_steamid = GrabSteamID_INI(configsDir, auth) // Lets get its SteamID

	return found_steamid
}

//------------------
//	Show_Staff()
//------------------

public Show_Staff(id)
{
	new bb_get_show_staff = get_cvar_num ( "bb_show_staff" )
	if (bb_get_show_staff <= 0)
		return PLUGIN_HANDLED

	// if the player is a zombie, delete the radar dot
	if (bb_get_user_zombie(id))
		Delete_Staff(id);

	new origin[3]
	get_user_origin(id, origin, 0);

	new authid[32]
	get_user_authid(id, authid, 31)

	new players[32],num,i;
	get_players(players, num)
	for (i=0; i<num; i++)
	{
		if (is_user_connected(players[i]) && !is_user_bot(players[i]))
		{
			if (is_user_admin(id))
			{
				if(GetPlayerDot[id] == DOT_FLGREEN)
					GetPlayerDot[id] = DOT_ORANGE;

				bb_radar(players[i],id,origin,1,GetPlayerDot[id]);
				HasRadarDot[id] = true;
			}
			else if(FindSteamID(authid))
			{
				if(GetPlayerDot[id] == DOT_FLGREEN)
					GetPlayerDot[id] = DOT_LTBLUE;

				bb_radar(players[i],id,origin,1,GetPlayerDot[id]);
				HasRadarDot[id] = true;
			}
			else if(FindSteamID_INI(authid))
			{
				if(GetPlayerDot[id] == DOT_FLGREEN)
					GetPlayerDot[id] = DOT_WHITE;

				bb_radar(players[i],id,origin,1,GetPlayerDot[id]);
				HasRadarDot[id] = true;
			}
		}
	}
	return PLUGIN_HANDLED
}

//------------------
//	Delete_Staff()
//------------------

public Delete_Staff(id)
{
	new bb_get_show_staff = get_cvar_num ( "bb_show_staff" )
	if (bb_get_show_staff <= 0)
		return PLUGIN_HANDLED

	if (!HasRadarDot[id])
		return PLUGIN_HANDLED

	new origin[3]
	get_user_origin(id, origin, 0);

	new players[32],num,i;
	get_players(players, num)
	for (i=0; i<num; i++)
	{
		if (is_user_connected(players[i]) && !is_user_bot(players[i]))
		{
			bb_radar(players[i],id,origin,0,DOT_GREEN);
		}
	}
	return PLUGIN_HANDLED
}

//------------------
//	BBcmd_Admin_Announce()
//------------------

public BBcmd_Admin_Announce(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[32], arg2[32], arg3[32]

	read_argv(1, arg, 31)
	read_argv(2, arg2, 31)
	read_argv(3, arg3, 31)

	new duration = str_to_num(arg)

	if (duration < -1) {
		client_print(id,print_console,"[BB] You need to specify an amount of duration (in seconds)!")
		return PLUGIN_HANDLED
	}

	new players[32],num,i;
	get_players(players, num)
	for (i=0; i<num; i++)
	{
		if (is_user_connected(players[i]) && !is_user_bot(players[i]))
		{
			bb_show_message(players[i],duration,arg2,arg3);
		}
	}

	return PLUGIN_HANDLED
}

//------------------
//	BBcmd_Admin_FullReset()
//------------------

public BBcmd_Admin_FullReset(id, level, cid)
{
	new bb_get_adminresets = get_cvar_num ( "bb_allow_adminresets" )
	if (bb_get_adminresets <= 1)
		return PLUGIN_HANDLED

	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[32]

	read_argv(1, arg, 31)
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)

	if (!player)
		return PLUGIN_HANDLED

	new authid[32], name2[32], authid2[32], name[32]

	FullReset(player);

	get_user_authid(id, authid, 31)
	get_user_name(id, name, 31)
	get_user_authid(player, authid2, 31)
	get_user_name(player, name2, 31)

	log_amx("BB CMD: ^"%s<%d><%s><>^" have made a full reset on ^"%s<%d><%s><>^"", name, get_user_userid(id), authid, name2, get_user_userid(player), authid2)

	return PLUGIN_HANDLED
}

//------------------
//	BBcmd_Admin_Reset()
//------------------

public BBcmd_Admin_Reset(id, level, cid)
{
	new bb_get_adminresets = get_cvar_num ( "bb_allow_adminresets" )
	if (bb_get_adminresets <= 0)
		return PLUGIN_HANDLED

	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[32]

	read_argv(1, arg, 31)
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)

	if (!player)
		return PLUGIN_HANDLED

	new authid[32], name2[32], authid2[32], name[32]

	ResetSkills(player);

	get_user_authid(id, authid, 31)
	get_user_name(id, name, 31)
	get_user_authid(player, authid2, 31)
	get_user_name(player, name2, 31)

	log_amx("BB CMD: ^"%s<%d><%s><>^" have made a reset on ^"%s<%d><%s><>^"", name, get_user_userid(id), authid, name2, get_user_userid(player), authid2)

	return PLUGIN_HANDLED
}

//------------------
//	BBcmd_SetPoints()
//------------------

public BBcmd_SetPoints(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg[32]

	read_argv(1, arg, 31)
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)

	if (!player)
		return PLUGIN_HANDLED

	new points[32], authid[32], name2[32], authid2[32], name[32]

	read_argv(2, points, 31)

	new bb_points = str_to_num(points)

	if (bb_points < -1) {
		client_print(id,print_console,"[BB] You need to specify an amount!")
		return PLUGIN_HANDLED
	}

	bb_set_user_points(player,bb_points);

	get_user_authid(id, authid, 31)
	get_user_name(id, name, 31)
	get_user_authid(player, authid2, 31)
	get_user_name(player, name2, 31)

	log_amx("BB CMD: ^"%s<%d><%s><>^" have set ^"%s<%d><%s><>^" points to %d", name, get_user_userid(id), authid, name2, get_user_userid(player), authid2, bb_points)

	return PLUGIN_HANDLED
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

	new lvl[32], authid[32], name2[32], authid2[32], name[32]

	read_argv(2, lvl, 31)

	new bb_lvl = str_to_num(lvl)

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
	index_weapon = get_weapon(weapon_give);

	if (index_weapon<0) {
		client_print(id,print_console,"[BB] Cannot find the weapon Index!")
		return PLUGIN_CONTINUE
	}

	// If its a zombie, lets give an error (because zombies can't carry guns)
	if (bb_get_user_zombie(player))
		return PLUGIN_CONTINUE

	if (player) {
		free_weapon(player,index_weapon)
		client_print(player,print_chat,"[BB] You got the weapon %s!", TabWeapon_name[index_weapon])
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
//	get_weapon()
//------------------

public get_weapon(txtweapon[]) {
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
	weapon_index = get_weapon(weapon);

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

//------------------
//	ResetSkills()
//------------------

public ResetSkills(id)
{
	// Lets get the player's skills and points
	new hps, skill, speed, points;
	hps = bb_get_user_hps(id);
	skill = bb_get_user_skill(id);
	speed = bb_get_user_speed(id);
	points = bb_get_user_points(id);

	// Now, lets convert them into points!
	new GetPoints = points+(hps+speed+skill)
	bb_set_user_points(id, GetPoints);

	// Lets print to the client's chat, so we know we made this action
	client_print ( id, print_chat, "An admin have reset your skills, and turned them into %d point(s).", GetPoints ) 

	// Now the last bit, lets reset the skills
	bb_set_user_hps(id, 0);
	bb_set_user_skill(id, 0);
	bb_set_user_speed(id, 0);

	return PLUGIN_HANDLED
}

//------------------
//	FullReset()
//------------------

public FullReset(id)
{
	// Lets print the old stats
	new hps, skill, level, speed, points;
	hps = bb_get_user_hps(id);
	skill = bb_get_user_skill(id);
	level = bb_get_user_level(id);
	speed = bb_get_user_speed(id);
	points = bb_get_user_points(id);
	new Float:exp = bb_get_user_exp(id)

	new steamid[32], name[32]

	get_user_authid(id, steamid, 31)
	get_user_name(id, name, 31)

	// Lets display it for the client
	client_print ( id, print_console, "==----------[[ ORIGINAL STATS ]]--------------==" )
	client_print ( id, print_console, "NAME: %s", name )
	client_print ( id, print_console, "STEAMID: %s", steamid )
	client_print ( id, print_console, "==-------" )
	client_print ( id, print_console, "LEVEL: %d", level )
	client_print ( id, print_console, "EXP: %i", floatround(exp) )
	client_print ( id, print_console, "HPS: %d", hps )
	client_print ( id, print_console, "SKILL: %d", skill )
	client_print ( id, print_console, "SPEED: %d", speed )
	client_print ( id, print_console, "POINTS: %d", points )
	client_print ( id, print_console, "==----------[[ ORIGINAL STATS ]]--------------==" )

	// Now lets make sure we log this event, it will obtain all useful information if we want to reset it back.
	log_amx("==----------[[ ORIGINAL STATS ]]--------------==" )
	log_amx("NAME: %s", name )
	log_amx("STEAMID: %s", steamid )
	log_amx("==-------" )
	log_amx("LEVEL: %d", level )
	log_amx("EXP: %i", floatround(exp) )
	log_amx("HPS: %d", hps )
	log_amx("SKILL: %d", skill )
	log_amx("SPEED: %d", speed )
	log_amx("POINTS: %d", points )
	log_amx("==----------[[ ORIGINAL STATS ]]--------------==" )

	// Now lets reset everything!
	bb_set_user_points(id, 0);
	bb_set_user_hps(id, 0);
	bb_set_user_skill(id, 0);
	bb_set_user_speed(id, 0);
	bb_set_user_level(id, 0);
	bb_set_user_exp(id, 0.0);

	// Lets print to the client's chat, so we know we made this action
	client_print ( id, print_chat, "An admin have reset your values due to cheating and/or exploiting." ) 

	return PLUGIN_HANDLED
}