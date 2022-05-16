.segment "CODE"

IO              = $F000

TERM_CLS        = IO + 0
TERM_OUT        = IO + 1
TERM_OUT_RAW    = IO + 2
TERM_OUT_HEX    = IO + 3
TERM_IN         = IO + 4

MONCOUT:

        STA TERM_OUT
        RTS

MONRDKEY:
@LOOP:
        LDA TERM_IN
        BEQ @LOOP
        STA TERM_OUT
        RTS
