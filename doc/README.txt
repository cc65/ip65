NETBOOT65

TO USE:
	1) unzip the archive somewhere on your local hard drive
	2) start the bin/tftp_server.rb script (e.g. by double-clicking on it)
	3) boot up the client/utherboot.dsk (either in AppleWin, or using ADTPro to transfer to a real Apple 2 disk)

When Utherboot.dsk boots, it runs a program called "UTHERBOOT.PG2" that does the following
	
	- checks for an uthernet in slot 3
	- broadcasts a DHCP request to get an IP address allocated
	- broadcasts a TFTP request for a directory listing for anything matching "*.PG2"
	- displays a menu containing whatever files the TFTP server lists as available. 
	- Once a file is selected, it is downloaded via TFTP, and executed

ADDING MORE FILES

Only single-load files can be used (this may change in a future release). The files need to be in "PG2" format, which is essentially a DOS 3.3 Binary file.
The first 2 bytes of the file must be the load address (little-endian, i.e. low/high), and then the next 2 bytes must be the file length (excluding the 4 byte
header). The files also need to have a file extension of ".PG2" (in upper case, if your operating system of choice is case sensitive).

If you use CiderPress (http://ciderpress.sourceforge.net/) to extract files from a DSK image, they will not be in the correct format, however there is
a script that will convert such files (including, for example, the games supplied with the Apple 2 Game Server - http://a2gameserver.berlios.de/).
If you run bin/import_ags_games.rb and specify the path to a folder containing files extracted with CiderPress, e.g. the Apple 2 Game Server "games"
directory, a copy of all the games will be placed in the boot/ folder (converted to the appropriate format) - NB due to a limitation in the menu 
selection code, only the first 128 PG2 files in the boot/ folder can be selected.

Alternatively, you can use dsktool.rb (http://dsktool.rubyforge.org/) to extract files - it will retain the appropriate file header during the extraction.
For example, to extract the "DIG DUG" game from the online copy at http://mirrors.apple2.org.za/ftp.apple.asimov.net/images/games/action/digdug.dsk.gz, do
the following:

1) cd to the netboot65/boot folder
2) execute 'dsktool http://mirrors.apple2.org.za/ftp.apple.asimov.net/images/games/action/digdug.dsk.gz -e "DIG DUG" -o DIGDUG.PG2'

	
REQUIREMENTS:
	1) Uthernet in slot 3 (to use under AppleWin, you will need winpcap installed)
	2) a DHCP server on your network
	3) a working ruby installation

LIMITATIONS:
These may be fixed in a future release.
	- Uthernet must be in slot 3
	- Only single-load programs supported
	- Only BRUNable files supported (i.e. not Applesoft or Integer BASIC)
	- No more than 128 programs will be displayed in the menu
	- no HGR font, starfield or plinkity plonkety "music"
	- No C64 support

CREDITS:
	IP65 - lightweight IP+UDP stack written in CA65 assembler, by Per Olofsson - http://www.paradroid.net/ip65
	TFTP extension to IP65 - Jonno Downes - jonno@jamtronix.com

INSPIRATION:
	Apple 2 Game Server - http://a2gameserver.berlios.de/
	AppleWin - http://applewin.berlios.de/
	comp.sys.apple2 regulars - http://groups.google.com.au/group/comp.sys.apple2/

LICENSE:
	NETBOOT65 is licensed under the same terms as IP65, the Mozilla Public License Version 1.1.
For details, please visit http://www.mozilla.org/MPL/


SOURCE CODE:
	Available at http://sourceforge.net/svn/?group_id=250168

HISTORY:
	First alpha release - 2009-01-26 (Australia Day long weekend).

AUTHOR:
	Jonno Downes - jonno@jamtronix.com
