#!/bin/sh
# Temporary substitute for the future setup-zig Forgejo Action
curl $(curl https://ziglang.org/download/index.json | jq -r '.master."x86_64-linux".tarball') -o zig.tar.xz
tar -xf zig.tar.xz
mv zig*/ zig/
echo $(pwd)/zig >> $GITHUB_PATH
echo $GITHUB_PATH
