const std = @import("std");

const argzon = @import("argzon");

const liza = @import("liza.zig");

// TODO: Extract into `cli.zon` after Zig 0.14.1 release.
const cli = .{
    .name = "liza",
    .description = "Zig codebase initializer",
    .options = .{
        .{
            .short = 'c',
            .long = "cbs",
            .type = "Codebase",
            .default = .exe,
            .description = "Codebase type",
        },
        .{
            .short = 'r',
            .long = "rnr",
            .type = "Runner",
            .default = .github,
            .description = "CI/CD runner type",
        },
        .{
            .short = 'v',
            .long = "ver",
            .type = "string",
            .default = "0.0.0",
            .description = "Codebase semantic version triple",
        },
        .{
            .short = 'o',
            .long = "out",
            .type = "string",
            .default = "./",
            .description = "Output directory path",
        },
    },
    .flags = .{
        .{
            .long = "add-doc",
            .description = "Add documentation to exe or lib (add doc step, add CD workflow)",
            .excludes = .{
                "cbs bld",
                "cbs app",
            },
        },
        .{
            .long = "add-cov",
            .description = "Add code coverage to exe or lib (add cov step, edit CI workflow, edit .gitignore)",
            .excludes = .{
                "cbs bld",
                "cbs app",
            },
        },
        .{
            .long = "add-check",
            .description = "Add compilation check for ZLS Build-On-Save to exe or lib (add check step)",
            .excludes = .{
                "cbs bld",
                "cbs app",
            },
        },
    },
    .positionals = .{
        .{
            .meta = .PCKG_NAME,
            .type = "string",
            .description = "Package name (e.g. liza)",
        },
        .{
            .meta = .PCKG_DESC,
            .type = "string",
            .description = "Package description (e.g. \"Zig codebase initializer.\") or build's upstream repository link",
        },
        .{
            .meta = .USER_HNDL,
            .type = "string",
            .description = "User handle (e.g. tensorush)",
        },
        .{
            .meta = .USER_NAME,
            .type = "string",
            .description = "User name (e.g. \"Jora Troosh\")",
        },
    },
};

const PCKG_NAME_PREFIX = "zig-";

pub fn main() !void {
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    var arena_state = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_state.allocator();
    defer arena_state.deinit();

    const Args = argzon.Args(cli, .{ .enums = &.{ liza.Codebase, liza.Runner } });
    const args = try Args.parse(arena, std.io.getStdErr().writer(), .{ .is_gpa = false });

    const codebase = args.options.cbs;
    const runner = args.options.rnr;
    const version = try std.SemanticVersion.parse(args.options.ver);
    const out_dir_path = args.options.out;

    const add_doc = args.flags.@"add-doc";
    const add_cov = args.flags.@"add-cov";
    const add_check = args.flags.@"add-check";

    const pckg_name_with_prefix_opt = if (codebase == .lib and std.mem.startsWith(u8, args.positionals.PCKG_NAME, PCKG_NAME_PREFIX))
        args.positionals.PCKG_NAME
    else
        null;
    const pckg_name = if (pckg_name_with_prefix_opt) |pckg_name_with_prefix|
        pckg_name_with_prefix[PCKG_NAME_PREFIX.len..]
    else
        args.positionals.PCKG_NAME;

    const pckg_desc = args.positionals.PCKG_DESC;
    const user_hndl = args.positionals.USER_HNDL;
    const user_name = args.positionals.USER_NAME;

    if (!std.zig.isValidId(pckg_name)) {
        @panic("Package name must be a valid Zig identifier, only library's name can be prefixed with \"" ++ PCKG_NAME_PREFIX ++ "\"!");
    }

    const zig_version_run = try std.process.Child.run(.{ .allocator = arena, .argv = &.{ "zig", "version" } });
    const zig_version = try std.SemanticVersion.parse(std.mem.trimRight(u8, zig_version_run.stdout, "\n"));

    try liza.initialize(
        arena,
        pckg_name_with_prefix_opt,
        pckg_name,
        pckg_desc,
        user_hndl,
        user_name,
        codebase,
        runner,
        version,
        out_dir_path,
        add_doc,
        add_cov,
        add_check,
        zig_version,
    );
}
