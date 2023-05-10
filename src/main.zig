const std = @import("std");
const ncurses = @cImport({
    @cInclude("ncurses.h");
});
const stdlib = @cImport({
    @cInclude("stdlib.h");
});

const Variant = struct { name: usize, command: usize };

var buffer: [1024]u8 = undefined;

pub fn main() !void {
    var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fixed_buffer_allocator.allocator();

    const all_args = try std.process.argsAlloc(allocator);
    var args = all_args[1..];

    const usage =
        \\Usage: chmenu [-a] {name shell-command}
        \\
        \\ -h      Print this message and exit.
        \\ -a N    Automatically select the first option if there was no user activity
        \\         in the first N miliseconds of running the program.
        \\
        \\ Controls:
        \\ DOWN / n - Move selection to the next option.
        \\ UP   / p - Move selection to the previous option.
        \\ ENTER    - Exit with executing the corresponding command.
        \\ q        - Exit without executing anything.
    ;

    if (args.len == 0 or std.mem.eql(u8, args[0], "-h")) {
        std.log.info("{s}", .{usage});
        std.process.exit(0);
    }

    const autoselect_if_idle = std.mem.eql(u8, args[0], "-a");
    if (autoselect_if_idle and args.len < 2) {
        std.log.err("no idle time was provided.", .{});
        std.log.err("{s}", .{usage});
        std.process.exit(1);
    }

    const idle_time_milliseconds = if (!autoselect_if_idle) 0 else std.fmt.parseUnsigned(u32, args[1], 10) catch |reason| {
        std.log.err("cannot parse idle time: {}", .{reason});
        std.process.exit(1);
    };

    if (autoselect_if_idle) {
        args = args[2..];
    }

    if (args.len == 0) {
        std.log.err("expected an even number of arguments", .{});
        std.log.err("{s}", .{usage});
        std.process.exit(1);
    }

    if (@rem(args.len, 2) != 0) {
        std.log.err("expected an even number of arguments", .{});
        std.log.err("{s}", .{usage});
        std.process.exit(1);
    }

    var variants = try allocator.alloc(Variant, @divTrunc(args.len, 2));
    var max_name_length: usize = 0;

    var i: usize = 0;
    var vi: usize = 0;
    while (i < args.len) {
        variants[vi].name = i;
        variants[vi].command = i + 1;

        if (max_name_length < args[i].len) {
            max_name_length = args[i].len;
        }

        i += 2;
        vi += 1;
    }

    _ = ncurses.initscr();

    _ = ncurses.noecho();
    _ = ncurses.curs_set(0);

    const terminal_width: i32 = ncurses.getmaxx(ncurses.stdscr);
    const terminal_height: i32 = ncurses.getmaxy(ncurses.stdscr);

    const window_height: i32 = @intCast(i32, variants.len + 2);
    const window_width: i32 = @intCast(i32, max_name_length + 2);
    var window = ncurses.newwin(
        window_height,
        window_width,
        @divTrunc(terminal_height, 2) - @divTrunc(window_height, 2),
        @divTrunc(terminal_width, 2) - @divTrunc(window_width, 2),
    );

    _ = ncurses.keypad(window, true);
    _ = ncurses.wtimeout(window, 100);

    var current_time: i64 = 0;
    var pressed_anything: bool = false;
    var current_choise: isize = 0;
    var selected: bool = false;
    loop: while (true) {
        const start = std.time.milliTimestamp();

        if (autoselect_if_idle and current_time >= idle_time_milliseconds and pressed_anything == false) {
            selected = true;
            break :loop;
        }

        _ = ncurses.clear();
        _ = ncurses.refresh();

        _ = ncurses.box(window, 0, 0);

        _ = ncurses.wrefresh(window);
        for (variants) |variant, index| {
            if (index == current_choise) {
                _ = ncurses.wattron(window, ncurses.A_REVERSE);
            }
            _ = ncurses.mvwprintw(window, @intCast(c_int, index + 1), 1, "%s", @ptrCast([*c]const u8, args[variant.name]));
            if (index == current_choise) {
                _ = ncurses.wattroff(window, ncurses.A_REVERSE);
            }
        }

        const key = ncurses.wgetch(window);
        _ = switch (key) {
            ncurses.KEY_UP => {
                pressed_anything = true;
                current_choise -= 1;
            },
            ncurses.KEY_DOWN => {
                pressed_anything = true;
                current_choise += 1;
            },
            'n' => {
                pressed_anything = true;
                current_choise += 1;
            },
            'p' => {
                pressed_anything = true;
                current_choise -= 1;
            },
            '\n' => {
                selected = true;
                break :loop;
            },
            'q' => break :loop,
            else => {},
        };

        current_choise = std.math.clamp(current_choise, 0, variants.len - 1);

        _ = ncurses.wrefresh(window);

        const end = std.time.milliTimestamp();
        const delta = end - start;
        current_time += delta;
    }

    _ = ncurses.delwin(window);
    _ = ncurses.endwin();

    if (selected) {
        const commandIndex = variants[@intCast(usize, current_choise)].command;
        _ = stdlib.system(@ptrCast([*c]const u8, args[commandIndex]));
    }

    _ = allocator.free(variants);
    _ = std.process.argsFree(allocator, all_args);
}
