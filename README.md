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
	 "class"	"<class>"
}
```

Here is what can be put into each one:
```text
<filtername> : this can be anything, but i would refrain from making it anything that is already in use. Start it off with an exclamation point (!) to negate the filter
<team>  : this can be 0 to 3, anything else it will ignore the filter. Set to 0 to ignore the team number.
<class> : this is a number from 0 to 9, anything other than that the filter will be ignored.
<language text> : This is the text that is printed out when a plugin uses this filter
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


    