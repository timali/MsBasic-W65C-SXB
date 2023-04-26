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

; Allows JSR through the ROM-monitor jump table.
IO_TX_DATA:
        jmp     (MON_PTR_TX_DATA)

; Allows JSR through the ROM-monitor jump table.
IO_RX_DATA:
        jmp     (MON_PTR_RX_DATA)

; Allows JSR through the ROM-monitor jump table.
IO_IS_RX_DATA:
        jmp     (MON_PTR_IS_RX_DATA)
