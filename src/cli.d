// SPDX-FileCopyrightText: 2025 Soulfind Contributors
// SPDX-License-Identifier: GPL-3.0-or-later


module soulfind.cli;
@safe:

import soulfind.defines : VERSION;
import std.array : Appender;
import std.compiler : name, version_major, version_minor;
import std.conv : text;
import std.getopt : Option;
import std.stdio : write, writeln;
import std.string : rightJustifier;
import std.system : os;

void print_help(string description, Option[] options)
{
    Appender!string output;
    size_t short_max;
    size_t long_max;

    output ~= description;
    output ~= "\n";

    foreach (item; options) {
        if (item.optShort.length > short_max) short_max = item.optShort.length;
        if (item.optLong.length > long_max)   long_max  = item.optLong.length;
    }
    foreach (it; options) {
        output ~= text(
            it.optShort.rightJustifier(short_max), " ",
            it.optLong.rightJustifier(long_max), " ",
            it.help, "\n"
        );
    }
    write(output[]);
}

void print_version()
{
    writeln(
        "Soulfind ", VERSION, "\nCompiled with ", name, " ", version_major,
        ".", version_minor, " for ", os
    );
}
