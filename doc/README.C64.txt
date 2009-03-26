NETBOOT65


TO USE WITH VICE:
	1) unzip the archive somewhere on your local hard drive
	2) start the bin/tftp_server.rb script (e.g. by double-clicking on it)
	3) run VICE with the rrnetboot.bin cartridge attached (e.g. "x64.exe -cartrr clients\rrnetboot.bin")

When rrnetboot.bin boots, it does the following
	
	- broadcasts a DHCP request to get an IP address allocated
	- broadcasts a TFTP request for a directory listing for anything matching "*.PRG"
	- displays a menu containing whatever files the TFTP server lists as available. 
	- Once a file is selected, it is downloaded via TFTP, and executed

ADDING MORE FILES

Only single-load files can be used (this may change in a future release). The files need to be in "PRG" format, i.e.the first 2 bytes of the file must be
the load address (little-endian, i.e. low/high). The files also need to have a file extension of ".PRG" (in upper case, if your operating system of choice
is case sensitive).

Files need to be placed in the 'boot/' folder.

Due to a limitation in the menu  selection code, only the first 128 PRG files in the boot/ folder can be selected.

	
REQUIREMENTS:
	1) RR-NET or compatible adaptor (to use under VICE, you will need pcap or winpcap installed)
	2) a DHCP server on your network
	3) a working ruby installation
