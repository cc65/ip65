	.import console_printf


	.macro printfargs arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
	.ifnblank arg1
	    .addr arg1
	    printfargs arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
	.endif
	.endmacro

	.macro printf str, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

	.local arglist
	.local string

	pha
	.ifpc02
	phx
	phy
	.else
	txa
	pha
	tya
	pha
	.endif
	ldax #arglist
	jsr console_printf
	.ifpc02
	ply
	plx
	.else
	pla
	tay
	pla
	tax
	.endif
	pla

	.pushseg
	.rodata
	.if (.match(str, ""))
string:
	    .asciiz str
arglist:
	    .addr string
	.else
arglist:
	    .addr str
	.endif

	printfargs arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

	.popseg

	.endmacro
