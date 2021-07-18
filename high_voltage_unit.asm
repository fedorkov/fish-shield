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
;select controller
;only CONTROLLER_01 or CONTROLLER_02 must be defined!
#define     CONTROLLER_01
;#define        CONTROLLER_02

;==============================================================================
;parallel set forbidden!
#define     RELAY_100V  PORTA,RA1
#define     RELAY_200V  PORTA,RA2
#define     RELAY_250V  PORTA,RA3
#define     RELAY_300V  PORTA,RA4

#define     BUTTON      PORTA,RA5   ;is clear when button pressed
#define     POWER_KEY   PORTA,RA6   ;be attentive! check all inclusions!
#define     BUTTON_AUTO PORTA,RA7   ;autonomous mode

#define     CHANNELS07  PORTB
#define     CHANNEL0    PORTB,RB0
#define     CHANNEL1    PORTB,RB1
#define     CHANNEL2    PORTB,RB2
#define     CHANNEL3    PORTB,RB3
#define     CHANNEL4    PORTB,RB4
#define     CHANNEL5    PORTB,RB5
#define     CHANNEL6    PORTB,RB6
#define     CHANNEL7    PORTB,RB7

#define     BEEP        PORTC,RC0
#define     RELAY1      PORTC,RC1   ;soft mode
#define     RELAY2      PORTC,RC2

#define     CHANNEL8    PORTC,RC3
#define     CHANNEL9    PORTC,RC4

#define     TX_ENABLE   PORTC,RC5   ;for RS-485

;==============================================================================
flags               equ 0x20
#define F_RX                flags,0 ;rx_data enabled
#define F_ANSWER            flags,1
#define F_IMP_LEVEL         flags,2 ;low or high level
#define F_TEST_MODE         flags,3 ;test mode on/off
#define F_CONT_ACTIVE       flags,4 ;controller is active (new value)
#define F_CONT_ACTIVE_PREV  flags,5 ;controller is active (actual value)

;local
channel             equ 0x26    ;0-9
rx_data             equ 0x27
actual_data         equ 0x2A
prev_data           equ 0x2B

;xxxxxx00 - controllers off
;xxxxxx01 - controller01 on (main)
;xxxxxx10 - controller02 on (reserve)
;xxxxx0xx - frequency == 5Hz (default)
;xxxxx1xx - frequency == 10Hz
#define ACTUAL_DATA_CONT01      actual_data,0
#define ACTUAL_DATA_CONT02      actual_data,1
#define ACTUAL_DATA_10HZ        actual_data,2
#define PREV_DATA_CONT01        prev_data,0
#define PREV_DATA_CONT02        prev_data,1
#define PREV_DATA_10HZ          prev_data,2

;Timer0 (1MHz - 1us)
tmr0_h          equ 0x30
tmr0_l          equ 0x31
;Timer0 initial values:
;50Hz - 20000us - 0xB1E0
;60Hz - 16666us - 0xBEE6
;70Hz - 14286us - 0xC833
;80Hz - 12500us - 0xCF2C
;90Hz - 11111us - 0xD499
;100Hz - 10000us - 0xD8F0
TMR0_5HZ_H      equ 0xB1
TMR0_5HZ_L      equ 0xE0
;TMR0_6HZ_H     equ 0xBE
;TMR0_6HZ_L     equ 0xE6
;TMR0_7HZ_H     equ 0xC8
;TMR0_7HZ_L     equ 0x33
;TMR0_8HZ_H     equ 0xCF
;TMR0_8HZ_L     equ 0x2C
;TMR0_9HZ_H     equ 0xD4
;TMR0_9HZ_L     equ 0x99
TMR0_10HZ_H     equ 0xD8
TMR0_10HZ_L     equ 0xF0

;Timer1 (1MHz - 1us)
tmr1_h          equ 0x32
tmr1_l          equ 0x33
;Timer1 initial values:
;-250 = 0xFF06
;-300 = 0xFED4
;-350 = 0xFEA2
;-400 = 0xFE70
;-450 = 0xFE3E
;-500 = 0xFE0C
TMR1_025MS_H    equ 0xFF
TMR1_025MS_L    equ 0x06
;TMR1_030MS_H   equ 0xFE
;TMR1_030MS_L   equ 0xD4
;TMR1_035MS_H   equ 0xFE
;TMR1_035MS_L   equ 0xA2
;TMR1_040MS_H   equ 0xFE
;TMR1_040MS_L   equ 0x70
;TMR1_045MS_H   equ 0xFE
;TMR1_045MS_L   equ 0x3E
;TMR1_050MS_H   equ 0xFE
;TMR1_050MS_L   equ 0x0C

;Timer2 (7812.5Hz - 128us)
tmr2_seconds    equ 0x34
tmr2_aux        equ 0x35

;Timer3 (1MHz - 1us)
;Timer3 initial values:
;10ms: -10000 = 0xD8F0
;50ms: -50000 = 0x3CB0
TMR3_10MS_H     equ 0xD8
TMR3_10MS_L     equ 0xF0
TMR3_50MS_H     equ 0x3C
TMR3_50MS_L     equ 0xB0

;default values
#define TMR1_H_DEFAULT      TMR1_025MS_H
#define TMR1_L_DEFAULT      TMR1_025MS_L
#define TMR0_H_DEFAULT      TMR0_5HZ_H
#define TMR0_L_DEFAULT      TMR0_5HZ_L

temp0   equ 0x40
temp1   equ 0x41
temp2   equ 0x42
temp3   equ 0x43

;==============================================================================

    org     0x00
    bra     start

    org     0x08
    bra     interrupt_high

    org     0x18
    bra     interrupt_low

    code    0x200

;==============================================================================
interrupt_high:
    ;global interrupts disable
    bcf     INTCON, GIEH

    ;RX
    btfsc   PIR1, RCIF
    call    rs485_rx_next

    ;global interrupts enable
    bsf     INTCON, GIEH

    return

;------------------------------------------------------------------------------
interrupt_low:
    ;global interrupts disable
    bcf     INTCON, GIEL

    ;impulse end
    btfsc   PIR1, TMR1IF
    call    tmr1_interrupt

    ;impulse frequency
    btfsc   INTCON, TMR0IF
    call    tmr0_interrupt

    ;soft start off
    btfsc   PIR1, TMR2IF
    call    tmr2_interrupt

    ;global interrupts enable
    bsf     INTCON, GIEL

    return

;==============================================================================
start:
    movlw   b'01110010'     ;sleep mode disabled, 8MHz selected, internal osc
    movwf   OSCCON

    movlw   b'00000000'
    movwf   ADCON0
    movlw   b'00001110'     ;AN0 as analog input
    movwf   ADCON1
    movlw   b'00010010'     ;left justified, 4Tad, Fosc/32
    movwf   ADCON2

    movlw   b'10100001'     ;RA7, RA5 - buttons, AN0 - analog input
    movwf   TRISA
    clrf    PORTA

    movlw   b'00000000'
    movwf   TRISB
    clrf    PORTB
    bsf     INTCON2, RBPU

    movlw   b'11000000'     ;set TRISC<7:6> for EUSART
    movwf   TRISC
    clrf    PORTC

    ;Timer0 (1MHz - 1us) uses for generating impulse frequency (50-100Hz)
    ;clear T08BIT; prescaler (8MHz/4):2 = 1MHz (about 65ms max, 16Hz min)
    movlw   b'00000000'
    movwf   T0CON
    bsf     INTCON, TMR0IE  ;Timer0 overflow interrupt enable

    ;Timer1 (1MHz - 1us) uses for generating impulse duration (0,25-0,50ms)
    ;set RD16; prescaler (8MHz/4):2 = 1MHz (about 65ms max)
    movlw   b'10010000'
    movwf   T1CON
    bsf     PIE1, TMR1IE    ;Timer1 overflow interrupt enable

    ;Timer2 (7812.5Hz - 128us) uses for soft-start
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

    bsf     RCON, IPEN      ;interrupt priority enable

    ;default values
    clrf    flags
    clrf    flags_data
    clrf    channel
    clrf    rx_data
    clrf    actual_data
    clrf    prev_data

    movlw   TMR1_H_DEFAULT
    movwf   tmr1_h
    movlw   TMR1_L_DEFAULT
    movwf   tmr1_l
    movlw   TMR0_H_DEFAULT
    movwf   tmr0_h
    movlw   TMR0_L_DEFAULT
    movwf   tmr0_l

    ;global interrupts enable
    bsf     INTCON, GIEH
    bsf     INTCON, GIEL

;==============================================================================
;MAIN BLOCK
;==============================================================================
    call    beep
    call    rs485_rx_init

;select normal or autonomous mode
select_mode:
    btfsc   F_RX
    bra     base_mode
    btfss   BUTTON_AUTO     ;skip if not pressed (==1)
    bra     autonomous_mode
    call    btn_test
    bra     select_mode

autonomous_mode:
    call    rs485_rx_off
    call    tmr0_reinit
base_mode:
    bcf     F_RX

main_cycle:
    call    btn_test

    btfsc   F_RX            ;in autonomous mode F_RX is always clear
    call    rx_process

    bra     main_cycle

;==============================================================================
;BUTTON PROCESS
;==============================================================================
;------------------------------------------------------------------------------
;BUTTON "TEST"
;------------------------------------------------------------------------------
btn_test:
    btfsc   BUTTON          ;skip if pressed (==0)
    return

    bsf     F_TEST_MODE
    call    tmr0_off
    call    tmr1_off
    bcf     POWER_KEY
    call    tmr2_off
    bsf     RELAY1
    clrf    CHANNELS07
    bcf     CHANNEL8
    bcf     CHANNEL9
    bsf     CHANNEL0
    clrf    channel
    call    delay_50ms      ;pause for discharge
    bsf     POWER_KEY
    bra     btn_test_end

btn_test_loop:
    btfsc   BUTTON          ;skip if pressed (==0)
    bra     btn_test_loop

    call    test_switch

    ;contact chatter removal block
btn_test_end:
    call    delay_10ms
btn_test_release:
    btfss   BUTTON          ;skip if not pressed (==1)
    bra     btn_test_release
    call    delay_10ms

    bra     btn_test_loop
;   return


;==============================================================================
;TEST MODE ROUTINE
;==============================================================================
test_switch:
    clrf    CHANNELS07
    bcf     CHANNEL8
    bcf     CHANNEL9

    call    change_channel

    movlw   .0
    cpfsgt  channel
    bra     test_switch_ch0
    movlw   .1
    cpfsgt  channel
    bra     test_switch_ch1
    movlw   .2
    cpfsgt  channel
    bra     test_switch_ch2
    movlw   .3
    cpfsgt  channel
    bra     test_switch_ch3
    movlw   .4
    cpfsgt  channel
    bra     test_switch_ch4
    movlw   .5
    cpfsgt  channel
    bra     test_switch_ch5
    movlw   .6
    cpfsgt  channel
    bra     test_switch_ch6
    movlw   .7
    cpfsgt  channel
    bra     test_switch_ch7
    movlw   .8
    cpfsgt  channel
    bra     test_switch_ch8
    movlw   .9
    cpfsgt  channel
    bra     test_switch_ch9

test_switch_ch0:
    bsf     CHANNEL0
    bra     test_switch_end
test_switch_ch1:
    bsf     CHANNEL1
    bra     test_switch_end
test_switch_ch2:
    bsf     CHANNEL2
    bra     test_switch_end
test_switch_ch3:
    bsf     CHANNEL3
    bra     test_switch_end
test_switch_ch4:
    bsf     CHANNEL4
    bra     test_switch_end
test_switch_ch5:
    bsf     CHANNEL5
    bra     test_switch_end
test_switch_ch6:
    bsf     CHANNEL6
    bra     test_switch_end
test_switch_ch7:
    bsf     CHANNEL7
    bra     test_switch_end
test_switch_ch8:
    bsf     CHANNEL8
    bra     test_switch_end
test_switch_ch9:
    bsf     CHANNEL9
    bra     test_switch_end

test_switch_end:
    return

;==============================================================================
;RS-485
;==============================================================================
;------------------------------------------------------------------------------
;rs485_rx_init
;------------------------------------------------------------------------------
rs485_rx_init:
    bcf     TXSTA, TXEN     ;disable transmitter
    bcf     PIE1, TXIE      ;disable transmit interrupt

    bcf     TX_ENABLE       ;set driver to RX

    bcf     RCSTA, CREN     ;disable receiver for clearing any error
    bsf     RCSTA, CREN     ;enable receiver
    bsf     PIE1, RCIE      ;enable receive interrupt
    bcf     PIR1, RCIF      ;clear interrupt flag

    return

;------------------------------------------------------------------------------
;rs485_rx_next
;out: rx_data / -
;------------------------------------------------------------------------------
rs485_rx_next:
    bcf     PIR1, RCIF

    btfsc   RCSTA, OERR
    bra     rs485_rx_next_oerr  ;BREAKPOINT
    btfsc   RCSTA, FERR
    bra     rs485_rx_next_ferr  ;BREAKPOINT
    bra     rs485_rx_next_ok

rs485_rx_next_ferr:
    ;framing error (stop-bit error)
    movff   RCREG, temp0
    movff   RCREG, temp0    ;DEBUG: is required?
    return

rs485_rx_next_oerr:
    bcf     RCSTA, CREN     ;disable receiver for clearing any error
    bsf     RCSTA, CREN     ;enable receiver
    return

rs485_rx_next_ok:
    movff   RCREG, rx_data
    bsf     F_RX
    return

;------------------------------------------------------------------------------
;rs485_rx_off
;------------------------------------------------------------------------------
rs485_rx_off:
    bcf     RCSTA, CREN     ;disable receiver
    return

;==============================================================================
;RS-485 RX PROCESS FUNCTION
;==============================================================================
rx_process:
    movff   actual_data, prev_data
    movff   rx_data, actual_data
    bcf     F_RX

    ;----------------------------------------------------------------
    ;make this controller active or not active
    ;----------------------------------------------------------------

#ifdef CONTROLLER_01
#undef CONTROLLER_02        ;for insure
#endif

#ifdef CONTROLLER_01
    btfsc   ACTUAL_DATA_CONT01
    bsf     F_CONT_ACTIVE
    btfss   ACTUAL_DATA_CONT01
    bcf     F_CONT_ACTIVE
    btfsc   PREV_DATA_CONT01
    bsf     F_CONT_ACTIVE_PREV
    btfss   PREV_DATA_CONT01
    bcf     F_CONT_ACTIVE_PREV

#endif
#ifdef CONTROLLER_02
    btfsc   ACTUAL_DATA_CONT02
    bsf     F_CONT_ACTIVE
    btfss   ACTUAL_DATA_CONT02
    bcf     F_CONT_ACTIVE
    btfsc   PREV_DATA_CONT02
    bsf     F_CONT_ACTIVE_PREV
    btfss   PREV_DATA_CONT02
    bcf     F_CONT_ACTIVE_PREV
#endif

    ;----------------------------------------------------------------
    ;run or stop this controller
    ;----------------------------------------------------------------

    btfsc   F_CONT_ACTIVE
    bra     rx_process_cont_active_set
    bra     rx_process_cont_active_clear
rx_process_cont_active_clear:
    btfsc   F_CONT_ACTIVE_PREV
    bra     rx_process_cont_off
    bra     rx_process_cont_end
rx_process_cont_active_set:
    btfss   F_CONT_ACTIVE_PREV
    bra     rx_process_cont_on
    bra     rx_process_cont_end

rx_process_cont_off:
    call    tmr0_off
    call    tmr1_off
    bcf     POWER_KEY
    call    tmr2_off
    bsf     RELAY1          ;set bit RELAY1 for soft mode off
    clrf    CHANNELS07
    bcf     CHANNEL8
    bcf     CHANNEL9
    bsf     CHANNEL0
    clrf    channel
    bra     rx_process_cont_end

rx_process_cont_on:
    ;set_300V
    bcf     RELAY_100V
    bcf     RELAY_200V
    bcf     RELAY_250V
    call    soft_start
    call    delay_10ms
    bsf     RELAY_300V
    bsf     POWER_KEY
    call    tmr0_reinit
    bra     rx_process_cont_end

rx_process_cont_end:

    ;----------------------------------------------------------------
    ;set frequency if controller is active
    ;----------------------------------------------------------------

    btfss   F_CONT_ACTIVE
    bra     rx_process_frequency_end    ;if controller is not active

    btfsc   ACTUAL_DATA_10HZ
    bra     rx_process_10Hz_check       ;if bit ACTUAL_DATA_10HZ is set
    bra     rx_process_5Hz_check        ;if bit ACTUAL_DATA_10HZ is not set
rx_process_5Hz_check:
    btfsc   PREV_DATA_10HZ              ;skip if 5Hz is already set
    bra     rx_process_5Hz_set
    bra     rx_process_frequency_end
rx_process_10Hz_check:
    btfss   PREV_DATA_10HZ              ;skip if 10Hz is already set
    bra     rx_process_10Hz_set
    bra     rx_process_frequency_end

rx_process_5Hz_set:
    call    tmr0_off
    movlw   TMR0_5HZ_H
    movwf   tmr0_h
    movlw   TMR0_5HZ_L
    movwf   tmr0_l
    bra     rx_process_frequency_end

rx_process_10Hz_set:
    call    tmr0_off
    movlw   TMR0_10HZ_H
    movwf   tmr0_h
    movlw   TMR0_10HZ_L
    movwf   tmr0_l
    bra     rx_process_frequency_end

rx_process_frequency_end:
    btfsc   F_CONT_ACTIVE   ;for insure
    call    tmr0_reinit     ;run only if controller is active
    bra     rx_process_end

    ;----------------------------------------------------------------
    ;end
    ;----------------------------------------------------------------

rx_process_end:
    return

;==============================================================================
;TIMER FUNCTIONS
;==============================================================================
;------------------------------------------------------------------------------
tmr0_interrupt:
    call    tmr0_reinit
    call    set_levels
    call    change_channel
    return

;------------------------------------------------------------------------------
tmr0_reinit:
    bcf     T0CON, TMR0ON   ;disable Timer0
    bcf     INTCON, TMR0IF  ;clear Timer0 interrupt flag
    movff   tmr0_h, TMR0H
    movff   tmr0_l, TMR0L
    bsf     T0CON, TMR0ON   ;enable Timer0
    return

;------------------------------------------------------------------------------
tmr0_off:
    bcf     T0CON, TMR0ON   ;disable Timer0
    bcf     INTCON, TMR0IF  ;clear Timer0 interrupt flag
    return

;------------------------------------------------------------------------------
tmr1_interrupt:
    clrf    CHANNELS07
    bcf     CHANNEL8
    bcf     CHANNEL9
    call    tmr1_off
    bsf     POWER_KEY
    return

;------------------------------------------------------------------------------
tmr1_reinit:
    bcf     T1CON, TMR1ON   ;disable Timer1 ;DEBUG: don't stop timer?
    bcf     PIR1, TMR1IF    ;clear Timer1 interrupt flag
    movff   tmr1_h, TMR1H
    movff   tmr1_l, TMR1L
    bsf     T1CON, TMR1ON   ;enable Timer1
    return

;------------------------------------------------------------------------------
tmr1_off:
    bcf     T1CON, TMR1ON   ;disable Timer1 ;DEBUG: don't stop timer?
    bcf     PIR1, TMR1IF    ;clear Timer1 interrupt flag
    return

;------------------------------------------------------------------------------
;Timer2 interrupts every 128us * 256 = 32.768ms = 0.032768s
;0.032768s * 31 = 1.015808s (about 1 second)
;------------------------------------------------------------------------------
soft_start:
    bcf     RELAY1          ;clear bit RELAY1 for soft mode on
    movlw   .10
    movwf   tmr2_seconds
tmr2_second_reinit:
    movlw   .31
    movwf   tmr2_aux
tmr2_reinit:
    bcf     T2CON, TMR2ON   ;disable Timer2
    bcf     PIR1, TMR2IF    ;clear Timer2 interrupt flag
    clrf    TMR2
    bsf     T2CON, TMR2ON   ;enable Timer2
    return
;   ^^^^^^

tmr2_interrupt:
    ;every 0.032768s
    decfsz  tmr2_aux
    bra     tmr2_reinit

    ;every second (every .31 zeroing of tmr2_aux)
    decfsz  tmr2_seconds
    bra     tmr2_second_reinit

    ;finish on zeroing of tmr2_second (10 seconds)
    bsf     RELAY1          ;set bit RELAY1 for soft mode off
tmr2_off:
    bcf     T2CON, TMR2ON   ;disable Timer2
    bcf     PIR1, TMR2IF    ;clear Timer2 interrupt flag
    return

;==============================================================================
;DELAY FUNCTIONS
;==============================================================================
;------------------------------------------------------------------------------
;basic delays (uses timer)
;------------------------------------------------------------------------------
delay_10ms:
    bcf     T3CON, TMR3ON   ;stop timer
    movlw   TMR3_10MS_H
    movwf   TMR3H
    movlw   TMR3_10MS_L
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


;==============================================================================
;SOUNDS
;==============================================================================
;------------------------------------------------------------------------------
beep:
    bsf     BEEP
    call    delay_50ms
    call    delay_50ms
    bcf     BEEP
    return

;------------------------------------------------------------------------------
click:
    btg     BEEP
    call    delay_10ms
    bcf     BEEP
    return

;==============================================================================
;SECTION FUNCTIONS
;==============================================================================
;------------------------------------------------------------------------------
change_channel:
    incf    channel
    movlw   .10
    cpfslt  channel
    clrf    channel
    return

;------------------------------------------------------------------------------
set_levels:
    bcf     POWER_KEY

set_levels_ord1:
    movlw   .0
    cpfsgt  channel
    bra     set_levels_ord1_ch0
    movlw   .1
    cpfsgt  channel
    bra     set_levels_ord1_ch1
    movlw   .2
    cpfsgt  channel
    bra     set_levels_ord1_ch2
    movlw   .3
    cpfsgt  channel
    bra     set_levels_ord1_ch3
    movlw   .4
    cpfsgt  channel
    bra     set_levels_ord1_ch4
    movlw   .5
    cpfsgt  channel
    bra     set_levels_ord1_ch5
    movlw   .6
    cpfsgt  channel
    bra     set_levels_ord1_ch6
    movlw   .7
    cpfsgt  channel
    bra     set_levels_ord1_ch7
    movlw   .8
    cpfsgt  channel
    bra     set_levels_ord1_ch8
    movlw   .9
    cpfsgt  channel
    bra     set_levels_ord1_ch9

set_levels_ord1_ch0:
    movlw   b'11111110'
    movwf   CHANNELS07
    bsf     CHANNEL8
    bsf     CHANNEL9
    bra     set_levels_end
set_levels_ord1_ch1:
    movlw   b'11111101'
    movwf   CHANNELS07
    bsf     CHANNEL8
    bsf     CHANNEL9
    bra     set_levels_end
set_levels_ord1_ch2:
    movlw   b'11111011'
    movwf   CHANNELS07
    bsf     CHANNEL8
    bsf     CHANNEL9
    bra     set_levels_end
set_levels_ord1_ch3:
    movlw   b'11110111'
    movwf   CHANNELS07
    bsf     CHANNEL8
    bsf     CHANNEL9
    bra     set_levels_end
set_levels_ord1_ch4:
    movlw   b'11101111'
    movwf   CHANNELS07
    bsf     CHANNEL8
    bsf     CHANNEL9
    bra     set_levels_end
set_levels_ord1_ch5:
    movlw   b'11011111'
    movwf   CHANNELS07
    bsf     CHANNEL8
    bsf     CHANNEL9
    bra     set_levels_end
set_levels_ord1_ch6:
    movlw   b'10111111'
    movwf   CHANNELS07
    bsf     CHANNEL8
    bsf     CHANNEL9
    bra     set_levels_end
set_levels_ord1_ch7:
    movlw   b'01111111'
    movwf   CHANNELS07
    bsf     CHANNEL8
    bsf     CHANNEL9
    bra     set_levels_end
set_levels_ord1_ch8:
    movlw   b'11111111'
    movwf   CHANNELS07
    bsf     CHANNEL9
    bcf     CHANNEL8        ;for timing and insure
    bra     set_levels_end
set_levels_ord1_ch9:
    movlw   b'11111111'
    movwf   CHANNELS07
    bsf     CHANNEL8
    bcf     CHANNEL9        ;for timing and insure
    bra     set_levels_end

;----------------
set_levels_end:
    call    tmr1_reinit
    return
