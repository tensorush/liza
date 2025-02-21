//! Root source file that exposes the application to Mach.

const std = @import("std");
const mach = @import("mach");

const App = @This();

/// Application name.
pub const mach_module = .app;

/// Mach modules available to the application.
pub const Modules = mach.Modules(.{ mach.Core, App });

/// Application's functions exposed to Mach as systems.
pub const mach_systems = .{ .main, .init, .tick, .deinit };

/// Application's schedule.
pub const main = mach.schedule(.{
    .{ mach.Core, .init },
    .{ App, .init },
    .{ mach.Core, .main },
});

window: mach.ObjectID,
title_timer: mach.time.Timer,
pipeline: *mach.gpu.RenderPipeline,

pub fn init(core: *mach.Core, app: *App, app_mod: mach.Mod(App)) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    // Create window.
    const window = try core.windows.new(.{
        .title = "core-triangle",
    });

    // Initialize application state.
    app.* = .{
        .window = window,
        .title_timer = try mach.time.Timer.start(),
        .pipeline = undefined,
    };
}

fn setupPipeline(core: *mach.Core, app: *App, window_id: mach.ObjectID) !void {
    var window = core.windows.getValue(window_id);
    defer core.windows.setValueRaw(window_id, window);

    // Create shader module.
    const shader_module = window.device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    // Create blend state that describes how rendered colors get blended.
    const blend = mach.gpu.BlendState{};

    // Create color target that describes window's pixel format.
    const color_target = mach.gpu.ColorTargetState{
        .format = window.framebuffer_format,
        .blend = &blend,
    };

    // Create fragment state that describes which shader and entrypoint to use for rendering fragments.
    const fragment = mach.gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    // Create render pipeline.
    const label = @tagName(mach_module) ++ ".init";
    const pipeline_descriptor = mach.gpu.RenderPipeline.Descriptor{
        .label = label,
        .fragment = &fragment,
        .vertex = mach.gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };
    app.pipeline = window.device.createRenderPipeline(&pipeline_descriptor);
}

pub fn tick(app: *App, core: *mach.Core) void {
    const label = @tagName(mach_module) ++ ".tick";
    const window = core.windows.getValue(app.window);

    // Handle events.
    while (core.nextEvent()) |event| {
        switch (event) {
            .window_open => |ev| {
                try setupPipeline(core, app, ev.window_id);
            },
            .close => core.exit(),
            else => {},
        }
    }

    // Create command encoder.
    const command_encoder = window.device.createCommandEncoder(&.{ .label = label });
    defer command_encoder.release();

    // Grab swapchain's back buffer.
    const back_buffer_view = window.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create color attachment.
    const sky_blue_background = mach.gpu.Color{ .r = 0.776, .g = 0.988, .b = 1.0, .a = 1.0 };
    const color_attachments = [_]mach.gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue_background,
        .load_op = .clear,
        .store_op = .store,
    }};

    // Begin render pass.
    const render_pass = command_encoder.beginRenderPass(&mach.gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));
    defer render_pass.release();

    // Draw.
    render_pass.setPipeline(app.pipeline);
    render_pass.draw(3, 1, 0, 0);

    // End render pass.
    render_pass.end();

    // Finish command encoding.
    var commands = command_encoder.finish(&.{ .label = label });
    defer commands.release();

    // Submit commands to queue.
    window.queue.submit(&[_]*mach.gpu.CommandBuffer{commands});
}

pub fn deinit(app: *App) void {
    app.pipeline.release();
}
