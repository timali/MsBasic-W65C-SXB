.segment "CODE"

.if (USE_SIMULATOR)

; Output the character in A. X must be preserved, but not Y.
MONCOUT:

        STA SIM_TERM_OUT
        RTS

; Read a character and return it in A. The read character should be echoed.
; X must be preserved, but not Y.
MONRDKEY:
@LOOP:
        LDA SIM_TERM_IN
        BEQ @LOOP
        STA SIM_TERM_OUT
        RTS

.else

; Allows JSR through the ROM-monitor jump table.
MON_TX_DATA:
        jmp     (MON_PTR_TX_DATA)

; Allows JSR through the ROM-monitor jump table.
MON_RX_DATA:
        jmp     (MON_PTR_RX_DATA)

; Allows JSR through the ROM-monitor jump table.
MON_IS_RX_DATA:
        jmp     (MON_PTR_IS_RX_DATA)

; Output the character in A. X must be preserved, but not Y.
MONCOUT:
        phx
        jsr     MON_TX_DATA
        plx
        rts

; Read a character and return it in A. The read character should be echoed.
; X must be preserved, but not Y.
MONRDKEY:
        phx
        jsr     MON_RX_DATA
        jsr     MON_TX_DATA     ; Echo the character.
        plx
        rts

.endif
