// SPDX-FileCopyrightText: 2024 Soulfind Contributors
// SPDX-FileCopyrightText: 2005-2017 SeeSchloss <seeschloss@seeschloss.org>
// SPDX-License-Identifier: GPL-3.0-or-later


module main;
@safe:

import defines;

import server;

import std.stdio : writefln;

import core.sys.posix.unistd : fork;
import core.sys.posix.signal;

extern(C) void handle_termination(int)
{
	writefln("\nA la prochaine...");
}

@trusted
private void setup_signal_handler()
{
	sigaction_t act;
	act.sa_handler = &handle_termination;

	sigaction(SIGINT, &act, null);
	sigaction(SIGTERM, &act, null);
}

private void help(string[] args)
{
	writefln("Usage: %s [database_file] [-d|--daemon]", args[0]);
	writefln(
		"\tdatabase_file: path to the sqlite3 database (default: %s)",
		default_db_file
	);
	writefln("\t-d, --daemon : fork in the background");
}

private int main(string[] args)
{
	bool daemon;
	string db = default_db_file;

	if (args.length > 3) help(args);

	foreach (arg ; args[1 .. $]) {
		switch (arg) {
			case "-h":
			case "--help":
				help(args);
				return 0;
			case "-d":
			case "--daemon":
				daemon = true;
				break;
			default:
				db = arg;
				break;
		}
	}

	if (daemon && fork())
		return 0;

	setup_signal_handler();

	auto server = new Server(db);
	return server.listen();
}
