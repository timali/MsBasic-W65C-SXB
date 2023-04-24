; SAVE/LOAD support for the W65Cx-SXB.
;
; The FLASH memory in the currently-selected bank is used for saving and
; loading, but the region used is free in all supported configurations, so
; it can be used with both the factory ROM monitor and the customized ROM
; monitor, and with MS-BASIC running from FLASH or from RAM.
;
; The first two bytes saved to FLASH are the size of the program (LSB-first),
; followed by the actual program bytes.

.segment "CODE"

; Whether to actually perform the FLASH operations or not. Used for debugging.
PERFORM_FLASH_OPERATIONS                = 1

; Saves the current program to FLASH memory. The program is stored in TXTTAB,
; so we need to save from TXTTAB up to VARTAB, which immediately follows it.
SAVE:
        ; Subtraction requires carry flag initially set.
        sec

        ; Compute the number of bytes to write. Start with the LSB.
        lda     VARTAB
        sbc     TXTTAB
        sta     ZP_TMP_1

        ; Finish the computation with the LSB.
        lda     VARTAB+1
        sbc     TXTTAB+1
        sta     ZP_TMP_2

        ; See if the program will fit by examining the MSB. Account for storing
        ; an additional two bytes to record the program's size.
        lda     #>(SAVE_FLASH_SIZE-2)
        cmp     ZP_TMP_2
        bcc     @Too_Big
        bne     @Size_Ok

        ; If the MSBs are the same, compare the LSBs.
        lda     #<(SAVE_FLASH_SIZE-2)
        cmp     ZP_TMP_1
        bcc     @Too_Big

@Size_Ok:

        ; Use ZP_TMP_W as a FLASH write pointer.
        lda     #<SAVE_FLASH_START
        sta     ZP_TMP_W
        lda     #>SAVE_FLASH_START
        sta     ZP_TMP_W+1

@Erase_Loop:
        ; Erase the FLASH sector.
        jsr     ERASE_FLASH_SECTOR

        ; Move to the next FLASH sector (each sector is 4 KB).
        clc
        lda     ZP_TMP_W+1
        adc     #$10
        sta     ZP_TMP_W+1

        ; See if we've erased all the sectors we need to.
        cmp     #>SAVE_FLASH_END
        bcc     @Erase_Loop

        ; Use ZP_TMP_W as a FLASH write pointer. Only need to restore MSB.
        lda     #>SAVE_FLASH_START
        sta     ZP_TMP_W+1

        ; Write the size LSB.
        lda     ZP_TMP_1
        jsr     WRITE_FLASH_BYTE

        ; Write the size MSB.
        lda     ZP_TMP_2
        jsr     WRITE_FLASH_BYTE

        ; Use ZP_TMP_1,ZP_TMP_2 as a source address pointer. Copy from TXTTAB.
        lda     TXTTAB
        sta     ZP_TMP_1
        lda     TXTTAB+1
        sta     ZP_TMP_2

@FlashCopyLoop:

        ; Load the next byte to copy from the source pointer.
        lda     (ZP_TMP_1)

        ; Write the byte to FLASH.
        jsr     WRITE_FLASH_BYTE

        ; Move to the next source address.
        inc     ZP_TMP_1
        bne     @SourcePtrUpdated
        inc     ZP_TMP_2

@SourcePtrUpdated:

        ; See if we're done copying. Check the LSB.
        lda     ZP_TMP_1
        cmp     VARTAB
        bne     @FlashCopyLoop

        ; The LSB matches, so now check the MSB.
        lda     ZP_TMP_2
        cmp     VARTAB+1
        bne     @FlashCopyLoop

        ; Print the message indicating the program was saved. This is a tail
        ; call, so the RTS is performed at the end of STROUT.
        lda     #<QT_SAVED
        ldy     #>QT_SAVED
        jmp     STROUT

        ; Print the message indicating the program is too large. This performs
        ; a tail call, with STROUT performing an RTS, so a call to this will
        ; end up returning from the caller's current function.
@Too_Big:
        lda     #<QT_TOO_BIG
        ldy     #>QT_TOO_BIG
        jmp     STROUT

; Erases the flash sector containing the address contained in ZP_TMP_W.
ERASE_FLASH_SECTOR:

        ; Disable interrupts to ensure FLASH access sequence is not interrupted.
        PLATFORM_SEI

        .if (PERFORM_FLASH_OPERATIONS)

        ; Prepare the FLASH for erasing a sector.
        lda     #$AA
        sta     $8000+$5555
        lda     #$55
        sta     $8000+$2AAA
        lda     #$80
        sta     $8000+$5555
        lda     #$AA
        sta     $8000+$5555
        lda     #$55
        sta     $8000+$2AAA
        lda     #$30

        ; Initialiate the erase by writing to any byte within the sector.
        sta     (ZP_TMP_W)

@CheckForEraseComplete:
        lda     (ZP_TMP_W)
        cmp     #$FF
        bne     @CheckForEraseComplete

        .endif

        ; It is now safe to reenable interrupts.
        PLATFORM_CLI

        rts

; Writes the byte in A to the FLASH memory pointed to by ZP_TMP_W. The pointer at
; ZP_TMP_W will automatically be incremented to the next address.
WRITE_FLASH_BYTE:

        ; Disable interrupts to ensure FLASH access sequence is not interrupted.
        PLATFORM_SEI

        .if PERFORM_FLASH_OPERATIONS

        ; Issue the sequence to unlock the FLASH memory to write a byte.
        ldx     #$AA
        stx     $8000 + $5555
        ldx     #$55
        stx     $8000 + $2AAA
        ldx     #$A0
        stx     $8000 + $5555

        ; A holds the byte to write. Store it at the address pointed to by ZP_TMP_W.
        sta     (ZP_TMP_W)

        ; Wait until the write has completed. It should take at most 20 us.
@CheckForWriteComplete:
        cmp     (ZP_TMP_W)
        bne     @CheckForWriteComplete

        .endif

        ; It is now safe to reenable interrupts.
        ; BUT INTERRUPTS ARE ONLY ENABLED TO START WITH FOR UART builds.
        ; So only enable interrupts here if there were originally enabled.
        PLATFORM_CLI

        ; Move to the next address.
        inc     ZP_TMP_W
        bne     @SkipMsb
        inc     ZP_TMP_W+1
@SkipMsb:

        rts

; Loads the current program from FLASH memory. The program must be loaded to the
; area pointed to by TXTTAB, and then VARTAB must be set to point immediately
; after the program.
LOAD:
        ; Print the message indicated the program was loaded.
        lda     #<QT_LOADED
        ldy     #>QT_LOADED
        jsr     STROUT

        ; Print the 'OK', because it does not automatically get printed
        ; by the final call to FIX_LINKS.
        lda     #<QT_OK
        ldy     #>QT_OK
        jsr     STROUT

        ; Re-link the program. This is a tail call, so when FIX_LINKS
        ; completes, it calls JSR, which returns to the original caller.
        jmp     FIX_LINKS

QT_SAVED:
        .byte   "SAVED"
        .byte   $0D,$0A,$00

QT_TOO_BIG:
        .byte   "TOO BIG"
        .byte   $0D,$0A,$00

QT_LOADED:
        .byte   "LOADED"
        .byte   $0D,$0A,$00