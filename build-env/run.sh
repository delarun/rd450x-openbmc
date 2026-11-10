#!/bin/sh
# Run a command inside the OpenBMC build container.
# Sources live in the project, build output on /mnt/data.
PROJ=$(cd "$(dirname "$0")/.." && pwd)
BUILD=${RD450X_BUILD_DIR:-/mnt/data/openbmc-build-rd450x}
exec docker run --rm -i \
    -v "$PROJ":"$PROJ" -v "$BUILD":"$BUILD" \
    -w "$PROJ/openbmc" -e BUILD="$BUILD" \
    rd450x-openbmc-build bash -c "$*"
