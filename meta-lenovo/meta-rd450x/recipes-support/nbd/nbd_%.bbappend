# nbd-client 3.27.1 accepts -n/-nofork but never applies it (the parsed
# result has no such field; "nofork" is only set for netlink), so the client
# daemonizes. jsnbd's nbd-proxy treats the exit of the process it started as
# "client stopped" and tears the virtual media session down at once.
do_configure:prepend:rd450x() {
    if ! grep -q 'rd450x: honour -nofork' ${S}/nbd-client.c; then
        sed -i '/^#ifndef NOFORK$/{N;/if(!nofork)/i\
	/* rd450x: honour -nofork */\
	for (int rd_i = 1; rd_i < argc; rd_i++) {\
		if (!strcmp(argv[rd_i], "-n") || !strcmp(argv[rd_i], "-nofork") ||\
		    !strcmp(argv[rd_i], "--nofork"))\
			nofork = 1;\
	}
}' ${S}/nbd-client.c
    fi
    grep -q 'rd450x: honour -nofork' ${S}/nbd-client.c
}
