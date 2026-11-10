# Two problems seen on the board with nbd-client 3.27:
# - nbd-client now refuses to start without an export name unless netlink
#   is used ("not enough information specified"); pass an empty name, which
#   selects the default export as before;
# - when the client dies, nbd-proxy's SIGCHLD loop only stops on
#   waitpid() == 0, so with no children left (-1/ECHILD) it spins forever
#   and the web server that spawned it hangs until its watchdog fires.
do_configure:prepend:rd450x() {
    sed -i 's|execlp("nbd-client", "nbd-client", "-u", ctx->sock_path,|execlp("nbd-client", "nbd-client", "-N", "", "-u", ctx->sock_path,|' ${S}/nbd-proxy.c
    sed -i 's|        if (pid == 0)$|        if (pid <= 0)|' ${S}/nbd-proxy.c
    grep -q '"-N", "", "-u"' ${S}/nbd-proxy.c
    grep -q 'if (pid <= 0)' ${S}/nbd-proxy.c
}
