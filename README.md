IP65 consists of three parts:
- A [TCP/IP library to be used by 6502 asm programmers](https://github.com/cc65/ip65/wiki/Library-for-asm-programs) using the [ca65](http://cc65.github.io/doc/ca65.html) macro assembler
- A [TCP/IP library to be used by C programmers](https://github.com/cc65/ip65/wiki/Library-for-C-programs) using the [cc65](http://cc65.github.io/doc/cc65.html) 6502 C cross compiler
- Several ready-to-run TCP/IP programs using one of the libraries

All three parts are available for three 6502 based target systems:
- The C64
- The Apple II
- The ATARI (XL)

IP65 requires Ethernet hardware. There's no support for TCP/IP over serial connections whatsoever.

On the C64 there are two supported Ethernet carts:
- The [RR-Net](http://wiki.icomp.de/wiki/RR-Net) - emulated by [VICE](http://vice-emu.sourceforge.net/)
- The [ETH64](http://www.ide64.org/eth64.html)

On the Apple II there are three supported Ethernet cards:
- The [Uthernet](https://web.archive.org/web/20150323031638/http://a2retrosystems.com/products.htm) - emulated by [AppleWin](https://github.com/AppleWin/AppleWin) and [GSport](https://david-schmidt.github.io/gsport/)
- The [LANceGS](https://web.archive.org/web/20010331001718/http://lancegs.a2central.com:80/)
- The [Uthernet II](http://a2retrosystems.com/products.htm)

On the ATARI (XL) there is one supported Ethernet cart:
- The [Dragon Cart](http://www.atari8ethernet.com/) - emulated by [Altirra](http://www.virtualdub.org/altirra.html)
