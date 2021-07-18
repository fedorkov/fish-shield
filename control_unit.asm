    list    p=18f2520

#include    "p18f2520.inc"

    CONFIG OSC = INTIO67    ;internal oscillator, port function on RA6 and RA7
    CONFIG FCMEN = OFF      ;fail-safe clock monitor disabled
    CONFIG IESO = OFF       ;internal/external oscillator switchover disabled
    CONFIG PWRT = ON        ;power-up timer enable
    CONFIG BOREN = OFF      ;brown-out reset disabled in hardware and software
    CONFIG WDT = OFF        ;WDT disabled (control is placed on the SWDTEN bit)
    CONFIG MCLRE = OFF      ;RE3 input pin enabled; MCLR disabled
;   CONFIG LPT1OSC = OFF    ;Timer1 configured for higher power operation
    CONFIG PBADEN = OFF     ;PORTB<4:0> pins are configured as digital I/O
;   CONFIG CCP2MX = PORTBE  ;CCP2 input/output is multiplexed with RB3
    CONFIG STVREN = OFF     ;stack full/underflow will not cause reset
    CONFIG LVP = OFF        ;single-supply ICSP disabled
;   CONFIG XINST = OFF      ;legacy mode
    CONFIG DEBUG = OFF      ;background debugger disabled

    CONFIG CP0 = ON         ;block 0 (000800-001FFFh) code-protection
    CONFIG CP1 = ON         ;block 1 (002000-003FFFh) code-protection
    CONFIG CP2 = ON         ;block 2 (004000-005FFFh) code-protection
    CONFIG CP3 = ON         ;block 3 (006000-007FFFh) code-protection

    CONFIG CPB = OFF        ;boot block (000000-0007FFh) code-protection
    CONFIG CPD = OFF        ;data EEPROM code-protection
    CONFIG WRT0 = OFF       ;block 0 (000800-001FFFh) write-protection
    CONFIG WRT1 = OFF       ;block 1 (002000-003FFFh) write-protection
    CONFIG WRT2 = OFF       ;block 2 (004000-005FFFh) write-protection
    CONFIG WRT3 = OFF       ;block 3 (006000-007FFFh) write-protection
    CONFIG WRTB = OFF       ;boot block (000000-0007FFh) write-protection
    CONFIG WRTC = OFF       ;configuration registers (300000-3000FFh) write-protection
    CONFIG WRTD = OFF       ;data EEPROM write-protection
    CONFIG EBTR0 = OFF      ;block 0 (000800-001FFFh) protection from table reads executed in other blocks
    CONFIG EBTR1 = OFF      ;block 1 (002000-003FFFh) protection from table reads executed in other blocks
    CONFIG EBTR2 = OFF      ;block 2 (004000-005FFFh) protection from table reads executed in other blocks
    CONFIG EBTR3 = OFF      ;block 3 (006000-007FFFh) protection from table reads executed in other blocks
    CONFIG EBTRB = OFF      ;boot block (000000-0007FFh) protection from table reads executed in other blocks

;==============================================================================

#define     BTN_OK      PORTA,RA0   ;is clear when pressed
#define     BTN_CANCEL  PORTA,RA4   ;is clear when pressed
#define     BTN_MENU    PORTA,RA5   ;is clear when pressed
#define     DISP_LIGHT  PORTA,RA6
#define     DISP_DB     PORTB
#define     LIGHT       PORTC,RC0
#define     BEEP        PORTC,RC1
#define     DISP_RS     PORTC,RC2   ;"RS" is same as "AO"
#define     DISP_RW     PORTC,RC3
#define     DISP_E      PORTC,RC4
#define     TX_ENABLE   PORTC,RC5   ;for RS-485

;==============================================================================

str                 equ 0x00    ;.16 bytes, 0x00-0x0F

flags               equ 0x20
;#define    F_FLAG      flags,0

;local
symbol              equ 0x26
temp                equ 0x27
tx_data             equ 0x2B

;menu
menu_level          equ 0x30
menu_item           equ 0x31
menu_item0_val      equ 0x32
menu_item1_val      equ 0x33
menu_item2_val      equ 0x34
;menu_item3_val     equ 0x35
;menu_item4_val     equ 0x36
menu_value_backup   equ 0x37

MENU_ITEMS          equ .3
MENU_ITEM0_VALUES   equ .1      ;working
MENU_ITEM1_VALUES   equ .3      ;controller
MENU_ITEM2_VALUES   equ .2      ;frequency

;Timer2 (7812.5Hz - 128us)
;0.128ms * 157 = 20.096ms; -157 = 0xFF63
TMR2_20MS       equ 0x63

;Timer3 (1MHz = 1us)
;Timer3 initial values:
;10us: -10 = 0xFFF6
;40us: -40 = 0xFFD8
;1ms: -1000 = 0xFC18
;10ms: -10000 = 0xD8F0
;20ms: -20000 = 0xB1E0
;30ms: -30000 = 0x8AD0
;50ms: -50000 = 0x3CB0
TMR3_10US_H     equ 0xFF
TMR3_10US_L     equ 0xF6
TMR3_40US_H     equ 0xFF
TMR3_40US_L     equ 0xD8
TMR3_1MS_H      equ 0xFC
TMR3_1MS_L      equ 0x18
TMR3_10MS_H     equ 0xD8
TMR3_10MS_L     equ 0xF0
TMR3_20MS_H     equ 0xB1
TMR3_20MS_L     equ 0xE0
TMR3_30MS_H     equ 0x8A
TMR3_30MS_L     equ 0xD0
TMR3_50MS_H     equ 0x3C
TMR3_50MS_L     equ 0xB0

;==============================================================================
    org     0x00
    bra     start

    org     0x08
    bra     interrupt

    org     0x18
    bra     interrupt

    org     0x30

RUS_TAB_C0  db  'A', 0xA0, 'B', 0xA1, 0xE0, 'E', 0xA3, 0xA4, 0xA5, 0xA6, 'K', 0xA7, 'M', 'H', 'O', 0xA8
RUS_TAB_D0  db  'P', 'C', 'T', 0xA9, 0xAA, 'X', 0xE1, 0xAB, 0xAC, 0xE2, 0xAD, 0xAE, 0x08, 0xAF, 0xB0, 0xB1
RUS_TAB_E0  db  'a', 0xB2, 0xB3, 0xB4, 0xE3, 'e', 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 'o', 0xBE
RUS_TAB_F0  db  'p', 'c', 0xBF, 'y', 0xE4, 'x', 0xE5, 0xC0, 0xC1, 0xE6, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7

HAIL_S0 data    " << УРЗ-300 >>  "
HAIL_S1 data    "                "

M0      data    "Нормальный режим"
BLANK   data    "                "
M1      data    " Контроллер     "
M2      data    " Частота        "

M00     data    "   выключено    "
M01     data    " основной блок  "
M02     data    " резервный блок "

M10     data    " выключен       "
M11     data    " основной       "
M12     data    " резеовный      "

M20     data    " 5 Герц         "
M21     data    " 10 Герц        "


    code    0x400

;==============================================================================
interrupt:
    ;global interrupts disable
    bcf     INTCON, GIEL
    bcf     INTCON, GIEH

    btfsc   PIR1, TXIF
    call    rs485_tx_next

    ;timeout
    btfsc   PIR1, TMR2IF
    call    tmr2_interrupt

    ;global interrupts enable
    bsf     INTCON, GIEH
    bsf     INTCON, GIEL

    return

;==============================================================================
start:
    movlw   b'01110010'     ;sleep mode disabled, 8MHz selected, internal osc
    movwf   OSCCON

    movlw   b'00001111'     ;PORTA digital I/O
    movwf   ADCON1
    movlw   b'00110001'     ;RA5, RA4, RA0 - buttons
    movwf   TRISA
    clrf    PORTA

    movlw   b'00000000'
    movwf   TRISB
    clrf    PORTB

    movlw   b'11000000'
    movwf   TRISC
    clrf    PORTC

    ;Timer2 (7812.5Hz - 128us) uses for TX timing
    ;only 8 bit mode; prescaler and postscaler (8MHz/4):16:16 = 7812.5Hz (128us)
    movlw   b'01111010'
    movwf   T2CON
    bsf     PIE1, TMR2IE    ;Timer2 overflow interrupt enable

    ;Timer3 (1MHz - 1us) uses for delays (also for contact chatter removal)
    ;set RD16; prescaler (8MHz/4):2 = 1MHz (about 65ms max)
    ;don't interrupt on overflow
    movlw   b'10010000'
    movwf   T3CON

    ;--------------------------------
    ;init EUSART (RS-485)
    ;--------------------------------
    movlw   b'00000000'
    movwf   BAUDCON
    movlw   b'00000000'
    movwf   TXSTA
    movlw   b'10000000'     ;set SPEN
    movwf   RCSTA
    movlw   .12             ;9600baud
    movwf   SPBRG
    ;--------------------------------

    ;default values
    clrf    flags

    clrf    symbol
    clrf    temp

    clrf    tx_data
    clrf    menu_level
    clrf    menu_item
    clrf    menu_item0_val      ;unused
    clrf    menu_value_backup

    ;global interrupts enable
    bsf     INTCON, GIEH
    bsf     INTCON, GIEL

;==============================================================================
;MAIN BLOCK
;==============================================================================

    call    load_table
    call    disp_init
    bsf     DISP_LIGHT
    call    beep

    movlw   HIGH(HAIL_S0)
    movwf   TBLPTRH
    movlw   LOW(HAIL_S0)
    call    puts0
    movlw   HIGH(HAIL_S1)
    movwf   TBLPTRH
    movlw   LOW(HAIL_S1)
    call    puts1
    call    delay_1s
;   call    delay_1s
;   call    delay_1s

    call    disp_cls
    call    disp_refresh
    call    rs485_tx_packet

main_cycle:
    call    btn_menu
    call    btn_ok
    call    btn_cancel
    bra     main_cycle

;==============================================================================
;MENU AND BUTTON SERVICE
;==============================================================================
;------------------------------------------------------------------------------
;BUTTON "MENU"
;------------------------------------------------------------------------------
btn_menu:
    btfsc   BTN_MENU            ;skip if pressed (==0)
    return

;----------------

    movlw   .0
    cpfsgt  menu_level          ;if level 0 then...
    bra     btn_menu_lev0       ;bra

    movlw   .1
    cpfsgt  menu_level          ;if level 1 then...
    bra     btn_menu_lev1       ;bra

    ;else reset menu for insure
    clrf    menu_level
    clrf    menu_item
    bra     btn_cancel_end

;----------------

btn_menu_lev0:                  ;select menu item
    incf    menu_item
    movlw   MENU_ITEMS
    cpfslt  menu_item
    clrf    menu_item
    bra     btn_menu_end

btn_menu_lev1:
    movlw   .0
    cpfsgt  menu_item           ;if item 0 then...
    bra     btn_menu_lev1_i0

    movlw   .1
    cpfsgt  menu_item           ;if item 1 then...
    bra     btn_menu_lev1_i1    ;bra

    movlw   .2
    cpfsgt  menu_item           ;if item 2 then...
    bra     btn_menu_lev1_i2    ;bra

    bra     btn_menu_end        ;else do nothing, for insure

btn_menu_lev1_i0:
    incf    menu_item0_val
    movlw   MENU_ITEM0_VALUES
    cpfslt  menu_item0_val
    clrf    menu_item0_val
    bra     btn_menu_end

btn_menu_lev1_i1:
    incf    menu_item1_val
    movlw   MENU_ITEM1_VALUES
    cpfslt  menu_item1_val
    clrf    menu_item1_val
    bra     btn_menu_end

btn_menu_lev1_i2:
    incf    menu_item2_val
    movlw   MENU_ITEM2_VALUES
    cpfslt  menu_item2_val
    clrf    menu_item2_val
    bra     btn_menu_end

;----------------

btn_menu_end:
    call    disp_refresh

    ;contact chatter removal block
    call    delay_10ms
btn_menu_release:
    btfss   BTN_MENU            ;skip if not pressed (==1)
    bra     btn_menu_release
    call    delay_10ms
    return

;------------------------------------------------------------------------------
;BUTTON "OK"
;------------------------------------------------------------------------------
btn_ok:
    btfsc   BTN_OK              ;skip if pressed (==0)
    return

;----------------

    movlw   .0
    cpfsgt  menu_level          ;if level 0 then...
    bra     btn_ok_lev0         ;bra

    movlw   .1
    cpfsgt  menu_level          ;if level 1 then...
    bra     btn_ok_lev1         ;bra

    ;else reset menu for insure
    clrf    menu_level
    clrf    menu_item
    bra     btn_cancel_end

;----------------

btn_ok_lev0:                    ;enter menu item
    movlw   0x01                ;enter level 1
    movwf   menu_level

    movlw   .0
    cpfsgt  menu_item           ;if item 0 then...
    bra     btn_ok_lev0_i0

    movlw   .1
    cpfsgt  menu_item           ;if item 1 then...
    bra     btn_ok_lev0_i1      ;bra

    movlw   .2
    cpfsgt  menu_item           ;if item 2 then...
    bra     btn_ok_lev0_i2      ;bra

btn_ok_lev0_i0:
    clrf    menu_level          ;exit level 0 back
    clrf    menu_item           ;for insure
    bra     btn_ok_end          ;do nothing

btn_ok_lev0_i1:
    movff   menu_item1_val, menu_value_backup
    bra     btn_ok_end

btn_ok_lev0_i2:
    movff   menu_item2_val, menu_value_backup
    bra     btn_ok_end

;----------------

btn_ok_lev1:                    ;exit menu item
    clrf    menu_level          ;exit to level 0

    movlw   .0
    cpfsgt  menu_item           ;if item 0 then...
    bra     btn_ok_lev1_i0      ;that's impossible

    movlw   .1
    cpfsgt  menu_item           ;if item 1 then...
    bra     btn_ok_lev1_i1      ;bra

    movlw   .2
    cpfsgt  menu_item           ;if item 2 then...
    bra     btn_ok_lev1_i2      ;bra

btn_ok_lev1_i0:
    ;no variables to correct
    bra     btn_ok_end

btn_ok_lev1_i1:
    movff   menu_item1_val, controller      ;correct variable
    ;TODO: save variable to EEPROM
    bra     btn_ok_end

btn_ok_lev1_i2:
    movff   menu_item2_val, frequency       ;correct variable
    ;TODO: save variable to EEPROM
    bra     btn_ok_end

;----------------

btn_ok_end:
    call    disp_refresh

    ;contact chatter removal block
    call    delay_10ms
btn_ok_release:
    btfss   BTN_OK              ;skip if not pressed (==1)
    bra     btn_ok_release
    call    delay_10ms
    return

;------------------------------------------------------------------------------
;BUTTON "CANCEL"
;------------------------------------------------------------------------------
btn_cancel:
    btfsc   BTN_CANCEL          ;skip if pressed (==0)
    return

;----------------

    movlw   .0
    cpfsgt  menu_level          ;if level 0 then...
    bra     btn_cancel_lev0     ;bra

    movlw   .1
    cpfsgt  menu_level          ;if level 1 then...
    bra     btn_cancel_lev1     ;bra

    ;else reset menu for insure
    bra     btn_cancel_reset_menu

;----------------

btn_cancel_lev0:
btn_cancel_reset_menu:
    clrf    menu_level
    clrf    menu_item
    bra     btn_cancel_end

;----------------

btn_cancel_lev1:                ;exit menu item
    clrf    menu_level          ;exit to level 0

    movlw   .0
    cpfsgt  menu_item           ;if item 0 then...
    bra     btn_cancel_lev1_i0  ;that's impossible

    movlw   .1
    cpfsgt  menu_item           ;if item 1 then...
    bra     btn_cancel_lev1_i1  ;bra

    movlw   .2
    cpfsgt  menu_item           ;if item 2 then...
    bra     btn_cancel_lev1_i2  ;bra

btn_cancel_lev1_i0:
    ;no values for rollback
    bra     btn_cancel_end

btn_cancel_lev1_i1:
    movff   menu_value_backup, menu_item1_val
    bra     btn_cancel_end

btn_cancel_lev1_i2:
    movff   menu_value_backup, menu_item2_val
    bra     btn_cancel_end

;----------------

btn_cancel_end:
    call    disp_refresh

    ;contact chatter removal block
    call    delay_10ms
btn_cancel_release:
    btfss   BTN_CANCEL          ;skip if not pressed (==1)
    bra     btn_cancel_release
    call    delay_10ms
    return

;------------------------------------------------------------------------------
;disp_refresh
;------------------------------------------------------------------------------
disp_refresh:
    movlw   .0
    cpfsgt  menu_item           ;if item 0 then...
    bra     disp_refresh_i0     ;bra

    movlw   .1
    cpfsgt  menu_item           ;if item 1 then...
    bra     disp_refresh_i1     ;bra

    movlw   .2
    cpfsgt  menu_item           ;if item 2 then...
    bra     disp_refresh_i2     ;bra

    bra     disp_refresh_i0     ;else refresh to item 0

;----------------
;item 0
;----------------
disp_refresh_i0:
    movlw   HIGH(M0)
    movwf   TBLPTRH
    movlw   LOW(M0)
    call    puts0

    movlw   .0
    cpfsgt  menu_item1_val      ;if value 0 then...
    bra     disp_refresh_i0_v0  ;bra

    movlw   .1
    cpfsgt  menu_item1_val      ;if value 1 then...
    bra     disp_refresh_i0_v1  ;bra

    movlw   .2
    cpfsgt  menu_item1_val      ;if value 2 then...
    bra     disp_refresh_i0_v2  ;bra

disp_refresh_i0_v0:
    movlw   HIGH(M00)
    movwf   TBLPTRH
    movlw   LOW(M00)
    call    puts1
    bra     disp_refresh_end

disp_refresh_i0_v1:
    movlw   HIGH(M01)
    movwf   TBLPTRH
    movlw   LOW(M01)
    call    puts1
    bra     disp_refresh_end

disp_refresh_i0_v2:
    movlw   HIGH(M02)
    movwf   TBLPTRH
    movlw   LOW(M02)
    call    puts1
    bra     disp_refresh_end

    bra     disp_refresh_end    ;for insure

;------------------------
;item 1, values 0-2
;------------------------
disp_refresh_i1:
    movlw   HIGH(M1)
    movwf   TBLPTRH
    movlw   LOW(M1)
    call    puts0

    movlw   .0
    cpfsgt  menu_item1_val      ;if value 0 then...
    bra     disp_refresh_i1_v0  ;bra

    movlw   .1
    cpfsgt  menu_item1_val      ;if value 1 then...
    bra     disp_refresh_i1_v1  ;bra

    movlw   .2
    cpfsgt  menu_item1_val      ;if value 2 then...
    bra     disp_refresh_i1_v2  ;bra

disp_refresh_i1_v0:
    movlw   HIGH(M10)
    movwf   TBLPTRH
    movlw   LOW(M10)
    call    puts1
    bra     disp_refresh_end

disp_refresh_i1_v1:
    movlw   HIGH(M11)
    movwf   TBLPTRH
    movlw   LOW(M11)
    call    puts1
    bra     disp_refresh_end

disp_refresh_i1_v2:
    movlw   HIGH(M12)
    movwf   TBLPTRH
    movlw   LOW(M12)
    call    puts1
    bra     disp_refresh_end

;------------------------
;item 2, values 0-1
;------------------------
disp_refresh_i2:
    movlw   HIGH(M2)
    movwf   TBLPTRH
    movlw   LOW(M2)
    call    puts0

    movlw   .0
    cpfsgt  menu_item2_val      ;if value 0 then...
    bra     disp_refresh_i2_v0  ;bra

    movlw   .1
    cpfsgt  menu_item2_val      ;if value 1 then...
    bra     disp_refresh_i2_v1  ;bra

disp_refresh_i2_v0:
    movlw   HIGH(M20)
    movwf   TBLPTRH
    movlw   LOW(M20)
    call    puts1
    bra     disp_refresh_end

disp_refresh_i2_v1:
    movlw   HIGH(M21)
    movwf   TBLPTRH
    movlw   LOW(M21)
    call    puts1
    bra     disp_refresh_end

;------------------------

disp_refresh_end:
    movlw   .0
    cpfsgt  menu_item           ;if item 0 then...
    bra     disp_refresh_ret    ;do nothing

    movlw   .0
    cpfsgt  menu_level          ;if level 0 then...
    bra     disp_refresh_str0   ;bra

    movlw   .1
    cpfsgt  menu_level          ;if level 1 then...
    bra     disp_refresh_str1   ;bra


disp_refresh_str0:
    call    arrow_0
    bra     disp_refresh_ret

disp_refresh_str1:
    call    arrow_1
    bra     disp_refresh_ret

;----------------

disp_refresh_ret:
    return

;==============================================================================
;DISPLAY FUNCTIONS
;==============================================================================
;------------------------------------------------------------------------------
;disp_init
;------------------------------------------------------------------------------
disp_init:
    call    delay_20ms      ;wait for more than 15ms after Vcc rises to 4.5V

    ;BF can not be checked before this instruction
    movlw   b'00110000'     ;function set
    call    disp_write_inst
    call    delay_10ms      ;wait for more than 4.1ms

    ;BF can not be checked before this instruction
    movlw   b'00110000'     ;function set
    call    disp_write_inst
    call    delay_10ms      ;wait for more than 100us

    ;BF can not be checked before this instruction
    movlw   b'00110000'
    call    disp_write_inst
    call    delay_10ms

    ;BF can be checked after the following instructions.
    ;When BF is not checked, the waiting time between
    ;instructions is longer than execution instruction time

    movlw   b'00111000'     ;function set: 8-bit bus, 2-line, 5x8 dots
    call    disp_write_inst
    call    delay_10ms

    movlw   b'00001000'     ;display off, cursor off, blink off
    call    disp_write_inst
    call    delay_10ms

    movlw   b'00000001'     ;display clear
    call    disp_write_inst
    call    delay_10ms

    movlw   b'00000110'     ;entry mode set: "left to right", shift mode off
    call    disp_write_inst
    call    delay_10ms

    ;end of necessary initialization

    movlw   b'00001100'     ;display on, cursor off, blink off
    call    disp_write_inst
    call    delay_10ms

    return

;------------------------------------------------------------------------------
;disp_cls
;------------------------------------------------------------------------------
disp_cls:
    movlw   b'00000001'     ;display clear
    call    disp_write_inst
    call    delay_10ms
    return

;------------------------------------------------------------------------------
;disp_write_data, putc - write data to display
;disp_write_inst - write instruction to display
;in: WREG - byte to write
;------------------------------------------------------------------------------
disp_write_inst:
    bcf     DISP_RS         ;data (1) / instruction (0) bit
    bra     disp_write_common

disp_write_data:
putc:
    bsf     DISP_RS         ;data (1) / instruction (0) bit

disp_write_common:
    bcf     DISP_RW         ;read (1) / write (0) bit
    movwf   DISP_DB
    bsf     DISP_E
    bcf     DISP_E
    call    delay_40us
    return

;------------------------------------------------------------------------------
;puts0 - put string to display (upper string)
;puts1 - put string to display (lower string)
;input: WREG - input 16-symbol string from programm 
;------------------------------------------------------------------------------
puts0:
    call    load_str        ;uses WREG
    call    convert_str     ;uses WREG
    movlw   0x80+0x00       ;set DDRAM address 0x00 (upper string)
    bra     puts_common

puts1:
    call    load_str        ;uses WREG
    call    convert_str     ;uses WREG
    movlw   0x80+0x40       ;set DDRAM address 0x40 (lower string)

puts_common:
    call    disp_write_inst
    lfsr    FSR1, str       ;(0x000) string address in file registers
puts_loop:
    movff   INDF1, WREG
    call    putc
    movlw   str+0x0F        ;for .16 symbols, check adresses after 0xF0
    incf    FSR1L
    cpfsgt  FSR1L
    bra     puts_loop

    return

;------------------------------------------------------------------------------
;arrow functions
;------------------------------------------------------------------------------
arrow_0:
    movlw   0x80+0x00+.14   ;position .14 in upper string
    call    disp_write_inst
    movlw   '>'
    call    putc

    movlw   0x80+0x40+.14   ;position .14 in lower string
    call    disp_write_inst
    movlw   ' '
    call    putc

    return

;------------------------------------------------------------------------------
arrow_1:
    movlw   0x80+0x00+.14   ;position .14 in upper string
    call    disp_write_inst
    movlw   ' '
    call    putc

    movlw   0x80+0x40+.14   ;position .14 in lower string
    call    disp_write_inst
    movlw   '>'
    call    putc

    return

;------------------------------------------------------------------------------
arrow_off:
    movlw   0x80+0x00+.14   ;position .14 in upper string
    call    disp_write_inst
    movlw   ' '
    call    putc

    movlw   0x80+0x40+.14   ;position .14 in lower string
    call    disp_write_inst
    movlw   ' '
    call    putc

    return

;==============================================================================
;STRING FUNCTIONS
;==============================================================================
;------------------------------------------------------------------------------
;load_str
;loads 16 bytes from address TBLPTRL to string0 FSR0 (0x000)
;input: <TBLPTRH:WREG> - address in program memory of 16-byte string to load
;uses: WREG, FSR1, TBLPTR, TABLAT
;------------------------------------------------------------------------------
load_str:
    lfsr    FSR1, 0x000     ;str == 0x000, string address in file registers
    movwf   TBLPTRL
    movlw   0x0F            ;.16 symbols
load_str_loop:
    tblrd*+
    movff   TABLAT, POSTINC1
    cpfsgt  FSR1L
    bra     load_str_loop

    return

;------------------------------------------------------------------------------
;load_table
;loads rusian table with codes 0xC0-0xFF to file registers 0xC0-0xFF
;uses WREG, FSR0, TBLPTR, TABLAT
;------------------------------------------------------------------------------
load_table:
    movlw   RUS_TAB_C0
    movwf   TBLPTRL         ;start address (source)
    lfsr    FSR0, 0x0C0     ;start address (destination)
load_table_loop:
    tblrd*+
    movff   TABLAT, INDF0
    incfsz  FSR0L           ;finish after 0xFF
    bra     load_table_loop

    return

;------------------------------------------------------------------------------
;convert_str
;converts 16 bytes from address FSR0 (0x000)
;from ASCII to DV-16230 russian format
;uses WREG, FSR0 for table, FSR1 for string
;------------------------------------------------------------------------------
convert_str:
    lfsr    FSR1, str       ;(0x000) string address in file registers

convert_str_loop:
    movlw   0xBF
    cpfsgt  INDF1           ;skip if russian letter
    bra     convert_str_skip

    ;put new symbol-code to string from table
    movff   INDF1, FSR0L
    movff   INDF0, INDF1

convert_str_skip:
    movlw   str + 0x0F      ;for .16 symbols, check adresses after 0xF0
    incf    FSR1L
    cpfsgt  FSR1L
    bra     convert_str_loop

    return




;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################

;==============================================================================
;RS-485 TX PACKET
;==============================================================================
rs485_tx_packet:
    clrf    tx_data

    ;----------------
    ;set controller
    ;----------------

    movlw   .0
    cpfsgt  controller              ;if controller == 0 then...
    bra     rs485_tx_packet_freq    ;bra

    movlw   .1
    cpfsgt  controller              ;if controller == 1 then...
    bra     rs485_tx_packet_cont01  ;bra

    movlw   .2
    cpfsgt  controller              ;if controller == 2 then...
    bra     rs485_tx_packet_cont02  ;bra

rs485_tx_packet_cont01:
    movlw   b'00000001'     ;controller 01 (base)
    iorwf   tx_data, F
    bra     rs485_tx_packet_freq

rs485_tx_packet_cont02:
    movlw   b'00000010'     ;controller 02 (reserve)
    iorwf   tx_data, F
    bra     rs485_tx_packet_freq

    ;----------------
    ;set frequency
    ;----------------

rs485_tx_packet_freq:

    movlw   .0
    cpfsgt  frequency               ;if frequency == 0 then...
    bra     rs485_tx_packet_5Hz     ;bra

    movlw   .1
    cpfsgt  frequency               ;if frequency == 1 then...
    bra     rs485_tx_packet_10Hz    ;bra


rs485_tx_packet_5Hz:
    bra     rs485_tx_packet_start

rs485_tx_packet_10Hz:
    movlw   b'00000100'             ;10Hz bit
    iorwf   tx_data, F
    bra     rs485_tx_packet_start

    ;----------------
    ;transmit
    ;----------------

rs485_tx_packet_start:
    movf    tx_data, W
    call    rs485_tx_single
    call    tmr2_reinit
    return

;==============================================================================
;RS-485 TX
;==============================================================================
;------------------------------------------------------------------------------
;rs485_tx_single
;single TX without interrupts
;in: WREG - byte to transmit
;------------------------------------------------------------------------------
rs485_tx_single:
    bcf     RCSTA, CREN     ;disable receiver
    bcf     PIE1, RCIE      ;disable receive interrupt

    bsf     TX_ENABLE       ;set driver to TX
    bsf     TXSTA, TXEN     ;enable transmitter
    bsf     PIE1, TXIE      ;disable transmit interrupt
    movwf   TXREG           ;start transmission

rs485_tx_single_wait:
    btfss   TXSTA, TRMT     ;skip when TSR is empty
    bra     rs485_tx_single_wait

    return

;==============================================================================
;TIMER2
;uses for TX timing
;==============================================================================
tmr2_reinit:
    bcf     T2CON, TMR2ON   ;disable Timer2
    bcf     PIR1, TMR2IF    ;clear Timer2 interrupt flag

    ;DEBUG: empiric
    movlw   0xA0
    movwf   PR2

    movlw   TMR2_20MS
    movwf   TMR2

    bsf     T2CON, TMR2ON   ;enable Timer2
    return

;------------------------------------------------------------------------------
tmr2_off:
    bcf     T2CON, TMR2ON   ;disable Timer2
    bcf     PIR1, TMR2IF    ;clear Timer2 interrupt flag
    return

;------------------------------------------------------------------------------
tmr2_interrupt:
    call    tmr2_off
    call    rs485_tx_packet
    return

;==============================================================================
;SOUNDS
;==============================================================================
;------------------------------------------------------------------------------
click:
    bsf     BEEP
    call    delay_40us
    bcf     BEEP
    return

;------------------------------------------------------------------------------
beep:
    bsf     BEEP
    call    delay_50ms
    call    delay_50ms
    bcf     BEEP
    return

;==============================================================================
;DELAY FUNCTIONS
;==============================================================================
;------------------------------------------------------------------------------
;basic delays (uses timer)
;------------------------------------------------------------------------------
delay_10us:
    bcf     T3CON, TMR3ON   ;stop timer
    movlw   TMR3_10US_H
    movwf   TMR3H
    movlw   TMR3_10US_L
    movwf   TMR3L
    bra     delay_main

delay_40us:
    bcf     T3CON, TMR3ON   ;stop timer
    movlw   TMR3_40US_H
    movwf   TMR3H
    movlw   TMR3_40US_L
    movwf   TMR3L
    bra     delay_main

delay_1ms:
    bcf     T3CON, TMR3ON   ;stop timer
    movlw   TMR3_1MS_H
    movwf   TMR3H
    movlw   TMR3_1MS_L
    movwf   TMR3L
    bra     delay_main

delay_10ms:
    bcf     T3CON, TMR3ON   ;stop timer
    movlw   TMR3_10MS_H
    movwf   TMR3H
    movlw   TMR3_10MS_L
    movwf   TMR3L
    bra     delay_main

delay_20ms:
    bcf     T3CON, TMR3ON   ;stop timer
    movlw   TMR3_20MS_H
    movwf   TMR3H
    movlw   TMR3_20MS_L
    movwf   TMR3L
    bra     delay_main

delay_30ms:
    bcf     T3CON, TMR3ON   ;stop timer
    movlw   TMR3_30MS_H
    movwf   TMR3H
    movlw   TMR3_30MS_L
    movwf   TMR3L
    bra     delay_main

delay_50ms:
    bcf     T3CON, TMR3ON   ;stop timer
    movlw   TMR3_50MS_H
    movwf   TMR3H
    movlw   TMR3_50MS_L
    movwf   TMR3L
    bra     delay_main

delay_main:
    bcf     PIR2, TMR3IF    ;clear interrupt flag
    bsf     T3CON, TMR3ON   ;start timer
delay_loop:
    btfss   PIR2, TMR3IF
    bra     delay_loop

    bcf     T3CON, TMR3ON   ;stop timer
    bcf     PIR2, TMR3IF    ;clear interrupt flag
    return

;------------------------------------------------------------------------------
;derived delays (uses basic delays)
;------------------------------------------------------------------------------
delay_1s:
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
delay_500ms:
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
delay_250ms:
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    call    delay_50ms
    return
