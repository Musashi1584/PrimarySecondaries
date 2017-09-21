[h1]This mod adds pistols as primary weapons[/h1]

Works for XCom 2 War of the Chosen.

The pistols must be bought separatly from normal pistols.

All pistols are fully upgradable.

[h1]So whats inside?[/h1]

Primary Pistol
Primary Laser Pistol (You need [Long War Laser Pack - WotC (unofficial)] for this)
Primary Mag Pistol
Primary Plasma Pistol
Primary Sawed-Off Shotgun
Primary Mag Shorty
Primary Shadowkeeper
Enhanced Primary Shadowkeeper
Powered Primary Shadowkeeper

[h1]Why do i need a separate mod for this/What does this mod actually do?[/h1]

[list]
[*]It allows classes to define the pistol category as primary weapon category, without having a soldier with bare hands

[*]It tweaks the pistols so that the default position is in the hands of your soldier and not in the holster.

[*]It tweaks the left hand position so that its on the pistol grip and not in the air or on the barrel in tactical combat (not perfect but the best i am capable of).

[*]In loadout this left hand can't be postioned atm so i recommend using the 'laid back' personality where the soldier holds the weapon upwards.

[*]It tweaks the soldiers shooting animation so the soldier don't pull and put back the pistol. Its in his hand all the time.

[*]Pistols give +3 mobility

[*]Pistols have a clip size (6 per default) and pistol shots and perks consume ammo

[/list]

Rangers and Specialist can use primary pistols out of the box.

[h1]How can my custom class use primary pistols?[/h1]
You can modify any class using primary pistols by adding this to the class defintion in XComClassData.ini

[code]
+AllowedWeapons=(SlotType=eInvSlot_PrimaryWeapon, WeaponType="pistol")
[/code]

to have the class starting with pistols you need to change the loadout e.g 
[code]
;+SquaddieLoadout="SquaddieMyFancyClass"
+SquaddieLoadout="SquaddieMyFancyClassWithPrimaryPistol"
[/code]

and in XComGameData.ini
[code]
[XComGame.X2ItemTemplateManager]
+Loadouts=(LoadoutName="SquaddieMyFancyClassWithPrimaryPistol", Items[0]=(Item="Pistol_CV_Primary"), Items[1]=(Item="InsertMyFancyClassSecondryItemHere"))
[/code]

If you are not comfortable with editing ini file and stuff don't worry, i am sure classes will be released in the future that use primary pistols.

[h1]FAQ[/h1]
The laser pistol effects seem broken?

Sub to [url=steamcommunity.com/workshop/filedetails/?id=1124064427]"Missing Packages Fix + Resource"[/url], this should fix the problem.


[h1]Credits to:[/h1]
Pavonis Interactive and Capnpubs for the Laser and Coil Pistol.
Krakah for the pistol attachments.
.vhs for the steam workshop image.
