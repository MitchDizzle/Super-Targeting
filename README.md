Super Targeting
=========

Super Targeting adds in a config for server operators to make their own filter for the ProcessTargetString which is used in many of the SM commands.

Future Work
-----------

I plan on adding a few more things to this plugin, which insnese will break the older one.

A few that come to mind are:
 - Alive
 - Conditions



Installation & Setup
===========

```sourcepawn
SuperTargeting.smx -> Sourcemod/plugins/
SuperTargeting.cfg -> Sourcemod/configs/
```

Configuration
------------


The format is so:
```text
"@<filtername>"
{
	 "text"		"<language text>"
	 "team"		"<team>"
	 "class"	"<class>" //TF2/DODS/L4D/L4D2 ONLY
	 "alive"	"<-1/0/1>"
	 "bots"		"<-1/0/1>"
	 "cond"		"<-1/#>" //TF2 ONLY
}
```

Here is what can be put into each one:
```text
<filtername> : this can be anything, but i would refrain from making it anything that is already in use. Start it off with an exclamation point (!) to negate the filter
<text>	: This is the text that is printed out when a plugin uses this filter. This is only for these games: TF2, DOD:S, L4D.
<team>  : This can be 0 to 3, anything else it will ignore the filter. Set to 0 to ignore the team number.
<class> : This is a number from 0 to 9, anything other than that the filter will be ignored.
<alive>	: This will only check players that are alive, or dead. Set to -1 to ignore this filter, or don't include it in the config.
<bots>	: This will only check players that are bots, or players. Acts exactly like the alive check.
<cond> 	: This is a TF2 only feature, that checks if a player is in a current condition, right now there is only ways to check if a player is one condition at a time.
```

List of all the class/team numbers:
```text
Classes:
0 : Any Class
1 : Scout
2 : Sniper
3 : Soldier
4 : Demoman
5 : Medic
6 : Heavy
7 : Pyro
8 : Spy
9 : Engineer

Teams:
0 : Any team
1 : Spectator
2 : RED
3 : BLU

Alive/Bots:
-1: Don't Check
0: Player must return false to pass
1: Player must return True to pass

Conditions: (TF2)
-1: Don't check conditions
0 : Slowed
1 : Zoomed // Snipers zooming in.
3 : Disguised //Spys that are disguised.
4 : Cloaked //Player is cloaked.
5 : Ubercharged
6 : TeleportedGlow // a user that had just teleported.
7 : Taunting
11 : Kritzkrieged 
14 : Bonked
15 : Dazed
16 : Buffed
17 : Charging
19 : CritCola
21 : Healing
22 : OnFire
23 : Overhealed
24 : Jarated
25 : Bleeding
27 : Milked
30 : MarkedForDeath
32 : SpeedBuffAlly
36 : CritHype // scout's hype?
77 : HalloweenGhostMode
```

Below this is an example that will target all scouts
```sourcepawn
"@scout"
{
	 "text"		"all Scouts"
	 "team"		"0"
	 "class"		"1"
}
When used it will display: ***** all Scouts.
i.e.: [SM] Slayed all Scouts.
```


Credit where it's due
-----------
 - [ReFlexPoison] : Created the base of the code and most of the filters syntax for the config. [Class Target Filters]
 - [ddhoward] : He also made a similar plugin of ReFlexPoison's, it had a few custom filters that I appended onto the config. [Class Targeting]




[ReFlexPoison]:https://forums.alliedmods.net/member.php?u=149090
[Class Target Filters]:https://forums.alliedmods.net/showthread.php?t=214895
[ddhoward]:https://forums.alliedmods.net/member.php?u=180597
[Class Targeting]:https://forums.alliedmods.net/showthread.php?t=226986


    