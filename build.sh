#!/usr/bin/env bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )

var=CFLAGS_${TARGET}
CFLAGS=${!var}
var=COMPILER_ARGS_${TARGET}
COMPILER_ARGS=${!var} # add -opt for an optimized build.

mkdir -p $DIR/build/bin
mkdir -p $DIR/build/klib

jsinterop -pkg kotlinx.interop.wasm.dom \
          -o $DIR/build/klib/dom -target wasm32  || exit 1

konanc $DIR/src/main/kotlin \
        -r $DIR/build/klib -l dom \
        -o $DIR/build/bin/program -target wasm32 || exit 1

echo "Artifact path is $DIR/build/bin/program.wasm"
echo "Artifact path is $DIR/build/bin/program.wasm.js"
echo "Check out $DIR/index.html"
echo "Serve $DIR/ by an http server for the demo"

# simplehttp2server
