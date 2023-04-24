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

; Platform-specific macro to (re)enable interrupts.
.macro PLATFORM_CLI
                cli
.endmacro

; Platform-specific macro to disable interrupts.
.macro PLATFORM_SEI
                sei
.endmacro

; Called to allow the platform port to initialize itself.
; May use any registers without preserving their contents.
PLATFORM_INIT:

        ; Perform a soft-reset of the ACIA.
        lda     #$00
        sta     ACIA_STATUS_RESET

        ; Initialize the UART variables.
        sta     UART_RX_WR_IDX
        sta     UART_RX_RD_IDX
        sta     UART_STATUS

        ; Configure for desired baud, 8 stop bits, 1 data bit.
        lda     #$10 + UART_BAUD
        sta     ACIA_CTRL

        ; No parity, RTS and DTR low (ready), enable interrupts.
        lda     #$09
        sta     ACIA_CMD

.if (UART_FLOW_CONTROL_HW)
        ; Lower our RTS output (CA2), which asserts the signal, allowing data to
        ; be sent from the remote device to BASIC.
        lda     #$0C
        sta     USR_VIA_PCR
.endif

        ; Install our IRQ handler by overwriting the monitor's IRQ-02 shadow vector.
        lda     #<IRQ_HANDLER
        sta     IRQ_SHADOW_VEC
        lda     #>IRQ_HANDLER
        sta     IRQ_SHADOW_VEC+1

        ; Perform an initial read of the status register to clear out any stale
        ; flags, like the receiver overflow flag.
        lda     ACIA_STATUS_RESET

        ; Enable interrupts.
        cli

        rts

; Interrupt handler for 6502-emulation mode (which is the only mode we execute in).
; This is called from the ROM monitor only upon an actual IRQ (BRKs break into the
; ROM monitor instead). The ROM monitor does not save any context other than what
; the ISR automatically saves, so we're responsible for saving/restoring context.
;
; This ISR is called for any interrupt generated on the system. Currently, this is
; only UART interrupts. The UART ISR will be called in response to one of these:
;
;       1) A byte has been received.
;       2) The DSR line has changed state.
;       3) The DCD line has changed state.
;
; Unfortunately, there is no way to disable the DSR and DCD interrupts, so these
; lines must not be left floating, otherwise spurious interrupts can (and will)
; occur.
IRQ_HANDLER:
        ; Save all the registers we use.
        pha
        phx

        ; Bit 7 of ACIA_STATUS_RESET indicates whether the UART has generated the
        ; interrupt. If there are multiple devices which could generate an interrupt,
        ; then we should check this bit to see if it was the UART or something else.
        ; Currently, only the UART generates interrupts, so there is no need to check
        ; it.

        ; Read the status register, which tells us if data is recieved and the status.
        lda     ACIA_STATUS_RESET

        ; Mask out everything but the framing and overrun bits, and set them in the
        ; UART_STATUS variable if they are set.
        tax
        and     #$06
        tsb     UART_STATUS
        txa

        ; Check to see if data has been received.
        bit     #$08
        beq     @No_Rx_Data

@No_Receiver_Overrun:

        ; Read the received data. This clears the bit in the status register, which
        ; disables interrupt generation for this condition.
        lda     ACIA_DATA

        ; Store the character at the next free write position in the RX buffer.
        ldx     UART_RX_WR_IDX
        sta     UART_RX_BUFF, x

.if (UART_FLOW_CONTROL_HW)
        ; There is at least one byte in the RX buffer, so de-assert RTS (raise CA2)
        ; to prevent any more data being added. We technically only need to do this
        ; when the buffer transitions from empty to non-empty, but it does not hurt,
        ; and it is simpler, to do it every time we receive a byte.
        lda     #$0E
        sta     USR_VIA_PCR

@Move_To_Next_Index:
.endif

        ; Compute the next write position in the RX buffer.
        inx
        txa
        and     #UART_RX_BUFF_MASK

        ; See if the RX buffer is full (if write index == read index).
        cmp     UART_RX_RD_IDX
        bne     @Update_Write_Ptr

        ; The RX buffer is full, so we've lost the incoming data.
        lda     #$01
        tsb     UART_STATUS
        bra     @No_Rx_Data

@Update_Write_Ptr:

        ; The buffer is not full, so update the write index, which effectively
        ; adds the received data to the RX buffer.
        sta     UART_RX_WR_IDX

@No_Rx_Data:
        ; At this point, DSR and/or DCD may have also changed state, but we don't
        ; care about them. They will not generate another IRQ until they change states
        ; again.

        ; Restore all the registers we use and return from the ISR.
        plx
        pla
        rti

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

        ; Wait long enough to ensure the character is output. The ACIA has a
        ; bug which prevents us from polling the UART to find this out.
        ldy     #UART_DELAY_Y
        ldx     #UART_DELAY_X
        jsr     MON_DELAY

        rts

; Waits for a character, and returns it in A.
IO_RX_DATA:
        ; Only the write pointer is modified within the ISR, so we know the read
        ; pointer will not change. Wait for data to be available by waiting until
        ; the write pointer is no longer equal to the read pointer.
        ldx     UART_RX_RD_IDX
@loop:
        cpx     UART_RX_WR_IDX
        beq     @loop

        ; Read the data from the buffer. Must be done before updating the index.
        ldy     UART_RX_BUFF, x

        ; Compute the next read index.
        inx
        txa
        and     #UART_RX_BUFF_MASK

.if (UART_FLOW_CONTROL_HW)
        ; See if the RX buffer has become empty (read pointer = write pointer).
        cmp     UART_RX_WR_IDX
        bne     @Store_Read_Index

        ; The buffer has become empty, so assert RTS to allow more data to be
        ; received.
        ldx     #$0C
        stx     USR_VIA_PCR

@Store_Read_Index:
.endif

        ; Store the next read index. This is the point where the ISR is notified.
        sta     UART_RX_RD_IDX

        ; Return the data read in A.
        tya
        rts

; Returns 0 in A if no input data is available.
IO_IS_RX_DATA:
        ; The RX buffer is empty if the read pointer = write pointer.
        lda     UART_RX_WR_IDX
        cmp     UART_RX_RD_IDX

        rts