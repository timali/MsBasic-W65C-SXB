.segment "CODE"

.ifdef APPLE
.include "apple_loadsave.s"
.endif
.ifdef KIM
.include "kim_loadsave.s"
.endif
.ifdef MICROTAN
.include "microtan_loadsave.s"
.endif
.ifdef AIM65
.include "aim65_loadsave.s"
.endif
.ifdef SYM1
.include "sym1_loadsave.s"
.endif
.ifdef W65C_SXB
    .if (USE_SIMULATOR)
        .include "w65c_sxb_io_sim.s"
    .else
        .if (USE_USB_FOR_IO)
            .include "w65c_sxb_io_usb.s"
        .else
            .include "w65c_sxb_io_uart.s"
        .endif
    .endif
    .include "w65c_sxb_loadsave.s"
    .include "w65c_sxb_io.s"
.endif