; configuration. Use the latest version of BASIC available, which
; includes several bugfixes.
CONFIG_2C                   := 1

CONFIG_MONCOUT_DESTROYS_Y   := 1
CONFIG_FIX_INIT_COPY        := 1
CONFIG_NULL                 := 1
CONFIG_PRINT_CR             := 1 ; print CR when line end reached
CONFIG_SAFE_NAMENOTFOUND    := 1
CONFIG_SCRTCH_ORDER         := 2

USE_SIMULATOR               = 1 ; Use the 6502 simulator instead of the real hardware

; CONFIG_FILE                 := 1; support PRINT#, INPUT#, GET#, CMD

; zero page
ZP_START1                   = $00 ; Occupies $00-$9
ZP_START2                   = $15 ; Occupies $15-??
ZP_START3                   = $0A ; Uccupies $0A-14
ZP_START4                   = $63

; extra/override ZP variables
USR                         := GORESTART    ; xxx Same as CBM, but is this right?

; constants
STACK_TOP                   := $FC
SPACE_FOR_GOSUB             := $36
NULL_MAX                    := $F2 ; probably different in original version; the image I have seems to be modified; see PDF
WIDTH                       := 80
WIDTH2                      := 56

; The start of available RAM, right after the stack.
RAMSTART2                   := $0200

; The start of reserved memory (prevent overwriting monitor work-RAM).
RAMEND                      := $7E00

; magic memory locations
L1800                       := $1800
L1873                       := $1873

; Simulator definitions
.if (USE_SIMULATOR)

SIM_IO                      = $F000
SIM_TERM_CLS                = SIM_IO + 0
SIM_TERM_OUT                = SIM_IO + 1
SIM_TERM_OUT_RAW            = SIM_IO + 2
SIM_TERM_OUT_HEX            = SIM_IO + 3
SIM_TERM_IN                 = SIM_IO + 4

.endif
