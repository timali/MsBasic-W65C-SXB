.segment "CODE"

; Output the character in A. X must be preserved, but not Y.
; Uses ZP_TMP_1, so it is not reentrant.
MONCOUT:
        stx     ZP_TMP_1
        jsr     IO_TX_DATA
        ldx     ZP_TMP_1
        rts

; Read a character and return it in A. The read character should be echoed.
; X must be preserved, but not Y.
; Uses ZP_TMP_1, so it is not reentrant.
MONRDKEY:
        stx     ZP_TMP_1
        jsr     IO_RX_DATA
        jsr     IO_TX_DATA     ; Echo the character.
        ldx     ZP_TMP_1
        rts