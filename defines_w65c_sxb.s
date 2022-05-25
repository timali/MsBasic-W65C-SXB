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
; 1: Use a custom-built ROM monitor.
USE_CUST_ROM_MONITOR        = 0

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
UART_BAUD                   = $00

; When using the UART for IO, this is the size of the RX buffer. This
; must be a power of two. The actual usable space in the buffer is one
; byte less than specified.
UART_RX_BUFF_SZ             = $10

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

; Currently not supported.
; CONFIG_FILE               := 1; support PRINT#, INPUT#, GET#, CMD

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
    ; BASIC is in ROM, so the start of available RAM is right after the stack.
    RAMSTART2               := $0200

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

.endif

; Export this so the linker knows where to place the BASIC image.
.export BAS_START

; The start of reserved memory (prevent overwriting monitor work-RAM).
RAMEND                      := $7E00

; magic memory locations
L1800                       := $1800
L1873                       := $1873

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

    MON_PTR_SIG             := MON_PTR_TBL + $00
    MON_PTR_INIT            := MON_PTR_TBL + $02
    MON_PTR_IS_RX_DATA      := MON_PTR_TBL + $04
    MON_PTR_RX_DATA         := MON_PTR_TBL + $06
    MON_PTR_TX_DATA         := MON_PTR_TBL + $08

    ACIA_BASE               := $7F80
    ACIA_DATA               := ACIA_BASE + $00
    ACIA_STATUS_RESET       := ACIA_BASE + $01
    ACIA_CMD                := ACIA_BASE + $02
    ACIA_CTRL               := ACIA_BASE + $03

    UART_RX_BUFF_MASK       = UART_RX_BUFF_SZ - 1

.endif

; Save the current segment so we can restore it when we're done.
.pushseg

; Define ZP variables used in our port.
.zeropage
.org    ZP_START_PORT

    ; Temporary variables.
    ZP_TMP_1:       .res 1
    ZP_TMP_2:       .res 1

    ; Define variables used with the UART.
    .if (!USE_SIMULATOR) && (!USE_USB_FOR_IO)
        ; The UART RX buffer.
        UART_RX_BUFF:           .res    UART_RX_BUFF_SZ

        ; UART RX buffer write and read indices.
        UART_RX_WR_IDX:         .res    1
        UART_RX_RD_IDX:         .res    1

        ; The number of UART RX overflows.
        UART_RX_OVERFLOWS:      .res    1
    .endif

; Set up the RST vector to point to COLD_START. This is useful when
; using the WDC debugger, so the debugger knows the entry point.
.segment "RSTVEC"
    .addr   COLD_START

; Restore the previous segment in use.
.popseg