.segment "CODE"

.if (USE_SIMULATOR)

; Output the character in A.
MONCOUT:

        STA SIM_TERM_OUT
        RTS

; Read a character and return it in A.
MONRDKEY:
@LOOP:
        LDA SIM_TERM_IN
        BEQ @LOOP
        STA SIM_TERM_OUT
        RTS

.else

.endif
