// SPDX-FileCopyrightText: 2024-2025 Soulfind Contributors
// SPDX-FileCopyrightText: 2005-2017 SeeSchloss <seeschloss@seeschloss.org>
// SPDX-License-Identifier: GPL-3.0-or-later


module soulfind.setup;
@safe:

import soulfind.cli : CLIOption, parse_args, print_help, print_version;
import soulfind.defines : default_db_filename, exit_message;
import soulfind.setup.setup : Setup;
import std.conv : text;
import std.stdio : writeln;

int run(string[] args)
{
    string  db_filename = default_db_filename;
    bool    show_version;
    bool    show_help;

    auto options = [
        CLIOption(
            "d", "database", text(
                "Database path (default: ", default_db_filename, ")."
            ), "path",
            (value) { db_filename = value; }
        ),
        CLIOption(
            "v", "version", "Show version.", null,
            (_) { show_version = true; }
        ),
        CLIOption(
            "h", "help", "Show this help message.", null,
            (_) { show_help = true; }
        )
    ];
    try {
        parse_args(args, options);
    }
    catch (Exception e) {
        writeln(e.msg);
        return 1;
    }

    if (show_version) {
        print_version();
        return 0;
    }

    if (show_help) {
        print_help("Soulfind server management tool", options);
        return 0;
    }

    auto setup = new Setup(db_filename);
    const exit_code = setup.show();

    writeln("\n", exit_message);
    return exit_code;
}
