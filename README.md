IP65 consists of three parts
- A TCP/IP library to be used by 6502 asm programmers using the [ca65](http://cc65.github.io/doc/ca65.html) macro assembler.
- A TCP/IP library to be used by C programmers using the [cc65](http://cc65.github.io/doc/cc65.html) 6502 C cross compiler.
- Some ready-to-run TCP/IP programs using the TCP/IP library.

All three parts are available for three 6502 based targets
- The C64
- The Apple II
- The ATARI (XL)

IP65 requires Ethernet hardware. There's no support for TCP/IP over serial connections whatsoever.

On the C64 there are two supported Ethernet carts
- The [RR-Net](http://wiki.icomp.de/wiki/RR-Net) - emulated by [VICE](http://vice-emu.sourceforge.net/)
- The [ETH64](http://www.ide64.org/eth64.html)

On the Apple II there are three supported Ethernet cards
- The [Uthernet](https://web.archive.org/web/20010331001718/http://lancegs.a2central.com:80/) - emulated by [AppleWin](https://github.com/AppleWin/AppleWin) and [GSport](https://david-schmidt.github.io/gsport/)
- The [LANceGS](https://web.archive.org/web/20020602144800/http://lancegs.a2central.com:80/install/index.html)
- The [Uthernet II](http://a2retrosystems.com/products.htm)

On the ATARI (XL) there is one supported Ethernet cart
- The [Dragon Cart](http://www.atari8ethernet.com/) - emulated by [Altirra](http://www.virtualdub.org/altirra.html)