# boost.context's ARM assembly produces text relocations on ARMv5 as well.
# meta-aspeed only waives the QA check for aspeed-g5; do the same for this
# AST2400 board.
INSANE_SKIP:${PN}-context:rd450x = "textrel"
