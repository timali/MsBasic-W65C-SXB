.segment "CODE"

.if UART_BAUD = $00             ; 115200, 695 cycles @ 8 MHz
        UART_DELAY_Y    = 1
        UART_DELAY_X    = 139

.elseif UART_BAUD = $01         ; 50
        .error "Baud rate not supported because it requires a longer delay."
.elseif UART_BAUD = $02         ; 75
        .error "Baud rate not supported because it requires a longer delay."
.elseif UART_BAUD = $03         ; 110
        .error "Baud rate not supported because it requires a longer delay."

.elseif UART_BAUD = $06         ; 300, 266670 cycles @ 8 MHz
        UART_DELAY_Y    = 209
        UART_DELAY_X    = 86

.elseif UART_BAUD = $08         ; 1200, 66670 cycles @ 8 MHz
        UART_DELAY_Y    = 53
        UART_DELAY_X    = 22

.elseif UART_BAUD = $0F         ; 19200, 4170 cycles @ 8 MHz
        UART_DELAY_Y    = 4
        UART_DELAY_X    = 66
.else
        .error "You must calculate the UART delays for this baud rate."
.endif

; Called to allow the platform port to initialize itself.
; May use any registers without preserving their contents.
PLATFORM_INIT:
        ; Perform a soft-reset of the ACIA.
        lda     #$00
        sta     ACIA_STATUS_RESET

        ; Configure for 19200 baud, 8 stop bits, 1 data bit.
        lda     #$10 + UART_BAUD
        sta     ACIA_CTRL

        ; No partiy, RTS and DTR low (ready), disable interrupts.
        lda     #$0B
        sta     ACIA_CMD

        rts

; Delays at least 5X+1280(Y-1) cycles. If X/Y is 0, then it behaves like X/Y is 256.
; The W65Cx SXB boards have an 8 MHz clock, so the delay is 160 us per Y count.
MON_DELAY:
@loop:  dex          ; (2 cycles)
        bne  @loop   ; (3 cycles in loop, 2 cycles at end)
        dey          ; (2 cycles)
        bne  @loop   ; (3 cycles in loop, 2 cycles at end)
        rts

; Outputs the character in A.
IO_TX_DATA:
        ; Write the character to the UART.
        sta     ACIA_DATA

        ; Wait long endough to ensure the character is output. The ACIA has a
        ; bug which prevents us from polling the UART to find this out.
        ldy     #UART_DELAY_Y
        ldx     #UART_DELAY_X
        jsr     MON_DELAY

        rts

; Waits for a character, and returns it in A.
IO_RX_DATA:
        ; Wait for a character to be available.
        lda     #$08
        bit     ACIA_STATUS_RESET
        beq     IO_RX_DATA

        ; Read the character.
        lda     ACIA_DATA

        rts

; Returns 0 in A if no input data is available.
IO_IS_RX_DATA:
        lda     #$08
        bit     ACIA_STATUS_RESET
        rts