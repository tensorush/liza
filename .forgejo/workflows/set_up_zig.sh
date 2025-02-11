curl $(curl https://ziglang.org/download/index.json | jq -r '.master."x86_64-linux".tarball') -o zig.tar.xz
tar -xf zig.tar.xz
mv zig*/ /usr/local/zig/
echo "export PATH="/usr/local/zig:\$PATH"" >> ~/.bashrc
