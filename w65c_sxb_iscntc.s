.segment "CODE"

; This is called periodically when the program is running, and during a LIST operation.
; If the user wants to BREAK, sensure the  flag is set, move $03 into A, and then allow
; code execution to flow through this file, and into the "STOP" routine. Otherwise, to
; continue without BREAK, issue an RTS, branch to RET2, or leave Z clear.
; Apparently, no registers must be saved, so all are free to use.

.if (USE_SIMULATOR)

ISCNTC:
        ; See if a key has been pressed. If not, return. We can't use IO_IS_RX_DATA
        ; because reading from the RX register to see if any data is available will
        ; actually remove the data.
        LDA     SIM_TERM_IN
        beq     RET2

        ; See if the user pressed a CTRL+C.
        cmp     #$03

        ; Fall-through to "STOP". The Z flag determines whether we BREAK or not.
.else

ISCNTC:
        ; See if a key has been pressed. If not, return.
        jsr     IO_IS_RX_DATA
        beq     RET2

        ; Get the keypress.
        jsr     IO_RX_DATA

        ; See if the user pressed a CTRL+C.
        cmp     #$03

        ; Fall-through to "STOP". The Z flag determines whether we BREAK or not.

.endif