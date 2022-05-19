		.segment "HEADER"
.ifdef KBD
        jmp     LE68C
        .byte   $00,$13,$56
.endif
.ifdef AIM65
        jmp     COLD_START
        jmp     RESTART
        .word   AYINT,GIVAYF
.endif
.ifdef SYM1
        jmp     PR_WRITTEN_BY
.endif
.ifdef W65C_SXB
  .if (!USE_SIMULATOR)
        .byte   "WDC"           ; Auto-start signature for custom ROM monitor.
  .endif
        jmp     COLD_START      ; Jump to the cold-start routine.
.endif