.segment "CODE"
ISCNTC:

; This is called periodically when the program is running, and during a LIST operation.
; If the user wants to BREAK, sensure the  flag is set, move $03 into A, and then allow
; code execution to flow through this file, and into the "STOP" routine. Otherwise, to
; continue without BREAK, issue an RTS, branch to RET2, or leave Z clear.

.if (USE_SIMULATOR)

        ; See if a key has been pressed. If not, return.
        LDA     SIM_TERM_IN
        beq     RET2

        ; See if the user pressed a CTRL+C.
        cmp     #$03

        ; Fall-through to "STOP". The Z flag determines whether we BREAK or not.
.else

.endif