
.segment "FONTHDR"

  .word vt100_font
  .word vt100_font_end - 1

.segment "FONT"

.export vt100_font

.assert (vt100_font & $3ff) = 0, error, "Invalid font address"  ; font definition must be at an 1K boundary

vt100_font:

;$00 - space
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$01 - !
  .byte %00000000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00000000
  .byte %00011000
  .byte %00000000

;$02 - "
  .byte %00000000
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$03 - #
  .byte %00000000
  .byte %01100110
  .byte %11111111
  .byte %01100110
  .byte %01100110
  .byte %11111111
  .byte %01100110
  .byte %00000000

;$04 - $
  .byte %00011000
  .byte %00111110
  .byte %01100000
  .byte %00111100
  .byte %00000110
  .byte %01111100
  .byte %00011000
  .byte %00000000

;$05 - %
  .byte %00000000
  .byte %01100110
  .byte %01101100
  .byte %00011000
  .byte %00110000
  .byte %01100110
  .byte %01000110
  .byte %00000000

;$06 - &
  .byte %00011100
  .byte %00110110
  .byte %00011100
  .byte %00111000
  .byte %01101111
  .byte %01100110
  .byte %00111011
  .byte %00000000

;$07 - '
  .byte %00000000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$08 - (
  .byte %00000000
  .byte %00001110
  .byte %00011100
  .byte %00011000
  .byte %00011000
  .byte %00011100
  .byte %00001110
  .byte %00000000

;$09 - )
  .byte %00000000
  .byte %01110000
  .byte %00111000
  .byte %00011000
  .byte %00011000
  .byte %00111000
  .byte %01110000
  .byte %00000000

;$0A - asterisk
  .byte %00000000
  .byte %01100110
  .byte %00111100
  .byte %11111111
  .byte %00111100
  .byte %01100110
  .byte %00000000
  .byte %00000000

;$0B - plus
  .byte %00000000
  .byte %00011000
  .byte %00011000
  .byte %01111110
  .byte %00011000
  .byte %00011000
  .byte %00000000
  .byte %00000000

;$0C - comma
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00011000
  .byte %00011000
  .byte %00110000

;$0D - minus
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %01111110
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$0E - period
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00011000
  .byte %00011000
  .byte %00000000

;$0F - /
  .byte %00000000
  .byte %00000110
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %01100000
  .byte %01000000
  .byte %00000000

;$10 - 0
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %01101110
  .byte %01110110
  .byte %01100110
  .byte %00111100
  .byte %00000000

;$11 - 1
  .byte %00000000
  .byte %00011000
  .byte %00111000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %01111110
  .byte %00000000

;$12 - 2
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %01111110
  .byte %00000000

;$13 - 3
  .byte %00000000
  .byte %01111110
  .byte %00001100
  .byte %00011000
  .byte %00001100
  .byte %01100110
  .byte %00111100
  .byte %00000000

;$14 - 4
  .byte %00000000
  .byte %00001100
  .byte %00011100
  .byte %00111100
  .byte %01101100
  .byte %01111110
  .byte %00001100
  .byte %00000000

;$15 - 5
  .byte %00000000
  .byte %01111110
  .byte %01100000
  .byte %01111100
  .byte %00000110
  .byte %01100110
  .byte %00111100
  .byte %00000000

;$16 - 6
  .byte %00000000
  .byte %00111100
  .byte %01100000
  .byte %01111100
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00000000

;$17 - 7
  .byte %00000000
  .byte %01111110
  .byte %00000110
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %00110000
  .byte %00000000

;$18 - 8
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %00111100
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00000000

;$19 - 9
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %00111110
  .byte %00000110
  .byte %00001100
  .byte %00111000
  .byte %00000000

;$1A - colon
  .byte %00000000
  .byte %00000000
  .byte %00011000
  .byte %00011000
  .byte %00000000
  .byte %00011000
  .byte %00011000
  .byte %00000000

;$1B - semicolon
  .byte %00000000
  .byte %00000000
  .byte %00011000
  .byte %00011000
  .byte %00000000
  .byte %00011000
  .byte %00011000
  .byte %00110000

;$1C - <
  .byte %00000110
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %00011000
  .byte %00001100
  .byte %00000110
  .byte %00000000

;$1D - =
  .byte %00000000
  .byte %00000000
  .byte %01111110
  .byte %00000000
  .byte %00000000
  .byte %01111110
  .byte %00000000
  .byte %00000000

;$1E - >
  .byte %01100000
  .byte %00110000
  .byte %00011000
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %01100000
  .byte %00000000

;$1F - ?
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %00001100
  .byte %00011000
  .byte %00000000
  .byte %00011000
  .byte %00000000

;$20 - @
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %01101110
  .byte %01101110
  .byte %01100000
  .byte %00111110
  .byte %00000000

;$21 - A
  .byte %00000000
  .byte %00011000
  .byte %00111100
  .byte %01100110
  .byte %01100110
  .byte %01111110
  .byte %01100110
  .byte %00000000

;$22 - B
  .byte %00000000
  .byte %01111100
  .byte %01100110
  .byte %01111100
  .byte %01100110
  .byte %01100110
  .byte %01111100
  .byte %00000000

;$23 - C
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %01100000
  .byte %01100000
  .byte %01100110
  .byte %00111100
  .byte %00000000

;$24 - D
  .byte %00000000
  .byte %01111000
  .byte %01101100
  .byte %01100110
  .byte %01100110
  .byte %01101100
  .byte %01111000
  .byte %00000000

;$25 - E
  .byte %00000000
  .byte %01111110
  .byte %01100000
  .byte %01111100
  .byte %01100000
  .byte %01100000
  .byte %01111110
  .byte %00000000

;$26 - F
  .byte %00000000
  .byte %01111110
  .byte %01100000
  .byte %01111100
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %00000000

;$27 - G
  .byte %00000000
  .byte %00111110
  .byte %01100000
  .byte %01100000
  .byte %01101110
  .byte %01100110
  .byte %00111110
  .byte %00000000

;$28 - H
  .byte %00000000
  .byte %01100110
  .byte %01100110
  .byte %01111110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00000000

;$29 - I
  .byte %00000000
  .byte %01111110
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %01111110
  .byte %00000000

;$2A - J
  .byte %00000000
  .byte %00000110
  .byte %00000110
  .byte %00000110
  .byte %00000110
  .byte %01100110
  .byte %00111100
  .byte %00000000

;$2B - K
  .byte %00000000
  .byte %01100110
  .byte %01101100
  .byte %01111000
  .byte %01111000
  .byte %01101100
  .byte %01100110
  .byte %00000000

;$2C - L
  .byte %00000000
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01111110
  .byte %00000000

;$2D - M
  .byte %00000000
  .byte %01100011
  .byte %01110111
  .byte %01111111
  .byte %01101011
  .byte %01100011
  .byte %01100011
  .byte %00000000

;$2E - N
  .byte %00000000
  .byte %01100110
  .byte %01110110
  .byte %01111110
  .byte %01111110
  .byte %01101110
  .byte %01100110
  .byte %00000000

;$2F - O
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00000000

;$30 - P
  .byte %00000000
  .byte %01111100
  .byte %01100110
  .byte %01100110
  .byte %01111100
  .byte %01100000
  .byte %01100000
  .byte %00000000

;$31 - Q
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01101100
  .byte %00110110
  .byte %00000000

;$32 - R
  .byte %00000000
  .byte %01111100
  .byte %01100110
  .byte %01100110
  .byte %01111100
  .byte %01101100
  .byte %01100110
  .byte %00000000

;$33 - S
  .byte %00000000
  .byte %00111100
  .byte %01100000
  .byte %00111100
  .byte %00000110
  .byte %00000110
  .byte %00111100
  .byte %00000000

;$34 - T
  .byte %00000000
  .byte %01111110
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00000000

;$35 - U
  .byte %00000000
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01111110
  .byte %00000000

;$36 - V
  .byte %00000000
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00011000
  .byte %00000000

;$37 - W
  .byte %00000000
  .byte %01100011
  .byte %01100011
  .byte %01101011
  .byte %01111111
  .byte %01110111
  .byte %01100011
  .byte %00000000

;$38 - X
  .byte %00000000
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00111100
  .byte %01100110
  .byte %01100110
  .byte %00000000

;$39 - Y
  .byte %00000000
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00000000

;$3A - Z
  .byte %00000000
  .byte %01111110
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %01100000
  .byte %01111110
  .byte %00000000

;$3B - [
  .byte %00000000
  .byte %00011110
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011110
  .byte %00000000

;$3C - \
  .byte %00000000
  .byte %01000000
  .byte %01100000
  .byte %00110000
  .byte %00011000
  .byte %00001100
  .byte %00000110
  .byte %00000000

;$3D - ]
  .byte %00000000
  .byte %01111000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %01111000
  .byte %00000000

;$3E - ^
  .byte %00000000
  .byte %00001000
  .byte %00011100
  .byte %00110110
  .byte %01100011
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$3F - underline
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11111111
  .byte %00000000

;$40 - original: heart card; now 'HT' (line drawing mode)
;  .byte %00000000
;  .byte %00110110
;  .byte %01111111
;  .byte %01111111
;  .byte %00111110
;  .byte %00011100
;  .byte %00001000
;  .byte %00000000
  .byte %00000000
  .byte %01010000
  .byte %01110000
  .byte %01010000
  .byte %00001110
  .byte %00000100
  .byte %00000100
  .byte %00000000

;$41 - mid left window
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011111
  .byte %00011111
  .byte %00011000
  .byte %00011000
  .byte %00011000

;$42 - right box
  .byte %00000011
  .byte %00000011
  .byte %00000011
  .byte %00000011
  .byte %00000011
  .byte %00000011
  .byte %00000011
  .byte %00000011

;$43 - low right window
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %11111000
  .byte %11111000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$44 - mid right window
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %11111000
  .byte %11111000
  .byte %00011000
  .byte %00011000
  .byte %00011000

;$45 - up right window
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11111000
  .byte %11111000
  .byte %00011000
  .byte %00011000
  .byte %00011000

;$46 - original: right slant box; now 'dot' (line drawing mode)
;  .byte %00000011
;  .byte %00000111
;  .byte %00001110
;  .byte %00011100
;  .byte %00111000
;  .byte %01110000
;  .byte %11100000
;  .byte %11000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00011000
  .byte %00011000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$47 - original: left slant box; now 'pound'  (line drawing mode)
;  .byte %11000000
;  .byte %11100000
;  .byte %01110000
;  .byte %00111000
;  .byte %00011100
;  .byte %00001110
;  .byte %00000111
;  .byte %00000011
  .byte %00011100
  .byte %00110110
  .byte %01100000
  .byte %01111100
  .byte %01100000
  .byte %00110000
  .byte %01111110
  .byte %00000000

;$48 - original: right slant solid; now 'FF' (line drawing mode)
;  .byte %00000001
;  .byte %00000011
;  .byte %00000111
;  .byte %00001111
;  .byte %00011111
;  .byte %00111111
;  .byte %01111111
;  .byte %11111111
  .byte %00000000
  .byte %01110000
  .byte %01000000
  .byte %01101110
  .byte %01001000
  .byte %00001100
  .byte %00001000
  .byte %00000000

;$49 - original: low right solid; now 'CR' (line drawing mode)
;  .byte %00000000
;  .byte %00000000
;  .byte %00000000
;  .byte %00000000
;  .byte %00001111
;  .byte %00001111
;  .byte %00001111
;  .byte %00001111
  .byte %00000000
  .byte %01110000
  .byte %01000000
  .byte %01001100
  .byte %01111010
  .byte %00001100
  .byte %00001010
  .byte %00000000

;$4A - original: left slant solid;  now 'LF' (line drawing mode)
;  .byte %10000000
;  .byte %11000000
;  .byte %11100000
;  .byte %11110000
;  .byte %11111000
;  .byte %11111100
;  .byte %11111110
;  .byte %11111111
  .byte %00000000
  .byte %01000000
  .byte %01000000
  .byte %01001110
  .byte %01111000
  .byte %00001100
  .byte %00001000
  .byte %00000000

;$4B - original: up right solid; now ° (line drawing mode)
;  .byte %00001111
;  .byte %00001111
;  .byte %00001111
;  .byte %00001111
;  .byte %00000000
;  .byte %00000000
;  .byte %00000000
;  .byte %00000000
  .byte %00000000
  .byte %00011000
  .byte %01100110
  .byte %01100110
  .byte %00011000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$4C - original: up left solid; now upper line
;  .byte %11110000
;  .byte %11110000
;  .byte %11110000
;  .byte %11110000
;  .byte %00000000
;  .byte %00000000
;  .byte %00000000
;  .byte %00000000
  .byte %00000000
  .byte %11111111
  .byte %11111111
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$4D - top box
  .byte %11111111
  .byte %11111111
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$4E - bottom box
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11111111
  .byte %11111111

;$4F - original: low left solid; now lower line
;  .byte %00000000
;  .byte %00000000
;  .byte %00000000
;  .byte %00000000
;  .byte %11110000
;  .byte %11110000
;  .byte %11110000
;  .byte %11110000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11111111
  .byte %11111111
  .byte %00000000

;$50 - original: club card; now plus/minus (line drawing mode)
;  .byte %00000000
;  .byte %00011100
;  .byte %00011100
;  .byte %01110111
;  .byte %01110111
;  .byte %00001000
;  .byte %00011100
;  .byte %00000000
  .byte %00000000
  .byte %00011000
  .byte %01111110
  .byte %00011000
  .byte %00000000
  .byte %01111110
  .byte %00000000
  .byte %00000000

;$51 - up left window
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00011111
  .byte %00011111
  .byte %00011000
  .byte %00011000
  .byte %00011000

;$52 - mid box
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11111111
  .byte %11111111
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$53 - mid window
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %11111111
  .byte %11111111
  .byte %00011000
  .byte %00011000
  .byte %00011000

;$54 - original: solid circle; now 'NL' (line drawing mode)
;  .byte %00000000
;  .byte %00000000
;  .byte %00111100
;  .byte %01111110
;  .byte %01111110
;  .byte %01111110
;  .byte %00111100
;  .byte %00000000
  .byte %00000000
  .byte %01001000
  .byte %01101000
  .byte %01011000
  .byte %01001000
  .byte %00001000
  .byte %00001110
  .byte %00000000

;$55 - original: bottom solid; now 'VT' (line drawing mode)
;  .byte %00000000
;  .byte %00000000
;  .byte %00000000
;  .byte %00000000
;  .byte %11111111
;  .byte %11111111
;  .byte %11111111
;  .byte %11111111
  .byte %00000000
  .byte %01010000
  .byte %01010000
  .byte %01011110
  .byte %00100100
  .byte %00000100
  .byte %00000100
  .byte %00000000

;$56 - left box
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11000000

;$57 - up mid window
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11111111
  .byte %11111111
  .byte %00011000
  .byte %00011000
  .byte %00011000

;$58 - low mid window
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %11111111
  .byte %11111111
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$59 - original: left solid; now '<=' (line drawing mode)
;  .byte %11110000
;  .byte %11110000
;  .byte %11110000
;  .byte %11110000
;  .byte %11110000
;  .byte %11110000
;  .byte %11110000
;  .byte %11110000
  .byte %00000000
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %00011000
  .byte %00001100
  .byte %00111110
  .byte %00000000

;$5A - low left window
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011111
  .byte %00011111
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$5B - original: display escape; now diamond
;  .byte %01111000
;  .byte %01100000
;  .byte %01111000
;  .byte %01100000
;  .byte %01111110
;  .byte %00011000
;  .byte %00011110
;  .byte %00000000
  .byte %00000000
  .byte %00011000
  .byte %00111100
  .byte %01111110
  .byte %01111110
  .byte %00111100
  .byte %00011000
  .byte %00000000

;$5C - original: up arrow; now checkerboard
;  .byte %00000000
;  .byte %00011000
;  .byte %00111100
;  .byte %01111110
;  .byte %00011000
;  .byte %00011000
;  .byte %00011000
;  .byte %00000000
  .byte %10101010
  .byte %01010101
  .byte %10101010
  .byte %01010101
  .byte %10101010
  .byte %01010101
  .byte %10101010
  .byte %01010101

;$5D - original: down arrow; now '>=' (line drawing mode)
;  .byte %00000000
;  .byte %00011000
;  .byte %00011000
;  .byte %00011000
;  .byte %01111110
;  .byte %00111100
;  .byte %00011000
;  .byte %00000000
  .byte %00000000
  .byte %00110000
  .byte %00011000
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %01111100
  .byte %00000000

;$5E - original: left arrow; now 'pi' (line drawing mode)
;  .byte %00000000
;  .byte %00011000
;  .byte %00110000
;  .byte %01111110
;  .byte %00110000
;  .byte %00011000
;  .byte %00000000
;  .byte %00000000
  .byte %00000000
  .byte %00000001
  .byte %11111111
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00000000

;$5F - original: right arrow; now 'unequal' (line drawing mode)
;  .byte %00000000
;  .byte %00011000
;  .byte %00001100
;  .byte %01111110
;  .byte %00001100
;  .byte %00011000
;  .byte %00000000
;  .byte %00000000
  .byte %00000000
  .byte %00011000
  .byte %01111110
  .byte %00011000
  .byte %00011000
  .byte %01111110
  .byte %00011000
  .byte %00000000

;$60 - original: diamond card; now `
;  .byte %00000000
;  .byte %00011000
;  .byte %00111100
;  .byte %01111110
;  .byte %01111110
;  .byte %00111100
;  .byte %00011000
;  .byte %00000000
  .byte %00000000
  .byte %00110000
  .byte %00011000
  .byte %00001100
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$61 - a
  .byte %00000000
  .byte %00000000
  .byte %00111100
  .byte %00000110
  .byte %00111110
  .byte %01100110
  .byte %00111110
  .byte %00000000

;$62 - b
  .byte %00000000
  .byte %01100000
  .byte %01100000
  .byte %01111100
  .byte %01100110
  .byte %01100110
  .byte %01111100
  .byte %00000000

;$63 - c
  .byte %00000000
  .byte %00000000
  .byte %00111100
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %00111100
  .byte %00000000

;$64 - d
  .byte %00000000
  .byte %00000110
  .byte %00000110
  .byte %00111110
  .byte %01100110
  .byte %01100110
  .byte %00111110
  .byte %00000000

;$65 - e
  .byte %00000000
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %01111110
  .byte %01100000
  .byte %00111100
  .byte %00000000

;$66 - f
  .byte %00000000
  .byte %00001110
  .byte %00011000
  .byte %00111110
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00000000

;$67 - g
  .byte %00000000
  .byte %00000000
  .byte %00111110
  .byte %01100110
  .byte %01100110
  .byte %00111110
  .byte %00000110
  .byte %01111100

;$68 - h
  .byte %00000000
  .byte %01100000
  .byte %01100000
  .byte %01111100
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00000000

;$69 - i
  .byte %00000000
  .byte %00011000
  .byte %00000000
  .byte %00111000
  .byte %00011000
  .byte %00011000
  .byte %00111100
  .byte %00000000

;$6A - j
  .byte %00000000
  .byte %00000110
  .byte %00000000
  .byte %00000110
  .byte %00000110
  .byte %00000110
  .byte %00000110
  .byte %00111100

;$6B - k
  .byte %00000000
  .byte %01100000
  .byte %01100000
  .byte %01101100
  .byte %01111000
  .byte %01101100
  .byte %01100110
  .byte %00000000

;$6C - l
  .byte %00000000
  .byte %00111000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00111100
  .byte %00000000

;$6D - m
  .byte %00000000
  .byte %00000000
  .byte %01100110
  .byte %01111111
  .byte %01111111
  .byte %01101011
  .byte %01100011
  .byte %00000000

;$6E - n
  .byte %00000000
  .byte %00000000
  .byte %01111100
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00000000

;$6F - o
  .byte %00000000
  .byte %00000000
  .byte %00111100
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00000000

;$70 - p
  .byte %00000000
  .byte %00000000
  .byte %01111100
  .byte %01100110
  .byte %01100110
  .byte %01111100
  .byte %01100000
  .byte %01100000

;$71 - q
  .byte %00000000
  .byte %00000000
  .byte %00111110
  .byte %01100110
  .byte %01100110
  .byte %00111110
  .byte %00000110
  .byte %00000110

;$72 - r
  .byte %00000000
  .byte %00000000
  .byte %01111100
  .byte %01100110
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %00000000

;$73 - s
  .byte %00000000
  .byte %00000000
  .byte %00111110
  .byte %01100000
  .byte %00111100
  .byte %00000110
  .byte %01111100
  .byte %00000000

;$74 - t
  .byte %00000000
  .byte %00011000
  .byte %01111110
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00001110
  .byte %00000000

;$75 - u
  .byte %00000000
  .byte %00000000
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00111110
  .byte %00000000

;$76 - v
  .byte %00000000
  .byte %00000000
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00011000
  .byte %00000000

;$77 - w
  .byte %00000000
  .byte %00000000
  .byte %01100011
  .byte %01101011
  .byte %01111111
  .byte %00111110
  .byte %00110110
  .byte %00000000

;$78 - x
  .byte %00000000
  .byte %00000000
  .byte %01100110
  .byte %00111100
  .byte %00011000
  .byte %00111100
  .byte %01100110
  .byte %00000000

;$79 - y
  .byte %00000000
  .byte %00000000
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00111110
  .byte %00001100
  .byte %01111000

;$7A - z
  .byte %00000000
  .byte %00000000
  .byte %01111110
  .byte %00001100
  .byte %00011000
  .byte %00110000
  .byte %01111110
  .byte %00000000

;$7B - original: spade card; now: {
;  .byte %00000000
;  .byte %00011000
;  .byte %00111100
;  .byte %01111110
;  .byte %01111110
;  .byte %00011000
;  .byte %00111100
;  .byte %00000000
  .byte %00000000
  .byte %00011110
  .byte %00011000
  .byte %00110000
  .byte %00110000
  .byte %00011000
  .byte %00011110
  .byte %00000000

;$7C - |
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000

;$7D - original: display clear; now: }
;  .byte %00000000
;  .byte %01111110
;  .byte %01111000
;  .byte %01111100
;  .byte %01101110
;  .byte %01100110
;  .byte %00000110
;  .byte %00000000
  .byte %00000000
  .byte %01111000
  .byte %00011000
  .byte %00001100
  .byte %00001100
  .byte %00011000
  .byte %01111000
  .byte %00000000

;$7E - original: display backspace; now: ~
;  .byte %00001000
;  .byte %00011000
;  .byte %00111000
;  .byte %01111000
;  .byte %00111000
;  .byte %00011000
;  .byte %00001000
;  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00110110
  .byte %11011000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

;$7F - display tab
  .byte %00010000
  .byte %00011000
  .byte %00011100
  .byte %00011110
  .byte %00011100
  .byte %00011000
  .byte %00010000
  .byte %00000000

vt100_font_end:

  .end
