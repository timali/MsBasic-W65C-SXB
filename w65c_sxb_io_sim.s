.segment "CODE"

; Platform-specific macro to (re)enable interrupts.
.macro PLATFORM_CLI
                ; Do nothing here because this port does not use interrupts.
.endmacro

; Platform-specific macro to disable interrupts.
.macro PLATFORM_SEI
                ; Do nothing here because this port does not use interrupts.
.endmacro

; Called to allow the platform port to initialize itself.
; May use any registers without preserving their contents.
PLATFORM_IO_INIT:
        rts

; Outputs the character in A.
IO_TX_DATA:
        sta     SIM_TERM_OUT
        rts

; Waits for a character, and returns it in A.
IO_RX_DATA:
@loop:
        lda     SIM_TERM_IN
        beq     @loop
        rts