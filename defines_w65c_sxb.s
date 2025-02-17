; The W65Cx-SBX boards either have a 65C02 or a 65816, so set the
; CPU to 65C02, which is the least-common denominator.
.setcpu "65c02"

; ***************** USER-CONFIGURABLE SETTINGS **********************

; 0: Run BASIC from system RAM.
; 1: Run BASIC from ROM. Currently requires the custom-ROM monitor.
USE_ROM                     = 0

; 0: Use the Kowalski 6502 simulator instead of the real SXB hardware.
; 1: Use the 65X-SXB hardware.
USE_SIMULATOR               = 0

; 0: Use the UART (ACIA) for IO.
; 1: Use the USB debugging interface (virtual COM port) for IO.
USE_USB_FOR_IO              = 0

; 0: Use the standard factory ROM monitor.
; 1: Use a custom-built ROM monitor (https://github.com/timali/W65C816SXB-Custom-ROM).
USE_CUST_ROM_MONITOR        = 1

; When using the UART, specify the baud rate.
; 0:    115200
; 1:    50
; 2:    75
; 3:    109.92
; 4:    134.58
; 5:    150
; 6:    300
; 7:    600
; 8:    1200
; 9:    1800
; A:    2400
; B:    3600
; C:    4800
; D:    7200
; E:    9600
; F:    19200
UART_BAUD                   = $0F

; When using the UART for IO, this is the size of the RX buffer. This
; must be a power of two. The actual usable space in the buffer is one
; byte less than specified.
UART_RX_BUFF_SZ             = $10

; When using the UART for IO, this controls whether hardware (RTS/CTS)
; flow control is enabled. Due to bugs on the ACIA, neither the RTS or
; CTS pins on the ACIA can be used, so we use the following workaround:
;
; 1) The CA2 output on the user VIA (J3, pin 4) is used for the RTS
;    output. This allows BASIC to control the flow of data coming into
;    it from the remote device, which is great for allowing BASIC
;    programs to be entered via a file transfer from a PC via terminal
;    emulator.
;
; 2) Flow control from BASIC to the remote device is not supported.
;    This could be accomplished using an input on the user VIA, the
;    PIA, or even the DSR or DCD inputs on the ACIA. But, flow control
;    in this direction is less important, so it is not supported.
;
; RTS/CTS flow control must be enabled on the remote device. This
; allows reliable communication even at 115200 baud.
;
; You can check the status of the UART by examining the UART status
; variable in BASIC, for example, PEEK(228). If the result is 0,
; then there have been no framing errors, receiver overruns, or RX
; buffer overflows, so all data has been received properly
UART_FLOW_CONTROL_HW        := 1

; ********************** PRIVATE SETTINGS ***************************
; Use the latest version of BASIC available, which includes several
; bugfixes.
CONFIG_2C                   := 1

CONFIG_MONCOUT_DESTROYS_Y   := 1
CONFIG_FIX_INIT_COPY        := 1
CONFIG_NULL                 := 1
CONFIG_PRINT_CR             := 1 ; print CR when line end reached
CONFIG_SAFE_NAMENOTFOUND    := 1
CONFIG_SCRTCH_ORDER         := 2

; Allow ASCII characters up through and including '~' to be used.
MAX_ASCII_VAL               = $7E;

; Currently not supported. Eventually, this will allow using OPEN, CLOSE,
; PRINT#, INPUT#, and GET# commands, to support multiple IO devices.
; CONFIG_FILE               := 1; support 

; Zero-page allocations.
ZP_START1                   = $00 ; Occupies $00-$09
ZP_START2                   = $15 ; Occupies $15-$1A + INPUTBUFFER-LENGTH
ZP_START3                   = $0A ; Uccupies $0A-14
ZP_START4                   = $63 ; Occupies $63-$BF + CHRGET and RNDSEED

; The next free ZP address is $DD. Use three bytes starting here for the USR
; vector. Upon cold start, $DD will contain "JMP IQERR". So by default, if
; the program calls USR(), it will return an Illegal Quantity error. To use
; the USR function, the program may POKE the address of their machine language
; routine to addresses $DE and $DF (LSB first).
USR                         := $DD ; Three bytes are used.

; Zero-page allocations for the custom port. These start after ZP_START4,
; which includes $1D bytes for copying CHRGET and RNDSEED, and after the
; the USR jmp vector, which uses three bytes.
ZP_START_PORT               = $E0

; constants
STACK_TOP                   := $FC
SPACE_FOR_GOSUB             := $36
NULL_MAX                    := $F2 ; probably different in original version; the image I have seems to be modified; see PDF
WIDTH                       := 80
WIDTH2                      := 56

.if (USE_ROM)

    ; When running from ROM, execute the code that accesses FLASH right after the
    ; stack. It gets copied there from ROM during initialization.
    FLASH_RUN_START         := $0200;

    ; BASIC is in ROM, so the start of available RAM is right after the code that
    ; accesses the FLASH memory.
    RAMSTART2               := FLASH_RUN_START + __FLASH_CODE_SIZE__

    ; Place BASIC at the beginning of flash memory. This is possible because we
    ; are running a custom ROM monitor, which makes this region available.
    BAS_START               := $8000

.else

    ; Place BASIC right after the stack in RAM.
    BAS_START               := $0200

    ; Start RAM for BASIC use right after the BASIC code. This is the start of
    ; the EXTRA segment. Anything in EXTRA gets loaded as code when the BASIC
    ; image is loaded, but BASIC overwrites it upon initialization.
    .import                 __EXTRA_RUN__
    RAMSTART2               := __EXTRA_RUN__

    ; When running from RAM, we can execute the code that accesses FLASH directly
    ; from its load location, so place it there.
    .import __FLASH_CODE_LOAD__
    FLASH_RUN_START         := __FLASH_CODE_LOAD__

.endif

; Export this so the linker knows where to place the BASIC image.
.export BAS_START

; Export this so the linker knows where to place the FLASH access code.
.export FLASH_RUN_START

; The start of reserved memory (prevent overwriting monitor work-RAM).
RAMEND                      := $7E00

; The region in FLASH memory where  BASIC programs are saved/loaded. This
; range was chosen so as to be free for all configurations. Note that even
; when the stock factory ROM monitor is used, the BASIC program will be
; saved/loaded to a region in FLASH which is not used by the monitor.
;
;   • BASIC in RAM with stock ROM monitor:
;       ○ FLASH free range: $9000-$EFFF (24 KB).
;   • BASIC in RAM with custom ROM monitor:
;       ○ FLASH free range: $8000-$EFFF (28 KB).
;   • BASIC in ROM with stock ROM monitor:
;       ○ Unsupported because BASIC and the ROM monitor collide. 
;   • BASIC in ROM with custom ROM monitor:
;       ○ FLASH free rnage: $B000-$EFFF (16 KB).
SAVE_FLASH_START            := $B000
SAVE_FLASH_END              := $F000

; The maximum size of the BASIC SAVE area.
SAVE_FLASH_SIZE             := SAVE_FLASH_END - SAVE_FLASH_START

; This is not a supported combination because BASIC in ROM would
; occupy the same space as the factory ROM monitor.
.if (USE_ROM && (USE_CUST_ROM_MONITOR = 0))
    .error  "USE_CUST_ROM_MONITOR must be enabled when USE_ROM is enabled."
.endif

; Kowalski 6502 Assembler/Simulator definitions.
.if (USE_SIMULATOR)

    SIM_IO                      = $F000
    SIM_TERM_CLS                = SIM_IO + 0
    SIM_TERM_OUT                = SIM_IO + 1
    SIM_TERM_OUT_RAW            = SIM_IO + 2
    SIM_TERM_OUT_HEX            = SIM_IO + 3
    SIM_TERM_IN                 = SIM_IO + 4

.else
; W65x-SXB hardware definitions.

    .if (USE_CUST_ROM_MONITOR)
        MON_PTR_TBL         := $F080
        IRQ_SHADOW_VEC      := $7EFE
    .else
        MON_PTR_TBL         := $8080
        IRQ_SHADOW_VEC      := $7EFE
    .endif

    ; Subroutines in the ROM monitor.
    MON_PTR_SIG             := MON_PTR_TBL + $00
    MON_PTR_INIT            := MON_PTR_TBL + $02
    MON_PTR_IS_RX_DATA      := MON_PTR_TBL + $04
    MON_PTR_RX_DATA         := MON_PTR_TBL + $06
    MON_PTR_TX_DATA         := MON_PTR_TBL + $08

    ; These routines are only available in the customized monitor.
.if USE_CUST_ROM_MONITOR
    MON_PTR_WAIT_USB_FIFO   := MON_PTR_TBL + $18
.endif

    ; The ACIA registers.
    ACIA_BASE               := $7F80
    ACIA_DATA               := ACIA_BASE + $00
    ACIA_STATUS_RESET       := ACIA_BASE + $01
    ACIA_CMD                := ACIA_BASE + $02
    ACIA_CTRL               := ACIA_BASE + $03

    ; The user VIA registers (only the ones we use).
    USR_VIA_BASE            := $7FC0
    USR_VIA_PCR             := USR_VIA_BASE + $0C

    ; Compute a mask based on the UART RX buffer size.
    UART_RX_BUFF_MASK       = UART_RX_BUFF_SZ - 1

.endif

; Save the current segment so we can restore it when we're done.
.pushseg

; Define ZP variables used in our port.
.zeropage
.org    ZP_START_PORT

    ; Temporary variables.
    ZP_TMP_1:       .res 1
    ZP_TMP_2:       .res 1 ; Must follow ZP+TMP_1.
    ZP_TMP_W:       .res 2

    ; Define variables used with the UART.
    .if (!USE_SIMULATOR) && (!USE_USB_FOR_IO)

        ; UART RX buffer write and read indices.
        UART_RX_WR_IDX:         .res    1
        UART_RX_RD_IDX:         .res    1

        ; The status of the UART.
        ;   Bit 0: Whether the RX buffer has overflown. This happens when the
        ;          application does not read data from the RX buffer before it
        ;          becomes full.
        ;   Bit 1: Whether an RX framing error has occurred.
        ;   Bit 2: Whether the receiver register has been overrun. This happens
        ;          when the ISR does not read the data from the UART receiver
        ;          register before another byte was received.
        UART_STATUS:            .res    1

        ; The UART RX buffer.
        UART_RX_BUFF:           .res    UART_RX_BUFF_SZ

    .endif

    ; Check to ensure all our zero-page variables fit.
    .if (* > $100)
        .error "Out of space in zero page."
    .endif

; Set up the RST vector to point to COLD_START. This is useful when
; using the WDC debugger, so the debugger knows the entry point.
.segment "RSTVEC"
    .addr   COLD_START

; Restore the previous segment in use.
.popseg