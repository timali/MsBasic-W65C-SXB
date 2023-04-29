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

; The standard monitor does this by default, so it is only needed if we are
; using the customized ROM monitor.
.if USE_CUST_ROM_MONITOR
        jsr     IO_WAIT_FOR_USB_FIFO
.endif
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

; Waits for the USB FIFO to be configured by the host PC.
; The standard monitor does this by default, so it is only needed if we are
; using the customized ROM monitor.
.if USE_CUST_ROM_MONITOR
IO_WAIT_FOR_USB_FIFO:
        jmp     (MON_PTR_WAIT_USB_FIFO)
.endif
