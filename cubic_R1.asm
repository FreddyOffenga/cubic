; Cubic
; F#READY, 2022-08-01

; Release 1
; was: linecube_v13_dli

; v13 - 213
; a few more bytes saved - 213
; clean up, all vars are 8-bit now
; whoaaa! another 16 bytes removed and it still works - 216 bytes

; v13
; smaller, 213 bytes

; v12
; more sizecoding in action! - 232 bytes :D

; v11 - 252 bytes
; inc draw_color, no lda #1 - 252 bytes
; removed all clc/sec since they are not needed "somehow" - 254 bytes
; try 8-bit instead of 9-bit range for 360 degrees, saved only 2 bytes - 262 bytes

; v10 - 264 bytes
; added counter to cheat away from glitch - 264 bytes

; v9 - 248
; added double buffering (page flipping) - 248 bytes
; still has a glitch at about 180' rotation :/

; v8 - 227
; cut down tmp_times_16 code and calls - 227 bytes :)
; countdown loops for calc/draw - 245 bytes
; re-used last drawto point for first plot point - 249 bytes

; v7 - 266
; combined two lsr routines - 266 bytes

; v6 - 269
; inlined calc_lines - 269 bytes
; inlined another jsr - 273 bytes
; inlined rotate calculations (Minsky circle) - 277 bytes

; v5 - 285 bytes
; clear screen (gr.7 call) instead of redraw cube in black

; v4 - 300 bytes
; - extract 2x used store_position routine - 300 bytes
; - combined draw_lines and draw_verticals - 304 bytes
; - inlined 4x calc routine - 311 bytes

; v3 - 327 bytes
; - more drawing, more slowness, but now draws cube

; v2 - 295 bytes
; - even slower, two flickering rotating squares :(

; v1 - 245 bytes
; - whoohoo, rotating flickering single-face square

ICAX1Z      = $2a       ; set to $20 to skip clear screen

ROWCRS		= $54		; byte
y_position	= ROWCRS	; alias

COLCRS		= $55		; word
x_position	= COLCRS	; alias

OLDROW  	= $5a		; byte
y_start		= OLDROW	; alias

OLDCOL  	= $5b		; word
x_start		= OLDCOL	; alias

SAVMSC      = $58       ; screen pointer
RAMTOP      = $6a

open_mode	= $ef9c		; A=mode
clear_scr	= $f420		; zero screen memory
draw_to		= $f9c2		; $f9bf (stx FILFLG)
plot_pixel	= $f1d8

FILFLG		= $2b7
FILDAT		= $2fd

ATACHR		= $2fb		; drawing color
draw_color	= ATACHR	; alias

height      = 32
initial_y   = 32

origin_x    = 160/2     ; xo
origin_y    = 40        ; yo

var_x       = $80       ; byte
var_y       = $81       ; byte
var_tmp     = $82       ; byte

var_x9      = $83       ; byte
var_y9      = $84       ; byte
var_x10     = $85       ; byte
var_y10     = $86       ; byte
top_offset  = $87
counter     = $88

x_array     = $8a
y_array     = $8e

dl_vec_hi   = $af9d

COLBK       = $d01a
WSYNC       = $d40a
NMIEN       = $d40e

			org $a0

            lda #7
            jsr open_mode
            
            lda #$8d
            sta $afe0
            
            lda #<dli
            sta $200
            lda #>dli
            sta $201
                        
            lda #$c0
            sta NMIEN

            dec draw_color

reset
            lda #0
            sta counter
            sta var_x
                        
            lda #initial_y
            sta var_y
            
loop
            inc counter
            lda counter
            cmp #15
            beq reset

            lda SAVMSC+1
            sta $af9d
            eor #$20
            sta SAVMSC+1
            pha
            clc
            adc #$10
            sta RAMTOP
           
            jsr clear_scr
        
            pla
            sta SAVMSC+1

;  x9=x//256
; x10=x//512
calc_x9     lda var_x
            sta var_x9
            lsr
            sta var_x10

;  y9=y//256
; y10=y//512
calc_y9     lda var_y
            sta var_y9
            lsr
            sta var_y10
            
; draw cube
            
calc_lines
            lda #origin_x
;            clc
            adc var_y9
            sta x_array+3

            lda #origin_y
;            sec
            sbc var_x10
            sta y_array+3
            
; drawto xo-x9, yo-y10+h

            lda #origin_x
;            sec
            sbc var_x9
            sta x_array+2
            
            lda #origin_y
;            sec
            sbc var_y10
            sta y_array+2
                        
;drawto xo-y9, yo+x10+h

            lda #origin_x
;            sec
            sbc var_y9
            sta x_array+1
            
            lda #origin_y
;            clc
            adc var_x10
            sta y_array+1
            
;drawto xo+x9, yo+y10+h

            lda #origin_x
;            clc
            adc var_x9
            sta x_array+0

            lda #origin_y
;            clc
            adc var_y10
            sta y_array+0            

            lda #0
            jsr draw_lines

            lda #height
            jsr draw_lines
            
;-- Rotate cube

;x=x+(y9*delta)
calc_new_x

; tmp = y9 * delta
            lda var_y9
            lsr
            lsr
            lsr
            sta var_tmp

; var_x = var_x + tmp
            lda var_x
            clc
            adc var_tmp
            sta var_x

; y=y-((x//256)*delta)
calc_new_y

; tmp = x >> 8
            lda var_x

            lsr
            lsr
            lsr
            sta var_tmp

            
; y = y - tmp
            lda var_y
            sec
            sbc var_tmp
            sta var_y            
 
            jmp loop

; real draw using x_array, y_array

draw_lines
            sta top_offset

;            clc
            adc y_array+0
            sta y_start

            lda x_array+0
            sta x_start

            ldx #3
draw_square
            txa
            pha
            
            jsr store_position
            
            pla
            tax
            dex
            bpl draw_square

draw_vertical 
           
            ldx #3
draw_verts
            txa
            pha

            lda x_array,x
            sta x_start

            lda y_array,x
            sta y_start
            
            jsr store_position
           
            pla
            tax
            dex
            bpl draw_verts
            rts
            
store_position
            lda x_array,x
            sta x_position

            lda y_array,x
            clc
            adc top_offset

            sta y_position
            
            jmp draw_to

dli         pha
            txa
            pha
            ldx #60
raster      
            txa
            lsr
            lsr
            eor #$0f
            sta WSYNC
            sta COLBK
            dex
            bne raster

            pla
            tax
            pla
            rti
