.segment "INIT"

; Called from init.s to allow the platform port to initialize itself.
; May use any registers without preserving their contents.
PLATFORM_INIT:

        ; If we're running from ROM, then we must copy the code that accesses
        ; FLASH memory into RAM, where it will be executed.
        .if (USE_ROM)

                ; Import the linker-defined symbols we need to perform the copy.
                .import __FLASH_CODE_SIZE__
                .import __FLASH_CODE_LOAD__
                .import __FLASH_CODE_RUN__

                ; Get the number of bytes to copy. Must be < 256.
                ldx     #__FLASH_CODE_SIZE__

                ; Copy all the code from the "FLASH_CODE" section to the run address.
@Copy_Loop:
                lda     __FLASH_CODE_LOAD__-1, x
                sta     __FLASH_CODE_RUN__-1, x
                dex
                bne     @Copy_Loop

        .endif

        ; Now that the platform is initialized, initialize the platform's IO.
        jsr     PLATFORM_IO_INIT

        rts