# Temporary substitute for setup-zig Forgejo Action
curl $(curl https://ziglang.org/download/index.json | jq -r '.master."x86_64-linux".tarball') -o zig.tar.xz
tar -xf zig.tar.xz
mv zig*/ zig/
